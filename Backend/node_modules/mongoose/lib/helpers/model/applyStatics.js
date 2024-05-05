'use strict';

/**
 * Register statics for this model
 * @param {Model} model
 * @param {Schema} schema
 * @api private
 */
module.exports = function applyStatics(model, schema) {
  for (const i in schema.statics) {
    model[i] = schema.statics[i];
  }
};
