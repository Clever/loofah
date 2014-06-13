## Loofah

A Javascript library that scrubs data.

## Introduction

```javascript
Scrubbers = require 'lib/loofah'
```
You often need to scrub sensitive information from data before moving it to an insecure location, or publishing it. For example, you may want to publish errors on [Sentry](https://app.getsentry.com/) and before doing this, you should ensure that you are not exposing fields like passwords, api keys or usernames. Loofah provides a number of easily extensible and configurable helper functions to remove these. For example, to redact all values associated with a key of `password` or `secret` you would call:

```javascript
object = {a : {password: 'pwd', secrets: 'no match'}, secret: 'shhh'
clean_object = Scrubbers.object_keys(['password', 'secret'])(object)
clean_object
// {a : {password: '[REDACTED]', secrets: 'no match'}, secret: '[REDACTED]'
```

## Library Functions

The loofah library provides a number of helper functions or scrubbers which operate on strings, objects and arrays. If given an object or array, the functions call themselves on all of its members using _.map or deepMapValues from [underscore.deep](https://github.com/Clever/underscore.deep). If the functions encounter something that is not a string, object or array it is returned unchanged.

Each helper function takes a list of keywords - in the example above these are `password` and `secret`. These return a function that can then be called on an object. 

```javascript
myscrubber = Scrubbers.object_keys(['password', 'secret'])
myscrubber({nothing: 'to scrub'})
# {nothing: 'to scrub'}
myscrubber({password: 'scrub this'})
# {password: '[REDACTED]'}
```

The keywords specify search terms and can either be regular expressions or strings. Some functions will scrub the match (substrings) while others expect the search term to be a key and will scrub the value that follows. Strings will be converted to regular expressions by the scrubber. The Regex will generally be case insensitive and need to match an entire key.

### object_keys
If passed an object, redacts all information stored in a key that matches one of the keywords. If not passed an object, `object keys` returns what it was given.

```javascript
Scrubbers.object_keys(['secret', 'password'])({password: { a: 'pwd1', b: 'pwd2'}, secrets: 'not matched'})
// {password: { a: '[REDACTED]', b: '[REDACTED]'}, secrets: 'not matched'}
```

### substrings
Redacts all substrings that match one of the keywords. If given an array or object `substrings` calls itself on each of the values.
NB: Keywords passed as strings will be converted to case sensitive Regex

```javascript
Scrubbers.substrings(['thisIsOurApiKey'])( "Don't steal our thisIsOurApiKey")
// Don't steal our [REDACTED]
Scrubbers.substrings(['thisIsOurApiKey'])({a: 'wrong case thisisourapikey', b: 'look, thisIsOurApiKey'})
// {a: 'wrong case thisisourapikey', b: 'look, [REDACTED]'}
```

### url_query_params
Redacts the value of a url encoded `'<key>=<value>'` pair where the key matches one of the keywords. If passed an array or object, `url_query_params` calls itself on each of the values.

```javascript
Scrubbers.url_query_params(['client_id', 'client_secret'])('www.example.com/?CliENT_Id=123456789.apps.com&client_secret=123456789&grant_type=refresh_token')
// www.example.com/?[REDACTED].apps.com&[REDACTED]&grant_type=refresh_token
```

### key_value_pairs
Redacts the value of `'<key><delim><value>'` pairs in where the key matches one of the keywords. The delimiters can be specified in a string after the keywords, else they default to whitespace, `=` and `:`. If passed an array or object `key_value_pairs` calls itself on each of the values.

```javascript
Scrubbers.key_value_pairs(['email', 'user'])("The user: NAME has email = NAME@example.com")
// The user: [REDACTED] has email = [REDACTED]
myscrubber = Scrubbers.key_value_pairs(['email', 'user'], "//s=:-") // delimiters are whitespace, '=', ':' and '-'
("The user: NAME has email - NAME@example.com")
// The user: [REDACTED] has email - [REDACTED]
```

## Composition
These functions can easily be composed using _.compose:

```javascript
_.compose(Scrubbers.object_keys(['password', 'secret']), Scrubbers.substrings(['12345abcde']))(object)
```

## Defaults
Loofah provides a default list of keywords for each of its functions (except substrings which should only be called with application specific values). You can call using the default configuration by providing no arguments.

```javascript
Scrubbers.object_keys()(object)
```

You can also call all of the library functions (except substrings) with their defaults by calling:

```javascript
Scrubbers.default()(object)
// equivalent to _.compose(key_value_pairs(), url_query_params(), object_keys())(object)
```

If the defaults are not quite right, you can add extra parameters by composition.

```javascript
_.compose(Scrubbers.default(), Scrubbers.object_keys(['keys', 'not', 'in', 'defaults']))(object)
```

This will call object_keys twice; once with the parameters specified in defaults and once with your parameters. There is no way to remove parameters from the defaults other than editing the code.
