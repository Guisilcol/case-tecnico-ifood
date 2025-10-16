import sys

from pyspark.sql import SparkSession, functions as F, DataFrame


class Pipeline:
    def __init__(
        self,
        spark: "SparkSession",
    ):
        self.spark = spark

    def compute_yellow(self) -> "DataFrame":
        df = self.spark.read.table("bronze_db.nyc_taxi_data_yellow")
        df = df.selectExpr(
            "vendorid as id_fornecedor",
            "passenger_count as quantidade_passageiros",
            "total_amount as valor_corrida",
            "tpep_pickup_datetime as data_hora_embarque",
            "tpep_dropoff_datetime as data_hora_desembarque",
            "payment_type as id_tipo_pagamento",
            "ano_mes_referencia",
            '"YELLOW" as tipo_servico',
        )

        return df

    def compute_green(self) -> "DataFrame":
        df = self.spark.read.table("bronze_db.nyc_taxi_data_green")
        df = df.selectExpr(
            "vendorid as id_fornecedor",
            "passenger_count as quantidade_passageiros",
            "total_amount as valor_corrida",
            "lpep_pickup_datetime as data_hora_embarque",
            "lpep_dropoff_datetime as data_hora_desembarque",
            "payment_type as id_tipo_pagamento",
            "ano_mes_referencia",
            '"GREEN" as tipo_servico',
        )

        return df

    def compute_unified(
        self, yellow_df: "DataFrame", green_df: "DataFrame"
    ) -> "DataFrame":
        df = yellow_df.union(green_df)

        df = df.withColumn(
            "nome_fornecedor",
            F.when(F.col("id_fornecedor") == 1, "Creative Mobile Technologies, LLC")
            .when(F.col("id_fornecedor") == 2, "Curb Mobility, LLC")
            .when(F.col("id_fornecedor") == 6, "Myle Technologies Inc")
            .when(F.col("id_fornecedor") == 7, "Helix")
            .otherwise("FORNECEDOR NÃO IDENTIFICADO"),
        )

        df = df.withColumn(
            "descricao_tipo_pagamento",
            F.when(F.col("id_tipo_pagamento") == 0, "Viagem com tarifa flexível")
            .when(F.col("id_tipo_pagamento") == 1, "Cartão de crédito")
            .when(F.col("id_tipo_pagamento") == 2, "Dinheiro")
            .when(F.col("id_tipo_pagamento") == 3, "Sem cobrança")
            .when(F.col("id_tipo_pagamento") == 4, "Contestação")
            .when(F.col("id_tipo_pagamento") == 5, "Desconhecido")
            .when(F.col("id_tipo_pagamento") == 6, "Viagem cancelada")
            .otherwise("TIPO DE PAGAMENTO NÃO IDENTIFICADO"),
        )

        df = df.withColumn(
            "indicador_cancelamento",
            F.when(F.col("id_tipo_pagamento") == 6, "S").otherwise("N"),
        )
        df = df.withColumn(
            "indicador_viagem_sem_cobranca",
            F.when(F.col("id_tipo_pagamento") == 3, "S").otherwise("N"),
        )
        df = df.withColumn("id", F.expr("uuid()"))
        df = df.withColumn("data_hora_criacao_registro", F.current_timestamp())

        df = df.select(
            "id",
            "id_fornecedor",
            "nome_fornecedor",
            "quantidade_passageiros",
            "valor_corrida",
            "data_hora_embarque",
            "data_hora_desembarque",
            "indicador_cancelamento",
            "indicador_viagem_sem_cobranca",
            "id_tipo_pagamento",
            "descricao_tipo_pagamento",
            "tipo_servico",
            "ano_mes_referencia",
            "data_hora_criacao_registro",
        )
        return df

    def run(self):
        yellow_df = self.compute_yellow()
        green_df = self.compute_green()
        df = self.compute_unified(yellow_df, green_df)

        df.write.insertInto("silver_db.tb_corrida_taxi_ny", overwrite=True)


def main():
    spark = SparkSession.getActiveSession()
    pipeline = Pipeline(spark)
    pipeline.run()


if __name__ == "__main__":
    import traceback

    try:
        main()
    except Exception as e:
        print(traceback.format_exc())
        sys.exit(1)
