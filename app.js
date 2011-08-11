(function() {
  var PageContent, PageContentSchema, Schema, app, express, mongoose;
  mongoose = require("mongoose");
  mongoose.connect('mongodb://localhost/spider');
  Schema = mongoose.Schema;
  PageContentSchema = new Schema({
    url: {
      type: String
    },
    title: {
      type: String
    },
    body: {
      type: String
    }
  });
  PageContent = mongoose.model('PageContent', PageContentSchema);
  express = require("express");
  app = module.exports = express.createServer();
  app.configure(function() {
    app.set("views", __dirname + "/views");
    app.set("view engine", "jade");
    app.use(express.bodyParser());
    app.use(express.methodOverride());
    app.use(require("stylus").middleware({
      src: __dirname + "/public"
    }));
    app.use(app.router);
    return app.use(express.static(__dirname + "/public"));
  });
  app.configure("development", function() {
    return app.use(express.errorHandler({
      dumpExceptions: true,
      showStack: true
    }));
  });
  app.configure("production", function() {
    return app.use(express.errorHandler());
  });
  app.get("/", function(req, res) {
    return res.render("index", {
      title: "Search Engine"
    });
  });
  app.get("/search", function(req, res) {
    var keyword;
    keyword = req.param('k');
    return PageContent.find({
      title: new RegExp(keyword)
    }, function(err, docs) {
      console.log(docs);
      return res.render('search', {
        title: "Search Results",
        keyword: keyword,
        results: docs
      });
    });
  });
  app.listen(8000);
  console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env);
}).call(this);
