resource "aws_glue_catalog_table" "nyc_taxi_data_highvolumeforhire" {
  database_name = aws_glue_catalog_database.bronze_db.name
  name          = "nyc_taxi_data_highvolumeforhire"
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
    location      = "${var.bronze_db_s3_location}/nyc_taxi_data_highvolumeforhire/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "nyc_taxi_data_highvolumeforhire"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name    = "hvfhs_license_num"
      type    = "string"
      comment = "Número de licença da base HVFHS (High Volume For-Hire Services)"
    }

    columns {
      name    = "dispatching_base_num"
      type    = "string"
      comment = "Número de licença da base de despacho TLC que enviou o veículo"
    }

    columns {
      name    = "originating_base_num"
      type    = "string"
      comment = "Número de base onde a solicitação de viagem foi recebida"
    }

    columns {
      name    = "request_datetime"
      type    = "timestamp"
      comment = "Data e hora em que o passageiro solicitou a viagem"
    }

    columns {
      name    = "on_scene_datetime"
      type    = "timestamp"
      comment = "Data e hora em que o motorista chegou ao local de embarque"
    }

    columns {
      name    = "pickup_datetime"
      type    = "timestamp"
      comment = "Data e hora em que o passageiro foi embarcado"
    }

    columns {
      name    = "dropoff_datetime"
      type    = "timestamp"
      comment = "Data e hora em que o passageiro foi desembarcado"
    }

    columns {
      name    = "pulocationid"
      type    = "bigint"
      comment = "Zona de táxi TLC onde o passageiro foi embarcado"
    }

    columns {
      name    = "dolocationid"
      type    = "bigint"
      comment = "Zona de táxi TLC onde o passageiro foi desembarcado"
    }

    columns {
      name    = "trip_miles"
      type    = "double"
      comment = "Distância total da viagem em milhas"
    }

    columns {
      name    = "trip_time"
      type    = "bigint"
      comment = "Tempo total da viagem em segundos"
    }

    columns {
      name    = "base_passenger_fare"
      type    = "double"
      comment = "Tarifa base cobrada do passageiro"
    }

    columns {
      name    = "tolls"
      type    = "double"
      comment = "Valor total de pedágios pagos durante a viagem"
    }

    columns {
      name    = "bcf"
      type    = "double"
      comment = "Taxa BCF (Black Car Fund) cobrada na viagem"
    }

    columns {
      name    = "sales_tax"
      type    = "double"
      comment = "Imposto sobre vendas aplicado à viagem"
    }

    columns {
      name    = "congestion_surcharge"
      type    = "double"
      comment = "Sobretaxa de congestionamento cobrada em viagens"
    }

    columns {
      name    = "airport_fee"
      type    = "double"
      comment = "Taxa de aeroporto aplicável para viagens de/para aeroportos"
    }

    columns {
      name    = "tips"
      type    = "double"
      comment = "Valor da gorjeta paga pelo passageiro"
    }

    columns {
      name    = "driver_pay"
      type    = "double"
      comment = "Valor total pago ao motorista pela viagem"
    }

    columns {
      name    = "shared_request_flag"
      type    = "string"
      comment = "Indica se o passageiro solicitou uma viagem compartilhada"
    }

    columns {
      name    = "shared_match_flag"
      type    = "string"
      comment = "Indica se a viagem foi correspondida com outro passageiro para compartilhamento"
    }

    columns {
      name    = "access_a_ride_flag"
      type    = "string"
      comment = "Indica se a viagem foi pelo programa Access-A-Ride"
    }

    columns {
      name    = "wav_request_flag"
      type    = "string"
      comment = "Indica se o passageiro solicitou um veículo acessível para cadeira de rodas (WAV)"
    }

    columns {
      name    = "wav_match_flag"
      type    = "string"
      comment = "Indica se um veículo acessível para cadeira de rodas (WAV) foi designado"
    }

    columns {
      name    = "data_hora_ingestao"
      type    = "timestamp"
      comment = "Data e hora da ingestão do registro"
    }

  }
}
