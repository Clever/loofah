## Loofah

A Javascript library that scrubs data.

## Introduction

You often need to scrub sensitive information from data before it is made openly available. For example, you may want to publish errors on [Sentry](https://app.getsentry.com/). Before doing this, you should ensure that what you are publishing does not contain fields like passwords, api keys or usernames. Loofah provides a number of easily extensible and configurable helper functions to remove these.

## Library Functions

```
Scrubbers = require 'lib/loofah'
```

The loofah library provides a number of helper functions or scrubbers which can operate on strings and objects. Any other data type will be returned unchanged. To use one of these functions, call it with a list of keywords and then call the result of this on the data you want to scrub. 

```
clean_object = Scrubbers.function_name([keywords]) object
```

The keywords specify the fields to be scrubbed and can be either regular expressions or strings (strings will be converted to regular expressions by the scrubber). Choose specific keywords to avoid accidental matches: `id` would match both `skid` and `idle`. Take advantage of regular expressions: To match `id` pass `^id$` (relying on implicit conversion) or `/^id$/i`. Except where mentioned, the implicit conversion creates a regular expression that is case insensitive.

### bad_keys
If passed an object, redacts all information stored in a key that matches one of the keywords.

```
Scrubbers.bad_keys(['secret', 'password']) {passwords: { a: 'pwd1', b: 'pwd2'}, secret: 'shhh'}
# {password: { a: '[REDACTED]', b: '[REDACTED]'}, secret: '[REDACTED]'}
```
If not passed an object, `bad_keys` returns what it was given.

### bad_vals
Redacts all substrings that match one of the keywords. Defaults to case sensitive regex.

```
Scrubbers.bad_vals(['thisISourAPIkey']) 'Don't steal our thisISourAPIkey'
# Don't steal our [REDACTED]
```


### url_encode
Redacts the value of a url encoded `'<key>=<value>'` pair where the key matches one of the keywords.

```
Scrubbers.url_encode(['client_id', 'client_secret']) 'www.example.com/?CliENT_Id=123456789.apps.com&client_secret=123456789&grant_type=refresh_token'
# www.example.com/?[REDACTED].apps.com&[REDACTED]&grant_type=refresh_token
```

### plain_text
Redacts the value of `'<key><delim><value>'` pairs in where the key matches one of the keywords and the delimiters are whitespace, `=` and `:`.

```
Scrubbers.plain_text(['email', 'user']) "The user: NAME has email: NAME@example.com"
# The user: [REDACTED] has email: [REDACTED]
```

## Composition
These functions can easily be composed using _.compose:

```
_.compose(Scrubbers.bad_keys(['password', 'secret']), Scrubbers.bad_vals(['12345abcde'])) object
```

## Defaults
Loofah provides a default list of keywords for each of its functions (except bad_vals which should only be called with application specific values). You can call using the default configuration by providing no arguments.

```
Scrubbers.bad_keys() object
```

You can also call all of the library functions (except bad_vals) with their defaults by calling:

```
Scrubbers.default() object
```

If the defaults are not quite right, you can add extra parameters by composition.

```
_.compose(Scrubbers.default(), Scrubbers.bad_keys(['keys', 'not', 'in', 'defaults'])) object
```

This will call bad_keys twice; once with the parameters specified in defaults and once with your parameters. There is no way to remove parameters from the defaults other than editing the code.


## User extensible
You can easily write your own functions and use them with the provided scrubbers. If you have the following scrubber:

```
loof: (keywords) ->
  return (object) ->
    # Do something on object, using the keywords
    return object
```
You can easily compose it with the provided scrubbers:

```
new_loofah = require 'user_file'
_.compose(Scrubbers.bad_keys(['password', 'secret']), new_loofah.loof(['some', args'])) object
```
