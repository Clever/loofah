_ = require 'underscore'
assert = require 'assert'
os = require 'os'

Scrubbers = require ("#{__dirname}/../lib/loofah")
user_scrub = require("#{__dirname}/lib/user_scrubber")

describe 'Loofah', ->

  describe 'bad_keys', ->
    it 'scrubs keys with banned names', ->
      object =
        a: 'non sensitive'
        b:
          secret: 'shhhh'
          c: 'non sensitive'
          big_Secret: 'SHHHH'
        passwords:
          d: 'qwerty'
      expected =
        a: 'non sensitive'
        b:
          secret: '[REDACTED]'
          c: 'non sensitive'
          big_Secret: '[REDACTED]'
        passwords:
          d: '[REDACTED]'
      assert.deepEqual (Scrubbers.bad_keys(['secret', 'password']) object), expected

    it 'if not given an object, returns what it was given', ->
      assert.equal (Scrubbers.bad_keys(['secret', 'password']) 'string'), 'string'
      assert.equal (Scrubbers.bad_keys(['secret', 'password']) 2), 2
      assert.equal (Scrubbers.bad_keys(['secret', 'password']) undefined), undefined


  describe 'bad_vals', ->
    it 'scrubs banned values in objects', ->
      object =
        a: 'a string of text contains thisIsOurApiKey'
        b: 'a string of text contains thisisourapikey'
        c: 'thisIsOurApiKeythisIsOurApiKeythisIsOurApiKey'
      expected =
        a: 'a string of text contains [REDACTED]'
        b: 'a string of text contains thisisourapikey'
        c: '[REDACTED][REDACTED][REDACTED]'
      assert.deepEqual (Scrubbers.bad_vals(['thisIsOurApiKey']) object), expected

    it 'scrubs banned values from strings', ->
      object = 'a string of text contains thisIsOurApiKey'
      expected = 'a string of text contains [REDACTED]'
      assert.equal (Scrubbers.bad_vals([/thisIsOurApiKey/g]) object), expected

    it 'if not given an object or string, returns what it was given', ->
      assert.equal (Scrubbers.bad_vals(['thisIsOurApiKey']) 2), 2
      assert.equal (Scrubbers.bad_vals(['secret', 'password']) undefined), undefined


  describe 'url_encode', ->
    it 'replaces sensitive url encoded info in objects with [REDACTED]', ->
      object =
        url: 'refresh_token=1234567890asdfghjkl&CliENT_Id=123456789.apps.googleusercontent.com&client_secret=123456789asdfghjkl&grant_type=refresh_token'
      expected =
      url: 'refresh_token=[REDACTED]&CliENT_Id=[REDACTED].apps.googleusercontent.com&client_secret=[REDACTED]&grant_type=refresh_token'
      assert.deepEqual (Scrubbers.url_encode([/client_*/i, 'refresh_token'] object), expected

    it 'replaces sensitive url encoded info in strings with [REDACTED]', ->
      url = 'refresh_token=1234567890asdfghjkl&CliENT_Id=123456789.apps.googleusercontent.com&client_secret=123456789asdfghjkl&grant_type=refresh_token'
      expected = 'refresh_token=[REDACTED]&CliENT_Id=[REDACTED].apps.googleusercontent.com&client_secret=[REDACTED]&grant_type=refresh_token'
      assert.equal (Scrubbers.url_encode(['client_secret', 'refresh_token', 'client_id', 'client_secret']) url), expected


  describe 'plain_text', ->
    it 'replaces senstive info in object with [REDACTED]', ->
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
        b: 'Error: Username [REDACTED] was taken'
        c: 'Error: thisUsernames [REDACTED] was taken'
        d: 'username [REDACTED] was taken'
        e: 'Error: Username [REDACTED]'
        f: 'Error: Username  =  [REDACTED]'
        g: 'Error: Username'
      assert.deepEqual (Scrubbers.plain_text(['username']) object), expected

    it 'replaces senstive info in string with [REDACTED]', ->
      string = 'Error: Username  =  12345@example.com'
      expected = 'Error: Username  =  [REDACTED]'
      assert.equal (Scrubbers.plain_text(['username']) string), expected

    it 'if not given an object or string, it returns what it was given', ->
      assert.equal (Scrubbers.plain_text(['username']) 2), 2
      assert.equal (Scrubbers.plain_text(['username']) null), null

  describe 'composition and extension', ->
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
        user: '[REDACTED]'
        id: 'number'
        a: 'user'
        b: 'id [REDACTED]'
        c: 'someurl?id=[REDACTED]&user=name'
      scrub = _.compose(Scrubbers.plain_text(['id']), Scrubbers.bad_keys(['user']), Scrubbers.url_encode(['id']),)
      assert.deepEqual (scrub object), expected

    it 'has sensible defaults', ->
      object =
        password: 'pwd!'
        a: 'boring'
      expected =
        password: '[REDACTED]'
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
        password: '[REDACTED]'
        url: 'refresh_token=[REDACTED]&client_id=[REDACTED]&client_secret=[REDACTED]'
        string: 'username = [REDACTED]'
      assert.deepEqual (Scrubbers.default() object), expected

    it 'allows user defined functions to be composed with default ones', ->
      object =
        password: 'pwd'
        url: 'refresh_token=1234512345a&client_id=someid&client_secret=somethingelse'
        string: 'username = 12345@example.com'
        omit_this_key: 'some_val'
      expected =
        password: '[REDACTED]'
        url: 'refresh_token=[REDACTED]&client_id=[REDACTED]&client_secret=[REDACTED]'
        string: 'username = [REDACTED]'
      scrub = _.compose(Scrubbers.default(), user_scrub.scrub(['some', 'bads']))
      assert.deepEqual (scrub object), expected
