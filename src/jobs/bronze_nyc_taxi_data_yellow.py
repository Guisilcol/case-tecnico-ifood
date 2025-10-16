from pyspark.sql import SparkSession, types as T

spark = SparkSession.builder.getOrCreate()


class Pipeline:
    def run(self):
        schema = T.StructType(
            [
                T.StructField("VendorID", T.LongType(), True),
                T.StructField("tpep_pickup_datetime", T.TimestampType(), True),
                T.StructField("tpep_dropoff_datetime", T.TimestampType(), True),
                T.StructField("passenger_count", T.LongType(), True),
                T.StructField("trip_distance", T.DoubleType(), True),
                T.StructField("RatecodeID", T.LongType(), True),
                T.StructField("store_and_fwd_flag", T.StringType(), True),
                T.StructField("PULocationID", T.LongType(), True),
                T.StructField("DOLocationID", T.LongType(), True),
                T.StructField("payment_type", T.LongType(), True),
                T.StructField("fare_amount", T.DoubleType(), True),
                T.StructField("extra", T.DoubleType(), True),
                T.StructField("mta_tax", T.DoubleType(), True),
                T.StructField("tip_amount", T.DoubleType(), True),
                T.StructField("tolls_amount", T.DoubleType(), True),
                T.StructField("improvement_surcharge", T.DoubleType(), True),
                T.StructField("total_amount", T.DoubleType(), True),
                T.StructField("congestion_surcharge", T.DoubleType(), True),
                T.StructField("airport_fee", T.DoubleType(), True),
            ]
        )

        df = spark.read.schema(schema).parquet(
            "s3://bucket-landing-zone-241963575180/nyc_taxi_data_yellow/"
        )
        df.write.insertInto("bronze_db.nyc_taxi_data_yellow", overwrite=True)


def main():
    pipeline = Pipeline()
    pipeline.run()


if __name__ == "__main__":
    import sys
    import traceback

    try:
        main()
    except Exception as e:
        print(traceback.format_exc())
        sys.exit(1)
