// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:matcher/matcher.dart';
import 'package:test/test.dart' show test, expect;

import 'test_utils.dart';

void main() {
  test('Reports mismatches in whitespace and escape sequences', () {
    shouldFail('before\nafter', equals('before\\nafter'),
        contains('Differ at offset 7'));
  });

  test('Retains outer matcher mismatch text', () {
    shouldFail(
        {'word': 'thing'},
        containsPair('word', equals('notthing')),
        allOf([
          contains("contains key 'word' but with value is different"),
          contains('Differ at offset 0')
        ]));
  });

  test('collapseWhitespace', () {
    var source = '\t\r\n hello\t\r\n world\r\t \n';
    expect(collapseWhitespace(source), 'hello world');
  });

  test('isEmpty', () {
    shouldPass('', isEmpty);
    shouldFail(null, isEmpty, startsWith('Expected: empty  Actual: <null>'));
    shouldFail(0, isEmpty, startsWith('Expected: empty  Actual: <0>'));
    shouldFail('a', isEmpty, startsWith("Expected: empty  Actual: 'a'"));
  });

  // Regression test for: https://code.google.com/p/dart/issues/detail?id=21562
  test('isNot(isEmpty)', () {
    shouldPass('a', isNot(isEmpty));
    shouldFail('', isNot(isEmpty), 'Expected: not empty Actual: \'\'');
    shouldFail(null, isNot(isEmpty),
        startsWith('Expected: not empty  Actual: <null>'));
  });

  test('isNotEmpty', () {
    shouldFail('', isNotEmpty, startsWith("Expected: non-empty  Actual: ''"));
    shouldFail(
        null, isNotEmpty, startsWith('Expected: non-empty  Actual: <null>'));
    shouldFail(0, isNotEmpty, startsWith('Expected: non-empty  Actual: <0>'));
    shouldPass('a', isNotEmpty);
  });

  test('equalsIgnoringCase', () {
    shouldPass('hello', equalsIgnoringCase('HELLO'));
    shouldFail('hi', equalsIgnoringCase('HELLO'),
        "Expected: 'HELLO' ignoring case Actual: 'hi'");
    shouldFail(42, equalsIgnoringCase('HELLO'),
        endsWith('not an <Instance of \'String\'>'));
  });

  test('equalsIgnoringWhitespace', () {
    shouldPass(' hello   world  ', equalsIgnoringWhitespace('hello world'));
    shouldFail(
        ' helloworld  ',
        equalsIgnoringWhitespace('hello world'),
        "Expected: 'hello world' ignoring whitespace "
            "Actual: ' helloworld ' "
            "Which: is 'helloworld' with whitespace compressed");
    shouldFail(42, equalsIgnoringWhitespace('HELLO'),
        endsWith('not an <Instance of \'String\'>'));
  });

  test('startsWith', () {
    shouldPass('hello', startsWith(''));
    shouldPass('hello', startsWith('hell'));
    shouldPass('hello', startsWith('hello'));
    shouldFail(
        'hello',
        startsWith('hello '),
        "Expected: a string starting with 'hello ' "
            "Actual: 'hello'");
    shouldFail(
        42, startsWith('hello '), endsWith('not an <Instance of \'String\'>'));
  });

  test('endsWith', () {
    shouldPass('hello', endsWith(''));
    shouldPass('hello', endsWith('lo'));
    shouldPass('hello', endsWith('hello'));
    shouldFail(
        'hello',
        endsWith(' hello'),
        "Expected: a string ending with ' hello' "
            "Actual: 'hello'");
    shouldFail(
        42, startsWith('hello '), endsWith('not an <Instance of \'String\'>'));
  });

  test('contains', () {
    shouldPass('hello', contains(''));
    shouldPass('hello', contains('h'));
    shouldPass('hello', contains('o'));
    shouldPass('hello', contains('hell'));
    shouldPass('hello', contains('hello'));
    shouldFail(
        'hello', contains(' '), "Expected: contains ' ' Actual: 'hello'");
  });

  test('stringContainsInOrder', () {
    shouldPass('goodbye cruel world', stringContainsInOrder(['']));
    shouldPass('goodbye cruel world', stringContainsInOrder(['goodbye']));
    shouldPass('goodbye cruel world', stringContainsInOrder(['cruel']));
    shouldPass('goodbye cruel world', stringContainsInOrder(['world']));
    shouldPass(
        'goodbye cruel world', stringContainsInOrder(['good', 'bye', 'world']));
    shouldPass(
        'goodbye cruel world', stringContainsInOrder(['goodbye', 'cruel']));
    shouldPass(
        'goodbye cruel world', stringContainsInOrder(['cruel', 'world']));
    shouldPass('goodbye cruel world',
        stringContainsInOrder(['goodbye', 'cruel', 'world']));
    shouldPass(
        'foo', stringContainsInOrder(['f', '', '', '', 'o', '', '', 'o']));

    shouldFail(
        'abc',
        stringContainsInOrder(['ab', 'bc']),
        "Expected: a string containing 'ab', 'bc' in order "
            "Actual: 'abc'");
    shouldFail(
        'hello',
        stringContainsInOrder(['hello', 'hello']),
        "Expected: a string containing 'hello', 'hello' in order "
            "Actual: 'hello'");
    shouldFail(
        'goodbye cruel world',
        stringContainsInOrder(['goo', 'cruel', 'bye']),
        "Expected: a string containing 'goo', 'cruel', 'bye' in order "
            "Actual: 'goodbye cruel world'");
  });

  test('matches', () {
    shouldPass('c0d', matches('[a-z][0-9][a-z]'));
    shouldPass('c0d', matches(RegExp('[a-z][0-9][a-z]')));
    shouldFail('cOd', matches('[a-z][0-9][a-z]'),
        "Expected: match '[a-z][0-9][a-z]' Actual: 'cOd'");
    shouldFail(42, matches('[a-z][0-9][a-z]'),
        endsWith('not an <Instance of \'String\'>'));
  });
}
