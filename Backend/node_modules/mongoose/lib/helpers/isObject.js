'use strict';

/**
 * Determines if `arg` is an object.
 *
 * @param {Object|Array|String|Function|RegExp|any} arg
 * @api private
 * @return {Boolean}
 */

module.exports = function(arg) {
  return (
    Buffer.isBuffer(arg) ||
    Object.prototype.toString.call(arg) === '[object Object]'
  );
};
