'use strict';

const castBoolean = require('../../cast/boolean');

/*!
 * ignore
 */

module.exports = function(val) {
  const path = this != null ? this.path : null;
  return castBoolean(val, path);
};
