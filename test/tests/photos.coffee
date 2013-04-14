require 'sugar'
uuid = require 'node-uuid'
restify = require 'restify'

{url} = require '../../server'
Photo = require '../../models/photo'
should = require '../should'
root = '/photos'

describe 'Photos', ->

  before ->
    @client = restify.createJsonClient({url})
    @params =
      title: uuid.v4()
      image: require '../image'

  after (done) ->
    if @id
      Photo.findByIdAndRemove @id, done
    else
      done()

  describe root, ->

    it 'GET', (done) ->
      @client.get root, (error, req, res, {photos}) ->
        should.not.exist error?.message
        Photo.count (error, count) ->
          should.not.exist error
          photos.length.should.equal count
          done()

    it 'POST', (done) ->
      @client.post root, @params, (error, req, res, {photo}) =>
        should.not.exist error?.message
        @id = photo.id
        @key = photo.key
        photo.should.include.keys [
          'id'
          'key'
          'title'
          'image'
          'thumbnail'
          'created'
          'updated'
        ]
        @params.title.should.equal photo.title
        done()

  describe "#{root}/:id", ->

    it 'GET', (done) ->
      should.exist @id
      @client.get "#{root}/#{@id}", (error, req, res, {photo}) ->
        should.not.exist error?.message
        should.not.exist photo.key
        done()

    it 'PUT', (done) ->
      should.exist @id
      should.exist @key
      @client.get "#{root}/#{@id}", (error, req, res, data) =>
        should.not.exist error?.message
        data.photo.title = uuid.v4()
        photo = Object.clone(data.photo)
        photo.key = @key
        @client.put "#{root}/#{@id}", photo, (error, req, res, {photo}) ->
          should.not.exist error?.message
          data.photo.updated.should.not.equal photo.updated
          delete data.photo.updated
          delete photo.updated
          data.photo.should.deep.equal photo
          done()

    it 'PATCH', (done) ->
      should.exist @id
      should.exist @key
      @client.get "#{root}/#{@id}", (error, req, res, data) =>
        should.not.exist error?.message
        data.photo.title = title = uuid.v4()
        @client.patch "#{root}/#{@id}", {title, @key}, (error, req, res, {photo}) ->
          should.not.exist error
          data.photo.updated.should.not.equal photo.updated
          delete data.photo.updated
          delete photo.updated
          data.photo.should.deep.equal photo
          done()

    it 'DELETE', (done) ->
      should.exist @id
      should.exist @key
      @client.del "#{root}/#{@id}?key=#{@key}", (error, req, res) ->
        should.not.exist error?.message
        delete @id
        delete @key
        done()