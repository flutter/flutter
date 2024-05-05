/*!
 * Module dependencies.
 */

'use strict';

const SchemaObjectIdOptions = require('../options/schemaObjectIdOptions');
const SchemaType = require('../schemaType');
const castObjectId = require('../cast/objectid');
const getConstructorName = require('../helpers/getConstructorName');
const oid = require('../types/objectid');
const isBsonType = require('../helpers/isBsonType');
const utils = require('../utils');

const CastError = SchemaType.CastError;
let Document;

/**
 * ObjectId SchemaType constructor.
 *
 * @param {String} key
 * @param {Object} options
 * @inherits SchemaType
 * @api public
 */

function SchemaObjectId(key, options) {
  const isKeyHexStr = typeof key === 'string' && key.length === 24 && /^[a-f0-9]+$/i.test(key);
  const suppressWarning = options && options.suppressWarning;
  if ((isKeyHexStr || typeof key === 'undefined') && !suppressWarning) {
    utils.warn('mongoose: To create a new ObjectId please try ' +
      '`Mongoose.Types.ObjectId` instead of using ' +
      '`Mongoose.Schema.ObjectId`. Set the `suppressWarning` option if ' +
      'you\'re trying to create a hex char path in your schema.');
  }
  SchemaType.call(this, key, options, 'ObjectId');
}

/**
 * This schema type's name, to defend against minifiers that mangle
 * function names.
 *
 * @api public
 */
SchemaObjectId.schemaName = 'ObjectId';

SchemaObjectId.defaultOptions = {};

/*!
 * Inherits from SchemaType.
 */
SchemaObjectId.prototype = Object.create(SchemaType.prototype);
SchemaObjectId.prototype.constructor = SchemaObjectId;
SchemaObjectId.prototype.OptionsConstructor = SchemaObjectIdOptions;

/**
 * Attaches a getter for all ObjectId instances
 *
 * #### Example:
 *
 *     // Always convert to string when getting an ObjectId
 *     mongoose.ObjectId.get(v => v.toString());
 *
 *     const Model = mongoose.model('Test', new Schema({}));
 *     typeof (new Model({})._id); // 'string'
 *
 * @param {Function} getter
 * @return {this}
 * @function get
 * @static
 * @api public
 */

SchemaObjectId.get = SchemaType.get;

/**
 * Sets a default option for all ObjectId instances.
 *
 * #### Example:
 *
 *     // Make all object ids have option `required` equal to true.
 *     mongoose.Schema.ObjectId.set('required', true);
 *
 *     const Order = mongoose.model('Order', new Schema({ userId: ObjectId }));
 *     new Order({ }).validateSync().errors.userId.message; // Path `userId` is required.
 *
 * @param {String} option The option you'd like to set the value for
 * @param {Any} value value for option
 * @return {undefined}
 * @function set
 * @static
 * @api public
 */

SchemaObjectId.set = SchemaType.set;

SchemaObjectId.setters = [];

/**
 * Adds an auto-generated ObjectId default if turnOn is true.
 * @param {Boolean} turnOn auto generated ObjectId defaults
 * @api public
 * @return {SchemaType} this
 */

SchemaObjectId.prototype.auto = function(turnOn) {
  if (turnOn) {
    this.default(defaultId);
    this.set(resetId);
  }

  return this;
};

/*!
 * ignore
 */

SchemaObjectId._checkRequired = v => isBsonType(v, 'ObjectId');

/*!
 * ignore
 */

SchemaObjectId._cast = castObjectId;

/**
 * Get/set the function used to cast arbitrary values to objectids.
 *
 * #### Example:
 *
 *     // Make Mongoose only try to cast length 24 strings. By default, any 12
 *     // char string is a valid ObjectId.
 *     const original = mongoose.ObjectId.cast();
 *     mongoose.ObjectId.cast(v => {
 *       assert.ok(typeof v !== 'string' || v.length === 24);
 *       return original(v);
 *     });
 *
 *     // Or disable casting entirely
 *     mongoose.ObjectId.cast(false);
 *
 * @param {Function} caster
 * @return {Function}
 * @function get
 * @static
 * @api public
 */

SchemaObjectId.cast = function cast(caster) {
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

SchemaObjectId._defaultCaster = v => {
  if (!(isBsonType(v, 'ObjectId'))) {
    throw new Error(v + ' is not an instance of ObjectId');
  }
  return v;
};

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

SchemaObjectId.checkRequired = SchemaType.checkRequired;

/**
 * Check if the given value satisfies a required validator.
 *
 * @param {Any} value
 * @param {Document} doc
 * @return {Boolean}
 * @api public
 */

SchemaObjectId.prototype.checkRequired = function checkRequired(value, doc) {
  if (SchemaType._isRef(this, value, doc, true)) {
    return !!value;
  }

  // `require('util').inherits()` does **not** copy static properties, and
  // plugins like mongoose-float use `inherits()` for pre-ES6.
  const _checkRequired = typeof this.constructor.checkRequired === 'function' ?
    this.constructor.checkRequired() :
    SchemaObjectId.checkRequired();

  return _checkRequired(value);
};

/**
 * Casts to ObjectId
 *
 * @param {Object} value
 * @param {Object} doc
 * @param {Boolean} init whether this is an initialization cast
 * @api private
 */

SchemaObjectId.prototype.cast = function(value, doc, init) {
  if (!(isBsonType(value, 'ObjectId')) && SchemaType._isRef(this, value, doc, init)) {
    // wait! we may need to cast this to a document
    if ((getConstructorName(value) || '').toLowerCase() === 'objectid') {
      return new oid(value.toHexString());
    }

    if (value == null || utils.isNonBuiltinObject(value)) {
      return this._castRef(value, doc, init);
    }
  }

  let castObjectId;
  if (typeof this._castFunction === 'function') {
    castObjectId = this._castFunction;
  } else if (typeof this.constructor.cast === 'function') {
    castObjectId = this.constructor.cast();
  } else {
    castObjectId = SchemaObjectId.cast();
  }

  try {
    return castObjectId(value);
  } catch (error) {
    throw new CastError('ObjectId', value, this.path, error, this);
  }
};

/*!
 * ignore
 */

function handleSingle(val) {
  return this.cast(val);
}

SchemaObjectId.prototype.$conditionalHandlers = {
  ...SchemaType.prototype.$conditionalHandlers,
  $gt: handleSingle,
  $gte: handleSingle,
  $lt: handleSingle,
  $lte: handleSingle
};

/*!
 * ignore
 */

function defaultId() {
  return new oid();
}

defaultId.$runBeforeSetters = true;

function resetId(v) {
  Document || (Document = require('../document'));

  if (this instanceof Document) {
    if (v === void 0) {
      const _v = new oid();
      return _v;
    }
  }

  return v;
}

/*!
 * Module exports.
 */

module.exports = SchemaObjectId;
