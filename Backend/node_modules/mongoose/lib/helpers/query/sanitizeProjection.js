'use strict';

module.exports = function sanitizeProjection(projection) {
  if (projection == null) {
    return;
  }

  const keys = Object.keys(projection);
  for (let i = 0; i < keys.length; ++i) {
    if (typeof projection[keys[i]] === 'string') {
      projection[keys[i]] = 1;
    }
  }
};
