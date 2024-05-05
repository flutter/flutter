'use strict';

/*!
 * Module dependencies.
 */

const SchemaType = require('../schemaType');
const MongooseError = require('../error/index');
const SchemaStringOptions = require('../options/schemaStringOptions');
const castString = require('../cast/string');
const utils = require('../utils');
const isBsonType = require('../helpers/isBsonType');

const CastError = SchemaType.CastError;

/**
 * String SchemaType constructor.
 *
 * @param {String} key
 * @param {Object} options
 * @inherits SchemaType
 * @api public
 */

function SchemaString(key, options) {
  this.enumValues = [];
  this.regExp = null;
  SchemaType.call(this, key, options, 'String');
}

/**
 * This schema type's name, to defend against minifiers that mangle
 * function names.
 *
 * @api public
 */
SchemaString.schemaName = 'String';

SchemaString.defaultOptions = {};

/*!
 * Inherits from SchemaType.
 */
SchemaString.prototype = Object.create(SchemaType.prototype);
SchemaString.prototype.constructor = SchemaString;
Object.defineProperty(SchemaString.prototype, 'OptionsConstructor', {
  configurable: false,
  enumerable: false,
  writable: false,
  value: SchemaStringOptions
});

/*!
 * ignore
 */

SchemaString._cast = castString;

/**
 * Get/set the function used to cast arbitrary values to strings.
 *
 * #### Example:
 *
 *     // Throw an error if you pass in an object. Normally, Mongoose allows
 *     // objects with custom `toString()` functions.
 *     const original = mongoose.Schema.Types.String.cast();
 *     mongoose.Schema.Types.String.cast(v => {
 *       assert.ok(v == null || typeof v !== 'object');
 *       return original(v);
 *     });
 *
 *     // Or disable casting entirely
 *     mongoose.Schema.Types.String.cast(false);
 *
 * @param {Function} caster
 * @return {Function}
 * @function get
 * @static
 * @api public
 */

SchemaString.cast = function cast(caster) {
  if (arguments.length === 0) {
    return this._cast;
  }
  if (caster === false) {
    caster = this._defaultCaster;
  }
  this._cast = caster;

  return this._cast;
};

/*!
 * ignore
 */

SchemaString._defaultCaster = v => {
  if (v != null && typeof v !== 'string') {
    throw new Error();
  }
  return v;
};

/**
 * Attaches a getter for all String instances.
 *
 * #### Example:
 *
 *     // Make all numbers round down
 *     mongoose.Schema.String.get(v => v.toLowerCase());
 *
 *     const Model = mongoose.model('Test', new Schema({ test: String }));
 *     new Model({ test: 'FOO' }).test; // 'foo'
 *
 * @param {Function} getter
 * @return {this}
 * @function get
 * @static
 * @api public
 */

SchemaString.get = SchemaType.get;

/**
 * Sets a default option for all String instances.
 *
 * #### Example:
 *
 *     // Make all strings have option `trim` equal to true.
 *     mongoose.Schema.String.set('trim', true);
 *
 *     const User = mongoose.model('User', new Schema({ name: String }));
 *     new User({ name: '   John Doe   ' }).name; // 'John Doe'
 *
 * @param {String} option The option you'd like to set the value for
 * @param {Any} value value for option
 * @return {undefined}
 * @function set
 * @static
 * @api public
 */

SchemaString.set = SchemaType.set;

SchemaString.setters = [];

/*!
 * ignore
 */

SchemaString._checkRequired = v => (v instanceof String || typeof v === 'string') && v.length;

/**
 * Override the function the required validator uses to check whether a string
 * passes the `required` check.
 *
 * #### Example:
 *
 *     // Allow empty strings to pass `required` check
 *     mongoose.Schema.Types.String.checkRequired(v => v != null);
 *
 *     const M = mongoose.model({ str: { type: String, required: true } });
 *     new M({ str: '' }).validateSync(); // `null`, validation passes!
 *
 * @param {Function} fn
 * @return {Function}
 * @function checkRequired
 * @static
 * @api public
 */

