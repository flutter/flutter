'use strict';

const get = require('../get');
const helperIsObject = require('../isObject');
const decorateDiscriminatorIndexOptions = require('../indexes/decorateDiscriminatorIndexOptions');

/**
 * Gather all indexes defined in the schema, including single nested,
 * document arrays, and embedded discriminators.
 * @param {Schema} schema
 * @api private
 */

module.exports = function getIndexes(schema) {
  let indexes = [];
  const schemaStack = new WeakMap();
  const indexTypes = schema.constructor.indexTypes;
  const indexByName = new Map();

  collectIndexes(schema);
  return indexes;

  function collectIndexes(schema, prefix, baseSchema) {
    // Ignore infinitely nested schemas, if we've already seen this schema
    // along this path there must be a cycle
    if (schemaStack.has(schema)) {
      return;
    }
    schemaStack.set(schema, true);

    prefix = prefix || '';
    const keys = Object.keys(schema.paths);

    for (const key of keys) {
      const path = schema.paths[key];
      if (baseSchema != null && baseSchema.paths[key]) {
        // If looking at an embedded discriminator schema, don't look at paths
        // that the
        continue;
      }

      if (path.$isMongooseDocumentArray || path.$isSingleNested) {
        if (get(path, 'options.excludeIndexes') !== true &&
            get(path, 'schemaOptions.excludeIndexes') !== true &&
            get(path, 'schema.options.excludeIndexes') !== true) {
          collectIndexes(path.schema, prefix + key + '.');
        }

        if (path.schema.discriminators != null) {
          const discriminators = path.schema.discriminators;
          const discriminatorKeys = Object.keys(discriminators);
          for (const discriminatorKey of discriminatorKeys) {
            collectIndexes(discriminators[discriminatorKey],
              prefix + key + '.', path.schema);
          }
        }

        // Retained to minimize risk of backwards breaking changes due to
        // gh-6113
        if (path.$isMongooseDocumentArray) {
          continue;
        }
      }

      const index = path._index || (path.caster && path.caster._index);

      if (index !== false && index !== null && index !== undefined) {
        const field = {};
        const isObject = helperIsObject(index);
        const options = isObject ? index : {};
        const type = typeof index === 'string' ? index :
          isObject ? index.type :
            false;

        if (type && indexTypes.indexOf(type) !== -1) {
          field[prefix + key] = type;
        } else if (options.text) {
          field[prefix + key] = 'text';
          delete options.text;
        } else {
          let isDescendingIndex = false;
          if (index === 'descending' || index === 'desc') {
            isDescendingIndex = true;
          } else if (index === 'ascending' || index === 'asc') {
            isDescendingIndex = false;
          } else {
            isDescendingIndex = Number(index) === -1;
          }

          field[prefix + key] = isDescendingIndex ? -1 : 1;
        }

        delete options.type;
        if (!('background' in options)) {
          options.background = true;
        }
        if (schema.options.autoIndex != null) {
          options._autoIndex = schema.options.autoIndex;
        }

        const indexName = options && options.name;

        if (typeof indexName === 'string') {
          if (indexByName.has(indexName)) {
            Object.assign(indexByName.get(indexName), field);
          } else {
            indexes.push([field, options]);
            indexByName.set(indexName, field);
          }
        } else {
          indexes.push([field, options]);
          indexByName.set(indexName, field);
        }
      }
    }

    schemaStack.delete(schema);

    if (prefix) {
      fixSubIndexPaths(schema, prefix);
    } else {
      schema._indexes.forEach(function(index) {
        const options = index[1];
        if (!('background' in options)) {
          options.background = true;
        }
        decorateDiscriminatorIndexOptions(schema, options);
      });
      indexes = indexes.concat(schema._indexes);
    }
  }

  /**
   * Checks for indexes added to subdocs using Schema.index().
   * These indexes need their paths prefixed properly.
   *
   * schema._indexes = [ [indexObj, options], [indexObj, options] ..]
   * @param {Schema} schema
   * @param {String} prefix
   * @api private
   */

  function fixSubIndexPaths(schema, prefix) {
    const subindexes = schema._indexes;
    const len = subindexes.length;
    for (let i = 0; i < len; ++i) {
      const indexObj = subindexes[i][0];
      const indexOptions = subindexes[i][1];
      const keys = Object.keys(indexObj);
      const klen = keys.length;
      const newindex = {};

      // use forward iteration, order matters
      for (let j = 0; j < klen; ++j) {
        const key = keys[j];
        newindex[prefix + key] = indexObj[key];
      }

      const newIndexOptions = Object.assign({}, indexOptions);
      if (indexOptions != null && indexOptions.partialFilterExpression != null) {
        newIndexOptions.partialFilterExpression = {};
        const partialFilterExpression = indexOptions.partialFilterExpression;
        for (const key of Object.keys(partialFilterExpression)) {
          newIndexOptions.partialFilterExpression[prefix + key] =
            partialFilterExpression[key];
        }
      }

      indexes.push([newindex, newIndexOptions]);
    }
  }
};
