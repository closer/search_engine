_           = require('underscore')
http        = require("http")
URL         = require('url')
Iconv       = require("iconv-jp").Iconv
Buffer      = require('buffer').Buffer
Segmenter   = require('./segmenter').Segmenter
PageContent = require('./model').PageContent

seg = new Segmenter

class Crawler

  constructor: ()->
    @max_connection = 1
    @current_connections = []

  seed: (url)->
    PageContent.update { url: url }, { url: url }, { upsert: true }, (err, doc)->
      #console.log "seed #{url}"
    return

  crawl: ()->
    setTimeout ()=>
      if @max_connection > @current_connections.length
        this.crawl_start()
      this.crawl()
    , 100

  crawl_start: ()->
    query = PageContent.find { body: null, status: null }
    query.limit 1
    query.exec (err, docs)=>
      return if err
      docs.forEach (pc)=>
        url = pc.url
        unless err
          @current_connections.push url
          this.crawl_per_page url


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

        console.log response

        unless response.statusCode == 200
          this.crawl_complete(url, 'bad status', response, '')
          return

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
            when 'shift_jis'
              'shift-jis'
            else
              charset

        iconv = new Iconv(charset, 'utf-8//TRANSLIT//IGNORE')
        try
          outputBuffer = iconv.convert(concatBuffer)
          body = outputBuffer.toString('utf8')
          status = "success"
        catch e
          console.log 'convert failed'
          body = ""
          stauts = "failed"
        finally
          this.crawl_complete(url, status, response, body)

        return

    request.end()
    return

  crawl_complete:(url, status, res, html)->
    host = URL.parse(url).host
    parsed = html_parse(html)
    c = seg.parse parsed.plain
    keywords = c.keywords()
    links = link_parse html
    for link in links
      link = link.replace(/^\/(.*)/, ()-> "http://#{host}/#{RegExp.$1}")
      this.seed link if link.match(/^http/)
    pc =
      url:   url
      title: parsed.title
      body:  parsed.plain
      words: keywords
      status: status
    PageContent.update { url :url }, pc, { upsert: true }, ()=>
      console.log "crawl #{url} : COMPLETE #{status}"
      @current_connections = _(@current_connections).without(url)

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


module.exports.Crawler = Crawler