SchemaString.checkRequired = SchemaType.checkRequired;

/**
 * Adds an enum validator
 *
 * #### Example:
 *
 *     const states = ['opening', 'open', 'closing', 'closed']
 *     const s = new Schema({ state: { type: String, enum: states }})
 *     const M = db.model('M', s)
 *     const m = new M({ state: 'invalid' })
 *     m.save(function (err) {
 *       console.error(String(err)) // ValidationError: `invalid` is not a valid enum value for path `state`.
 *       m.state = 'open'
 *       m.save(callback) // success
 *     })
 *
 *     // or with custom error messages
 *     const enum = {
 *       values: ['opening', 'open', 'closing', 'closed'],
 *       message: 'enum validator failed for path `{PATH}` with value `{VALUE}`'
 *     }
 *     const s = new Schema({ state: { type: String, enum: enum })
 *     const M = db.model('M', s)
 *     const m = new M({ state: 'invalid' })
 *     m.save(function (err) {
 *       console.error(String(err)) // ValidationError: enum validator failed for path `state` with value `invalid`
 *       m.state = 'open'
 *       m.save(callback) // success
 *     })
 *
 * @param {...String|Object} [args] enumeration values
 * @return {SchemaType} this
 * @see Customized Error Messages https://mongoosejs.com/docs/api/error.html#Error.messages
 * @see Enums in JavaScript https://masteringjs.io/tutorials/fundamentals/enum
 * @api public
 */

SchemaString.prototype.enum = function() {
  if (this.enumValidator) {
    this.validators = this.validators.filter(function(v) {
      return v.validator !== this.enumValidator;
    }, this);
    this.enumValidator = false;
  }

  if (arguments[0] === void 0 || arguments[0] === false) {
    return this;
  }

  let values;
  let errorMessage;

  if (utils.isObject(arguments[0])) {
    if (Array.isArray(arguments[0].values)) {
      values = arguments[0].values;
      errorMessage = arguments[0].message;
    } else {
      values = utils.object.vals(arguments[0]);
      errorMessage = MongooseError.messages.String.enum;
    }
  } else {
    values = arguments;
    errorMessage = MongooseError.messages.String.enum;
  }

  for (const value of values) {
    if (value !== undefined) {
      this.enumValues.push(this.cast(value));
    }
  }

  const vals = this.enumValues;
  this.enumValidator = function(v) {
    return null == v || ~vals.indexOf(v);
  };
  this.validators.push({
    validator: this.enumValidator,
    message: errorMessage,
    type: 'enum',
    enumValues: vals
  });

  return this;
};

/**
 * Adds a lowercase [setter](https://mongoosejs.com/docs/api/schematype.html#SchemaType.prototype.set()).
 *
 * #### Example:
 *
 *     const s = new Schema({ email: { type: String, lowercase: true }})
 *     const M = db.model('M', s);
 *     const m = new M({ email: 'SomeEmail@example.COM' });
 *     console.log(m.email) // someemail@example.com
 *     M.find({ email: 'SomeEmail@example.com' }); // Queries by 'someemail@example.com'
 *
 * Note that `lowercase` does **not** affect regular expression queries:
 *
 * #### Example:
 *
 *     // Still queries for documents whose `email` matches the regular
 *     // expression /SomeEmail/. Mongoose does **not** convert the RegExp
 *     // to lowercase.
 *     M.find({ email: /SomeEmail/ });
 *
 * @api public
 * @return {SchemaType} this
 */

SchemaString.prototype.lowercase = function(shouldApply) {
  if (arguments.length > 0 && !shouldApply) {
    return this;
  }
  return this.set(v => {
    if (typeof v !== 'string') {
      v = this.cast(v);
    }
    if (v) {
      return v.toLowerCase();
    }
    return v;
  });
};

