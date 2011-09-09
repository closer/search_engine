_ = require 'underscore'
crawler = require('./crawler')

klasses = [
  crawler.Spider,
  crawler.HtmlParser,
  crawler.LinkTracker
]

instances = []

process.stdin.resume()

process.on 'SIGINT', ()->
  for instance in instances
    instance.stop()
  process.exit()

for klass in klasses
  _.times 1, ()->
    instance = new klass
    instances.push instance
    instance.daemonize()

