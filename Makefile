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

api-isort:
	docker-compose run --rm api-src isort .

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

# BUILD
build: build-frontend build-frontend-node build-api build-api-src

build-frontend:
	DOCKER_BUILDKIT=1 docker --log-level=debug build --pull --build-arg BUILDKIT_INLINE_CACHE=1 \
    --cache-from ${REGISTRY}/more-charts-frontend:cache \
    --tag ${REGISTRY}/more-charts-frontend:cache \
    --tag ${REGISTRY}/more-charts-frontend:${IMAGE_TAG} \
    --file frontend/docker/production/nginx/Dockerfile frontend

build-frontend-node:
	DOCKER_BUILDKIT=1 docker --log-level=debug build --pull --build-arg BUILDKIT_INLINE_CACHE=1 \
    --cache-from ${REGISTRY}/more-charts-frontend-node:cache \
    --tag ${REGISTRY}/more-charts-frontend-node:cache \
    --tag ${REGISTRY}/more-charts-frontend-node:${IMAGE_TAG} \
    --file frontend/docker/production/node/Dockerfile frontend

build-api:
	DOCKER_BUILDKIT=1 docker --log-level=debug build --pull --build-arg BUILDKIT_INLINE_CACHE=1 \
    --cache-from ${REGISTRY}/more-charts-api:cache \
    --tag ${REGISTRY}/more-charts-api:cache \
    --tag ${REGISTRY}/more-charts-api:${IMAGE_TAG} \
    --file api/docker/production/nginx/Dockerfile api

build-api-src:
	DOCKER_BUILDKIT=1 docker --log-level=debug build --pull --build-arg BUILDKIT_INLINE_CACHE=1 \
    --target builder \
    --cache-from ${REGISTRY}/more-charts-api-src:cache-builder \
    --tag ${REGISTRY}/more-charts-api-src:cache-builder \
	--file api/docker/production/src/Dockerfile api

	DOCKER_BUILDKIT=1 docker --log-level=debug build --pull --build-arg BUILDKIT_INLINE_CACHE=1 \
    --cache-from ${REGISTRY}/more-charts-api-src:cache-builder \
    --cache-from ${REGISTRY}/more-charts-api-src:cache \
    --tag ${REGISTRY}/more-charts-api-src:cache \
    --tag ${REGISTRY}/more-charts-api-src:${IMAGE_TAG} \
	--file api/docker/production/src/Dockerfile api


push-build-cache: push-build-cache-frontend push-build-cache-api

push-build-cache-frontend:
	docker push ${REGISTRY}/more-charts-frontend:cache
	docker push ${REGISTRY}/more-charts-frontend-node:cache

push-build-cache-api:
	docker push ${REGISTRY}/more-charts-api:cache
	docker push ${REGISTRY}/more-charts-api-src:cache-builder
	docker push ${REGISTRY}/more-charts-api-src:cache

# TEST
testing-build: testing-build-frontend testing-build-frontend-node testing-build-api testing-build-api-src testing-build-cucumber

testing-build-frontend:
	DOCKER_BUILDKIT=1 docker --log-level=debug build --pull --build-arg BUILDKIT_INLINE_CACHE=1 \
    --cache-from ${REGISTRY}/more-charts-testing-frontend:cache \
    --tag ${REGISTRY}/more-charts-testing-frontend:cache \
    --tag ${REGISTRY}/more-charts-testing-frontend:${IMAGE_TAG} \
    --file frontend/docker/testing/nginx/Dockerfile frontend

testing-build-frontend-node:
	DOCKER_BUILDKIT=1 docker --log-level=debug build --pull --build-arg BUILDKIT_INLINE_CACHE=1 \
    --cache-from ${REGISTRY}/more-charts-testing-frontend-node:cache \
    --tag ${REGISTRY}/more-charts-testing-frontend-node:cache \
    --tag ${REGISTRY}/more-charts-testing-frontend-node:${IMAGE_TAG} \
    --file frontend/docker/testing/node/Dockerfile frontend

