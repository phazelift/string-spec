{ assert }	= require 'chai'
StringSpec = require '../string-spec.js'



error = null
StringSpec.onError (msg) -> error = msg
beforeEach -> error = null



describe 'constructor initialization', ->

	it 'should allow the constructor being called without an initialization object', ->
		new StringSpec
		assert.deepEqual error, null


	it 'should not allow the min property in the initialization object to be greater than the max property', ->
		new StringSpec {min: 1, max: 0}
		assert.deepEqual error,
			"code": 13
			"id": ""
			"method": "constructor"
			"sender": "string-spec"
			"text": "cannot set max value smaller than min value, max now set to min"
			"type": "error"

	it 'should show an error when an invalid prop type was used in initialization object', ->
		new StringSpec {min: '1', max: 0}
		assert.deepEqual error,
			"code": 14
			"id": "min"
			"method": "constructor"
			"sender": "string-spec"
			"text": "invalid initialization prop-type"
			"type": "error"

	it 'should show an error when a regexp and include was used in initialization object', ->
		new StringSpec {include: '1', regexp: /abc/}
		assert.deepEqual error,
			"code": 12
			"id": ""
			"method": "constructor"
			"sender": "string-spec"
			"text": "include and regexp should not be mixed, regexp now ignored"
			"type": "error"

	it 'include and exclude properties in the initialization object should not be mutually exclusive', ->
		new StringSpec {include: 'abc', exclude: 'bc'}
		assert.deepEqual error, null


	it 'returns an id of StringSpec', ->
		assert.isTrue (new StringSpec) instanceof StringSpec


	it 'initializes min correctly', ->
		validator = new StringSpec {min: 2}
		assert.equal validator.min, 2

	it 'initializes min correctly', ->
		validator = new StringSpec {min: '2'}
		assert.equal validator.min, 0


	it 'initializes max correctly', ->
		validator = new StringSpec {max: 2}
		assert.equal validator.max, 2


	it 'initializes include correctly', ->
		validator = new StringSpec {include: '?!'}
		assert.equal validator.include, '?!'


	it 'initializes exclude correctly', ->
		validator = new StringSpec {exclude: '?!'}
		assert.equal validator.exclude, '?!'

	it 'initializes regexp correctly', ->
		validator = new StringSpec {regexp: /abc/}
		validation = validator.validate 'abc'
		assert.deepEqual validation,
			"id": ""
			"code": 0
			"error": ""
			"found": []
			"value": "abc"

	it 'initializes unicode correctly', ->
		validator = new StringSpec {unicode: true}
		assert.equal validator.unicode, true

	it 'initializes validator correctly', ->
		validator = new StringSpec {validator: (s) -> s is '?'}
		validation = validator.validate '?'
		assert.deepEqual validation,
			"id": ""
			"code": 0
			"error": ""
			"found": []
			"value": "?"





describe '.validate functionality', ->


	it 'should reject calls when called without arguments', ->
		validator = new StringSpec {id: 'test'}
		validation = validator.validate()
		assert.deepEqual validation,
			"id": "test"
			"code": 26
			"error": "invalid argument type"
			"found": [undefined]
			"value": undefined

		assert.deepEqual error,
			"code": 26
			"id": "test"
			"method": "validate"
			"sender": "string-spec"
			"text": "invalid argument type"
			"type": "error"


	it 'should err on a string that is longer than max', ->
		validator = new StringSpec {id: 'max test', max: 3}
		assert.deepEqual validator.validate('jack'),
			"id": "max test"
			"code": 23
			"error": "too long"
			"found": ['jack']
			"value": "jack"


	it 'should err on a string that is shorter than min', ->
		validator = new StringSpec {min: 3}
		assert.deepEqual validator.validate('no'),
			"id": ""
			"code": 24
			"error": "too short"
			"found": ['no']
			"value": "no"


	it 'should err on a string that contains not included character(s)', ->
		validator = new StringSpec {include: 'abc'}
		assert.deepEqual validator.validate('abc?'),
			"id": ""
			"code": 21
			"error": "found not included character(s)"
			"found": ["?"]
			"value": "abc?"


	it 'should err on a string that contains excluded character(s)', ->
		validator = new StringSpec {id: 'exclude test', exclude: '?'}
		assert.deepEqual validator.validate('abc?'),
			"id": "exclude test"
			"code": 22
			"error": "found excluded character(s)"
			"found": ["?"]
			"value": "abc?"


	it 'should err on a string that doesnt match a regexp', ->
		validator = new StringSpec {regexp: /^abc$/}
		assert.deepEqual validator.validate('abc?'),
			"id": ""
			"code": 27
			"error": "regexp validation failed"
			"found": []
			"value": "abc?"


	it 'should not err on a string that does match a regexp', ->
		validator = new StringSpec {regexp: /^abc$/}
		assert.deepEqual validator.validate('abc'),
			"id": ""
			"code": 0
			"error": ""
			"found": []
			"value": "abc"


	it 'should err on unicode character(s) by default', ->
		validator = new StringSpec {}
		assert.deepEqual validator.validate('c🐶a'),
			"id": ""
			"code": 25
			"error": "contains unicode character(s)"
			"found": []
			"value": "c🐶a"


	it 'should allow unicode character(s) when set during initialization', ->
		validator = new StringSpec {id: 'unicode test', unicode: true}
		assert.deepEqual validator.validate('c🐶a'),
			"id": "unicode test"
			"code": 0
			"error": ""
			"found": []
			"value": "c🐶a"


	it 'should invalidate with custom validator', ->
		validator = new StringSpec {validator: (s) -> s is '!'}
		validation = validator.validate '?'
		assert.deepEqual validation,
			"id": ""
			"code": 28
			"error": "custom validation failed"
			"found": []
			"value": "?"




describe '.assign functionality', ->

	it 'should return the alt value when initialization has succeeded, but validation failed', ->
		validator = new StringSpec { min: 2 }
		result = validator.assign 'a', '?'
		assert.equal result, '?'


	it 'should not return the alt value when initialization has succeeded, but validation failed', ->
		validator = new StringSpec { exclude: 'x' }
		result = validator.assign 'ax', '?'
		assert.equal result, '?'


	it 'should assign the given value when initialization has succeeded and value is validated', ->
		validator = new StringSpec {min: 2, max: 4, exclude: 'x', include: 'aeiouk'}
		result = validator.assign 'ok', '?'
		assert.equal result, 'ok'


	it 'should accept an error handler as "alt" argument', ->
		validator = new StringSpec {id: 'handler test', min: 5, max: 6}
		result = validator.assign 'fail', (msg) ->
			assert.deepEqual msg,
				"id": "handler test"
				"code": 24
				"error": "too short"
				"found": ['fail']
				"value": "fail"
			return '?'
		assert.equal result, '?'


	it 'alt error handler should put undefined in found field if argument given is undefined', ->
		validator = new StringSpec {id: 'handler test', min: 5, max: 6}
		result = validator.assign undefined, (msg) ->
			assert.deepEqual msg,
				"id": "handler test"
				"code": 26
				"error": "invalid argument type"
				"found": [undefined]
				"value": undefined
			return '?'
		assert.equal result, '?'


