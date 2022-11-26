FROM nginx:1.22-alpine

COPY .docker/production/nginx/conf.d /etc/nginx/conf.d

WORKDIR /app

COPY ./public ./public