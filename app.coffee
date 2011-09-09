Segmenter = require('./segmenter').Segmenter

Page = require('./model').Page

Waiter = require('./callback_waiter').Waiter

seg = new Segmenter

per_page = 50

body_helper = (body, keywords)->
  return unless body
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

  count = 0
  docs = []

  callback = ()->
    res.render 'index'
      layout: !ajax
      page: page
      keyword: keyword
      keywords: keywords
      count: count
      results: docs
      body_helper: body_helper

  if !keyword
    callback()
  else

    waiter = new Waiter ()-> callback(); return

    waiter.set 'count'
    waiter.set 'doc'

    c = seg.parse keyword
    keywords = c.keywords()

    Page
      .where('words').all(keywords)
      .$where('status == "success"')
      .count (err, c)->
        count = c
        waiter.end 'count'
        return

    Page
      .where('words').all(keywords)
      .$where('status = "success"')
      .limit(per_page)
      .skip(page * per_page)
      .run (err, d)->
        console.log arguments
        docs = d
        waiter.end 'doc'
        return
  return

app.listen 8000
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env
