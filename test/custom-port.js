'use strict'

const Lab = require('@hapi/lab')
const Mongoose = require('mongoose')
const { expect } = require('@hapi/code')
const { describe, it } = (exports.lab = Lab.script())
const { MONGODB_PORT = 27017, MONGODB_USERNAME = null, MONGODB_PASSWORD = null, MONGODB_CONNECTION_STRING = null } = process.env

if (!MONGODB_USERNAME) {
  describe('MongoDB Instance on Custom Port ->', () => {
    it('connects to MongoDB on custom port', async () => {
      const uri = MONGODB_CONNECTION_STRING || `mongodb://127.0.0.1:${MONGODB_PORT}`
      await expect(
        Mongoose.connect(uri, {
          serverSelectionTimeoutMS: 3000
        })
      ).to.not.reject()
      await Mongoose.disconnect()
    })
  })
} else {
  describe('MongoDB Instance on Custom Port with credentials ->', () => {
    it('connects to MongoDB on custom port', async () => {
      const uri = MONGODB_CONNECTION_STRING || `mongodb://${MONGODB_USERNAME}:${MONGODB_PASSWORD}@127.0.0.1:${MONGODB_PORT}/?authSource=admin`
      await expect(
        Mongoose.connect(uri, {
          serverSelectionTimeoutMS: 3000
        })
      ).to.not.reject()
      await Mongoose.disconnect()
    })
  })
}
