class Worker

  constructor: ()->
    @daemon = false
    @working = false
    @intavalId = null
    return

  daemonize: ()->
    @daemon = true
    @intervalId = setInterval ()=>
      @run() if @daemon
    , 10
    return

  stop: ()->
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
    @queue
      .findOne({})
      .populate('page')
      .run (err, queue)=>
        unless err
          if queue
            @work queue, finish
          else
            @finish()
        else
          console.log err
          @finish()

  work:(queue, finish)-> # abstruct
    @finish()

  finish: ()->
    @working = false

module.exports.Worker = Worker


