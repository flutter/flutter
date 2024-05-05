'use strict';

const trustedSymbol = Symbol('mongoose#trustedSymbol');

exports.trustedSymbol = trustedSymbol;

exports.trusted = function trusted(obj) {
  if (obj == null || typeof obj !== 'object') {
    return obj;
  }
  obj[trustedSymbol] = true;
  return obj;
};
