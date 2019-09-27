#!/bin/bash

DEPLOYMENT_SERVER_USER=$1
cd /home || exit
cd $DEPLOYMENT_SERVER_USER || exit
set -a
source ./odoo-variables.env
docker-compose up -d