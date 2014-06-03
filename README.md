## Scrub

A coffeescript library to scrub data from objects.

## Library Functions

```
Scrubbers = require 'lib/scrub'
```

The scrub library contains a variety of helper functions. These functions take as an argument a list of keywords which specify what is to be scrubbed. They return a function that takes an object, creates a copy of this object with the specified data scrubbed, and returns the copy.

### bad_keys
Omits any keys in the object that match a case insensitive regex text with one of keywords. This is designed to remove common keys such as 'password'.

### bad_vals
Replaces any substring that exactly matches one of the keywords with `'[REDACTED]'`. This is designed to protect against sharing of known secrets such as your API_key.

### url_encode
Replaces an url encoded &<key>=<value>& pair with `'[REDACTED]'`, where key matches a case insensitive regex test with one of the keywords. For example `'www.example.com/client_id=12345&password=pwd'` will be changed to `'www.example.com/[REDACTED]&[REDACTED]'` if `client_id` and `password` (or any substring of these keys) are provided as keywords.

### plain_text
Searches through each of the values in the object and replaces any `'key[delim]value'` pair with `'[REDACTED]'` where key is one of the keywords and delim is one of `'= '`.

## Usage
To remove all keys that include `'password'` or `'secret'` you would call:

```
Scrubbers.bad_keys(['password', 'secret']) object
```
Similarly, to ensure that the string 'abcde12345' shows up nowhere in the object, you would call:

```
Scrubbers.bad_vals(['abcde12345']) object
```

## Composition
These functions can easily be composed using _.compose:

```
_.compose(Scrubbers.bad_keys(['password', 'secret']), Scrubbers.bad_vals(['12345abcde'])) object
```

## Defaults
The scrub library provides a default which can be called using.

```
Scrubbers.default() object
```
See the code for the parameters that this uses.

If the defaults are not quite right, you can add extra parameters by composition.

```
_.compose(Scrubbers.defaults(), Scrubbers.bad_keys(['keys', 'not', 'in', 'defaults'])) object
```

If bad_keys is called as part of defaults, this will call it twice; once with the parameters specified in defaults and once with your parameters. There is no way to remove parameters from the defaults other than editing the code.


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
