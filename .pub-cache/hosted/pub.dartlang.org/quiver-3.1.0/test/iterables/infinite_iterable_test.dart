// Copyright 2018 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:quiver/src/iterables/infinite_iterable.dart';
import 'package:test/test.dart';

class NaturalNumberIterable extends InfiniteIterable<int> {
  @override
  final iterator = NaturalNumberIterator();
}

class NaturalNumberIterator implements Iterator<int> {
  int _current = -1;

  @override
  int get current => _current;

  @override
  bool moveNext() {
    ++_current;
    return true;
  }
}

void main() {
  group('InfiniteIterable', () {
    late NaturalNumberIterable it;

    setUp(() {
      it = NaturalNumberIterable();
    });

    test('isEmpty should be false', () {
      expect(it.isEmpty, isFalse);
    });

    test('isNotEmpty should be true', () {
      expect(it.isNotEmpty, isTrue);
    });

    test('single should throw StateError', () {
      expect(() => it.single, throwsStateError);
    });

    test('last should throw UnsupportedError', () {
      expect(() => it.last, throwsUnsupportedError);
    });

    test('length should throw UnsupportedError', () {
      expect(() => it.length, throwsUnsupportedError);
    });

    test('every should throw UnsupportedError', () {
      bool yes(int x) => true;
      expect(() => it.every(yes), throwsUnsupportedError);
    });

    test('fold should throw UnsupportedError', () {
      expect(() => it.fold(0, (__, ___) => 0), throwsUnsupportedError);
    });

    test('forEach should throw UnsupportedError', () {
      void nop(int x) {}
      expect(() => it.forEach(nop), throwsUnsupportedError);
    });

    test('join should throw UnsupportedError', () {
      expect(() => it.join(), throwsUnsupportedError);
    });

    test('lastWhere should throw UnsupportedError', () {
      expect(() => it.lastWhere((_) => true), throwsUnsupportedError);
    });

    test('reduce should throw UnsupportedError', () {
      expect(() => it.reduce((_, __) => 0), throwsUnsupportedError);
    });

    test('toList should throw UnsupportedError', () {
      expect(() => it.toList(), throwsUnsupportedError);
    });

    test('toSet should throw UnsupportedError', () {
      expect(() => it.toSet(), throwsUnsupportedError);
    });

    test('first should return a value', () {
      expect(it.first, 0);
    });

    test('any should return', () {
      expect(it.any((x) => x == 2), isTrue);
    });

    test('contains should return', () {
      expect(it.contains(2), isTrue);
    });

    test('expand should return', () {
      final expanded = it.expand((x) => [x, x]);
      expect(expanded.first, 0);
    });

    test('firstWhere should return', () {
      expect(it.firstWhere((x) => x > 1), 2);
    });

    test('map should return', () {
      final mapped = it.map((x) => x + 3);
      expect(mapped.first, 3);
    });

    test('singleWhere should throw UnsupportedError', () {
      expect(() => it.singleWhere((x) => x == 0), throwsUnsupportedError);
    });

    test('skip should return', () {
      final skipped = it.skip(3);
      expect(skipped.first, 3);
    });

    test('skipWhile should return', () {
      final skipped = it.skipWhile((x) => x < 3);
      expect(skipped.first, 3);
    });

    test('take should return', () {
      final taken = it.take(3);
      expect(taken, [0, 1, 2]);
    });

    test('take should return', () {
      final taken = it.takeWhile((x) => x < 3);
      expect(taken, [0, 1, 2]);
    });

    test('where should return', () {
      final whered = it.where((x) => x < 3);
      expect(whered.first, 0);
    });
  });
}
