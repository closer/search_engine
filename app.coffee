mongoose = require "mongoose"

mongoose.connect 'mongodb://localhost/spider'

Schema = mongoose.Schema

PageContentSchema = new Schema
  url   : { type: String }
  title : { type: String }
  body  : { type: String }

PageContent = mongoose.model('PageContent', PageContentSchema)

express = require("express")
app = module.exports = express.createServer()
app.configure ->
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use require("stylus").middleware(src: __dirname + "/public")
  app.use app.router
  app.use express.static(__dirname + "/public")

app.configure "development", ->
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true
  )

app.configure "production", ->
  app.use express.errorHandler()

app.get "/", (req, res) ->
  res.render "index", title: "Search Engine"

app.get "/search", (req, res) ->
  keyword = req.param('k')
  PageContent.find { title : new RegExp(keyword) }, (err, docs) ->
    console.log docs
    res.render 'search'
      title: "Search Results"
      keyword: keyword
      results: docs

app.listen 8000
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env
