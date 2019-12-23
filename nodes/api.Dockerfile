FROM ubuntu:18.04

ARG API_ARGS

RUN apt update
RUN apt-get -y install openssl

WORKDIR /opt/api/

COPY ./bin /opt/eosio/bin

ENV PATH /opt/eosio/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

EXPOSE 8888
EXPOSE 8080
EXPOSE 9876

CMD nodeos --genesis-json /opt/api/genesis.json  --disable-replay-opts --data-dir /opt/api --config-dir /opt/api $API_ARGS
