/*!
 * Module dependencies.
 */

'use strict';

const SchemaType = require('../schemaType');
const CastError = SchemaType.CastError;
const castDecimal128 = require('../cast/decimal128');
const isBsonType = require('../helpers/isBsonType');

/**
 * Decimal128 SchemaType constructor.
 *
 * @param {String} key
 * @param {Object} options
 * @inherits SchemaType
 * @api public
 */

function SchemaDecimal128(key, options) {
  SchemaType.call(this, key, options, 'Decimal128');
}

/**
 * This schema type's name, to defend against minifiers that mangle
 * function names.
 *
 * @api public
 */
SchemaDecimal128.schemaName = 'Decimal128';

SchemaDecimal128.defaultOptions = {};

/*!
 * Inherits from SchemaType.
 */
SchemaDecimal128.prototype = Object.create(SchemaType.prototype);
SchemaDecimal128.prototype.constructor = SchemaDecimal128;

/*!
 * ignore
 */

SchemaDecimal128._cast = castDecimal128;

/**
 * Sets a default option for all Decimal128 instances.
 *
 * #### Example:
 *
 *     // Make all decimal 128s have `required` of true by default.
 *     mongoose.Schema.Decimal128.set('required', true);
 *
 *     const User = mongoose.model('User', new Schema({ test: mongoose.Decimal128 }));
 *     new User({ }).validateSync().errors.test.message; // Path `test` is required.
 *
 * @param {String} option The option you'd like to set the value for
 * @param {Any} value value for option
 * @return {undefined}
 * @function set
 * @static
 * @api public
 */

SchemaDecimal128.set = SchemaType.set;

SchemaDecimal128.setters = [];

/**
 * Attaches a getter for all Decimal128 instances
 *
 * #### Example:
 *
 *     // Automatically convert Decimal128s to Numbers
 *     mongoose.Schema.Decimal128.get(v => v == null ? v : Number(v));
 *
 * @param {Function} getter
 * @return {this}
 * @function get
 * @static
 * @api public
 */

SchemaDecimal128.get = SchemaType.get;

/**
 * Get/set the function used to cast arbitrary values to decimals.
 *
 * #### Example:
 *
 *     // Make Mongoose only refuse to cast numbers as decimal128
 *     const original = mongoose.Schema.Types.Decimal128.cast();
 *     mongoose.Decimal128.cast(v => {
 *       assert.ok(typeof v !== 'number');
 *       return original(v);
 *     });
 *
 *     // Or disable casting entirely
 *     mongoose.Decimal128.cast(false);
 *
 * @param {Function} [caster]
 * @return {Function}
 * @function get
 * @static
 * @api public
 */

SchemaDecimal128.cast = function cast(caster) {
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

SchemaDecimal128._defaultCaster = v => {
  if (v != null && !isBsonType(v, 'Decimal128')) {
    throw new Error();
  }
  return v;
};

/*!
 * ignore
 */

SchemaDecimal128._checkRequired = v => isBsonType(v, 'Decimal128');

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

SchemaDecimal128.checkRequired = SchemaType.checkRequired;

/**
 * Check if the given value satisfies a required validator.
 *
 * @param {Any} value
 * @param {Document} doc
 * @return {Boolean}
 * @api public
 */

SchemaDecimal128.prototype.checkRequired = function checkRequired(value, doc) {
  if (SchemaType._isRef(this, value, doc, true)) {
    return !!value;
  }

  // `require('util').inherits()` does **not** copy static properties, and
  // plugins like mongoose-float use `inherits()` for pre-ES6.
  const _checkRequired = typeof this.constructor.checkRequired === 'function' ?
    this.constructor.checkRequired() :
    SchemaDecimal128.checkRequired();

  return _checkRequired(value);
};

/**
 * Casts to Decimal128
 *
 * @param {Object} value
 * @param {Object} doc
 * @param {Boolean} init whether this is an initialization cast
 * @api private
 */

SchemaDecimal128.prototype.cast = function(value, doc, init) {
  if (SchemaType._isRef(this, value, doc, init)) {
    if (isBsonType(value, 'Decimal128')) {
      return value;
    }

    return this._castRef(value, doc, init);
  }

  let castDecimal128;
  if (typeof this._castFunction === 'function') {
    castDecimal128 = this._castFunction;
  } else if (typeof this.constructor.cast === 'function') {
    castDecimal128 = this.constructor.cast();
  } else {
    castDecimal128 = SchemaDecimal128.cast();
  }

  try {
    return castDecimal128(value);
  } catch (error) {
    throw new CastError('Decimal128', value, this.path, error, this);
  }
};

/*!
 * ignore
 */

function handleSingle(val) {
  return this.cast(val);
}

SchemaDecimal128.prototype.$conditionalHandlers = {
  ...SchemaType.prototype.$conditionalHandlers,
  $gt: handleSingle,
  $gte: handleSingle,
  $lt: handleSingle,
  $lte: handleSingle
};

/*!
 * Module exports.
 */

module.exports = SchemaDecimal128;
