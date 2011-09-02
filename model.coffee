mongoose = require "mongoose"

mongoose.connect 'mongodb://localhost/search_engine'

Schema = mongoose.Schema

PageContentSchema = new Schema
  url   : { type: String, index: {unique: true}}
  url   : { type: String, index: {unique: true}}
  title : { type: String, index: true }
  body  : { type: String, index: true }
  words : { type: Array, index: true }
  status: { type: String, index: true }

exports.PageContent = mongoose.model('PageContent', PageContentSchema)

