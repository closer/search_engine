_ = require 'underscore'

PageContent = require('./model').PageContent
TinySegmenter = require('./tiny_segmenter').TinySegmenter

IGNORE_CHARCTORS = _.flatten [
  [' ', '　'],
  [ '。', '、', '・', '･'],
  [',', '.', '"', "'"],
  ['で', 'に', 'を', 'は', 'の', 'が']]

console.log IGNORE_CHARCTORS

seg = new TinySegmenter

express = require("express")
app = module.exports = express.createServer()
app.configure ->
  app.set "views", "#{__dirname}/views"
  app.set "view engine", "jade"
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use require("stylus").middleware(src: "#{__dirname}/public")
  app.use app.router
  app.use express.static("#{__dirname}/public")

app.configure "development", ->
  app.use express.errorHandler
    dumpExceptions: true
    showStack: true

app.configure "production", ->
  app.use express.errorHandler()

app.get "/", (req, res) ->
  keyword = req.param('k')
  ajax = req.param('ajax') == "true"

  console.log '----------------------------'

  keywords = seg.segment keyword
  console.log keywords

  keywords = _.map keywords, (word)->
    return word.replace(/[\s]/g, '')
  console.log keywords

  keywords = keywords.sort()
  console.log keywords

  keywords = _.difference(keywords, IGNORE_CHARCTORS)
  console.log keywords

  keywords = _.uniq(keywords)
  console.log keywords

  keywords = _.compact keywords
  console.log keywords

  callback = (err, docs)->
    res.render 'index'
      layout: !ajax
      keyword: keyword
      keywords: keywords
      results: docs
  if !keyword
    callback(null, [])
  else
    PageContent.find { words : keywords }, callback

app.listen 8000
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env
