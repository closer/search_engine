crawler = require('./crawler')

klasses = [
  crawler.Spider,
  crawler.HtmlParser,
  crawler.LinkTracker
]

instances = []

process.stdin.resume()

process.on 'SIGINT', ()->
  console.log "stop!!!"
  for instance in instances
    instance.stop()
  process.exit()

for klass in klasses
  instance = new klass
  instances.push instance
  instance.daemonize()

