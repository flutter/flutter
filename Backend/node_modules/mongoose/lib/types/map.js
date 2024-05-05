'use strict';

const Mixed = require('../schema/mixed');
const MongooseError = require('../error/mongooseError');
const clone = require('../helpers/clone');
const deepEqual = require('../utils').deepEqual;
const getConstructorName = require('../helpers/getConstructorName');
const handleSpreadDoc = require('../helpers/document/handleSpreadDoc');
const util = require('util');
const specialProperties = require('../helpers/specialProperties');
const isBsonType = require('../helpers/isBsonType');

const populateModelSymbol = require('../helpers/symbols').populateModelSymbol;

/*!
 * ignore
 */

class MongooseMap extends Map {
  constructor(v, path, doc, schemaType) {
    if (getConstructorName(v) === 'Object') {
      v = Object.keys(v).reduce((arr, key) => arr.concat([[key, v[key]]]), []);
    }
    super(v);
    this.$__parent = doc != null && doc.$__ != null ? doc : null;
    this.$__path = path;
    this.$__schemaType = schemaType == null ? new Mixed(path) : schemaType;

    this.$__runDeferred();
  }

  $init(key, value) {
    checkValidKey(key);

    super.set(key, value);

    if (value != null && value.$isSingleNested) {
      value.$basePath = this.$__path + '.' + key;
    }
  }

  $__set(key, value) {
    super.set(key, value);
  }

  /**
   * Overwrites native Map's `get()` function to support Mongoose getters.
   *
   * @api public
   * @method get
   * @memberOf Map
   */

  get(key, options) {
    if (isBsonType(key, 'ObjectId')) {
      key = key.toString();
    }

    options = options || {};
    if (options.getters === false) {
      return super.get(key);
    }
    return this.$__schemaType.applyGetters(super.get(key), this.$__parent);
  }

  /**
   * Overwrites native Map's `set()` function to support setters, `populate()`,
   * and change tracking. Note that Mongoose maps _only_ support strings and
   * ObjectIds as keys.
   *
   * #### Example:
   *
   *     doc.myMap.set('test', 42); // works
   *     doc.myMap.set({ obj: 42 }, 42); // Throws "Mongoose maps only support string keys"
   *
   * @api public
   * @method set
   * @memberOf Map
   */

  set(key, value) {
    if (isBsonType(key, 'ObjectId')) {
      key = key.toString();
    }

    checkValidKey(key);
    value = handleSpreadDoc(value);

    // Weird, but because you can't assign to `this` before calling `super()`
    // you can't get access to `$__schemaType` to cast in the initial call to
    // `set()` from the `super()` constructor.

    if (this.$__schemaType == null) {
      this.$__deferred = this.$__deferred || [];
      this.$__deferred.push({ key: key, value: value });
      return;
    }

    let _fullPath;
    const parent = this.$__parent;
    const populated = parent != null && parent.$__ && parent.$__.populated ?
      parent.$populated(fullPath.call(this), true) || parent.$populated(this.$__path, true) :
      null;
    const priorVal = this.get(key);

    if (populated != null) {
      if (this.$__schemaType.$isSingleNested) {
        throw new MongooseError(
          'Cannot manually populate single nested subdoc underneath Map ' +
          `at path "${this.$__path}". Try using an array instead of a Map.`
        );
      }
      if (Array.isArray(value) && this.$__schemaType.$isMongooseArray) {
        value = value.map(v => {
          if (v.$__ == null) {
            v = new populated.options[populateModelSymbol](v);
          }
          // Doesn't support single nested "in-place" populate
          v.$__.wasPopulated = { value: v._id };
          return v;
        });
      } else {
        if (value.$__ == null) {
          value = new populated.options[populateModelSymbol](value);
        }
        // Doesn't support single nested "in-place" populate
        value.$__.wasPopulated = { value: value._id };
      }
    } else {
      try {
        const options = this.$__schemaType.$isMongooseDocumentArray || this.$__schemaType.$isSingleNested ?
          { path: fullPath.call(this) } :
          null;
        value = this.$__schemaType.applySetters(
          value,
          this.$__parent,
          false,
          this.get(key),
          options
        );
      } catch (error) {
        if (this.$__parent != null && this.$__parent.$__ != null) {
          this.$__parent.invalidate(fullPath.call(this), error);
          return;
        }
        throw error;
      }
    }

    super.set(key, value);

    if (parent != null && parent.$__ != null && !deepEqual(value, priorVal)) {
      parent.markModified(fullPath.call(this));
    }

    // Delay calculating full path unless absolutely necessary, because string
    // concatenation is a bottleneck re: #13171
    function fullPath() {
      if (_fullPath) {
        return _fullPath;
      }
      _fullPath = this.$__path + '.' + key;
      return _fullPath;
    }
  }

