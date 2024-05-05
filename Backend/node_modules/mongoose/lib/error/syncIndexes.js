'use strict';

/*!
 * Module dependencies.
 */

const MongooseError = require('./mongooseError');

/**
 * SyncIndexes Error constructor.
 *
 * @param {String} message
 * @param {String} errorsMap
 * @inherits MongooseError
 * @api private
 */

class SyncIndexesError extends MongooseError {
  constructor(message, errorsMap) {
    super(message);
    this.errors = errorsMap;
  }
}

Object.defineProperty(SyncIndexesError.prototype, 'name', {
  value: 'SyncIndexesError'
});


module.exports = SyncIndexesError;
