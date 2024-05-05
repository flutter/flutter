/**
 * ObjectId type constructor
 *
 * #### Example:
 *
 *     const id = new mongoose.Types.ObjectId;
 *
 * @constructor ObjectId
 */

'use strict';

const ObjectId = require('bson').ObjectId;
const objectIdSymbol = require('../helpers/symbols').objectIdSymbol;

/**
 * Getter for convenience with populate, see gh-6115
 * @api private
 */

Object.defineProperty(ObjectId.prototype, '_id', {
  enumerable: false,
  configurable: true,
  get: function() {
    return this;
  }
});

/*!
 * Convenience `valueOf()` to allow comparing ObjectIds using double equals re: gh-7299
 */

if (!ObjectId.prototype.hasOwnProperty('valueOf')) {
  ObjectId.prototype.valueOf = function objectIdValueOf() {
    return this.toString();
  };
}

ObjectId.prototype[objectIdSymbol] = true;

module.exports = ObjectId;
