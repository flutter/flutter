'use strict';

const Decimal128Type = require('../types/decimal128');
const assert = require('assert');

module.exports = function castDecimal128(value) {
  if (value == null) {
    return value;
  }

  if (typeof value === 'object' && typeof value.$numberDecimal === 'string') {
    return Decimal128Type.fromString(value.$numberDecimal);
  }

  if (value instanceof Decimal128Type) {
    return value;
  }

  if (typeof value === 'string') {
    return Decimal128Type.fromString(value);
  }

  if (typeof Buffer === 'function' && Buffer.isBuffer(value)) {
    return new Decimal128Type(value);
  }
  if (typeof Uint8Array === 'function' && value instanceof Uint8Array) {
    return new Decimal128Type(value);
  }

  if (typeof value === 'number') {
    return Decimal128Type.fromString(String(value));
  }

  if (typeof value.valueOf === 'function' && typeof value.valueOf() === 'string') {
    return Decimal128Type.fromString(value.valueOf());
  }

  assert.ok(false);
};
