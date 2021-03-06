_ = require 'underscore'
benv = require 'benv'
sinon = require 'sinon'
Backbone = require 'backbone'
{ fabricate } = require 'antigravity'
{ resolve } = require 'path'
Artist = require '../../../models/artist'

describe 'ArtworkFilterView', ->
  before (done) ->
    benv.setup =>
      benv.expose $: benv.require 'jquery'
      Backbone.$ = $
      @ArtworkFilterView = benv.requireWithJadeify resolve(__dirname, '../view'), ['template', 'filterTemplate', 'headerTemplate']
      @ArtworkFilterView.__set__ 'ArtworkColumnsView', sinon.stub().returns { length: -> 999 }
      done()

  after ->
    benv.teardown()

  beforeEach ->
    sinon.stub Backbone, 'sync'
    @model = new Artist fabricate 'artist', id: 'foo-bar'
    @view = new @ArtworkFilterView model: @model

  afterEach ->
    Backbone.sync.restore()

  describe '#initialize', ->
    describe '#render', ->
      it 'renders the container template', ->
        @view.$el.html().should.containEql 'artwork-filter'
        @view.$el.html().should.containEql 'artwork-columns'

    it 'fetches the filter', ->
      Backbone.sync.args[0][1].url().should.containEql '/api/v1/search/filtered/artist/foo-bar/suggest'

    it 'fetches the artworks', ->
      Backbone.sync.args[1][1].url().should.containEql '/api/v1/search/filtered/artist/foo-bar'

  describe '#renderFilter', ->
    beforeEach ->
      Backbone.sync.args[0][2].success fabricate 'artist_filtered_search_suggest'

    it 'renders the filter template', ->
      @view.$filter.html().should.containEql '<h2>Works</h2>'

  describe '#handleState', ->
    describe '#handleFilterState', ->
      it 'sets the state for the filter container depending on the request event', ->
        # _.isUndefined(@view.$filter.attr 'data-state').should.be.true
        @view.filter.trigger 'request'
        @view.$filter.attr('data-state').should.equal 'loading'
        @view.filter.trigger 'sync'
        @view.$filter.attr('data-state').should.equal 'loaded'
        @view.filter.trigger 'request'
        @view.$filter.attr('data-state').should.equal 'loading'
        @view.filter.trigger 'error'
        @view.$filter.attr('data-state').should.equal 'loaded'

    describe '#handleArtworksState', ->
      it 'sets the state for the artworks container + button depending on the request event', ->
        _.isUndefined(@view.$columns.attr 'data-state').should.be.true
        @view.artworks.trigger 'request'
        @view.$columns.attr('data-state').should.equal 'loading'
        @view.$button.attr('data-state').should.equal 'loading'
        @view.artworks.trigger 'sync'
        @view.$columns.attr('data-state').should.equal 'loaded'
        @view.$button.attr('data-state').should.equal 'loaded'
        @view.artworks.trigger 'request'
        @view.$columns.attr('data-state').should.equal 'loading'
        @view.$button.attr('data-state').should.equal 'loading'
        @view.artworks.trigger 'error'
        @view.$columns.attr('data-state').should.equal 'loaded'
        @view.$button.attr('data-state').should.equal 'loaded'

  describe '#loadNextPage', ->
    it 'loads the next page when the button is clicked', ->
      Backbone.sync.callCount.should.equal 2
      @view.artworks.params.get('page').should.equal 1
      @view.$('#artwork-see-more').click()
      @view.artworks.params.get('page').should.equal 2
      Backbone.sync.callCount.should.equal 3
      _.last(Backbone.sync.args)[2].data.should.eql size: 9, page: 2
      @view.$('#artwork-see-more').click()
      @view.artworks.params.get('page').should.equal 3
      Backbone.sync.callCount.should.equal 4
      _.last(Backbone.sync.args)[2].data.should.eql size: 9, page: 3

    describe 'error', ->
      it 'reverts the params', ->
        @view.artworks.params.attributes.should.eql size: 9, page: 1
        @view.$('#artwork-see-more').click()
        _.last(Backbone.sync.args)[2].data.should.eql size: 9, page: 2
        Backbone.sync.restore()
        sinon.stub(Backbone, 'sync').yieldsTo 'error'
        # Tries to get next page but errors
        @view.$('#artwork-see-more').click()
        _.last(Backbone.sync.args)[2].data.should.eql size: 9, page: 3
        # Next try should have the same params
        @view.$('#artwork-see-more').click()
        _.last(Backbone.sync.args)[2].data.should.eql size: 9, page: 3

  describe '#selectCriteria', ->
    beforeEach ->
      Backbone.sync.args[0][2].success fabricate 'artist_filtered_search_suggest'

    it 'pulls the filter criteria out of the link and selects it', ->
      @view.$('.artwork-filter-select').first().click()
      @view.filter.selected.attributes.should.eql medium: 'work-on-paper'
      @view.$('.artwork-filter-select').last().click()
      @view.filter.selected.attributes.should.eql period: 2010

  describe '#fetchArtworks', ->
    beforeEach ->
      Backbone.sync.args[0][2].success fabricate 'artist_filtered_search_suggest'

    it 'fetches the artworks, passing in the selected filters + view params', ->
      @view.$('.artwork-filter-select:eq(0)').click()
      _.last(Backbone.sync.args)[2].data.should.eql medium: 'work-on-paper'
      @view.$('.artwork-filter-select:eq(1)').click()
      _.last(Backbone.sync.args)[2].data.should.eql medium: 'sculpture'
      @view.$('.artwork-filter-select').last().click()
      _.last(Backbone.sync.args)[2].data.should.eql period: 2010
      @view.$('#artwork-see-more').click()
      _.last(Backbone.sync.args)[2].data.should.eql period: 2010, size: 9, page: 2

  describe '#fetchArtworksFromBeginning', ->
    beforeEach ->
      Backbone.sync.args[0][2].success fabricate 'artist_filtered_search_suggest'

    it 'fetches resets the params before fetching artworks when a filter is clicked', ->
      @view.$('.artwork-filter-select:eq(0)').click()
      @view.$('#artwork-see-more').click()
      _.last(Backbone.sync.args)[2].data.should.eql medium: 'work-on-paper', size: 9, page: 2
      @view.$('#artwork-see-more').click()
      _.last(Backbone.sync.args)[2].data.should.eql medium: 'work-on-paper', size: 9, page: 3
      @view.$('.artwork-filter-select:eq(1)').click()
      _.last(Backbone.sync.args)[2].data.should.eql medium: 'sculpture'

  describe '#toggleBoolean', ->
    beforeEach ->
      Backbone.sync.args[0][2].success fabricate 'artist_filtered_search_suggest'

    it 'fetches the artworks, toggling the boolean filter criteria', ->
      @view.$('input[type="checkbox"]').first().click()
      @view.filter.selected.attributes.should.eql price_range: '-1:1000000000000'
      _.last(Backbone.sync.args)[2].data.should.eql price_range: '-1:1000000000000'
      @view.$('input[type="checkbox"]').first().click()
      @view.filter.selected.attributes.should.eql {}
      _.last(Backbone.sync.args)[2].data.should.not.containEql price_range: '-1:1000000000000'

  describe '#setButtonState', ->
    beforeEach ->
      @columnLength = 0
      @view.columns = length: => @columnLength

    it 'sets the correct button state when there is 1 remaining artwork', ->
      @view.filter.active.set 'total', 10
      @columnLength = 9
      @view.setButtonState()
      @view.$button.is(':visible').should.be.true
      @view.$button.text().should.equal 'See More (1)'

    it 'sets the correct button state when there are no remaining artworks', ->
      @view.filter.active.set 'total', 10
      @columnLength = 10
      @view.setButtonState()
      @view.$button.attr('style').should.equal 'display: none;'
      @view.$button.text().should.equal 'See More (0)'

    it 'sets the correct state when toggled', ->
      @view.filter.active.set 'total', 10
      @columnLength = 10
      @view.setButtonState()
      # Is hidden
      @view.$button.attr('style').should.equal 'display: none;'
      @columnLength = 4
      @view.setButtonState()
      # Is now visible again
      _.isEmpty(@view.$button.attr('style')).should.be.true
      @view.$button.text().should.equal 'See More (6)'
