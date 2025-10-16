SHELL := /bin/bash

.PHONY: help terraform-plan build deploy upload-source test install clean

help:
	@echo "Available targets:"
	@echo "  terraform-plan    - Run terraform plan to preview infrastructure changes"
	@echo "  deploy            - Apply terraform configuration to create/update infrastructure"
	@echo "  upload-source     - Upload src folder to S3 source code bucket"
	@echo "  test              - Run pytest tests"
	@echo "  install           - Install Python dependencies"
	@echo "  clean             - Clean temporary files and caches"

terraform-plan:
	@echo "Running terraform plan..."
	set -a && source .env && set +a && cd infra && terraform init && terraform plan

build:
	@echo "Building project..."
	bash build_shared_wheel.sh

upload-source:
	@echo "Uploading source code to S3 bucket..."
	@set -a && source .env && set +a && \
	if [ -z "$$TF_VAR_bucket_source_code" ]; then \
		echo "Error: TF_VAR_bucket_source_code not set in .env file"; \
		exit 1; \
	fi && \
	echo "Using bucket: $$TF_VAR_bucket_source_code" && \
	aws s3 sync src/ s3://$$TF_VAR_bucket_source_code/src/ --delete && \
	echo "Source code uploaded successfully to s3://$$TF_VAR_bucket_source_code/src/"

deploy:
	@echo "Building project before deployment..."
	@$(MAKE) build
	@echo "Applying terraform configuration..."
	set -a && source .env && set +a && cd infra && terraform init -upgrade && terraform apply
	@echo "Uploading source code after deployment..."
	@$(MAKE) upload-source

# Test target
test:
	@echo "Running tests..."
	pytest -v

# Install dependencies
install:
	@echo "Installing dependencies..."
	pip install -r requirements.txt

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
