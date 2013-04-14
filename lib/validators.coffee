require 'sugar'

exports.notBlank = (value) ->
  not value?.isBlank()