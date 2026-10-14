# AGENTS.md

## Overview

This repository provides GitHub Actions for spinning up and tearing down MongoDB instances and replica sets in CI workflows using Docker:

- **Root Action (`action.yml`)**: Composite action executing `start-mongodb.sh` to run MongoDB (`7.0`, `8.0`, `latest`) via Docker, configure standalone or single-node replica set instances, and emit output connection parameters.
- **Teardown Action (`teardown/action.yml`)**: Companion composite action running `teardown/stop-mongodb.sh` to stop and remove containers cleanly.
- **Test Suite (`test/`)**: Node.js integration tests built with `@hapi/lab`, `@hapi/code`, and `mongoose`.

## Setup commands

- Install dependencies: `npm install` (or `npm ci`)
- Note for Windows environments: Use `npm.cmd` if PowerShell execution policy blocks `.ps1` wrapper scripts.

## Build and test commands

### Smallest Sensible Subset Validation

Never run the full test suite when only isolated components or specific workflows are touched. Always target the specific test file corresponding to the changed functionality:

- **List tests (dry-run, no container required)**:
  ```bash
  npm run list-tests
  ```

- **Single instance tests**:
  ```bash
  npm test ./test/single-instance.js
  ```

- **Custom port tests**:
  ```bash
  npm test ./test/custom-port.js
  ```

- **Replica set tests**:
  ```bash
  npm test ./test/replica-set.js
  ```

- **Target single test by ID**:
  ```bash
  npm run test-single -- <test_id>
  ```

- **Full test suite sweep (CI only or final pre-release validation)**:
  ```bash
  npm test
  ```

### Test Runtime Requirements

The Node.js tests in `test/` are live integration tests that require an active MongoDB server. When executing tests locally or in custom runners:
- Start the target MongoDB container first, or provide an active connection URI via environment variables.
- Configurable test environment variables:
  - `MONGODB_CONNECTION_STRING`: Complete connection URI (takes precedence).
  - `MONGODB_PORT`: MongoDB port (defaults to `27017`).
  - `MONGODB_USERNAME`: Root username for authenticated tests.
  - `MONGODB_PASSWORD`: Root password for authenticated tests.
  - `MONGODB_REPLICA_SET`: Replica set name for replica set tests (defaults to `mongodb-test-rs`).

## Component Boundaries & Rules

1. **Root Action (`action.yml` & `start-mongodb.sh`)**:
   - Maps GitHub Action inputs into environment variables (`MONGODB_VERSION`, `MONGODB_PORT`, `MONGODB_REPLICA_SET`, `MONGODB_ROOT_USERNAME`, `MONGODB_ROOT_PASSWORD`, `MONGODB_DB`, `CONTAINER_NAME`, `CONNECTION_TIMEOUT`).
   - Uses `mongosh` inside the container for health-check pings and replica set initiation.
   - Masks passwords in GitHub Action logs using `::add-mask::`.
   - Populates `$GITHUB_OUTPUT` with `connection-string`, `port`, `replica-set`, and `container-name`.
   - **Constraint**: Replica sets currently do not support authentication (`MONGODB_ROOT_USERNAME`).
   - **Pre-execution cleanup**: Automatically detects and stops conflicting containers with the same name before launching.

2. **Teardown Action (`teardown/action.yml` & `teardown/stop-mongodb.sh`)**:
   - Takes `container-name` (default: `mongodb`).
   - Gracefully stops and forcefully removes the container if it exists.
   - Must remain idempotent (succeed even if the container has already stopped or does not exist).

3. **Workflow Tests (`.github/workflows/`)**:
   - `.github/workflows/test-single-instance.yml`: Matrix tests (`7.0`, `8.0`) across default port, custom port, and credential combinations.
   - `.github/workflows/test-replica-set.yml`: Matrix tests (`7.0`, `8.0`) across default and custom ports with transactions and replica set validation.

## Code Style & Conventions

- **JavaScript**: CommonJS (`'use strict'`), 2-space indentation, single quotes, no unnecessary semicolons. Tests use `@hapi/lab` (`describe`, `it`, `before`, `after`) and `@hapi/code` (`expect(...)`).
- **Shell Scripts**:
  - `#!/usr/bin/env bash` with `set -eo pipefail`.
  - Prefer environment variables with fallback defaults: `${VAR:-default}`.
  - Use GitHub Actions log grouping (`echo "::group::..."` / `echo "::endgroup::"`).
  - Ensure compatibility with standard Linux runner environments (`ubuntu-latest`).
- **Commit Messages**: Conventional Commits standard (e.g., `feat: ...`, `fix: ...`, `refactor: ...`, `docs: ...`, `chore: ...`). This repository uses Release Please (`.github/workflows/release-please.yml`) to generate changelogs and bump versions automatically.

## PR Instructions

- Follow the Conventional Commit format for PR titles and commit messages.
- If modifying action inputs or outputs, ensure:
  1. `action.yml` input/output definitions are updated.
  2. `start-mongodb.sh` handles the new or changed environment variable.
  3. `README.md` action reference tables and examples are kept in sync.
  4. Scoped tests in `test/` and workflows in `.github/workflows/` are updated to cover the changes.
