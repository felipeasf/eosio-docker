# Infrastructure Docker

## Requirements:

Check the following instructions before starting docker:

 - All contract binaries (eosio and ultra contracts) must have to be in the contracts folder `nodes/data/contracts`. Create a folder for each contract
 E.g.: nodes/data/contracts/eosio.system, nodes/data/contracts/ultra.nft.
 - Check if the biaries are in the `nodes/bin` folder.
 - Ensure that nodeos was built with kafka plugin

## Run Instructions

### Startup script
Run the startup script to create, configure and run the containers

```
Usage: ./startup.sh {PRODUCERS}
```
Where {PRODUCERS} is the number of producers that you want to run.

It's indicated to run at least 3 producers to have a multi-node architecture.

If you want to run in a single-node architecture, run with 0

Ex.:

```
./startup.sh 3

./startup.sh 0
```

### Stopping

To stop and clean up the containers run:
```
docker-compose down
```

## Validating

### Kibana
Open on browser

http://127.0.0.1:5601/


### RabbitMQ
Open on browser

http://localhost:15672/

### Hyperion API

```
curl http://127.0.0.1:7000/v2/history/get_actions
```
In case of any problems, try to restart hyperion-api container

```
docker restart hyperion-api
```
