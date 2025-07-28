#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

if [ \! -f "${DIR}/.env" ]; then
  echo "Error: .env file not found in ${DIR}. Please create it based on the .env-example file."
  exit 1
fi
echo "Processing .env"
source .env
source ${DIR}/helper/cp_config.sh
source ${DIR}/helper/functions.sh

#-------------------------------------------------------------------------------
# Update cli permission to be executable
update_cli_permissions

# Create client files to be used for produce/consume
create_client_files

create_env_file

docker compose up -d
