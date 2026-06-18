-- =============================================================================
-- 1. CRIAÇÃO DO BANCO E DOS SCHEMAS
-- =============================================================================


CREATE SCHEMA stg;

CREATE SCHEMA dw;

CREATE SCHEMA mart;

-- =============================================================================
-- 2. TABELA DE STAGING (RAW)
-- =============================================================================
DROP TABLE IF EXISTS stg.notificacao_raw;

CREATE TABLE stg.notificacao_raw (
    DataNotificacao TEXT,
    DataCadastro TEXT,
    DataDiagnostico TEXT,
    DataColeta_RT_PCR TEXT,
    DataColetaTesteRapido TEXT,
    DataColetaSorologia TEXT,
    DataColetaSorologiaIGG TEXT,
    DataEncerramento TEXT,
    DataObito TEXT,
    Classificacao TEXT,
    Evolucao TEXT,
    CriterioConfirmacao TEXT,
    StatusNotificacao TEXT,
    Municipio TEXT,
    Bairro TEXT,
    FaixaEtaria TEXT,
    IdadeNaDataNotificacao TEXT,
    Sexo TEXT,
    RacaCor TEXT,
    Escolaridade TEXT,
    Gestante TEXT,
    Febre TEXT,
    DificuldadeRespiratoria TEXT,
    Tosse TEXT,
    Coriza TEXT,
    DorGarganta TEXT,
    Diarreia TEXT,
    Cefaleia TEXT,
    ComorbidadePulmao TEXT,
    ComorbidadeCardio TEXT,
    ComorbidadeRenal TEXT,
    ComorbidadeDiabetes TEXT,
    ComorbidadeTabagismo TEXT,
    ComorbidadeObesidade TEXT,
    FicouInternado TEXT,
    ViagemBrasil TEXT,
    ViagemInternacional TEXT,
    ProfissionalSaude TEXT,
    PossuiDeficiencia TEXT,
    MoradorDeRua TEXT,
    ResultadoRT_PCR TEXT,
    ResultadoTesteRapido TEXT,
    ResultadoSorologia TEXT,
    ResultadoSorologia_IGG TEXT,
    TipoTesteRapido TEXT
);

-- Carga dos dados brutos
COPY stg.notificacao_raw
FROM 'D:/MICRODADOS.csv'
WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ';',
        ENCODING 'LATIN1',
        NULL '',
        QUOTE E'\x01'
    );

-- =============================================================================
-- 3. CRIAÇÃO DAS DIMENSÕES (COM FLOCO DE NEVE NA GEOGRAFIA)
-- =============================================================================

-- --- DIM TEMPO ---
DROP TABLE IF EXISTS dw.dim_tempo CASCADE;

CREATE TABLE dw.dim_tempo (
    sk_tempo INT PRIMARY KEY,
    data DATE,
    dia SMALLINT,
    mes SMALLINT,
    ano SMALLINT,
    trimestre SMALLINT,
    nome_mes VARCHAR(15),
    dia_semana VARCHAR(15),
    ano_mes CHAR(7),
    eh_fim_de_semana BOOLEAN,
    semana_epidemiologica SMALLINT
);

INSERT INTO
    dw.dim_tempo
VALUES (
        -1,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        'Desconhecido',
        'Desconhecido',
        'N/D',
        FALSE,
        NULL
    );

-- --- FLOCO DE NEVE: NÍVEL 1 - REGIÃO/MACRORREGIÃO ---
DROP TABLE IF EXISTS dw.dim_regiao CASCADE;

CREATE TABLE dw.dim_regiao (
    sk_regiao SERIAL PRIMARY KEY,
    regiao_es VARCHAR(30) NOT NULL,
    macrorregiao VARCHAR(30) NOT NULL,
    UNIQUE (regiao_es, macrorregiao)
);

INSERT INTO
    dw.dim_regiao (
        sk_regiao,
        regiao_es,
        macrorregiao
    ) OVERRIDING SYSTEM VALUE
VALUES (
        -1,
        'Desconhecida',
        'Desconhecida'
    );

-- --- FLOCO DE NEVE: NÍVEL 2 - MUNICÍPIO ---
DROP TABLE IF EXISTS dw.dim_municipio CASCADE;

