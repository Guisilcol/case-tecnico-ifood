import re
import sys

import pyspark.sql.functions as F
from databricks.sdk import WorkspaceClient


from pyspark.sql import SparkSession, DataFrame
from databricks.sdk.dbutils import RemoteDbUtils


class Pipeline:
    def __init__(
        self,
        spark: "SparkSession",
        dbutils: "RemoteDbUtils",
        source_prefix: "str",
        target_table: "str",
    ):
        self.spark = spark
        self.dbutils = dbutils
        self.source_prefix = source_prefix
        self.target_table = target_table

    def cast_columns_to_string(self, df: "DataFrame") -> "DataFrame":
        for column in df.columns:
            df = df.withColumn(column, F.col(column).cast("string"))
        return df

    def concatenate_dataframes(self, dfs: "list[DataFrame]") -> "DataFrame":
        df = dfs[0]
        for other_df in dfs[1:]:
            df = df.unionByName(other_df, allowMissingColumns=True)
        return df

    def lowercase_columns_names(self, df: "DataFrame") -> "DataFrame":
        for column in df.columns:
            df = df.withColumnRenamed(column, column.lower())

        return df

    def equalize_schemas(self, df: "DataFrame", target_df: "DataFrame") -> "DataFrame":
        for field in target_df.schema.fields:
            if field.name not in df.columns:
                df = df.withColumn(field.name, F.lit(None).cast(field.dataType))

            df = df.withColumn(field.name, F.col(field.name).cast(field.dataType))

        df = df.select([field.name for field in target_df.schema.fields])

        return df

    def run(self):
        target_df = self.spark.read.table(self.target_table)
        files = self.dbutils.fs.ls(f"{self.source_prefix}/")

        # Lê arquivo por arquivo e faz o cast de todas as colunas para string
        dfs: "list[DataFrame]" = []
        for file in files:

            # Extrai o "ano_mes_referencia=YYYY-MM" do nome do arquivo (file)
            partition = re.search(r"ano_mes_referencia=\d{4}-\d{2}", file.path)
            if not partition:
                raise ValueError(
                    f"Não foi possível extrair a partição do arquivo: {file.path}"
                )

            partition_value = partition.group(0).split("=")[1]
            df = self.spark.read.parquet(file.path, mergeSchema=True)
            df = df.withColumn("ano_mes_referencia", F.lit(partition_value))
            df = self.cast_columns_to_string(df)
            df = self.lowercase_columns_names(df)
            dfs.append(df)

        df = self.concatenate_dataframes(dfs)
        df = df.withColumn("data_hora_ingestao", F.current_timestamp())

        df = self.equalize_schemas(df, target_df)
        df.write.mode("overwrite").insertInto(self.target_table)


def main():
    table_name = sys.argv[1]
    source_prefix = sys.argv[2]

    dbutils = WorkspaceClient().dbutils
    spark = SparkSession.getActiveSession()
    pipeline = Pipeline(
        spark, dbutils, source_prefix=source_prefix, target_table=table_name
    )
    pipeline.run()


if __name__ == "__main__":
    import traceback

    try:
        main()
    except Exception as e:
        print(traceback.format_exc())
        sys.exit(1)
