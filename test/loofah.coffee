_ = require 'underscore'
assert = require 'assert'
os = require 'os'

Scrubbers = require ("#{__dirname}/../lib/loofah")
user_scrub = require("#{__dirname}/lib/user_scrubber")

describe 'Loofah', ->

  describe 'bad_keys', ->
    _.each [
      [{a: 'non sensitive'}, {a: 'non sensitive'}]
      [
        {b: {secret:'shhh', c: 'non sensitive'}, big_secret: 'SHHH'}
        {b: {secret:'[REDACTED]', c: 'non sensitive'}, big_secret: 'SHHH'}
      ]
      [{password: 'pwd'}, {password: '[REDACTED]'}]
    ], ([input, output]) ->
      it 'scrubs keys with banned names', ->
        assert.deepEqual (Scrubbers.bad_keys(['secret', 'password']) input), output

    _.each ['string', 2, undefined, null], (value) ->
      it 'if not given an object, returns what it was given', ->
        assert.equal (Scrubbers.bad_keys(['secret', 'password']) value), value


  describe 'bad_vals', ->
    _.each [
      [{a: 'a string of text contains thisIsOurApiKey'}, {a: 'a string of text contains [REDACTED]'}]
      [{b: 'a string of text contains thisisourapikey'}, {b: 'a string of text contains thisisourapikey'}]
      [{c: 'thisIsOurApiKeythisIsOurApiKeythisIsOurApiKey'}, {c: '[REDACTED][REDACTED][REDACTED]'}]
      ['thisIsOurApiKeythisIsOurApiKeythisIsOurApiKey', '[REDACTED][REDACTED][REDACTED]']
    ], ([input, output]) ->
      it 'scrubs banned values in strings and objects', ->
        assert.deepEqual (Scrubbers.bad_vals(['thisIsOurApiKey']) input), output

    _.each [2, undefined, null], (value) ->
      it 'if not given an object or string, returns what it was given', ->
        assert.equal (Scrubbers.bad_vals(['some', 'kwargs']) value), value


  describe 'url_encode', ->
    _.each [
      [
        {url: 'refresh_token=1234567890asdfghjkl&CliENT_Id=123456789.apps.googleusercontent.com&client_secret=123456789asdfghjkl&grant_type=refresh_token'}
        {url: 'refresh_token=[REDACTED]&CliENT_Id=[REDACTED].apps.googleusercontent.com&client_secret=[REDACTED]&grant_type=refresh_token'}
      ]
      [
        'refresh_token=1234567890asdfghjkl&CliENT_Id=123456789.apps.googleusercontent.com&client_secret=123456789asdfghjkl&grant_type=refresh_token'
        'refresh_token=[REDACTED]&CliENT_Id=[REDACTED].apps.googleusercontent.com&client_secret=[REDACTED]&grant_type=refresh_token'
      ]
    ], ([input, output]) ->
      it 'replaces sensitive url encoded info in strings and objects with [REDACTED]', ->
        assert.deepEqual (Scrubbers.url_encode([/client_*/i, 'refresh_token']) input), output

  _.each ['this username NAME is in a string', 2, undefined, null], (value) ->
    it 'if not given a url, returns what it was given', ->
      assert.deepEqual (Scrubbers.url_encode(['username']) value), value
   
  describe 'plain_text', ->
    _.each [
      ['Error: something went wrong', 'Error: something went wrong']
      ['Error: Username 12345@example.com was taken', 'Error: Username [REDACTED] was taken']
      ['Error: thisUsernames 12345@example.com was taken', 'Error: thisUsernames 12345@example.com was taken']
      ['username 12345@example.com was taken', 'username [REDACTED] was taken']
      ['Error: Username 12345@example.com', 'Error: Username [REDACTED]']
      ['Error: Username  =  12345@example.com', 'Error: Username  =  [REDACTED]']
      ['Error: Username', 'Error: Username']
      [{a:'Error: Username 12345@example.com'}, {a:'Error: Username [REDACTED]'}]
    ], ([input, output]) ->
      it 'replaces sensitive data in plain text with [REDACTED]', ->
        assert.deepEqual (Scrubbers.plain_text(['username']) input), output

    _.each [2, undefined, null], (value) ->
      it 'if not given an object or string, returns what it was given', ->
        assert.equal (Scrubbers.plain_text(['username']) value), value

  describe 'composition and extension', ->
      
    it 'allows user defined functions', ->
      assert.deepEqual (user_scrub.scrub(['some', 'bads']) {a:'good', omit_this_key:'bad'}), {a:'good'}

    _.each [
      [{user:'name'}, {user:'[REDACTED]'}]
      [{id:'number'}, {id:'number'}]
      [{a:'user'}, {a:'user'}]
      [{b:'id 1234'}, {b:'id [REDACTED]'}]
      [{c:'someurl?id=12345&user=name'}, {c:'someurl?id=[REDACTED]&user=name'}]
    ], ([input, output]) ->
      it 'allows different illegal words for different functions', ->
        scrub = _.compose(Scrubbers.plain_text(['id']), Scrubbers.bad_keys(['user']), Scrubbers.url_encode(['id']),)
        assert.deepEqual scrub(input), output

    _.each [
      [Scrubbers.bad_keys(), {password: 'pwd', a: 'password'}, {password: '[REDACTED]', a: 'password'}]
      [Scrubbers.plain_text(), 'user NAME is taken', 'user [REDACTED] is taken']
      [Scrubbers.url_encode(), 'www.example.com/?client_id=abc&client_secret=123'
        ,'www.example.com/?client_id=[REDACTED]&client_secret=[REDACTED]']
    ], ([func, input, output]) ->
      it 'has default args when none are given', ->
        assert.deepEqual func(input), output

    _.each [
      [{password: 'pwd'}, {password: '[REDACTED]'}]
      [
        {url: 'refresh_token=1234512345a&client_id=someid&client_secret=somethingelse'}
        {url: 'refresh_token=[REDACTED]&client_id=[REDACTED]&client_secret=[REDACTED]'}
      ]
      [{string: 'username = 12345@example.com'}, {string: 'username = [REDACTED]'}]
    ], ([input, output]) ->
      it 'allows default composition', ->
        assert.deepEqual (Scrubbers.default() input), output

    _.each [
      [{password: 'pwd'}, {password: '[REDACTED]'}]
      [
        {url: 'refresh_token=1234512345a&client_id=someid&client_secret=somethingelse'}
        {url: 'refresh_token=[REDACTED]&client_id=[REDACTED]&client_secret=[REDACTED]'}
      ]
      [{string: 'username = 12345@example.com'}, {string: 'username = [REDACTED]'}]
      [{omit_this_key: 'val'}, {}]
    ], ([input, output]) ->
      it 'allows user defined functions to be composed with default ones', ->
      scrub = _.compose(Scrubbers.default(), user_scrub.scrub(['some', 'bads']))
      assert.deepEqual (scrub input), output
