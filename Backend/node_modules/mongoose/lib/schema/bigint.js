'use strict';

/*!
 * Module dependencies.
 */

const CastError = require('../error/cast');
const SchemaType = require('../schemaType');
const castBigInt = require('../cast/bigint');

/**
 * BigInt SchemaType constructor.
 *
 * @param {String} path
 * @param {Object} options
 * @inherits SchemaType
 * @api public
 */

function SchemaBigInt(path, options) {
  SchemaType.call(this, path, options, 'BigInt');
}

/**
 * This schema type's name, to defend against minifiers that mangle
 * function names.
 *
 * @api public
 */
SchemaBigInt.schemaName = 'BigInt';

SchemaBigInt.defaultOptions = {};

/*!
 * Inherits from SchemaType.
 */
SchemaBigInt.prototype = Object.create(SchemaType.prototype);
SchemaBigInt.prototype.constructor = SchemaBigInt;

/*!
 * ignore
 */

SchemaBigInt._cast = castBigInt;

/**
 * Sets a default option for all BigInt instances.
 *
 * #### Example:
 *
 *     // Make all bigints required by default
 *     mongoose.Schema.BigInt.set('required', true);
 *
 * @param {String} option The option you'd like to set the value for
 * @param {Any} value value for option
 * @return {undefined}
 * @function set
 * @static
 * @api public
 */

SchemaBigInt.set = SchemaType.set;

SchemaBigInt.setters = [];

/**
 * Attaches a getter for all BigInt instances
 *
 * #### Example:
 *
 *     // Convert bigints to numbers
 *     mongoose.Schema.BigInt.get(v => v == null ? v : Number(v));
 *
 * @param {Function} getter
 * @return {this}
 * @function get
 * @static
 * @api public
 */

SchemaBigInt.get = SchemaType.get;

/**
 * Get/set the function used to cast arbitrary values to booleans.
 *
 * #### Example:
 *
 *     // Make Mongoose cast empty string '' to false.
 *     const original = mongoose.Schema.BigInt.cast();
 *     mongoose.Schema.BigInt.cast(v => {
 *       if (v === '') {
 *         return false;
 *       }
 *       return original(v);
 *     });
 *
 *     // Or disable casting entirely
 *     mongoose.Schema.BigInt.cast(false);
 *
 * @param {Function} caster
 * @return {Function}
 * @function get
 * @static
 * @api public
 */

SchemaBigInt.cast = function cast(caster) {
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

SchemaBigInt._checkRequired = v => v != null;

/**
 * Override the function the required validator uses to check whether a value
 * passes the `required` check.
 *
 * @param {Function} fn
 * @return {Function}
 * @function checkRequired
 * @static
 * @api public
 */

SchemaBigInt.checkRequired = SchemaType.checkRequired;

/**
 * Check if the given value satisfies a required validator.
 *
 * @param {Any} value
 * @return {Boolean}
 * @api public
 */

SchemaBigInt.prototype.checkRequired = function(value) {
  return this.constructor._checkRequired(value);
};

/**
 * Casts to bigint
 *
 * @param {Object} value
 * @param {Object} model this value is optional
 * @api private
 */

SchemaBigInt.prototype.cast = function(value) {
  let castBigInt;
  if (typeof this._castFunction === 'function') {
    castBigInt = this._castFunction;
  } else if (typeof this.constructor.cast === 'function') {
    castBigInt = this.constructor.cast();
  } else {
    castBigInt = SchemaBigInt.cast();
  }

  try {
    return castBigInt(value);
  } catch (error) {
    throw new CastError('BigInt', value, this.path, error, this);
  }
};

/*!
 * ignore
 */

SchemaBigInt.$conditionalHandlers = {
  ...SchemaType.prototype.$conditionalHandlers,
  $gt: handleSingle,
  $gte: handleSingle,
  $lt: handleSingle,
  $lte: handleSingle
};

/*!
 * ignore
 */

function handleSingle(val, context) {
  return this.castForQuery(null, val, context);
}

/**
 * Casts contents for queries.
 *
 * @param {String} $conditional
 * @param {any} val
 * @api private
 */

SchemaBigInt.prototype.castForQuery = function($conditional, val, context) {
  let handler;
  if ($conditional != null) {
    handler = SchemaBigInt.$conditionalHandlers[$conditional];

    if (handler) {
      return handler.call(this, val);
    }

    return this.applySetters(null, val, context);
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

/**
 *
 * @api private
 */

SchemaBigInt.prototype._castNullish = function _castNullish(v) {
  if (typeof v === 'undefined') {
    return v;
  }
  const castBigInt = typeof this.constructor.cast === 'function' ?
    this.constructor.cast() :
    SchemaBigInt.cast();
  if (castBigInt == null) {
    return v;
  }
  return v;
};

/*!
 * Module exports.
 */

module.exports = SchemaBigInt;
