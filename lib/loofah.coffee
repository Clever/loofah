_ = require 'underscore'
_.mixin require 'underscore.deep' # the version that works is not on npm

module.exports =
  default: -> _.compose(key_value_pairs(), url_query_params(), object_keys())

  object_keys: object_keys = (b_keys = ['password', 'user', 'email', 'api', 'secret']) ->
    (object) -> _check_and_call _object_keys, object, b_keys

  substrings: substrings = (sstrings) ->
    (object) -> _check_and_call _substrings, object, sstrings

  url_query_params: url_query_params = (query_params = ['client_id', 'client_secret', 'refresh_token']) ->
    (object) -> _check_and_call _url_query_params, object, query_params

  key_value_pairs: key_value_pairs = (keywords = ['user', 'username', 'password', 'email'], delims = "\\s:=") ->
    (object) -> _check_and_call _key_value_pairs, object, {keywords, delims}

_check_and_call = (func, object, keywords) ->
  return object unless _.isString(object) or _.isObject(object)
  return func object, keywords if _.isString object
  _.deepMapValues object, (val, key) ->
    return val unless  _.isString val
    func val, keywords, key

_splitter = (string, delims) ->
  split_string = []
  i = if delims[0].test string[0] then 1 else 0
  while true
    if (next = string.search delims[i]) is -1
      split_string.push string
      return split_string
    split_string.push string[..next - 1]
    string = string[next..]
    i = 1 - i

_object_keys = (val, b_keys, key) ->
  return val unless key?
  _.each b_keys, (b_key) ->
    b_key = new RegExp "(\\.|^)#{b_key}(\\.|$)", 'i' unless _.isRegExp b_key
    return val = '[REDACTED]' if (b_key.test key)
  val

_substrings = (string, sstrings) ->
  _.each sstrings, (sstring) ->
    sstring = new RegExp sstring, 'g' unless _.isRegExp sstring
    string = string.replace sstring, '[REDACTED]'
  string

_key_value_pairs = (string, keywords) ->
  {keywords, delims} = keywords
  val = _splitter string , [
      new RegExp "[^#{delims}]"
      new RegExp "[#{delims}]"
  ]
  _.each keywords, (keyword) ->
    keyword = new RegExp "^#{keyword}$", 'i' unless _.isRegExp keyword
    _.each val, (v, i) ->
      val[i + 2] = '[REDACTED]' if val[i + 1] isnt '=' and val[i + 2]? and keyword.test v
  val.join('')

_url_query_params = (string, query_params) ->
  val = _splitter string, [/[=.&?]/, /[^=.&?]/]
  _.each query_params, (qparam) ->
    qparam = new RegExp "(^|[=.&?])#{qparam}", 'i' unless _.isRegExp qparam
    _.each val, (v, i) ->
      val[i + 2] = "[REDACTED]" if val[i + 2]? and val[i + 1] is '=' and qparam.test v
  val.join('')

module.exports._private = {_splitter} if process.env.NODE_ENV is 'test'
