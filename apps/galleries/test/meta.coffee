fs = require 'fs'
jade = require 'jade'

describe 'Meta tags', ->

  describe 'featured gallery partners meta tags', ->

    before ->
      @file = "#{process.cwd()}/apps/galleries/meta.jade"
      @sd =
        APP_URL: 'http://localhost:5000'
        ASSET_PATH: 'http://localhost:5000'
      @html = jade.render fs.readFileSync(@file).toString(),
        sd: @sd

    it 'includes canonical url, twitter card, og tags, and title', ->
      @html.should.containEql "<meta property=\"twitter:card\" content=\"summary"
      @html.should.containEql "<link rel=\"canonical\" href=\"http://localhost:5000/galleries"
      @html.should.containEql "<meta property=\"og:url\" content=\"http://localhost:5000/galleries"
      @html.should.containEql "<meta property=\"og:title\" content=\"Galleries | Artsy"