CREATE TABLE dw.dim_municipio (
    sk_municipio SERIAL PRIMARY KEY,
    municipio VARCHAR(100) NOT NULL,
    uf CHAR(2) DEFAULT 'ES',
    fk_regiao INT NOT NULL REFERENCES dw.dim_regiao (sk_regiao),
    UNIQUE (municipio, uf)
);

INSERT INTO
    dw.dim_municipio (
        sk_municipio,
        municipio,
        uf,
        fk_regiao
    ) OVERRIDING SYSTEM VALUE
VALUES (-1, 'Desconhecido', 'ES', -1);

-- --- FLOCO DE NEVE: NÍVEL 3 - BAIRRO (Grão mais fino) ---
DROP TABLE IF EXISTS dw.dim_bairro CASCADE;

CREATE TABLE dw.dim_bairro (
    sk_bairro SERIAL PRIMARY KEY,
    bairro VARCHAR(150) NOT NULL,
    fk_municipio INT NOT NULL REFERENCES dw.dim_municipio (sk_municipio),
    UNIQUE (bairro, fk_municipio)
);

INSERT INTO
    dw.dim_bairro (
        sk_bairro,
        bairro,
        fk_municipio
    ) OVERRIDING SYSTEM VALUE
VALUES (-1, 'Desconhecido', -1);

-- --- DIM CLASSIFICAÇÃO ---
DROP TABLE IF EXISTS dw.dim_classificacao CASCADE;

CREATE TABLE dw.dim_classificacao (
    sk_class SERIAL PRIMARY KEY,
    classificacao VARCHAR(50),
    evolucao VARCHAR(50),
    criterio_confirmacao VARCHAR(50),
    status_notificacao VARCHAR(30),
    UNIQUE (
        classificacao,
        evolucao,
        criterio_confirmacao,
        status_notificacao
    )
);

INSERT INTO
    dw.dim_classificacao (
        sk_class,
        classificacao,
        evolucao,
        criterio_confirmacao,
        status_notificacao
    ) OVERRIDING SYSTEM VALUE
VALUES (
        -1,
        'Desconhecida',
        'Desconhecida',
        'Desconhecido',
        'Desconhecido'
    );

-- --- DIM PERFIL PACIENTE ---
DROP TABLE IF EXISTS dw.dim_perfil_paciente CASCADE;

CREATE TABLE dw.dim_perfil_paciente (
    sk_perfil SERIAL PRIMARY KEY,
    sexo VARCHAR(20),
    faixa_etaria VARCHAR(30),
    raca_cor VARCHAR(30),
    escolaridade VARCHAR(100),
    gestante VARCHAR(40),
    profissional_saude VARCHAR(20),
    morador_rua VARCHAR(20),
    possui_deficiencia VARCHAR(20),
    UNIQUE (
        sexo,
        faixa_etaria,
        raca_cor,
        escolaridade,
        gestante,
        profissional_saude,
        morador_rua,
        possui_deficiencia
    )
);

INSERT INTO
    dw.dim_perfil_paciente (
        sk_perfil,
        sexo,
        faixa_etaria,
        raca_cor,
        escolaridade,
        gestante,
        profissional_saude,
        morador_rua,
        possui_deficiencia
    ) OVERRIDING SYSTEM VALUE
VALUES (
        -1,
        'Desconhecido',
        'Desconhecida',
        'Desconhecida',
        'Desconhecida',
        'Desconhecido',
        'Desconhecido',
        'Desconhecido',
        'Desconhecido'
    );

-- --- DIM SINTOMAS ---
DROP TABLE IF EXISTS dw.dim_sintomas CASCADE;

CREATE TABLE dw.dim_sintomas (
    sk_sint SERIAL PRIMARY KEY,
    febre VARCHAR(20),
    dif_respiratoria VARCHAR(20),
    tosse VARCHAR(20),
    coriza VARCHAR(20),
    dor_garganta VARCHAR(20),
    diarreia VARCHAR(20),
    cefaleia VARCHAR(20),
    UNIQUE (
        febre,
        dif_respiratoria,
        tosse,
        coriza,
        dor_garganta,
        diarreia,
        cefaleia
    )
);

INSERT INTO
    dw.dim_sintomas (
        sk_sint,
        febre,
        dif_respiratoria,
        tosse,
        coriza,
        dor_garganta,
        diarreia,
        cefaleia
    ) OVERRIDING SYSTEM VALUE
VALUES (
        -1,
        'Desconhecido',
        'Desconhecido',
        'Desconhecido',
        'Desconhecido',
        'Desconhecido',
        'Desconhecido',
        'Desconhecido'
    );

