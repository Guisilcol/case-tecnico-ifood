"""
Script para fazer download dos dados de táxis de NYC direto para S3.
Este script baixa dados de Yellow Taxi, Green Taxi e FHV (For-Hire Vehicle).

Uso:
    python download_nyc_taxi_data.py <base> [start_month] [end_month] --s3-bucket BUCKET [--s3-prefix PREFIX] [--base-url URL]

Dados disponíveis em: https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
Formato: Parquet
"""

import typing
import requests
from dataclasses import dataclass
import datetime as dt
import sys
from dateutil.relativedelta import relativedelta
import boto3
from botocore.exceptions import ClientError
import io

from shared.glue_resolved_args import GlueResolvedArgs

if typing.TYPE_CHECKING:
    from typing import List, Dict
    from mypy_boto3_s3 import S3Client


@dataclass
class Arguments(GlueResolvedArgs):
    base: "str"
    s3_bucket: "str"
    start_month: "str | None" = None
    end_month: "str | None" = None
    s3_prefix: "str" = "nyc_taxi_data"
    base_url: "str" = "https://d37ci6vzurychx.cloudfront.net/trip-data"


class App:
    sources = {
        "yellow": "yellow_tripdata",
        "green": "green_tripdata",
        "fhv": "fhv_tripdata",
        "fhvhv": "fhvhv_tripdata",  # High Volume For-Hire Vehicles
        "forhire": "fhv_tripdata",  # Alias para fhv
        "highvolumeforhire": "fhvhv_tripdata",  # Alias para fhvhv
    }

    def __init__(self, args: "Arguments", s3_cli: "S3Client"):

        self.args = args
        self.s3_client = s3_cli

    def generate_months_range(self, start_date: str, end_date: str) -> "List[str]":
        """
        Gera uma lista de meses no formato YYYY-MM entre duas datas.

        Args:
            start_date: Data de início no formato YYYY-MM
            end_date: Data de fim no formato YYYY-MM

        Returns:
            Lista de strings no formato YYYY-MM
        """

        try:
            start = dt.datetime.strptime(start_date, "%Y-%m")
            end = dt.datetime.strptime(end_date, "%Y-%m")

            if start > end:
                raise ValueError("Data de início deve ser anterior à data de fim")

            months = []
            current = start

            while current <= end:
                months.append(current.strftime("%Y-%m"))
                current += relativedelta(months=1)

            return months

        except ValueError as e:
            if "time data" in str(e) or "unconverted data" in str(e):
                raise ValueError("Formato de data inválido. Use YYYY-MM (ex: 2023-01)")
            raise e

    def check_s3_file_exists(self, bucket: "str", s3_key: "str") -> "bool":
        """
        Verifica se um arquivo já existe no S3.

        Args:
            s3_key: Chave (path) do arquivo no S3

        Returns:
            True se o arquivo existe, False caso contrário
        """
        try:
            self.s3_client.head_object(Bucket=bucket, Key=s3_key)
            return True
        except ClientError:
            return False

    def download_to_s3(self, url: "str", s3_key: "str", filename: "str") -> "bool":
        try:
            if self.check_s3_file_exists(self.s3_bucket, s3_key):
                print(f"Arquivo já existe no S3: {filename}")
                return True

            print(f"Baixando {filename}...")
            response = requests.get(url, stream=True, timeout=30)
            response.raise_for_status()

            file_data = io.BytesIO()

            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    file_data.write(chunk)

            file_data.seek(0)

            self.s3_client.upload_fileobj(
                file_data,
                self.s3_bucket,
                s3_key,
                ExtraArgs={"ContentType": "application/octet-stream"},
            )

            print(f"Upload concluído: s3://{self.s3_bucket}/{s3_key}")
            return True

        except requests.exceptions.RequestException as e:
            print(f"Erro no download de {filename}: {e}")
            return False

        except ClientError as e:
            print(f"Erro ao fazer upload para S3 de {filename}: {e}")
            return False

        except Exception as e:
            print(f"Erro inesperado em {filename}: {e}")
            return False

    def download_dataset(
        self, data_type: "str", months: "List[str]"
    ) -> "Dict[str, bool]":
        """
        Faz download de um tipo específico de dados para S3.

        Args:
            data_type: Tipo de dados (yellow, green, fhv, fhvhv)
            months: Lista de meses no formato YYYY-MM

        Returns:
            Dicionário com status do download para cada arquivo
        """
        if data_type not in self.sources:
            raise ValueError(f"Tipo de dados inválido: {data_type}")

        results = {}
        data_prefix = self.sources[data_type]

        for month in months:
            filename = f"{data_prefix}_{month}.parquet"
            s3_key = f"{self.args.s3_prefix}/ano_mes_referencia={month}/{filename}"
            url = f"{self.args.base_url}/{filename}"

            success = self.download_to_s3(url, s3_key, filename)
            results[filename] = success

        return results

    def run(self):
        # Validação dos argumentos
        if self.args.start_month and not self.args.end_month:
            # Se apenas start_month foi informado, usa apenas esse mês
            self.args.end_month = self.args.start_month
        elif self.args.end_month and not self.args.start_month:
            print(
                "Erro: Se end_month for informado, start_month também deve ser informado"
            )
            raise ValueError("start_month é obrigatório se end_month for informado")

        print(
            f"Configuração S3: bucket={self.args.s3_bucket}, prefix={self.args.s3_prefix}"
        )

        # Determina quais meses baixar
        if self.args.start_month and self.args.end_month:
            months = self.generate_months_range(
                self.args.start_month, self.args.end_month
            )
            print(
                f"Download: {self.args.base} ({self.args.start_month} a {self.args.end_month}) - {len(months)} meses"
            )
        else:
            start_month = "2009-01"
            end_month = dt.datetime.now().strftime("%Y-%m")
            months = self.generate_months_range(start_month, end_month)
            print(f"Download: {self.args.base} (carga full) - {len(months)} meses")

        # Faz o download
        results = self.download_dataset(self.args.base, months)

        # Mostra resumo
        successful = sum(1 for success in results.values() if success)
        total = len(results)
        print(f"\nResumo: {successful}/{total} arquivos enviados para S3")
        print(f"Localização: s3://{self.args.s3_bucket}/{self.args.s3_prefix}/")

        # Lista arquivos com erro
        failed_files = [
            filename for filename, success in results.items() if not success
        ]
        if failed_files:
            print(f"Falhas: {', '.join(failed_files)}")


def main():
    args = Arguments.get()
    s3_client = boto3.client("s3")
    app = App(args, s3_client)
    app.run()


if __name__ == "__main__":
    import traceback

    try:
        main()
    except Exception as e:
        traceback.print_exc()
        sys.exit(1)
