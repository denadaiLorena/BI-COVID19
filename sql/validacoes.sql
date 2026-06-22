-- ============================================================
-- Q1: Casos confirmados por município e mês (2021 e 2022)
-- Mostra quais municípios tiveram mais casos confirmados
-- e como evoluiu mês a mês
-- ============================================================
SELECT
    l.municipio,
    t.ano_mes,
    SUM(f.flag_confirmado) AS confirmados,
    SUM(f.qtd_notificacao) AS notificacoes_total
FROM dw.fato_notificacao_covid f
JOIN dw.dim_localidade l ON l.sk_local = f.sk_local
JOIN dw.dim_tempo t ON t.sk_tempo = f.sk_data_notificacao
WHERE t.ano IN (2021, 2022)
GROUP BY l.municipio, t.ano_mes
ORDER BY confirmados DESC
LIMIT 20;


-- ============================================================
-- Q2: Letalidade por faixa etária
-- Calcula o percentual de óbitos entre os casos confirmados
-- para cada faixa etária — revela quais grupos foram mais afetados
-- ============================================================
SELECT
    p.faixa_etaria,
    SUM(f.flag_confirmado) AS confirmados,
    SUM(f.flag_obito_covid) AS obitos,
    ROUND(100.0 * SUM(f.flag_obito_covid)
        / NULLIF(SUM(f.flag_confirmado), 0), 2) AS letalidade_pct
FROM dw.fato_notificacao_covid f
JOIN dw.dim_perfil_paciente p ON p.sk_perfil = f.sk_perfil
GROUP BY p.faixa_etaria
ORDER BY letalidade_pct DESC;


-- ============================================================
-- Q3: Sintomas mais associados à internação
-- Verifica quais combinações de sintomas (febre, tosse,
-- dificuldade respiratória) resultaram em mais internações
-- ============================================================
SELECT
    s.febre,
    s.tosse,
    s.dif_respiratoria,
    SUM(f.flag_internado) AS internacoes,
    SUM(f.qtd_notificacao) AS casos
FROM dw.fato_notificacao_covid f
JOIN dw.dim_sintomas s ON s.sk_sint = f.sk_sint
GROUP BY s.febre, s.tosse, s.dif_respiratoria
HAVING SUM(f.qtd_notificacao) > 1000
ORDER BY internacoes DESC
LIMIT 10;


-- ============================================================
-- Q4: Tempo médio entre notificação e encerramento por município
-- Mede a eficiência do sistema de saúde em cada município —
-- quanto menor o número de dias, mais rápido foi o encerramento do caso
-- ============================================================
SELECT
    l.municipio,
    ROUND(AVG(f.dias_notif_encerramento)::numeric, 1) AS dias_medio,
    COUNT(*) AS casos
FROM dw.fato_notificacao_covid f
JOIN dw.dim_localidade l ON l.sk_local = f.sk_local
WHERE f.dias_notif_encerramento IS NOT NULL
  AND f.dias_notif_encerramento BETWEEN 0 AND 180
GROUP BY l.municipio
HAVING COUNT(*) > 500
ORDER BY dias_medio DESC;


-- ============================================================
-- Q5: Impacto de comorbidades na letalidade
-- Analisa se pacientes com doenças cardíacas, diabetes
-- e obesidade tiveram maior taxa de óbitos por COVID
-- ============================================================
SELECT
    c.com_cardio,
    c.com_diabetes,
    c.com_obesidade,
    SUM(f.flag_confirmado) AS confirmados,
    SUM(f.flag_obito_covid) AS obitos,
    ROUND(100.0 * SUM(f.flag_obito_covid)
        / NULLIF(SUM(f.flag_confirmado), 0), 2) AS letalidade_pct
FROM dw.fato_notificacao_covid f
JOIN dw.dim_comorbidade c ON c.sk_como = f.sk_como
GROUP BY c.com_cardio, c.com_diabetes, c.com_obesidade
ORDER BY letalidade_pct DESC
LIMIT 15;
