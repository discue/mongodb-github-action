#!/usr/bin/env bash
set -eo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-mongodb}"

echo "::group::Stopping and removing MongoDB container [${CONTAINER_NAME}]"

if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
  echo "Stopping container [${CONTAINER_NAME}]..."
  docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
  docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
  echo "Successfully stopped and removed container [${CONTAINER_NAME}]."
else
  echo "No container named [${CONTAINER_NAME}] was found."
fi

echo "::endgroup::"
