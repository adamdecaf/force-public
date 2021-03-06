_ = require 'underscore'
sd = require('sharify').data
Backbone = require 'backbone'
CurrentUser = require '../../../models/current_user.coffee'
Partner = require '../../../models/partner.coffee'
Artworks = require '../../../collections/artworks.coffee'
ArtworkColumnsView = require '../../../components/artwork_columns/view.coffee'

module.exports = class PartnerCollectionView extends Backbone.View

  defaults:
    pageSize: 16 # 4 by 4
    nextPage: 1
    isForSale: true

  initialize: (options={}) ->
    { @pageSize, @nextPage, @profile, @partner, @isForSale } = _.defaults options, @defaults

    @collection ?= new Artworks() # Maintain each page of artworks fetched
    @listenTo @collection, "request", @renderLoading
    @listenTo @collection, "sync", @hideLoading

    @setupCurrentUser()
    @initArtworkColumns()
    @loadNextPage()

  setupCurrentUser: ->
    @currentUser = CurrentUser.orNull()
    @currentUser?.initializeDefaultArtworkCollection()

  initArtworkColumns: ->
    @artworkColumnsView = new ArtworkColumnsView
      el: @$el
      collection: @collection
      numberOfColumns: 4
      gutterWidth: 40
      artworkSize: 'tall'
      allowDuplicates: true

  loadNextPage: =>
    @fetchNextPageArtworks
      success: (collection, response, options) =>
        @isFetching = false

        page = options?.data?.page or @nextPage # fetched page

        if page is 1
          $(window).on 'scroll.collection.partner', _.throttle(@infiniteScroll, 150)

        if collection.length < 1
          $(window).off('scroll.collection')

        else
          @artworkColumnsView.appendArtworks collection.models
          @nextPage = page + 1

  infiniteScroll: =>
    fold = $(window).height() + $(window).scrollTop()
    @loadNextPage() unless fold < @$el.offset()?.top + @$el.height()

  #
  # Fetch the next page of saved artworks and (blindly) append them
  # to @collection.
  fetchNextPageArtworks: (options) ->
    return if @isFetching
    @isFetching = true

    url = "#{@partner.url()}/artworks"
    data =
      page: @nextPage
      size: @pageSize
      published: true
      not_for_sale: true unless @isForSale
      for_sale: true if @isForSale
    @collection.fetch
      url: url
      data: data
      success: options?.success
      error: options?.error

  renderLoading: ->
    unless @$loadingSpinner?
      @$el.after( @$loadingSpinner = $('<div class="loading-spinner"></div>') )
    @$loadingSpinner.show()

  hideLoading: -> @$loadingSpinner.hide()
