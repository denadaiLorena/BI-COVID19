INSERT INTO
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
SELECT
    -- TEMPO: todas as datas filtradas para o intervalo válido
    COALESCE(
        CASE
            WHEN NULLIF(TRIM(datanotificacao), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'  THEN CAST(
                TO_CHAR(
                    NULLIF(TRIM(datanotificacao), '')::DATE,
                    'YYYYMMDD'
                ) AS INT
            )
        END,
        -1
    ),
    COALESCE(
        CASE
            WHEN NULLIF(TRIM(datacadastro), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'  THEN CAST(
                TO_CHAR(
                    NULLIF(TRIM(datacadastro), '')::DATE,
                    'YYYYMMDD'
                ) AS INT
            )
        END,
        -1
    ),
    COALESCE(
        CASE
            WHEN NULLIF(TRIM(datadiagnostico), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'  THEN CAST(
                TO_CHAR(
                    NULLIF(TRIM(datadiagnostico), '')::DATE,
                    'YYYYMMDD'
                ) AS INT
            )
        END,
        -1
    ),
    COALESCE(
        CASE
            WHEN COALESCE(
                NULLIF(TRIM(datacoleta_rt_pcr), '')::DATE,
                NULLIF(
                    TRIM(datacoletatesterapido),
                    ''
                )::DATE,
                NULLIF(TRIM(datacoletasorologia), '')::DATE,
                NULLIF(
                    TRIM(datacoletasorologiaigg),
                    ''
                )::DATE
            ) BETWEEN '2020-01-01' AND '2026-12-31'  THEN CAST(
                TO_CHAR(
                    COALESCE(
                        NULLIF(TRIM(datacoleta_rt_pcr), '')::DATE,
                        NULLIF(
                            TRIM(datacoletatesterapido),
                            ''
                        )::DATE,
                        NULLIF(TRIM(datacoletasorologia), '')::DATE,
                        NULLIF(
                            TRIM(datacoletasorologiaigg),
                            ''
                        )::DATE
                    ),
                    'YYYYMMDD'
                ) AS INT
            )
        END,
        -1
    ),
    COALESCE(
        CASE
            WHEN NULLIF(TRIM(dataencerramento), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'  THEN CAST(
                TO_CHAR(
                    NULLIF(TRIM(dataencerramento), '')::DATE,
                    'YYYYMMDD'
                ) AS INT
            )
        END,
        -1
    ),
    COALESCE(
        CASE
            WHEN NULLIF(TRIM(dataobito), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'  THEN CAST(
                TO_CHAR(
                    NULLIF(TRIM(dataobito), '')::DATE,
                    'YYYYMMDD'
                ) AS INT
            )
        END,
        -1
    ),
    COALESCE(dl.sk_local, -1),
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
        WHEN NULLIF(TRIM(dataencerramento), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'
        AND NULLIF(TRIM(datanotificacao), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'  THEN NULLIF(TRIM(dataencerramento), '')::DATE - NULLIF(TRIM(datanotificacao), '')::DATE
    END,
    CASE
        WHEN NULLIF(TRIM(dataobito), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'
        AND NULLIF(TRIM(datanotificacao), '')::DATE BETWEEN '2020-01-01' AND '2026-12-31'  THEN NULLIF(TRIM(dataobito), '')::DATE - NULLIF(TRIM(datanotificacao), '')::DATE
    END
FROM
    stg.notificacao_raw s
    LEFT JOIN dw.dim_localidade dl ON dl.municipio = COALESCE(
        NULLIF(TRIM(s.municipio), ''),
        'Desconhecido'
    )
    AND dl.bairro = COALESCE(
        NULLIF(TRIM(s.bairro), ''),
        'Desconhecido'
    )
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
