"""ETL: popula as dimensoes a partir de stg.notificacao_raw."""
from sqlalchemy import create_engine, text
# Importa a classe do seu arquivo database_connector.py
from database_connector import BancoDeDados

# Instancia a classe para utilizar a engine configurada
db = BancoDeDados()
engine = db.engine_dw

def carregar_dimensao(nome_tabela, colunas_origem, colunas_destino):
    """Extrai combinacoes distintas da staging e insere na dimensao."""
    col_src = ", ".join(colunas_origem)
    col_dst = ", ".join(colunas_destino)
    sql = f"""
        INSERT INTO dw.{nome_tabela} ({col_dst})
        SELECT DISTINCT {col_src}
        FROM stg.notificacao_raw
        ON CONFLICT ({col_dst}) DO NOTHING;
    """
    # Utiliza a engine vinda da instância db
    with engine.begin() as conn:
        conn.execute(text(sql))
    print(f"[OK] Dimensao {nome_tabela} carregada.")

# --- As chamadas das funções permanecem iguais ---
# ... (manter o restante do código conforme original)
# --- DIM_LOCALIDADE ---
carregar_dimensao(
    "dim_localidade",
    colunas_origem=["COALESCE(NULLIF(TRIM(municipio),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(bairro),''), 'Desconhecido')"],
    colunas_destino=["municipio", "bairro"]
)

# --- DIM_CLASSIFICACAO ---
carregar_dimensao(
    "dim_classificacao",
    colunas_origem=["COALESCE(NULLIF(TRIM(classificacao),''), 'Desconhecida')",
                    "COALESCE(NULLIF(TRIM(evolucao),''), 'Desconhecida')",
                    "COALESCE(NULLIF(TRIM(criterioconfirmacao),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(statusnotificacao),''), 'Desconhecido')"],
    colunas_destino=["classificacao", "evolucao", "criterio_confirmacao", "status_notificacao"]
)

# --- DIM_PERFIL_PACIENTE ---
carregar_dimensao(
    "dim_perfil_paciente",
    colunas_origem=["COALESCE(NULLIF(TRIM(sexo),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(faixaetaria),''), 'Desconhecida')",
                    "COALESCE(NULLIF(TRIM(racacor),''), 'Desconhecida')",
                    "COALESCE(NULLIF(TRIM(escolaridade),''), 'Desconhecida')",
                    "COALESCE(NULLIF(TRIM(gestante),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(profissionalsaude),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(moradorderua),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(possuideficiencia),''), 'Desconhecido')"],
    colunas_destino=["sexo", "faixa_etaria", "raca_cor", "escolaridade",
                     "gestante", "profissional_saude", "morador_rua", "possui_deficiencia"]
)

# --- DIM_SINTOMAS (junk) ---
carregar_dimensao(
    "dim_sintomas",
    colunas_origem=["COALESCE(NULLIF(TRIM(febre),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(dificuldaderespiratoria),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(tosse),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(coriza),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(dorgarganta),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(diarreia),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(cefaleia),''), 'Desconhecido')"],
    colunas_destino=["febre", "dif_respiratoria", "tosse", "coriza",
                     "dor_garganta", "diarreia", "cefaleia"]
)

# --- DIM_COMORBIDADE (junk) ---
carregar_dimensao(
    "dim_comorbidade",
    colunas_origem=["COALESCE(NULLIF(TRIM(comorbidadepulmao),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(comorbidadecardio),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(comorbidaderenal),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(comorbidadediabetes),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(comorbidadetabagismo),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(comorbidadeobesidade),''), 'Desconhecido')"],
    colunas_destino=["com_pulmao", "com_cardio", "com_renal",
                     "com_diabetes", "com_tabagismo", "com_obesidade"]
)

# --- DIM_TESTE ---
carregar_dimensao(
    "dim_teste",
    colunas_origem=["COALESCE(NULLIF(TRIM(tipotesterapido),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(resultadort_pcr),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(resultadotesterapido),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(resultadosorologia),''), 'Desconhecido')",
                    "COALESCE(NULLIF(TRIM(resultadosorologia_igg),''), 'Desconhecido')"],
    colunas_destino=["tipo_teste_rapido", "resultado_rt_pcr", "resultado_teste_rap",
                     "resultado_sorologia", "resultado_sorol_igg"]
)