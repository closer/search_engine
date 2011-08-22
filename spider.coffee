http    = require("http")
URL     = require('url')
Iconv   = require("iconv-jp").Iconv
Buffer  = require('buffer').Buffer
Segmenter = require('./mecab_test').Segmenter
PageContent = require('./model').PageContent

class Crawler

  crawl: (url)->
    query = PageContent.find {}
    query.where { body: '' }
    query.limit 1
    query.exec (err, doc)=>
      console.log doc
      this.crawl_per_page doc unless err

  crawl_per_page: (url) ->
    host = URL.parse(url).host
    connection = http.createClient 80, host

    console.log "crawl #{url}"
    request = connection.request 'GET', url, host: host
    request.on 'response', (response)=>
      responseBuffers = []
      responseLength = 0

      response.on 'data', (chunk)=>
        responseBuffers.push chunk

      response.on 'end', =>
        totalLength = 0
        index = 0
        outputBuffer

        for currentBuffer in responseBuffers
          totalLength += currentBuffer.length

        concatBuffer = new Buffer(totalLength)

        while currentBuffer = responseBuffers.shift()
          currentBuffer.copy concatBuffer, index, 0
          index += currentBuffer.length

        charset =
          if contentType = response.headers['content-type']
            if match = contentType.match(/charset=(.*)$/)
              match[1]
            else
              if match = concatBuffer.toString().match(/charset=([^"']*)["']/)
                match[1]
              else
                'utf-8'
          else
            'utf-8'
        charset =
          switch charset
            when 'shift_jis' then 'shift-jis'
            else
              charset

        iconv = new Iconv(charset, 'utf-8//TRANSLIT//IGNORE')
        try
          outputBuffer = iconv.convert(concatBuffer)
        catch e
          console.log 'convert failed'
        body = outputBuffer.toString('utf8')

        this.crawl_complete(url, response, body)
        return

    request.end()
    return

  crawl_complete:(url, res, html)->
    parsed = html_parse(html)
    c = seg.parse parsed.plain
    keywords = c.keywords()
    links = link_parse html
    for link in links
      PageContent.update { url: link }, { url: link }, { upsert: true }
    pc =
      url:   url
      title: parsed.title
      body:  parsed.plain
      words: keywords
    PageContent.update { url :url }, pc, { upsert: true }, ()->

doctype_parse = (html)->
  if m = html.match(/<!doctype[^>]*>/i)
    m[0]
  else
    ""

tag_reg = (tag="\\w+", opt="ims")->
  new RegExp("<(#{tag})[^>]*>((.|\\n|\\r)*)<\\/\\1>", opt)

tag_parse = (plain, tag="\\w+", opt="ims")->
  if m = plain.replace(/[\r\n\s\t]+/, ' ').match(tag_reg(tag, opt))
    m[2]
  else
    ""

strip_tag = (html)->
  html = html.replace(/[\s\t\n\r]+/mg, ' ')
  html = html.replace(tag_reg('script|style|textarea', 'img'), '')
  html = html.replace(/<img[^>]*alt="([^"]*)"[^>]*>/img, -> " #{RegExp.$1} " )
  html = html.replace(/<\/?\w*[^>]*>/img, '')
  html

link_parse = (html)->
  links = []
  html.replace /<a[^>]*href="([^"]*)">/g, -> links.push RegExp.$1
  links

html_parse = (html)->
  doctype = doctype_parse(html)
  title   = tag_parse(html, 'title')
  body    = tag_parse(html, 'body')
  plain   = strip_tag(body)
  return {
    doctype: doctype
    title: title
    plain: plain
  }

crawler = new Crawler
seg = new Segmenter
crawler.crawl('http://shinronavi.com/')

