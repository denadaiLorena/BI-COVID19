SELECT 
    p.faixa_etaria, 
    p.sexo, 
    COUNT(*) AS total_obitos
FROM dw.fato_notificacao_covid f
JOIN dw.dim_perfil_paciente p ON f.sk_perfil = p.sk_perfil
WHERE f.flag_obito_covid = 1
GROUP BY p.faixa_etaria, p.sexo
ORDER BY p.faixa_etaria, p.sexo;