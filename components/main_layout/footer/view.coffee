_ = require 'underscore'
Backbone = require 'backbone'
FeedbackView = require '../../contact/feedback.coffee'
mediator = require '../../../lib/mediator.coffee'

module.exports = class FooterView extends Backbone.View
  events:
    'click .mlf-feedback': 'feedback'

  initialize: (options) ->
    mediator.on 'open:feedback', @openFeedback, this

  feedback: (e) ->
    e.preventDefault()
    mediator.trigger 'open:feedback'

  openFeedback: ->
    new FeedbackView
