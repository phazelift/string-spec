// Generated by CoffeeScript 2.7.0
(function () {
  var ALL_INIT_PROPS, DEFAULT_REGEXP, DEFAULT_VALIDATOR, ERROR_MSG, MessageEvents, StringSpec, assign, forceObject, forceString, hasUnicode, intersection, isFunction, message, notIncludedChars, notString;
  assign = require('assign-variable');
  hasUnicode = require('@sygn/has-unicode');
  intersection = require('string-intersection');
  MessageEvents = require('message-events');
  notIncludedChars = require('@sygn/not-included-characters');
  ({
    notString,
    forceString,
    forceObject,
    isFunction
  } = require('types.js'));
  ALL_INIT_PROPS = ['id', 'min', 'max', 'include', 'exclude', 'regexp', 'unicode', 'validator'];
  DEFAULT_REGEXP = new RegExp();

  DEFAULT_VALIDATOR = function () {
    return true;
  };

  ERROR_MSG = {
    0: '',
    // initialization errors
    11: 'unknown key found in initialization object',
    12: 'include and regexp should not be mixed, regexp now ignored',
    13: 'cannot set max value smaller than min value, max now set to min',
    14: 'invalid initialization prop-type',
    // validation errors
    21: 'found not included character(s)',
    22: 'found excluded character(s)',
    23: 'too long',
    24: 'too short',
    25: 'contains unicode character(s)',
    26: 'invalid argument type',
    27: 'regexp validation failed',
    28: 'custom validation failed'
  }; // message method id defaults to constructor
  // all non constructor messages should supply their method id

  message = new MessageEvents('error', function (id, code, method = '') {
    return {
      sender: 'string-spec',
      method: code < 20 ? 'constructor' : method,
      type: 'error',
      id: forceString(id),
      code: code,
      text: ERROR_MSG[code]
    };
  }); // passing through messages from assign used in constructor
  // hiding 'undefined' warnings because all initialization props are optional

  assign.onWarn(function (msg) {
    if (msg.value !== void 0) {
      return message.error(msg.id, 14);
    }
  });
  StringSpec = class StringSpec {
    static onError(handler) {
      return message.on('error', handler);
    } // checking for typo's to support debugging


    checkProps(props) {
      var key, value;
      props = forceObject(props);

      for (key in props) {
        value = props[key];

        if (ALL_INIT_PROPS.indexOf(key) < 0) {
          message.error(forceString(props.id), 11);
        }
      }

      return props;
    }

    constructor(props) {
      props = this.checkProps(props);
      this.id = assign(props.id, '', 'id');
      this.min = assign(props.min, 0, 'min');
      this.max = assign(props.max, 2e308, 'max');
      this.include = assign(props.include, '', 'include');
      this.exclude = assign(props.exclude, '', 'exclude');
      this.regexp = assign(props.regexp, DEFAULT_REGEXP, 'regexp');
      this.unicode = assign(props.unicode, false, 'unicode');
      this.validator = assign(props.validator, DEFAULT_VALIDATOR, 'validator');

      if (this.include && this.regexp !== DEFAULT_REGEXP) {
        this.regexp = DEFAULT_REGEXP;
        message.error(this.id, 12);
      }

      if (this.min > this.max) {
        this.max = this.min;
        message.error(this.id, 13);
      }

      return Object.freeze(this);
    }

    validationResult(value, code = 0, found = []) {
      return {
        id: this.id,
        value: value,
        code: code,
        error: ERROR_MSG[code],
        found: found
      };
    }

    assign(value, alt) {
      var handleAlt, validation;

      handleAlt = result => {
        if (isFunction(alt)) {
          return alt(result);
        } else {
          return forceString(alt);
        }
      };

      if (notString(value)) {
        message.error(this.id, 26, 'assign');
        return handleAlt(this.validationResult(value, 26, [value]));
      }

      validation = this.validate(value);

      if (validation.error) {
        return handleAlt(validation);
      }

      return value;
    }

    validate(value) {
      var found, validation;

      if (notString(value)) {
        message.error(this.id, 26, 'validate');
        return this.validationResult(value, 26, [value]);
      }

      if (!this.unicode && hasUnicode(value)) {
        return this.validationResult(value, 25);
      }

      if (value.length > this.max) {
        return this.validationResult(value, 23, [value]);
      }

      if (value.length < this.min) {
        return this.validationResult(value, 24, [value]);
      }

      if (this.include.length) {
        found = notIncludedChars(value, this.include);

        if (found.length) {
          return this.validationResult(value, 21, found);
        }
      }

      if (this.exclude.length) {
        found = intersection(value, this.exclude);

        if (found.length) {
          return this.validationResult(value, 22, found);
        }
      }

      if (this.regexp !== DEFAULT_REGEXP && !this.regexp.test(value)) {
        return this.validationResult(value, 27);
      }

      if (!(validation = this.validator(value))) {
        return this.validationResult(value, 28);
      }

      return this.validationResult(value);
    }

  };
  module.exports = StringSpec;
}).call(this);