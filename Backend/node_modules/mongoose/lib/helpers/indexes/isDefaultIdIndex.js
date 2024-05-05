'use strict';

const get = require('../get');

module.exports = function isDefaultIdIndex(index) {
  if (Array.isArray(index)) {
    // Mongoose syntax
    const keys = Object.keys(index[0]);
    return keys.length === 1 && keys[0] === '_id' && index[0]._id !== 'hashed';
  }

  if (typeof index !== 'object') {
    return false;
  }

  const key = get(index, 'key', {});
  return Object.keys(key).length === 1 && key.hasOwnProperty('_id');
};
