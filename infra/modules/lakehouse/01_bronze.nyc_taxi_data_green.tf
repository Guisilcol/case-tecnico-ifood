resource "aws_glue_catalog_table" "nyc_taxi_data_green" {
  database_name = aws_glue_catalog_database.bronze_db.name
  name          = "nyc_taxi_data_green"
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "parquet"
  }

  partition_keys {
    name    = "ano_mes_referencia"
    type    = "string"
    comment = "Ano/Mês de referência do registro"
  }

  storage_descriptor {
    location      = "${var.bronze_db_s3_location}/nyc_taxi_data_green/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "nyc_taxi_data_green"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name    = "vendorid"
      type    = "bigint"
      comment = "Identificador do fornecedor LPEP que forneceu o registro"
    }

    columns {
      name    = "lpep_pickup_datetime"
      type    = "timestamp"
      comment = "Data e hora em que o taxímetro foi acionado"
    }

    columns {
      name    = "lpep_dropoff_datetime"
      type    = "timestamp"
      comment = "Data e hora em que o taxímetro foi desligado"
    }

    columns {
      name    = "store_and_fwd_flag"
      type    = "string"
      comment = "Indica se o registro foi armazenado na memória do veículo antes de ser enviado (Y=sim, N=não)"
    }

    columns {
      name    = "ratecodeid"
      type    = "bigint"
      comment = "Código de tarifa final em vigor no final da viagem"
    }

    columns {
      name    = "pulocationid"
      type    = "bigint"
      comment = "Zona de táxi TLC onde o taxímetro foi acionado"
    }

    columns {
      name    = "dolocationid"
      type    = "bigint"
      comment = "Zona de táxi TLC onde o taxímetro foi desligado"
    }

    columns {
      name    = "passenger_count"
      type    = "bigint"
      comment = "Número de passageiros no veículo (valor informado pelo motorista)"
    }

    columns {
      name    = "trip_distance"
      type    = "double"
      comment = "Distância da viagem em milhas registrada pelo taxímetro"
    }

    columns {
      name    = "fare_amount"
      type    = "double"
      comment = "Tarifa calculada pelo taxímetro com base no tempo e distância"
    }

    columns {
      name    = "extra"
      type    = "double"
      comment = "Extras e sobretaxas diversos (inclui taxas de hora de pico e noturnas)"
    }

    columns {
      name    = "mta_tax"
      type    = "double"
      comment = "Taxa MTA acionada automaticamente com base na tarifa medida"
    }

    columns {
      name    = "tip_amount"
      type    = "double"
      comment = "Valor da gorjeta (preenchido automaticamente para gorjetas com cartão de crédito)"
    }

    columns {
      name    = "tolls_amount"
      type    = "double"
      comment = "Valor total de todos os pedágios pagos na viagem"
    }

    columns {
      name    = "ehail_fee"
      type    = "double"
      comment = "Taxa de serviço de e-hail"
    }

    columns {
      name    = "improvement_surcharge"
      type    = "double"
      comment = "Taxa de melhoria de $0.30 cobrada em viagens na bandeirada"
    }

    columns {
      name    = "total_amount"
      type    = "double"
      comment = "Valor total cobrado dos passageiros (não inclui gorjetas em dinheiro)"
    }

    columns {
      name    = "payment_type"
      type    = "bigint"
      comment = "Código numérico indicando como o passageiro pagou pela viagem"
    }

    columns {
      name    = "trip_type"
      type    = "bigint"
      comment = "Código indicando se a viagem foi uma corrida de rua ou despacho"
    }

    columns {
      name    = "congestion_surcharge"
      type    = "double"
      comment = "Sobretaxa de congestionamento cobrada em viagens"
    }

    columns {
      name    = "data_hora_ingestao"
      type    = "timestamp"
      comment = "Data e hora da ingestão do registro"
    }

  }
}
