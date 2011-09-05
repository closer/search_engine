class Waiter
  constructor: (callback)->
    @callback = callback
    @keys = []
    @end_keys = []

  set:(key)->
    @keys.push key

  end:(key)->
    @end_keys.push key
    if @keys.sort().join('|') == @end_keys.sort().join('|')
      @__complete()

  __complete: ()->
    @callback()

module.exports.Waiter = Waiter
