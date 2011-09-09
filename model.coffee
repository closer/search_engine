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

  spider_queues       : [ { type: Schema.ObjectId, ref: 'SpiderQueue' } ]
  html_parser_queues  : [ { type: Schema.ObjectId, ref: 'HtmlParserQueue' } ]
  link_tracker_queues : [ { type: Schema.ObjectId, ref: 'LinkTrackerQueue' } ]

QueueSchema = new Schema
  created_at: { type: Date }
  page : { type : Schema.ObjectId, ref: 'Page' }

module.exports =
  Page             : mongoose.model('Page',  PageSchema)
  SpiderQueue      : mongoose.model('SpiderQueue', QueueSchema)
  HtmlParserQueue  : mongoose.model('HtmlParserQueue', QueueSchema)
  LinkTrackerQueue : mongoose.model('LinkTrackerQueue', QueueSchema)

