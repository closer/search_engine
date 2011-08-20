http    = require("http")
url     = require('url')
#Apricot = require("apricot").Apricot
Iconv   = require("iconv-jp").Iconv
Buffer  = require('buffer').Buffer

class Crawler
  constructor: (URL)->
    @host = url.parse(URL).host
    console.log @host
    @connection = http.createClient 80, @host
    @url_pool = [URL]
    this

  crawl: (callback)->
    while @url_pool.length > 0
      console.log @url_pool
      this.crawl_per_page @url_pool.shift(), callback

  crawl_per_page: (url, callback) ->
    console.log "crawl #{url}"
    request = @connection.request 'GET', url, host: @host
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

        callback(url, response, body) if callback
        return

    request.end()
    return

exports.Crawler = Crawler
