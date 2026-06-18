DROP TABLE IF EXISTS dw.fato_exame CASCADE;
CREATE TABLE dw.fato_exame (
    sk_fato_exame BIGSERIAL PRIMARY KEY,
    
    -- Dimensões em Conformidade (Conformed Dimensions)
    sk_data_coleta INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_bairro INT NOT NULL REFERENCES dw.dim_bairro(sk_bairro),         -- DIM_LOCALIDADE
    sk_perfil INT NOT NULL REFERENCES dw.dim_perfil_paciente(sk_perfil), -- DIM_PERFIL_PACIENTE
    
    -- Atributos do Exame
    tipo_exame VARCHAR(50) NOT NULL, -- 'RT-PCR', 'Teste Rápido', 'Sorologia', 'Sorologia IGG'
    resultado_exame VARCHAR(50) NOT NULL, -- 'Positivo', 'Negativo', 'Inconclusivo', etc.
    tipo_teste_rapido VARCHAR(60) NOT NULL, -- Especificação se for teste rápido
    
    -- Métrica
    qtd_exames SMALLINT NOT NULL DEFAULT 1
);

-- Índices para performance
CREATE INDEX idx_fato_exame_data ON dw.fato_exame(sk_data_coleta);
CREATE INDEX idx_fato_exame_bairro ON dw.fato_exame(sk_bairro);