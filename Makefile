.PHONY: help test shell clean lint build

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build Docker test environment
	docker compose build

shell: ## Start and enter Docker test environment
	docker compose up -d && docker compose exec dotfiles bash

test: build ## Build and run install.sh in a clean container
	docker compose run --rm dotfiles bash -c \
		"curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash"

lint: ## Run shellcheck on all shell scripts
	@echo "==> Running shellcheck..."
	shellcheck -s bash dot_bashrc dot_bash_aliases dot_bash_profile install.sh
	@echo "==> All checks passed!"

clean: ## Stop containers and remove volumes
	docker compose down -v
	docker system prune -f

status: ## Show Docker container status
	docker compose ps
