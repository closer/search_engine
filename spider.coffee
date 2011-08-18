Crawler = require('./crawler').Crawler
crawler = new Crawler 'http://www.iana.org/domains/example/'

crawler.crawl (res, body, doc)->
  doc.find('body').each (body)->
    body.innerHTML
