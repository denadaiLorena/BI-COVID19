SELECT 
    'Pulmão' AS comorbidade, SUM(c.com_pulmao) AS total FROM dw.dim_comorbidade c 
    JOIN dw.fato_notificacao_covid f ON c.sk_comorbidade = f.sk_como WHERE f.flag_obito_covid = 1
UNION ALL
SELECT 'Cardio', SUM(c.com_cardio) FROM dw.dim_comorbidade c 
    JOIN dw.fato_notificacao_covid f ON c.sk_comorbidade = f.sk_como WHERE f.flag_obito_covid = 1
UNION ALL
SELECT 'Diabetes', SUM(c.com_diabetes) FROM dw.dim_comorbidade c 
    JOIN dw.fato_notificacao_covid f ON c.sk_comorbidade = f.sk_como WHERE f.flag_obito_covid = 1
UNION ALL
SELECT 'Obesidade', SUM(c.com_obesidade) FROM dw.dim_comorbidade c 
    JOIN dw.fato_notificacao_covid f ON c.sk_comorbidade = f.sk_como WHERE f.flag_obito_covid = 1
UNION ALL
SELECT 'Renal', SUM(c.com_renal) FROM dw.dim_comorbidade c 
    JOIN dw.fato_notificacao_covid f ON c.sk_comorbidade = f.sk_como WHERE f.flag_obito_covid = 1
ORDER BY total DESC
LIMIT 5;