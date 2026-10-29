#!/usr/bin/env bash
set -eo pipefail

# Map inputs from environment variables (or fallback to positional arguments for backwards compatibility)
MONGODB_VERSION="${MONGODB_VERSION:-${1:-latest}}"
MONGODB_REPLICA_SET="${MONGODB_REPLICA_SET:-${2:-}}"
MONGODB_PORT="${MONGODB_PORT:-${3:-27017}}"
MONGODB_ROOT_USERNAME="${MONGODB_ROOT_USERNAME:-${4:-}}"
MONGODB_ROOT_PASSWORD="${MONGODB_ROOT_PASSWORD:-${5:-}}"
MONGODB_DB="${MONGODB_DB:-}"
CONTAINER_NAME="${CONTAINER_NAME:-mongodb}"
CONNECTION_TIMEOUT="${CONNECTION_TIMEOUT:-45}"

# Mask sensitive credentials in GitHub Actions output
if [ -n "${MONGODB_ROOT_PASSWORD}" ]; then
  echo "::add-mask::${MONGODB_ROOT_PASSWORD}"
fi

if [ -z "${MONGODB_VERSION}" ]; then
  echo "Missing MongoDB version in the [mongodb-version] input. Received empty value."
  exit 2
fi

# Ensure existing container with the same name is removed to avoid conflicts
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
  echo "Removing existing container [${CONTAINER_NAME}]..."
  docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
fi

if [ -z "${MONGODB_REPLICA_SET}" ]; then
  echo "::group::Starting single-node MongoDB"
  echo "  - version: [${MONGODB_VERSION}]"
  echo "  - port: [${MONGODB_PORT}]"
  echo "  - container: [${CONTAINER_NAME}]"
  if [ -n "${MONGODB_ROOT_USERNAME}" ]; then
    echo "  - username: [${MONGODB_ROOT_USERNAME}]"
    echo "  - password: [*** masked ***]"
  fi
  if [ -n "${MONGODB_DB}" ]; then
    echo "  - database: [${MONGODB_DB}]"
  fi
  echo "::endgroup::"

  # Work around MongoDB SERVER-121912 (TCMalloc per-CPU rseq incompatibility on Linux kernel 6.19+)
  DOCKER_ENV_ARGS=(--env "GLIBC_TUNABLES=glibc.pthread.rseq=1")
  if [ -n "${MONGODB_ROOT_USERNAME}" ]; then
    DOCKER_ENV_ARGS+=(--env "MONGO_INITDB_ROOT_USERNAME=${MONGODB_ROOT_USERNAME}")
    DOCKER_ENV_ARGS+=(--env "MONGO_INITDB_ROOT_PASSWORD=${MONGODB_ROOT_PASSWORD}")
  fi
  if [ -n "${MONGODB_DB}" ]; then
    DOCKER_ENV_ARGS+=(--env "MONGO_INITDB_DATABASE=${MONGODB_DB}")
  fi

  docker run \
    --name "${CONTAINER_NAME}" \
    --publish "${MONGODB_PORT}:${MONGODB_PORT}" \
    --detach \
    "${DOCKER_ENV_ARGS[@]}" \
    mongo:"${MONGODB_VERSION}" \
    mongod --port "${MONGODB_PORT}" --bind_ip_all

  echo "::group::Waiting for MongoDB to accept connections"
  AUTH_ARGS=()
  if [ -n "${MONGODB_ROOT_USERNAME}" ]; then
    AUTH_ARGS=(--username "${MONGODB_ROOT_USERNAME}" --password "${MONGODB_ROOT_PASSWORD}" --authenticationDatabase admin)
  fi

  TIMER=0
  until docker exec "${CONTAINER_NAME}" mongosh --port "${MONGODB_PORT}" "${AUTH_ARGS[@]}" --quiet --eval "db.adminCommand({ ping: 1 })" >/dev/null 2>&1
  do
    sleep 1
    TIMER=$((TIMER + 1))
    echo -n "."

    if [ "${TIMER}" -ge "${CONNECTION_TIMEOUT}" ]; then
      echo ""
      echo "MongoDB did not become ready within ${CONNECTION_TIMEOUT} seconds. Container logs:"
      docker logs "${CONTAINER_NAME}"
      exit 2
    fi
  done

  echo ""
  echo "MongoDB is ready and accepting connections!"
  echo "::endgroup::"

  # Construct connection string
  if [ -n "${MONGODB_ROOT_USERNAME}" ]; then
    CONN_STR="mongodb://${MONGODB_ROOT_USERNAME}:${MONGODB_ROOT_PASSWORD}@127.0.0.1:${MONGODB_PORT}/?authSource=admin"
    if [ -n "${MONGODB_DB}" ]; then
      CONN_STR="mongodb://${MONGODB_ROOT_USERNAME}:${MONGODB_ROOT_PASSWORD}@127.0.0.1:${MONGODB_PORT}/${MONGODB_DB}?authSource=admin"
    fi
  else
    CONN_STR="mongodb://127.0.0.1:${MONGODB_PORT}"
    if [ -n "${MONGODB_DB}" ]; then
      CONN_STR="mongodb://127.0.0.1:${MONGODB_PORT}/${MONGODB_DB}"
    fi
  fi

  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "connection-string=${CONN_STR}" >> "${GITHUB_OUTPUT}"
    echo "port=${MONGODB_PORT}" >> "${GITHUB_OUTPUT}"
    echo "replica-set=" >> "${GITHUB_OUTPUT}"
    echo "container-name=${CONTAINER_NAME}" >> "${GITHUB_OUTPUT}"
  fi

  exit 0
