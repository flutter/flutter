'use strict';

const CastError = require('../error/cast');

/**
 * Given a value, cast it to a string, or throw a `CastError` if the value
 * cannot be casted. `null` and `undefined` are considered valid.
 *
 * @param {Any} value
 * @param {String} [path] optional the path to set on the CastError
 * @return {string|null|undefined}
 * @throws {CastError}
 * @api private
 */

module.exports = function castString(value, path) {
  // If null or undefined
  if (value == null) {
    return value;
  }

  // handle documents being passed
  if (value._id && typeof value._id === 'string') {
    return value._id;
  }

  // Re: gh-647 and gh-3030, we're ok with casting using `toString()`
  // **unless** its the default Object.toString, because "[object Object]"
  // doesn't really qualify as useful data
  if (value.toString &&
      value.toString !== Object.prototype.toString &&
      !Array.isArray(value)) {
    return value.toString();
  }

  throw new CastError('string', value, path);
};
