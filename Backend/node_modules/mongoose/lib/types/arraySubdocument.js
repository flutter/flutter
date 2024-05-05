/*!
 * Module dependencies.
 */

'use strict';

const EventEmitter = require('events').EventEmitter;
const Subdocument = require('./subdocument');
const utils = require('../utils');

const documentArrayParent = require('../helpers/symbols').documentArrayParent;

/**
 * A constructor.
 *
 * @param {Object} obj js object returned from the db
 * @param {MongooseDocumentArray} parentArr the parent array of this document
 * @param {Boolean} skipId
 * @param {Object} fields
 * @param {Number} index
 * @inherits Document
 * @api private
 */

function ArraySubdocument(obj, parentArr, skipId, fields, index) {
  if (utils.isMongooseDocumentArray(parentArr)) {
    this.__parentArray = parentArr;
    this[documentArrayParent] = parentArr.$parent();
  } else {
    this.__parentArray = undefined;
    this[documentArrayParent] = undefined;
  }
  this.$setIndex(index);
  this.$__parent = this[documentArrayParent];

  let options;
  if (typeof skipId === 'object' && skipId != null) {
    options = { isNew: true, ...skipId };
    skipId = undefined;
  } else {
    options = { isNew: true };
  }

  Subdocument.call(this, obj, fields, this[documentArrayParent], skipId, options);
}

/*!
 * Inherit from Subdocument
 */
ArraySubdocument.prototype = Object.create(Subdocument.prototype);
ArraySubdocument.prototype.constructor = ArraySubdocument;

Object.defineProperty(ArraySubdocument.prototype, '$isSingleNested', {
  configurable: false,
  writable: false,
  value: false
});

Object.defineProperty(ArraySubdocument.prototype, '$isDocumentArrayElement', {
  configurable: false,
  writable: false,
  value: true
});

for (const i in EventEmitter.prototype) {
  ArraySubdocument[i] = EventEmitter.prototype[i];
}

/*!
 * ignore
 */

ArraySubdocument.prototype.$setIndex = function(index) {
  this.__index = index;

  if (this.$__ != null && this.$__.validationError != null) {
    const keys = Object.keys(this.$__.validationError.errors);
    for (const key of keys) {
      this.invalidate(key, this.$__.validationError.errors[key]);
    }
  }
};

/*!
 * ignore
 */

ArraySubdocument.prototype.populate = function() {
  throw new Error('Mongoose does not support calling populate() on nested ' +
    'docs. Instead of `doc.arr[0].populate("path")`, use ' +
    '`doc.populate("arr.0.path")`');
};

/*!
 * ignore
 */

ArraySubdocument.prototype.$__removeFromParent = function() {
  const _id = this._doc._id;
  if (!_id) {
    throw new Error('For your own good, Mongoose does not know ' +
      'how to remove an ArraySubdocument that has no _id');
  }
  this.__parentArray.pull({ _id: _id });
};

/**
 * Returns the full path to this document. If optional `path` is passed, it is appended to the full path.
 *
 * @param {String} [path]
 * @param {Boolean} [skipIndex] Skip adding the array index. For example `arr.foo` instead of `arr.0.foo`.
 * @return {String}
 * @api private
 * @method $__fullPath
 * @memberOf ArraySubdocument
 * @instance
 */

ArraySubdocument.prototype.$__fullPath = function(path, skipIndex) {
  if (this.__index == null) {
    return null;
  }
  if (!this.$__.fullPath) {
    this.ownerDocument();
  }

  if (skipIndex) {
    return path ?
      this.$__.fullPath + '.' + path :
      this.$__.fullPath;
  }

  return path ?
    this.$__.fullPath + '.' + this.__index + '.' + path :
    this.$__.fullPath + '.' + this.__index;
};

/**
 * Given a path relative to this document, return the path relative
 * to the top-level document.
 * @method $__pathRelativeToParent
 * @memberOf ArraySubdocument
 * @instance
 * @api private
 */

ArraySubdocument.prototype.$__pathRelativeToParent = function(path, skipIndex) {
  if (this.__index == null || (!this.__parentArray || !this.__parentArray.$path)) {
    return null;
  }
  if (skipIndex) {
    return path == null ? this.__parentArray.$path() : this.__parentArray.$path() + '.' + path;
  }
  if (path == null) {
    return this.__parentArray.$path() + '.' + this.__index;
  }
  return this.__parentArray.$path() + '.' + this.__index + '.' + path;
};

/**
 * Returns this sub-documents parent document.
 * @method $parent
 * @memberOf ArraySubdocument
 * @instance
 * @api public
 */

ArraySubdocument.prototype.$parent = function() {
  return this[documentArrayParent];
};

/**
 * Returns this subdocument's parent array.
 *
 * #### Example:
 *
 *     const Test = mongoose.model('Test', new Schema({
 *       docArr: [{ name: String }]
 *     }));
 *     const doc = new Test({ docArr: [{ name: 'test subdoc' }] });
 *
 *     doc.docArr[0].parentArray() === doc.docArr; // true
 *
 * @api public
 * @method parentArray
 * @returns DocumentArray
 */

ArraySubdocument.prototype.parentArray = function() {
  return this.__parentArray;
};

/*!
 * Module exports.
 */

module.exports = ArraySubdocument;
