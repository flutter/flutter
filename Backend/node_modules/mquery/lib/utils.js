'use strict';

/*!
 * Module dependencies.
 */

const specialProperties = ['__proto__', 'constructor', 'prototype'];

/**
 * Clones objects
 *
 * @param {Object} obj the object to clone
 * @param {Object} options
 * @return {Object} the cloned object
 * @api private
 */

const clone = exports.clone = function clone(obj, options) {
  if (obj === undefined || obj === null)
    return obj;

  if (Array.isArray(obj))
    return exports.cloneArray(obj, options);

  if (obj.constructor) {
    if (/ObjectI[dD]$/.test(obj.constructor.name)) {
      return 'function' == typeof obj.clone
        ? obj.clone()
        : new obj.constructor(obj.id);
    }

    if (obj.constructor.name === 'ReadPreference') {
      return new obj.constructor(obj.mode, clone(obj.tags, options));
    }

    if ('Binary' == obj._bsontype && obj.buffer && obj.value) {
      return 'function' == typeof obj.clone
        ? obj.clone()
        : new obj.constructor(obj.value(true), obj.sub_type);
    }

    if ('Date' === obj.constructor.name || 'Function' === obj.constructor.name)
      return new obj.constructor(+obj);

    if ('RegExp' === obj.constructor.name)
      return new RegExp(obj);

    if ('Buffer' === obj.constructor.name)
      return Buffer.from(obj);
  }

  if (isObject(obj))
    return exports.cloneObject(obj, options);

  if (obj.valueOf)
    return obj.valueOf();
};

/*!
 * ignore
 */

exports.cloneObject = function cloneObject(obj, options) {
  const minimize = options && options.minimize,
      ret = {},
      keys = Object.keys(obj),
      len = keys.length;
  let hasKeys = false,
      val,
      k = '',
      i = 0;

  for (i = 0; i < len; ++i) {
    k = keys[i];
    // Not technically prototype pollution because this wouldn't merge properties
    // onto `Object.prototype`, but avoid properties like __proto__ as a precaution.
    if (specialProperties.indexOf(k) !== -1) {
      continue;
    }

    val = clone(obj[k], options);

    if (!minimize || ('undefined' !== typeof val)) {
      hasKeys || (hasKeys = true);
      ret[k] = val;
    }
  }

  return minimize
    ? hasKeys && ret
    : ret;
};

exports.cloneArray = function cloneArray(arr, options) {
  const ret = [],
      l = arr.length;
  let i = 0;
  for (; i < l; i++)
    ret.push(clone(arr[i], options));
  return ret;
};

/**
 * Merges `from` into `to` without overwriting existing properties.
 *
 * @param {Object} to
 * @param {Object} from
 * @api private
 */

exports.merge = function merge(to, from) {
  const keys = Object.keys(from);

  for (const key of keys) {
    if (specialProperties.indexOf(key) !== -1) {
      continue;
    }
    if ('undefined' === typeof to[key]) {
      to[key] = from[key];
    } else {
      if (exports.isObject(from[key])) {
        merge(to[key], from[key]);
      } else {
        to[key] = from[key];
      }
    }
  }
};

/**
 * Same as merge but clones the assigned values.
 *
 * @param {Object} to
 * @param {Object} from
 * @api private
 */

exports.mergeClone = function mergeClone(to, from) {
  const keys = Object.keys(from);

  for (const key of keys) {
    if (specialProperties.indexOf(key) !== -1) {
      continue;
    }
    if ('undefined' === typeof to[key]) {
      to[key] = clone(from[key]);
    } else {
      if (exports.isObject(from[key])) {
        mergeClone(to[key], from[key]);
      } else {
        to[key] = clone(from[key]);
      }
    }
  }
};

/**
 * Read pref helper (mongo 2.2 drivers support this)
 *
 * Allows using aliases instead of full preference names:
 *
 *     p   primary
 *     pp  primaryPreferred
 *     s   secondary
 *     sp  secondaryPreferred
 *     n   nearest
 *
 * @param {String} pref
 */

exports.readPref = function readPref(pref) {
  switch (pref) {
    case 'p':
      pref = 'primary';
      break;
    case 'pp':
      pref = 'primaryPreferred';
      break;
    case 's':
      pref = 'secondary';
      break;
    case 'sp':
      pref = 'secondaryPreferred';
      break;
    case 'n':
      pref = 'nearest';
      break;
  }

  return pref;
};


/**
 * Read Concern helper (mongo 3.2 drivers support this)
 *
 * Allows using string to specify read concern level:
 *
 *     local          3.2+
 *     available      3.6+
 *     majority       3.2+
 *     linearizable   3.4+
 *     snapshot       4.0+
 *
 * @param {String|Object} concern
 */

exports.readConcern = function readConcern(concern) {
  if ('string' === typeof concern) {
    switch (concern) {
      case 'l':
        concern = 'local';
        break;
      case 'a':
        concern = 'available';
        break;
      case 'm':
        concern = 'majority';
        break;
      case 'lz':
        concern = 'linearizable';
        break;
      case 's':
        concern = 'snapshot';
        break;
    }
    concern = { level: concern };
  }
  return concern;
};

/**
 * Object.prototype.toString.call helper
 */

const _toString = Object.prototype.toString;
exports.toString = function(arg) {
  return _toString.call(arg);
};

/**
 * Determines if `arg` is an object.
 *
 * @param {Object|Array|String|Function|RegExp|any} arg
 * @return {Boolean}
 */

const isObject = exports.isObject = function(arg) {
  return '[object Object]' == exports.toString(arg);
};

/**
 * Object.keys helper
 */

exports.keys = Object.keys;

/**
 * Basic Object.create polyfill.
 * Only one argument is supported.
 *
 * Based on https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Object/create
 */

exports.create = 'function' == typeof Object.create
  ? Object.create
  : create;

function create(proto) {
  if (arguments.length > 1) {
    throw new Error('Adding properties is not supported');
  }

  function F() { }
  F.prototype = proto;
  return new F;
}

/**
 * inheritance
 */

exports.inherits = function(ctor, superCtor) {
  ctor.prototype = exports.create(superCtor.prototype);
  ctor.prototype.constructor = ctor;
};

/**
 * Check if this object is an arguments object
 *
 * @param {Any} v
 * @return {Boolean}
 */

exports.isArgumentsObject = function(v) {
  return Object.prototype.toString.call(v) === '[object Arguments]';
};
