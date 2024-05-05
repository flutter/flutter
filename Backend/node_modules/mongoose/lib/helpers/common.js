'use strict';

/*!
 * Module dependencies.
 */

const Binary = require('bson').Binary;
const isBsonType = require('./isBsonType');
const isMongooseObject = require('./isMongooseObject');
const MongooseError = require('../error');
const util = require('util');

exports.flatten = flatten;
exports.modifiedPaths = modifiedPaths;

/*!
 * ignore
 */

function flatten(update, path, options, schema) {
  let keys;
  if (update && isMongooseObject(update) && !Buffer.isBuffer(update)) {
    keys = Object.keys(update.toObject({ transform: false, virtuals: false }) || {});
  } else {
    keys = Object.keys(update || {});
  }

  const numKeys = keys.length;
  const result = {};
  path = path ? path + '.' : '';

  for (let i = 0; i < numKeys; ++i) {
    const key = keys[i];
    const val = update[key];
    result[path + key] = val;

    // Avoid going into mixed paths if schema is specified
    const keySchema = schema && schema.path && schema.path(path + key);
    const isNested = schema && schema.nested && schema.nested[path + key];
    if (keySchema && keySchema.instance === 'Mixed') continue;

    if (shouldFlatten(val)) {
      if (options && options.skipArrays && Array.isArray(val)) {
        continue;
      }
      const flat = flatten(val, path + key, options, schema);
      for (const k in flat) {
        result[k] = flat[k];
      }
      if (Array.isArray(val)) {
        result[path + key] = val;
      }
    }

    if (isNested) {
      const paths = Object.keys(schema.paths);
      for (const p of paths) {
        if (p.startsWith(path + key + '.') && !result.hasOwnProperty(p)) {
          result[p] = void 0;
        }
      }
    }
  }

  return result;
}

/*!
 * ignore
 */

function modifiedPaths(update, path, result, recursion = null) {
  if (update == null || typeof update !== 'object') {
    return;
  }

  if (recursion == null) {
    recursion = {
      raw: { update, path },
      trace: new WeakSet()
    };
  }

  if (recursion.trace.has(update)) {
    throw new MongooseError(`a circular reference in the update value, updateValue:
${util.inspect(recursion.raw.update, { showHidden: false, depth: 1 })}
updatePath: '${recursion.raw.path}'`);
  }
  recursion.trace.add(update);

  const keys = Object.keys(update || {});
  const numKeys = keys.length;
  result = result || {};
  path = path ? path + '.' : '';

  for (let i = 0; i < numKeys; ++i) {
    const key = keys[i];
    let val = update[key];

    const _path = path + key;
    result[_path] = true;
    if (!Buffer.isBuffer(val) && isMongooseObject(val)) {
      val = val.toObject({ transform: false, virtuals: false });
    }
    if (shouldFlatten(val)) {
      modifiedPaths(val, path + key, result, recursion);
    }
  }
  recursion.trace.delete(update);

  return result;
}

/*!
 * ignore
 */

function shouldFlatten(val) {
  return val &&
      typeof val === 'object' &&
      !(val instanceof Date) &&
      !isBsonType(val, 'ObjectId') &&
      (!Array.isArray(val) || val.length !== 0) &&
      !(val instanceof Buffer) &&
      !isBsonType(val, 'Decimal128') &&
      !(val instanceof Binary);
}
