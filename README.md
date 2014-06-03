## Scrub

A coffeescript library to scrub sensitive data from objects.

## Library Functions

```
Scrubbers = require 'lib/scrub'
```

The scrub library provides a number of helper functions. Each of these functions take a list of keywords which specify what is to be scrubbed. They each return a function that takes an object. When called, this function operates on a copy of the given object and returns it.

### bad_keys
Omits all keys in the object that match a case insensitive regex text with one of keywords. This is designed to remove common keys such as 'password'. You should be careful to choose fairly specific keywords - `'id'` will result in key `'skid'` being omitted.

### bad_vals
Replaces any substring that exactly matches one of the keywords with `'[REDACTED]'`. This is designed to protect against sharing of known secrets such as API keys, secrets or id.

### url_encode
Replaces an url encoded `'<key>=<value>'` pair with `'[REDACTED]'`, where key matches a case insensitive regex test with `"#{keyword}="`. For example `'www.example.com/client_id=12345&password=pwd'` will be changed to `'www.example.com/[REDACTED]&[REDACTED]'` if `client_id` and `password` (or `id` but not `client`) are provided as keywords.

### plain_text
Searches through each of the object's values until it finds a case insensitive regex match with one of the keywords. It replaces all text from the start of the match to the second contiguous set of delimiters with `'[REDACTED]'`. E.g. `'userPasswordlist<some number of delims>pwds<delim>'` will be reduced to `'user[REDACTED]<delim>'` if `'password'` is a keyword. As with bad_keys, you should choose specific keywords to prevent accidental matching.

## Usage
To remove all keys that include `'password'` or `'secret'` you would call:

```
Scrubbers.bad_keys(['password', 'secret']) object
```
Similarly, to ensure that the string 'abcde12345' (which is a secret key) is removed, you would call:

```
Scrubbers.bad_vals(['abcde12345']) object
```

## Composition
These functions can easily be composed using _.compose:

```
_.compose(Scrubbers.bad_keys(['password', 'secret']), Scrubbers.bad_vals(['12345abcde'])) object
```

## Defaults
The scrub library provides a default configuration for each of its functions (except bad_vals which should only be called with application specific values). These defaults are defined in the Scrubber class. You can call with the defaults by providing no arguments, an empty or array, or an argument that is not an array.

```
Scrubbers.bad_keys() object
```

You can also call all of the library functions (except bad_vals) with their defaults by calling:

```
Scrubbers.default() object
```

If the defaults are not quite right, you can add extra parameters by composition.

```
_.compose(Scrubbers.defaults(), Scrubbers.bad_keys(['keys', 'not', 'in', 'defaults'])) object
```

This will call bad_keys twice; once with the parameters specified in defaults and once with your parameters. There is no way to remove parameters from the defaults other than editing the code.


## User extensible
You can easily write your own functions and use them with the provided scrubbers. If you have the following scrubber:

```
scrub: (keywords) ->
  return (object) ->
    <do something on a copy of object>
    return object
```
You can easily compose it with the provided scrubbers:

```
uscrub = require 'user_scrubfile'
_.compose(Scrubbers.bad_keys(['password', 'secret']), uscrub_scrub(['some', args'])) object
```
