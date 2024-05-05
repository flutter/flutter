'use strict';

var test = require('tape');

var getSideChannel = require('../');

test('export', function (t) {
	t.equal(typeof getSideChannel, 'function', 'is a function');
	t.equal(getSideChannel.length, 0, 'takes no arguments');

	var channel = getSideChannel();
	t.ok(channel, 'is truthy');
	t.equal(typeof channel, 'object', 'is an object');

	t.end();
});

test('assert', function (t) {
	var channel = getSideChannel();
	t['throws'](
		function () { channel.assert({}); },
		TypeError,
		'nonexistent value throws'
	);

	var o = {};
	channel.set(o, 'data');
	t.doesNotThrow(function () { channel.assert(o); }, 'existent value noops');

	t.end();
});

test('has', function (t) {
	var channel = getSideChannel();
	/** @type {unknown[]} */ var o = [];

	t.equal(channel.has(o), false, 'nonexistent value yields false');

	channel.set(o, 'foo');
	t.equal(channel.has(o), true, 'existent value yields true');

	t.equal(channel.has('abc'), false, 'non object value non existent yields false');

	channel.set('abc', 'foo');
	t.equal(channel.has('abc'), true, 'non object value that exists yields true');

	t.end();
});

test('get', function (t) {
	var channel = getSideChannel();
	var o = {};
	t.equal(channel.get(o), undefined, 'nonexistent value yields undefined');

	var data = {};
	channel.set(o, data);
	t.equal(channel.get(o), data, '"get" yields data set by "set"');

	t.end();
});

test('set', function (t) {
	var channel = getSideChannel();
	var o = function () {};
	t.equal(channel.get(o), undefined, 'value not set');

	channel.set(o, 42);
	t.equal(channel.get(o), 42, 'value was set');

	channel.set(o, Infinity);
	t.equal(channel.get(o), Infinity, 'value was set again');

	var o2 = {};
	channel.set(o2, 17);
	t.equal(channel.get(o), Infinity, 'o is not modified');
	t.equal(channel.get(o2), 17, 'o2 is set');

	channel.set(o, 14);
	t.equal(channel.get(o), 14, 'o is modified');
	t.equal(channel.get(o2), 17, 'o2 is not modified');

	t.end();
});
