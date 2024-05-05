/* eslint strict:off */
/* eslint no-var: off */
/* eslint no-redeclare: off */

var stringToParts = require('./stringToParts');

// These properties are special and can open client libraries to security
// issues
var ignoreProperties = ['__proto__', 'constructor', 'prototype'];

/**
 * Returns the value of object `o` at the given `path`.
 *
 * ####Example:
 *
 *     var obj = {
 *         comments: [
 *             { title: 'exciting!', _doc: { title: 'great!' }}
 *           , { title: 'number dos' }
 *         ]
 *     }
 *
 *     mpath.get('comments.0.title', o)         // 'exciting!'
 *     mpath.get('comments.0.title', o, '_doc') // 'great!'
 *     mpath.get('comments.title', o)           // ['exciting!', 'number dos']
 *
 *     // summary
 *     mpath.get(path, o)
 *     mpath.get(path, o, special)
 *     mpath.get(path, o, map)
 *     mpath.get(path, o, special, map)
 *
 * @param {String} path
 * @param {Object} o
 * @param {String} [special] When this property name is present on any object in the path, walking will continue on the value of this property.
 * @param {Function} [map] Optional function which receives each individual found value. The value returned from `map` is used in the original values place.
 */

exports.get = function(path, o, special, map) {
  var lookup;

  if ('function' == typeof special) {
    if (special.length < 2) {
      map = special;
      special = undefined;
    } else {
      lookup = special;
      special = undefined;
    }
  }

  map || (map = K);

  var parts = 'string' == typeof path
    ? stringToParts(path)
    : path;

  if (!Array.isArray(parts)) {
    throw new TypeError('Invalid `path`. Must be either string or array');
  }

  var obj = o,
      part;

  for (var i = 0; i < parts.length; ++i) {
    part = parts[i];
    if (typeof parts[i] !== 'string' && typeof parts[i] !== 'number') {
      throw new TypeError('Each segment of path to `get()` must be a string or number, got ' + typeof parts[i]);
    }

    if (Array.isArray(obj) && !/^\d+$/.test(part)) {
      // reading a property from the array items
      var paths = parts.slice(i);

      // Need to `concat()` to avoid `map()` calling a constructor of an array
      // subclass
      return [].concat(obj).map(function(item) {
        return item
          ? exports.get(paths, item, special || lookup, map)
          : map(undefined);
      });
    }

    if (lookup) {
      obj = lookup(obj, part);
    } else {
      var _from = special && obj[special] ? obj[special] : obj;
      obj = _from instanceof Map ?
        _from.get(part) :
        _from[part];
    }

    if (!obj) return map(obj);
  }

  return map(obj);
};

/**
 * Returns true if `in` returns true for every piece of the path
 *
 * @param {String} path
 * @param {Object} o
 */

exports.has = function(path, o) {
  var parts = typeof path === 'string' ?
    stringToParts(path) :
    path;

  if (!Array.isArray(parts)) {
    throw new TypeError('Invalid `path`. Must be either string or array');
  }

  var len = parts.length;
  var cur = o;
  for (var i = 0; i < len; ++i) {
    if (typeof parts[i] !== 'string' && typeof parts[i] !== 'number') {
      throw new TypeError('Each segment of path to `has()` must be a string or number, got ' + typeof parts[i]);
    }
    if (cur == null || typeof cur !== 'object' || !(parts[i] in cur)) {
      return false;
    }
    cur = cur[parts[i]];
  }

  return true;
};

/**
 * Deletes the last piece of `path`
 *
 * @param {String} path
 * @param {Object} o
 */

exports.unset = function(path, o) {
  var parts = typeof path === 'string' ?
    stringToParts(path) :
    path;

  if (!Array.isArray(parts)) {
    throw new TypeError('Invalid `path`. Must be either string or array');
  }

  var len = parts.length;
  var cur = o;
  for (var i = 0; i < len; ++i) {
    if (cur == null || typeof cur !== 'object' || !(parts[i] in cur)) {
      return false;
    }
    if (typeof parts[i] !== 'string' && typeof parts[i] !== 'number') {
      throw new TypeError('Each segment of path to `unset()` must be a string or number, got ' + typeof parts[i]);
    }
    // Disallow any updates to __proto__ or special properties.
    if (ignoreProperties.indexOf(parts[i]) !== -1) {
      return false;
    }
    if (i === len - 1) {
      delete cur[parts[i]];
      return true;
    }
    cur = cur instanceof Map ? cur.get(parts[i]) : cur[parts[i]];
  }

  return true;
};

