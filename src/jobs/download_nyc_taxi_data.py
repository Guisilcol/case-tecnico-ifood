"""
Script para fazer download dos dados de táxis de NYC direto para S3.
Este script baixa dados de Yellow Taxi, Green Taxi e FHV (For-Hire Vehicle).

Uso:
    python download_nyc_taxi_data.py <base> [start_month] [end_month] --s3-bucket BUCKET [--s3-prefix PREFIX] [--base-url URL]

Dados disponíveis em: https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
Formato: Parquet
"""

import requests
from dataclasses import dataclass
from typing import List, Dict, Self
import time
from datetime import datetime
import argparse
import sys
from dateutil.relativedelta import relativedelta
import boto3
from botocore.exceptions import ClientError
import io


@dataclass
class Arguments:
    """Classe para armazenar os argumentos do script."""

    base: str
    s3_bucket: str
    start_month: str | None = None
    end_month: str | None = None
    s3_prefix: str = "nyc_taxi_data"
    base_url: str = "https://d37ci6vzurychx.cloudfront.net/trip-data"

    @classmethod
    def parse_arguments(cls) -> Self:
        """Parse argumentos da linha de comando."""
        parser = argparse.ArgumentParser(
            description="Download de dados de táxis de NYC para S3",
            formatter_class=argparse.RawDescriptionHelpFormatter,
            epilog="""
                Exemplos de uso:
                python download_nyc_taxi_data.py yellow --s3-bucket my-bucket                              # Carga full da base yellow
                python download_nyc_taxi_data.py green 2023-01 2023-05 --s3-bucket my-bucket              # Green de jan/2023 a mai/2023
                python download_nyc_taxi_data.py forhire 2022-12 2023-02 --s3-bucket my-bucket            # For-hire de dez/2022 a fev/2023
                python download_nyc_taxi_data.py highvolumeforhire 2023-06 --s3-bucket my-bucket          # High volume for-hire apenas jun/2023

                Bases disponíveis:
                - yellow: Yellow Taxi
                - green: Green Taxi  
                - forhire: For-Hire Vehicle (FHV)
                - highvolumeforhire: High Volume For-Hire Vehicle (FHVHV)
            """.strip(),
        )

        parser.add_argument(
            "base",
            choices=["yellow", "green", "forhire", "highvolumeforhire"],
            help="Base de dados para download",
        )

        parser.add_argument(
            "start-month",
            nargs="?",
            help="Ano-mês de início (formato YYYY-MM). Se não informado, faz carga full",
        )

        parser.add_argument(
            "end-month",
            nargs="?",
            help="Ano-mês de fim (formato YYYY-MM). Se não informado, usa apenas start_month",
        )

        parser.add_argument(
            "--s3-bucket",
            required=True,
            help="Nome do bucket S3 onde os dados serão armazenados",
        )

        parser.add_argument(
            "--s3-prefix",
            default="nyc_taxi_data",
            help="Prefixo (pasta) no S3 para salvar os dados (padrão: nyc_taxi_data)",
        )

        parser.add_argument(
            "--base-url",
            default="https://d37ci6vzurychx.cloudfront.net/trip-data",
            help="URL base para download dos dados (padrão: https://d37ci6vzurychx.cloudfront.net/trip-data)",
        )

        args = parser.parse_args()
        return cls(
            base=args.base,
            s3_bucket=args.s3_bucket,
            start_month=args.start_month,
            end_month=args.end_month,
            s3_prefix=args.s3_prefix,
            base_url=args.base_url,
        )


