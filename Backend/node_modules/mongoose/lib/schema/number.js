'use strict';

/*!
 * Module requirements.
 */

const MongooseError = require('../error/index');
const SchemaNumberOptions = require('../options/schemaNumberOptions');
const SchemaType = require('../schemaType');
const castNumber = require('../cast/number');
const handleBitwiseOperator = require('./operators/bitwise');
const utils = require('../utils');

const CastError = SchemaType.CastError;

/**
 * Number SchemaType constructor.
 *
 * @param {String} key
 * @param {Object} options
 * @inherits SchemaType
 * @api public
 */

function SchemaNumber(key, options) {
  SchemaType.call(this, key, options, 'Number');
}

/**
 * Attaches a getter for all Number instances.
 *
 * #### Example:
 *
 *     // Make all numbers round down
 *     mongoose.Number.get(function(v) { return Math.floor(v); });
 *
 *     const Model = mongoose.model('Test', new Schema({ test: Number }));
 *     new Model({ test: 3.14 }).test; // 3
 *
 * @param {Function} getter
 * @return {this}
 * @function get
 * @static
 * @api public
 */

SchemaNumber.get = SchemaType.get;

/**
 * Sets a default option for all Number instances.
 *
 * #### Example:
 *
 *     // Make all numbers have option `min` equal to 0.
 *     mongoose.Schema.Number.set('min', 0);
 *
 *     const Order = mongoose.model('Order', new Schema({ amount: Number }));
 *     new Order({ amount: -10 }).validateSync().errors.amount.message; // Path `amount` must be larger than 0.
 *
 * @param {String} option The option you'd like to set the value for
 * @param {Any} value value for option
 * @return {undefined}
 * @function set
 * @static
 * @api public
 */

SchemaNumber.set = SchemaType.set;

SchemaNumber.setters = [];

/*!
 * ignore
 */

SchemaNumber._cast = castNumber;

/**
 * Get/set the function used to cast arbitrary values to numbers.
 *
 * #### Example:
 *
 *     // Make Mongoose cast empty strings '' to 0 for paths declared as numbers
 *     const original = mongoose.Number.cast();
 *     mongoose.Number.cast(v => {
 *       if (v === '') { return 0; }
 *       return original(v);
 *     });
 *
 *     // Or disable casting entirely
 *     mongoose.Number.cast(false);
 *
 * @param {Function} caster
 * @return {Function}
 * @function get
 * @static
 * @api public
 */

