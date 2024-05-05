'use strict';

const _modifiedPaths = require('../common').modifiedPaths;

/**
 * Given an update document with potential update operators (`$set`, etc.)
 * returns an object whose keys are the directly modified paths.
 *
 * If there are any top-level keys that don't start with `$`, we assume those
 * will get wrapped in a `$set`. The Mongoose Query is responsible for wrapping
 * top-level keys in `$set`.
 *
 * @param {Object} update
 * @return {Object} modified
 */

module.exports = function modifiedPaths(update) {
  const keys = Object.keys(update);
  const res = {};

  const withoutDollarKeys = {};
  for (const key of keys) {
    if (key.startsWith('$')) {
      _modifiedPaths(update[key], '', res);
      continue;
    }
    withoutDollarKeys[key] = update[key];
  }

  _modifiedPaths(withoutDollarKeys, '', res);

  return res;
};
