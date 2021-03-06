fs = require 'fs'
jade = require 'jade'
{ fabricate } = require 'antigravity'

describe 'Meta tags', ->

  before ->
    @sd =
      ASSET_PATH: "http://localhost:5000"
      APP_URL: "http://localhost:5000"
    @file = "#{process.cwd()}/apps/shows/meta.jade"
    @html = jade.render fs.readFileSync(@file).toString(),
      sd: @sd

  it 'includes canonical url, twitter card, og tags, and title', ->
    @html.should.containEql "<meta property=\"twitter:card\" content=\"summary"
    @html.should.containEql "<link rel=\"canonical\" href=\"http://localhost:5000/shows"
    @html.should.containEql "<meta property=\"og:url\" content=\"http://localhost:5000/shows"
    @html.should.containEql "<meta property=\"og:title\" content=\"Shows | Artsy"
    @html.should.containEql "<meta property=\"og:description\" content=\"Explore all shows on Artsy"