-- --- DIM COMORBIDADE ---
DROP TABLE IF EXISTS dw.dim_comorbidade CASCADE;

CREATE TABLE dw.dim_comorbidade (
    sk_como SERIAL PRIMARY KEY,
    com_pulmao VARCHAR(20),
    com_cardio VARCHAR(20),
    com_renal VARCHAR(20),
    com_diabetes VARCHAR(20),
    com_tabagismo VARCHAR(20),
    com_obesidade VARCHAR(20),
    UNIQUE (
        com_pulmao,
        com_cardio,
        com_renal,
        com_diabetes,
        com_tabagismo,
        com_obesidade
    )
);

INSERT INTO
    dw.dim_comorbidade (
        sk_como,
        com_pulmao,
        com_cardio,
        com_renal,
        com_diabetes,
        com_tabagismo,
        com_obesidade
    ) OVERRIDING SYSTEM VALUE
VALUES (
        -1,
        'Desconhecido',
        'Desconhecido',
        'Desconhecido',
        'Desconhecido',
        'Desconhecido',
        'Desconhecido'
    );

-- --- DIM TESTE ---
DROP TABLE IF EXISTS dw.dim_teste CASCADE;

CREATE TABLE dw.dim_teste (
    sk_teste SERIAL PRIMARY KEY,
    tipo_teste_rapido VARCHAR(60),
    resultado_rt_pcr VARCHAR(30),
    resultado_teste_rap VARCHAR(30),
    resultado_sorologia VARCHAR(30),
    resultado_sorol_igg VARCHAR(30),
    UNIQUE (
        tipo_teste_rapido,
        resultado_rt_pcr,
        resultado_teste_rap,
        resultado_sorologia,
        resultado_sorol_igg
    )
);

INSERT INTO
    dw.dim_teste (
        sk_teste,
        tipo_teste_rapido,
        resultado_rt_pcr,
        resultado_teste_rap,
        resultado_sorologia,
        resultado_sorol_igg
    ) OVERRIDING SYSTEM VALUE
VALUES (
        -1,
        'Desconhecido',
        'Desconhecido',
        'Desconhecido',
        'Desconhecido',
        'Desconhecido'
    );

-- =============================================================================
-- 4. CRIAÇÃO DA TABELA FATO (CHAMA SK_BAIRRO)
-- =============================================================================
DROP TABLE IF EXISTS dw.fato_notificacao_covid CASCADE;

CREATE TABLE dw.fato_notificacao_covid (
    sk_fato BIGSERIAL PRIMARY KEY,
    sk_data_notificacao INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_data_cadastro INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_data_diagnostico INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_data_coleta INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_data_encerramento INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_data_obito INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),

-- Chave da Dimensão em Floco de Neve (Grão do Bairro)
sk_bairro INT NOT NULL REFERENCES dw.dim_bairro(sk_bairro),
    
    sk_perfil INT NOT NULL REFERENCES dw.dim_perfil_paciente(sk_perfil),
    sk_class INT NOT NULL REFERENCES dw.dim_classificacao(sk_class),
    sk_sint INT NOT NULL REFERENCES dw.dim_sintomas(sk_sint),
    sk_como INT NOT NULL REFERENCES dw.dim_comorbidade(sk_como),
    sk_teste INT NOT NULL REFERENCES dw.dim_teste(sk_teste),
    qtd_notificacao SMALLINT NOT NULL DEFAULT 1,
    flag_confirmado SMALLINT NOT NULL DEFAULT 0,
    flag_obito_covid SMALLINT NOT NULL DEFAULT 0,
    flag_internado SMALLINT NOT NULL DEFAULT 0,
    flag_cura SMALLINT NOT NULL DEFAULT 0,
    idade_anos SMALLINT,
    dias_notif_encerramento INT,
    dias_notif_obito INT
);

CREATE INDEX idx_fato_data_notif ON dw.fato_notificacao_covid (sk_data_notificacao);

CREATE INDEX idx_fato_bairro ON dw.fato_notificacao_covid (sk_bairro);

CREATE INDEX idx_fato_class ON dw.fato_notificacao_covid (sk_class);

-- =============================================================================
-- 5. POPULANDO AS TABELAS (ETL SQL)
-- =============================================================================

