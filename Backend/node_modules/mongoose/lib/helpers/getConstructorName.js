'use strict';

/**
 * If `val` is an object, returns constructor name, if possible. Otherwise returns undefined.
 * @api private
 */

module.exports = function getConstructorName(val) {
  if (val == null) {
    return void 0;
  }
  if (typeof val.constructor !== 'function') {
    return void 0;
  }
  return val.constructor.name;
};