testing-build-api:
	DOCKER_BUILDKIT=1 docker --log-level=debug build --pull --build-arg BUILDKIT_INLINE_CACHE=1 \
    --cache-from ${REGISTRY}/more-charts-testing-api:cache \
    --tag ${REGISTRY}/more-charts-testing-api:cache \
    --tag ${REGISTRY}/more-charts-testing-api:${IMAGE_TAG} \
    --file api/docker/testing/nginx/Dockerfile api

testing-build-api-src:
	DOCKER_BUILDKIT=1 docker --log-level=debug build --pull --build-arg BUILDKIT_INLINE_CACHE=1 \
    --target builder \
    --cache-from ${REGISTRY}/more-charts-testing-api-src:cache-builder \
    --tag ${REGISTRY}/more-charts-testing-api-src:cache-builder \
	--file api/docker/testing/src/Dockerfile api

	DOCKER_BUILDKIT=1 docker --log-level=debug build --pull --build-arg BUILDKIT_INLINE_CACHE=1 \
    --cache-from ${REGISTRY}/more-charts-testing-api-src:cache-builder \
    --cache-from ${REGISTRY}/more-charts-testing-api-src:cache \
    --tag ${REGISTRY}/more-charts-testing-api-src:cache \
    --tag ${REGISTRY}/more-charts-testing-api-src:${IMAGE_TAG} \
	--file api/docker/testing/src/Dockerfile api

testing-build-cucumber:
	DOCKER_BUILDKIT=1 docker --log-level=debug build --pull --build-arg BUILDKIT_INLINE_CACHE=1 \
	--cache-from ${REGISTRY}/more-charts-cucumber-node-cli:cache \
	--tag ${REGISTRY}/more-charts-cucumber-node-cli:cache \
	--tag ${REGISTRY}/more-charts-cucumber-node-cli:${IMAGE_TAG} \
	--file cucumber/docker/testing/node/Dockerfile \
	cucumber

push-testing-build-cache: push-testing-build-cache-frontend push-testing-build-cache-api push-testing-build-cache-cucumber

push-testing-build-cache-frontend:
	docker push ${REGISTRY}/more-charts-testing-frontend:cache
	docker push ${REGISTRY}/more-charts-testing-frontend-node:cache

push-testing-build-cache-api:
	docker push ${REGISTRY}/more-charts-testing-api:cache
	docker push ${REGISTRY}/more-charts-testing-api-src:cache-builder
	docker push ${REGISTRY}/more-charts-testing-api-src:cache

push-testing-build-cache-cucumber:
	docker push ${REGISTRY}/more-charts-cucumber-node-cli:cache

testing-init:
	COMPOSE_PROJECT_NAME=testing docker-compose -f docker-compose-testing.yml up -d

testing-smoke:
	COMPOSE_PROJECT_NAME=testing docker-compose -f docker-compose-testing.yml run --rm cucumber-node-cli yarn smoke-ci

testing-e2e:
	COMPOSE_PROJECT_NAME=testing docker-compose -f docker-compose-testing.yml run --rm cucumber-node-cli yarn e2e-ci

deploy:
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'rm -rf site_${BUILD_NUMBER}'
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'mkdir site_${BUILD_NUMBER}'
	scp -o StrictHostKeyChecking=no -P ${PORT} docker-compose-production.yml deploy@${HOST}:site_${BUILD_NUMBER}/docker-compose.yml
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'cd site_${BUILD_NUMBER} && echo "COMPOSE_PROJECT_NAME=more-charts" >> .env'
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'cd site_${BUILD_NUMBER} && echo "REGISTRY=${REGISTRY}" >> .env'
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'cd site_${BUILD_NUMBER} && echo "IMAGE_TAG=${IMAGE_TAG}" >> .env'
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'cd site_${BUILD_NUMBER} && docker-compose pull'
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'cd site_${BUILD_NUMBER} && docker-compose up --build -d api-postgres api-php-cli'
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'cd site_${BUILD_NUMBER} && docker-compose up --build --remove-orphans -d'
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'rm -f site'
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'ln -sr site_${BUILD_NUMBER} site'

rollback:
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'cd site_${BUILD_NUMBER} && docker-compose pull'
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'cd site_${BUILD_NUMBER} && docker-compose up --build --remove-orphans -d'
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'rm -f site'
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'ln -sr site_${BUILD_NUMBER} site'