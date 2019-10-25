#!/bin/bash

DEPLOYMENT_SERVER_USER=$1
cd /home || exit
cd $DEPLOYMENT_SERVER_USER || exit
docker-compose up -d