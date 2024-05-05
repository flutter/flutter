'use strict';

const utils = require('../../utils');

const keysToSkip = new Set(['__index', '__parentArray', '_doc']);

/**
 * Using spread operator on a Mongoose document gives you a
 * POJO that has a tendency to cause infinite recursion. So
 * we use this function on `set()` to prevent that.
 */

module.exports = function handleSpreadDoc(v, includeExtraKeys) {
  if (utils.isPOJO(v) && v.$__ != null && v._doc != null) {
    if (includeExtraKeys) {
      const extraKeys = {};
      for (const key of Object.keys(v)) {
        if (typeof key === 'symbol') {
          continue;
        }
        if (key[0] === '$') {
          continue;
        }
        if (keysToSkip.has(key)) {
          continue;
        }
        extraKeys[key] = v[key];
      }
      return { ...v._doc, ...extraKeys };
    }
    return v._doc;
  }

  return v;
};
