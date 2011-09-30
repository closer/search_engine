model = require './model'

base_url = "http://shinronavi.com/"

Page = model.Page

init = ()->
  Page
    .create
      url:    base_url
      title:  ''
      body:   ''
      plain:  ''
      words:  []
      status: ''

      spider_queue: true
      html_parser_queue: false
      link_tracker_queue: false
      , ()->
        console.log arguments
        process.exit()


Page.findOne {url: base_url}, (e,d)->

  if d
    d.remove init
  else
    init()


