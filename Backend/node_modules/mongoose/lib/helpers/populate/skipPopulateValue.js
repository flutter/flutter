'use strict';

module.exports = function SkipPopulateValue(val) {
  if (!(this instanceof SkipPopulateValue)) {
    return new SkipPopulateValue(val);
  }

  this.val = val;
  return this;
};
