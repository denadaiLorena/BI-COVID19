-- 1. CRIAÇÃO DA MATERIALIZED VIEW NO SCHEMA MART
DROP MATERIALIZED VIEW IF EXISTS mart.mv_resumo_municipio_mes CASCADE;

CREATE MATERIALIZED VIEW mart.mv_resumo_municipio_mes AS
SELECT
    m.municipio,
    t.ano_mes,
    t.ano,
    t.mes,
    SUM(f.flag_confirmado) AS total_confirmados,
    SUM(f.flag_obito_covid) AS total_obitos,
    SUM(f.flag_internado) AS total_internacoes,
    SUM(f.qtd_notificacao) AS total_notificacoes
FROM dw.fato_notificacao_covid f
JOIN dw.dim_bairro b ON b.sk_bairro = f.sk_bairro
JOIN dw.dim_municipio m ON m.sk_municipio = b.fk_municipio
JOIN dw.dim_tempo t ON t.sk_tempo = f.sk_data_notificacao
GROUP BY m.municipio, t.ano_mes, t.ano, t.mes
WITH DATA;

-- Criando um índice na view para acelerar filtros por município/período
CREATE INDEX idx_mv_municipio_mes ON mart.mv_resumo_municipio_mes (municipio, ano_mes);


-- =============================================================================
-- 2. QUERIES DE AVALIAÇÃO DE PERFORMANCE (PARA ANALISAR COM EXPLAIN)
-- =============================================================================

-- Query A: Consulta direto na Fato (Modelo Floco de Neve original)
-- EXPLAIN ANALYZE
SELECT m.municipio, t.ano_mes, SUM(f.flag_confirmado) 
FROM dw.fato_notificacao_covid f
JOIN dw.dim_bairro b ON b.sk_bairro = f.sk_bairro
JOIN dw.dim_municipio m ON m.sk_municipio = b.fk_municipio
JOIN dw.dim_tempo t ON t.sk_tempo = f.sk_data_notificacao
WHERE m.municipio = 'SERRA'
GROUP BY m.municipio, t.ano_mes;

-- Query B: Mesma consulta utilizando o Data Mart Pré-Agregado
-- EXPLAIN ANALYZE
SELECT municipio, ano_mes, total_confirmados 
FROM mart.mv_resumo_municipio_mes
WHERE municipio = 'SERRA';
