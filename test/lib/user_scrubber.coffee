_ = require 'underscore'

module.exports =
  scrub: (keywords) ->
    return (object) ->
      _.omit object, 'omit_this_key'

