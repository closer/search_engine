Apricot = require('apricot').Apricot

Apricot.open 'http://nabeshima.2012_shinronavi.nasubi.license/index.php', (err, doc)->
  if err
    console.log err
  else
    console.log doc
