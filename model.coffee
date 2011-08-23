mongoose = require "mongoose"

mongoose.connect 'mongodb://localhost/spider'

Schema = mongoose.Schema

PageContentSchema = new Schema
  url   : { type: String, index: {unique: true}}
  title : { type: String }
  body  : { type: String }
  words : { type: Array }
  status: { type: String }

exports.PageContent = mongoose.model('PageContent', PageContentSchema)

