{Page} = require './model'


class Worker

  constructor: ()->
    console.log 'Initialized'
    @daemon = false
    @working = false
    @intavalId = null
    @current_page = null
    @logger = require('./logger').create 'test'
    return

  daemonize: ()->
    @daemon = true
    @intervalId = setInterval ()=>
      @run() if @daemon
    , 10
    return

  stop: ()->
    console.log "stop!!!"
    @daemon = false
    clearInterval @intervalId
    @intervalId = null
    return

  run: ()->
    unless @working
      @working = true
      @iteration()
    return

  iteration: ()->
    query = {}
    query[@queue] = true
    Page
      .findOne(query)
      .run (err, page)=>
        unless err
          if page
            @current_page = page
            @work()
          else
            @finish()
        else
          console.log err
          @finish()

  work:()-> # abstruct
    @finish()

  finish: ()->
    if @current_page
      @current_queue = null
    @working = false


Worker.run = ()->
  instance = new this()

  process.stdin.resume()

  process.on 'SIGINT', ()->
    instance.stop()
    process.exit()

  instance.daemonize()

  return instance

module.exports.Worker = Worker

