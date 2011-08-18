
segmenter = new require("./tiny_segmenter").TinySegmenter

Crawler = require('crawler').Crawler

crawler = new Crawler
  maxConnections: 10
  callback: (err, results, $) ->
    if err
      console.log err.message
    else
      console.log resutls
      $('a').each (a) ->
        crawler.queue a.href

crawler.queue ['http://example.com/']
