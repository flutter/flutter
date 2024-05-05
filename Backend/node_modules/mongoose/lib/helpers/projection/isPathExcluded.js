'use strict';

const isDefiningProjection = require('./isDefiningProjection');

/**
 * Determines if `path` is excluded by `projection`
 *
 * @param {Object} projection
 * @param {String} path
 * @return {Boolean}
 * @api private
 */

module.exports = function isPathExcluded(projection, path) {
  if (projection == null) {
    return false;
  }

  if (path === '_id') {
    return projection._id === 0;
  }

  const paths = Object.keys(projection);
  let type = null;

  for (const _path of paths) {
    if (isDefiningProjection(projection[_path])) {
      type = projection[path] === 1 ? 'inclusive' : 'exclusive';
      break;
    }
  }

  if (type === 'inclusive') {
    return projection[path] !== 1;
  }
  if (type === 'exclusive') {
    return projection[path] === 0;
  }
  return false;
};
