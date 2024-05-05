'use strict';

const isBsonType = require('../isBsonType');

module.exports = function areDiscriminatorValuesEqual(a, b) {
  if (typeof a === 'string' && typeof b === 'string') {
    return a === b;
  }
  if (typeof a === 'number' && typeof b === 'number') {
    return a === b;
  }
  if (isBsonType(a, 'ObjectId') && isBsonType(b, 'ObjectId')) {
    return a.toString() === b.toString();
  }
  return false;
};
