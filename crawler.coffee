_           = require 'underscore'
http        = require 'http'
URL         = require 'url'
{Iconv}     = require 'iconv-jp'
{Buffer}    = require 'buffer'
{Segmenter} = require './segmenter'

{Worker}    = require './worker'
{Page}      = require './model'

module.exports.Spider = class extends Worker
  queue: 'spider_queue'

  work: ()->
    @logger.add 'info', "Spider#work"
    page = @current_page
    url = page.url
    @logger.add 'info', url
    if url.match(/^https/)
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

        @logger.add 'debug', "1 #{charset}"
        charset =
          if contentType = response.headers['content-type']
            if match = contentType.match(/charset=(.*)$/)
              match[1]
            else
              if match = concatBuffer.toString().match(/charset="?([^"']*)["']/)
                match[1]
              else
                'utf-8'
          else
            'utf-8'
        @logger.add 'debug', "2 #{charset}"
        charset =
          switch charset
            when 'shift_jis'
              'shift-jis'
            else
              charset

        @logger.add 'debug', "3 #{charset}"

        iconv = new Iconv(charset, 'utf-8//TRANSLIT//IGNORE')
        try
          outputBuffer = iconv.convert(concatBuffer)
          body = outputBuffer.toString('utf8')
          status = "success"
        catch e
          body = ""
          stauts = "failed"
        finally
          @logger.add 'debug', body
          @crawl_complete(url, status, response, body)

        return

    request.on 'error', ()=>
      @finish()

    request.end()
    return

  crawl_complete: (url, status, response, body)->
    page = @current_page
    page.url = url
    page.status = status
    page.body = body
    page.spider_queue = false
    page.html_parser_queue = true
    page.save ()=>
      @logger.add 'info', "Spider#finish"
      @finish()


module.exports.HtmlParser = class extends Worker
  queue: 'html_parser_queue'
  segmenter: new Segmenter

  work: ()->
    @logger.add 'info', "HtmlParser#work"
    page = @current_page
    parsed = @html_parse(page.body)
    c = @segmenter.parse parsed.plain
    keywords = c.keywords()


    page.title = parsed.title
    page.plain =  parsed.plain
    page.words = keywords
    page.html_parser_queue = false
    page.link_tracker_queue = true

    page
      .save ()=>
        @logger.add 'info', "HtmlParser#finish"
        @finish()

  doctype_parse: (html)->
    if m = html.match(/<!doctype[^>]*>/i)
      m[0]
    else
      ""

  tag_reg: (tag="\\w+", opt="ims")->
    new RegExp("<(#{tag})[^>]*>((.|\\n|\\r)*)<\\/\\1>", opt)

  tag_parse: (plain, tag="\\w+", opt="ims")->
    if m = plain.replace(/[\r\n\s\t]+/, ' ').match(@tag_reg(tag, opt))
      m[2]
    else
      ""

  strip_tag: (html)->
    html = html.replace(/[\s\t\n\r]+/mg, ' ')
    html = html.replace(@tag_reg('script|style|textarea', 'img'), '')
    html = html.replace(/<img[^>]*alt="([^"]*)"[^>]*>/img, -> " #{RegExp.$1} " )
    html = html.replace(/<\/?\w*[^>]*>/img, '')
    html

  html_parse: (html)->
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
  queue: 'link_tracker_queue'
  work: ()->
    @logger.add 'info', "LinkTracker#work"
    page = @current_page
    url = page.url
    html = page.body
    @logger.add 'debug', html
    host = URL.parse(url).host
    links = @link_parse html
    for link in links
      link = link.replace(/^\/(.*)/, ()-> "http://#{host}/#{RegExp.$1}")
      if link.match(/^http:\/\//)
        Page
          .create
            url:    link
            title:  ''
            body:   ''
            plain:  ''
            words:  []
            status: ''

            spider_queue: true
            html_parser_queue: false
            link_tracker_queue: false
          , (e, d)=>

    page.link_tracker_queue = false
    page.save ()=>
      @logger.add 'info', "LinkTracker#finish"
      @finish()

  link_parse: (html)->
    links = []
    html.replace /<a[^>]*href="([^"]*)">/g, -> links.push RegExp.$1
    links

