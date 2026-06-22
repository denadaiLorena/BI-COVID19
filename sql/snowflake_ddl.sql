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
-- COPY stg.notificacao_raw
-- FROM 'D:/MICRODADOS.csv'
-- WITH (
--     FORMAT csv,
--     HEADER true,
--     ...
-- );


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