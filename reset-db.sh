#!/usr/bin/env bash

echo "Shutting down DB service"
docker compose down
echo "Deleting DB"
sudo rm -rf data
echo "Deleting client RT logs"
sudo rm -rf /tmp/rt/dbs-fxpub*
echo "Re-initializing DB"
./init-db.sh
