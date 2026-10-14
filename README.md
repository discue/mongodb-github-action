# MongoDB GitHub Action

A GitHub Action that starts a modern MongoDB server or MongoDB replica set in your CI/CD workflow. Built as a fast, native composite action targeting recent MongoDB versions (`7.0`, `8.0`, `latest`).

## Features

- **Fast & Lightweight**: Implemented as a GitHub Actions Composite Action (`using: composite`) that runs directly against the runner's Docker engine without extra image-build overhead.
- **Modern MongoDB Support**: Built specifically for modern MongoDB (`7.0`, `8.0`, `latest`) using `mongosh`.
- **Workflow-Ready Outputs**: Automatically emits `connection-string`, `port`, `replica-set`, and `container-name` outputs so subsequent steps in your workflow can connect immediately.
- **Enterprise Security**: Automatically masks sensitive inputs (`mongodb-root-password`) via GitHub Actions log masking (`::add-mask::`) and avoids logging credentials.
- **Teardown & Cleanup Support**: Includes automatic startup conflict cleanup and an optional `teardown` companion sub-action (`discue/mongodb-github-action/teardown@v2`) for guaranteed post-job container removal.
- **Port & Container Flexibility**: Configurable ports, container names, connection timeouts, and database initialization.

---

## Usage

### Basic Single Instance with Cleanup

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 'lts/*'

      - name: Start MongoDB
        id: mongodb
        uses: discue/mongodb-github-action@v2
        with:
          mongodb-version: '8.0'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test
        env:
          # Connect to the MongoDB server running in this workflow:
          MONGODB_URI: ${{ steps.mongodb.outputs.connection-string }}

      - name: Stop MongoDB
        if: always() # Ensures cleanup runs even if previous steps failed
        uses: discue/mongodb-github-action/teardown@v2
```

---

### Connecting to MongoDB in the Same Workflow

Steps running in the same workflow job can connect to the MongoDB instance using either:

1. **The Action Output (Recommended)**:
   ```yaml
   env:
     MONGODB_URI: ${{ steps.mongodb.outputs.connection-string }}
   ```
2. **Direct Localhost / 127.0.0.1 URI**:
   ```
   mongodb://127.0.0.1:27017
   ```
   > **Note**: For Node.js `lts/*` applications, use `127.0.0.1` rather than `localhost` to ensure IPv4 loopback connection compatibility.

---

### With Username and Password

```yaml
      - name: Start MongoDB with Authentication
        id: mongodb
        uses: discue/mongodb-github-action@v2
        with:
          mongodb-version: '8.0'
          mongodb-root-username: admin
          mongodb-root-password: ${{ secrets.MONGODB_PASSWORD }}
          mongodb-db: my_database

      - name: Run tests
        run: npm test
        env:
          MONGODB_URI: ${{ steps.mongodb.outputs.connection-string }}

      - name: Stop MongoDB
        if: always()
        uses: discue/mongodb-github-action/teardown@v2
```

---

### Using a Custom Port

```yaml
      - name: Start MongoDB on Custom Port
        id: mongodb
        uses: discue/mongodb-github-action@v2
        with:
          mongodb-version: '7.0'
          mongodb-port: 27018
          container-name: mongodb-custom

      - name: Run tests
        run: npm test
        env:
          MONGODB_URI: ${{ steps.mongodb.outputs.connection-string }}

      - name: Stop MongoDB
        if: always()
        uses: discue/mongodb-github-action/teardown@v2
        with:
          container-name: mongodb-custom
```

---

### With a Single-Node Replica Set

Replica sets are ideal for testing features like MongoDB Transactions, Change Streams, and multi-document consistency.

> **Note**: Replica sets are currently **unauthenticated**. Providing `mongodb-root-username` or `mongodb-root-password` together with `mongodb-replica-set` is not currently supported.

```yaml
      - name: Start MongoDB Replica Set
        id: mongodb
        uses: discue/mongodb-github-action@v2
        with:
          mongodb-version: '8.0'
          mongodb-replica-set: rs0

      - name: Run tests
        run: npm test
        env:
          MONGODB_URI: ${{ steps.mongodb.outputs.connection-string }}

      - name: Stop MongoDB
        if: always()
        uses: discue/mongodb-github-action/teardown@v2
```

---

## Action Reference

### Main Action Inputs (`discue/mongodb-github-action@v2`)

| Input | Required | Default | Description |
| :--- | :---: | :---: | :--- |
| `mongodb-version` | No | `'latest'` | MongoDB Docker image tag (e.g. `'7.0'`, `'8.0'`, `'latest'`). |
| `mongodb-replica-set` | No | `''` | Replica set name (if set, initializes a single-node replica set). |
| `mongodb-port` | No | `'27017'` | Port mapped on the runner host. |
| `mongodb-root-username` | No | `''` | Root username for authentication (single-instance only). |
| `mongodb-root-password` | No | `''` | Root password for authentication (single-instance only; automatically masked). |
| `mongodb-db` | No | `''` | Initial database name to create. |
| `container-name` | No | `'mongodb'` | Name of the Docker container on the host. |
| `connection-timeout` | No | `'30'` | Maximum wait time in seconds for MongoDB to accept connections. |

### Main Action Outputs

| Output | Description | Example |
| :--- | :--- | :--- |
| `connection-string` | Complete MongoDB connection URI ready for client use | `mongodb://admin:pass@127.0.0.1:27017/?authSource=admin` |
| `port` | Exposed host port | `27017` |
| `replica-set` | Replica set name (if enabled) | `rs0` |
| `container-name` | Docker container name | `mongodb` |

### Teardown Sub-Action Inputs (`discue/mongodb-github-action/teardown@v2`)

| Input | Required | Default | Description |
| :--- | :---: | :---: | :--- |
| `container-name` | No | `'mongodb'` | Docker container name to stop and remove. |

---

## License

MIT © [discue](https://github.com/discue) (Originally forked from [supercharge](https://github.com/supercharge))
