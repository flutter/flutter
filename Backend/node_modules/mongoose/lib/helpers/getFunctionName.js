'use strict';

const functionNameRE = /^function\s*([^\s(]+)/;

module.exports = function(fn) {
  return (
    fn.name ||
    (fn.toString().trim().match(functionNameRE) || [])[1]
  );
};
