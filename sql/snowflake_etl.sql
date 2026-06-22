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