.PHONY: help terraform-plan terraform-apply test install clean

help:
	@echo "Available targets:"
	@echo "  terraform-plan    - Run terraform plan to preview infrastructure changes"
	@echo "  terraform-apply   - Apply terraform configuration to create/update infrastructure"
	@echo "  test              - Run pytest tests"
	@echo "  install           - Install Python dependencies"
	@echo "  clean             - Clean temporary files and caches"

terraform-plan:
	@echo "Running terraform plan..."
	cd infra && terraform init && terraform plan

terraform-apply:
	@echo "Applying terraform configuration..."
	cd infra && terraform init -upgrade && terraform apply

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
