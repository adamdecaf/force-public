_                       = require 'underscore'
Backbone                = require 'backbone'
sd                      = require('sharify').data
ShareView               = require '../../share/view.coffee'
AcquireArtwork          = require('../../acquire/view.coffee').acquireArtwork
analytics               = require('../../../lib/analytics.coffee')
SaveControls            = require '../../artwork_item/views/save_controls.coffee'
ShowInquiryView         = require './show_inquiry_view.coffee'
artworkColumns          = -> require('../../artwork_columns/template.jade') arguments...

module.exports.FeedItemView = class FeedItemView extends Backbone.View

  artworksPage: 1

  artworksPageSize: 8

  initialize: (options) ->
    throw 'requires a model' unless @model
    throw 'requires an $el' unless @$el.length > 0
    @artworkCollection = options.artworkCollection
    _.defer =>
      @setupArtworkSaveControls()
      @setupShareButtons()

  moreArtworksClick: (event) =>
    analytics.track.click "Clicked show all artworks on feed item"
    @fetchMoreArtworks $(event.target)

  setupArtworkSaveControls: (artworks=@model.artworks().models)->
    listItems =
      for artwork in artworks
        overlay = @$(".artwork-item[data-artwork='#{artwork.get('id')}']").find('.overlay-container')
        if overlay.length
          new SaveControls
            el               : overlay
            model            : artwork
            artworkCollection: @artworkCollection

    if @artworkCollection
      @artworkCollection.addRepoArtworks @model.artworks()
      @artworkCollection.syncSavedArtworks()

  setupShareButtons: ->
    el = if @$('.feed-item-share-section').length > 0 then @$('.feed-item-share-section') else @$('.post-actions')
    new ShareView el: el

  events:
    "click .purchase": "purchase"
    'click .see-more': 'fetchMoreArtworks'
    'click .feed-item-contact-gallery': 'contactGallery'

  purchase: (event) =>
    $target = $(event.target)
    id = $target.attr('data-id')
    new Artwork(id: id).fetch
      success: (artwork) =>
        # redirect to artwork page if artwork has multiple editions
        if artwork.get('edition_sets_count') > 1
          return App.router.navigate "/artwork/#{artwork.get('id')}", trigger: true

        AcquireArtwork artwork, $target
    false


  fetchMoreArtworks: ->
    @$seeMore ?= @$('.see-more')
    @$seeMore.addClass 'is-loading'
    @model.toChildModel().fetchArtworks
      success: (artworks) =>
        @$seeMore.remove()
        @$('.feed-large-artworks-columns').html artworkColumns artworkColumns: artworks.groupByColumnsInOrder(4)
        @setupArtworkSaveControls artworks
    false

  contactGallery: (e) ->
    new ShowInquiryView show: @model