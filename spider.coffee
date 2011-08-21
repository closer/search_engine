Segmenter = require('./mecab_test').Segmenter

PageContent = require('./model').PageContent

Crawler = require('./crawler').Crawler
crawler = new Crawler "http://shinronavi.com/school/4848/%E8%A1%8C%E5%B2%A1%E5%8C%BB%E5%AD%A6%E6%8A%80%E8%A1%93%E5%B0%82%E9%96%80%E5%AD%A6%E6%A0%A1/1484/event.php"
#crawler = new Crawler "http://shinronavi.com/"

seg = new Segmenter

html_parse = (html)->
  body =
  plain = body
    #.replace(/[\s\n]/g, '')
    .replace(/<("[^"]*"|'[^']*'|[^'">])*>/g, '')
    #.replace(/<[^\/][^>]*>([^<]*)<\/[^>]*>/g, -> RegExp.$1 )
    #.replace(/^[\t\s]*\n/g, ' ')
    .replace(/[\t\s]+/g, ' ')
  return {
    plain: plain
    body: body


crawler.crawl (url, res, body)->
  plain = html_parse body
  c = seg.parse plain
  keywords = c.keywords()
  pc =
    url:   url
    title: "test title2"
    body:  plain
    words: keywords
  PageContent.update { url :url }, pc, { upsert: true }, ()->
    console.log arguments
