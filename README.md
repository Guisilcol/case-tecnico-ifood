# Case Técnico iFood — NYC Taxi Data (AWS + Databricks)

Pipeline de dados para ingestão e processamento do dataset público de corridas de táxi de Nova York (TLC Trip Record Data) utilizando AWS S3 e Databricks. A infraestrutura é provisionada via Terraform.

Fonte dos dados: https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

## Visão Geral

Fluxo end-to-end:

- Infraestrutura (Terraform):
	- Buckets S3: landing, bronze, silver
	- IAM Role + External Locations no Databricks para ler/gravar no S3
	- Secrets no Databricks para chaves de acesso AWS (usadas no download dos dados)
	- Schemas no Unity Catalog (workspace): `bronze_db` e `silver_db`
	- Job no Databricks para orquestrar o pipeline
- Pipeline de dados (Databricks Jobs):
	1) Download dos Parquets da TLC para o S3 (landing), particionados por `ano_mes_referencia=YYYY-MM`.
	2) Ingestão Bronze (Spark): leitura da landing, tratamentos simples de dados e gravação nas tabelas bronze.
	3) ETL Silver (Spark): unificação das corridas “yellow” e “green” com enriquecimento de domínios e escrita em `silver_db.tb_corrida_taxi_ny`.

Os scripts de jobs estão em `src/jobs/` e as DDLs em `migrations/`.

## Estrutura do Repositório

- `infra/`: Terraform para AWS + Databricks (buckets, IAM, external locations, secrets, schemas e job)
- `migrations/`: SQL para criar as tabelas bronze e silver
- `src/jobs/`: scripts de pipeline (download, bronze, silver)
- `src/analysis/`: notebooks de exploração (landing/bronze/perguntas)
- `Makefile`: alvos para `plan` e `deploy` (Terraform)

## Pré-requisitos

- Conta AWS com permissões para criar S3 e IAM; AWS CLI configurado (perfil)
- Conta Databricks com Workspace e Unity Catalog habilitado
- Token de acesso Databricks (PAT)
- Terraform 1.5+ (recomendado)
- Python 3.10+ (para desenvolvimento local; jobs rodam no Databricks)

## Configuração de Ambiente (configure_env.bash)

O projeto utiliza um arquivo bash `configure_env.bash` para exportar variáveis de ambiente necessárias para o Terraform e outras ferramentas. O Terraform consome variáveis via o padrão `TF_VAR_<nome_da_variavel>`.

Existe um arquivo de exemplo `configure_env.example.bash` na raiz do projeto. Para configurar seu ambiente:

1. Copie o arquivo de exemplo:
```bash
cp configure_env.example.bash configure_env.bash
```

2. Edite o arquivo `configure_env.bash` com suas credenciais e configurações:

```bash
# Databricks
export DATABRICKS_HOST=https://<seu-workspace>.cloud.databricks.com/
export DATABRICKS_ACCOUNT_ID=<seu-account-id>
export DATABRICKS_TOKEN=<seu-token-pat>
export DATABRICKS_SERVERLESS_COMPUTE_ID=auto

# Buckets S3 (use nomes globais únicos)
export bucket_landing_zone=<seu-bucket-landing>
export bucket_bronze_layer=<seu-bucket-bronze>
export bucket_silver_layer=<seu-bucket-silver>

# AWS
export aws_region=us-east-2
export aws_profile=default
export aws_access_key_id=<AWS_ACCESS_KEY_ID>
export aws_secret_access_key=<AWS_SECRET_ACCESS_KEY>

# Databricks Workspace
export databricks_serverless_workspace_id=<seu-workspace-id>
export workspace_folder="/Workspace/Users/<seu-email>/case-tecnico-ifood"

# Variáveis para o Terraform (TF_VAR_*)
export TF_VAR_bucket_landing_zone=${bucket_landing_zone}
export TF_VAR_bucket_bronze_layer=${bucket_bronze_layer}
export TF_VAR_bucket_silver_layer=${bucket_silver_layer}
export TF_VAR_databricks_host=${DATABRICKS_HOST}
export TF_VAR_databricks_token=${DATABRICKS_TOKEN}
export TF_VAR_aws_region=${aws_region}
export TF_VAR_aws_profile=${aws_profile}
export TF_VAR_databricks_serverless_workspace_id=${databricks_serverless_workspace_id}
export TF_VAR_aws_access_key_id=${aws_access_key_id}
export TF_VAR_aws_secret_access_key=${aws_secret_access_key}
export TF_VAR_workspace_folder=${workspace_folder}
```

