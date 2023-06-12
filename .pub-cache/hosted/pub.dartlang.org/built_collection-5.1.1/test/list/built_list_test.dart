// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.s

import 'package:built_collection/src/list.dart';
import 'package:built_collection/src/internal/test_helpers.dart';
import 'package:test/test.dart';

import '../performance.dart';

void main() {
  group('BuiltList', () {
    test('instantiates empty by default', () {
      var list = BuiltList<int>();
      expect(list.isEmpty, isTrue);
      expect(list.isNotEmpty, isFalse);
    });

    test('allows <dynamic>', () {
      BuiltList<dynamic>();
    });

    test('can be instantiated from List', () {
      BuiltList<int>([]);
    });

    test('of constructor takes inferred type', () {
      expect(BuiltList.of([1, 2, 3]), const TypeMatcher<BuiltList<int>>());
    });

    test('reports non-emptiness', () {
      var list = BuiltList<int>([1]);
      expect(list.isEmpty, isFalse);
      expect(list.isNotEmpty, isTrue);
    });

    test('can be instantiated from List then converted back to equal List', () {
      var mutableList = [1];
      var list = BuiltList<int>(mutableList);
      expect(list.toList(), mutableList);
    });

    test('throws on wrong type element', () {
      expect(() => BuiltList<int>(['1']), throwsA(anything));
    });

    test('does not keep a mutable List', () {
      var mutableList = [1];
      var list = BuiltList<int>(mutableList);
      mutableList.clear();
      expect(list.toList(), [1]);
    });

    test('copies from BuiltList instances of different type', () {
      var list1 = BuiltList<Object>();
      var list2 = BuiltList<int>(list1);
      expect(list1, isNot(same(list2)));
    });

    test('can be converted to List<E>', () {
      expect(
        BuiltList<int>().toList(),
        const TypeMatcher<List<int>>(),
      );
      expect(
        BuiltList<int>().toList(),
        isNot(const TypeMatcher<List<String>>()),
      );
    });

    test('can be converted to an UnmodifiableListView', () {
      var immutableList = BuiltList<int>().asList();
      expect(immutableList, const TypeMatcher<List<int>>());
      expect(() => immutableList.add(1), throwsUnsupportedError);
      expect(immutableList, isEmpty);
    });

    test('can be converted to ListBuilder<E>', () {
      expect(
        BuiltList<int>().toBuilder(),
        const TypeMatcher<ListBuilder<int>>(),
      );
      expect(
        BuiltList<int>().toBuilder(),
        isNot(const TypeMatcher<ListBuilder<String>>()),
      );
    });

    test('can be converted to ListBuilder<E> and back to List<E>', () {
      expect(
        BuiltList<int>().toBuilder().build(),
        const TypeMatcher<BuiltList<int>>(),
      );
      expect(
        BuiltList<int>().toBuilder().build(),
        isNot(const TypeMatcher<BuiltList<String>>()),
      );
    });

    test('throws on null', () {
      expect(() => BuiltList<int>([null]), throwsA(anything));
    });

    test('nullable can store null', () {
      expect(BuiltList<int?>([null])[0], null);
    });

    test('of constructor throws on null', () {
      expect(() => BuiltList<int>.of([null as int]), throwsA(anything));
    });

    test('hashes to same value for same contents', () {
      var list1 = BuiltList<int>([1, 2, 3]);
      var list2 = BuiltList<int>([1, 2, 3]);

      expect(list1.hashCode, list2.hashCode);
    });

    test('hashes to different value for different contents', () {
      var list1 = BuiltList<int>([1, 2, 3]);
      var list2 = BuiltList<int>([1, 2, 4]);

      expect(list1.hashCode, isNot(list2.hashCode));
    });

    test('caches hash', () {
      var hashCodeSpy = HashCodeSpy();
      var list = BuiltList<Object>([hashCodeSpy]);

      hashCodeSpy.hashCodeSeen = 0;
      list.hashCode;
      list.hashCode;
      expect(hashCodeSpy.hashCodeSeen, 1);
    });

    test('compares equal to same instance', () {
      var list = BuiltList<int>([1, 2, 3]);
      expect(list == list, isTrue);
    });

    test('compares equal to same contents', () {
      var list1 = BuiltList<int>([1, 2, 3]);
      var list2 = BuiltList<int>([1, 2, 3]);
      expect(list1 == list2, isTrue);
    });

    test('compares not equal to different type', () {
      // ignore: unrelated_type_equality_checks
      expect(BuiltList<int>([1, 2, 3]) == '', isFalse);
    });

    test('compares not equal to different length BuiltList', () {
      expect(
          BuiltList<int>([1, 2, 3]) == BuiltList<int>([1, 2, 3, 4]), isFalse);
    });

    test('compares not equal to different hashcode BuiltList', () {
      expect(
          BuiltCollectionTestHelpers.overridenHashcodeBuiltList([1, 2, 3], 0) ==
              BuiltCollectionTestHelpers.overridenHashcodeBuiltList(
                  [1, 2, 3], 1),
          isFalse);
    });

    test('compares not equal to different content BuiltList', () {
      expect(
          BuiltCollectionTestHelpers.overridenHashcodeBuiltList([1, 2, 3], 0) ==
              BuiltCollectionTestHelpers.overridenHashcodeBuiltList(
                  [1, 2, 4], 0),
          isFalse);
    });

    test('provides toString() for debugging', () {
      expect(BuiltList<int>([1, 2, 3]).toString(), '[1, 2, 3]');
    });

    test('returns identical with toBuiltList', () {
      var list = BuiltList<int>([0, 1, 2]);
      expect(list.toBuiltList(), same(list));
    });

    test('converts to BuiltSet with toBuiltSet', () {
      expect(BuiltList<int>([0, 1, 2]).toBuiltSet(), [0, 1, 2]);
    });

    // Lazy copies.

    test('reuses BuiltList instances of the same type', () {
      var list1 = BuiltList<int>();
      var list2 = BuiltList<int>(list1);
      expect(list1, same(list2));
    });

    test('does not reuse BuiltList instances with subtype element type', () {
      var list1 = BuiltList<_ExtendsA>();
      var list2 = BuiltList<_A>(list1);
      expect(list1, isNot(same(list2)));
    });

    test('can be reused via ListBuilder if there are no changes', () {
      var list1 = BuiltList<Object>();
      var list2 = list1.toBuilder().build();
      expect(list1, same(list2));
    });

    test('converts to ListBuilder from correct type without copying', () {
      var makeLongList = () => BuiltList<int>(List<int>.filled(1000000, 0));
      var longList = makeLongList();
      var longListToListBuilder = longList.toBuilder;

      expectMuchFaster(longListToListBuilder, makeLongList);
    });

    test('converts to ListBuilder from wrong type by copying', () {
      var makeLongList = () => BuiltList<Object>(List<int>.filled(1000000, 0));
      var longList = makeLongList();
      var longListToListBuilder = () => ListBuilder<int>(longList);

      expectNotMuchFaster(longListToListBuilder, makeLongList);
    });

    test('has fast toList', () {
      var makeLongList = () => BuiltList<Object>(List<int>.filled(1000000, 0));
      var longList = makeLongList();
      var longListToList = () => longList.toList();

      expectMuchFaster(longListToList, makeLongList);
    });

    test('checks for reference identity', () {
      var makeLongList = () => BuiltList<Object>(List<int>.filled(1000000, 0));
      var longList = makeLongList();
      var otherLongList = makeLongList();

      expectMuchFaster(
          () => longList == longList, () => longList == otherLongList);
    });

    test('is not mutated when List from toList is mutated', () {
      var list = BuiltList<int>();
      list.toList().add(1);
      expect(list, []);
    });

    test('has build constructor', () {
      expect(BuiltList<int>.build((b) => b.addAll([0, 1, 2])), [0, 1, 2]);
    });

    test('has rebuild method', () {
      expect(BuiltList<int>([0, 1, 2]).rebuild((b) => b.addAll([3, 4, 5])),
          [0, 1, 2, 3, 4, 5]);
    });

    test('returns identical BuiltList on repeated build', () {
      var listBuilder = ListBuilder<int>([1, 2, 3]);
      expect(listBuilder.build(), same(listBuilder.build()));
    });

    // List.

    test('does not implement List', () {
      expect(BuiltList<int>() is List, isFalse);
    });

    test('has a method like List[]', () {
      expect(BuiltList<int>([1, 2, 3])[1], 2);
    });

    test('has a method like List+', () {
      expect(BuiltList<int>([1, 2, 3]) + BuiltList<int>([4, 5, 6]),
          [1, 2, 3, 4, 5, 6]);
    });

    test('has a method like List.length', () {
      expect(BuiltList<int>([1, 2, 3]).length, 3);
    });

    test('has a method like List.reversed', () {
      expect(BuiltList<int>([1, 2, 3]).reversed, [3, 2, 1]);
    });

    test('has a method like List.indexOf', () {
      expect(BuiltList<int>([1, 2, 3]).indexOf(2), 1);
      expect(BuiltList<int>([1, 2, 3]).indexOf(2, 2), -1);
    });

    test('has a method like List.lastIndexOf', () {
      expect(BuiltList<int>([1, 2, 3]).lastIndexOf(2), 1);
      expect(BuiltList<int>([1, 2, 3]).lastIndexOf(2, 0), -1);
    });

    test('has a method like List.sublist', () {
      expect(BuiltList<int>([1, 2, 3]).sublist(1), [2, 3]);
      expect(BuiltList<int>([1, 2, 3]).sublist(1, 2), [2]);
    });

    test('has a method like List.getRange', () {
      expect(BuiltList<int>([1, 2, 3]).getRange(1, 3), [2, 3]);
    });

    test('has a method like List.asMap', () {
      expect(BuiltList<int>([1, 2, 3]).asMap(), {0: 1, 1: 2, 2: 3});
    });

    test('has a method like List.indexWhere', () {
      expect(BuiltList<int>([1, 2, 3, 2]).indexWhere((x) => x == 2), 1);
      expect(BuiltList<int>([1, 2, 3, 2]).indexWhere((x) => x == 2, 2), 3);
    });

    test('has a method like List.lastIndexWhere', () {
      expect(BuiltList<int>([1, 2, 3, 2]).lastIndexWhere((x) => x == 2), 3);
      expect(BuiltList<int>([1, 2, 3, 2]).lastIndexWhere((x) => x == 2, 2), 1);
    });

    // Iterable.

    test('implements Iterable', () {
      expect(BuiltList<int>(), const TypeMatcher<Iterable>());
    });

    test('implements Iterable<E>', () {
      expect(BuiltList<int>(), const TypeMatcher<Iterable<int>>());
      expect(BuiltList<int>(), isNot(const TypeMatcher<Iterable<String>>()));
    });

    test('implements Iterable.map', () {
      expect(BuiltList<int>([1]).map((x) => x + 1), [2]);
    });

    test('implements Iterable.where', () {
      expect(BuiltList<int>([1, 2]).where((x) => x > 1), [2]);
    });

    test('implements Iterable.expand', () {
      expect(BuiltList<int>([1, 2]).expand((x) => [x, x + 1]), [1, 2, 2, 3]);
    });

    test('implements Iterable.contains', () {
      expect(BuiltList<int>([1]).contains(1), isTrue);
      expect(BuiltList<int>([1]).contains(2), isFalse);
    });

    test('implements Iterable.forEach', () {
      var value = 1;
      BuiltList<int>([2]).forEach((x) => value = x);
      expect(value, 2);
    });

    test('implements Iterable.reduce', () {
      expect(BuiltList<int>([1, 2]).reduce((x, y) => x + y), 3);
    });

    test('implements Iterable.fold', () {
      expect(
          BuiltList<int>([1, 2])
              .fold('', (x, y) => x.toString() + y.toString()),
          '12');
    });

    test('implements Iterable.followedBy', () {
      expect(BuiltList<int>([1, 2]).followedBy(BuiltList<int>([3, 4])),
          [1, 2, 3, 4]);
    });

    test('implements Iterable.every', () {
      expect(BuiltList<int>([1, 2]).every((x) => x == 1), isFalse);
      expect(BuiltList<int>([1, 2]).every((x) => x == 1 || x == 2), isTrue);
    });

    test('implements Iterable.join', () {
      expect(BuiltList<int>([1, 2]).join(','), '1,2');
    });

    test('implements Iterable.any', () {
      expect(BuiltList<int>([1, 2]).any((x) => x == 0), isFalse);
      expect(BuiltList<int>([1, 2]).any((x) => x == 1), isTrue);
    });

    test('implements Iterable.toSet', () {
      expect(BuiltList<int>([1, 2]).toSet(), const TypeMatcher<Set>());
      expect(BuiltList<int>([1, 2]).toSet(), [1, 2]);
    });

    test('implements Iterable.take', () {
      expect(BuiltList<int>([1, 2]).take(1), [1]);
    });

    test('implements Iterable.takeWhile', () {
      expect(BuiltList<int>([1, 2]).takeWhile((x) => x == 1), [1]);
    });

    test('implements Iterable.skip', () {
      expect(BuiltList<int>([1, 2]).skip(1), [2]);
    });

    test('implements Iterable.skipWhile', () {
      expect(BuiltList<int>([1, 2]).skipWhile((x) => x == 1), [2]);
    });

    test('implements Iterable.first', () {
      expect(BuiltList<int>([1, 2]).first, 1);
    });

    test('implements Iterable.last', () {
      expect(BuiltList<int>([1, 2]).last, 2);
    });

    test('implements Iterable.last', () {
      expect(() => BuiltList<int>([1, 2]).single, throwsA(anything));
      expect(BuiltList<int>([1]).single, 1);
    });

    test('implements Iterable.firstWhere', () {
      expect(BuiltList<int>([1, 2]).firstWhere((x) => x == 2), 2);
      expect(() => BuiltList<int>([1, 2]).firstWhere((x) => x == 3),
          throwsA(anything));
      expect(
          BuiltList<int>([1, 2]).firstWhere((x) => x == 3, orElse: () => 4), 4);
    });

    test('implements Iterable.lastWhere', () {
      expect(BuiltList<int>([1, 2]).lastWhere((x) => x == 2), 2);
      expect(() => BuiltList<int>([1, 2]).lastWhere((x) => x == 3),
          throwsA(anything));
      expect(
          BuiltList<int>([1, 2]).lastWhere((x) => x == 3, orElse: () => 4), 4);
    });

    test('implements Iterable.singleWhere', () {
      expect(BuiltList<int>([1, 2]).singleWhere((x) => x == 2), 2);
      expect(() => BuiltList<int>([1, 2]).singleWhere((x) => x == 3),
          throwsA(anything));
      expect(() => BuiltList<int>([1, 2]).singleWhere((x) => true),
          throwsA(anything));
      expect(BuiltList<int>([1, 2]).singleWhere((x) => x == 2), 2);
      expect(
          BuiltList<int>([1, 2]).singleWhere((x) => false, orElse: () => 7), 7);
    });

    test('implements Iterable.elementAt', () {
      expect(BuiltList<int>([1, 2]).elementAt(0), 1);
    });

    test('implements Iterable.cast', () {
      expect(BuiltList<int>([1, 2]).cast<Object>(),
          const TypeMatcher<Iterable<Object>>());
      expect(BuiltList<int>([1, 2]).cast<Object>(), [1, 2]);
    });

    test('implements Iterable.whereType', () {
      expect(BuiltList<Object>([1, 'two', 3]).whereType<String>(), ['two']);
    });

    test('can be created from`List` using extension methods', () {
      expect([1, 2, 3].build(), const TypeMatcher<BuiltList<int>>());
      expect([1, 2, 3].build(), [1, 2, 3]);
    });

    test('can be created from`Iterable` using extension methods', () {
      expect(
        [1, 2, 3].map((x) => x).toBuiltList(),
        const TypeMatcher<BuiltList<int>>(),
      );
      expect([1, 2, 3].map((x) => x).toBuiltList(), [1, 2, 3]);
    });
  });
}

class _A {}

class _ExtendsA extends _A {}
