_ = require 'underscore'
_.mixin require 'underscore.deep'

Scrubbers =
  default: ->
    bk = Scrubbers.bad_keys(['password', 'params'])
    ue = Scrubbers.url_encode(['client_id', 'client_secret', 'refresh_token'])
    pt = Scrubbers.plain_text(['username'])
    _.compose(pt, ue, bk)

  bad_vals: (substrings) ->
    return (object) =>
      obj = _.deepToFlat object
      _.each (_.pairs obj), ([key, val]) ->
        _.each substrings, (substring) ->
          obj[key] = obj[key].replace substring, '[REDACTED]'
      _.deepFromFlat obj

  bad_keys: (b_keys) ->
    return (object) =>
      obj = _.deepToFlat object
      _.each (_.keys obj), (key) ->
        _.each b_keys, (b_key) ->
          b_key = new RegExp b_key, 'i'
          if b_key.test key
            obj = _.omit obj, key
      _.deepFromFlat obj

  url_encode: (query_params) ->
    return (object) =>
      obj = _.deepToFlat object
      _.each (_.pairs obj), ([key, val]) ->
        _.each query_params, (qparam) ->
          # info can be encoded in the url in the form
          # <key>=<value> with . & ? field delimiters
          qparam = new RegExp "#{qparam}=", 'i'
          delimiters = new RegExp '[.&?]'
          while (start = val.search qparam) != -1
            end = start + val[start..].search delimiters
            s = if not start then '[REDACTED]' else val[..start - 1] + '[REDACTED]'
            e = if end > start then val[end..] else ''
            val = s + e
          obj[key] = val
      _.deepFromFlat obj

  plain_text: (keywords) ->
    return (object) =>
      obj = _.deepToFlat object
      _.each (_.pairs obj), ([key, val]) ->
        _.each keywords, (keyword) ->
          # Redact info in plain text
          delims = " ="
          delimiters = new RegExp "[#{delims}]"
          non_delimiters = new RegExp "[^#{delims}]"
          keyword = new RegExp "#{keyword}", 'i'
          while (start = val.search keyword) != -1
            end1 = start + val[start..].search delimiters
            end2 = end1 + val[end1..].search non_delimiters
            end3 = end2 + val[end2..].search delimiters
            s = if not start then '[REDACTED]' else val[..start - 1] + '[REDACTED]'
            e = if end3 > end2 and end2 > end1 and end1 > start then val[end3..] else ''
            val = s + e
          obj[key] = val
      _.deepFromFlat obj

module.exports = Scrubbers
