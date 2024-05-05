/*!
 * Module dependencies.
 */

'use strict';

const MongooseBuffer = require('../types/buffer');
const SchemaType = require('../schemaType');
const CastError = SchemaType.CastError;
const utils = require('../utils');
const handleBitwiseOperator = require('./operators/bitwise');

const UUID_FORMAT = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/i;
const Binary = MongooseBuffer.Binary;

/**
 * Helper function to convert the input hex-string to a buffer
 * @param {String} hex The hex string to convert
 * @returns {Buffer} The hex as buffer
 * @api private
 */

function hex2buffer(hex) {
  // use buffer built-in function to convert from hex-string to buffer
  const buff = hex != null && Buffer.from(hex, 'hex');
  return buff;
}

/**
 * Helper function to convert the buffer input to a string
 * @param {Buffer} buf The buffer to convert to a hex-string
 * @returns {String} The buffer as a hex-string
 * @api private
 */

function binary2hex(buf) {
  // use buffer built-in function to convert from buffer to hex-string
  const hex = buf != null && buf.toString('hex');
  return hex;
}

/**
 * Convert a String to Binary
 * @param {String} uuidStr The value to process
 * @returns {MongooseBuffer} The binary to store
 * @api private
 */

function stringToBinary(uuidStr) {
  // Protect against undefined & throwing err
  if (typeof uuidStr !== 'string') uuidStr = '';
  const hex = uuidStr.replace(/[{}-]/g, ''); // remove extra characters
  const bytes = hex2buffer(hex);
  const buff = new MongooseBuffer(bytes);
  buff._subtype = 4;

  return buff;
}

/**
 * Convert binary to a uuid string
 * @param {Buffer|Binary|String} uuidBin The value to process
 * @returns {String} The completed uuid-string
 * @api private
 */
function binaryToString(uuidBin) {
  // i(hasezoey) dont quite know why, but "uuidBin" may sometimes also be the already processed string
  let hex;
  if (typeof uuidBin !== 'string' && uuidBin != null) {
    hex = binary2hex(uuidBin);
    const uuidStr = hex.substring(0, 8) + '-' + hex.substring(8, 8 + 4) + '-' + hex.substring(12, 12 + 4) + '-' + hex.substring(16, 16 + 4) + '-' + hex.substring(20, 20 + 12);
    return uuidStr;
  }
  return uuidBin;
}

/**
 * UUIDv1 SchemaType constructor.
 *
 * @param {String} key
 * @param {Object} options
 * @inherits SchemaType
 * @api public
 */

function SchemaUUID(key, options) {
  SchemaType.call(this, key, options, 'UUID');
  this.getters.push(function(value) {
    // For populated
    if (value != null && value.$__ != null) {
      return value;
    }
    return binaryToString(value);
  });
}

/**
 * This schema type's name, to defend against minifiers that mangle
 * function names.
 *
 * @api public
 */
SchemaUUID.schemaName = 'UUID';

SchemaUUID.defaultOptions = {};

/*!
 * Inherits from SchemaType.
 */
SchemaUUID.prototype = Object.create(SchemaType.prototype);
SchemaUUID.prototype.constructor = SchemaUUID;

/*!
 * ignore
 */

SchemaUUID._cast = function(value) {
  if (value == null) {
    return value;
  }

  function newBuffer(initbuff) {
    const buff = new MongooseBuffer(initbuff);
    buff._subtype = 4;
    return buff;
  }

  if (typeof value === 'string') {
    if (UUID_FORMAT.test(value)) {
      return stringToBinary(value);
    } else {
      throw new CastError(SchemaUUID.schemaName, value, this.path);
    }
  }

  if (Buffer.isBuffer(value)) {
    return newBuffer(value);
  }

  if (value instanceof Binary) {
    return newBuffer(value.value(true));
  }

  // Re: gh-647 and gh-3030, we're ok with casting using `toString()`
  // **unless** its the default Object.toString, because "[object Object]"
  // doesn't really qualify as useful data
  if (value.toString && value.toString !== Object.prototype.toString) {
    if (UUID_FORMAT.test(value.toString())) {
      return stringToBinary(value.toString());
    }
  }

  throw new CastError(SchemaUUID.schemaName, value, this.path);
};

