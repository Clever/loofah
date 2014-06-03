_ = require 'underscore'
assert = require 'assert'
os = require 'os'

Scrubbers = require ("#{__dirname}/../lib/loofah")
user_scrub = require("#{__dirname}/lib/user_scrubber")

describe 'sentry-node', ->

  it 'scrubs keys with banned names', ->
    object =
      a : 'non sensitive'
      b :
        secret : 'shhhh'
        c : 'non sensitive'
        big_Secret: 'SHHHH'
      passwords :
        api: 'qwerty'
    expected =
      a: 'non sensitive'
      b: c: 'non sensitive'
    assert.deepEqual (Scrubbers.bad_keys(['secret', 'password']) object), expected

  it 'scrubs banned values', ->
    object =
      a: 'a string of text contains thisIsOurApiKey'
      b: 'a string of text contains thisisourapikey'
      c: 'a normal string'
    expected =
      a: 'a string of text contains [REDACTED]'
      b: 'a string of text contains thisisourapikey'
      c: 'a normal string'
    assert.deepEqual (Scrubbers.bad_vals(['thisIsOurApiKey']) object), expected

  it 'replaces sensitive url encoded info with [REDACTED]', ->
    object =
      url: 'refresh_token=1234567890asdfghjkl&CliENT_Id=123456789.apps.googleusercontent.com&client_secret=123456789asdfghjkl&grant_type=refresh_token'
    expected = {url: '[REDACTED]&[REDACTED].apps.googleusercontent.com&[REDACTED]&grant_type=refresh_token'}
    assert.deepEqual (Scrubbers.url_encode(['refresh_token', 'client_id', 'client_secret']) object), expected

  it 'replaces senstive info in string with [REDACTED]', ->
    object =
      a: 'Error: something went wrong'
      b: 'Error: Username 12345@example.com was taken'
      c: 'Error: thisUsernames 12345@example.com was taken'
      d: 'username 12345@example.com was taken'
      e: 'Error: Username 12345@example.com'
      f: 'Error: Username  =  12345@example.com'
      g: 'Error: Username'
    expected =
      a: 'Error: something went wrong'
      b: 'Error: [REDACTED] was taken'
      c: 'Error: this[REDACTED] was taken'
      d: '[REDACTED] was taken'
      e: 'Error: [REDACTED]'
      f: 'Error: [REDACTED]'
      g: 'Error: [REDACTED]'
    assert.deepEqual (Scrubbers.plain_text(['username']) object), expected

  it 'allows user defined functions', ->
    object =
      a: 'good'
      omit_this_key: 'bad'
    expected =
      a: 'good'
    assert.deepEqual (user_scrub.scrub(['some', 'bads']) object), expected

  it 'allows different illegal words for different functions', ->
    object =
      user: 'name'
      id: 'number'
      a: 'user'
      b: 'id 123456'
      c: 'someurl?id=12345&user=name'
    expected =
      id: 'number'
      a: 'user'
      b: '[REDACTED]'
      c: 'someurl?[REDACTED]&user=name'
    scrub = _.compose(Scrubbers.plain_text(['id']), Scrubbers.bad_keys(['user']), Scrubbers.url_encode(['id']),)
    assert.deepEqual (scrub object), expected

  it 'has sensible defaults', ->
    object =
      password: 'pwd!'
      a: 'boring'
    expected =
      a : 'boring'
    assert.deepEqual (Scrubbers.bad_keys() object), expected
    assert.deepEqual (Scrubbers.bad_keys('not array') object), expected
    assert.deepEqual (Scrubbers.bad_keys([]) object), expected

  it 'allows default composition', ->
    object =
      password: 'pwd'
      url: 'refresh_token=1234512345a&client_id=someid&client_secret=somethingelse'
      string: 'username = 12345@example.com'
    expected =
      url: '[REDACTED]&[REDACTED]&[REDACTED]'
      string: '[REDACTED]'
    assert.deepEqual (Scrubbers.default() object), expected

  it 'allows user defined functions to be composed with default ones', ->
    object =
      password: 'pwd'
      url: 'refresh_token=1234512345a&client_id=someid&client_secret=somethingelse'
      string: 'username = 12345@example.com'
      omit_this_key: 'some_val'
    expected =
      url: '[REDACTED]&[REDACTED]&[REDACTED]'
      string: '[REDACTED]'
    scrub = _.compose(Scrubbers.default(), user_scrub.scrub(['some', 'bads']))
    assert.deepEqual (scrub object), expected
