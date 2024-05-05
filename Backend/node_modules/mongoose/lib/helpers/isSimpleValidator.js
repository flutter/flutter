'use strict';

/**
 * Determines if `arg` is a flat object.
 *
 * @param {Object|Array|String|Function|RegExp|any} arg
 * @api private
 * @return {Boolean}
 */

module.exports = function isSimpleValidator(obj) {
  const keys = Object.keys(obj);
  let result = true;
  for (let i = 0, len = keys.length; i < len; ++i) {
    if (typeof obj[keys[i]] === 'object' && obj[keys[i]] !== null) {
      result = false;
      break;
    }
  }

  return result;
};
