-- Criação da tabela bronze: nyc_taxi_data_highvolumeforhire
-- Tabela bronze com dados de High Volume For-Hire Services (HVFHS) de NYC

CREATE TABLE IF NOT EXISTS bronze_db.nyc_taxi_data_highvolumeforhire (
  hvfhs_license_num STRING COMMENT 'Número de licença da base HVFHS (High Volume For-Hire Services)',
  dispatching_base_num STRING COMMENT 'Número de licença da base de despacho TLC que enviou o veículo',
  originating_base_num STRING COMMENT 'Número de base onde a solicitação de viagem foi recebida',
  request_datetime TIMESTAMP COMMENT 'Data e hora em que o passageiro solicitou a viagem',
  on_scene_datetime TIMESTAMP COMMENT 'Data e hora em que o motorista chegou ao local de embarque',
  pickup_datetime TIMESTAMP COMMENT 'Data e hora em que o passageiro foi embarcado',
  dropoff_datetime TIMESTAMP COMMENT 'Data e hora em que o passageiro foi desembarcado',
  pulocationid DOUBLE COMMENT 'Zona de táxi TLC onde o passageiro foi embarcado',
  dolocationid DOUBLE COMMENT 'Zona de táxi TLC onde o passageiro foi desembarcado',
  trip_miles DOUBLE COMMENT 'Distância total da viagem em milhas',
  trip_time DOUBLE COMMENT 'Tempo total da viagem em segundos',
  base_passenger_fare DOUBLE COMMENT 'Tarifa base cobrada do passageiro',
  tolls DOUBLE COMMENT 'Valor total de pedágios pagos durante a viagem',
  bcf DOUBLE COMMENT 'Taxa BCF (Black Car Fund) cobrada na viagem',
  sales_tax DOUBLE COMMENT 'Imposto sobre vendas aplicado à viagem',
  congestion_surcharge DOUBLE COMMENT 'Sobretaxa de congestionamento cobrada em viagens',
  airport_fee DOUBLE COMMENT 'Taxa de aeroporto aplicável para viagens de/para aeroportos',
  tips DOUBLE COMMENT 'Valor da gorjeta paga pelo passageiro',
  driver_pay DOUBLE COMMENT 'Valor total pago ao motorista pela viagem',
  shared_request_flag STRING COMMENT 'Indica se o passageiro solicitou uma viagem compartilhada',
  shared_match_flag STRING COMMENT 'Indica se a viagem foi correspondida com outro passageiro para compartilhamento',
  access_a_ride_flag STRING COMMENT 'Indica se a viagem foi pelo programa Access-A-Ride',
  wav_request_flag STRING COMMENT 'Indica se o passageiro solicitou um veículo acessível para cadeira de rodas (WAV)',
  wav_match_flag STRING COMMENT 'Indica se um veículo acessível para cadeira de rodas (WAV) foi designado',
  data_hora_ingestao TIMESTAMP COMMENT 'Data e hora da ingestão do registro',
  ano_mes_referencia STRING COMMENT 'Ano/Mês de referência do registro'
)
COMMENT 'Tabela bronze com dados de High Volume For-Hire Services (HVFHS) de NYC';
