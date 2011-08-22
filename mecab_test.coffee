_ = require 'underscore'
MeCab = require 'mecab-binding'

class KeywordCollection
  constructor:->
    @__keywords = []
    @__data = []

  add:(word='', data=[])->
    @__keywords.push word
    @__data.push data

  keywords:()->
    return @__keywords

class Segmenter
  constructor: ()->
    @m = new MeCab.Tagger ''

  parse: (text)->
    c = new KeywordCollection
    parsed = @m.parse text
    _(parsed.split(/\n/)).each (line)->
      return if line == 'EOS'
      r = line.split(/\t/)
      word = r.shift()
      data = if data = r.shift() then data.split(/,/) else []
      c.add word, data
      return
    return c

module.exports =
  KeywordCollection: KeywordCollection
  Segmenter: Segmenter
