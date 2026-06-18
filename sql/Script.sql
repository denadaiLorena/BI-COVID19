create database dw_covid
encoding 'UTF-8'
template template0;


CREATE SCHEMA stg;
CREATE SCHEMA dw;
CREATE SCHEMA mart;

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

SELECT COUNT(*) FROM stg.notificacao_raw;



--DIM TEMPO
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

INSERT INTO dw.dim_tempo VALUES
(-1, NULL, NULL, NULL, NULL, NULL, 'Desconhecido', 'Desconhecido', 'N/D', FALSE, NULL);



--DIM LOCALIDADE
DROP TABLE IF EXISTS dw.dim_localidade CASCADE;
CREATE TABLE dw.dim_localidade (
    sk_local SERIAL PRIMARY KEY,
    municipio VARCHAR(100),
    bairro VARCHAR(150),
    uf CHAR(2) DEFAULT 'ES',
    regiao_es VARCHAR(30),
    macrorregiao VARCHAR(30),
    UNIQUE (municipio, bairro)
);

INSERT INTO dw.dim_localidade (sk_local, municipio, bairro, uf, regiao_es, macrorregiao)
OVERRIDING SYSTEM VALUE
VALUES (-1, 'Desconhecido', 'Desconhecido', 'ES', 'Desconhecida', 'Desconhecida');



--DIM PACIENTE
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
    UNIQUE (sexo, faixa_etaria, raca_cor, escolaridade,
            gestante, profissional_saude, morador_rua, possui_deficiencia)
);

INSERT INTO dw.dim_perfil_paciente (sk_perfil, sexo, faixa_etaria, raca_cor, escolaridade,
                                     gestante, profissional_saude, morador_rua, possui_deficiencia)
OVERRIDING SYSTEM VALUE
VALUES (-1, 'Desconhecido', 'Desconhecida', 'Desconhecida', 'Desconhecida',
        'Desconhecido', 'Desconhecido', 'Desconhecido', 'Desconhecido');



--DIM CLASSIFICAÇÃO
DROP TABLE IF EXISTS dw.dim_classificacao CASCADE;
CREATE TABLE dw.dim_classificacao (
    sk_class SERIAL PRIMARY KEY,
    classificacao VARCHAR(50),
    evolucao VARCHAR(50),
    criterio_confirmacao VARCHAR(50),
    status_notificacao VARCHAR(30),
    UNIQUE (classificacao, evolucao, criterio_confirmacao, status_notificacao)
);

INSERT INTO dw.dim_classificacao (sk_class, classificacao, evolucao,
                                   criterio_confirmacao, status_notificacao)
OVERRIDING SYSTEM VALUE
VALUES (-1, 'Desconhecida', 'Desconhecida', 'Desconhecido', 'Desconhecido');



--DIM SINTOMAS
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
    UNIQUE (febre, dif_respiratoria, tosse, coriza, dor_garganta, diarreia, cefaleia)
);

INSERT INTO dw.dim_sintomas (sk_sint, febre, dif_respiratoria, tosse, coriza,
                              dor_garganta, diarreia, cefaleia)
OVERRIDING SYSTEM VALUE
VALUES (-1, 'Desconhecido','Desconhecido','Desconhecido','Desconhecido',
        'Desconhecido','Desconhecido','Desconhecido');



--DIM COMORBIDADE
DROP TABLE IF EXISTS dw.dim_comorbidade CASCADE;
CREATE TABLE dw.dim_comorbidade (
    sk_como SERIAL PRIMARY KEY,
    com_pulmao VARCHAR(20),
    com_cardio VARCHAR(20),
    com_renal VARCHAR(20),
    com_diabetes VARCHAR(20),
    com_tabagismo VARCHAR(20),
    com_obesidade VARCHAR(20),
    UNIQUE (com_pulmao, com_cardio, com_renal, com_diabetes, com_tabagismo, com_obesidade)
);

INSERT INTO dw.dim_comorbidade (sk_como, com_pulmao, com_cardio, com_renal,
                                 com_diabetes, com_tabagismo, com_obesidade)
OVERRIDING SYSTEM VALUE
VALUES (-1, 'Desconhecido','Desconhecido','Desconhecido',
        'Desconhecido','Desconhecido','Desconhecido');



--DIM TESTE
DROP TABLE IF EXISTS dw.dim_teste CASCADE;
CREATE TABLE dw.dim_teste (
    sk_teste SERIAL PRIMARY KEY,
    tipo_teste_rapido VARCHAR(60),
    resultado_rt_pcr VARCHAR(30),
    resultado_teste_rap VARCHAR(30),
    resultado_sorologia VARCHAR(30),
    resultado_sorol_igg VARCHAR(30),
    UNIQUE (tipo_teste_rapido, resultado_rt_pcr,
            resultado_teste_rap, resultado_sorologia, resultado_sorol_igg)
);

