#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd "$SCRIPT_PATH"

ACCOUNT_DATA_DIR="$1"
if [[ -d "${SCRIPT_PATH}/account-data" ]]; then
  ACCOUNT_DATA_DIR="${SCRIPT_PATH}/account-data"
fi

if [[ ! -d "$ACCOUNT_DATA_DIR" ]]; then
  echo "CloudMapper account-data dir not found"
  echo "Usage: $0 /path/to/cloudmapper/account-data"
  exit 1
fi 

docker run -it --rm \
  -v "${ACCOUNT_DATA_DIR}/":/opt/sgaudit/account-data \
  sgaudit
