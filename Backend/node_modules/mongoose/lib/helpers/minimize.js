'use strict';

const { isPOJO } = require('../utils');

module.exports = minimize;

/**
 * Minimizes an object, removing undefined values and empty objects
 *
 * @param {Object} object to minimize
 * @return {Object|undefined}
 * @api private
 */

function minimize(obj) {
  const keys = Object.keys(obj);
  let i = keys.length;
  let hasKeys;
  let key;
  let val;

  while (i--) {
    key = keys[i];
    val = obj[key];

    if (isPOJO(val)) {
      obj[key] = minimize(val);
    }

    if (undefined === obj[key]) {
      delete obj[key];
      continue;
    }

    hasKeys = true;
  }

  return hasKeys
    ? obj
    : undefined;
}