/**
 * Adds an uppercase [setter](https://mongoosejs.com/docs/api/schematype.html#SchemaType.prototype.set()).
 *
 * #### Example:
 *
 *     const s = new Schema({ caps: { type: String, uppercase: true }})
 *     const M = db.model('M', s);
 *     const m = new M({ caps: 'an example' });
 *     console.log(m.caps) // AN EXAMPLE
 *     M.find({ caps: 'an example' }) // Matches documents where caps = 'AN EXAMPLE'
 *
 * Note that `uppercase` does **not** affect regular expression queries:
 *
 * #### Example:
 *
 *     // Mongoose does **not** convert the RegExp to uppercase.
 *     M.find({ email: /an example/ });
 *
 * @api public
 * @return {SchemaType} this
 */

SchemaString.prototype.uppercase = function(shouldApply) {
  if (arguments.length > 0 && !shouldApply) {
    return this;
  }
  return this.set(v => {
    if (typeof v !== 'string') {
      v = this.cast(v);
    }
    if (v) {
      return v.toUpperCase();
    }
    return v;
  });
};

/**
 * Adds a trim [setter](https://mongoosejs.com/docs/api/schematype.html#SchemaType.prototype.set()).
 *
 * The string value will be [trimmed](https://masteringjs.io/tutorials/fundamentals/trim-string) when set.
 *
 * #### Example:
 *
 *     const s = new Schema({ name: { type: String, trim: true }});
 *     const M = db.model('M', s);
 *     const string = ' some name ';
 *     console.log(string.length); // 11
 *     const m = new M({ name: string });
 *     console.log(m.name.length); // 9
 *
 *     // Equivalent to `findOne({ name: string.trim() })`
 *     M.findOne({ name: string });
 *
 * Note that `trim` does **not** affect regular expression queries:
 *
 * #### Example:
 *
 *     // Mongoose does **not** trim whitespace from the RegExp.
 *     M.find({ name: / some name / });
 *
 * @api public
 * @return {SchemaType} this
 */

SchemaString.prototype.trim = function(shouldTrim) {
  if (arguments.length > 0 && !shouldTrim) {
    return this;
  }
  return this.set(v => {
    if (typeof v !== 'string') {
      v = this.cast(v);
    }
    if (v) {
      return v.trim();
    }
    return v;
  });
};

/**
 * Sets a minimum length validator.
 *
 * #### Example:
 *
 *     const schema = new Schema({ postalCode: { type: String, minlength: 5 })
 *     const Address = db.model('Address', schema)
 *     const address = new Address({ postalCode: '9512' })
 *     address.save(function (err) {
 *       console.error(err) // validator error
 *       address.postalCode = '95125';
 *       address.save() // success
 *     })
 *
 *     // custom error messages
 *     // We can also use the special {MINLENGTH} token which will be replaced with the minimum allowed length
 *     const minlength = [5, 'The value of path `{PATH}` (`{VALUE}`) is shorter than the minimum allowed length ({MINLENGTH}).'];
 *     const schema = new Schema({ postalCode: { type: String, minlength: minlength })
 *     const Address = mongoose.model('Address', schema);
 *     const address = new Address({ postalCode: '9512' });
 *     address.validate(function (err) {
 *       console.log(String(err)) // ValidationError: The value of path `postalCode` (`9512`) is shorter than the minimum length (5).
 *     })
 *
 * @param {Number} value minimum string length
 * @param {String} [message] optional custom error message
 * @return {SchemaType} this
 * @see Customized Error Messages https://mongoosejs.com/docs/api/error.html#Error.messages
 * @api public
 */

SchemaString.prototype.minlength = function(value, message) {
  if (this.minlengthValidator) {
    this.validators = this.validators.filter(function(v) {
      return v.validator !== this.minlengthValidator;
    }, this);
  }

  if (value !== null && value !== undefined) {
    let msg = message || MongooseError.messages.String.minlength;
    msg = msg.replace(/{MINLENGTH}/, value);
    this.validators.push({
      validator: this.minlengthValidator = function(v) {
        return v === null || v.length >= value;
      },
      message: msg,
      type: 'minlength',
      minlength: value
    });
  }

  return this;
};

