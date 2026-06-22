SELECT 
    t.data AS data_completa, 
    SUM(f.qtd_notificacao) AS total_notificacoes
FROM dw.fato_notificacao_covid f
JOIN dw.dim_tempo t ON f.sk_data_notificacao = t.sk_tempo
GROUP BY t.data
ORDER BY t.data;
