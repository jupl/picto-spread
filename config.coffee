{env} = process

module.exports =
  db:
    uri: env.MONGOLAB_URI ? env.MONGOHQ_URL ? 'mongodb://localhost/picto-spread'

  port: env.PORT ? 8888

  static:
    default: 'api/index.html'
    directory: './public'

  throttle:
    burst: 10
    rate: 5
    ip: yes

  image:
    format: 'JPEG'
    thumbnail:
      size: 200