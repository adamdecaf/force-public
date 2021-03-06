#
# Artwork page
#

express = require 'express'
routes = require './routes'

app = module.exports = express()
app.set 'views', __dirname + '/templates'
app.set 'view engine', 'jade'

app.get '/artwork/:id/save', routes.save
app.get '/artwork/:id', routes.index
app.get '/artwork/:id/:tab', routes.index
