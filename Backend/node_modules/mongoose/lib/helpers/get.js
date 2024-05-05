'use strict';

/**
 * Simplified lodash.get to work around the annoying null quirk. See:
 * https://github.com/lodash/lodash/issues/3659
 * @api private
 */

module.exports = function get(obj, path, def) {
  let parts;
  let isPathArray = false;
  if (typeof path === 'string') {
    if (path.indexOf('.') === -1) {
      const _v = getProperty(obj, path);
      if (_v == null) {
        return def;
      }
      return _v;
    }

    parts = path.split('.');
  } else {
    isPathArray = true;
    parts = path;

    if (parts.length === 1) {
      const _v = getProperty(obj, parts[0]);
      if (_v == null) {
        return def;
      }
      return _v;
    }
  }
  let rest = path;
  let cur = obj;
  for (const part of parts) {
    if (cur == null) {
      return def;
    }

    // `lib/cast.js` depends on being able to get dotted paths in updates,
    // like `{ $set: { 'a.b': 42 } }`
    if (!isPathArray && cur[rest] != null) {
      return cur[rest];
    }

    cur = getProperty(cur, part);

    if (!isPathArray) {
      rest = rest.substr(part.length + 1);
    }
  }

  return cur == null ? def : cur;
};

function getProperty(obj, prop) {
  if (obj == null) {
    return obj;
  }
  if (obj instanceof Map) {
    return obj.get(prop);
  }
  return obj[prop];
}
