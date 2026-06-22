SELECT 
    municipio, 
    mes, 
    SUM(total_notificacoes) AS total
FROM mart.mv_resumo_municipio_mes
GROUP BY municipio, mes
ORDER BY municipio, mes;