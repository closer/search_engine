model = require './model'

Page = model.Page
SpiderQueue = model.SpiderQueue

Page
  .find()
  .run (e, d)->
    sq = new SpiderQueue
      page: d[0]
    sq.save ()->