3. Carregue as variáveis de ambiente no seu terminal:
```bash
source configure_env.bash
```

Observações importantes:

- Os nomes de bucket S3 devem ser únicos globalmente.
- O arquivo `configure_env.bash` não deve ser versionado (adicione ao `.gitignore`).
- Sempre execute `source configure_env.bash` antes de rodar comandos Terraform ou Makefile.
- O provider AWS também entende `AWS_PROFILE` e `AWS_REGION`, mas aqui padronizamos via `TF_VAR_*` + variáveis do Terraform.
- O provider Databricks aqui está configurado para consumir `var.databricks_host` e `var.databricks_token` — por isso usamos `TF_VAR_*` no arquivo de configuração.

## Provisionar Infraestrutura (Terraform)

Após criar e carregar o arquivo `configure_env.bash`, execute:

```bash
source configure_env.bash
make plan
make deploy
```

O `deploy` irá:

- Criar os buckets S3 (landing, bronze, silver e um para código-fonte)
- Criar Role/Policy no IAM
- Configurar External Locations no Databricks para os buckets
- Criar Secret Scope/Secrets com suas chaves AWS
- Criar schemas `bronze_db` e `silver_db`
- Criar o Job `NYC_Taxi_Data_Processing_Job`

## Subir o código-fonte para o Workspace Databricks

O Job referencia os scripts Python pelo caminho do Workspace Databricks:

```
/Workspace/Users/<seu-email>/case-tecnico-ifood/src/jobs/*.py
```

Você tem algumas opções para garantir que o código esteja nesse caminho:

1) Databricks Repos
	 - No Databricks, crie um Repo apontando para este repositório.
	 - Clone para `/Workspace/Users/<seu-email>/case-tecnico-ifood` (ou ajuste o caminho no arquivo `infra/04_databricks_jobs.tf` caso use outro path).


## Criar Tabelas (migrações SQL)

As tabelas não são criadas automaticamente pelo Terraform. Após o deploy da infra:

1) Abra o editor SQL no Databricks.
2) Execute, em ordem, os arquivos do diretório `migrations/`:
	 - `0001_create_table_nyc_taxi_data_forhire.sql`
	 - `0002_create_table_nyc_taxi_data_green.sql`
	 - `0003_create_table_nyc_taxi_data_highvolumeforhire.sql`
	 - `0004_create_table_nyc_taxi_data_yellow.sql`
	 - `0005_create_table_tb_corrida_taxi_ny.sql`

Isso criará as tabelas `bronze_db.*` e a tabela `silver_db.tb_corrida_taxi_ny`.

## Executar o Pipeline (Databricks Job)

Com a infra provisionada, o código no Workspace e as tabelas criadas:

1) No Databricks, abra o Job `NYC_Taxi_Data_Processing_Job`.
2) Clique em “Run now”.

O job fará:

- Download para a landing (meses 2023-01 a 2023-05 para yellow/green/forhire/highvolumeforhire) com prefixos como `nyc_taxi_data_yellow/ano_mes_referencia=YYYY-MM/…`.
- Ingestão bronze para as tabelas `bronze_db.nyc_taxi_data_*`.
- ETL silver e escrita em `silver_db.tb_corrida_taxi_ny`.

Validação rápida (no Databricks SQL):

```sql
SELECT tipo_servico, COUNT(*)
FROM silver_db.tb_corrida_taxi_ny
GROUP BY 1;
```

## Execução Local (opcional)

Os scripts de bronze/silver dependem de um cluster Spark ativo e do `dbutils` do Databricks; portanto, a execução local não é suportada nativamente. O script de download (`src/jobs/download_nyc_taxi_data.py`) também foi desenhado para rodar no ambiente Databricks (recupera chaves via Secret Scope). Recomendamos executar sempre via Job no Databricks.

Para desenvolvimento local (lint/tests/SDK), você pode instalar as dependências de DEV:

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r src/requirements.dev.txt
```