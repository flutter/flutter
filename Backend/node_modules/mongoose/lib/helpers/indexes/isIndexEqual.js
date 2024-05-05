'use strict';

const get = require('../get');
const utils = require('../../utils');
/**
 * Given a Mongoose index definition (key + options objects) and a MongoDB server
 * index definition, determine if the two indexes are equal.
 *
 * @param {Object} schemaIndexKeysObject the Mongoose index spec
 * @param {Object} options the Mongoose index definition's options
 * @param {Object} dbIndex the index in MongoDB as returned by `listIndexes()`
 * @api private
 */

module.exports = function isIndexEqual(schemaIndexKeysObject, options, dbIndex) {
  // Special case: text indexes have a special format in the db. For example,
  // `{ name: 'text' }` becomes:
  // {
  //   v: 2,
  //   key: { _fts: 'text', _ftsx: 1 },
  //   name: 'name_text',
  //   ns: 'test.tests',
  //   background: true,
  //   weights: { name: 1 },
  //   default_language: 'english',
  //   language_override: 'language',
  //   textIndexVersion: 3
  // }
  if (dbIndex.textIndexVersion != null) {
    delete dbIndex.key._fts;
    delete dbIndex.key._ftsx;
    const weights = { ...dbIndex.weights, ...dbIndex.key };
    if (Object.keys(weights).length !== Object.keys(schemaIndexKeysObject).length) {
      return false;
    }
    for (const prop of Object.keys(weights)) {
      if (!(prop in schemaIndexKeysObject)) {
        return false;
      }
      const weight = weights[prop];
      if (weight !== get(options, 'weights.' + prop) && !(weight === 1 && get(options, 'weights.' + prop) == null)) {
        return false;
      }
    }

    if (options['default_language'] !== dbIndex['default_language']) {
      return dbIndex['default_language'] === 'english' && options['default_language'] == null;
    }

    return true;
  }

  const optionKeys = [
    'unique',
    'partialFilterExpression',
    'sparse',
    'expireAfterSeconds',
    'collation'
  ];
  for (const key of optionKeys) {
    if (!(key in options) && !(key in dbIndex)) {
      continue;
    }
    if (key === 'collation') {
      if (options[key] == null || dbIndex[key] == null) {
        return options[key] == null && dbIndex[key] == null;
      }
      const definedKeys = Object.keys(options.collation);
      const schemaCollation = options.collation;
      const dbCollation = dbIndex.collation;
      for (const opt of definedKeys) {
        if (get(schemaCollation, opt) !== get(dbCollation, opt)) {
          return false;
        }
      }
    } else if (!utils.deepEqual(options[key], dbIndex[key])) {
      return false;
    }
  }

  const schemaIndexKeys = Object.keys(schemaIndexKeysObject);
  const dbIndexKeys = Object.keys(dbIndex.key);
  if (schemaIndexKeys.length !== dbIndexKeys.length) {
    return false;
  }
  for (let i = 0; i < schemaIndexKeys.length; ++i) {
    if (schemaIndexKeys[i] !== dbIndexKeys[i]) {
      return false;
    }
    if (!utils.deepEqual(schemaIndexKeysObject[schemaIndexKeys[i]], dbIndex.key[dbIndexKeys[i]])) {
      return false;
    }
  }

  return true;
};
