FROM ubuntu:18.04

ARG PROD_ARGS
ARG HTTP_PORT
ARG P2P_PORT

RUN apt update
RUN apt-get install -y libcurl4-gnutls-dev
RUN apt-get install -y libusb-1.0-0-dev
RUN apt-get -y install openssl
RUN apt-get -y install jq
RUN apt-get -y install curl

WORKDIR /opt/producer/

COPY ./bin /opt/eosio/bin

ENV PATH /opt/eosio/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

EXPOSE 8888
EXPOSE 9876

CMD nodeos --genesis-json /opt/producer/genesis.json --disable-replay-opts --data-dir /opt/producer --config-dir /opt/producer $PROD_ARGS
