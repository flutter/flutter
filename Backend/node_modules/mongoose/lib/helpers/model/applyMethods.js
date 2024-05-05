'use strict';

const get = require('../get');
const utils = require('../../utils');

/**
 * Register methods for this model
 *
 * @param {Model} model
 * @param {Schema} schema
 * @api private
 */

module.exports = function applyMethods(model, schema) {
  const Model = require('../../model');

  function apply(method, schema) {
    Object.defineProperty(model.prototype, method, {
      get: function() {
        const h = {};
        for (const k in schema.methods[method]) {
          h[k] = schema.methods[method][k].bind(this);
        }
        return h;
      },
      configurable: true
    });
  }
  for (const method of Object.keys(schema.methods)) {
    const fn = schema.methods[method];
    if (schema.tree.hasOwnProperty(method)) {
      throw new Error('You have a method and a property in your schema both ' +
        'named "' + method + '"');
    }

    // Avoid making custom methods if user sets a method to itself, e.g.
    // `schema.method(save, Document.prototype.save)`. Can happen when
    // calling `loadClass()` with a class that `extends Document`. See gh-12254
    if (typeof fn === 'function' &&
        Model.prototype[method] === fn) {
      delete schema.methods[method];
      continue;
    }

    if (schema.reserved[method] &&
        !get(schema, `methodOptions.${method}.suppressWarning`, false)) {
      utils.warn(`mongoose: the method name "${method}" is used by mongoose ` +
        'internally, overwriting it may cause bugs. If you\'re sure you know ' +
        'what you\'re doing, you can suppress this error by using ' +
        `\`schema.method('${method}', fn, { suppressWarning: true })\`.`);
    }
    if (typeof fn === 'function') {
      model.prototype[method] = fn;
    } else {
      apply(method, schema);
    }
  }

  // Recursively call `applyMethods()` on child schemas
  model.$appliedMethods = true;
  for (const key of Object.keys(schema.paths)) {
    const type = schema.paths[key];
    if (type.$isSingleNested && !type.caster.$appliedMethods) {
      applyMethods(type.caster, type.schema);
    }
    if (type.$isMongooseDocumentArray && !type.Constructor.$appliedMethods) {
      applyMethods(type.Constructor, type.schema);
    }
  }
};
