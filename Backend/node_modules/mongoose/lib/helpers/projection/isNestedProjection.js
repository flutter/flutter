'use strict';

module.exports = function isNestedProjection(val) {
  if (val == null || typeof val !== 'object') {
    return false;
  }
  return val.$slice == null && val.$elemMatch == null && val.$meta == null && val.$ == null;
};