class App:
    """Classe para fazer download dos dados de táxis de NYC para S3."""

    def __init__(
        self,
        s3_bucket: str,
        s3_prefix: str = "nyc_taxi_data",
        base_url: str = "https://d37ci6vzurychx.cloudfront.net/trip-data",
    ):
        """
        Inicializa o downloader.

        Args:
            s3_bucket: Nome do bucket S3 onde os dados serão salvos
            s3_prefix: Prefixo (pasta) no S3 para salvar os dados
            base_url: URL base para download dos dados
        """
        self.s3_bucket = s3_bucket
        self.s3_prefix = s3_prefix
        self.base_url = base_url
        self.s3_client = boto3.client("s3")

        # Tipos de dados disponíveis
        self.data_types = {
            "yellow": "yellow_tripdata",
            "green": "green_tripdata",
            "fhv": "fhv_tripdata",
            "fhvhv": "fhvhv_tripdata",  # High Volume For-Hire Vehicles
            "forhire": "fhv_tripdata",  # Alias para fhv
            "highvolumeforhire": "fhvhv_tripdata",  # Alias para fhvhv
        }

        # Valida se o bucket existe
        try:
            self.s3_client.head_bucket(Bucket=self.s3_bucket)
        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            if error_code == "404":
                raise ValueError(f"Bucket S3 '{self.s3_bucket}' não existe")
            elif error_code == "403":
                raise ValueError(
                    f"Sem permissão para acessar o bucket '{self.s3_bucket}'"
                )
            else:
                raise ValueError(f"Erro ao acessar bucket S3: {e}")

    def _generate_months_range(self, start_date: str, end_date: str) -> List[str]:
        """
        Gera uma lista de meses no formato YYYY-MM entre duas datas.

        Args:
            start_date: Data de início no formato YYYY-MM
            end_date: Data de fim no formato YYYY-MM

        Returns:
            Lista de strings no formato YYYY-MM
        """
        try:
            start = datetime.strptime(start_date, "%Y-%m")
            end = datetime.strptime(end_date, "%Y-%m")

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

    def _get_all_available_months(self) -> List[str]:
        """
        Retorna uma lista com todos os meses disponíveis (carga full).
        """
        start_date = datetime(2009, 1, 1)
        end_date = datetime.now()

        months = []
        current = start_date

        while current <= end_date:
            months.append(current.strftime("%Y-%m"))
            current += relativedelta(months=1)

        return months

    def _check_s3_file_exists(self, s3_key: str) -> bool:
        """
        Verifica se um arquivo já existe no S3.

        Args:
            s3_key: Chave (path) do arquivo no S3

        Returns:
            True se o arquivo existe, False caso contrário
        """
        try:
            self.s3_client.head_object(Bucket=self.s3_bucket, Key=s3_key)
            return True
        except ClientError:
            return False

    def _download_to_s3(self, url: str, s3_key: str, filename: str) -> bool:
        """
        Faz download de um arquivo direto para S3.

        Args:
            url: URL do arquivo
            s3_key: Chave (path) onde salvar o arquivo no S3
            filename: Nome do arquivo (para exibição)

        Returns:
            True se o download foi bem-sucedido, False caso contrário
        """
        try:
            # Verifica se o arquivo já existe no S3
            if self._check_s3_file_exists(s3_key):
                print(f"Arquivo já existe no S3: {filename}")
                return True

            print(f"Baixando {filename}...")
            response = requests.get(url, stream=True, timeout=30)
            response.raise_for_status()

            # Faz o download em streaming direto para S3
            # Usa BytesIO para acumular os chunks e fazer upload
            file_data = io.BytesIO()

            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    file_data.write(chunk)

            # Volta para o início do buffer antes de fazer upload
            file_data.seek(0)

            # Faz upload para o S3
            self.s3_client.upload_fileobj(
                file_data,
                self.s3_bucket,
                s3_key,
                ExtraArgs={"ContentType": "application/octet-stream"},
            )

            print(f"Upload concluído para S3: s3://{self.s3_bucket}/{s3_key}")
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

    def download_dataset(self, data_type: str, months: List[str]) -> Dict[str, bool]:
        """
        Faz download de um tipo específico de dados para S3.

        Args:
            data_type: Tipo de dados (yellow, green, fhv, fhvhv)
            months: Lista de meses no formato YYYY-MM

        Returns:
            Dicionário com status do download para cada arquivo
        """
        if data_type not in self.data_types:
            raise ValueError(f"Tipo de dados inválido: {data_type}")

        results = {}
        data_prefix = self.data_types[data_type]

        for month in months:
            # Cria a estrutura de particionamento Hive no S3
            # Formato: s3://bucket/prefix/ano_mes_referencia=<ano-mes>/arquivo.parquet
            filename = f"{data_prefix}_{month}.parquet"
            s3_key = f"{self.s3_prefix}/ano_mes_referencia={month}/{filename}"
            url = f"{self.base_url}/{filename}"

            success = self._download_to_s3(url, s3_key, filename)
            results[filename] = success

            # Pequena pausa entre downloads
            time.sleep(1)

        return results


def main():
    """Função principal."""
    args = Arguments.parse_arguments()

    # Validação dos argumentos
    if args.start_month and not args.end_month:
        # Se apenas start_month foi informado, usa apenas esse mês
        args.end_month = args.start_month
    elif args.end_month and not args.start_month:
        print("Erro: Se end_month for informado, start_month também deve ser informado")
        sys.exit(1)

    # Cria o downloader
    print(f"Configuração S3: bucket={args.s3_bucket}, prefix={args.s3_prefix}")
    downloader = App(
        s3_bucket=args.s3_bucket, s3_prefix=args.s3_prefix, base_url=args.base_url
    )

    # Determina quais meses baixar
    if args.start_month and args.end_month:
        months = downloader._generate_months_range(args.start_month, args.end_month)
        print(
            f"Download: {args.base} ({args.start_month} a {args.end_month}) - {len(months)} meses"
        )
    else:
        months = downloader._get_all_available_months()
        print(f"Download: {args.base} (carga full) - {len(months)} meses")

    # Faz o download
    results = downloader.download_dataset(args.base, months)

    # Mostra resumo
    successful = sum(1 for success in results.values() if success)
    total = len(results)
    print(f"\nResumo: {successful}/{total} arquivos enviados para S3")
    print(f"Localização: s3://{args.s3_bucket}/{args.s3_prefix}/")

    # Lista arquivos com erro
    failed_files = [filename for filename, success in results.items() if not success]
    if failed_files:
        print(f"Falhas: {', '.join(failed_files)}")


if __name__ == "__main__":
    main()
