// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_gen/src/output_helpers.dart';
import 'package:test/test.dart';

void main() {
  group('valid values', () {
    _testSimpleValue('null', null, []);
    _testSimpleValue('String', 'string', ['string']);
    _testSimpleValue('empty List', [], []);
    _testSimpleValue('List', ['a', 'b', 'c'], ['a', 'b', 'c']);
    _testSimpleValue(
        'Iterable', Iterable.generate(3, (i) => i.toString()), ['0', '1', '2']);

    _testFunction('Future<Stream>',
        Future.value(Stream.fromIterable(['value'])), ['value']);
  });

  group('invalid values', () {
    _testSimpleValue('number', 42, throwsArgumentError);
    _testSimpleValue(
        'mixed good and bad', ['good', 42, 'also good'], throwsArgumentError);

    final badInstance = _ThrowOnToString();
    _testSimpleValue('really bad class', badInstance, throwsArgumentError);

    _testSimpleValue(
        'iterable with errors', _throwingIterable(), throwsArgumentError);

    _testFunction('sync throw', () => throw ArgumentError('Error message'),
        throwsArgumentError);

    _testFunction(
        'new Future.error',
        () => Future.error(ArgumentError('Error message')),
        throwsArgumentError);

    _testFunction('throw in async',
        () async => throw ArgumentError('Error message'), throwsArgumentError);
  });
}

void _testSimpleValue(String testName, Object? value, expected) {
  _testFunction(testName, value, expected);

  assert(value is! Future);

  _testFunction('Future<$testName>', Future.value(value), expected);

  if (value is Iterable) {
    _testFunction('Stream with values from $testName',
        Stream.fromIterable(value), expected);
  } else {
    _testFunction('Stream single value $testName', Stream.fromIterable([value]),
        expected);
  }
}

void _testFunction(String testName, value, expected) {
  test(testName, () async {
    if (expected is List) {
      expect(await normalizeGeneratorOutput(value).toList(), expected);
    } else {
      expect(() => normalizeGeneratorOutput(value).drain(), expected);
    }
  });
}

Iterable<String> _throwingIterable() sync* {
  yield 'a';
  yield 'b';
  throw ArgumentError('Error in iterator!');
}

class _ThrowOnToString {
  @override
  String toString() {
    throw UnsupportedError('cannot call toString');
  }
}
