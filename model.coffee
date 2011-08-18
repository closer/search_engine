mongoose = require "mongoose"

mongoose.connect 'mongodb://localhost/spider'

Schema = mongoose.Schema

PageContentSchema = new Schema
  url   : { type: String }
  title : { type: String }
  body  : { type: String }
  words : { type: Array }

exports.PageContent = mongoose.model('PageContent', PageContentSchema)

