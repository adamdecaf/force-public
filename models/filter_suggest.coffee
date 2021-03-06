_ = require 'underscore'
_.mixin require 'underscore.string'
Backbone = require 'backbone'
{ API_URL } = require('sharify').data

module.exports = class FilterSuggest extends Backbone.Model

  url: -> "#{API_URL}/api/v1/search/filtered/#{@get 'id'}/suggest"

  mediumsHash: (options) ->
    mediums = {}
    for label, count of @get('medium')
      mediums[_.titleize _.humanize label] = label
    mediums
