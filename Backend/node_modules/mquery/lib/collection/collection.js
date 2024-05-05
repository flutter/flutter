'use strict';

/**
 * methods a collection must implement
 */

const methods = [
  'find',
  'findOne',
  'updateMany',
  'updateOne',
  'replaceOne',
  'count',
  'distinct',
  'findOneAndDelete',
  'findOneAndUpdate',
  'aggregate',
  'findCursor',
  'deleteOne',
  'deleteMany'
];

/**
 * Collection base class from which implementations inherit
 */

function Collection() {}

for (let i = 0, len = methods.length; i < len; ++i) {
  const method = methods[i];
  Collection.prototype[method] = notImplemented(method);
}

module.exports = exports = Collection;
Collection.methods = methods;

/**
 * creates a function which throws an implementation error
 */

function notImplemented(method) {
  return function() {
    throw new Error('collection.' + method + ' not implemented');
  };
}
