'use strict';

const specialProperties = require('../specialProperties');


module.exports = function setDottedPath(obj, path, val) {
  if (path.indexOf('.') === -1) {
    if (specialProperties.has(path)) {
      return;
    }

    obj[path] = val;
    return;
  }
  const parts = path.split('.');

  const last = parts.pop();
  let cur = obj;
  for (const part of parts) {
    if (specialProperties.has(part)) {
      continue;
    }
    if (cur[part] == null) {
      cur[part] = {};
    }

    cur = cur[part];
  }

  if (!specialProperties.has(last)) {
    cur[last] = val;
  }
};
