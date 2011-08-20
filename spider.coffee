util = require './util'

PageContent = require('./model').PageContent

Crawler = require('./crawler').Crawler
crawler = new Crawler "http://shinronavi.com/school/4848/%E8%A1%8C%E5%B2%A1%E5%8C%BB%E5%AD%A6%E6%8A%80%E8%A1%93%E5%B0%82%E9%96%80%E5%AD%A6%E6%A0%A1/1484/event.php"

crawler.crawl (url, res, body)->
  plain = body
    #.replace(/[\s\n]/g, '')
    .replace(/<("[^"]*"|'[^']*'|[^'">])*>/g, '')
    #.replace(/<[^\/][^>]*>([^<]*)<\/[^>]*>/g, -> RegExp.$1 )
    #.replace(/^[\t\s]*\n/g, ' ')
    .replace(/[\t\s]+/g, ' ')
  keywords = util.segmenter plain
  console.log keywords
  pc =
    _id:   url
    url:   url
    title: "test title"
    body:  plain
    words: keywords
  new PageContent(pc).save()
