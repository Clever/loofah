_ = require 'underscore'

module.exports =
  scrub: (bads) ->
    return (object) ->
      _.omit object, 'omit_this_key'

