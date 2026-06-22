import os
import re
import gc
import pandas as pd
from sqlalchemy import create_engine

class BancoDeDados:
    def __init__(self):
        """
        Configura as conexões locais. 
        Otimizado com NullPool para não reter cache de dados na memória RAM.
        """
        self.USER = "postgres"
        self.PASSWORD = "6794"
        self.HOST = "localhost"  
        self.PORT = "5432"
        
        self.url_postgres = f"postgresql+psycopg2://{self.USER}:{self.PASSWORD}@{self.HOST}:{self.PORT}/postgres"
        self.url_dw = f"postgresql+psycopg2://{self.USER}:{self.PASSWORD}@{self.HOST}:{self.PORT}/dw_covid"
        
        # Desliga o pool de conexões para liberar a RAM do Python imediatamente após cada query
        from sqlalchemy.pool import NullPool
        self.engine_init = create_engine(self.url_postgres, poolclass=NullPool)
        self.engine_dw = create_engine(self.url_dw, poolclass=NullPool)

    def recriar_banco_dw(self):
        """Passo 1: Remove o banco de dados de forma limpa e força a liberação de memória"""
        print("Passo 1: Gerenciando o Banco de Dados no Servidor...")
        
        self.engine_dw.dispose()
        self.engine_init.dispose()
        gc.collect()
        
        try:
            with self.engine_init.connect().execution_options(isolation_level="AUTOCOMMIT") as conn:
                dbapi_conn = conn.connection
                with dbapi_conn.cursor() as cursor:
                    cursor.execute("""
                        SELECT pg_terminate_backend(pg_stat_activity.pid)
                        FROM pg_stat_activity
                        WHERE pg_stat_activity.datname = 'dw_covid' AND pid <> pg_backend_pid();
                    """)
                    cursor.execute("DROP DATABASE IF EXISTS dw_covid WITH (FORCE);")
                    cursor.execute("CREATE DATABASE dw_covid ENCODING 'UTF-8';")
                    print("[OK] Banco 'dw_covid' recriado com sucesso.")
                    return True
        except Exception as e:
            print(f"[ERRO CRÍTICO] Não foi possível recriar o banco: {e}")
            return False

    def executar_script_snowflake(self, caminho_sql):
        """Passo 2 e 3: Lê o arquivo SQL, aplica a correção RegEx e executa no DW"""
        print("\nPasso 2: Lendo e corrigindo o arquivo estrutural do Snowflake...")
        
        if not os.path.exists(caminho_sql):
            print(f"[ERRO] O arquivo {caminho_sql} não foi encontrado!")
            return

        try:
            with open(caminho_sql, "r", encoding="utf-8") as f:
                sql_script = f.read()
            
            sql_script_corrigido = re.sub(
                r"dataCamp_enc\s*:=\s*dataCamp_enc\s*,\s*dataencerramento", 
                "dataencerramento", 
                sql_script, 
                flags=re.IGNORECASE
            )
            
            print("Passo 3: Conectando diretamente no 'dw_covid' e gerando o esquema...")
            with self.engine_dw.connect().execution_options(isolation_level="AUTOCOMMIT") as conn:
                dbapi_conn = conn.connection
                with dbapi_conn.cursor() as cursor:
                    cursor.execute(sql_script_corrigido)
                    print("\n[SUCESSO] O modelo Snowflake foi gerado e populado com sucesso!")
                    
        except Exception as e:
            print(f"\n[ERRO] Falha ao processar as tabelas ou carregar o CSV: {e}")
        finally:
            sql_script = None
            sql_script_corrigido = None
            gc.collect()

    def salvar_dataframe(self, df, nome_tabela, if_exists='replace', schema=None):
        """
        Envia o DataFrame para a tabela no banco de dados usando COPY (bulk load),
        muito mais rápido que INSERT linha a linha para grandes volumes de dados.

        schema: nome do schema de destino (ex.: 'stg'). Se None, usa o schema
        padrão da conexão (geralmente 'public').
        """
        import io
        import csv
        import numpy as np

        df_copy = None
        buffer = None
        # Nome totalmente qualificado para o COPY (ex.: "stg"."notificacao_raw")
        nome_qualificado = f'"{schema}"."{nome_tabela}"' if schema else f'"{nome_tabela}"'
        try:
            # 1. Cria a estrutura da tabela (0 linhas) via to_sql
            df.head(0).to_sql(
                name=nome_tabela,
                con=self.engine_dw,
                if_exists=if_exists,
                index=False,
                schema=schema
            )

            # 2. Troca NaN/None por nulo real e usa quoting completo para
            #    proteger contra vírgulas, aspas ou quebras de linha dentro dos textos
            df_copy = df.replace({np.nan: None})

            buffer = io.StringIO()
            df_copy.to_csv(
                buffer,
                index=False,
                header=False,
                sep=',',
                quoting=csv.QUOTE_MINIMAL,
                na_rep=''  # campo vazio = NULL no COPY com FORMAT csv
            )
            buffer.seek(0)

            # 3. Bulk load via COPY
            with self.engine_dw.connect() as conn:
                dbapi_conn = conn.connection
                with dbapi_conn.cursor() as cursor:
                    cursor.copy_expert(
                        f"""COPY {nome_qualificado} FROM STDIN WITH (
                            FORMAT csv, DELIMITER ',', QUOTE '"', NULL ''
                        )""",
                        buffer
                    )
                dbapi_conn.commit()

            print(f"[OK] Tabela {nome_qualificado} populada via COPY ({len(df_copy)} linhas).")
        except Exception as e:
            print(f"[ERRO] Falha ao salvar lote no banco: {e}")
        finally:
            del df_copy, buffer
            import gc
            gc.collect()

            
    def processar_e_testar_data_mart(self, caminho_sql_mart):
        """Passo 1, 2, 3 e 4: Cria a Materialized View e compara a performance"""
        print("Passo 1: Lendo o script de criação do Data Mart...")
        if not os.path.exists(caminho_sql_mart):
            print(f"[ERRO] O arquivo {caminho_sql_mart} não foi encontrado!")
            return

        try:
            with open(caminho_sql_mart, "r", encoding="utf-8") as f:
                sql_content = f.read()

            comandos = [cmd.strip() for cmd in sql_content.split(";") if cmd.strip()]

            # Em vez de assumir posições fixas (comandos[0], [1], [2]...), identifica
            # cada comando pelo conteúdo: queries marcadas com "-- EXPLAIN ANALYZE"
            # vão para análise de performance; o restante (DROP/CREATE VIEW/INDEX) é DDL.
            ddl_comandos = []
            queries_explain = []

            for cmd in comandos:
                if re.search(r"--\s*EXPLAIN ANALYZE", cmd, flags=re.IGNORECASE):
                    query_limpa = re.sub(r"--\s*EXPLAIN ANALYZE", "", cmd, flags=re.IGNORECASE).strip()
                    queries_explain.append(query_limpa)
                else:
                    ddl_comandos.append(cmd)

            # A query do Data Mart referencia o schema 'mart.'; a query da Fato não.
            query_fato = next(q for q in queries_explain if "mart." not in q.lower())
            query_mv = next(q for q in queries_explain if "mart." in q.lower())

            with self.engine_dw.connect().execution_options(isolation_level="AUTOCOMMIT") as conn:
                dbapi_conn = conn.connection
                with dbapi_conn.cursor() as cursor:
                    print("Passo 2: Criando a Materialized View e Índices...")
                    for ddl in ddl_comandos:
                        cursor.execute(ddl + ";")
                    print("[OK] Materialized View criada com sucesso no schema 'mart'.")

                    print("\nPasso 3: Executando EXPLAIN ANALYZE na tabela Fato original (Ad-hoc)...")
                    cursor.execute(f"EXPLAIN ANALYZE {query_fato};")
                    runtime_fato = cursor.fetchall()
                    print("--- RESULTADO FATO ---")
                    for line in runtime_fato:
                        print(line[0])

                    print("\nPasso 4: Executando EXPLAIN ANALYZE no Data Mart (Materialized View)...")
                    cursor.execute(f"EXPLAIN ANALYZE {query_mv};")
                    runtime_mv = cursor.fetchall()
                    print("--- RESULTADO DATA MART ---")
                    for line in runtime_mv:
                        print(line[0])

        except Exception as e:
            print(f"\n[ERRO] Falha ao processar o Data Mart: {e}")
        finally:
            sql_content = None
            comandos = None
            gc.collect()

    def ler_tabela(self, nome_tabela):
        try:
            print(f"Buscando dados da tabela '{nome_tabela}'...")
            return pd.read_sql(f"SELECT * FROM {nome_tabela}", con=self.engine_dw)
        except Exception as e:
            print(f"[ERRO] Falha ao ler do banco: {e}")
            return None

    def ler_tabela_query(self, query):
        try:
            return pd.read_sql(query, self.engine_dw)
        except Exception as e:
            print(f"[ERRO] Falha ao executar a query: {e}")
            return pd.DataFrame()
    
    def executar_quality_gate(self, caminho_sql):
        if not os.path.exists(caminho_sql):
            print(f"[ERRO] O arquivo {caminho_sql} não foi encontrado!")
            return

        with open(caminho_sql, "r", encoding="utf-8") as f:
            sql_procedure = f.read()

        try:
            with self.engine_dw.connect().execution_options(isolation_level="AUTOCOMMIT") as conn:
                dbapi_conn = conn.connection
                with dbapi_conn.cursor() as cursor:
                    print("Passo 2: Criando a Stored Procedure no banco...")
                    cursor.execute(sql_procedure)
                    print("[OK] Stored Procedure 'dw.sp_validar_qualidade_carga' criada.")

                    print("\nPasso 3: Executando o Quality Gate (Validação)...")
                    cursor.execute("CALL dw.sp_validar_qualidade_carga();")
                    
                    for notice in dbapi_conn.notices:
                        print(f"Server Notice: {notice.strip()}")
                    
                    print("\n[SUCESSO] Dados validados. A carga da Fato está liberada!")
        except Exception as e:
            print(f"\n[BLOQUEADO] Carga interrompida pelo Quality Gate:")
            print(f"Detalhe do Erro: {e}")
        finally:
            sql_procedure = None
            gc.collect()