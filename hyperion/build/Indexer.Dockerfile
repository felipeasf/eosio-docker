FROM node:12.9-alpine

RUN apk add git
RUN apk add bash
RUN apk --no-cache add --virtual native-deps \
  g++ gcc libgcc libstdc++ linux-headers make python

RUN mkdir -p /root/app/
WORKDIR /root/app/

RUN git clone https://github.com/eosrio/Hyperion-History-API.git

WORKDIR /root/app/Hyperion-History-API

RUN npm install pm2 -g && npm install

CMD pm2-runtime ecosystem.config.json --only Indexer --update-env
