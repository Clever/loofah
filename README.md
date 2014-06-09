## Loofah

A Javascript library that scrubs data.

## Introduction

```javascript
Scrubbers = require 'lib/loofah'
```
You often need to scrub sensitive information from data before moving it to an insecure location, or publishing it. For example, you may want to publish errors on [Sentry](https://app.getsentry.com/) and before doing this, you should ensure that you are not exposing fields like passwords, api keys or usernames. Loofah provides a number of easily extensible and configurable helper functions to remove these. For example, to get an object where the value is redacted for any keys that are either `password` or `secret` you would call.

```javascript
clean_object = Scrubbers.bad_keys(['password', 'secret'])(object)
```

## Library Functions


The loofah library provides a number of helper functions or scrubbers which can operate on strings and objects. Any other data type will be returned unchanged. To use one of these functions, call it with a list of keywords and then call the result of this on the data you want to scrub. 

```javascript
clean_object = Scrubbers.function_name([keywords])(object)
```

The keywords specify search terms and can either be regular expressions or strings. Some functions will scrub the match (bad_vals) while others expect the search term to be a key, and will scrub the value that follows. Strings will be converted to regular expressions by the scrubber. The Regex will generally be case sensitive and need to match an entire key.

### bad_keys
If passed an object, redacts all information stored in a key that matches one of the keywords.

```javascript
Scrubbers.bad_keys(['secret', 'password'])({password: { a: 'pwd1', b: 'pwd2'}, secrets: 'shhh'})
// {password: { a: '[REDACTED]', b: '[REDACTED]'}, secrets: 'shhh'} // secrets is not matched
```
If not passed an object, `bad_keys` returns what it was given.

### bad_vals
Redacts all substrings that match one of the keywords. Defaults to case sensitive regex.

```javascript
Scrubbers.bad_vals(['thisIsOurApiKey'])( 'Don't steal our thisIsOurApiKey')
// Don't steal our [REDACTED]
```


### url_encode
Redacts the value of a url encoded `'<key>=<value>'` pair where the key matches one of the keywords.

```javascript
Scrubbers.url_encode(['client_id', 'client_secret'])('www.example.com/?CliENT_Id=123456789.apps.com&client_secret=123456789&grant_type=refresh_token')
// www.example.com/?[REDACTED].apps.com&[REDACTED]&grant_type=refresh_token
```

### plain_text
Redacts the value of `'<key><delim><value>'` pairs in where the key matches one of the keywords and the delimiters are whitespace, `=` and `:`.

```javascript
Scrubbers.plain_text(['email', 'user'])("The user: NAME has email: NAME@example.com")
// The user: [REDACTED] has email: [REDACTED]
```

## Composition
These functions can easily be composed using _.compose:

```javascript
_.compose(Scrubbers.bad_keys(['password', 'secret']), Scrubbers.bad_vals(['12345abcde']))(object)
```

## Defaults
Loofah provides a default list of keywords for each of its functions (except bad_vals which should only be called with application specific values). You can call using the default configuration by providing no arguments.

```javascript
Scrubbers.bad_keys()(object)
```

You can also call all of the library functions (except bad_vals) with their defaults by calling:

```javascript
Scrubbers.default()(object)
```

If the defaults are not quite right, you can add extra parameters by composition.

```javascript
_.compose(Scrubbers.default(), Scrubbers.bad_keys(['keys', 'not', 'in', 'defaults']))(object)
```

This will call bad_keys twice; once with the parameters specified in defaults and once with your parameters. There is no way to remove parameters from the defaults other than editing the code.
