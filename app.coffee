util = require './util'

PageContent = require('./model').PageContent

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

  keywords = util.segmenter keyword

  callback = (err, docs)->
    res.render 'index'
      layout: !ajax
      keyword: keyword
      keywords: keywords
      results: docs

  if !keyword
    callback(null, [])
  else
    PageContent.find { words : { $all: keywords } }, callback

app.listen 8000
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env
