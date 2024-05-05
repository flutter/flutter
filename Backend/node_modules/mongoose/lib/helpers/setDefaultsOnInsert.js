'use strict';
const modifiedPaths = require('./common').modifiedPaths;
const get = require('./get');

/**
 * Applies defaults to update and findOneAndUpdate operations.
 *
 * @param {Object} filter
 * @param {Schema} schema
 * @param {Object} castedDoc
 * @param {Object} options
 * @method setDefaultsOnInsert
 * @api private
 */

module.exports = function(filter, schema, castedDoc, options) {
  options = options || {};

  const shouldSetDefaultsOnInsert =
    options.setDefaultsOnInsert != null ?
      options.setDefaultsOnInsert :
      schema.base.options.setDefaultsOnInsert;

  if (!options.upsert || shouldSetDefaultsOnInsert === false) {
    return castedDoc;
  }

  const keys = Object.keys(castedDoc || {});
  const updatedKeys = {};
  const updatedValues = {};
  const numKeys = keys.length;
  const modified = {};

  let hasDollarUpdate = false;

  for (let i = 0; i < numKeys; ++i) {
    if (keys[i].startsWith('$')) {
      modifiedPaths(castedDoc[keys[i]], '', modified);
      hasDollarUpdate = true;
    }
  }

  if (!hasDollarUpdate) {
    modifiedPaths(castedDoc, '', modified);
  }

  const paths = Object.keys(filter);
  const numPaths = paths.length;
  for (let i = 0; i < numPaths; ++i) {
    const path = paths[i];
    const condition = filter[path];
    if (condition && typeof condition === 'object') {
      const conditionKeys = Object.keys(condition);
      const numConditionKeys = conditionKeys.length;
      let hasDollarKey = false;
      for (let j = 0; j < numConditionKeys; ++j) {
        if (conditionKeys[j].startsWith('$')) {
          hasDollarKey = true;
          break;
        }
      }
      if (hasDollarKey) {
        continue;
      }
    }
    updatedKeys[path] = true;
    modified[path] = true;
  }

  if (options && options.overwrite && !hasDollarUpdate) {
    // Defaults will be set later, since we're overwriting we'll cast
    // the whole update to a document
    return castedDoc;
  }

  schema.eachPath(function(path, schemaType) {
    // Skip single nested paths if underneath a map
    if (schemaType.path === '_id' && schemaType.options.auto) {
      return;
    }
    const def = schemaType.getDefault(null, true);
    if (isModified(modified, path)) {
      return;
    }
    if (typeof def === 'undefined') {
      return;
    }
    if (schemaType.splitPath().includes('$*')) {
      // Skip defaults underneath maps. We should never do `$setOnInsert` on a path with `$*`
      return;
    }

    castedDoc = castedDoc || {};
    castedDoc.$setOnInsert = castedDoc.$setOnInsert || {};
    if (get(castedDoc, path) == null) {
      castedDoc.$setOnInsert[path] = def;
    }
    updatedValues[path] = def;
  });

  return castedDoc;
};

function isModified(modified, path) {
  if (modified[path]) {
    return true;
  }

  // Is any parent path of `path` modified?
  const sp = path.split('.');
  let cur = sp[0];
  for (let i = 1; i < sp.length; ++i) {
    if (modified[cur]) {
      return true;
    }
    cur += '.' + sp[i];
  }

  // Is any child of `path` modified?
  const modifiedKeys = Object.keys(modified);
  if (modifiedKeys.length) {
    const parentPath = path + '.';

    for (const modifiedPath of modifiedKeys) {
      if (modifiedPath.slice(0, path.length + 1) === parentPath) {
        return true;
      }
    }
  }

  return false;
}
