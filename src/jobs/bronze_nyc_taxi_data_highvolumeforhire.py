import re
from dataclasses import dataclass
from datetime import datetime
from typing import Iterator, List

import awswrangler as wr
import boto3
import pandas as pd

from shared.glue_resolved_args import GlueResolvedArgs


@dataclass
class Arguments(GlueResolvedArgs):
    source_path: "str"
    target_db: "str"
    target_table: "str"


class Pipeline:
    def __init__(self, args: "Arguments"):
        self.args = args
        self.boto3_session = boto3.Session()

    def extract_year_month_from_path(self, path: str) -> str:
        """Extract year_month_reference from file path."""
        match = re.search(r"ano_mes_referencia=([^/]+)", path)
        return match.group(1) if match else None

    def discover_partitions(self) -> List[str]:
        s3_path = self.args.source_path
        if not s3_path.endswith("/"):
            s3_path += "/"

        print("> Descobrindo partições disponíveis...")

        all_files = wr.s3.list_objects(
            path=s3_path, boto3_session=self.boto3_session, suffix=".parquet"
        )

        print(f"> Encontrados {len(all_files)} arquivos parquet no total")

        # Extract unique partitions from file paths
        partitions = set()
        for file_path in all_files:
            partition = self.extract_year_month_from_path(file_path)
            if partition:
                partitions.add(partition)

        partitions_list = sorted(list(partitions))
        print(f"> Encontradas {len(partitions_list)} partições: {partitions_list}")

        return partitions_list

    def list_parquet_files_for_partition(self, year_month_reference: str) -> List[str]:
        """List parquet files for a specific partition."""
        s3_path = self.args.source_path
        if not s3_path.endswith("/"):
            s3_path += "/"

        # Add partition path
        partition_path = f"{s3_path}ano_mes_referencia={year_month_reference}/"

        files = wr.s3.list_objects(
            path=partition_path, boto3_session=self.boto3_session, suffix=".parquet"
        )
        return files

    def compute_raw(self, year_month_reference: str) -> "Iterator[pd.DataFrame]":
        """Read and process raw data for a specific partition."""
        print(f"> Listando arquivos parquet para partição {year_month_reference}...")
        files = self.list_parquet_files_for_partition(year_month_reference)

        if not files:
            raise ValueError(
                f"No parquet files found for partition {year_month_reference}"
            )

        print(f"> Encontrados {len(files)} arquivos parquet")

        dfs = wr.s3.read_parquet(
            path=files,
            boto3_session=self.boto3_session,
            path_suffix=".parquet",
            use_threads=False,
            chunked=1_000_000,
        )

        # df = pd.concat(dfs, ignore_index=True)

        # df["ano_mes_referencia"] = year_month_reference

        return dfs

    def compute_transformed(self, df: "pd.DataFrame") -> "pd.DataFrame":

        print(f"> Dados lidos: {len(df)} linhas")

        # Rename columns to lowercase and standardize naming
        df = df.rename(
            columns={
                "hvfhs_license_num": "hvfhs_license_num",
                "dispatching_base_num": "dispatching_base_num",
                "originating_base_num": "originating_base_num",
                "request_datetime": "request_datetime",
                "on_scene_datetime": "on_scene_datetime",
                "pickup_datetime": "pickup_datetime",
                "dropoff_datetime": "dropoff_datetime",
                "PULocationID": "pulocationid",
                "DOLocationID": "dolocationid",
                "trip_miles": "trip_miles",
                "trip_time": "trip_time",
                "base_passenger_fare": "base_passenger_fare",
                "tolls": "tolls",
                "bcf": "bcf",
                "sales_tax": "sales_tax",
                "congestion_surcharge": "congestion_surcharge",
                "airport_fee": "airport_fee",
                "tips": "tips",
                "driver_pay": "driver_pay",
                "shared_request_flag": "shared_request_flag",
                "shared_match_flag": "shared_match_flag",
                "access_a_ride_flag": "access_a_ride_flag",
                "wav_request_flag": "wav_request_flag",
                "wav_match_flag": "wav_match_flag",
            }
        )

        # Apply schema transformations based on the Spark schema provided
        df["hvfhs_license_num"] = df["hvfhs_license_num"].astype("string")
        df["dispatching_base_num"] = df["dispatching_base_num"].astype("string")
        df["originating_base_num"] = df["originating_base_num"].astype("string")
        df["request_datetime"] = pd.to_datetime(df["request_datetime"], errors="coerce")
        df["on_scene_datetime"] = pd.to_datetime(
            df["on_scene_datetime"], errors="coerce"
        )
        df["pickup_datetime"] = pd.to_datetime(df["pickup_datetime"], errors="coerce")
        df["dropoff_datetime"] = pd.to_datetime(df["dropoff_datetime"], errors="coerce")
        df["pulocationid"] = pd.to_numeric(df["pulocationid"], errors="coerce").astype(
            "Int64"
        )
        df["dolocationid"] = pd.to_numeric(df["dolocationid"], errors="coerce").astype(
            "Int64"
        )
        df["trip_miles"] = pd.to_numeric(df["trip_miles"], errors="coerce")
        df["trip_time"] = pd.to_numeric(df["trip_time"], errors="coerce").astype(
            "Int64"
        )
        df["base_passenger_fare"] = pd.to_numeric(
            df["base_passenger_fare"], errors="coerce"
        )
        df["tolls"] = pd.to_numeric(df["tolls"], errors="coerce")
        df["bcf"] = pd.to_numeric(df["bcf"], errors="coerce")
        df["sales_tax"] = pd.to_numeric(df["sales_tax"], errors="coerce")
        df["congestion_surcharge"] = pd.to_numeric(
            df["congestion_surcharge"], errors="coerce"
        )
        df["airport_fee"] = pd.to_numeric(df["airport_fee"], errors="coerce")
        df["tips"] = pd.to_numeric(df["tips"], errors="coerce")
        df["driver_pay"] = pd.to_numeric(df["driver_pay"], errors="coerce")
        df["shared_request_flag"] = df["shared_request_flag"].astype("string")
        df["shared_match_flag"] = df["shared_match_flag"].astype("string")
        df["access_a_ride_flag"] = df["access_a_ride_flag"].astype("string")
        df["wav_request_flag"] = df["wav_request_flag"].astype("string")
        df["wav_match_flag"] = df["wav_match_flag"].astype("string")

        # Add ingestion timestamp
        df["data_hora_ingestao"] = datetime.now()

        print("> Schema aplicado com sucesso")
        print(f"> Colunas: {df.columns.tolist()}")

        return df

    def run(self):
        print("> Iniciando a execução do job...")

        partitions = self.discover_partitions()

        if not partitions:
            print("> Nenhuma partição encontrada.")
            return

        print(f"> Total de partições a processar: {len(partitions)}")

        location = wr.catalog.get_table_location(
            database=self.args.target_db, table=self.args.target_table
        )
        for idx, partition in enumerate(partitions, 1):
            print(f"> Processando partição: {partition}")
            print(f"> Progresso: {idx}/{len(partitions)}")

            dfs = self.compute_raw(partition)

            for df in dfs:
                df["ano_mes_referencia"] = partition
                df = self.compute_transformed(df)

                print(
                    f"> Escrevendo {len(df)} linhas na partição ano_mes_referencia={partition}"
                )

                wr.s3.to_parquet(
                    df=df,
                    path=location,
                    dataset=True,
                    database=self.args.target_db,
                    table=self.args.target_table,
                    mode="append",
                    partition_cols=["ano_mes_referencia"],
                    boto3_session=self.boto3_session,
                    compression="snappy",
                )

        print("> Job finalizado com sucesso!")


def main():
    args, _ = Arguments.get()

    pipeline = Pipeline(args=args)
    pipeline.run()


if __name__ == "__main__":
    import sys
    import traceback

    try:
        main()
    except Exception as e:
        print(traceback.format_exc())
        sys.exit(1)
