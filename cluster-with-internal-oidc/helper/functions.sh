#!/bin/bash

update_cli_permissions(){

  # Script to get Confluent CLI `curl -k CLI_URL -o confluent`
  # Update the confluent cli permissions
  CONFLUENT_CLI='./bin/confluent'
  if [ -f $CONFLUENT_CLI ]; then
    echo "Updating permission of ${CONFLUENT_CLI} to 744"
    chmod 744 $CONFLUENT_CLI
  fi

}

create_client_files(){

  echo "Creating client files"
  cat templates/superuser.template | envsubst > mount/superuser.properties
  cat templates/client.template | envsubst > mount/client.properties

}
