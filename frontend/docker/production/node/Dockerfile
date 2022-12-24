FROM node:16.15.1-alpine3.15

WORKDIR /app

COPY ./package.json ./

RUN yarn install

# expose 3000 on container
EXPOSE 3000

# set app serving to permissive / assigned
ENV NUXT_HOST=0.0.0.0

# set app port
ENV NUXT_PORT=3000

CMD ["npm", "run", "dev"]
