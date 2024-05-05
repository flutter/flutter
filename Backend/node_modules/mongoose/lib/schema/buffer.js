/*!
 * Module dependencies.
 */

'use strict';

const MongooseBuffer = require('../types/buffer');
const SchemaBufferOptions = require('../options/schemaBufferOptions');
const SchemaType = require('../schemaType');
const handleBitwiseOperator = require('./operators/bitwise');
const utils = require('../utils');

const Binary = MongooseBuffer.Binary;
const CastError = SchemaType.CastError;

/**
 * Buffer SchemaType constructor
 *
 * @param {String} key
 * @param {Object} options
 * @inherits SchemaType
 * @api public
 */

function SchemaBuffer(key, options) {
  SchemaType.call(this, key, options, 'Buffer');
}

/**
 * This schema type's name, to defend against minifiers that mangle
 * function names.
 *
 * @api public
 */
SchemaBuffer.schemaName = 'Buffer';

SchemaBuffer.defaultOptions = {};

/*!
 * Inherits from SchemaType.
 */
SchemaBuffer.prototype = Object.create(SchemaType.prototype);
SchemaBuffer.prototype.constructor = SchemaBuffer;
SchemaBuffer.prototype.OptionsConstructor = SchemaBufferOptions;

/*!
 * ignore
 */

SchemaBuffer._checkRequired = v => !!(v && v.length);

/**
 * Sets a default option for all Buffer instances.
 *
 * #### Example:
 *
 *     // Make all buffers have `required` of true by default.
 *     mongoose.Schema.Buffer.set('required', true);
 *
 *     const User = mongoose.model('User', new Schema({ test: Buffer }));
 *     new User({ }).validateSync().errors.test.message; // Path `test` is required.
 *
 * @param {String} option The option you'd like to set the value for
 * @param {Any} value value for option
 * @return {undefined}
 * @function set
 * @static
 * @api public
 */

SchemaBuffer.set = SchemaType.set;

SchemaBuffer.setters = [];

/**
 * Attaches a getter for all Buffer instances
 *
 * #### Example:
 *
 *     // Always convert to string when getting an ObjectId
 *     mongoose.Schema.Types.Buffer.get(v => v.toString('hex'));
 *
 *     const Model = mongoose.model('Test', new Schema({ buf: Buffer } }));
 *     typeof (new Model({ buf: Buffer.fromString('hello') }).buf); // 'string'
 *
 * @param {Function} getter
 * @return {this}
 * @function get
 * @static
 * @api public
 */

SchemaBuffer.get = SchemaType.get;

/**
 * Override the function the required validator uses to check whether a string
 * passes the `required` check.
 *
 * #### Example:
 *
 *     // Allow empty strings to pass `required` check
 *     mongoose.Schema.Types.String.checkRequired(v => v != null);
 *
 *     const M = mongoose.model({ buf: { type: Buffer, required: true } });
 *     new M({ buf: Buffer.from('') }).validateSync(); // validation passes!
 *
 * @param {Function} fn
 * @return {Function}
 * @function checkRequired
 * @static
 * @api public
 */

SchemaBuffer.checkRequired = SchemaType.checkRequired;

/**
 * Check if the given value satisfies a required validator. To satisfy a
 * required validator, a buffer must not be null or undefined and have
 * non-zero length.
 *
 * @param {Any} value
 * @param {Document} doc
 * @return {Boolean}
 * @api public
 */

SchemaBuffer.prototype.checkRequired = function(value, doc) {
  if (SchemaType._isRef(this, value, doc, true)) {
    return !!value;
  }
  return this.constructor._checkRequired(value);
};

/**
 * Casts contents
 *
 * @param {Object} value
 * @param {Document} doc document that triggers the casting
 * @param {Boolean} init
 * @api private
 */

