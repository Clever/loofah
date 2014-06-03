## Loofah

A coffeescript library to scrub sensitive data from objects.

## Library Functions

```
Scrubbers = require 'lib/loofah'
```

The loofah library provides a number of helper functions or scrubbers. Each of these functions takes a list of keywords which specifies what is to be scrubbed and returns a function that takes an object. When called, this function scrubs and returns a copy of the object.

### bad_keys
Omits all keys in the object that match a case insensitive regex text with one of keywords. This is designed to remove common keys such as 'password'. You should be careful to choose fairly specific keywords - `'id'` will result in key `'skid'` being omitted.

### bad_vals
Replaces any substring that exactly matches one of the keywords with `'[REDACTED]'`. This is designed to protect against sharing of known secrets such as API keys, secrets or ids.

### url_encode
Replaces an url encoded `'<key>=<value>'` pair with `'[REDACTED]'`, where key matches a case insensitive regex test with `"#{keyword}="`. For example `'www.example.com/client_id=12345&password=pwd'` will be changed to `'www.example.com/[REDACTED]&[REDACTED]'` if `client_id` and `password` (or `id` but not `client`) are provided as keywords.

### plain_text
It replaces all text from the start of a case insensitive regex match with one of the keywords to the second contiguous set of delimiters with `'[REDACTED]'`. E.g. `'userPasswordlist<some number of delims>pwds<delim>'` will be reduced to `'user[REDACTED]<delim>'` if `'password'` is a keyword. As with bad_keys, you should choose specific keywords to prevent accidental matching.

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
Loofah provides a default configuration for each of its functions (except bad_vals which should only be called with application specific values). These defaults are defined in the `'Scrubbers'` class. You can call using the default configuration by providing no arguments.

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
myloofah: (keywords) ->
  return (object) ->
    <do something on a copy of object>
    return object
```
You can easily compose it with the provided scrubbers:

```
scrub = require 'user_file'
_.compose(Scrubbers.bad_keys(['password', 'secret']), scrub.myloofah(['some', args'])) object
```
