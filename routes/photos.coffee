require 'sugar'
{NotAuthorizedError} = require 'restify'
uuid = require 'node-uuid'
gm = require 'gm'
Q = require 'q'

Photo = require '../models/photo'
config = require '../config'
root = '/photos'

module.exports = (server) ->

  # index
  server.get root, (req, res, next) ->
    Photo
    .find()
    .select(image: no)
    .exec (error, photos) ->
      unless error
        photos = photos.map((photo) -> photo.toClient())
        res.send(200, {photos})
      next error

  # create
  server.post root, (req, res, next) ->
    {params} = req
    photo = null
    image = new Buffer(params.image, 'base64')

    # Make sure image is a valid format
    createImage(image)

    # After validating image, generate thumbnail
    .then (buffer) ->
      params.image = buffer
      createImage(image, thumbnail: yes)

    # After thumbnail is generated, create photo
    .then (buffer) ->
      params.thumbnail = buffer
      params.key = uuid.v4()
      photo = new Photo(params)
      Q.ninvoke photo, 'save'

    # Once photo is saved, let user know
    .then ->
      photo = photo.toClient(includeKey: yes)
      res.send(201, {photo})
      next()

    # A problem occurred
    .fail(next)

  # show
  server.get "#{root}/:_id", (req, res, next) ->
    {_id} = req.params
    Photo.findById _id, (error, photo) ->
      photo = photo.toClient()
      res.send(200, {photo}) unless error
      next error

  # put
  server.put "#{root}/:_id", update(patch: no)

  # patch
  server.patch "#{root}/:_id", update(patch: yes)

  delete
  server.del "#{root}/:_id", (req, res, next) ->
    {_id, key} = req.params
    if key
      Photo.findOneAndRemove {_id, key}, (error) ->
        res.send 204 unless error
        next error
    else
      next(new NotAuthorizedError('Key is required to modify'))

# ----------------------------------------------------------------------------

createImage = (image, {thumbnail} = {}) ->
  buffers = []
  gmImage = gm image

  # Make sure to not reencode if a JPEG
  Q.ninvoke(gmImage, 'format').then (format) ->
    return image if format.any(config.image.format) and not thumbnail

    # Use GraphicsMagick to create thumbnail
    Q.fcall ->
      gmImage = gmImage.setFormat(config.image.format)
      if thumbnail
        gmImage = gmImage
        .resize(config.image.thumbnail.size, config.image.thumbnail.size, '^')
        .gravity('Center')
        .crop(config.image.thumbnail.size, config.image.thumbnail.size)
      Q.ninvoke gmImage, 'stream'

    # Concatenate all buffer output chunks
    .then ([stdout]) ->
      deferred = Q.defer()
      stdout.on 'data', (data) ->
        buffers.push data
      stdout.on 'close', ->
        deferred.resolve Buffer.concat(buffers)
      deferred.promise

# Update method used for both PUT and PATCH requests
update = ({patch} = {}) -> (req, res, next) ->
  {params} = req
  {_id, key} = params

  # Make sure a key is provided
  return next(new NotAuthorizedError('Key is required to modify')) unless key

  # Set up params and image buffer
  Photo.schema.eachPath((path) -> params[path] ?= null) unless patch
  delete params._id
  delete params.key
  delete params.thumbnail
  delete params.created
  delete params.modified
  image = new Buffer(params.image, 'base64') if params.image

  # If we are updating an image, then redo the image and thumbnail
  Q.fcall ->
    return unless image
    createImage(image)
    .then (buffer) ->
      params.image = buffer
      createImage(image, thumbnail: yes)
    .then (buffer) ->
      params.thumbnail = buffer

  # After any image work needed update model
  .then ->
    Q.ninvoke Photo, 'findOneAndUpdate', {_id, key}, params

  # Once photo is updated, let user know
  .then (photo) ->
    photo = photo.toClient()
    res.send 200, {photo}
    next()

  # A problem occurred
  .fail(next)