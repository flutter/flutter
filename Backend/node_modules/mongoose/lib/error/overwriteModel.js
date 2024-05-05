
/*!
 * Module dependencies.
 */

'use strict';

const MongooseError = require('./');


class OverwriteModelError extends MongooseError {
  /**
   * OverwriteModel Error constructor.
   * @param {String} name
   * @api private
   */
  constructor(name) {
    super('Cannot overwrite `' + name + '` model once compiled.');
  }
}

Object.defineProperty(OverwriteModelError.prototype, 'name', {
  value: 'OverwriteModelError'
});

/*!
 * exports
 */

module.exports = OverwriteModelError;
