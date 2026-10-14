'use strict'

const Lab = require('@hapi/lab')
const Mongoose = require('mongoose')
const { expect } = require('@hapi/code')
const { describe, it } = (exports.lab = Lab.script())
const { MONGODB_USERNAME = null, MONGODB_PASSWORD = null, MONGODB_CONNECTION_STRING = null } = process.env

if (!MONGODB_USERNAME) {
  describe('MongoDB Single Instance ->', () => {
    it('connects to MongoDB', async () => {
      const uri = MONGODB_CONNECTION_STRING || 'mongodb://127.0.0.1:27017'
      await expect(
        Mongoose.connect(uri, {
          serverSelectionTimeoutMS: 3000
        })
      ).to.not.reject()
      await Mongoose.disconnect()
    })

    it('fails to connect to non-existent MongoDB instance', async () => {
      await expect(
        Mongoose.connect('mongodb://127.0.0.1:27018', {
          serverSelectionTimeoutMS: 1000
        })
      ).to.reject()
    })
  })
} else {
  describe('MongoDB Single Instance with credentials ->', () => {
    it('connects to MongoDB', async () => {
      const uri = MONGODB_CONNECTION_STRING || `mongodb://${MONGODB_USERNAME}:${MONGODB_PASSWORD}@127.0.0.1:27017/?authSource=admin`
      await expect(
        Mongoose.connect(uri, {
          serverSelectionTimeoutMS: 3000
        })
      ).to.not.reject()
      await Mongoose.disconnect()
    })

    it('fails to connect to non-existent MongoDB instance', async () => {
      await expect(
        Mongoose.connect(`mongodb://${MONGODB_USERNAME}:${MONGODB_PASSWORD}@127.0.0.1:27018/?authSource=admin`, {
          serverSelectionTimeoutMS: 1000
        })
      ).to.reject()
    })
  })
}