SchemaString.prototype.minLength = SchemaString.prototype.minlength;

/**
 * Sets a maximum length validator.
 *
 * #### Example:
 *
 *     const schema = new Schema({ postalCode: { type: String, maxlength: 9 })
 *     const Address = db.model('Address', schema)
 *     const address = new Address({ postalCode: '9512512345' })
 *     address.save(function (err) {
 *       console.error(err) // validator error
 *       address.postalCode = '95125';
 *       address.save() // success
 *     })
 *
 *     // custom error messages
 *     // We can also use the special {MAXLENGTH} token which will be replaced with the maximum allowed length
 *     const maxlength = [9, 'The value of path `{PATH}` (`{VALUE}`) exceeds the maximum allowed length ({MAXLENGTH}).'];
 *     const schema = new Schema({ postalCode: { type: String, maxlength: maxlength })
 *     const Address = mongoose.model('Address', schema);
 *     const address = new Address({ postalCode: '9512512345' });
 *     address.validate(function (err) {
 *       console.log(String(err)) // ValidationError: The value of path `postalCode` (`9512512345`) exceeds the maximum allowed length (9).
 *     })
 *
 * @param {Number} value maximum string length
 * @param {String} [message] optional custom error message
 * @return {SchemaType} this
 * @see Customized Error Messages https://mongoosejs.com/docs/api/error.html#Error.messages
 * @api public
 */

SchemaString.prototype.maxlength = function(value, message) {
  if (this.maxlengthValidator) {
    this.validators = this.validators.filter(function(v) {
      return v.validator !== this.maxlengthValidator;
    }, this);
  }

  if (value !== null && value !== undefined) {
    let msg = message || MongooseError.messages.String.maxlength;
    msg = msg.replace(/{MAXLENGTH}/, value);
    this.validators.push({
      validator: this.maxlengthValidator = function(v) {
        return v === null || v.length <= value;
      },
      message: msg,
      type: 'maxlength',
      maxlength: value
    });
  }

  return this;
};

SchemaString.prototype.maxLength = SchemaString.prototype.maxlength;

/**
 * Sets a regexp validator.
 *
 * Any value that does not pass `regExp`.test(val) will fail validation.
 *
 * #### Example:
 *
 *     const s = new Schema({ name: { type: String, match: /^a/ }})
 *     const M = db.model('M', s)
 *     const m = new M({ name: 'I am invalid' })
 *     m.validate(function (err) {
 *       console.error(String(err)) // "ValidationError: Path `name` is invalid (I am invalid)."
 *       m.name = 'apples'
 *       m.validate(function (err) {
 *         assert.ok(err) // success
 *       })
 *     })
 *
 *     // using a custom error message
 *     const match = [ /\.html$/, "That file doesn't end in .html ({VALUE})" ];
 *     const s = new Schema({ file: { type: String, match: match }})
 *     const M = db.model('M', s);
 *     const m = new M({ file: 'invalid' });
 *     m.validate(function (err) {
 *       console.log(String(err)) // "ValidationError: That file doesn't end in .html (invalid)"
 *     })
 *
 * Empty strings, `undefined`, and `null` values always pass the match validator. If you require these values, enable the `required` validator also.
 *
 *     const s = new Schema({ name: { type: String, match: /^a/, required: true }})
 *
 * @param {RegExp} regExp regular expression to test against
 * @param {String} [message] optional custom error message
 * @return {SchemaType} this
 * @see Customized Error Messages https://mongoosejs.com/docs/api/error.html#Error.messages
 * @api public
 */