-- --- POPULAR DIM TEMPO ---
INSERT INTO
    dw.dim_tempo (
        sk_tempo,
        data,
        dia,
        mes,
        ano,
        trimestre,
        nome_mes,
        dia_semana,
        ano_mes,
        eh_fim_de_semana,
        semana_epidemiologica
    )
SELECT
    CAST(TO_CHAR(d, 'YYYYMMDD') AS INT) AS sk_tempo,
    d,
    EXTRACT(
        DAY
        FROM d
    )::SMALLINT,
    EXTRACT(
        MONTH
        FROM d
    )::SMALLINT,
    EXTRACT(
        YEAR
        FROM d
    )::SMALLINT,
    EXTRACT(
        QUARTER
        FROM d
    )::SMALLINT,
    TO_CHAR(d, 'TMMonth'),
    TO_CHAR(d, 'TMDay'),
    TO_CHAR(d, 'YYYY-MM'),
    EXTRACT(
        ISODOW
        FROM d
    ) >= 6,
    EXTRACT(
        WEEK
        FROM d
    )::SMALLINT
FROM generate_series(
        '2020-01-01'::DATE, '2026-12-31'::DATE, '1 day'::INTERVAL
    ) d;

-- --- POPULAR FLOCO DE NEVE GEOGRÁFICO (REQUER ORDEM ESTRITA) ---

-- Carga Passo 1: Região (Fixo/Mapeado ou inferido da Staging se existisse. Como a Staging só tem Município/Bairro, criamos o padrão inicial)
INSERT INTO
    dw.dim_regiao (regiao_es, macrorregiao)
VALUES (
        'Metropolitana',
        'Metropolitana'
    ) -- Exemplo para capital e arredores
ON CONFLICT DO NOTHING;

-- Carga Passo 2: Município (Relaciona com a Região criada)
INSERT INTO
    dw.dim_municipio (municipio, fk_regiao)
SELECT DISTINCT
    COALESCE(
        NULLIF(TRIM(municipio), ''),
        'Desconhecido'
    ),
    -1 -- Aponta para a Região padrão definida (-1)
FROM stg.notificacao_raw
ON CONFLICT (municipio, uf) DO NOTHING;

-- Carga Passo 3: Bairro (Relaciona com o Município correspondente)
INSERT INTO
    dw.dim_bairro (bairro, fk_municipio)
SELECT DISTINCT
    COALESCE(
        NULLIF(TRIM(s.bairro), ''),
        'Desconhecido'
    ),
    COALESCE(m.sk_municipio, -1)
FROM stg.notificacao_raw s
    LEFT JOIN dw.dim_municipio m ON m.municipio = COALESCE(
        NULLIF(TRIM(s.municipio), ''), 'Desconhecido'
    )
ON CONFLICT (bairro, fk_municipio) DO NOTHING;

-- --- POPULAR DEMAIS DIMENSÕES ---
INSERT INTO
    dw.dim_classificacao (
        classificacao,
        evolucao,
        criterio_confirmacao,
        status_notificacao
    )
