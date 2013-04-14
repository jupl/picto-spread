restify = require 'restify'
config = require './config'

# Set up database
require './db'

# Set up server
module.exports = server = restify.createServer config.server
server.pre restify.pre.pause()
server.pre restify.pre.sanitizePath()
server.pre restify.pre.userAgentConnection()
server.use restify.requestLogger()
server.use restify.bodyParser()
server.use restify.queryParser()
server.use restify.jsonp()
server.use restify.throttle(config.throttle)

# Set up routes
require('./routes/photos')(server)

# Set up public static assets
server.get /^\/.*/, restify.serveStatic(config.static)

# Start server
server.listen config.port, ->
  console.log "#{server.name} (#{server.url})"