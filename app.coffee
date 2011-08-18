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
  if !keyword
    res.render 'index'
      keyword: ''
      results: []
  else
    PageContent.find { words : [keyword] }, (err, docs) ->
      console.log docs
      res.render 'index'
        keyword: keyword
        results: docs

app.listen 8000
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env
