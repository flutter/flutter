'use strict';

module.exports = function isAsyncFunction(v) {
  return (
    typeof v === 'function' &&
    v.constructor &&
    v.constructor.name === 'AsyncFunction'
  );
};
