'use strict';

const CastError = require('../error/cast');

/**
 * Given a value, cast it to a boolean, or throw a `CastError` if the value
 * cannot be casted. `null` and `undefined` are considered valid.
 *
 * @param {Any} value
 * @param {String} [path] optional the path to set on the CastError
 * @return {Boolean|null|undefined}
 * @throws {CastError} if `value` is not one of the allowed values
 * @api private
 */

module.exports = function castBoolean(value, path) {
  if (module.exports.convertToTrue.has(value)) {
    return true;
  }
  if (module.exports.convertToFalse.has(value)) {
    return false;
  }

  if (value == null) {
    return value;
  }

  throw new CastError('boolean', value, path);
};

module.exports.convertToTrue = new Set([true, 'true', 1, '1', 'yes']);
module.exports.convertToFalse = new Set([false, 'false', 0, '0', 'no']);
