// Copyright 2013 Google Inc. All Rights Reserved.
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

library quiver.core.optional_test;

import 'package:quiver/src/core/optional.dart';
import 'package:test/test.dart';

void main() {
  group('Optional', () {
    test('absent should be not present and not gettable', () {
      const Optional absent = Optional<int>.absent();
      expect(absent.isPresent, isFalse);
      expect(absent.isNotPresent, isTrue);
      expect(() => absent.value, throwsStateError);
    });

    test('of should be present and return value', () {
      Optional seven = Optional<int>.of(7);
      expect(seven.isPresent, isTrue);
      expect(seven.isNotPresent, isFalse);
      expect(seven.value, 7);
    });

    test('ifPresent should execute only if present', () {
      int? value;
      Optional<int>.of(7).ifPresent((v) {
        value = v;
      });
      expect(value, 7);
      const Optional<int>.absent().ifPresent((v) {
        value = v;
      });
      expect(value, 7);
    });

    test('isAbsent should execute only if absent', () {
      int? value;
      Optional<int>.of(7).ifAbsent(() {
        value = 7;
      });
      expect(value, null);
      const Optional<int>.absent().ifAbsent(() {
        value = 7;
      });
      expect(value, 7);
    });

    test('fromNullable should allow present or absent', () {
      expect(const Optional<int>.fromNullable(7).value, 7);
      expect(const Optional<int>.fromNullable(null).isPresent, isFalse);
      expect(const Optional<int>.fromNullable(null).isNotPresent, isTrue);
    });

    test('or should return present and replace absent', () {
      expect(Optional<int>.of(7).or(13), 7);
      expect(const Optional<int>.fromNullable(null).or(13), 13);
    });

    test('orNull should return value if present or null if absent', () {
      expect(Optional<int>.of(7).orNull, isNotNull);
      expect(const Optional<int>.fromNullable(null).orNull, isNull);
    });

    test('transform should return transformed value or absent', () {
      expect(Optional<int>.of(7).transform((a) => a + 1),
          equals(Optional<int>.of(8)));
      expect(
          const Optional<int>.fromNullable(null)
              .transform((a) => a + 1)
              .isPresent,
          isFalse);
    });

    test('transformNullable should return transformed value or absent', () {
      expect(Optional<int>.of(7).transformNullable((a) => a + 1),
          equals(Optional<int>.of(8)));
      expect(
          const Optional<int>.fromNullable(null)
              .transformNullable((a) => a + 1)
              .isPresent,
          isFalse);
    });

    test('transformNullable should return absent if transformed value is null',
        () {
      String? maybeToString(int i) => null;

      expect(Optional<int>.of(7).transformNullable(maybeToString).isPresent,
          isFalse);
    });

    test('hashCode should allow optionals to be in hash sets', () {
      expect(
          Set.from([
            Optional<int>.of(7),
            Optional<int>.of(8),
            const Optional<int>.absent()
          ]),
          equals(Set.from([
            Optional<int>.of(7),
            Optional<int>.of(8),
            const Optional<int>.absent()
          ])));
      expect(Set.from([Optional<int>.of(7), Optional<int>.of(8)]),
          isNot(equals(Set.from([Optional<int>.of(7), Optional<int>.of(9)]))));
    });

    test('== should compare by value', () {
      expect(Optional<int>.of(7), equals(Optional<int>.of(7)));
      expect(const Optional<int>.fromNullable(null),
          equals(const Optional<int>.fromNullable(null)));
      expect(const Optional<int>.fromNullable(null),
          equals(const Optional<String>.fromNullable(null)));
      expect(const Optional<int>.fromNullable(null),
          isNot(equals(Optional<int>.of(7))));
      expect(Optional<int>.of(7), isNot(equals(Optional<int>.of(8))));
    });

    test('toString should show the value or absent', () {
      expect(Optional<int>.of(7).toString(), equals('Optional { value: 7 }'));
      expect(const Optional<int>.fromNullable(null).toString(),
          equals('Optional { absent }'));
    });

    test('length when absent should return 0', () {
      expect(const Optional.absent().length, equals(0));
    });

    test('length when present should return 1', () {
      expect(Optional<int>.of(1).length, equals(1));
    });

    test('expand should behave as equivalent iterable', () {
      final optionals = <Optional<int>>[
        Optional<int>.of(1),
        const Optional.absent(),
        Optional<int>.of(2)
      ].expand((i) => i);
      expect(optionals, orderedEquals([1, 2]));
    });
  });
}
