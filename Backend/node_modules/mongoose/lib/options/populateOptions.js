'use strict';

const clone = require('../helpers/clone');

class PopulateOptions {
  constructor(obj) {
    this._docs = {};
    this._childDocs = [];

    if (obj == null) {
      return;
    }
    obj = clone(obj);
    Object.assign(this, obj);
    if (typeof obj.subPopulate === 'object') {
      this.populate = obj.subPopulate;
    }


    if (obj.perDocumentLimit != null && obj.limit != null) {
      throw new Error('Can not use `limit` and `perDocumentLimit` at the same time. Path: `' + obj.path + '`.');
    }
  }
}

/**
 * The connection used to look up models by name. If not specified, Mongoose
 * will default to using the connection associated with the model in
 * `PopulateOptions#model`.
 *
 * @memberOf PopulateOptions
 * @property {Connection} connection
 * @api public
 */

module.exports = PopulateOptions;
