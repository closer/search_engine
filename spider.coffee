Crawler = require('./crawler').Crawler
crawler = new Crawler 'http://nabeshima.2012_shinronavi.nasubi.license/index.php'

crawler.crawl (res, body, doc)->
  console.log body
