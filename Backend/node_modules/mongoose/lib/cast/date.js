'use strict';

const assert = require('assert');

module.exports = function castDate(value) {
  // Support empty string because of empty form values. Originally introduced
  // in https://github.com/Automattic/mongoose/commit/efc72a1898fc3c33a319d915b8c5463a22938dfe
  if (value == null || value === '') {
    return null;
  }

  if (value instanceof Date) {
    assert.ok(!isNaN(value.valueOf()));

    return value;
  }

  let date;

  assert.ok(typeof value !== 'boolean');

  if (value instanceof Number || typeof value === 'number') {
    date = new Date(value);
  } else if (typeof value === 'string' && !isNaN(Number(value)) && (Number(value) >= 275761 || Number(value) < -271820)) {
    // string representation of milliseconds take this path
    date = new Date(Number(value));
  } else if (typeof value.valueOf === 'function') {
    // support for moment.js. This is also the path strings will take because
    // strings have a `valueOf()`
    date = new Date(value.valueOf());
  } else {
    // fallback
    date = new Date(value);
  }

  if (!isNaN(date.valueOf())) {
    return date;
  }

  assert.ok(false);
};
