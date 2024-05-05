'use strict';

module.exports = function once(fn) {
  let called = false;
  return function() {
    if (called) {
      return;
    }
    called = true;
    return fn.apply(null, arguments);
  };
};