INSERT INTO dw.dim_teste (sk_teste, tipo_teste_rapido, resultado_rt_pcr,
                           resultado_teste_rap, resultado_sorologia, resultado_sorol_igg)
OVERRIDING SYSTEM VALUE
VALUES (-1, 'Desconhecido','Desconhecido','Desconhecido',
        'Desconhecido','Desconhecido');


DROP TABLE IF EXISTS dw.fato_notificacao_covid CASCADE;
CREATE TABLE dw.fato_notificacao_covid (
    sk_fato BIGSERIAL PRIMARY KEY,

    -- Dimensões de tempo (role-playing)
    sk_data_notificacao INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_data_cadastro INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_data_diagnostico INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_data_coleta INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_data_encerramento INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_data_obito INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),

    -- Dimensões descritivas
    sk_local INT NOT NULL REFERENCES dw.dim_localidade(sk_local),
    sk_perfil INT NOT NULL REFERENCES dw.dim_perfil_paciente(sk_perfil),
    sk_class INT NOT NULL REFERENCES dw.dim_classificacao(sk_class),
    sk_sint INT NOT NULL REFERENCES dw.dim_sintomas(sk_sint),
    sk_como INT NOT NULL REFERENCES dw.dim_comorbidade(sk_como),
    sk_teste INT NOT NULL REFERENCES dw.dim_teste(sk_teste),

    -- Medidas
    qtd_notificacao SMALLINT NOT NULL DEFAULT 1,
    flag_confirmado SMALLINT NOT NULL DEFAULT 0,
    flag_obito_covid SMALLINT NOT NULL DEFAULT 0,
    flag_internado SMALLINT NOT NULL DEFAULT 0,
    flag_cura SMALLINT NOT NULL DEFAULT 0,
    idade_anos SMALLINT,
    dias_notif_encerramento INT,
    dias_notif_obito INT
);

-- Índices para consultas OLAP
CREATE INDEX idx_fato_data_notif ON dw.fato_notificacao_covid(sk_data_notificacao);
CREATE INDEX idx_fato_local ON dw.fato_notificacao_covid(sk_local);
CREATE INDEX idx_fato_class ON dw.fato_notificacao_covid(sk_class);
CREATE INDEX idx_fato_perfil ON dw.fato_notificacao_covid(sk_perfil);



-------------------------------------------------- POPULANDO AS TABELAS -------------------------------------------------

-- Populando a DIM TEMPO
INSERT INTO dw.dim_tempo (
    sk_tempo, data, dia, mes, ano, trimestre,
    nome_mes, dia_semana, ano_mes, eh_fim_de_semana, semana_epidemiologica
)
SELECT
    CAST(TO_CHAR(d, 'YYYYMMDD') AS INT) AS sk_tempo,
    d,
    EXTRACT(DAY FROM d)::SMALLINT,
    EXTRACT(MONTH FROM d)::SMALLINT,
    EXTRACT(YEAR FROM d)::SMALLINT,
    EXTRACT(QUARTER FROM d)::SMALLINT,
    TO_CHAR(d, 'TMMonth'),
    TO_CHAR(d, 'TMDay'),
    TO_CHAR(d, 'YYYY-MM'),
    EXTRACT(ISODOW FROM d) >= 6,
    EXTRACT(WEEK FROM d)::SMALLINT
FROM generate_series('2020-01-01'::DATE, '2026-12-31'::DATE, '1 day'::INTERVAL) d;


-- DIM LOCALIDADE
INSERT INTO dw.dim_localidade (municipio, bairro)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM("municipio"), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM("bairro"), ''), 'Desconhecido')
FROM stg.notificacao_raw
ON CONFLICT (municipio, bairro) DO NOTHING;



-- DIM CLASSIFICAÇÃO
INSERT INTO dw.dim_classificacao (classificacao, evolucao, criterio_confirmacao, status_notificacao)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(classificacao), ''), 'Desconhecida'),
    COALESCE(NULLIF(TRIM(evolucao), ''), 'Desconhecida'),
    COALESCE(NULLIF(TRIM(criterioconfirmacao), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(statusnotificacao), ''), 'Desconhecido')
FROM stg.notificacao_raw
ON CONFLICT (classificacao, evolucao, criterio_confirmacao, status_notificacao) DO NOTHING;



