'use strict'

const Lab = require('@hapi/lab')
const Mongoose = require('mongoose')
const { expect } = require('@hapi/code')
const { describe, it, before, after } = (exports.lab = Lab.script())
const { MONGODB_PORT = 27017, MONGODB_REPLICA_SET = 'mongodb-test-rs', MONGODB_CONNECTION_STRING = null } = process.env

describe('MongoDB Replica Set ->', () => {
  before(async () => {
    const connectionString = MONGODB_CONNECTION_STRING || `mongodb://127.0.0.1:${MONGODB_PORT}/test?replicaSet=${MONGODB_REPLICA_SET}`

    console.log('---------------------------------------------------------------------')
    console.log('connecting to MongoDB using connection string -> ' + connectionString)
    console.log('---------------------------------------------------------------------')

    await Mongoose.connect(connectionString, {
      serverSelectionTimeoutMS: 5000
    })
  })

  after(async () => {
    if (Mongoose.connection && Mongoose.connection.db) {
      await Mongoose.connection.db.dropDatabase()
    }
    await Mongoose.disconnect()
  })

  it('queries the replica set status', async () => {
    const db = Mongoose.connection.db.admin()
    const { ok, set } = await db.command({ replSetGetStatus: 1 })

    expect(ok).to.equal(1)
    expect(set).to.equal(MONGODB_REPLICA_SET)
  })

  it('saves a document', async () => {
    const Dog = Mongoose.model('Dog', new Mongoose.Schema({ name: String }))
    const albert = await new Dog({ name: 'Albert' }).save()
    expect(albert.name).to.equal('Albert')
  })

  it('uses transactions', async () => {
    const Customer = Mongoose.model('Customer', new Mongoose.Schema({ name: String }))
    await Customer.createCollection()

    const session = await Mongoose.startSession()
    session.startTransaction()

    await Customer.create([{ name: 'test-customer' }], { session })

    expect(
      await Customer.findOne({ name: 'test-customer' })
    ).to.not.exist()

    expect(
      await Customer.findOne({ name: 'test-customer' }).session(session)
    ).to.exist()

    await session.commitTransaction()
    await session.endSession()

    expect(
      await Customer.findOne({ name: 'test-customer' })
    ).to.exist()
  })
})
