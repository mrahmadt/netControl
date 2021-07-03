#!/usr/bin/env bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
SETUP_DIR="${BASE_DIR}/setup"

echo "[$BASE_DIR]"

echo "/install.sh"
cat ${SETUP_DIR}/functions.sh.template ${SETUP_DIR}/install.sh.template > ${BASE_DIR}/install.sh

echo "src/uninstall.sh"
cat ${SETUP_DIR}/functions.sh.template ${SETUP_DIR}/uninstall.sh.template > ${BASE_DIR}/src/uninstall.sh