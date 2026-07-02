.PHONY: help up down build restart logs ps clean seed test lint format

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

up: ## Start all services
	docker compose up -d

down: ## Stop all services
	docker compose down

build: ## Build all Docker images
	docker compose build

restart: ## Restart all services
	docker compose restart

logs: ## View logs from all services
	docker compose logs -f

ps: ## List running services
	docker compose ps

clean: ## Stop and remove all containers, networks, and volumes
	docker compose down -v

seed: ## Seed the database with sample data
	python scripts/seed.py --host localhost --port 5432 --user employee_user --password employee_pass --db employee_db --count 50

test: ## Run all tests
	cd services/employee-api && python -m pytest tests/ -v

test-api: ## Run API tests only
	cd services/employee-api && python -m pytest tests/test_employees.py -v

lint: ## Lint Python code
	cd services/employee-api && pip install flake8 black && \
		flake8 app --max-line-length=120 --exclude=__pycache__,alembic && \
		black --check app --line-length=120

format: ## Format Python code with Black
	cd services/employee-api && pip install black && \
		black app --line-length=120

frontend-build: ## Build frontend for production
	cd services/frontend && npm install && npm run build

health: ## Check health of all services
	@bash deployments/scripts/health-check.sh

# Deployment is handled exclusively through GitHub Actions workflows.
# See .github/workflows/deploy.yml for the automated deployment pipeline.
# Manual SSH deployment is not supported.

.PHONY: help up down build restart logs ps clean seed test test-api lint format frontend-build health
