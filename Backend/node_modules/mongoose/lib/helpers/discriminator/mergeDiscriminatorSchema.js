'use strict';
const schemaMerge = require('../schema/merge');
const specialProperties = require('../../helpers/specialProperties');
const isBsonType = require('../../helpers/isBsonType');
const ObjectId = require('../../types/objectid');
const isObject = require('../../helpers/isObject');
/**
 * Merges `from` into `to` without overwriting existing properties.
 *
 * @param {Object} to
 * @param {Object} from
 * @param {String} [path]
 * @api private
 */

module.exports = function mergeDiscriminatorSchema(to, from, path, seen) {
  const keys = Object.keys(from);
  let i = 0;
  const len = keys.length;
  let key;

  path = path || '';
  seen = seen || new WeakSet();

  if (seen.has(from)) {
    return;
  }
  seen.add(from);

  while (i < len) {
    key = keys[i++];
    if (!path) {
      if (key === 'discriminators' ||
        key === 'base' ||
        key === '_applyDiscriminators' ||
        key === '_userProvidedOptions' ||
        key === 'options' ||
        key === 'tree') {
        continue;
      }
    }
    if (path === 'tree' && from != null && from.instanceOfSchema) {
      continue;
    }
    if (specialProperties.has(key)) {
      continue;
    }
    if (to[key] == null) {
      to[key] = from[key];
    } else if (isObject(from[key])) {
      if (!isObject(to[key])) {
        to[key] = {};
      }
      if (from[key] != null) {
        // Skip merging schemas if we're creating a discriminator schema and
        // base schema has a given path as a single nested but discriminator schema
        // has the path as a document array, or vice versa (gh-9534)
        if ((from[key].$isSingleNested && to[key].$isMongooseDocumentArray) ||
              (from[key].$isMongooseDocumentArray && to[key].$isSingleNested) ||
              (from[key].$isMongooseDocumentArrayElement && to[key].$isMongooseDocumentArrayElement)) {
          continue;
        } else if (from[key].instanceOfSchema) {
          if (to[key].instanceOfSchema) {
            schemaMerge(to[key], from[key].clone(), true);
          } else {
            to[key] = from[key].clone();
          }
          continue;
        } else if (isBsonType(from[key], 'ObjectId')) {
          to[key] = new ObjectId(from[key]);
          continue;
        }
      }
      mergeDiscriminatorSchema(to[key], from[key], path ? path + '.' + key : key, seen);
    }
  }

  if (from != null && from.instanceOfSchema) {
    to.tree = Object.assign({}, from.tree, to.tree);
  }
};
