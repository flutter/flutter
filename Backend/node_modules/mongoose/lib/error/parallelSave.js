'use strict';

/*!
 * Module dependencies.
 */

const MongooseError = require('./');

class ParallelSaveError extends MongooseError {
  /**
   * ParallelSave Error constructor.
   *
   * @param {Document} doc
   * @api private
   */
  constructor(doc) {
    const msg = 'Can\'t save() the same doc multiple times in parallel. Document: ';
    super(msg + doc._id);
  }
}

Object.defineProperty(ParallelSaveError.prototype, 'name', {
  value: 'ParallelSaveError'
});

/*!
 * exports
 */

module.exports = ParallelSaveError;
