#!/bin/bash

DEPLOYMENT_SERVER_USER=$1
cd /home || exit
cd $DEPLOYMENT_SERVER_USER || exit
if [ -z "$(docker-compose ps -q odoo)" ] || [ -z "$(docker ps -q --no-trunc | grep "$(docker-compose ps -q odoo)")" ]; then
  # not running
  docker-compose up -d
else
  # already running, restart to activate changes
  docker-compose restart
fi