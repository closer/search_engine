mongoose = require "mongoose"

mongoose.connect 'mongodb://localhost/search_engine'

Schema = mongoose.Schema

PageSchema = new Schema
  url   : { type: String, index: {unique: true}}
  title : { type: String, index: true }
  body  : { type: String, index: true }
  words : { type: Array, index: true }
  status: { type: String, index: true }

QueueSchema = new Schema
  url   : { type: String }
  from  : { type: String }
  title : { type: String }

module.exports =
  Page  : mongoose.model('Page',  PageSchema)
  Queue : mongoose.model('Queue', QueueSchema)

