'use strict';

/**
 * Creates an object that precomputes whether a given path has child fields in
 * the projection.
 *
 * #### Example:
 *
 *     const res = hasIncludedChildren({ 'a.b.c': 0 });
 *     res.a; // 1
 *     res['a.b']; // 1
 *     res['a.b.c']; // 1
 *     res['a.c']; // undefined
 *
 * @param {Object} fields
 * @api private
 */

module.exports = function hasIncludedChildren(fields) {
  const hasIncludedChildren = {};
  const keys = Object.keys(fields);

  for (const key of keys) {

    if (key.indexOf('.') === -1) {
      hasIncludedChildren[key] = 1;
      continue;
    }
    const parts = key.split('.');
    let c = parts[0];

    for (let i = 0; i < parts.length; ++i) {
      hasIncludedChildren[c] = 1;
      if (i + 1 < parts.length) {
        c = c + '.' + parts[i + 1];
      }
    }
  }

  return hasIncludedChildren;
};
