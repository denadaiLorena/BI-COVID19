import os
import re
from sqlalchemy import create_engine

class BancoDeDados:
    def __init__(self):
        """
        Configura as URLs de conexão. 
        Mude o HOST, USER e PASSWORD para os dados do seu banco na nuvem (ex: Supabase/Aiven)
        ou mantenha estes se conseguiu rodar o Postgres local.
        """
        self.USER = "postgres"
        self.PASSWORD = "6794"
        self.HOST = "localhost"  # Mude para o link da nuvem se necessário
        self.PORT = "5432"
        
        # URLs de conexão usando o driver correto do Postgres (psycopg2)
        self.url_postgres = f"postgresql+psycopg2://{self.USER}:{self.PASSWORD}@{self.HOST}:{self.PORT}/postgres"
        self.url_dw = f"postgresql+psycopg2://{self.USER}:{self.PASSWORD}@{self.HOST}:{self.PORT}/dw_covid"
        
        # Cria as engines do SQLAlchemy
        self.engine_init = create_engine(self.url_postgres)
        self.engine_dw = create_engine(self.url_dw)

    def recriar_banco_dw(self):
        """Passo 1: Derruba conexões presas e recria o banco 'dw_covid' do zero"""
        print("Passo 1: Gerenciando o Banco de Dados no Servidor...")
        try:
            with self.engine_init.connect().execution_options(isolation_level="AUTOCOMMIT") as conn:
                dbapi_conn = conn.connection
                with dbapi_conn.cursor() as cursor:
                    # Força a queda de outras conexões para permitir o DROP
                    cursor.execute("""
                        SELECT pg_terminate_backend(pg_stat_activity.pid)
                        FROM pg_stat_activity
                        WHERE pg_stat_activity.datname = 'dw_covid' AND pid <> pg_backend_pid();
                    """)
                    cursor.execute("DROP DATABASE IF EXISTS dw_covid;")
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
            
            # Correção cirúrgica via RegEx do campo de encerramento
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

    def processar_e_testar_data_mart(self, caminho_sql_mart):
        """
        Passo 1, 2, 3 e 4: Cria a Materialized View e compara a performance
        da consulta Ad-hoc (Fato) contra o Data Mart utilizando EXPLAIN ANALYZE.
        """
        import os

        print("Passo 1: Lendo o script de criação do Data Mart...")
        if not os.path.exists(caminho_sql_mart):
            print(f"[ERRO] O arquivo {caminho_sql_mart} não foi encontrado!")
            return

        try:
            with open(caminho_sql_mart, "r", encoding="utf-8") as f:
                sql_content = f.read()
            
            # Separa os comandos por ponto e vírgula
            comandos = [cmd.strip() for cmd in sql_content.split(";") if cmd.strip()]
            
            with self.engine_dw.connect().execution_options(isolation_level="AUTOCOMMIT") as conn:
                dbapi_conn = conn.connection
                with dbapi_conn.cursor() as cursor:
                    print("Passo 2: Criando a Materialized View e Índices...")
                    # Executa os dois primeiros comandos (geralmente CREATE MATERIALIZED VIEW e CREATE INDEX)
                    cursor.execute(comandos[0] + ";")
                    cursor.execute(comandos[1] + ";")
                    print("[OK] Materialized View criada com sucesso no schema 'mart'.")
                    
                    # --- AVALIAÇÃO EXPLAIN ANALYZE: MODELO AD-HOC (FATO) ---
                    print("\nPasso 3: Executando EXPLAIN ANALYZE na tabela Fato original (Ad-hoc)...")
                    # Remove o comentário `-- EXPLAIN ANALYZE` caso ele exista no arquivo e força a execução do comando
                    clean_query_fato = comandos[2].replace("-- EXPLAIN ANALYZE", "").strip()
                    query_fato = f"EXPLAIN ANALYZE {clean_query_fato};"
                    
                    cursor.execute(query_fato)
                    runtime_fato = cursor.fetchall()
                    print("--- RESULTADO FATO ---")
                    for line in runtime_fato:
                        print(line[0])
                    
                    # --- AVALIAÇÃO EXPLAIN ANALYZE: DATA MART (MV) ---
                    print("\nPasso 4: Executando EXPLAIN ANALYZE no Data Mart (Materialized View)...")
                    clean_query_mv = comandos[3].replace("-- EXPLAIN ANALYZE", "").strip()
                    query_mv = f"EXPLAIN ANALYZE {clean_query_mv};"
                    
                    cursor.execute(query_mv)
                    runtime_mv = cursor.fetchall()
                    print("--- RESULTADO DATA MART ---")
                    for line in runtime_mv:
                        print(line[0])
                        
        except Exception as e:
            print(f"\n[ERRO] Falha ao processar o Data Mart: {e}")

    def salvar_dataframe(self, df, nome_tabela, if_exists='replace'):
        """
        Envia um DataFrame do Pandas direto para uma tabela no banco de dados.
        """
        try:
            print(f"Enviando dados para a tabela '{nome_tabela}'...")
            # Usando a engine_dw para salvar dentro do banco dw_covid
            df.to_sql(name=nome_tabela, con=self.engine_dw, if_exists=if_exists, index=False)
            print(f"[OK] Dados salvos com sucesso na tabela '{nome_tabela}'!")
        except Exception as e:
            print(f"[ERRO] Falha ao salvar no banco: {e}")

    def ler_tabela(self, nome_tabela):
        """
        Busca uma tabela do banco de dados e transforma de volta em um DataFrame.
        """
        try:
            print(f"Buscando dados da tabela '{nome_tabela}'...")
            df = pd.read_sql(f"SELECT * FROM {nome_tabela}", con=self.engine_dw)
            return df
        except Exception as e:
            print(f"[ERRO] Falha ao ler do banco: {e}")
            return None
        
    