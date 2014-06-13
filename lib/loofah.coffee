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

_check_and_call = (func, object, keywords, key) ->
  return func object, keywords, key if _.isString object
  return _map_over_array(func, object, keywords, key) if _.isArray object
  return _map_over_object(func, object, keywords, key) if _.isObject object
  object

_map_over_object = (func, object, keywords, base_key='') ->
  _.deepMapValues object, (val, key) ->
    return _map_over_array(func, val, keywords, "#{base_key}.#{key}") if _.isArray val
    return val unless _.isString val
    func val, keywords, "#{base_key}.#{key}"

_map_over_array = (func, object, keywords, key) ->
  _.map object, (item) ->
    _check_and_call(func, item, keywords, key)

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
  val = string.split new RegExp "([#{delims}]+)"
  _.each keywords, (keyword) ->
    keyword = new RegExp "^#{keyword}$", 'i' unless _.isRegExp keyword
    _.each val, (v, i) ->
      val[i + 2] = '[REDACTED]' if val[i + 1] isnt '=' and val[i + 2]? and keyword.test v
  val.join('')

_url_query_params = (string, query_params) ->
  val = string.split /([=.&/]+)/
  _.each query_params, (qparam) ->
    qparam = new RegExp "(^|[=.&?])#{qparam}", 'i' unless _.isRegExp qparam
    _.each val, (v, i) ->
      val[i + 2] = "[REDACTED]" if val[i + 2]? and val[i + 1] is '=' and qparam.test v
  val.join('')
