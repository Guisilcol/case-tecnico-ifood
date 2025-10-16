resource "aws_glue_catalog_table" "nyc_taxi_data_forhire" {
  database_name = aws_glue_catalog_database.bronze_db.name
  name          = "nyc_taxi_data_forhire"
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
    location      = "${var.bronze_db_s3_location}/nyc_taxi_data_forhire"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "nyc_taxi_data_forhire"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name    = "dispatching_base_num"
      type    = "string"
      comment = "Número de licença da base de despacho TLC que enviou o veículo"
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
      name    = "sr_flag"
      type    = "bigint"
      comment = "Indica se a viagem foi uma solicitação compartilhada (shared ride)"
    }

    columns {
      name    = "affiliated_base_number"
      type    = "string"
      comment = "Número de licença da base afiliada ao despacho"
    }

    columns {
      name    = "data_hora_ingestao"
      type    = "timestamp"
      comment = "Data e hora da ingestão do registro"
    }

  }
}
