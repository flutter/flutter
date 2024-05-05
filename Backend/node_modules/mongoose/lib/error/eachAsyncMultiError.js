/*!
 * Module dependencies.
 */

'use strict';

const MongooseError = require('./');


/**
 * If `eachAsync()` is called with `continueOnError: true`, there can be
 * multiple errors. This error class contains an `errors` property, which
 * contains an array of all errors that occurred in `eachAsync()`.
 *
 * @api private
 */

class EachAsyncMultiError extends MongooseError {
  /**
   * @param {String} connectionString
   */
  constructor(errors) {
    let preview = errors.map(e => e.message).join(', ');
    if (preview.length > 50) {
      preview = preview.slice(0, 50) + '...';
    }
    super(`eachAsync() finished with ${errors.length} errors: ${preview}`);

    this.errors = errors;
  }
}

Object.defineProperty(EachAsyncMultiError.prototype, 'name', {
  value: 'EachAsyncMultiError'
});

/*!
 * exports
 */

module.exports = EachAsyncMultiError;
