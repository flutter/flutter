'use strict';

/**
 * Determines if `path2` is a subpath of or equal to `path1`
 *
 * @param {string} path1
 * @param {string} path2
 * @return {Boolean}
 * @api private
 */

module.exports = function isSubpath(path1, path2) {
  return path1 === path2 || path2.startsWith(path1 + '.');
};
