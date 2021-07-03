#!/usr/bin/env bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
TOOLS_DIR="${BASE_DIR}/tools"

echo "[$BASE_DIR]"

echo "/install.sh"
cat ${TOOLS_DIR}/functions.sh.template ${TOOLS_DIR}/install.sh.template > ${BASE_DIR}/install.sh

echo "src/uninstall.sh"
cat ${TOOLS_DIR}/functions.sh.template ${TOOLS_DIR}/uninstall.sh.template > ${BASE_DIR}/src/uninstall.sh