  /**
   * Overwrites native Map's `clear()` function to support change tracking.
   *
   * @api public
   * @method clear
   * @memberOf Map
   */

  clear() {
    super.clear();
    const parent = this.$__parent;
    if (parent != null) {
      parent.markModified(this.$__path);
    }
  }

  /**
   * Overwrites native Map's `delete()` function to support change tracking.
   *
   * @api public
   * @method delete
   * @memberOf Map
   */

  delete(key) {
    if (isBsonType(key, 'ObjectId')) {
      key = key.toString();
    }

    this.set(key, undefined);
    return super.delete(key);
  }

  /**
   * Converts this map to a native JavaScript Map so the MongoDB driver can serialize it.
   *
   * @api public
   * @method toBSON
   * @memberOf Map
   */

  toBSON() {
    return new Map(this);
  }

  toObject(options) {
    if (options && options.flattenMaps) {
      const ret = {};
      const keys = this.keys();
      for (const key of keys) {
        ret[key] = clone(this.get(key), options);
      }
      return ret;
    }

    return new Map(this);
  }

  $toObject() {
    return this.constructor.prototype.toObject.apply(this, arguments);
  }

  /**
   * Converts this map to a native JavaScript Map for `JSON.stringify()`. Set
   * the `flattenMaps` option to convert this map to a POJO instead.
   *
   * #### Example:
   *
   *     doc.myMap.toJSON() instanceof Map; // true
   *     doc.myMap.toJSON({ flattenMaps: true }) instanceof Map; // false
   *
   * @api public
   * @method toJSON
   * @param {Object} [options]
   * @param {Boolean} [options.flattenMaps=false] set to `true` to convert the map to a POJO rather than a native JavaScript map
   * @memberOf Map
   */

  toJSON(options) {
    if (typeof (options && options.flattenMaps) === 'boolean' ? options.flattenMaps : true) {
      const ret = {};
      const keys = this.keys();
      for (const key of keys) {
        ret[key] = clone(this.get(key), options);
      }
      return ret;
    }

    return new Map(this);
  }

  inspect() {
    return new Map(this);
  }

  $__runDeferred() {
    if (!this.$__deferred) {
      return;
    }

    for (const keyValueObject of this.$__deferred) {
      this.set(keyValueObject.key, keyValueObject.value);
    }

    this.$__deferred = null;
  }
}

if (util.inspect.custom) {
  Object.defineProperty(MongooseMap.prototype, util.inspect.custom, {
    enumerable: false,
    writable: false,
    configurable: false,
    value: MongooseMap.prototype.inspect
  });
}

Object.defineProperty(MongooseMap.prototype, '$__set', {
  enumerable: false,
  writable: true,
  configurable: false
});

Object.defineProperty(MongooseMap.prototype, '$__parent', {
  enumerable: false,
  writable: true,
  configurable: false
});

Object.defineProperty(MongooseMap.prototype, '$__path', {
  enumerable: false,
  writable: true,
  configurable: false
});

Object.defineProperty(MongooseMap.prototype, '$__schemaType', {
  enumerable: false,
  writable: true,
  configurable: false
});

/**
 * Set to `true` for all Mongoose map instances
 *
 * @api public
 * @property $isMongooseMap
 * @memberOf MongooseMap
 * @instance
 */

Object.defineProperty(MongooseMap.prototype, '$isMongooseMap', {
  enumerable: false,
  writable: false,
  configurable: false,
  value: true
});

Object.defineProperty(MongooseMap.prototype, '$__deferredCalls', {
  enumerable: false,
  writable: false,
  configurable: false,
  value: true
});

/**
 * Since maps are stored as objects under the hood, keys must be strings
 * and can't contain any invalid characters
 * @param {String} key
 * @api private
 */

function checkValidKey(key) {
  const keyType = typeof key;
  if (keyType !== 'string') {
    throw new TypeError(`Mongoose maps only support string keys, got ${keyType}`);
  }
  if (key.startsWith('$')) {
    throw new Error(`Mongoose maps do not support keys that start with "$", got "${key}"`);
  }
  if (key.includes('.')) {
    throw new Error(`Mongoose maps do not support keys that contain ".", got "${key}"`);
  }
  if (specialProperties.has(key)) {
    throw new Error(`Mongoose maps do not support reserved key name "${key}"`);
  }
}

module.exports = MongooseMap;
