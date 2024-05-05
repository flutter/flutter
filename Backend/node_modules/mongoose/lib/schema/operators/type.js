'use strict';

/*!
 * ignore
 */

module.exports = function(val) {
  if (Array.isArray(val)) {
    if (!val.every(v => typeof v === 'number' || typeof v === 'string')) {
      throw new Error('$type array values must be strings or numbers');
    }
    return val;
  }

  if (typeof val !== 'number' && typeof val !== 'string') {
    throw new Error('$type parameter must be number, string, or array of numbers and strings');
  }

  return val;
};