/**
 * Sets the `val` at the given `path` of object `o`.
 *
 * @param {String} path
 * @param {Anything} val
 * @param {Object} o
 * @param {String} [special] When this property name is present on any object in the path, walking will continue on the value of this property.
 * @param {Function} [map] Optional function which is passed each individual value before setting it. The value returned from `map` is used in the original values place.
 */

exports.set = function(path, val, o, special, map, _copying) {
  var lookup;

  if ('function' == typeof special) {
    if (special.length < 2) {
      map = special;
      special = undefined;
    } else {
      lookup = special;
      special = undefined;
    }
  }

  map || (map = K);

  var parts = 'string' == typeof path
    ? stringToParts(path)
    : path;

  if (!Array.isArray(parts)) {
    throw new TypeError('Invalid `path`. Must be either string or array');
  }

  if (null == o) return;

  for (var i = 0; i < parts.length; ++i) {
    if (typeof parts[i] !== 'string' && typeof parts[i] !== 'number') {
      throw new TypeError('Each segment of path to `set()` must be a string or number, got ' + typeof parts[i]);
    }
    // Silently ignore any updates to `__proto__`, these are potentially
    // dangerous if using mpath with unsanitized data.
    if (ignoreProperties.indexOf(parts[i]) !== -1) {
      return;
    }
  }

  // the existance of $ in a path tells us if the user desires
  // the copying of an array instead of setting each value of
  // the array to the one by one to matching positions of the
  // current array. Unless the user explicitly opted out by passing
  // false, see Automattic/mongoose#6273
  var copy = _copying || (/\$/.test(path) && _copying !== false),
      obj = o,
      part;

  for (var i = 0, len = parts.length - 1; i < len; ++i) {
    part = parts[i];

    if ('$' == part) {
      if (i == len - 1) {
        break;
      } else {
        continue;
      }
    }

    if (Array.isArray(obj) && !/^\d+$/.test(part)) {
      var paths = parts.slice(i);
      if (!copy && Array.isArray(val)) {
        for (var j = 0; j < obj.length && j < val.length; ++j) {
          // assignment of single values of array
          exports.set(paths, val[j], obj[j], special || lookup, map, copy);
        }
      } else {
        for (var j = 0; j < obj.length; ++j) {
          // assignment of entire value
          exports.set(paths, val, obj[j], special || lookup, map, copy);
        }
      }
      return;
    }

    if (lookup) {
      obj = lookup(obj, part);
    } else {
      var _to = special && obj[special] ? obj[special] : obj;
      obj = _to instanceof Map ?
        _to.get(part) :
        _to[part];
    }

    if (!obj) return;
  }

  // process the last property of the path

  part = parts[len];

  // use the special property if exists
  if (special && obj[special]) {
    obj = obj[special];
  }

  // set the value on the last branch
  if (Array.isArray(obj) && !/^\d+$/.test(part)) {
    if (!copy && Array.isArray(val)) {
      _setArray(obj, val, part, lookup, special, map);
    } else {
      for (var j = 0; j < obj.length; ++j) {
        var item = obj[j];
        if (item) {
          if (lookup) {
            lookup(item, part, map(val));
          } else {
            if (item[special]) item = item[special];
            item[part] = map(val);
          }
        }
      }
    }
  } else {
    if (lookup) {
      lookup(obj, part, map(val));
    } else if (obj instanceof Map) {
      obj.set(part, map(val));
    } else {
      obj[part] = map(val);
    }
  }
};

/*!
 * Split a string path into components delimited by '.' or
 * '[\d+]'
 *
 * #### Example:
 *     stringToParts('foo[0].bar.1'); // ['foo', '0', 'bar', '1']
 */

exports.stringToParts = stringToParts;

/*!
 * Recursively set nested arrays
 */

function _setArray(obj, val, part, lookup, special, map) {
  for (var item, j = 0; j < obj.length && j < val.length; ++j) {
    item = obj[j];
    if (Array.isArray(item) && Array.isArray(val[j])) {
      _setArray(item, val[j], part, lookup, special, map);
    } else if (item) {
      if (lookup) {
        lookup(item, part, map(val[j]));
      } else {
        if (item[special]) item = item[special];
        item[part] = map(val[j]);
      }
    }
  }
}

/*!
 * Returns the value passed to it.
 */

function K(v) {
  return v;
}
