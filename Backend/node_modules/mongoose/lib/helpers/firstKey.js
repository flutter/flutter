'use strict';

module.exports = function firstKey(obj) {
  if (obj == null) {
    return null;
  }
  return Object.keys(obj)[0];
};
