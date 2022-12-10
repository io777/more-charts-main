init: init-ci frontend-ready
init-ci: docker-down-clear \
	api-clear frontend-clear cucumber-clear \
	docker-pull docker-build docker-up \
	frontend-init cucumber-init \
	frontend-run
test: api-test frontend-test test-e2e
test-e2e: cucumber-clear cucumber-e2e

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down --remove-orphans

docker-down-clear:
	docker-compose down -v --remove-orphans

docker-pull:
	- docker-compose pull

docker-build:
# DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 docker-compose build --build-arg BUILDKIT_INLINE_CACHE=1 --pull
	docker-compose build --pull

push-dev-cache:
	docker-compose push

# BACKEND
api-init: api-pip-install

api-pip-install:
	docker-compose run --rm api-src python3 -m pip install -r requirements.txt

api-check-all:
	docker-compose run --rm api-src sh ./ci

api-black-check:
	docker-compose run --rm api-src black --check .

api-black:
	docker-compose run --rm api-src black .

api-flake8:
	docker-compose run --rm api-src flake8 .

api-test:
	docker-compose run --rm api-src python3 manage.py test

api-clear:
	docker run --rm -v ${PWD}/api:/app -w /app alpine sh -c 'rm -rf var/cache/* var/log/* var/test/*'

api-run:
	docker-compose restart api-src
	docker-compose restart api

# FRONTEND
frontend-init: frontend-yarn-install

frontend-yarn-install:
	docker-compose run --rm frontend-node yarn install

frontend-yarn-upgrade:
	docker-compose run --rm frontend-node yarn upgrade

frontend-test:
	docker-compose run --rm frontend-node yarn test

frontend-lintfix:
	docker-compose run --rm frontend-node yarn lintfix

frontend-check: frontend-test frontend-lintfix

frontend-ready:
	docker run --rm -v ${PWD}/frontend:/app -w /app alpine touch .ready

frontend-clear:
	docker run --rm -v ${PWD}/frontend:/app -w /app alpine sh -c 'rm -rf .ready build'

frontend-run:
	docker-compose restart frontend-node
	docker-compose restart frontend

# CUCUMBER
cucumber-clear:
	docker run --rm -v ${PWD}/cucumber:/app -w /app alpine sh -c 'rm -rf var/*'

cucumber-init: cucumber-yarn-install

cucumber-yarn-install:
	docker-compose run --rm cucumber-node-cli yarn install

cucumber-yarn-upgrade:
	docker-compose run --rm cucumber-node-cli yarn upgrade

cucumber-lint:
	docker-compose run --rm cucumber-node-cli yarn lint

cucumber-lint-fix:
	docker-compose run --rm cucumber-node-cli yarn lint-fix

cucumber-smoke:
	docker-compose run --rm cucumber-node-cli yarn smoke

cucumber-e2e:
	docker-compose run --rm cucumber-node-cli yarn e2e

# jenkins
validate-jenkins:
	curl --user andrey -X POST -F "jenkinsfile=<Jenkinsfile" http://localhost:8000/pipeline-model-converter/validate
# curl --user ${USER} -X POST -F "jenkinsfile=<Jenkinsfile" ${HOST}/pipeline-model-converter/validate

