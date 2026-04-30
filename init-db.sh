#!/usr/bin/env bash

mkdir -p data/db data/rt data/logs data/imports
cp -r samples/* data/imports
chmod -R 777 data
