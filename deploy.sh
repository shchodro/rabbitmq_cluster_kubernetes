#!/bin/bash

REVISION=$1

if [ -z $REVISION ]; then
  echo "ERROR: no revision specified"
  echo "USAGE: deploy.sh revision"
  exit 1
fi

# Initial deployment
# helm install --name=rabbitmq helm-chart --set revision=XXXXXXX

exec helm upgrade rabbitmq helm-chart --set revision=$REVISION
