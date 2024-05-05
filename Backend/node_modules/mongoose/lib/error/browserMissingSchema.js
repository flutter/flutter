/*!
 * Module dependencies.
 */

'use strict';

const MongooseError = require('./');


class MissingSchemaError extends MongooseError {
  /**
   * MissingSchema Error constructor.
   */
  constructor() {
    super('Schema hasn\'t been registered for document.\n'
      + 'Use mongoose.Document(name, schema)');
  }
}

Object.defineProperty(MissingSchemaError.prototype, 'name', {
  value: 'MongooseError'
});

/*!
 * exports
 */

module.exports = MissingSchemaError;