SchemaBuffer.prototype.cast = function(value, doc, init) {
  let ret;
  if (SchemaType._isRef(this, value, doc, init)) {
    if (value && value.isMongooseBuffer) {
      return value;
    }

    if (Buffer.isBuffer(value)) {
      if (!value || !value.isMongooseBuffer) {
        value = new MongooseBuffer(value, [this.path, doc]);
        if (this.options.subtype != null) {
          value._subtype = this.options.subtype;
        }
      }
      return value;
    }

    if (value instanceof Binary) {
      ret = new MongooseBuffer(value.value(true), [this.path, doc]);
      if (typeof value.sub_type !== 'number') {
        throw new CastError('Buffer', value, this.path, null, this);
      }
      ret._subtype = value.sub_type;
      return ret;
    }

    if (value == null || utils.isNonBuiltinObject(value)) {
      return this._castRef(value, doc, init);
    }
  }

  // documents
  if (value && value._id) {
    value = value._id;
  }

  if (value && value.isMongooseBuffer) {
    return value;
  }

  if (Buffer.isBuffer(value)) {
    if (!value || !value.isMongooseBuffer) {
      value = new MongooseBuffer(value, [this.path, doc]);
      if (this.options.subtype != null) {
        value._subtype = this.options.subtype;
      }
    }
    return value;
  }

  if (value instanceof Binary) {
    ret = new MongooseBuffer(value.value(true), [this.path, doc]);
    if (typeof value.sub_type !== 'number') {
      throw new CastError('Buffer', value, this.path, null, this);
    }
    ret._subtype = value.sub_type;
    return ret;
  }

  if (value === null) {
    return value;
  }


  const type = typeof value;
  if (
    type === 'string' || type === 'number' || Array.isArray(value) ||
    (type === 'object' && value.type === 'Buffer' && Array.isArray(value.data)) // gh-6863
  ) {
    if (type === 'number') {
      value = [value];
    }
    ret = new MongooseBuffer(value, [this.path, doc]);
    if (this.options.subtype != null) {
      ret._subtype = this.options.subtype;
    }
    return ret;
  }

  throw new CastError('Buffer', value, this.path, null, this);
};

/**
 * Sets the default [subtype](https://studio3t.com/whats-new/best-practices-uuid-mongodb/)
 * for this buffer. You can find a [list of allowed subtypes here](https://api.mongodb.com/python/current/api/bson/binary.html).
 *
 * #### Example:
 *
 *     const s = new Schema({ uuid: { type: Buffer, subtype: 4 });
 *     const M = db.model('M', s);
 *     const m = new M({ uuid: 'test string' });
 *     m.uuid._subtype; // 4
 *
 * @param {Number} subtype the default subtype
 * @return {SchemaType} this
 * @api public
 */

SchemaBuffer.prototype.subtype = function(subtype) {
  this.options.subtype = subtype;
  return this;
};

/*!
 * ignore
 */
function handleSingle(val, context) {
  return this.castForQuery(null, val, context);
}

SchemaBuffer.prototype.$conditionalHandlers = {
  ...SchemaType.prototype.$conditionalHandlers,
  $bitsAllClear: handleBitwiseOperator,
  $bitsAnyClear: handleBitwiseOperator,
  $bitsAllSet: handleBitwiseOperator,
  $bitsAnySet: handleBitwiseOperator,
  $gt: handleSingle,
  $gte: handleSingle,
  $lt: handleSingle,
  $lte: handleSingle
};

/**
 * Casts contents for queries.
 *
 * @param {String} $conditional
 * @param {any} [value]
 * @api private
 */

SchemaBuffer.prototype.castForQuery = function($conditional, val, context) {
  let handler;
  if ($conditional != null) {
    handler = this.$conditionalHandlers[$conditional];
    if (!handler) {
      throw new Error('Can\'t use ' + $conditional + ' with Buffer.');
    }
    return handler.call(this, val);
  }

  let casted;
  try {
    casted = this.applySetters(val, context);
  } catch (err) {
    if (err instanceof CastError && err.path === this.path && this.$fullPath != null) {
      err.path = this.$fullPath;
    }
    throw err;
  }
  return casted ? casted.toObject({ transform: false, virtuals: false }) : casted;
};

/*!
 * Module exports.
 */

module.exports = SchemaBuffer;
