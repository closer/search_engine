mongoose = require "mongoose"

mongoose.connect 'mongodb://localhost/search_engine'

Schema = mongoose.Schema

PageSchema = new Schema
  url   : { type: String, index: { unique: true } }
  title : { type: String }
  body  : { type: String }
  plain : { type: String }
  words : { type: Array, index: true }
  status: { type: String, index: true }

  spider_queue       : { type: Boolean, index: true }
  html_parser_queue  : { type: Boolean, index: true }
  link_tracker_queue : { type: Boolean, index: true }

module.exports =
  Page             : mongoose.model('Page',             PageSchema)

