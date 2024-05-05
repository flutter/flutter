'use strict';

/*!
 * ignore
 */

let driver = null;

module.exports.get = function() {
  return driver;
};

module.exports.set = function(v) {
  driver = v;
};
