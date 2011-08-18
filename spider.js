(function() {
  var Crawler, crawler, segmenter;
  segmenter = new require("./tiny_segmenter").TinySegmenter;
  Crawler = require('crawler').Crawler;
  crawler = new Crawler({
    maxConnections: 10,
    callback: function(err, results, $) {
      console.log(results);
      return $('a').each(function(a) {
        return crawler.queue(a.href);
      });
    }
  });
  crawler.queue('http://example.com/');
}).call(this);
