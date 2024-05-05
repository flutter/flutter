'use strict';

/*!
 * ignore
 */

module.exports = function hasDollarKeys(obj) {

  if (typeof obj !== 'object' || obj === null) {
    return false;
  }

  const keys = Object.keys(obj);
  const len = keys.length;

  for (let i = 0; i < len; ++i) {
    if (keys[i][0] === '$') {
      return true;
    }
  }

  return false;
};
