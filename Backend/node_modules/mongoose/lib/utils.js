'use strict';

/*!
 * Module dependencies.
 */

const UUID = require('bson').UUID;
const ms = require('ms');
const mpath = require('mpath');
const ObjectId = require('./types/objectid');
const PopulateOptions = require('./options/populateOptions');
const clone = require('./helpers/clone');
const immediate = require('./helpers/immediate');
const isObject = require('./helpers/isObject');
const isMongooseArray = require('./types/array/isMongooseArray');
const isMongooseDocumentArray = require('./types/documentArray/isMongooseDocumentArray');
const isBsonType = require('./helpers/isBsonType');
const getFunctionName = require('./helpers/getFunctionName');
const isMongooseObject = require('./helpers/isMongooseObject');
const promiseOrCallback = require('./helpers/promiseOrCallback');
const schemaMerge = require('./helpers/schema/merge');
const specialProperties = require('./helpers/specialProperties');
const { trustedSymbol } = require('./helpers/query/trusted');

let Document;

exports.specialProperties = specialProperties;

exports.isMongooseArray = isMongooseArray.isMongooseArray;
exports.isMongooseDocumentArray = isMongooseDocumentArray.isMongooseDocumentArray;
exports.registerMongooseArray = isMongooseArray.registerMongooseArray;
exports.registerMongooseDocumentArray = isMongooseDocumentArray.registerMongooseDocumentArray;

const oneSpaceRE = /\s/;
const manySpaceRE = /\s+/;

/**
 * Produces a collection name from model `name`. By default, just returns
 * the model name
 *
 * @param {String} name a model name
 * @param {Function} pluralize function that pluralizes the collection name
 * @return {String} a collection name
 * @api private
 */

exports.toCollectionName = function(name, pluralize) {
  if (name === 'system.profile') {
    return name;
  }
  if (name === 'system.indexes') {
    return name;
  }
  if (typeof pluralize === 'function') {
    return pluralize(name);
  }
  return name;
};

/**
 * Determines if `a` and `b` are deep equal.
 *
 * Modified from node/lib/assert.js
 *
 * @param {any} a a value to compare to `b`
 * @param {any} b a value to compare to `a`
 * @return {Boolean}
 * @api private
 */

