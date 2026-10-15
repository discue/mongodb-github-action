# Changelog

## [2.0.1](https://github.com/discue/mongodb-github-action/compare/v2.0.0...v2.0.1) (2026-10-15)


### Bug Fixes

* increase default timeout ([6cf8c24](https://github.com/discue/mongodb-github-action/commit/6cf8c247cdb650c1e3dec42026a6051e191f9fac))

## 2.0.0 (2026-10-14)


### Features

* modernize this action ([9bda63d](https://github.com/discue/mongodb-github-action/commit/9bda63dacc22cf87c84b754ba3e840d8ed488593))


### Miscellaneous Chores

* release 2.0.0 ([8a06bdc](https://github.com/discue/mongodb-github-action/commit/8a06bdc9f750dd5b3244107bceb87c0bd11fe7ea))

## [1.7.0](https://github.com/superchargejs/mongodb-github-action/compare/v1.6.0...v1.7.0) - 2021-07-21

### Added
- enable to set username and password

## [1.6.0](https://github.com/superchargejs/mongodb-github-action/compare/v1.5.0...v1.6.0) - 2021-06-01

### Added
- show replica set status after `rs.initiate()`

## [1.5.0](https://github.com/superchargejs/mongodb-github-action/compare/v1.4.1...v1.5.0) - 2021-05-31

### Added
- refined tests for custom ports
- refined custom port handling when using replica sets
- extended output for better debugging in GitHub Actions

## [1.4.1](https://github.com/superchargejs/mongodb-github-action/compare/v1.4.0...v1.4.1) - 2021-05-24

### Updated
- use strings for `mongodb-version` in Readme and GitHub Actions Workflows

## [1.4.1](https://github.com/superchargejs/mongodb-github-action/compare/v1.4.0...v1.4.1) - 2021-05-24

### Added
- `mongodb-port` input allowing to start a MongoDB instance (or single-node replica set) on a custom port

## [1.4.0](https://github.com/superchargejs/mongodb-github-action/compare/v1.3.0...v1.4.0) - 2021-05-11

### Added
- `mongodb-port` input allowing to start a MongoDB instance (or single-node replica set) on a custom port

## [1.3.0](https://github.com/superchargejs/mongodb-github-action/compare/v1.2.0...v1.3.0) - 2020-04-10

### Added
- check if the `mongodb-version` input is present: if not, print a message and fail the job

## [1.2.0](https://github.com/superchargejs/mongodb-github-action/compare/v1.1.0...v1.2.0) - 2020-03-30

### Added
- `mongodb-replica-set` input to define a MongoDB replica set name
- tests connecting to MongoDB instances (single instance, replica set) created by this GitHub Action

## [1.1.0](https://github.com/superchargejs/mongodb-github-action/compare/v1.0.0...v1.1.0) - 2019-12-18

### Updated
- switched from a Node.js workflow to a Docker-based workflow
  - reduces noise in the repo by removing the Node.js dependencies and only relying on a shell script
- green database icon in GitHub Action details

## 1.0.0 - 2019-12-17

### Added
- `1.0.0` release 🚀 🎉
