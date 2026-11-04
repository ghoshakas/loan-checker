.PHONY: help init pull up down build logs ps

help:            ## Show this help
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*## /\t/'

init:            ## First run: fetch the submodules and create .env
	git submodule update --init --recursive
	@test -f .env || (cp .env.example .env && echo "Created .env, now fill in PASSWORD_HASH_SECRET and ADMIN_PASSWORD")

pull:            ## Pull the latest backend + frontend from upstream
	./scripts/pull-upstream.sh

up:              ## Build and start the whole stack
	docker compose up -d --build

down:            ## Stop the stack (data volumes are kept)
	docker compose down

build:           ## Rebuild images without starting
	docker compose build

logs:            ## Follow logs from all services
	docker compose logs -f

ps:              ## Show service status
	docker compose ps