SELECT DISTINCT
    COALESCE(
        NULLIF(TRIM(classificacao), ''),
        'Desconhecida'
    ),
    COALESCE(
        NULLIF(TRIM(evolucao), ''),
        'Desconhecida'
    ),
    COALESCE(
        NULLIF(TRIM(criterioconfirmacao), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(TRIM(statusnotificacao), ''),
        'Desconhecido'
    )
FROM stg.notificacao_raw
ON CONFLICT DO NOTHING;

INSERT INTO
    dw.dim_perfil_paciente (
        sexo,
        faixa_etaria,
        raca_cor,
        escolaridade,
        gestante,
        profissional_saude,
        morador_rua,
        possui_deficiencia
    )
SELECT DISTINCT
    COALESCE(
        NULLIF(TRIM(sexo), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(TRIM(faixaetaria), ''),
        'Desconhecida'
    ),
    COALESCE(
        NULLIF(TRIM(racacor), ''),
        'Desconhecida'
    ),
    COALESCE(
        NULLIF(TRIM(escolaridade), ''),
        'Desconhecida'
    ),
    COALESCE(
        NULLIF(TRIM(gestante), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(TRIM(profissionalsaude), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(TRIM(moradorderua), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(TRIM(possuideficiencia), ''),
        'Desconhecido'
    )
FROM stg.notificacao_raw
ON CONFLICT DO NOTHING;

INSERT INTO
    dw.dim_sintomas (
        febre,
        dif_respiratoria,
        tosse,
        coriza,
        dor_garganta,
        diarreia,
        cefaleia
    )
SELECT DISTINCT
    COALESCE(
        NULLIF(TRIM(febre), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(
            TRIM(dificuldaderespiratoria),
            ''
        ),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(TRIM(tosse), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(TRIM(coriza), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(TRIM(dorgarganta), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(TRIM(diarreia), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(TRIM(cefaleia), ''),
        'Desconhecido'
    )
FROM stg.notificacao_raw
ON CONFLICT DO NOTHING;

INSERT INTO
    dw.dim_comorbidade (
        com_pulmao,
        com_cardio,
        com_renal,
        com_diabetes,
        com_tabagismo,
        com_obesidade
    )
SELECT DISTINCT
    COALESCE(
        NULLIF(TRIM(comorbidadepulmao), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(TRIM(comorbidadecardio), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(TRIM(comorbidaderenal), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(TRIM(comorbidadediabetes), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(
            TRIM(comorbidadetabagismo),
            ''
        ),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(
            TRIM(comorbidadeobesidade),
            ''
        ),
        'Desconhecido'
    )
FROM stg.notificacao_raw
ON CONFLICT DO NOTHING;

INSERT INTO
    dw.dim_teste (
        tipo_teste_rapido,
        resultado_rt_pcr,
        resultado_teste_rap,
        resultado_sorologia,
        resultado_sorol_igg
    )
SELECT DISTINCT
    COALESCE(
        NULLIF(TRIM(tipotesterapido), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(TRIM(resultadort_pcr), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(
            TRIM(resultadotesterapido),
            ''
        ),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(TRIM(resultadosorologia), ''),
        'Desconhecido'
    ),
    COALESCE(
        NULLIF(
            TRIM(resultadosorologia_igg),
            ''
        ),
        'Desconhecido'
    )
FROM stg.notificacao_raw
ON CONFLICT DO NOTHING;

-- --- POPULAR TABELA FATO ---
INSERT INTO
    dw.fato_notificacao_covid (
        sk_data_notificacao,
        sk_data_cadastro,
        sk_data_diagnostico,
        sk_data_coleta,
        sk_data_encerramento,
        sk_data_obito,
        sk_bairro,
        sk_perfil,
        sk_class,
        sk_sint,
        sk_como,
        sk_teste,
        qtd_notificacao,
        flag_confirmado,
        flag_obito_covid,
        flag_internado,
        flag_cura,
        idade_anos,
        dias_notif_encerramento,
        dias_notif_obito
    )
SELECT
    -- Tratamento das Datas (Regra de Negócio Antiga Mantida)
    COALESCE(
        CASE
            WHEN NULLIF(TRIM(datanotificacao), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'  THEN CAST(
                TO_CHAR(
                    NULLIF(TRIM(datanotificacao), '')::DATE, 'YYYYMMDD'
                ) AS INT
            )
        END, -1
    ), COALESCE(
        CASE
            WHEN NULLIF(TRIM(datacadastro), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'  THEN CAST(
                TO_CHAR(
                    NULLIF(TRIM(datacadastro), '')::DATE, 'YYYYMMDD'
                ) AS INT
            )
        END, -1
    ), COALESCE(
        CASE
            WHEN NULLIF(TRIM(datadiagnostico), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'  THEN CAST(
                TO_CHAR(
                    NULLIF(TRIM(datadiagnostico), '')::DATE, 'YYYYMMDD'
                ) AS INT
            )
        END, -1
    ), COALESCE(
        CASE
            WHEN COALESCE(
                NULLIF(TRIM(datacoleta_rt_pcr), '')::DATE, NULLIF(
                    TRIM(datacoletatesterapido), ''
                )::DATE, NULLIF(TRIM(datacoletasorologia), '')::DATE, NULLIF(
                    TRIM(datacoletasorologiaigg), ''
                )::DATE
            ) BETWEEN '2020-01-01' AND '2026-12-31'  THEN CAST(
                TO_CHAR(
                    COALESCE(
                        NULLIF(TRIM(datacoleta_rt_pcr), '')::DATE, NULLIF(
                            TRIM(datacoletatesterapido), ''
                        )::DATE, NULLIF(TRIM(datacoletasorologia), '')::DATE, NULLIF(
                            TRIM(datacoletasorologiaigg), ''
                        )::DATE
                    ), 'YYYYMMDD'
                ) AS INT
            )
        END, -1
    ), COALESCE(
        CASE
            WHEN NULLIF(
                TRIM(
                    dataCamp_enc := dataCamp_enc, dataencerramento
                ), ''
            )::DATE BETWEEN '2020-01-01' AND '2026-12-31'  THEN CAST(
                TO_CHAR(
                    NULLIF(TRIM(dataencerramento), '')::DATE, 'YYYYMMDD'
                ) AS INT
            )
        END, -1
    ), COALESCE(
        CASE
            WHEN NULLIF(TRIM(dataobito), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'  THEN CAST(
                TO_CHAR(
                    NULLIF(TRIM(dataobito), '')::DATE, 'YYYYMMDD'
                ) AS INT
            )
        END, -1
    ),

-- CAPTURA DO SK_BAIRRO VIA HISTÓRICO FLOCO DE NEVE
COALESCE(db.sk_bairro, -1),

-- DEMAIS CHAVES STRATEGICAS
COALESCE(dp.sk_perfil, -1),
COALESCE(dc.sk_class, -1),
COALESCE(ds.sk_sint, -1),
COALESCE(dm.sk_como, -1),
COALESCE(dt.sk_teste, -1),
1,
CASE
    WHEN s.classificacao = 'Confirmados' THEN 1
    ELSE 0
END,
CASE
    WHEN s.evolucao ILIKE '%bito pelo COVID%' THEN 1
    ELSE 0
END,
CASE
    WHEN s.ficouinternado = 'Sim' THEN 1
    ELSE 0
END,
CASE
    WHEN s.evolucao = 'Cura' THEN 1
    ELSE 0
END,
NULLIF(
    SPLIT_PART(
        s.idadenadatanotificacao,
        ' anos',
        1
    ),
    ''
)::INT,
CASE
    WHEN NULLIF(
        TRIM(
            dataCamp_enc := dataCamp_enc,
            dataencerramento
        ),
        ''
    )::DATE BETWEEN '2020-01-01' AND '2026-12-31'
    AND NULLIF(TRIM(datanotificacao), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'  THEN NULLIF(TRIM(dataencerramento), '')::DATE - NULLIF(TRIM(datanotificacao), '')::DATE
END,
CASE
    WHEN NULLIF(TRIM(dataobito), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'
    AND NULLIF(TRIM(datanotificacao), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'  THEN NULLIF(TRIM(dataobito), '')::DATE - NULLIF(TRIM(datanotificacao), '')::DATE
END
FROM stg.notificacao_raw s
    -- JOIN PARA ENCONTRAR O BAIRRO CORRETO NO FLOCO DE NEVE
    LEFT JOIN dw.dim_municipio dm_b ON dm_b.municipio = COALESCE(
        NULLIF(TRIM(s.municipio), ''), 'Desconhecido'
    )
    LEFT JOIN dw.dim_bairro db ON db.bairro = COALESCE(
        NULLIF(TRIM(s.bairro), ''), 'Desconhecido'
    )
    AND db.fk_municipio = dm_b.sk_municipio

-- DEMAIS RELACIONAMENTOS PADRÃO
LEFT JOIN dw.dim_perfil_paciente dp ON dp.sexo = COALESCE(
    NULLIF(TRIM(s.sexo), ''),
    'Desconhecido'
)
AND dp.faixa_etaria = COALESCE(
    NULLIF(TRIM(s.faixaetaria), ''),
    'Desconhecida'
)
AND dp.raca_cor = COALESCE(
    NULLIF(TRIM(s.racacor), ''),
    'Desconhecida'
)
AND dp.escolaridade = COALESCE(
    NULLIF(TRIM(s.escolaridade), ''),
    'Desconhecida'
)
AND dp.gestante = COALESCE(
    NULLIF(TRIM(s.gestante), ''),
    'Desconhecido'
)
AND dp.profissional_saude = COALESCE(
    NULLIF(TRIM(s.profissionalsaude), ''),
    'Desconhecido'
)
AND dp.morador_rua = COALESCE(
    NULLIF(TRIM(s.moradorderua), ''),
    'Desconhecido'
)
AND dp.possui_deficiencia = COALESCE(
    NULLIF(TRIM(s.possuideficiencia), ''),
    'Desconhecido'
)
LEFT JOIN dw.dim_classificacao dc ON dc.classificacao = COALESCE(
    NULLIF(TRIM(s.classificacao), ''),
    'Desconhecida'
)
AND dc.evolucao = COALESCE(
    NULLIF(TRIM(s.evolucao), ''),
    'Desconhecida'
)
AND dc.criterio_confirmacao = COALESCE(
    NULLIF(
        TRIM(s.criterioconfirmacao),
        ''
    ),
    'Desconhecido'
)
AND dc.status_notificacao = COALESCE(
    NULLIF(TRIM(s.statusnotificacao), ''),
    'Desconhecido'
)
LEFT JOIN dw.dim_sintomas ds ON ds.febre = COALESCE(
    NULLIF(TRIM(s.febre), ''),
    'Desconhecido'
)
AND ds.dif_respiratoria = COALESCE(
    NULLIF(
        TRIM(s.dificuldaderespiratoria),
        ''
    ),
    'Desconhecido'
)
AND ds.tosse = COALESCE(
    NULLIF(TRIM(s.tosse), ''),
    'Desconhecido'
)
AND ds.coriza = COALESCE(
    NULLIF(TRIM(s.coriza), ''),
    'Desconhecido'
)
AND ds.dor_garganta = COALESCE(
    NULLIF(TRIM(s.dorgarganta), ''),
    'Desconhecido'
)
AND ds.diarreia = COALESCE(
    NULLIF(TRIM(s.diarreia), ''),
    'Desconhecido'
)
AND ds.cefaleia = COALESCE(
    NULLIF(TRIM(s.cefaleia), ''),
    'Desconhecido'
)
LEFT JOIN dw.dim_comorbidade dm ON dm.com_pulmao = COALESCE(
    NULLIF(TRIM(s.comorbidadepulmao), ''),
    'Desconhecido'
)
AND dm.com_cardio = COALESCE(
    NULLIF(TRIM(s.comorbidadecardio), ''),
    'Desconhecido'
)
AND dm.com_renal = COALESCE(
    NULLIF(TRIM(s.comorbidaderenal), ''),
    'Desconhecido'
)
AND dm.com_diabetes = COALESCE(
    NULLIF(
        TRIM(s.comorbidadediabetes),
        ''
    ),
    'Desconhecido'
)
AND dm.com_tabagismo = COALESCE(
    NULLIF(
        TRIM(s.comorbidadetabagismo),
        ''
    ),
    'Desconhecido'
)
AND dm.com_obesidade = COALESCE(
    NULLIF(
        TRIM(s.comorbidadeobesidade),
        ''
    ),
    'Desconhecido'
)
LEFT JOIN dw.dim_teste dt ON dt.tipo_teste_rapido = COALESCE(
    NULLIF(TRIM(s.tipotesterapido), ''),
    'Desconhecido'
)
AND dt.resultado_rt_pcr = COALESCE(
    NULLIF(TRIM(s.resultadort_pcr), ''),
    'Desconhecido'
)
AND dt.resultado_teste_rap = COALESCE(
    NULLIF(
        TRIM(s.resultadotesterapido),
        ''
    ),
    'Desconhecido'
)
AND dt.resultado_sorologia = COALESCE(
    NULLIF(
        TRIM(s.resultadosorologia),
        ''
    ),
    'Desconhecido'
)
AND dt.resultado_sorol_igg = COALESCE(
    NULLIF(
        TRIM(s.resultadosorologia_igg),
        ''
    ),
    'Desconhecido'
);

-- =============================================================================
-- 6. EXEMPLO DE REESCRITA DA QUERY DE VALIDAÇÃO (Q1 COM JOIN FLOCO DE NEVE)
-- =============================================================================
-- Comparado com a versão anterior, precisamos subir a hierarquia (Bairro -> Município)
SELECT
    m.municipio,
    t.ano_mes,
    SUM(f.flag_confirmado) AS confirmados,
    SUM(f.qtd_notificacao) AS notificacoes_total
FROM dw.fato_notificacao_covid f
    JOIN dw.dim_bairro b ON b.sk_bairro = f.sk_bairro
    JOIN dw.dim_municipio m ON m.sk_municipio = b.fk_municipio
    JOIN dw.dim_tempo t ON t.sk_tempo = f.sk_data_notificacao
WHERE
    t.ano IN (2021, 2022)
GROUP BY
    m.municipio,
    t.ano_mes
ORDER BY confirmados DESC
LIMIT 20;