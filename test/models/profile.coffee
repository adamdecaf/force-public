_ = require 'underscore'
{ fabricate } = require 'antigravity'
sd = require('sharify').data
should = require 'should'
Backbone = require 'backbone'
Partner = require '../../models/partner'
Profile = require '../../models/profile'
sinon = require 'sinon'

describe 'Profile', ->

  beforeEach ->
    sinon.stub Backbone, 'sync'
    @profile = new Profile(fabricate('partner_profile',
      owner:
        type: "Museum"
        sortable_id: "getty-museum"
        name: "J. Paul Getty Museum"
        default_profile_id: "getty"
      icon:
        id: "51eefb79275b2420810001fe",
        image_filename: "GGLogo1.jpg",
        image_url: "http://static2.artsy.net/profile_icons/51eefb79275b2420810001fe/:version.jpg",
        image_versions: [ "square140" ]
        x: 0
        y: 0
        width: 140
    ))

  afterEach ->
    Backbone.sync.restore()

  describe '#isUserClass', ->

    it 'returns is-user if the profile is a user and is set to use a circular default icon', ->
      @profile.isUserClass().should.equal 'is-partner'
      @profile.set owner_type: 'User'
      @profile.set default_icon_version: 'circle'
      @profile.isUserClass().should.equal 'is-user'

  describe '#iconImageUrl', ->

    it "returns the icon url for the model's default icon version", ->
      @profile.iconImageUrl().should.containEql "square"

  describe '#alphaSortKey', ->

    it "returns the profile owner's display name", ->
      @profile.alphaSortKey().should.equal @profile.displayName()

  describe '#href', ->

    it "returns the client link to this profile", ->
      @profile.href().should.containEql "/#{@profile.get('id')}"

  describe '#displayName', ->

    it "returns the profile owner's display name", ->
      @profile.displayName().should.equal @profile.get('owner').name

  describe '#isPartner', ->

    it "returns true if the profile does not belong to a User or Admin", ->
      @profile.set 'owner_type', 'PartnerGallery'
      @profile.isPartner().should.be.true
      @profile.set 'owner_type', 'Admin'
      @profile.isPartner().should.be.false
      @profile.set 'owner_type', 'User'
      @profile.isPartner().should.be.false

  describe '#defaultIconInitials', ->

    it "returns up to two initials for a partner name", ->
      @profile.defaultIconInitials().should.equal "JP"

      @profile.get('owner').name = "Whitney"
      @profile.defaultIconInitials().should.equal "W"

      @profile.get('owner').name = "John Jacob Jingle Heimer Schmidt"
      @profile.defaultIconInitials().should.equal "JJ"

    it "does not include non-word characters", ->
      @profile.get('owner').name = "Chime & Read"
      @profile.defaultIconInitials().should.equal "CR"

      @profile.get('owner').name = "2 % Johan _ Gregor 37"
      @profile.defaultIconInitials().should.equal "2J"

  describe '#formatFollowText', ->

    it 'returns formatted follows text', ->
      @profile.set follows_count: 1234567
      @profile.formatFollowText().should.equal '1,234,567 Followers'

  describe '#getFormattedWebsite', ->

    it 'formats website', ->
      @profile.set website: 'https://artsy.net'
      @profile.getFormattedWebsite().should.equal 'artsy.net'

  describe '#metaTitle', ->

    it 'correctly formats title for users', ->
      @profile.set owner_type: 'User'
      @profile.metaTitle().should.equal 'J. Paul Getty Museum | Artsy'

    it 'correctly formats title for galleries', ->
      @profile.set owner_type: 'PartnerGallery'
      @profile.metaTitle().should.equal 'J. Paul Getty Museum | Artists, Art for Sale, and Contact Info | Artsy'

    it 'correctly formats title for non-gallery partners', ->
      @profile.set owner_type: 'PartnerMuseum'
      @profile.metaTitle().should.equal 'J. Paul Getty Museum | Artists, Artworks, and Contact Info | Artsy'

    it 'correctly formats title for fairs', ->
      @profile.set owner_type: 'FairOrganizer'
      @profile.metaTitle().should.equal 'J. Paul Getty Museum | Fair Info, Artists, and Art for Sale | Artsy'
      @profile.metaTitle('info').should.equal 'J. Paul Getty Museum | Visitor Information | Artsy'
      @profile.metaTitle('posts').should.equal 'J. Paul Getty Museum | Read Highlights from the Fair | Artsy'
      @profile.metaTitle('forYou').should.equal 'J. Paul Getty Museum | Your Personal Fair Guide | Artsy'

  describe '#metaDescription', ->

    it 'correctly formats description', ->
      @profile.set('bio', 'bio')
      @profile.metaDescription().should.equal 'bio'

      @profile.set('bio', undefined)
      @profile.metaDescription().should.equal 'J. Paul Getty Museum on Artsy'

  describe '#fetchFavorites', ->

    it 'fetches the saved-artwork collection based on the owner', ->
      @profile.get('owner').id = 'foobar'
      @profile.fetchFavorites({})
      Backbone.sync.args[0][1].url.should.containEql 'saved-artwork/artworks'

    it 'returns feed items with a set url', (done) ->
      @profile.get('owner').id = 'foobar'
      @profile.fetchFavorites success: (items) ->
        items.url.should.containEql 'saved-artwork/artworks'
        done()
      Backbone.sync.args[0][2].success [{ id: 'bar' }]

  describe '#fetchPosts', ->

    it 'fetches posts', ->
      @profile.set id: 'moobar'
      @profile.fetchPosts({})
      Backbone.sync.args[0][2].url.should.containEql 'profile/moobar/posts'
