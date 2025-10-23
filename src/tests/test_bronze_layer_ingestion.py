from pytest import fixture
from pyspark.sql import SparkSession
from databricks.connect.session import DatabricksSession
from jobs.bronze_layer_ingestion import Pipeline


@fixture(scope="session")
def spark() -> SparkSession:
    spark = DatabricksSession.builder.getOrCreate()
    return spark


@fixture
def pipeline(spark: SparkSession) -> Pipeline:
    dbutils = None
    source_prefix = "./tmp"
    target_table = "test_db.test_table"

    return Pipeline(spark, dbutils, source_prefix, target_table)


def test_lowercase_columns_names(pipeline: Pipeline):
    data = []
    df = pipeline.spark.createDataFrame(data, "NAME string, AGE int, city string")
    result_df = pipeline.lowercase_columns_names(df)

    expected_columns = ["name", "age", "city"]
    assert result_df.columns == expected_columns


def test_concatenate_dataframes(pipeline: Pipeline):
    data1 = [("Alice", 30), ("Bob", 25)]
    df1 = pipeline.spark.createDataFrame(data1, "name string, age int")

    data2 = [("Charlie", 35), ("David", 28)]
    df2 = pipeline.spark.createDataFrame(data2, "name string, age int")

    expected_df = pipeline.spark.createDataFrame(
        [("Alice", 30), ("Bob", 25), ("Charlie", 35), ("David", 28)],
        "name string, age int",
    )

    result_df = pipeline.concatenate_dataframes([df1, df2])
    assert result_df.collect() == expected_df.collect()


def test_equalize_schemas(pipeline: Pipeline):
    data = [("Alice", 30), ("Bob", 25)]
    df = pipeline.spark.createDataFrame(data, "name string, age int")

    target_data = [("Charlie", 35, "New York"), ("David", 28, "Los Angeles")]
    target_df = pipeline.spark.createDataFrame(
        target_data, "name string, age int, city string"
    )

    result_df = pipeline.equalize_schemas(df, target_df)

    expected_data = [("Alice", 30, None), ("Bob", 25, None)]
    expected_df = pipeline.spark.createDataFrame(
        expected_data, "name string, age int, city string"
    )

    assert result_df.schema == expected_df.schema
