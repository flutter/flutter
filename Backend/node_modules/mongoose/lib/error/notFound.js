'use strict';

/*!
 * Module dependencies.
 */

const MongooseError = require('./');
const util = require('util');

class DocumentNotFoundError extends MongooseError {
  /**
   * OverwriteModel Error constructor.
   * @api private
   */
  constructor(filter, model, numAffected, result) {
    let msg;
    const messages = MongooseError.messages;
    if (messages.DocumentNotFoundError != null) {
      msg = typeof messages.DocumentNotFoundError === 'function' ?
        messages.DocumentNotFoundError(filter, model) :
        messages.DocumentNotFoundError;
    } else {
      msg = 'No document found for query "' + util.inspect(filter) +
        '" on model "' + model + '"';
    }

    super(msg);

    this.result = result;
    this.numAffected = numAffected;
    this.filter = filter;
    // Backwards compat
    this.query = filter;
  }
}

Object.defineProperty(DocumentNotFoundError.prototype, 'name', {
  value: 'DocumentNotFoundError'
});

/*!
 * exports
 */

module.exports = DocumentNotFoundError;
