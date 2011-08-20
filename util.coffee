_ = require 'underscore'

TinySegmenter = require('./tiny_segmenter').TinySegmenter
seg = new TinySegmenter

IGNORE_CHARCTORS = _.flatten [
  [' ', '　'],
  [ '。', '、', '・', '･'],
  [',', '.', '"', "'"],
  ['で', 'に', 'を', 'は', 'の', 'が']]

exports.segmenter = (keyword)->
  keywords = seg.segment keyword
  keywords = _(keywords).map (word)-> word.replace(/[\s]/g, '')
  keywords = _(keywords).sort()
  keywords = _(keywords).difference(IGNORE_CHARCTORS)
  keywords = _(keywords).uniq()
  keywords = _(keywords).compact()

  return keywords

