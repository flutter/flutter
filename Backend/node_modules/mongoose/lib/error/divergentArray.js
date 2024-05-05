
/*!
 * Module dependencies.
 */

'use strict';

const MongooseError = require('./');

class DivergentArrayError extends MongooseError {
  /**
   * DivergentArrayError constructor.
   * @param {Array<String>} paths
   * @api private
   */
  constructor(paths) {
    const msg = 'For your own good, using `document.save()` to update an array '
            + 'which was selected using an $elemMatch projection OR '
            + 'populated using skip, limit, query conditions, or exclusion of '
            + 'the _id field when the operation results in a $pop or $set of '
            + 'the entire array is not supported. The following '
            + 'path(s) would have been modified unsafely:\n'
            + '  ' + paths.join('\n  ') + '\n'
            + 'Use Model.updateOne() to update these arrays instead.';
    // TODO write up a docs page (FAQ) and link to it
    super(msg);
  }
}

Object.defineProperty(DivergentArrayError.prototype, 'name', {
  value: 'DivergentArrayError'
});

/*!
 * exports
 */

module.exports = DivergentArrayError;