SchemaString.prototype.match = function match(regExp, message) {
  // yes, we allow multiple match validators

  const msg = message || MongooseError.messages.String.match;

  const matchValidator = function(v) {
    if (!regExp) {
      return false;
    }

    // In case RegExp happens to have `/g` flag set, we need to reset the
    // `lastIndex`, otherwise `match` will intermittently fail.
    regExp.lastIndex = 0;

    const ret = ((v != null && v !== '')
      ? regExp.test(v)
      : true);
    return ret;
  };

  this.validators.push({
    validator: matchValidator,
    message: msg,
    type: 'regexp',
    regexp: regExp
  });
  return this;
};

/**
 * Check if the given value satisfies the `required` validator. The value is
 * considered valid if it is a string (that is, not `null` or `undefined`) and
 * has positive length. The `required` validator **will** fail for empty
 * strings.
 *
 * @param {Any} value
 * @param {Document} doc
 * @return {Boolean}
 * @api public
 */

SchemaString.prototype.checkRequired = function checkRequired(value, doc) {
  if (typeof value === 'object' && SchemaType._isRef(this, value, doc, true)) {
    return value != null;
  }

  // `require('util').inherits()` does **not** copy static properties, and
  // plugins like mongoose-float use `inherits()` for pre-ES6.
  const _checkRequired = typeof this.constructor.checkRequired === 'function' ?
    this.constructor.checkRequired() :
    SchemaString.checkRequired();

  return _checkRequired(value);
};

/**
 * Casts to String
 *
 * @api private
 */

SchemaString.prototype.cast = function(value, doc, init) {
  if (typeof value !== 'string' && SchemaType._isRef(this, value, doc, init)) {
    return this._castRef(value, doc, init);
  }

  let castString;
  if (typeof this._castFunction === 'function') {
    castString = this._castFunction;
  } else if (typeof this.constructor.cast === 'function') {
    castString = this.constructor.cast();
  } else {
    castString = SchemaString.cast();
  }

  try {
    return castString(value);
  } catch (error) {
    throw new CastError('string', value, this.path, null, this);
  }
};

/*!
 * ignore
 */

function handleSingle(val, context) {
  return this.castForQuery(null, val, context);
}

/*!
 * ignore
 */

function handleArray(val, context) {
  const _this = this;
  if (!Array.isArray(val)) {
    return [this.castForQuery(null, val, context)];
  }
  return val.map(function(m) {
    return _this.castForQuery(null, m, context);
  });
}

/*!
 * ignore
 */

function handleSingleNoSetters(val) {
  if (val == null) {
    return this._castNullish(val);
  }

  return this.cast(val, this);
}

const $conditionalHandlers = {
  ...SchemaType.prototype.$conditionalHandlers,
  $all: handleArray,
  $gt: handleSingle,
  $gte: handleSingle,
  $lt: handleSingle,
  $lte: handleSingle,
  $options: handleSingleNoSetters,
  $regex: function handle$regex(val) {
    if (Object.prototype.toString.call(val) === '[object RegExp]') {
      return val;
    }

    return handleSingleNoSetters.call(this, val);
  },
  $not: handleSingle
};

Object.defineProperty(SchemaString.prototype, '$conditionalHandlers', {
  configurable: false,
  enumerable: false,
  writable: false,
  value: Object.freeze($conditionalHandlers)
});

/**
 * Casts contents for queries.
 *
 * @param {String} $conditional
 * @param {any} [val]
 * @api private
 */

SchemaString.prototype.castForQuery = function($conditional, val, context) {
  let handler;
  if ($conditional != null) {
    handler = this.$conditionalHandlers[$conditional];
    if (!handler) {
      throw new Error('Can\'t use ' + $conditional + ' with String.');
    }
    return handler.call(this, val, context);
  }

  if (Object.prototype.toString.call(val) === '[object RegExp]' || isBsonType(val, 'BSONRegExp')) {
    return val;
  }

  try {
    return this.applySetters(val, context);
  } catch (err) {
    if (err instanceof CastError && err.path === this.path && this.$fullPath != null) {
      err.path = this.$fullPath;
    }
    throw err;
  }
};

/*!
 * Module exports.
 */

module.exports = SchemaString;
