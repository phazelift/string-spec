assign				= require 'assign-variable'
hasUnicode			= require '@sygn/has-unicode'
intersection		= require 'string-intersection'
MessageEvents		= require 'message-events'
notIncludedChars	= require '@sygn/not-included-characters'
{ notString, forceString, forceObject, isFunction } = require 'types.js'


ALL_INIT_PROPS		= [ 'id', 'min', 'max', 'include', 'exclude', 'regexp', 'unicode','validator' ]
DEFAULT_REGEXP		= new RegExp
DEFAULT_VALIDATOR = -> true


ERROR_MSG =
	0: ''
	# initialization errors
	11: 'unknown key found in initialization object'
	12: 'include and regexp should not be mixed, regexp now ignored'
	13: 'cannot set max value smaller than min value, max now set to min'
	14: 'invalid initialization prop-type'

	# validation errors
	21: 'found not included character(s)'
	22: 'found excluded character(s)'
	23: 'too long'
	24: 'too short'
	25: 'contains unicode character(s)'
	26: 'invalid argument type'
	27: 'regexp validation failed'
	28: 'custom validation failed'


# message method id defaults to constructor
# all non constructor messages should supply their method id
message = new MessageEvents 'error', (id, code, method= '') ->
	sender	: 'string-spec'
	method	: if (code < 20) then 'constructor' else method
	type		: 'error'
	id			: forceString id
	code		: code
	text		: ERROR_MSG[ code ]


# passing through messages from assign used in constructor
# hiding 'undefined' warnings because all initialization props are optional
assign.onWarn (msg) ->
	if msg.value isnt undefined
		message.error msg.id, 14




class StringSpec

	@onError: (handler) -> message.on 'error', handler


	# checking for typo's to support debugging
	checkProps: (props) ->
		props	= forceObject props
		for key, value of props
			if ALL_INIT_PROPS.indexOf(key) < 0
				message.error forceString(props.id), 11
		return props



	constructor: (props) ->
		props				= @checkProps props
		@id				= assign props.id, '', 'id'
		@min				= assign props.min, 0, 'min'
		@max				= assign props.max, Infinity, 'max'
		@include 		= assign props.include, '', 'include'
		@exclude 		= assign props.exclude, '', 'exclude'
		@regexp			= assign props.regexp, DEFAULT_REGEXP, 'regexp'
		@unicode 		= assign props.unicode, false, 'unicode'
		@validator		= assign props.validator, DEFAULT_VALIDATOR, 'validator'

		if @include and (@regexp isnt DEFAULT_REGEXP)
			@regexp = DEFAULT_REGEXP
			message.error @id, 12

		if @min > @max
			@max = @min
			message.error @id, 13

		return Object.freeze @




	validationResult: (value, code= 0, found= []) ->
		id			: @id
		value		: value
		code		: code
		error		: ERROR_MSG[ code ]
		found		: found



	assign: (value, alt) ->

		handleAlt = (result) => if (isFunction alt) then (alt result) else (forceString alt)

		if notString value
			message.error @id, 26, 'assign'
			return handleAlt @validationResult value, 26, [value]

		validation = @validate value
		if validation.error
			return handleAlt validation
		return value



	validate: (value) ->

		if notString value
			message.error @id, 26, 'validate'
			return @validationResult value, 26, [value]

		if (not @unicode) and (hasUnicode value)
			return @validationResult value, 25

		if (value.length > @max)
			return @validationResult value, 23, [value]

		if (value.length < @min)
			return @validationResult value, 24, [value]

		if @include.length
			found = notIncludedChars value, @include
			if found.length
				return @validationResult value, 21, found

		if @exclude.length
			found = intersection value, @exclude
			if found.length
				return @validationResult value, 22, found

		if (@regexp isnt DEFAULT_REGEXP) and not (@regexp.test value)
			return @validationResult value, 27

		if not validation = @validator value
			return @validationResult value, 28

		return @validationResult value



module.exports = StringSpec
