Segmenter = require('./mecab_test').Segmenter

PageContent = require('./model').PageContent

seg = new Segmenter

per_page = 10

body_helper = (body, keywords)->
  results = []
  for word in keywords
    i = body.indexOf(word)
    results.push(
      body.substr(i-10, 10) +
      "<strong>" +
      body.substr(i, word.length) +
      "</strong>" +
      body.substr(i+word.length, 10))
  results.join('...')

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
  page = if p = req.param('p') then parseInt(p) else 0
  keywords = []
  ajax = req.param('ajax') == "true"

  callback = (err, docs)->
    console.log docs
    res.render 'index'
      layout: !ajax
      keyword: keyword
      keywords: keywords
      results: docs
      body_helper: body_helper

  if !keyword
    callback(null, [])
  else
    c = seg.parse keyword
    keywords = c.keywords()
    query = PageContent.find {}
    query.where { words : { $all: keywords }}
    query.limit per_page
    query.skip page * per_page
    query.exec callback

app.listen 8000
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env
