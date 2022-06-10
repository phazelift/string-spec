# string-spec

## A specific string type assign and validator

<br/>

Most often we don't need a string of infinite length with any possible type of characters. Yet, this is exactly what we define all the time:
```typescript
let name = '';	// serious?
```
When we need maximum performance there is pretty much no way around this. But when performance is not an issue, as for example with input validation, we can do better.

string-spec is like a type definition that is way more specific than just `let s: string;`

Once you have defined a string-spec you can validate values against it, or use it to assign values. Assigning values using string-spec assures your string variables/data to always comply to the spec you've defined.

Some examples
```typescript
// have some generic set of characters
const ALL_ALPHA_CHARACTERS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

// create a spec that can be re-used throughout your program
const tUsername = new StringSpec({
   id: 'username',
   min: 2,
   max: 36,
   include: ALL_ALPHA_CHARACTERS,
});


// .validate returns a result object
const validation = tUsername.validate('bob?');
// {
//    id: 'username',
//    code: 21,
//    error: 'found not included character(s)',
//    found: [ '?' ]
//    value: 'bob?'
// }

// use validation before using a value
const validation = tUsername.validate(value);
if ( validation.error ){
	handleUsernameError(validation);
} else doSomethingWithUsername(value);

// assign a value to a variable and be confident it won't be wrong
username = tUsername.assign('alice');
// username == 'alice'

// the second value is assigned in case validation fails
username = tUsername.assign('!#@$', '?');
// username == '?'

// .assign returns a typeof 'string' value at all times
username = tUsername.assign('alice?');
// username == ''

// you can handle validation by replacing the alternative value with a handler
username = tUsername.assign('d', ({ code }) => {
	// error code: 24 is for 'too short', see the error object spec for more
	if (code == 24){
		// you could trigger an event/action here to update UI with error message
		showUsernameError(`A minimum of ${tUsername.min} characters required!`);
	}
	// the return value is what will be assigned when validation fails
	return '';
});
// username == ''

// you can validate with regular expressions
// but mind, they cannot be mixed with setting the 'include' prop
const tMobilePhone = new StringSpec({
   id: 'mobilePhone',
   regexp: /^\s*\+?\s*([0-9][\s-]*){10}$/,
});
tMobilePhone.validate('0 123 456 789');
// { id: 'mobilePhone', code: 0, error: '', found: [] }

// when you need an even more specific string, and a regular expression
// is getting tricky, you can add your own validator to keep it readable
const tHexColor = new StringSpec({
	id: 'hexColor',
	include: 'abcdefABCDEF0123456789',
	validator: string => (string.length == 3) || (string.length == 6),
});
const color = tHexColor.assign('dude', 'fff');
// color == 'fff'
```

# API

All (optional) initialization props with their default values

```typescript
const tMyString = new StringSpec({
	id: '',                  // you can give an id to show in error messages
	min: 0,                  // minimum string length
	max: Infinity,           // maximum string length
	include: '',             // an empty string matches all possible characters
	exclude: '',             // include and exclude don't have to be mutually exclusive
	regexp: new RegExp,      // regexp can be set as sole validator
	unicode: false,          // set to true if you want to allow for unicode 😎
	validator: value => true // return false to invalidate value
});
```
Error objects returned by the .assign and .validate methods always contain the following properties and types:

	id: string        // add an id for this StringSpec to show in error messages
	code: number      // the error code generated (see all error codes and messages below)
	error: string     // the error string
	found: array      // an array with possible values that generated the error
	value: any        // the value argument passed to .assign or .validate


All error codes and their related text message:

	0: ''	(no error == empty string)

	initialization errors
	11: unknown key found in initialization object
	12: include and regexp should not be mixed, regexp now ignored
	13: cannot set max value smaller than min value, max now set to min
	14: invalid initialization prop-type

	validation errors
	21: found not included character(s)
	22: found excluded character(s)
	23: too long
	24: too short
	25: contains unicode character(s)
	26: invalid argument type
	27: regexp validation failed
	28: custom validation failed
---

string-spec won't spam argument/type/api errors or warnings into the console.  Instead uses <a href="https://www.npmjs.com/package/message-events">message-events</a>. You only have to supply a handler.
It's as simple as:
```typescript
StringSpec.onError(console.error);

const tTest = new StringSpec({ min: '2' });
// {
//   sender: 'string-spec',
//   id: 'min',
//   method: 'constructor',
//   type: 'error',
//   code: 14,
//   text: 'invalid initialization prop-type'
// }
```

---

## change log

0.1.0

- first commit

---
## License MIT




