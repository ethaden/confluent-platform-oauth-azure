#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

if [ \! -f "${DIR}/.env" ]; then
  echo "Error: .env file not found in ${DIR}. Please create it based on the .env-example file."
  exit 1
fi

docker compose up -d
