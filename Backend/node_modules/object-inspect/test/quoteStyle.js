'use strict';

var inspect = require('../');
var test = require('tape');

test('quoteStyle option', function (t) {
    t['throws'](function () { inspect(null, { quoteStyle: false }); }, 'false is not a valid value');
    t['throws'](function () { inspect(null, { quoteStyle: true }); }, 'true is not a valid value');
    t['throws'](function () { inspect(null, { quoteStyle: '' }); }, '"" is not a valid value');
    t['throws'](function () { inspect(null, { quoteStyle: {} }); }, '{} is not a valid value');
    t['throws'](function () { inspect(null, { quoteStyle: [] }); }, '[] is not a valid value');
    t['throws'](function () { inspect(null, { quoteStyle: 42 }); }, '42 is not a valid value');
    t['throws'](function () { inspect(null, { quoteStyle: NaN }); }, 'NaN is not a valid value');
    t['throws'](function () { inspect(null, { quoteStyle: function () {} }); }, 'a function is not a valid value');

    t.end();
});
