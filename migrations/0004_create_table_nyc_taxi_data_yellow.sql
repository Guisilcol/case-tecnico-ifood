-- Criação da tabela bronze: nyc_taxi_data_yellow
-- Tabela bronze com dados de táxis amarelos de NYC

CREATE TABLE IF NOT EXISTS bronze_db.nyc_taxi_data_yellow (
  vendorid DOUBLE COMMENT 'Identificador do fornecedor TPEP que forneceu o registro',
  tpep_pickup_datetime TIMESTAMP COMMENT 'Data e hora em que o taxímetro foi acionado',
  tpep_dropoff_datetime TIMESTAMP COMMENT 'Data e hora em que o taxímetro foi desligado',
  passenger_count DOUBLE COMMENT 'Número de passageiros no veículo (valor informado pelo motorista)',
  trip_distance DOUBLE COMMENT 'Distância da viagem em milhas registrada pelo taxímetro',
  ratecodeid DOUBLE COMMENT 'Código de tarifa final em vigor no final da viagem',
  store_and_fwd_flag STRING COMMENT 'Indica se o registro foi armazenado na memória do veículo antes de ser enviado (Y=sim, N=não)',
  pulocationid DOUBLE COMMENT 'Zona de táxi TLC onde o taxímetro foi acionado',
  dolocationid DOUBLE COMMENT 'Zona de táxi TLC onde o taxímetro foi desligado',
  payment_type DOUBLE COMMENT 'Código numérico indicando como o passageiro pagou pela viagem',
  fare_amount DOUBLE COMMENT 'Tarifa calculada pelo taxímetro com base no tempo e distância',
  extra DOUBLE COMMENT 'Extras e sobretaxas diversos (inclui taxas de hora de pico e noturnas)',
  mta_tax DOUBLE COMMENT 'Taxa MTA acionada automaticamente com base na tarifa medida',
  tip_amount DOUBLE COMMENT 'Valor da gorjeta (preenchido automaticamente para gorjetas com cartão de crédito)',
  tolls_amount DOUBLE COMMENT 'Valor total de todos os pedágios pagos na viagem',
  improvement_surcharge DOUBLE COMMENT 'Taxa de melhoria de $0.30 cobrada em viagens na bandeirada',
  total_amount DOUBLE COMMENT 'Valor total cobrado dos passageiros (não inclui gorjetas em dinheiro)',
  congestion_surcharge DOUBLE COMMENT 'Sobretaxa de congestionamento cobrada em viagens',
  airport_fee DOUBLE COMMENT 'Taxa de aeroporto aplicável para viagens de/para aeroportos',
  data_hora_ingestao TIMESTAMP COMMENT 'Data e hora da ingestão do registro.',
  ano_mes_referencia STRING COMMENT 'Ano/Mês de referência do registro'
)
COMMENT 'Tabela bronze com dados de táxis amarelos de NYC';
