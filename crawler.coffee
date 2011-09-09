_           = require('underscore')
http        = require("http")
URL         = require('url')
Iconv       = require("iconv-jp").Iconv
Buffer      = require('buffer').Buffer
Segmenter   = require('./segmenter').Segmenter
model       = require('./model')

Worker = require('./worker').Worker

SpiderQueue      = model.SpiderQueue
HtmlParserQueue  = model.HtmlParserQueue
LinkTrackerQueue = model.LinkTrackerQueue

Page  = model.Page

module.exports.Spider = class extends Worker
  queue: SpiderQueue

  work: (queue)->
    url = queue.page.url
    console.log "crawl #{url}"
    if url.match(/^https/)
      console.log ('close')
      return
    host = URL.parse(url).host
    connection = http.createClient 80, host

    request = connection.request 'GET', url, host: host
    request.on 'response', (response)=>
      responseBuffers = []
      responseLength = 0

      response.on 'data', (chunk)=>
        responseBuffers.push chunk

      response.on 'end', =>

        unless response.statusCode == 200
          @crawl_complete(url, 'bad status', response, '')
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
          @crawl_complete(url, status, response, body)

        return

    request.end()
    return

  crawl_complete: (url, status, response, body)->
    page = new Page
    page.url = url
    page.status = status
    page.body = body
    page.save ()=>
      hp = new HtmlParserQueue
      hp.page = page.id
      hp.save ()=>
        @finish()


module.exports.HtmlParser = class extends Worker
  queue: HtmlParserQueue
  segmenter: new Segmenter

  work: (queue)->
    page = queue.page
    parsed = @html_parse(page.body)
    c = @segmenter.parse parsed.plain
    keywords = c.keywords()
    pc =
      url:   url
      title: parsed.title
      body:  parsed.plain
      words: keywords
      status: status
    page.update { url :url }, pc, { upsert: true }, ()=>
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
    doctype = @doctype_parse(html)
    title   = @tag_parse(html, 'title')
    body    = @tag_parse(html, 'body')
    plain   = @strip_tag(body)
    return {
      doctype: doctype
      title: title
      plain: plain
    }


module.exports.LinkTracker = class extends Worker
  queue: LinkTrackerQueue

  work: (queue)->
    url = queue.page.url
    html = queue.page.body
    host = URL.parse(url).host
    links = @link_parse html
    for link in links
      link = link.replace(/^\/(.*)/, ()-> "http://#{host}/#{RegExp.$1}")
      if link.match(/^http/)
        page = new Page
        page.url = link
        page.save ()->
          new_queue = new SpiderQueue
          new_queue.page = page.id
          new_queue.save ()->


