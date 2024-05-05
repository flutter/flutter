/*!
 * Module dependencies.
 */

'use strict';

const MongooseError = require('./');

class ObjectParameterError extends MongooseError {
  /**
   * Constructor for errors that happen when a parameter that's expected to be
   * an object isn't an object
   *
   * @param {Any} value
   * @param {String} paramName
   * @param {String} fnName
   * @api private
   */
  constructor(value, paramName, fnName) {
    super('Parameter "' + paramName + '" to ' + fnName +
      '() must be an object, got "' + value.toString() + '" (type ' + typeof value + ')');
  }
}


Object.defineProperty(ObjectParameterError.prototype, 'name', {
  value: 'ObjectParameterError'
});

module.exports = ObjectParameterError;
