{Schema} = mongoose = require 'mongoose'
timestamps = require 'mongoose-times'
{notBlank} = require '../lib/validators'

schema = new Schema
  key:
    type: String
    required: yes
  title:
    type: String
    required: yes
  description:
    type: String
    default: ''
  image:
    type: Buffer
    required: yes
  thumbnail:
    type: Buffer
    required: yes

schema.plugin(timestamps, lastUpdated: 'updated')
schema.path('title').validate(notBlank, 'Invalid title')
schema.method 'toClient', ({includeKey} = {}) ->
  json = @toObject(virtuals: yes)
  json.id = json._id
  delete json._id
  delete json.__v
  delete json.key unless includeKey
  json

module.exports = mongoose.model 'Photo', schema