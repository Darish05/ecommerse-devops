.PHONY: gen-complete-demo
gen-complete-demo:
	make -C deploy/kubernetes docker-gen-complete-demo

DOCKER_COMPOSE_CMD := $(shell if docker compose version >/dev/null 2>&1; then echo "docker compose"; elif command -v docker-compose >/dev/null 2>&1; then echo "docker-compose"; fi)

.PHONY: check-generated-files
check-generated-files:
	make -C deploy/kubernetes docker-check-complete-demo

.PHONY: local-jenkins-up
local-jenkins-up:
	$(DOCKER_COMPOSE_CMD) -f ci/local-jenkins/docker-compose.yml up -d --build

.PHONY: local-jenkins-down
local-jenkins-down:
	$(DOCKER_COMPOSE_CMD) -f ci/local-jenkins/docker-compose.yml down

.PHONY: local-monitoring-up
local-monitoring-up:
	$(DOCKER_COMPOSE_CMD) -f deploy/docker-compose/docker-compose.monitoring.yml up -d

.PHONY: local-monitoring-down
local-monitoring-down:
	$(DOCKER_COMPOSE_CMD) -f deploy/docker-compose/docker-compose.monitoring.yml down

.PHONY: local-sockshop-up
local-sockshop-up:
	$(DOCKER_COMPOSE_CMD) -f deploy/docker-compose/docker-compose.yml up -d

.PHONY: local-sockshop-down
local-sockshop-down:
	$(DOCKER_COMPOSE_CMD) -f deploy/docker-compose/docker-compose.yml down

.PHONY: enable-local-push-automation
enable-local-push-automation:
	bash scripts/setup-local-git-automation.sh