fi

# Replica set handling
echo "::group::Starting MongoDB single-node replica set"
if [ -n "${MONGODB_ROOT_USERNAME}" ]; then
  echo "Replica set does not support credentials yet. Please run replica sets without credentials or see documentation."
  exit 1
fi

echo "  - version: [${MONGODB_VERSION}]"
echo "  - port: [${MONGODB_PORT}]"
echo "  - replica set: [${MONGODB_REPLICA_SET}]"
echo "  - container: [${CONTAINER_NAME}]"
echo "::endgroup::"

docker run \
  --name "${CONTAINER_NAME}" \
  --publish "${MONGODB_PORT}:${MONGODB_PORT}" \
  --detach \
  --env "GLIBC_TUNABLES=glibc.pthread.rseq=1" \
  mongo:"${MONGODB_VERSION}" \
  mongod --replSet "${MONGODB_REPLICA_SET}" --port "${MONGODB_PORT}" --bind_ip_all

echo "::group::Waiting for MongoDB to accept connections"
TIMER=0
until docker exec "${CONTAINER_NAME}" mongosh --port "${MONGODB_PORT}" --quiet --eval "db.adminCommand({ ping: 1 })" >/dev/null 2>&1
do
  sleep 1
  TIMER=$((TIMER + 1))
  echo -n "."

  if [ "${TIMER}" -ge "${CONNECTION_TIMEOUT}" ]; then
    echo ""
    echo "MongoDB did not become ready within ${CONNECTION_TIMEOUT} seconds. Container logs:"
    docker logs "${CONTAINER_NAME}"
    exit 2
  fi
done

echo ""
echo "MongoDB process ready. Initiating replica set [${MONGODB_REPLICA_SET}]..."
echo "::endgroup::"

echo "::group::Initiating replica set [${MONGODB_REPLICA_SET}]"
docker exec "${CONTAINER_NAME}" mongosh --port "${MONGODB_PORT}" --quiet --eval "
  rs.initiate({
    _id: '${MONGODB_REPLICA_SET}',
    members: [ { _id: 0, host: '127.0.0.1:${MONGODB_PORT}' } ]
  })
"

# Wait for primary election
TIMER=0
until docker exec "${CONTAINER_NAME}" mongosh --port "${MONGODB_PORT}" --quiet --eval "db.adminCommand({ hello: 1 }).isWritablePrimary" | grep -q 'true'
do
  sleep 1
  TIMER=$((TIMER + 1))
  echo -n "."

  if [ "${TIMER}" -ge "${CONNECTION_TIMEOUT}" ]; then
    echo ""
    echo "Replica set did not elect a primary within ${CONNECTION_TIMEOUT} seconds."
    docker exec "${CONTAINER_NAME}" mongosh --port "${MONGODB_PORT}" --eval "rs.status()"
    exit 2
  fi
done

echo ""
echo "Success! Initiated replica set [${MONGODB_REPLICA_SET}] and primary is elected."
docker exec "${CONTAINER_NAME}" mongosh --port "${MONGODB_PORT}" --quiet --eval "rs.status().members.map(m => ({ id: m._id, name: m.name, stateStr: m.stateStr }))"
echo "::endgroup::"

CONN_STR="mongodb://127.0.0.1:${MONGODB_PORT}/?replicaSet=${MONGODB_REPLICA_SET}"
if [ -n "${MONGODB_DB}" ]; then
  CONN_STR="mongodb://127.0.0.1:${MONGODB_PORT}/${MONGODB_DB}?replicaSet=${MONGODB_REPLICA_SET}"
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "connection-string=${CONN_STR}" >> "${GITHUB_OUTPUT}"
  echo "port=${MONGODB_PORT}" >> "${GITHUB_OUTPUT}"
  echo "replica-set=${MONGODB_REPLICA_SET}" >> "${GITHUB_OUTPUT}"
  echo "container-name=${CONTAINER_NAME}" >> "${GITHUB_OUTPUT}"
fi
