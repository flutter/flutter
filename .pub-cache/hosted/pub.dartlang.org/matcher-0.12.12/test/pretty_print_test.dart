// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:matcher/matcher.dart';
import 'package:matcher/src/pretty_print.dart';
import 'package:test/test.dart' show group, test, expect;

class DefaultToString {}

class CustomToString {
  @override
  String toString() => 'string representation';
}

class _PrivateName {
  @override
  String toString() => 'string representation';
}

class _PrivateNameIterable extends IterableMixin {
  @override
  Iterator get iterator => [1, 2, 3].iterator;
}

void main() {
  test('with primitive objects', () {
    expect(prettyPrint(12), equals('<12>'));
    expect(prettyPrint(12.13), equals('<12.13>'));
    expect(prettyPrint(true), equals('<true>'));
    expect(prettyPrint(null), equals('<null>'));
    expect(prettyPrint(() => 12), matches(r'<Closure.*>'));
  });

  group('with a string', () {
    test('containing simple characters', () {
      expect(prettyPrint('foo'), equals("'foo'"));
    });

    test('containing newlines', () {
      expect(
          prettyPrint('foo\nbar\nbaz'),
          equals("'foo\\n'\n"
              "  'bar\\n'\n"
              "  'baz'"));
    });

    test('containing escapable characters', () {
      expect(prettyPrint("foo\rbar\tbaz'qux\v"),
          equals(r"'foo\rbar\tbaz\'qux\v'"));
    });
  });

  group('with an iterable', () {
    test('containing primitive objects', () {
      expect(prettyPrint([1, true, 'foo']), equals("[1, true, 'foo']"));
    });

    test('containing a multiline string', () {
      expect(
          prettyPrint(['foo', 'bar\nbaz\nbip', 'qux']),
          equals('[\n'
              "  'foo',\n"
              "  'bar\\n'\n"
              "    'baz\\n'\n"
              "    'bip',\n"
              "  'qux'\n"
              ']'));
    });

    test('containing a matcher', () {
      expect(prettyPrint(['foo', endsWith('qux')]),
          equals("['foo', <a string ending with 'qux'>]"));
    });

    test("that's under maxLineLength", () {
      expect(prettyPrint([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], maxLineLength: 30),
          equals('[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]'));
    });

    test("that's over maxLineLength", () {
      expect(
          prettyPrint([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], maxLineLength: 29),
          equals('[\n'
              '  0,\n'
              '  1,\n'
              '  2,\n'
              '  3,\n'
              '  4,\n'
              '  5,\n'
              '  6,\n'
              '  7,\n'
              '  8,\n'
              '  9\n'
              ']'));
    });

    test('factors indentation into maxLineLength', () {
      expect(
          prettyPrint([
            'foo\nbar',
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
          ], maxLineLength: 30),
          equals('[\n'
              "  'foo\\n'\n"
              "    'bar',\n"
              '  [\n'
              '    0,\n'
              '    1,\n'
              '    2,\n'
              '    3,\n'
              '    4,\n'
              '    5,\n'
              '    6,\n'
              '    7,\n'
              '    8,\n'
              '    9\n'
              '  ]\n'
              ']'));
    });

    test("that's under maxItems", () {
      expect(prettyPrint([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], maxItems: 10),
          equals('[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]'));
    });

    test("that's over maxItems", () {
      expect(prettyPrint([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], maxItems: 9),
          equals('[0, 1, 2, 3, 4, 5, 6, 7, ...]'));
    });

    test("that's recursive", () {
      var list = <dynamic>[1, 2, 3];
      list.add(list);
      expect(prettyPrint(list), equals('[1, 2, 3, (recursive)]'));
    });
  });

  group('with a map', () {
    test('containing primitive objects', () {
      expect(prettyPrint({'foo': 1, 'bar': true}),
          equals("{'foo': 1, 'bar': true}"));
    });

    test('containing a multiline string key', () {
      expect(
          prettyPrint({'foo\nbar': 1, 'bar': true}),
          equals('{\n'
              "  'foo\\n'\n"
              "    'bar': 1,\n"
              "  'bar': true\n"
              '}'));
    });

    test('containing a multiline string value', () {
      expect(
          prettyPrint({'foo': 'bar\nbaz', 'qux': true}),
          equals('{\n'
              "  'foo': 'bar\\n'\n"
              "    'baz',\n"
              "  'qux': true\n"
              '}'));
    });

    test('containing a multiline string key/value pair', () {
      expect(
          prettyPrint({'foo\nbar': 'baz\nqux'}),
          equals('{\n'
              "  'foo\\n'\n"
              "    'bar': 'baz\\n'\n"
              "    'qux'\n"
              '}'));
    });

    test('containing a matcher key', () {
      expect(prettyPrint({endsWith('bar'): 'qux'}),
          equals("{<a string ending with 'bar'>: 'qux'}"));
    });

    test('containing a matcher value', () {
      expect(prettyPrint({'foo': endsWith('qux')}),
          equals("{'foo': <a string ending with 'qux'>}"));
    });

    test("that's under maxLineLength", () {
      expect(prettyPrint({'0': 1, '2': 3, '4': 5, '6': 7}, maxLineLength: 32),
          equals("{'0': 1, '2': 3, '4': 5, '6': 7}"));
    });

    test("that's over maxLineLength", () {
      expect(
          prettyPrint({'0': 1, '2': 3, '4': 5, '6': 7}, maxLineLength: 31),
          equals('{\n'
              "  '0': 1,\n"
              "  '2': 3,\n"
              "  '4': 5,\n"
              "  '6': 7\n"
              '}'));
    });

    test('factors indentation into maxLineLength', () {
      expect(
          prettyPrint([
            'foo\nbar',
            {'0': 1, '2': 3, '4': 5, '6': 7}
          ], maxLineLength: 32),
          equals('[\n'
              "  'foo\\n'\n"
              "    'bar',\n"
              '  {\n'
              "    '0': 1,\n"
              "    '2': 3,\n"
              "    '4': 5,\n"
              "    '6': 7\n"
              '  }\n'
              ']'));
    });

    test("that's under maxItems", () {
      expect(prettyPrint({'0': 1, '2': 3, '4': 5, '6': 7}, maxItems: 4),
          equals("{'0': 1, '2': 3, '4': 5, '6': 7}"));
    });

    test("that's over maxItems", () {
      expect(prettyPrint({'0': 1, '2': 3, '4': 5, '6': 7}, maxItems: 3),
          equals("{'0': 1, '2': 3, ...}"));
    });
  });
  group('with an object', () {
    test('with a default [toString]', () {
      expect(prettyPrint(DefaultToString()),
          equals("<Instance of 'DefaultToString'>"));
    });

    test('with a custom [toString]', () {
      expect(prettyPrint(CustomToString()),
          equals('CustomToString:<string representation>'));
    });

    test('with a custom [toString] and a private name', () {
      expect(prettyPrint(_PrivateName()),
          equals('_PrivateName:<string representation>'));
    });
  });

  group('with an iterable', () {
    test("that's not a list", () {
      expect(prettyPrint([1, 2, 3, 4].map((n) => n * 2)),
          equals('MappedListIterable<int, int>:[2, 4, 6, 8]'));
    });

    test("that's not a list and has a private name", () {
      expect(prettyPrint(_PrivateNameIterable()),
          equals('_PrivateNameIterable:[1, 2, 3]'));
    });
  });

  test('Type', () {
    expect(prettyPrint(''.runtimeType), 'Type:<String>');
  });
}
