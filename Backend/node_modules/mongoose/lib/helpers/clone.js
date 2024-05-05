'use strict';

const Decimal = require('../types/decimal128');
const ObjectId = require('../types/objectid');
const specialProperties = require('./specialProperties');
const isMongooseObject = require('./isMongooseObject');
const getFunctionName = require('./getFunctionName');
const isBsonType = require('./isBsonType');
const isMongooseArray = require('../types/array/isMongooseArray').isMongooseArray;
const isObject = require('./isObject');
const isPOJO = require('./isPOJO');
const symbols = require('./symbols');
const trustedSymbol = require('./query/trusted').trustedSymbol;

/**
 * Object clone with Mongoose natives support.
 *
 * If options.minimize is true, creates a minimal data object. Empty objects and undefined values will not be cloned. This makes the data payload sent to MongoDB as small as possible.
 *
 * Functions are never cloned.
 *
 * @param {Object} obj the object to clone
 * @param {Object} options
 * @param {Boolean} isArrayChild true if cloning immediately underneath an array. Special case for minimize.
 * @return {Object} the cloned object
 * @api private
 */

function clone(obj, options, isArrayChild) {
  if (obj == null) {
    return obj;
  }

  if (Array.isArray(obj)) {
    return cloneArray(isMongooseArray(obj) ? obj.__array : obj, options);
  }

  if (isMongooseObject(obj)) {
    if (options) {
      // Single nested subdocs should apply getters later in `applyGetters()`
      // when calling `toObject()`. See gh-7442, gh-8295
      if (options._skipSingleNestedGetters && obj.$isSingleNested) {
        options = Object.assign({}, options, { getters: false });
      }
      if (options.retainDocuments && obj.$__ != null) {
        const clonedDoc = obj.$clone();
        if (obj.__index != null) {
          clonedDoc.__index = obj.__index;
        }
        if (obj.__parentArray != null) {
          clonedDoc.__parentArray = obj.__parentArray;
        }
        clonedDoc.$__parent = obj.$__parent;
        return clonedDoc;
      }
    }
    const isSingleNested = obj.$isSingleNested;

    if (isPOJO(obj) && obj.$__ != null && obj._doc != null) {
      return obj._doc;
    }

    let ret;
    if (options && options.json && typeof obj.toJSON === 'function') {
      ret = obj.toJSON(options);
    } else {
      ret = obj.toObject(options);
    }

    if (options && options.minimize && !obj.constructor.$__required && isSingleNested && Object.keys(ret).length === 0) {
      return undefined;
    }

    return ret;
  }

  const objConstructor = obj.constructor;

  if (objConstructor) {
    switch (getFunctionName(objConstructor)) {
      case 'Object':
        return cloneObject(obj, options, isArrayChild);
      case 'Date':
        return new objConstructor(+obj);
      case 'RegExp':
        return cloneRegExp(obj);
      default:
        // ignore
        break;
    }
  }

  if (isBsonType(obj, 'ObjectId')) {
    if (options && options.flattenObjectIds) {
      return obj.toJSON();
    }
    return new ObjectId(obj.id);
  }

  if (isBsonType(obj, 'Decimal128')) {
    if (options && options.flattenDecimals) {
      return obj.toJSON();
    }
    return Decimal.fromString(obj.toString());
  }

  // object created with Object.create(null)
  if (!objConstructor && isObject(obj)) {
    return cloneObject(obj, options, isArrayChild);
  }

  if (typeof obj === 'object' && obj[symbols.schemaTypeSymbol]) {
    return obj.clone();
  }

  // If we're cloning this object to go into a MongoDB command,
  // and there's a `toBSON()` function, assume this object will be
  // stored as a primitive in MongoDB and doesn't need to be cloned.
  if (options && options.bson && typeof obj.toBSON === 'function') {
    return obj;
  }

  if (typeof obj.valueOf === 'function') {
    return obj.valueOf();
  }

  return cloneObject(obj, options, isArrayChild);
}
module.exports = clone;

/*!
 * ignore
 */

function cloneObject(obj, options, isArrayChild) {
  const minimize = options && options.minimize;
  const omitUndefined = options && options.omitUndefined;
  const seen = options && options._seen;
  const ret = {};
  let hasKeys;

  if (seen && seen.has(obj)) {
    return seen.get(obj);
  } else if (seen) {
    seen.set(obj, ret);
  }
  if (trustedSymbol in obj) {
    ret[trustedSymbol] = obj[trustedSymbol];
  }

  let i = 0;
  let key = '';
  const keys = Object.keys(obj);
  const len = keys.length;

  for (i = 0; i < len; ++i) {
    if (specialProperties.has(key = keys[i])) {
      continue;
    }

    // Don't pass `isArrayChild` down
    const val = clone(obj[key], options, false);

    if ((minimize === false || omitUndefined) && typeof val === 'undefined') {
      delete ret[key];
    } else if (minimize !== true || (typeof val !== 'undefined')) {
      hasKeys || (hasKeys = true);
      ret[key] = val;
    }
  }

  return minimize && !isArrayChild ? hasKeys && ret : ret;
}

function cloneArray(arr, options) {
  let i = 0;
  const len = arr.length;
  const ret = new Array(len);
  for (i = 0; i < len; ++i) {
    ret[i] = clone(arr[i], options, true);
  }

  return ret;
}

function cloneRegExp(regexp) {
  const ret = new RegExp(regexp.source, regexp.flags);

  if (ret.lastIndex !== regexp.lastIndex) {
    ret.lastIndex = regexp.lastIndex;
  }
  return ret;
}
