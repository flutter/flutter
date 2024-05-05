'use strict';

/*!
 * ignore
 */

const queryOperations = Object.freeze([
  // Read
  'countDocuments',
  'distinct',
  'estimatedDocumentCount',
  'find',
  'findOne',
  // Update
  'findOneAndReplace',
  'findOneAndUpdate',
  'replaceOne',
  'updateMany',
  'updateOne',
  // Delete
  'deleteMany',
  'deleteOne',
  'findOneAndDelete'
]);

exports.queryOperations = queryOperations;

/*!
 * ignore
 */

const queryMiddlewareFunctions = queryOperations.concat([
  'validate'
]);

exports.queryMiddlewareFunctions = queryMiddlewareFunctions;