-- DIM PERFIL PACIENTE
INSERT INTO dw.dim_perfil_paciente (sexo, faixa_etaria, raca_cor, escolaridade,
                                     gestante, profissional_saude, morador_rua, possui_deficiencia)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(sexo), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(faixaetaria), ''), 'Desconhecida'),
    COALESCE(NULLIF(TRIM(racacor), ''), 'Desconhecida'),
    COALESCE(NULLIF(TRIM(escolaridade), ''), 'Desconhecida'),
    COALESCE(NULLIF(TRIM(gestante), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(profissionalsaude), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(moradorderua), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(possuideficiencia), ''), 'Desconhecido')
FROM stg.notificacao_raw
ON CONFLICT (sexo, faixa_etaria, raca_cor, escolaridade,
             gestante, profissional_saude, morador_rua, possui_deficiencia) DO NOTHING;



-- DIM SINTOMAS
INSERT INTO dw.dim_sintomas (febre, dif_respiratoria, tosse, coriza,
                              dor_garganta, diarreia, cefaleia)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(febre), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(dificuldaderespiratoria), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(tosse), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(coriza), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(dorgarganta), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(diarreia), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(cefaleia), ''), 'Desconhecido')
FROM stg.notificacao_raw
ON CONFLICT (febre, dif_respiratoria, tosse, coriza, dor_garganta, diarreia, cefaleia) DO NOTHING;



-- DIM COMORBIDADE
INSERT INTO dw.dim_comorbidade (com_pulmao, com_cardio, com_renal,
                                 com_diabetes, com_tabagismo, com_obesidade)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(comorbidadepulmao), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(comorbidadecardio), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(comorbidaderenal), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(comorbidadediabetes), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(comorbidadetabagismo), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(comorbidadeobesidade), ''), 'Desconhecido')
FROM stg.notificacao_raw
ON CONFLICT (com_pulmao, com_cardio, com_renal, com_diabetes, com_tabagismo, com_obesidade) DO NOTHING;



-- DIM TESTE
INSERT INTO dw.dim_teste (tipo_teste_rapido, resultado_rt_pcr,
                           resultado_teste_rap, resultado_sorologia, resultado_sorol_igg)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(tipotesterapido), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(resultadort_pcr), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(resultadotesterapido), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(resultadosorologia), ''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(resultadosorologia_igg), ''), 'Desconhecido')
FROM stg.notificacao_raw
ON CONFLICT (tipo_teste_rapido, resultado_rt_pcr,
             resultado_teste_rap, resultado_sorologia, resultado_sorol_igg) DO NOTHING; 