/**
 * Attaches a getter for all UUID instances.
 *
 * #### Example:
 *
 *     // Note that `v` is a string by default
 *     mongoose.Schema.UUID.get(v => v.toUpperCase());
 *
 *     const Model = mongoose.model('Test', new Schema({ test: 'UUID' }));
 *     new Model({ test: uuid.v4() }).test; // UUID with all uppercase
 *
 * @param {Function} getter
 * @return {this}
 * @function get
 * @static
 * @api public
 */

SchemaUUID.get = SchemaType.get;

/**
 * Sets a default option for all UUID instances.
 *
 * #### Example:
 *
 *     // Make all UUIDs have `required` of true by default.
 *     mongoose.Schema.UUID.set('required', true);
 *
 *     const User = mongoose.model('User', new Schema({ test: mongoose.UUID }));
 *     new User({ }).validateSync().errors.test.message; // Path `test` is required.
 *
 * @param {String} option The option you'd like to set the value for
 * @param {Any} value value for option
 * @return {undefined}
 * @function set
 * @static
 * @api public
 */

SchemaUUID.set = SchemaType.set;

SchemaUUID.setters = [];

/**
 * Get/set the function used to cast arbitrary values to UUIDs.
 *
 * #### Example:
 *
 *     // Make Mongoose refuse to cast UUIDs with 0 length
 *     const original = mongoose.Schema.Types.UUID.cast();
 *     mongoose.UUID.cast(v => {
 *       assert.ok(typeof v === "string" && v.length > 0);
 *       return original(v);
 *     });
 *
 *     // Or disable casting entirely
 *     mongoose.UUID.cast(false);
 *
 * @param {Function} [caster]
 * @return {Function}
 * @function get
 * @static
 * @api public
 */

SchemaUUID.cast = function cast(caster) {
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

SchemaUUID._checkRequired = v => v != null;

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

SchemaUUID.checkRequired = SchemaType.checkRequired;

/**
 * Check if the given value satisfies a required validator.
 *
 * @param {Any} value
 * @return {Boolean}
 * @api public
 */

SchemaUUID.prototype.checkRequired = function checkRequired(value) {
  if (Buffer.isBuffer(value)) {
    value = binaryToString(value);
  }
  return value != null && UUID_FORMAT.test(value);
};

/**
 * Casts to UUID
 *
 * @param {Object} value
 * @param {Object} doc
 * @param {Boolean} init whether this is an initialization cast
 * @api private
 */

SchemaUUID.prototype.cast = function(value, doc, init) {
  if (utils.isNonBuiltinObject(value) &&
      SchemaType._isRef(this, value, doc, init)) {
    return this._castRef(value, doc, init);
  }

  let castFn;
  if (typeof this._castFunction === 'function') {
    castFn = this._castFunction;
  } else if (typeof this.constructor.cast === 'function') {
    castFn = this.constructor.cast();
  } else {
    castFn = SchemaUUID.cast();
  }

  try {
    return castFn(value);
  } catch (error) {
    throw new CastError(SchemaUUID.schemaName, value, this.path, error, this);
  }
};

/*!
 * ignore
 */

function handleSingle(val) {
  return this.cast(val);
}

/*!
 * ignore
 */

function handleArray(val) {
  return val.map((m) => {
    return this.cast(m);
  });
}

SchemaUUID.prototype.$conditionalHandlers = {
  ...SchemaType.prototype.$conditionalHandlers,
  $bitsAllClear: handleBitwiseOperator,
  $bitsAnyClear: handleBitwiseOperator,
  $bitsAllSet: handleBitwiseOperator,
  $bitsAnySet: handleBitwiseOperator,
  $all: handleArray,
  $gt: handleSingle,
  $gte: handleSingle,
  $in: handleArray,
  $lt: handleSingle,
  $lte: handleSingle,
  $ne: handleSingle,
  $nin: handleArray
};

/**
 * Casts contents for queries.
 *
 * @param {String} $conditional
 * @param {any} val
 * @api private
 */

SchemaUUID.prototype.castForQuery = function($conditional, val, context) {
  let handler;
  if ($conditional != null) {
    handler = this.$conditionalHandlers[$conditional];
    if (!handler)
      throw new Error('Can\'t use ' + $conditional + ' with UUID.');
    return handler.call(this, val, context);
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

module.exports = SchemaUUID;