SchemaNumber.cast = function cast(caster) {
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

SchemaNumber._defaultCaster = v => {
  if (typeof v !== 'number') {
    throw new Error();
  }
  return v;
};

/**
 * This schema type's name, to defend against minifiers that mangle
 * function names.
 *
 * @api public
 */
SchemaNumber.schemaName = 'Number';

SchemaNumber.defaultOptions = {};

/*!
 * Inherits from SchemaType.
 */
SchemaNumber.prototype = Object.create(SchemaType.prototype);
SchemaNumber.prototype.constructor = SchemaNumber;
SchemaNumber.prototype.OptionsConstructor = SchemaNumberOptions;

/*!
 * ignore
 */

SchemaNumber._checkRequired = v => typeof v === 'number' || v instanceof Number;

/**
 * Override the function the required validator uses to check whether a string
 * passes the `required` check.
 *
 * @param {Function} fn
 * @return {Function}
 * @function checkRequired
 * @static
 * @api public
 */

SchemaNumber.checkRequired = SchemaType.checkRequired;

/**
 * Check if the given value satisfies a required validator.
 *
 * @param {Any} value
 * @param {Document} doc
 * @return {Boolean}
 * @api public
 */

SchemaNumber.prototype.checkRequired = function checkRequired(value, doc) {
  if (typeof value === 'object' && SchemaType._isRef(this, value, doc, true)) {
    return value != null;
  }

  // `require('util').inherits()` does **not** copy static properties, and
  // plugins like mongoose-float use `inherits()` for pre-ES6.
  const _checkRequired = typeof this.constructor.checkRequired === 'function' ?
    this.constructor.checkRequired() :
    SchemaNumber.checkRequired();

  return _checkRequired(value);
};

/**
 * Sets a minimum number validator.
 *
 * #### Example:
 *
 *     const s = new Schema({ n: { type: Number, min: 10 })
 *     const M = db.model('M', s)
 *     const m = new M({ n: 9 })
 *     m.save(function (err) {
 *       console.error(err) // validator error
 *       m.n = 10;
 *       m.save() // success
 *     })
 *
 *     // custom error messages
 *     // We can also use the special {MIN} token which will be replaced with the invalid value
 *     const min = [10, 'The value of path `{PATH}` ({VALUE}) is beneath the limit ({MIN}).'];
 *     const schema = new Schema({ n: { type: Number, min: min })
 *     const M = mongoose.model('Measurement', schema);
 *     const s= new M({ n: 4 });
 *     s.validate(function (err) {
 *       console.log(String(err)) // ValidationError: The value of path `n` (4) is beneath the limit (10).
 *     })
 *
 * @param {Number} value minimum number
 * @param {String} [message] optional custom error message
 * @return {SchemaType} this
 * @see Customized Error Messages https://mongoosejs.com/docs/api/error.html#Error.messages
 * @api public
 */

SchemaNumber.prototype.min = function(value, message) {
  if (this.minValidator) {
    this.validators = this.validators.filter(function(v) {
      return v.validator !== this.minValidator;
    }, this);
  }

  if (value !== null && value !== undefined) {
    let msg = message || MongooseError.messages.Number.min;
    msg = msg.replace(/{MIN}/, value);
    this.validators.push({
      validator: this.minValidator = function(v) {
        return v == null || v >= value;
      },
      message: msg,
      type: 'min',
      min: value
    });
  }

  return this;
};

/**
 * Sets a maximum number validator.
 *
 * #### Example:
 *
 *     const s = new Schema({ n: { type: Number, max: 10 })
 *     const M = db.model('M', s)
 *     const m = new M({ n: 11 })
 *     m.save(function (err) {
 *       console.error(err) // validator error
 *       m.n = 10;
 *       m.save() // success
 *     })
 *
 *     // custom error messages
 *     // We can also use the special {MAX} token which will be replaced with the invalid value
 *     const max = [10, 'The value of path `{PATH}` ({VALUE}) exceeds the limit ({MAX}).'];
 *     const schema = new Schema({ n: { type: Number, max: max })
 *     const M = mongoose.model('Measurement', schema);
 *     const s= new M({ n: 4 });
 *     s.validate(function (err) {
 *       console.log(String(err)) // ValidationError: The value of path `n` (4) exceeds the limit (10).
 *     })
 *
 * @param {Number} maximum number
 * @param {String} [message] optional custom error message
 * @return {SchemaType} this
 * @see Customized Error Messages https://mongoosejs.com/docs/api/error.html#Error.messages
 * @api public
 */

SchemaNumber.prototype.max = function(value, message) {
  if (this.maxValidator) {
    this.validators = this.validators.filter(function(v) {
      return v.validator !== this.maxValidator;
    }, this);
  }

  if (value !== null && value !== undefined) {
    let msg = message || MongooseError.messages.Number.max;
    msg = msg.replace(/{MAX}/, value);
    this.validators.push({
      validator: this.maxValidator = function(v) {
        return v == null || v <= value;
      },
      message: msg,
      type: 'max',
      max: value
    });
  }

  return this;
};

/**
 * Sets a enum validator
 *
 * #### Example:
 *
 *     const s = new Schema({ n: { type: Number, enum: [1, 2, 3] });
 *     const M = db.model('M', s);
 *
 *     const m = new M({ n: 4 });
 *     await m.save(); // throws validation error
 *
 *     m.n = 3;
 *     await m.save(); // succeeds
 *
 * @param {Array} values allowed values
 * @param {String} [message] optional custom error message
 * @return {SchemaType} this
 * @see Customized Error Messages https://mongoosejs.com/docs/api/error.html#Error.messages
 * @api public
 */

SchemaNumber.prototype.enum = function(values, message) {
  if (this.enumValidator) {
    this.validators = this.validators.filter(function(v) {
      return v.validator !== this.enumValidator;
    }, this);
  }


  if (!Array.isArray(values)) {
    const isObjectSyntax = utils.isPOJO(values) && values.values != null;
    if (isObjectSyntax) {
      message = values.message;
      values = values.values;
    } else if (typeof values === 'number') {
      values = Array.prototype.slice.call(arguments);
      message = null;
    }

    if (utils.isPOJO(values)) {
      values = Object.values(values);
    }
    message = message || MongooseError.messages.Number.enum;
  }

  message = message == null ? MongooseError.messages.Number.enum : message;

  this.enumValidator = v => v == null || values.indexOf(v) !== -1;
  this.validators.push({
    validator: this.enumValidator,
    message: message,
    type: 'enum',
    enumValues: values
  });

  return this;
};

/**
 * Casts to number
 *
 * @param {Object} value value to cast
 * @param {Document} doc document that triggers the casting
 * @param {Boolean} init
 * @api private
 */

SchemaNumber.prototype.cast = function(value, doc, init) {
  if (typeof value !== 'number' && SchemaType._isRef(this, value, doc, init)) {
    if (value == null || utils.isNonBuiltinObject(value)) {
      return this._castRef(value, doc, init);
    }
  }

  const val = value && typeof value._id !== 'undefined' ?
    value._id : // documents
    value;

  let castNumber;
  if (typeof this._castFunction === 'function') {
    castNumber = this._castFunction;
  } else if (typeof this.constructor.cast === 'function') {
    castNumber = this.constructor.cast();
  } else {
    castNumber = SchemaNumber.cast();
  }

  try {
    return castNumber(val);
  } catch (err) {
    throw new CastError('Number', val, this.path, err, this);
  }
};

/*!
 * ignore
 */

function handleSingle(val) {
  return this.cast(val);
}

function handleArray(val) {
  const _this = this;
  if (!Array.isArray(val)) {
    return [this.cast(val)];
  }
  return val.map(function(m) {
    return _this.cast(m);
  });
}

SchemaNumber.prototype.$conditionalHandlers = {
  ...SchemaType.prototype.$conditionalHandlers,
  $bitsAllClear: handleBitwiseOperator,
  $bitsAnyClear: handleBitwiseOperator,
  $bitsAllSet: handleBitwiseOperator,
  $bitsAnySet: handleBitwiseOperator,
  $gt: handleSingle,
  $gte: handleSingle,
  $lt: handleSingle,
  $lte: handleSingle,
  $mod: handleArray
};

/**
 * Casts contents for queries.
 *
 * @param {String} $conditional
 * @param {any} [value]
 * @api private
 */

SchemaNumber.prototype.castForQuery = function($conditional, val, context) {
  let handler;
  if ($conditional != null) {
    handler = this.$conditionalHandlers[$conditional];
    if (!handler) {
      throw new CastError('number', val, this.path, null, this);
    }
    return handler.call(this, val, context);
  }

  try {
    val = this.applySetters(val, context);
  } catch (err) {
    if (err instanceof CastError && err.path === this.path && this.$fullPath != null) {
      err.path = this.$fullPath;
    }
    throw err;
  }

  return val;
};

/*!
 * Module exports.
 */

module.exports = SchemaNumber;
