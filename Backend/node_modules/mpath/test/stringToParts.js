'use strict';

const assert = require('assert');
const stringToParts = require('../lib/stringToParts');

describe('stringToParts', function() {
  it('handles brackets for numbers', function() {
    assert.deepEqual(stringToParts('list[0].name'), ['list', '0', 'name']);
    assert.deepEqual(stringToParts('list[0][1].name'), ['list', '0', '1', 'name']);
  });

  it('handles dot notation', function() {
    assert.deepEqual(stringToParts('a.b.c'), ['a', 'b', 'c']);
    assert.deepEqual(stringToParts('a..b.d'), ['a', '', 'b', 'd']);
  });

  it('ignores invalid numbers in square brackets', function() {
    assert.deepEqual(stringToParts('foo[1mystring]'), ['foo[1mystring]']);
    assert.deepEqual(stringToParts('foo[1mystring].bar[1]'), ['foo[1mystring]', 'bar', '1']);
    assert.deepEqual(stringToParts('foo[1mystring][2]'), ['foo[1mystring]', '2']);
  });

  it('handles empty string', function() {
    assert.deepEqual(stringToParts(''), ['']);
  });

  it('handles trailing dot', function() {
    assert.deepEqual(stringToParts('a.b.'), ['a', 'b', '']);
  });
});