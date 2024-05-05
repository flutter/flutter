/*!
 * Module dependencies.
 */

'use strict';

const Binary = require('bson').Binary;
const utils = require('../utils');

/**
 * Mongoose Buffer constructor.
 *
 * Values always have to be passed to the constructor to initialize.
 *
 * @param {Buffer} value
 * @param {String} encode
 * @param {Number} offset
 * @api private
 * @inherits Buffer https://nodejs.org/api/buffer.html
 * @see https://bit.ly/f6CnZU
 */

function MongooseBuffer(value, encode, offset) {
  let val = value;
  if (value == null) {
    val = 0;
  }

  let encoding;
  let path;
  let doc;

  if (Array.isArray(encode)) {
    // internal casting
    path = encode[0];
    doc = encode[1];
  } else {
    encoding = encode;
  }

  let buf;
  if (typeof val === 'number' || val instanceof Number) {
    buf = Buffer.alloc(val);
  } else { // string, array or object { type: 'Buffer', data: [...] }
    buf = Buffer.from(val, encoding, offset);
  }
  utils.decorate(buf, MongooseBuffer.mixin);
  buf.isMongooseBuffer = true;

  // make sure these internal props don't show up in Object.keys()
  buf[MongooseBuffer.pathSymbol] = path;
  buf[parentSymbol] = doc;

  buf._subtype = 0;
  return buf;
}

const pathSymbol = Symbol.for('mongoose#Buffer#_path');
const parentSymbol = Symbol.for('mongoose#Buffer#_parent');
MongooseBuffer.pathSymbol = pathSymbol;

/*!
 * Inherit from Buffer.
 */

MongooseBuffer.mixin = {

  /**
   * Default subtype for the Binary representing this Buffer
   *
   * @api private
   * @property _subtype
   * @memberOf MongooseBuffer.mixin
   * @static
   */

  _subtype: undefined,

  /**
   * Marks this buffer as modified.
   *
   * @api private
   * @method _markModified
   * @memberOf MongooseBuffer.mixin
   * @static
   */

  _markModified: function() {
    const parent = this[parentSymbol];

    if (parent) {
      parent.markModified(this[MongooseBuffer.pathSymbol]);
    }
    return this;
  },

  /**
   * Writes the buffer.
   *
   * @api public
   * @method write
   * @memberOf MongooseBuffer.mixin
   * @static
   */

  write: function() {
    const written = Buffer.prototype.write.apply(this, arguments);

    if (written > 0) {
      this._markModified();
    }

    return written;
  },

  /**
   * Copies the buffer.
   *
   * #### Note:
   *
   * `Buffer#copy` does not mark `target` as modified so you must copy from a `MongooseBuffer` for it to work as expected. This is a work around since `copy` modifies the target, not this.
   *
   * @return {Number} The number of bytes copied.
   * @param {Buffer} target
   * @method copy
   * @memberOf MongooseBuffer.mixin
   * @static
   */

  copy: function(target) {
    const ret = Buffer.prototype.copy.apply(this, arguments);

    if (target && target.isMongooseBuffer) {
      target._markModified();
    }

    return ret;
  }
};

/*!
 * Compile other Buffer methods marking this buffer as modified.
 */

utils.each(
  [
    // node < 0.5
    'writeUInt8', 'writeUInt16', 'writeUInt32', 'writeInt8', 'writeInt16', 'writeInt32',
    'writeFloat', 'writeDouble', 'fill',
    'utf8Write', 'binaryWrite', 'asciiWrite', 'set',

    // node >= 0.5
    'writeUInt16LE', 'writeUInt16BE', 'writeUInt32LE', 'writeUInt32BE',
    'writeInt16LE', 'writeInt16BE', 'writeInt32LE', 'writeInt32BE', 'writeFloatLE', 'writeFloatBE', 'writeDoubleLE', 'writeDoubleBE']
  , function(method) {
    if (!Buffer.prototype[method]) {
      return;
    }
    MongooseBuffer.mixin[method] = function() {
      const ret = Buffer.prototype[method].apply(this, arguments);
      this._markModified();
      return ret;
    };
  });

/**
 * Converts this buffer to its Binary type representation.
 *
 * #### SubTypes:
 *
 *     const bson = require('bson')
 *     bson.BSON_BINARY_SUBTYPE_DEFAULT
 *     bson.BSON_BINARY_SUBTYPE_FUNCTION
 *     bson.BSON_BINARY_SUBTYPE_BYTE_ARRAY
 *     bson.BSON_BINARY_SUBTYPE_UUID
 *     bson.BSON_BINARY_SUBTYPE_MD5
 *     bson.BSON_BINARY_SUBTYPE_USER_DEFINED
 *     doc.buffer.toObject(bson.BSON_BINARY_SUBTYPE_USER_DEFINED);
 *
 * @see bsonspec https://bsonspec.org/#/specification
 * @param {Hex} [subtype]
 * @return {Binary}
 * @api public
 * @method toObject
 * @memberOf MongooseBuffer
 */

MongooseBuffer.mixin.toObject = function(options) {
  const subtype = typeof options === 'number'
    ? options
    : (this._subtype || 0);
  return new Binary(Buffer.from(this), subtype);
};

MongooseBuffer.mixin.$toObject = MongooseBuffer.mixin.toObject;

/**
 * Converts this buffer for storage in MongoDB, including subtype
 *
 * @return {Binary}
 * @api public
 * @method toBSON
 * @memberOf MongooseBuffer
 */

MongooseBuffer.mixin.toBSON = function() {
  return new Binary(this, this._subtype || 0);
};

/**
 * Determines if this buffer is equals to `other` buffer
 *
 * @param {Buffer} other
 * @return {Boolean}
 * @method equals
 * @memberOf MongooseBuffer
 */

MongooseBuffer.mixin.equals = function(other) {
  if (!Buffer.isBuffer(other)) {
    return false;
  }

  if (this.length !== other.length) {
    return false;
  }

  for (let i = 0; i < this.length; ++i) {
    if (this[i] !== other[i]) {
      return false;
    }
  }

  return true;
};

/**
 * Sets the subtype option and marks the buffer modified.
 *
 * #### SubTypes:
 *
 *     const bson = require('bson')
 *     bson.BSON_BINARY_SUBTYPE_DEFAULT
 *     bson.BSON_BINARY_SUBTYPE_FUNCTION
 *     bson.BSON_BINARY_SUBTYPE_BYTE_ARRAY
 *     bson.BSON_BINARY_SUBTYPE_UUID
 *     bson.BSON_BINARY_SUBTYPE_MD5
 *     bson.BSON_BINARY_SUBTYPE_USER_DEFINED
 *
 *     doc.buffer.subtype(bson.BSON_BINARY_SUBTYPE_UUID);
 *
 * @see bsonspec https://bsonspec.org/#/specification
 * @param {Hex} subtype
 * @api public
 * @method subtype
 * @memberOf MongooseBuffer
 */

MongooseBuffer.mixin.subtype = function(subtype) {
  if (typeof subtype !== 'number') {
    throw new TypeError('Invalid subtype. Expected a number');
  }

  if (this._subtype !== subtype) {
    this._markModified();
  }

  this._subtype = subtype;
};

/*!
 * Module exports.
 */

MongooseBuffer.Binary = Binary;

module.exports = MongooseBuffer;