exports.deepEqual = function deepEqual(a, b) {
  if (a === b) {
    return true;
  }

  if (typeof a !== 'object' || typeof b !== 'object') {
    return a === b;
  }

  if (a instanceof Date && b instanceof Date) {
    return a.getTime() === b.getTime();
  }

  if ((isBsonType(a, 'ObjectId') && isBsonType(b, 'ObjectId')) ||
      (isBsonType(a, 'Decimal128') && isBsonType(b, 'Decimal128'))) {
    return a.toString() === b.toString();
  }

  if (a instanceof RegExp && b instanceof RegExp) {
    return a.source === b.source &&
        a.ignoreCase === b.ignoreCase &&
        a.multiline === b.multiline &&
        a.global === b.global &&
        a.dotAll === b.dotAll &&
        a.unicode === b.unicode &&
        a.sticky === b.sticky &&
        a.hasIndices === b.hasIndices;
  }

  if (a == null || b == null) {
    return false;
  }

  if (a.prototype !== b.prototype) {
    return false;
  }

  if (a instanceof Map || b instanceof Map) {
    if (!(a instanceof Map) || !(b instanceof Map)) {
      return false;
    }
    return deepEqual(Array.from(a.keys()), Array.from(b.keys())) &&
      deepEqual(Array.from(a.values()), Array.from(b.values()));
  }

  // Handle MongooseNumbers
  if (a instanceof Number && b instanceof Number) {
    return a.valueOf() === b.valueOf();
  }

  if (Buffer.isBuffer(a)) {
    return exports.buffer.areEqual(a, b);
  }

  if (Array.isArray(a) || Array.isArray(b)) {
    if (!Array.isArray(a) || !Array.isArray(b)) {
      return false;
    }
    const len = a.length;
    if (len !== b.length) {
      return false;
    }
    for (let i = 0; i < len; ++i) {
      if (!deepEqual(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  if (a.$__ != null) {
    a = a._doc;
  } else if (isMongooseObject(a)) {
    a = a.toObject();
  }

  if (b.$__ != null) {
    b = b._doc;
  } else if (isMongooseObject(b)) {
    b = b.toObject();
  }

  const ka = Object.keys(a);
  const kb = Object.keys(b);
  const kaLength = ka.length;

  // having the same number of owned properties (keys incorporates
  // hasOwnProperty)
  if (kaLength !== kb.length) {
    return false;
  }

  // ~~~cheap key test
  for (let i = kaLength - 1; i >= 0; i--) {
    if (ka[i] !== kb[i]) {
      return false;
    }
  }

  // equivalent values for every corresponding key, and
  // ~~~possibly expensive deep test
  for (const key of ka) {
    if (!deepEqual(a[key], b[key])) {
      return false;
    }
  }

  return true;
};

/**
 * Get the last element of an array
 * @param {Array} arr
 */

exports.last = function(arr) {
  if (arr.length > 0) {
    return arr[arr.length - 1];
  }
  return void 0;
};

/*!
 * ignore
 */

exports.promiseOrCallback = promiseOrCallback;

/*!
 * ignore
 */

exports.cloneArrays = function cloneArrays(arr) {
  if (!Array.isArray(arr)) {
    return arr;
  }

  return arr.map(el => exports.cloneArrays(el));
};

/*!
 * ignore
 */

exports.omit = function omit(obj, keys) {
  if (keys == null) {
    return Object.assign({}, obj);
  }
  if (!Array.isArray(keys)) {
    keys = [keys];
  }

  const ret = Object.assign({}, obj);
  for (const key of keys) {
    delete ret[key];
  }
  return ret;
};

/**
 * Merges `from` into `to` without overwriting existing properties.
 *
 * @param {Object} to
 * @param {Object} from
 * @param {Object} [options]
 * @param {String} [path]
 * @api private
 */

exports.merge = function merge(to, from, options, path) {
  options = options || {};

  const keys = Object.keys(from);
  let i = 0;
  const len = keys.length;
  let key;

  if (from[trustedSymbol]) {
    to[trustedSymbol] = from[trustedSymbol];
  }

  path = path || '';
  const omitNested = options.omitNested || {};

  while (i < len) {
    key = keys[i++];
    if (options.omit && options.omit[key]) {
      continue;
    }
    if (omitNested[path]) {
      continue;
    }
    if (specialProperties.has(key)) {
      continue;
    }
    if (to[key] == null) {
      to[key] = from[key];
    } else if (exports.isObject(from[key])) {
      if (!exports.isObject(to[key])) {
        to[key] = {};
      }
      if (from[key] != null) {
        // Skip merging schemas if we're creating a discriminator schema and
        // base schema has a given path as a single nested but discriminator schema
        // has the path as a document array, or vice versa (gh-9534)
        if (options.isDiscriminatorSchemaMerge &&
            (from[key].$isSingleNested && to[key].$isMongooseDocumentArray) ||
            (from[key].$isMongooseDocumentArray && to[key].$isSingleNested)) {
          continue;
        } else if (from[key].instanceOfSchema) {
          if (to[key].instanceOfSchema) {
            schemaMerge(to[key], from[key].clone(), options.isDiscriminatorSchemaMerge);
          } else {
            to[key] = from[key].clone();
          }
          continue;
        } else if (isBsonType(from[key], 'ObjectId')) {
          to[key] = new ObjectId(from[key]);
          continue;
        }
      }
      merge(to[key], from[key], options, path ? path + '.' + key : key);
    } else if (options.overwrite) {
      to[key] = from[key];
    }
  }
};

/**
 * Applies toObject recursively.
 *
 * @param {Document|Array|Object} obj
 * @return {Object}
 * @api private
 */

exports.toObject = function toObject(obj) {
  Document || (Document = require('./document'));
  let ret;

  if (obj == null) {
    return obj;
  }

  if (obj instanceof Document) {
    return obj.toObject();
  }

  if (Array.isArray(obj)) {
    ret = [];

    for (const doc of obj) {
      ret.push(toObject(doc));
    }

    return ret;
  }

  if (exports.isPOJO(obj)) {
    ret = {};

    if (obj[trustedSymbol]) {
      ret[trustedSymbol] = obj[trustedSymbol];
    }

    for (const k of Object.keys(obj)) {
      if (specialProperties.has(k)) {
        continue;
      }
      ret[k] = toObject(obj[k]);
    }

    return ret;
  }

  return obj;
};

exports.isObject = isObject;

/**
 * Determines if `arg` is a plain old JavaScript object (POJO). Specifically,
 * `arg` must be an object but not an instance of any special class, like String,
 * ObjectId, etc.
 *
 * `Object.getPrototypeOf()` is part of ES5: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/getPrototypeOf
 *
 * @param {Object|Array|String|Function|RegExp|any} arg
 * @api private
 * @return {Boolean}
 */

exports.isPOJO = require('./helpers/isPOJO');

/**
 * Determines if `arg` is an object that isn't an instance of a built-in value
 * class, like Array, Buffer, ObjectId, etc.
 * @param {Any} val
 */

exports.isNonBuiltinObject = function isNonBuiltinObject(val) {
  return typeof val === 'object' &&
    !exports.isNativeObject(val) &&
    !exports.isMongooseType(val) &&
    !(val instanceof UUID) &&
    val != null;
};

/**
 * Determines if `obj` is a built-in object like an array, date, boolean,
 * etc.
 * @param {Any} arg
 */

exports.isNativeObject = function(arg) {
  return Array.isArray(arg) ||
    arg instanceof Date ||
    arg instanceof Boolean ||
    arg instanceof Number ||
    arg instanceof String;
};

/**
 * Determines if `val` is an object that has no own keys
 * @param {Any} val
 */

exports.isEmptyObject = function(val) {
  return val != null &&
    typeof val === 'object' &&
    Object.keys(val).length === 0;
};

/**
 * Search if `obj` or any POJOs nested underneath `obj` has a property named
 * `key`
 * @param {Object} obj
 * @param {String} key
 */

exports.hasKey = function hasKey(obj, key) {
  const props = Object.keys(obj);
  for (const prop of props) {
    if (prop === key) {
      return true;
    }
    if (exports.isPOJO(obj[prop]) && exports.hasKey(obj[prop], key)) {
      return true;
    }
  }
  return false;
};

/**
 * process.nextTick helper.
 *
 * Wraps `callback` in a try/catch + nextTick.
 *
 * node-mongodb-native has a habit of state corruption when an error is immediately thrown from within a collection callback.
 *
 * @param {Function} callback
 * @api private
 */

exports.tick = function tick(callback) {
  if (typeof callback !== 'function') {
    return;
  }
  return function() {
    try {
      callback.apply(this, arguments);
    } catch (err) {
      // only nextTick on err to get out of
      // the event loop and avoid state corruption.
      immediate(function() {
        throw err;
      });
    }
  };
};

/**
 * Returns true if `v` is an object that can be serialized as a primitive in
 * MongoDB
 * @param {Any} v
 */

exports.isMongooseType = function(v) {
  return isBsonType(v, 'ObjectId') || isBsonType(v, 'Decimal128') || v instanceof Buffer;
};

exports.isMongooseObject = isMongooseObject;

/**
 * Converts `expires` options of index objects to `expiresAfterSeconds` options for MongoDB.
 *
 * @param {Object} object
 * @api private
 */

exports.expires = function expires(object) {
  if (!(object && object.constructor.name === 'Object')) {
    return;
  }
  if (!('expires' in object)) {
    return;
  }

  object.expireAfterSeconds = (typeof object.expires !== 'string')
    ? object.expires
    : Math.round(ms(object.expires) / 1000);
  delete object.expires;
};

/**
 * populate helper
 * @param {String} path
 * @param {String} select
 * @param {Model} model
 * @param {Object} match
 * @param {Object} options
 * @param {Any} subPopulate
 * @param {Boolean} justOne
 * @param {Boolean} count
 */

exports.populate = function populate(path, select, model, match, options, subPopulate, justOne, count) {
  // might have passed an object specifying all arguments
  let obj = null;
  if (arguments.length === 1) {
    if (path instanceof PopulateOptions) {
      // If reusing old populate docs, avoid reusing `_docs` because that may
      // lead to bugs and memory leaks. See gh-11641
      path._docs = [];
      path._childDocs = [];
      return [path];
    }

    if (Array.isArray(path)) {
      const singles = makeSingles(path);
      return singles.map(o => exports.populate(o)[0]);
    }

    if (exports.isObject(path)) {
      obj = Object.assign({}, path);
    } else {
      obj = { path: path };
    }
  } else if (typeof model === 'object') {
    obj = {
      path: path,
      select: select,
      match: model,
      options: match
    };
  } else {
    obj = {
      path: path,
      select: select,
      model: model,
      match: match,
      options: options,
      populate: subPopulate,
      justOne: justOne,
      count: count
    };
  }

  if (typeof obj.path !== 'string') {
    throw new TypeError('utils.populate: invalid path. Expected string. Got typeof `' + typeof path + '`');
  }

  return _populateObj(obj);

  // The order of select/conditions args is opposite Model.find but
  // necessary to keep backward compatibility (select could be
  // an array, string, or object literal).
  function makeSingles(arr) {
    const ret = [];
    arr.forEach(function(obj) {
      if (oneSpaceRE.test(obj.path)) {
        const paths = obj.path.split(manySpaceRE);
        paths.forEach(function(p) {
          const copy = Object.assign({}, obj);
          copy.path = p;
          ret.push(copy);
        });
      } else {
        ret.push(obj);
      }
    });

    return ret;
  }
};

function _populateObj(obj) {
  if (Array.isArray(obj.populate)) {
    const ret = [];
    obj.populate.forEach(function(obj) {
      if (oneSpaceRE.test(obj.path)) {
        const copy = Object.assign({}, obj);
        const paths = copy.path.split(manySpaceRE);
        paths.forEach(function(p) {
          copy.path = p;
          ret.push(exports.populate(copy)[0]);
        });
      } else {
        ret.push(exports.populate(obj)[0]);
      }
    });
    obj.populate = exports.populate(ret);
  } else if (obj.populate != null && typeof obj.populate === 'object') {
    obj.populate = exports.populate(obj.populate);
  }

  const ret = [];
  const paths = oneSpaceRE.test(obj.path) ? obj.path.split(manySpaceRE) : [obj.path];
  if (obj.options != null) {
    obj.options = clone(obj.options);
  }

  for (const path of paths) {
    ret.push(new PopulateOptions(Object.assign({}, obj, { path: path })));
  }

  return ret;
}

/**
 * Return the value of `obj` at the given `path`.
 *
 * @param {String} path
 * @param {Object} obj
 * @param {Any} map
 */

exports.getValue = function(path, obj, map) {
  return mpath.get(path, obj, getValueLookup, map);
};

/*!
 * ignore
 */

const mapGetterOptions = Object.freeze({ getters: false });

function getValueLookup(obj, part) {
  let _from = obj?._doc || obj;
  if (_from != null && _from.isMongooseArrayProxy) {
    _from = _from.__array;
  }
  return _from instanceof Map ?
    _from.get(part, mapGetterOptions) :
    _from[part];
}

/**
 * Sets the value of `obj` at the given `path`.
 *
 * @param {String} path
 * @param {Anything} val
 * @param {Object} obj
 * @param {Any} map
 * @param {Any} _copying
 */

exports.setValue = function(path, val, obj, map, _copying) {
  mpath.set(path, val, obj, '_doc', map, _copying);
};

/**
 * Returns an array of values from object `o`.
 *
 * @param {Object} o
 * @return {Array}
 * @api private
 */

exports.object = {};
exports.object.vals = function vals(o) {
  const keys = Object.keys(o);
  let i = keys.length;
  const ret = [];

  while (i--) {
    ret.push(o[keys[i]]);
  }

  return ret;
};

const hop = Object.prototype.hasOwnProperty;

/**
 * Safer helper for hasOwnProperty checks
 *
 * @param {Object} obj
 * @param {String} prop
 */

exports.object.hasOwnProperty = function(obj, prop) {
  return hop.call(obj, prop);
};

/**
 * Determine if `val` is null or undefined
 *
 * @param {Any} val
 * @return {Boolean}
 */

exports.isNullOrUndefined = function(val) {
  return val === null || val === undefined;
};

/*!
 * ignore
 */

exports.array = {};

/**
 * Flattens an array.
 *
 * [ 1, [ 2, 3, [4] ]] -> [1,2,3,4]
 *
 * @param {Array} arr
 * @param {Function} [filter] If passed, will be invoked with each item in the array. If `filter` returns a falsy value, the item will not be included in the results.
 * @param {Array} ret
 * @return {Array}
 * @api private
 */

exports.array.flatten = function flatten(arr, filter, ret) {
  ret || (ret = []);

  arr.forEach(function(item) {
    if (Array.isArray(item)) {
      flatten(item, filter, ret);
    } else {
      if (!filter || filter(item)) {
        ret.push(item);
      }
    }
  });

  return ret;
};

/*!
 * ignore
 */

const _hasOwnProperty = Object.prototype.hasOwnProperty;

exports.hasUserDefinedProperty = function(obj, key) {
  if (obj == null) {
    return false;
  }

  if (Array.isArray(key)) {
    for (const k of key) {
      if (exports.hasUserDefinedProperty(obj, k)) {
        return true;
      }
    }
    return false;
  }

  if (_hasOwnProperty.call(obj, key)) {
    return true;
  }
  if (typeof obj === 'object' && key in obj) {
    const v = obj[key];
    return v !== Object.prototype[key] && v !== Array.prototype[key];
  }

  return false;
};

/*!
 * ignore
 */

const MAX_ARRAY_INDEX = Math.pow(2, 32) - 1;

exports.isArrayIndex = function(val) {
  if (typeof val === 'number') {
    return val >= 0 && val <= MAX_ARRAY_INDEX;
  }
  if (typeof val === 'string') {
    if (!/^\d+$/.test(val)) {
      return false;
    }
    val = +val;
    return val >= 0 && val <= MAX_ARRAY_INDEX;
  }

  return false;
};

/**
 * Removes duplicate values from an array
 *
 * [1, 2, 3, 3, 5] => [1, 2, 3, 5]
 * [ ObjectId("550988ba0c19d57f697dc45e"), ObjectId("550988ba0c19d57f697dc45e") ]
 *    => [ObjectId("550988ba0c19d57f697dc45e")]
 *
 * @param {Array} arr
 * @return {Array}
 * @api private
 */

exports.array.unique = function(arr) {
  const primitives = new Set();
  const ids = new Set();
  const ret = [];

  for (const item of arr) {
    if (typeof item === 'number' || typeof item === 'string' || item == null) {
      if (primitives.has(item)) {
        continue;
      }
      ret.push(item);
      primitives.add(item);
    } else if (isBsonType(item, 'ObjectId')) {
      if (ids.has(item.toString())) {
        continue;
      }
      ret.push(item);
      ids.add(item.toString());
    } else {
      ret.push(item);
    }
  }

  return ret;
};

exports.buffer = {};

/**
 * Determines if two buffers are equal.
 *
 * @param {Buffer} a
 * @param {Object} b
 */

exports.buffer.areEqual = function(a, b) {
  if (!Buffer.isBuffer(a)) {
    return false;
  }
  if (!Buffer.isBuffer(b)) {
    return false;
  }
  if (a.length !== b.length) {
    return false;
  }
  for (let i = 0, len = a.length; i < len; ++i) {
    if (a[i] !== b[i]) {
      return false;
    }
  }
  return true;
};

exports.getFunctionName = getFunctionName;

/**
 * Decorate buffers
 * @param {Object} destination
 * @param {Object} source
 */

exports.decorate = function(destination, source) {
  for (const key in source) {
    if (specialProperties.has(key)) {
      continue;
    }
    destination[key] = source[key];
  }
};

/**
 * merges to with a copy of from
 *
 * @param {Object} to
 * @param {Object} fromObj
 * @api private
 */

exports.mergeClone = function(to, fromObj) {
  if (isMongooseObject(fromObj)) {
    fromObj = fromObj.toObject({
      transform: false,
      virtuals: false,
      depopulate: true,
      getters: false,
      flattenDecimals: false
    });
  }
  const keys = Object.keys(fromObj);
  const len = keys.length;
  let i = 0;
  let key;

  while (i < len) {
    key = keys[i++];
    if (specialProperties.has(key)) {
      continue;
    }
    if (typeof to[key] === 'undefined') {
      to[key] = clone(fromObj[key], {
        transform: false,
        virtuals: false,
        depopulate: true,
        getters: false,
        flattenDecimals: false
      });
    } else {
      let val = fromObj[key];
      if (val != null && val.valueOf && !(val instanceof Date)) {
        val = val.valueOf();
      }
      if (exports.isObject(val)) {
        let obj = val;
        if (isMongooseObject(val) && !val.isMongooseBuffer) {
          obj = obj.toObject({
            transform: false,
            virtuals: false,
            depopulate: true,
            getters: false,
            flattenDecimals: false
          });
        }
        if (val.isMongooseBuffer) {
          obj = Buffer.from(obj);
        }
        exports.mergeClone(to[key], obj);
      } else {
        to[key] = clone(val, {
          flattenDecimals: false
        });
      }
    }
  }
};

/**
 * Executes a function on each element of an array (like _.each)
 *
 * @param {Array} arr
 * @param {Function} fn
 * @api private
 */

exports.each = function(arr, fn) {
  for (const item of arr) {
    fn(item);
  }
};

/**
 * Rename an object key, while preserving its position in the object
 *
 * @param {Object} oldObj
 * @param {String|Number} oldKey
 * @param {String|Number} newKey
 * @api private
 */
exports.renameObjKey = function(oldObj, oldKey, newKey) {
  const keys = Object.keys(oldObj);
  return keys.reduce(
    (acc, val) => {
      if (val === oldKey) {
        acc[newKey] = oldObj[oldKey];
      } else {
        acc[val] = oldObj[val];
      }
      return acc;
    },
    {}
  );
};

/*!
 * ignore
 */

exports.getOption = function(name) {
  const sources = Array.prototype.slice.call(arguments, 1);

  for (const source of sources) {
    if (source == null) {
      continue;
    }
    if (source[name] != null) {
      return source[name];
    }
  }

  return null;
};

/*!
 * ignore
 */

exports.noop = function() {};

exports.errorToPOJO = function errorToPOJO(error) {
  const isError = error instanceof Error;
  if (!isError) {
    throw new Error('`error` must be `instanceof Error`.');
  }

  const ret = {};
  for (const properyName of Object.getOwnPropertyNames(error)) {
    ret[properyName] = error[properyName];
  }
  return ret;
};

/*!
 * ignore
 */

exports.warn = function warn(message) {
  return process.emitWarning(message, { code: 'MONGOOSE' });
};


exports.injectTimestampsOption = function injectTimestampsOption(writeOperation, timestampsOption) {
  if (timestampsOption == null) {
    return;
  }
  writeOperation.timestamps = timestampsOption;
};
