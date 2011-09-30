m = require "./model"

for model in ["Spider", "HtmlParser", "LinkTracker"]
  ((model)->
    queue = "#{model}Queue"
    m[queue]
      .find()
      .count (e, d)->
        console.log "#{queue}:#{d}"
  )(model)
