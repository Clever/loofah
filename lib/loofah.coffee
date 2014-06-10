_ = require 'underscore'
_.mixin require 'underscore.deep' # the version that works is not on npm

module.exports =

  default: ->
    _.compose(plain_text(), url_encode(), bad_keys())

  bad_keys: bad_keys = (b_keys = ['password', 'user', 'email', 'api', 'secret']) ->
    return (object) ->
      return object if not _.isObject object
      return obj = _.deepMapValues object, (val, key) ->
        _.each b_keys, (b_key) ->
          b_key = new RegExp "(\\.|^)#{b_key}(\\.|$)", 'i' if not _.isRegExp b_key
          val = if (b_key.test key) then '[REDACTED]' else val
        val

  bad_vals: bad_vals = (substrings) ->
    return (object) ->
      return _bad_vals object, substrings if not _.isObject object
      return obj = _.deepMapValues object, (val) ->
        _bad_vals val, substrings

  _bad_vals: _bad_vals = (string, substrings) ->
    return string if not _.isString string
    _.each substrings, (substring) ->
      substring = new RegExp substring, 'g' if not _.isRegExp substring
      string = string.replace substring, '[REDACTED]'
    string

  url_encode: url_encode = (query_params = ['client_id', 'client_secret', 'refresh_token']) ->
    return (object) ->
      return _url_encode object, query_params if not _.isObject object
      return obj = _.deepMapValues object, (val) ->
        _url_encode val, query_params

  _url_encode: _url_encode = (string, query_params) ->
    return string if not _.isString string
    val = _splitter string, [/[=.&?]/, /[^=.&?]/]
    _.each query_params, (qparam) ->
      qparam = new RegExp "(^|[=.&?])#{qparam}", 'i' if not _.isRegExp qparam
      _.each val, (v, i) ->
        val[i + 2] = "[REDACTED]" if val[i + 2]? and val[i + 1] is '=' and qparam.test v
    val.join('')

  plain_text: plain_text = (keywords = ['user', 'username', 'password', 'email']) ->
    return (object) ->
      return _plain_text object, keywords if not _.isObject object
      return obj = _.deepMapValues object, (val) ->
        _plain_text val, keywords

  _plain_text: _plain_text = (string, keywords) ->
    return string if not _.isString string
    val = _splitter string , [/[^=:\s]/, /[\s=:]/]
    _.each keywords, (keyword) ->
      keyword = new RegExp "^#{keyword}$", 'i' if not _.isRegExp keyword
      _.each val, (v, i) ->
        val[i + 2] = '[REDACTED]' if val[i + 1] isnt '=' and val[i + 2]? and keyword.test v
    val.join('')

  _splitter: _splitter = (string, delims) ->
    list = []
    i = if delims[0].test string[0] then 1 else 0
    while true
      next = string.search delims[i]
      if next is -1
        list.push string
        return list
      list.push string[..next - 1]
      string = string[next..]
      i = 1 - i
