{Schema} = mongoose = require 'mongoose'
{timestamp} = require 'mongoose-troop'
{notBlank} = require '../lib/validators'

schema = new Schema
  title:
    type: String
    required: yes
    unique: yes
  key:
    type: String
    required: yes
    unique: yes
  image:
    type: Buffer
    required: yes
  thumbnail:
    type: Buffer
    required: yes

schema.plugin(timestamp)
schema.path('title').validate(notBlank, 'Invalid title')
schema.method 'toClient', ({includeKey} = {}) ->
  json = @toObject(virtuals: yes)
  json.id = json._id
  delete json._id
  delete json.__v
  delete json.key unless includeKey
  json

module.exports = mongoose.model 'Photo', schema