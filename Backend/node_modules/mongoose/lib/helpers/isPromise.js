'use strict';
function isPromise(val) {
  return !!val && (typeof val === 'object' || typeof val === 'function') && typeof val.then === 'function';
}

module.exports = isPromise;
