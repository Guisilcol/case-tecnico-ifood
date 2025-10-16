import re
from dataclasses import dataclass
from datetime import datetime
from typing import List

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

    def compute_raw(self, year_month_reference: str) -> "pd.DataFrame":
        """Read and process raw data for a specific partition."""
        print(f"> Listando arquivos parquet para partição {year_month_reference}...")
        files = self.list_parquet_files_for_partition(year_month_reference)

        if not files:
            raise ValueError(
                f"No parquet files found for partition {year_month_reference}"
            )

        print(f"> Encontrados {len(files)} arquivos parquet")

        df = wr.s3.read_parquet(
            path=files,
            boto3_session=self.boto3_session,
            path_suffix=".parquet",
            use_threads=True,
        )

        df["ano_mes_referencia"] = year_month_reference

        return df

    def compute_transformed(self, df: "pd.DataFrame") -> "pd.DataFrame":

        print(f"> Dados lidos: {len(df)} linhas")

        df = df.rename(
            columns={
                "dropOff_datetime": "dropoff_datetime",
                "PUlocationID": "pulocationid",
                "DOlocationID": "dolocationid",
                "SR_Flag": "sr_flag",
                "Affiliated_base_number": "affiliated_base_number",
            }
        )

        df["dispatching_base_num"] = df["dispatching_base_num"].astype("string")
        df["pickup_datetime"] = pd.to_datetime(df["pickup_datetime"], errors="coerce")
        df["dropoff_datetime"] = pd.to_datetime(df["dropoff_datetime"], errors="coerce")
        df["pulocationid"] = pd.to_numeric(df["pulocationid"], errors="coerce").astype(
            "Int64"
        )
        df["dolocationid"] = pd.to_numeric(df["dolocationid"], errors="coerce").astype(
            "Int64"
        )
        df["sr_flag"] = pd.to_numeric(df["sr_flag"], errors="coerce").astype("Int64")
        df["affiliated_base_number"] = df["affiliated_base_number"].astype("string")

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

            df = self.compute_raw(partition)
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
                mode="overwrite_partitions",
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
