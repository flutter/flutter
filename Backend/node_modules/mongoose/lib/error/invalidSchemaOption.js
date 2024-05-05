
/*!
 * Module dependencies.
 */

'use strict';

const MongooseError = require('./');

class InvalidSchemaOptionError extends MongooseError {
  /**
   * InvalidSchemaOption Error constructor.
   * @param {String} name
   * @api private
   */
  constructor(name, option) {
    const msg = `Cannot create use schema for property "${name}" because the schema has the ${option} option enabled.`;
    super(msg);
  }
}

Object.defineProperty(InvalidSchemaOptionError.prototype, 'name', {
  value: 'InvalidSchemaOptionError'
});

/*!
 * exports
 */

module.exports = InvalidSchemaOptionError;
