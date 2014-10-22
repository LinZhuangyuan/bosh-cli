#!/usr/bin/env bash

set -ex

echo "Running ci/run-acceptance-with-vm-in-container.sh"
echo "ENV:"
echo `env`

BOSH_MICRO_CLI_DIR=/home/ubuntu/go/src/github.com/cloudfoundry/bosh-micro-cli

#inside the docker container
BOSH_MICRO_PRIVATE_KEY_DIR=/home/ubuntu/private_keys
PRIVATE_KEY_DIR=$(cd $(dirname $BOSH_LITE_PRIVATE_KEY) && pwd)

echo "ENV:"
echo `env`

# Pushing to Docker Hub requires login
DOCKER_IMAGE=${DOCKER_IMAGE:-bosh/micro}

# To push to the Pivotal GoCD Docker Registry (behind firewall):
# DOCKER_IMAGE=docker.gocd.cf-app.com:5000/bosh-container

SRC_DIR=$(cd $(dirname $0)/.. && pwd)
chmod -R o+w $SRC_DIR

echo "Running '$@' in docker container '$DOCKER_IMAGE'..."

docker run \
  -e BOSH_AWS_ACCESS_KEY_ID \
  -e BOSH_AWS_SECRET_ACCESS_KEY \
  -e BOSH_LITE_KEYPAIR \
  -e BOSH_LITE_SUBNET_ID \
  -e BOSH_LITE_NAME \
  -e BOSH_LITE_SECURITY_GROUP \
  -e BOSH_LITE_PRIVATE_KEY \
  -e BOSH_MICRO_STEMCELL \
  -e BOSH_MICRO_CPI_RELEASE \
  -v $SRC_DIR:$BOSH_MICRO_CLI_DIR \
  -v $PRIVATE_KEY_DIR:$BOSH_MICRO_PRIVATE_KEY_DIR \
  $DOCKER_IMAGE \
  $BOSH_MICRO_CLI_DIR/bin/test-acceptance-with-vm --provider=aws \
  &

SUBPROC="$!"

trap "
  echo '--------------------- KILLING PROCESS'
  kill $SUBPROC

  echo '--------------------- KILLING CONTAINERS'
  docker ps -q | xargs docker kill
" SIGTERM SIGINT # gocd sends TERM; INT just nicer for testing with Ctrl+C

wait $SUBPROC