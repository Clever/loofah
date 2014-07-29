_ = require 'underscore'
_.mixin require 'underscore.deep'

module.exports =
  default: -> _.compose key_value_pairs(), url_query_params(), object_keys()

  object_keys: object_keys = (b_keys = ['password', 'user', 'email', 'api', 'secret']) ->
    (val) -> deep_map_strings val, (subval, subkey) ->
      return subval unless subkey?
      _.each b_keys, (b_key) ->
        b_key = new RegExp "(\\.|^)#{b_key}(\\.|$)", 'i' unless _.isRegExp b_key
        return subval = '[REDACTED]' if (b_key.test subkey)
      subval

  substrings: substrings = (sstrings) ->
    (val) -> deep_map_strings val, (subval) -> string_substrings subval, sstrings

  url_query_params: url_query_params = (query_params = ['client_id', 'client_secret', 'refresh_token']) ->
    (val) -> deep_map_strings val, (subval) -> string_url_query_params subval, query_params

  key_value_pairs: key_value_pairs = (keywords = ['user', 'username', 'password', 'email'], delims = "\\s:=") ->
    (val) -> deep_map_strings val, (subval) -> string_key_value_pairs subval, keywords, delims

deep_map_strings = (val, fn) ->
  deep_map_objects_and_arrays val, (subval, subkey) ->
    if _.isString subval then fn subval, subkey else subval

clone_error = (error) ->
  new_error = Object.create Object.getPrototypeOf error
  props = Object.getOwnPropertyNames error
  Object.defineProperties new_error, _.object props,
    _.map props, (prop) -> Object.getOwnPropertyDescriptor error, prop

deep_map_objects_and_arrays = (val, fn) ->
  key_helper = (val, fn, key) ->
    switch
      when _.isPlainObject val
        _.deepMapValues val, (subval, subkey) ->
          key_helper subval, fn, if key then "#{key}.#{subkey}" else subkey
      when _.isArray val then _.map val, (subval) -> key_helper subval, fn, key
      when val instanceof Error
        props_to_scrub = _.keys(val).concat ['message', 'stack']
        _.extend clone_error(val), key_helper _.pick(val, props_to_scrub), fn, key
      else fn val, key
  key_helper val, fn, ''

string_substrings = (string, sstrings) ->
  _.each sstrings, (sstring) ->
    sstring = new RegExp sstring, 'g' unless _.isRegExp sstring
    string = string.replace sstring, '[REDACTED]'
  string

string_url_query_params = (string, query_params) ->
  val = string.split /([=.&/]+)/
  _.each query_params, (qparam) ->
    qparam = new RegExp "(^|[=.&?])#{qparam}", 'i' unless _.isRegExp qparam
    _.each val, (v, i) ->
      val[i + 2] = "[REDACTED]" if val[i + 2]? and val[i + 1] is '=' and qparam.test v
  val.join('')

string_key_value_pairs = (string, keywords, delims) ->
  val = string.split new RegExp "([#{delims}]+)"
  _.each keywords, (keyword) ->
    keyword = new RegExp "^#{keyword}$", 'i' unless _.isRegExp keyword
    _.each val, (v, i) ->
      val[i + 2] = '[REDACTED]' if val[i + 1] isnt '=' and val[i + 2]? and keyword.test v
  val.join('')
