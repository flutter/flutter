
/*!
 * Module dependencies.
 */

'use strict';

const MongooseError = require('./');

class MissingSchemaError extends MongooseError {
  /**
   * MissingSchema Error constructor.
   * @param {String} name
   * @api private
   */
  constructor(name) {
    const msg = 'Schema hasn\'t been registered for model "' + name + '".\n'
            + 'Use mongoose.model(name, schema)';
    super(msg);
  }
}

Object.defineProperty(MissingSchemaError.prototype, 'name', {
  value: 'MissingSchemaError'
});

/*!
 * exports
 */

module.exports = MissingSchemaError;
