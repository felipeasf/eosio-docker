FROM ubuntu:18.04

ARG KAFKA_ARGS

RUN apt update
#RUN apt-get install -y apt-utils
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install openssl ca-certificates
RUN apt-get install -y librdkafka-dev
RUN apt-get install -y libicu-dev
RUN apt-get install -y libcurl4-gnutls-dev
RUN apt-get install -y libusb-1.0-0-dev
RUN apt-get install -y gnome-terminal
RUN apt-get install -y jq
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*

WORKDIR /opt/kafka/

COPY ./bin /opt/eosio/bin

ENV EOSIO_ROOT=/opt/eosio
ENV PATH /opt/eosio/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LD_LIBRARY_PATH /usr/lib:/usr/lib/x86_64-linux-gnu

EXPOSE 8888
EXPOSE 9876
EXPOSE 9092

ENV kafka_uri 0.0.0.0:9092

ENV message_format msgpack

ENV environment_parameter Dev

ENV ssl_enabled false
#ENV ssl_key_location /opt/eosio.contracts/kafka_user_key
#ENV ssl_certificate_location /opt/eosio.contracts/kafka_user_cert
#ENV ssl_ca_location /opt/eosio.contracts/kafka_ca_cert

ENV cors_enabled true

WORKDIR /opt/kafka/

#CMD ./kafkatest.sh

CMD nodeos --genesis-json /opt/kafka/genesis.json --disable-replay-opts --data-dir /opt/kafka --config-dir /opt/kafka $KAFKA_ARGS
