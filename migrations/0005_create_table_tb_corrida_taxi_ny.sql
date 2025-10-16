CREATE TABLE IF NOT EXISTS silver_db.tb_corrida_taxi_ny (
    id STRING NOT NULL,
    id_fornecedor DOUBLE,
    nome_fornecedor STRING NOT NULL,
    quantidade_passageiros DOUBLE,
    valor_corrida DOUBLE,
    data_hora_embarque TIMESTAMP,
    data_hora_desembarque TIMESTAMP,
    indicador_cancelamento STRING NOT NULL,
    indicador_viagem_sem_cobranca STRING NOT NULL,
    id_tipo_pagamento DOUBLE,
    descricao_tipo_pagamento STRING NOT NULL,
    tipo_servico STRING NOT NULL,
    data_hora_criacao_registro TIMESTAMP NOT NULL,
    ano_mes_referencia STRING
)
COMMENT 'Tabela silver contendo corridas de táxis em NY Yellow e Green unificadas';