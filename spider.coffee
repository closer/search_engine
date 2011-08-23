Crawler = require('./crawler').Crawler

crawler = new Crawler
crawler.seed 'http://shinronavi.com/'
crawler.crawl()
