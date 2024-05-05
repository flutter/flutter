'use strict';

/*!
 * ignore
 */

class MongooseError extends Error { }

Object.defineProperty(MongooseError.prototype, 'name', {
  value: 'MongooseError'
});

module.exports = MongooseError;
