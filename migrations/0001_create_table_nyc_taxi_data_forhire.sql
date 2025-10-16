-- Criação da tabela bronze: nyc_taxi_data_forhire
-- Tabela bronze com dados de For-Hire Vehicles (FHV) de NYC

CREATE TABLE IF NOT EXISTS bronze_db.nyc_taxi_data_forhire (
  dispatching_base_num STRING COMMENT 'Número de licença da base de despacho TLC que enviou o veículo',
  pickup_datetime TIMESTAMP COMMENT 'Data e hora em que o passageiro foi embarcado',
  dropoff_datetime TIMESTAMP COMMENT 'Data e hora em que o passageiro foi desembarcado',
  pulocationid DOUBLE COMMENT 'Zona de táxi TLC onde o passageiro foi embarcado',
  dolocationid DOUBLE COMMENT 'Zona de táxi TLC onde o passageiro foi desembarcado',
  sr_flag DOUBLE COMMENT 'Indica se a viagem foi uma solicitação compartilhada (shared ride)',
  affiliated_base_number STRING COMMENT 'Número de licença da base afiliada ao despacho',
  data_hora_ingestao TIMESTAMP COMMENT 'Data e hora da ingestão do registro',
  ano_mes_referencia STRING COMMENT 'Ano/Mês de referência do registro'
)
COMMENT 'Tabela bronze com dados de For-Hire Vehicles (FHV) de NYC';