-- TABELA FATO
insert
	into
	dw.fato_notificacao_covid (
    sk_data_notificacao,
	sk_data_cadastro,
	sk_data_diagnostico,
	sk_data_coleta,
	sk_data_encerramento,
	sk_data_obito,
	sk_local,
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
select
	-- TEMPO
    coalesce(cast(TO_CHAR(nullif(TRIM(datanotificacao), '')::DATE, 'YYYYMMDD') as INT), -1),
	coalesce(cast(TO_CHAR(nullif(TRIM(datacadastro), '')::DATE, 'YYYYMMDD') as INT), -1),
	coalesce(cast(TO_CHAR(nullif(TRIM(datadiagnostico), '')::DATE, 'YYYYMMDD') as INT), -1),
	coalesce(cast(TO_CHAR(
        coalesce(
            nullif(TRIM(datacoleta_rt_pcr), '')::DATE,
            nullif(TRIM(datacoletatesterapido), '')::DATE,
            nullif(TRIM(datacoletasorologia), '')::DATE,
            nullif(TRIM(datacoletasorologiaigg), '')::DATE
        ), 'YYYYMMDD') as INT), -1),
	coalesce(cast(TO_CHAR(nullif(TRIM(dataencerramento), '')::DATE, 'YYYYMMDD') as INT), -1),
	coalesce(cast(TO_CHAR(nullif(TRIM(dataobito), '')::DATE, 'YYYYMMDD') as INT), -1),

    -- DIMENSÕES DESCRITIVAS
    COALESCE(dl.sk_local, -1),
    COALESCE(dp.sk_perfil, -1),
    COALESCE(dc.sk_class, -1),
    COALESCE(ds.sk_sint, -1),
    COALESCE(dm.sk_como, -1),
    COALESCE(dt.sk_teste, -1),

    -- MEDIDAS
    1,
    CASE WHEN classificacao = 'Confirmados' THEN 1 ELSE 0 END,
    CASE WHEN evolucao ILIKE '%bito pelo COVID%' THEN 1 ELSE 0 END,
    CASE WHEN ficouinternado = 'Sim' THEN 1 ELSE 0 END,
    CASE WHEN evolucao = 'Cura' THEN 1 ELSE 0 END,
    NULLIF(SPLIT_PART(idadenadatanotificacao, ' anos', 1),'')::INT,
    NULLIF(TRIM(dataencerramento),'')::DATE - NULLIF(TRIM(datanotificacao),'')::DATE,
    NULLIF(TRIM(dataobito),'')::DATE - NULLIF(TRIM(datanotificacao),'')::DATE

FROM stg.notificacao_raw s
LEFT JOIN dw.dim_localidade dl
    ON dl.municipio = COALESCE(NULLIF(TRIM(s.municipio),''),'Desconhecido')
    AND dl.bairro = COALESCE(NULLIF(TRIM(s.bairro),''),'Desconhecido')
LEFT JOIN dw.dim_perfil_paciente dp
    ON dp.sexo = COALESCE(NULLIF(TRIM(s.sexo),''),'Desconhecido')
    AND dp.faixa_etaria = COALESCE(NULLIF(TRIM(s.faixaetaria),''),'Desconhecida')
    AND dp.raca_cor = COALESCE(NULLIF(TRIM(s.racacor),''),'Desconhecida')
    AND dp.escolaridade = COALESCE(NULLIF(TRIM(s.escolaridade),''),'Desconhecida')
    AND dp.gestante = COALESCE(NULLIF(TRIM(s.gestante),''),'Desconhecido')
    AND dp.profissional_saude = COALESCE(NULLIF(TRIM(s.profissionalsaude),''),'Desconhecido')
    AND dp.morador_rua = COALESCE(NULLIF(TRIM(s.moradorderua),''),'Desconhecido')
    AND dp.possui_deficiencia = COALESCE(NULLIF(TRIM(s.possuideficiencia),''),'Desconhecido')
LEFT JOIN dw.dim_classificacao dc
    ON dc.classificacao = COALESCE(NULLIF(TRIM(s.classificacao),''),'Desconhecida')
    AND dc.evolucao = COALESCE(NULLIF(TRIM(s.evolucao),''),'Desconhecida')
    AND dc.criterio_confirmacao = COALESCE(NULLIF(TRIM(s.criterioconfirmacao),''),'Desconhecido')
    AND dc.status_notificacao = COALESCE(NULLIF(TRIM(s.statusnotificacao),''),'Desconhecido')
LEFT JOIN dw.dim_sintomas ds
    ON ds.febre = COALESCE(NULLIF(TRIM(s.febre),''),'Desconhecido')
    AND ds.dif_respiratoria = COALESCE(NULLIF(TRIM(s.dificuldaderespiratoria),''),'Desconhecido')
    AND ds.tosse = COALESCE(NULLIF(TRIM(s.tosse),''),'Desconhecido')
    AND ds.coriza = COALESCE(NULLIF(TRIM(s.coriza),''),'Desconhecido')
    AND ds.dor_garganta = COALESCE(NULLIF(TRIM(s.dorgarganta),''),'Desconhecido')
    AND ds.diarreia = COALESCE(NULLIF(TRIM(s.diarreia),''),'Desconhecido')
    AND ds.cefaleia = COALESCE(NULLIF(TRIM(s.cefaleia),''),'Desconhecido')
LEFT JOIN dw.dim_comorbidade dm
    ON dm.com_pulmao = COALESCE(NULLIF(TRIM(s.comorbidadepulmao),''),'Desconhecido')
    AND dm.com_cardio = COALESCE(NULLIF(TRIM(s.comorbidadecardio),''),'Desconhecido')
    AND dm.com_renal = COALESCE(NULLIF(TRIM(s.comorbidaderenal),''),'Desconhecido')
    AND dm.com_diabetes = COALESCE(NULLIF(TRIM(s.comorbidadediabetes),''),'Desconhecido')
    AND dm.com_tabagismo = COALESCE(NULLIF(TRIM(s.comorbidadetabagismo),''),'Desconhecido')
    AND dm.com_obesidade = COALESCE(NULLIF(TRIM(s.comorbidadeobesidade),''),'Desconhecido')
LEFT JOIN dw.dim_teste dt
    ON dt.tipo_teste_rapido = COALESCE(NULLIF(TRIM(s.tipotesterapido),''),'Desconhecido')
    AND dt.resultado_rt_pcr = COALESCE(NULLIF(TRIM(s.resultadort_pcr),''),'Desconhecido')
    AND dt.resultado_teste_rap = COALESCE(NULLIF(TRIM(s.resultadotesterapido),''),'Desconhecido')
    AND dt.resultado_sorologia = COALESCE(NULLIF(TRIM(s.resultadosorologia),''),'Desconhecido')
    AND dt.resultado_sorol_igg = COALESCE(NULLIF(TRIM(s.resultadosorologia_igg),''),'Desconhecido');