http    = require("http")
url     = require('url')
Apricot = require("apricot").Apricot
Iconv   = require("iconv").Iconv
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
        charset =
          if contentType = response.headers['content-type']
            contentType.match(/charset=(.*)$/)[1]
          else
            'utf-8'
        totalLength = 0
        index = 0
        iconv = new Iconv(charset, 'utf-8//TRANSLIT//IGNORE')
        outputBuffer
        for currentBuffer in responseBuffers
          totalLength += currentBuffer.length
        concatBuffer = new Buffer(totalLength)
        while currentBuffer = responseBuffers.shift()
          currentBuffer.copy concatBuffer, index, 0
          index += currentBuffer.length
        try
          outputBuffer = iconv.convert(concatBuffer)
        catch e
          console.log e
        body = outputBuffer.toString('utf8')
        Apricot.parse body, (err, parsed)=>
          if err
            console.log err.message
          else
            parsed.find('a[href]').each (link)=>
              @url_pool.push link.href
            callback(response, body, parsed) if callback
          return
        return

    request.end()
    return

exports.Crawler = Crawler
