/*!
 * Module dependencies.
 */

'use strict';

const MongooseError = require('./');


/**
 * If `bulkWrite()` or `insertMany()` has validation errors, but
 * all valid operations succeed, and 'throwOnValidationError' is true,
 * Mongoose will throw this error.
 *
 * @api private
 */

class MongooseBulkWriteError extends MongooseError {
  constructor(validationErrors, results, rawResult, operation) {
    let preview = validationErrors.map(e => e.message).join(', ');
    if (preview.length > 200) {
      preview = preview.slice(0, 200) + '...';
    }
    super(`${operation} failed with ${validationErrors.length} Mongoose validation errors: ${preview}`);

    this.validationErrors = validationErrors;
    this.results = results;
    this.rawResult = rawResult;
    this.operation = operation;
  }
}

Object.defineProperty(MongooseBulkWriteError.prototype, 'name', {
  value: 'MongooseBulkWriteError'
});

/*!
 * exports
 */

module.exports = MongooseBulkWriteError;
