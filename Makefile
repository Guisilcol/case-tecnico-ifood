SHELL := /bin/bash

.PHONY: help terraform-plan build deploy upload-source test install clean

help:
	@echo "Available targets:"
	@echo "  plan              - Run terraform plan to preview infrastructure changes"
	@echo "  deploy            - Apply terraform configuration to create/update infrastructure"
	@echo "  test              - Run pytest tests"
	@echo "  install           - Install Python dependencies from requirements.txt"

plan:
	@echo "Running terraform plan..."
	set -a && source .env && set +a && cd infra && terraform init && terraform plan

deploy:
	@echo "Applying terraform configuration..."
	set -a && source .env && set +a && cd infra && terraform init -upgrade && terraform apply

# Test target
test:
	@echo "Running tests..."
	pytest -v

# Install dependencies
install:
	@echo "Installing dependencies..."
	pip install -r requirements.txt
