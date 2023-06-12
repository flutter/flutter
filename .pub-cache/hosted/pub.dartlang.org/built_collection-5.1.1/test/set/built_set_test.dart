// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:collection' show SplayTreeSet;
import 'package:built_collection/src/set.dart';
import 'package:built_collection/src/internal/test_helpers.dart';
import 'package:test/test.dart';

import '../performance.dart';

void main() {
  group('BuiltSet', () {
    test('instantiates empty by default', () {
      var set = BuiltSet<int>();
      expect(set.isEmpty, isTrue);
      expect(set.isNotEmpty, isFalse);
    });

    test('allows <dynamic>', () {
      BuiltSet<dynamic>();
    });

    test('can be instantiated from Set', () {
      BuiltSet<int>([]);
    });

    test('of constructor takes inferred type', () {
      expect(BuiltSet.of([1, 2, 3]), const TypeMatcher<BuiltSet<int>>());
    });

    test('reports non-emptiness', () {
      var set = BuiltSet<int>([1]);
      expect(set.isEmpty, isFalse);
      expect(set.isNotEmpty, isTrue);
    });

    test('can be instantiated from Set then converted back to equal Set', () {
      var mutableSet = [1];
      var set = BuiltSet<int>(mutableSet);
      expect(set.toSet(), mutableSet);
    });

    test('throws on wrong type element', () {
      expect(() => BuiltSet<int>(['1']), throwsA(anything));
    });

    test('does not keep a mutable Set', () {
      var mutableSet = [1];
      var set = BuiltSet<int>(mutableSet);
      mutableSet.clear();
      expect(set.toSet(), [1]);
    });

    test('copies from BuiltSet instances of different type', () {
      var set1 = BuiltSet<Object>();
      var set2 = BuiltSet<int>(set1);
      expect(set1, isNot(same(set2)));
    });

    test('can be converted to Set<E>', () {
      expect(
        BuiltSet<int>().toSet(),
        const TypeMatcher<Set<int>>(),
      );
      expect(
        BuiltSet<int>().toSet(),
        isNot(const TypeMatcher<Set<String>>()),
      );
    });

    test('uses same base when converted with toSet', () {
      var built = BuiltSet<int>.build((b) => b
        ..withBase(() => SplayTreeSet<int>())
        ..addAll([1, 3]));
      var set = built.toSet()..addAll([2, 4]);
      expect(set, [1, 2, 3, 4]);
    });

    test('can be converted to an UnmodifiableSetView', () {
      var immutableSet = BuiltSet<int>().asSet();
      expect(immutableSet, const TypeMatcher<Set<int>>());
      expect(() => immutableSet.add(1), throwsUnsupportedError);
      expect(immutableSet, isEmpty);
    });

    test('can be converted to SetBuilder<E>', () {
      expect(
        BuiltSet<int>().toBuilder(),
        const TypeMatcher<SetBuilder<int>>(),
      );
      expect(
        BuiltSet<int>().toBuilder(),
        isNot(const TypeMatcher<SetBuilder<String>>()),
      );
    });

    test('can be converted to SetBuilder<E> and back to Set<E>', () {
      expect(
        BuiltSet<int>().toBuilder().build(),
        const TypeMatcher<BuiltSet<int>>(),
      );
      expect(
        BuiltSet<int>().toBuilder().build(),
        isNot(const TypeMatcher<BuiltSet<String>>()),
      );
    });

    test('passes along its base when converted to SetBuilder', () {
      var set = BuiltSet<int>.build((b) => b
        ..withBase(() => SplayTreeSet<int>())
        ..addAll([10, 15, 5]));
      var builder = set.toBuilder()..addAll([2, 12]);
      expect(builder.build(), orderedEquals([2, 5, 10, 12, 15]));
    });

    test('throws on null', () {
      expect(() => BuiltSet<int>([null]), throwsA(anything));
    });

    test('hashes to same value for same contents', () {
      var set1 = BuiltSet<int>([1, 2, 3]);
      var set2 = BuiltSet<int>([1, 2, 3]);

      expect(set1.hashCode, set2.hashCode);
    });

    test('hashes to same value for same contents in different order', () {
      var set1 = BuiltSet<int>([1, 2, 3]);
      var set2 = BuiltSet<int>([3, 2, 1]);

      expect(set1.hashCode, set2.hashCode);
    });

    test('hashes to different value for different contents', () {
      var set1 = BuiltSet<int>([1, 2, 3]);
      var set2 = BuiltSet<int>([1, 2, 4]);

      expect(set1.hashCode, isNot(set2.hashCode));
    });

    test('caches hash', () {
      var hashCodeSpy = HashCodeSpy();
      var set = BuiltSet<Object>([hashCodeSpy]);

      hashCodeSpy.hashCodeSeen = 0;
      set.hashCode;
      set.hashCode;
      expect(hashCodeSpy.hashCodeSeen, 1);
    });

    test('compares equal to same instance', () {
      var set1 = BuiltSet<int>([1, 2, 3]);
      expect(set1 == set1, isTrue);
    });

    test('compares equal to same contents', () {
      var set1 = BuiltSet<int>([1, 2, 3]);
      var set2 = BuiltSet<int>([1, 2, 3]);
      expect(set1 == set2, isTrue);
    });

    test('compares not equal to different type', () {
      // ignore: unrelated_type_equality_checks
      expect(BuiltSet<int>([1, 2, 3]) == '', isFalse);
    });

    test('compares not equal to different length BuiltSet', () {
      expect(BuiltSet<int>([1, 2, 3]) == BuiltSet<int>([1, 2, 3, 4]), isFalse);
    });

    test('compares not equal to different hashcode BuiltSet', () {
      expect(
          BuiltCollectionTestHelpers.overridenHashcodeBuiltSet([1, 2, 3], 0) ==
              BuiltCollectionTestHelpers.overridenHashcodeBuiltSet(
                  [1, 2, 3], 1),
          isFalse);
    });

    test('compares not equal to different content BuiltSet', () {
      expect(
          BuiltCollectionTestHelpers.overridenHashcodeBuiltSet([1, 2, 3], 0) ==
              BuiltCollectionTestHelpers.overridenHashcodeBuiltSet(
                  [1, 2, 4], 0),
          isFalse);
    });

    test('provides toString() for debugging', () {
      expect(BuiltSet<int>([1, 2, 3]).toString(), '{1, 2, 3}');
    });

    test('preserves order', () {
      expect(BuiltSet<int>([1, 2, 3]), [1, 2, 3]);
      expect(BuiltSet<int>([3, 2, 1]), [3, 2, 1]);
    });

    test('has build constructor', () {
      expect(BuiltSet<int>.build((b) => b.addAll([0, 1, 2])), [0, 1, 2]);
    });

    test('has rebuild method', () {
      expect(BuiltSet<int>([0, 1, 2]).rebuild((b) => b.addAll([3, 4, 5])),
          [0, 1, 2, 3, 4, 5]);
    });

    test('converts to BuiltList with toBuiltList', () {
      expect(BuiltSet<int>([0, 1, 2]).toBuiltList(), [0, 1, 2]);
    });

    test('returns identical with toBuiltSet', () {
      var set = BuiltSet<int>([0, 1, 2]);
      expect(set.toBuiltSet(), same(set));
    });

    // Lazy copies.

    test('reuses BuiltSet instances of the same type', () {
      var set1 = BuiltSet<int>();
      var set2 = BuiltSet<int>(set1);
      expect(set1, same(set2));
    });

    test('does not reuse BuiltSet instances with subtype element type', () {
      var set1 = BuiltSet<_ExtendsA>();
      var set2 = BuiltSet<_A>(set1);
      expect(set1, isNot(same(set2)));
    });

    test('can be reused via SetBuilder if there are no changes', () {
      var set1 = BuiltSet<Object>();
      var set2 = set1.toBuilder().build();
      expect(set1, same(set2));
    });

    test('converts to SetBuilder from correct type without copying', () {
      var makeLongSet = () =>
          BuiltSet<int>(Set<int>.from(List<int>.generate(100000, (x) => x)));
      var longSet = makeLongSet();
      var longSetToSetBuilder = longSet.toBuilder;

      expectMuchFaster(longSetToSetBuilder, makeLongSet);
    });

    test('converts to SetBuilder from wrong type by copying', () {
      var makeLongSet = () =>
          BuiltSet<Object>(Set<int>.from(List<int>.generate(100000, (x) => x)));
      var longSet = makeLongSet();
      var longSetToSetBuilder = () => SetBuilder<int>(longSet);

      expectNotMuchFaster(longSetToSetBuilder, makeLongSet);
    });

    test('has fast toSet', () {
      var makeLongSet = () =>
          BuiltSet<Object>(Set<int>.from(List<int>.generate(100000, (x) => x)));
      var longSet = makeLongSet();
      var longSetToSet = () => longSet.toSet();

      expectMuchFaster(longSetToSet, makeLongSet);
    });

    test('checks for reference identity', () {
      var makeLongSet = () =>
          BuiltSet<Object>(Set<int>.from(List<int>.generate(100000, (x) => x)));
      var longSet = makeLongSet();
      var otherLongSet = makeLongSet();

      expectMuchFaster(() => longSet == longSet, () => longSet == otherLongSet);
    });

    test('is not mutated when Set from toSet is mutated', () {
      var set = BuiltSet<int>();
      set.toSet().add(1);
      expect(set, []);
    });

    // Set.

    test('does not implement Set', () {
      expect(BuiltSet<int>() is Set, isFalse);
    });

    test('has a method like Set.length', () {
      expect(BuiltSet<int>([1, 2, 3]).length, 3);
    });

    test('has a method like Set.containsAll', () {
      expect(BuiltSet<int>([1, 2, 3]).containsAll([1, 2]), isTrue);
      expect(BuiltSet<int>([1, 2, 3]).containsAll([1, 2, 3, 4]), isFalse);
    });

    test('has a method like Set.difference', () {
      expect(BuiltSet<int>([1, 2, 3]).difference(BuiltSet<int>([1])), [2, 3]);
    });

    test('has a method like Set.intersection', () {
      expect(BuiltSet<int>([1, 2, 3]).intersection(BuiltSet<int>([1])), [1]);
    });

    test('has a method like Set.lookup', () {
      expect(BuiltSet<int>([1, 2, 3]).lookup(1), 1);
      expect(BuiltSet<int>([1, 2, 3]).lookup(4), isNull);
    });

    test('has a method like Set.union', () {
      expect(BuiltSet<int>([1, 2, 3]).union(BuiltSet<int>([4])), [1, 2, 3, 4]);
    });

    // Iterable.

    test('implements Iterable', () {
      expect(BuiltSet<int>(), const TypeMatcher<Iterable>());
    });

    test('implements Iterable<E>', () {
      expect(
        BuiltSet<int>(),
        const TypeMatcher<Iterable<int>>(),
      );
      expect(
        BuiltSet<int>(),
        isNot(const TypeMatcher<Iterable<String>>()),
      );
    });

    test('implements Iterable.map', () {
      expect(BuiltSet<int>([1]).map((x) => x + 1), [2]);
    });

    test('implements Iterable.where', () {
      expect(BuiltSet<int>([1, 2]).where((x) => x > 1), [2]);
    });

    test('implements Iterable.expand', () {
      expect(BuiltSet<int>([1, 2]).expand((x) => [x, x + 1]), [1, 2, 2, 3]);
    });

    test('implements Iterable.contains', () {
      expect(BuiltSet<int>([1]).contains(1), isTrue);
      expect(BuiltSet<int>([1]).contains(2), isFalse);
    });

    test('implements Iterable.forEach', () {
      var value = 1;
      BuiltSet<int>([2]).forEach((x) => value = x);
      expect(value, 2);
    });

    test('implements Iterable.reduce', () {
      expect(BuiltSet<int>([1, 2]).reduce((x, y) => x + y), 3);
    });

    test('implements Iterable.fold', () {
      expect(
          BuiltSet<int>([1, 2]).fold('', (x, y) => x.toString() + y.toString()),
          '12');
    });

    test('implements Iterable.followedBy', () {
      expect(BuiltSet<int>([1, 2]).followedBy(BuiltSet<int>([3, 4])),
          [1, 2, 3, 4]);
    });

    test('implements Iterable.every', () {
      expect(BuiltSet<int>([1, 2]).every((x) => x == 1), isFalse);
      expect(BuiltSet<int>([1, 2]).every((x) => x == 1 || x == 2), isTrue);
    });

    test('implements Iterable.join', () {
      expect(BuiltSet<int>([1, 2]).join(','), '1,2');
    });

    test('implements Iterable.any', () {
      expect(BuiltSet<int>([1, 2]).any((x) => x == 0), isFalse);
      expect(BuiltSet<int>([1, 2]).any((x) => x == 1), isTrue);
    });

    test('implements Iterable.toSet', () {
      expect(BuiltSet<int>([1, 2]).toSet(), const TypeMatcher<Set>());
      expect(BuiltSet<int>([1, 2]).toSet(), [1, 2]);
    });

    test('implements Iterable.toList', () {
      expect(BuiltSet<int>([1, 2]).toList(), const TypeMatcher<List>());
      expect(BuiltSet<int>([1, 2]).toList(), [1, 2]);
    });

    test('implements Iterable.take', () {
      expect(BuiltSet<int>([1, 2]).take(1), [1]);
    });

    test('implements Iterable.takeWhile', () {
      expect(BuiltSet<int>([1, 2]).takeWhile((x) => x == 1), [1]);
    });

    test('implements Iterable.skip', () {
      expect(BuiltSet<int>([1, 2]).skip(1), [2]);
    });

    test('implements Iterable.skipWhile', () {
      expect(BuiltSet<int>([1, 2]).skipWhile((x) => x == 1), [2]);
    });

    test('implements Iterable.first', () {
      expect(BuiltSet<int>([1, 2]).first, 1);
    });

    test('implements Iterable.last', () {
      expect(BuiltSet<int>([1, 2]).last, 2);
    });

    test('implements Iterable.last', () {
      expect(() => BuiltSet<int>([1, 2]).single, throwsA(anything));
      expect(BuiltSet<int>([1]).single, 1);
    });

    test('implements Iterable.firstWhere', () {
      expect(BuiltSet<int>([1, 2]).firstWhere((x) => x == 2), 2);
      expect(() => BuiltSet<int>([1, 2]).firstWhere((x) => x == 3),
          throwsA(anything));
      expect(
          BuiltSet<int>([1, 2]).firstWhere((x) => x == 3, orElse: () => 4), 4);
    });

    test('implements Iterable.lastWhere', () {
      expect(BuiltSet<int>([1, 2]).lastWhere((x) => x == 2), 2);
      expect(() => BuiltSet<int>([1, 2]).lastWhere((x) => x == 3),
          throwsA(anything));
      expect(
          BuiltSet<int>([1, 2]).lastWhere((x) => x == 3, orElse: () => 4), 4);
    });

    test('implements Iterable.singleWhere', () {
      expect(BuiltSet<int>([1, 2]).singleWhere((x) => x == 2), 2);
      expect(() => BuiltSet<int>([1, 2]).singleWhere((x) => x == 3),
          throwsA(anything));
      expect(() => BuiltSet<int>([1, 2]).singleWhere((x) => true),
          throwsA(anything));
      expect(
          BuiltSet<int>([1, 2]).singleWhere((x) => false, orElse: () => 7), 7);
    });

    test('implements Iterable.elementAt', () {
      expect(BuiltSet<int>([1, 2]).elementAt(0), 1);
    });

    test('implements Iterable.cast', () {
      expect(BuiltSet<int>([1, 2]).cast<Object>(),
          const TypeMatcher<Iterable<Object>>());
      expect(BuiltSet<int>([1, 2]).cast<Object>(), [1, 2]);
    });

    test('implements Iterable.whereType', () {
      expect(BuiltSet<Object>([1, 'two', 3]).whereType<String>(), ['two']);
    });

    test('can be created from`Set` using extension methods', () {
      expect(
        {1, 2, 3}.build(),
        const TypeMatcher<BuiltSet<int>>(),
      );
      expect({1, 2, 3}.build(), [1, 2, 3]);
    });

    test('can be created from`Iterable` using extension methods', () {
      expect(
        [1, 2, 3].map((x) => x).toBuiltSet(),
        const TypeMatcher<BuiltSet<int>>(),
      );
      expect([1, 2, 3].map((x) => x).toBuiltSet(), [1, 2, 3]);
    });
  });
}

class _A {}

class _ExtendsA extends _A {}
