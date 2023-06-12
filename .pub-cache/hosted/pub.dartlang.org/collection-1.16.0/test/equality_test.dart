// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests equality utilities.

import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  Element o(Comparable id) => Element(id);

  // Lists that are point-wise equal, but not identical.
  var list1 = [o(1), o(2), o(3), o(4), o(5)];
  var list2 = [o(1), o(2), o(3), o(4), o(5)];
  // Similar length list with equal elements in different order.
  var list3 = [o(1), o(3), o(5), o(4), o(2)];

  test('IterableEquality - List', () {
    expect(const IterableEquality().equals(list1, list2), isTrue);
    Equality iterId = const IterableEquality(IdentityEquality());
    expect(iterId.equals(list1, list2), isFalse);
  });

  test('IterableEquality - LinkedSet', () {
    var l1 = LinkedHashSet.from(list1);
    var l2 = LinkedHashSet.from(list2);
    expect(const IterableEquality().equals(l1, l2), isTrue);
    Equality iterId = const IterableEquality(IdentityEquality());
    expect(iterId.equals(l1, l2), isFalse);
  });

  test('ListEquality', () {
    expect(const ListEquality().equals(list1, list2), isTrue);
    Equality listId = const ListEquality(IdentityEquality());
    expect(listId.equals(list1, list2), isFalse);
  });

  test('ListInequality length', () {
    var list4 = [o(1), o(2), o(3), o(4), o(5), o(6)];
    expect(const ListEquality().equals(list1, list4), isFalse);
    expect(
        const ListEquality(IdentityEquality()).equals(list1, list4), isFalse);
  });

  test('ListInequality value', () {
    var list5 = [o(1), o(2), o(3), o(4), o(6)];
    expect(const ListEquality().equals(list1, list5), isFalse);
    expect(
        const ListEquality(IdentityEquality()).equals(list1, list5), isFalse);
  });

  test('UnorderedIterableEquality', () {
    expect(const UnorderedIterableEquality().equals(list1, list3), isTrue);
    Equality uniterId = const UnorderedIterableEquality(IdentityEquality());
    expect(uniterId.equals(list1, list3), isFalse);
  });

  test('UnorderedIterableInequality length', () {
    var list6 = [o(1), o(3), o(5), o(4), o(2), o(1)];
    expect(const UnorderedIterableEquality().equals(list1, list6), isFalse);
    expect(
        const UnorderedIterableEquality(IdentityEquality())
            .equals(list1, list6),
        isFalse);
  });

  test('UnorderedIterableInequality values', () {
    var list7 = [o(1), o(3), o(5), o(4), o(6)];
    expect(const UnorderedIterableEquality().equals(list1, list7), isFalse);
    expect(
        const UnorderedIterableEquality(IdentityEquality())
            .equals(list1, list7),
        isFalse);
  });

  test('SetEquality', () {
    var set1 = HashSet.from(list1);
    var set2 = LinkedHashSet.from(list3);
    expect(const SetEquality().equals(set1, set2), isTrue);
    Equality setId = const SetEquality(IdentityEquality());
    expect(setId.equals(set1, set2), isFalse);
  });

  test('SetInequality length', () {
    var list8 = [o(1), o(3), o(5), o(4), o(2), o(6)];
    var set1 = HashSet.from(list1);
    var set2 = LinkedHashSet.from(list8);
    expect(const SetEquality().equals(set1, set2), isFalse);
    expect(const SetEquality(IdentityEquality()).equals(set1, set2), isFalse);
  });

  test('SetInequality value', () {
    var list7 = [o(1), o(3), o(5), o(4), o(6)];
    var set1 = HashSet.from(list1);
    var set2 = LinkedHashSet.from(list7);
    expect(const SetEquality().equals(set1, set2), isFalse);
    expect(const SetEquality(IdentityEquality()).equals(set1, set2), isFalse);
  });

  var map1a = {
    'x': [o(1), o(2), o(3)],
    'y': [true, false, null]
  };
  var map1b = {
    'x': [o(4), o(5), o(6)],
    'y': [false, true, null]
  };
  var map2a = {
    'x': [o(3), o(2), o(1)],
    'y': [false, true, null]
  };
  var map2b = {
    'x': [o(6), o(5), o(4)],
    'y': [null, false, true]
  };
  var l1 = [map1a, map1b];
  var l2 = [map2a, map2b];
  var s1 = {...l1};
  var s2 = {map2b, map2a};

  var i1 = Iterable.generate(l1.length, (i) => l1[i]);

  test('RecursiveEquality', () {
    const unordered = UnorderedIterableEquality();
    expect(unordered.equals(map1a['x'], map2a['x']), isTrue);
    expect(unordered.equals(map1a['y'], map2a['y']), isTrue);
    expect(unordered.equals(map1b['x'], map2b['x']), isTrue);
    expect(unordered.equals(map1b['y'], map2b['y']), isTrue);
    const mapval = MapEquality(values: unordered);
    expect(mapval.equals(map1a, map2a), isTrue);
    expect(mapval.equals(map1b, map2b), isTrue);
    const listmapval = ListEquality(mapval);
    expect(listmapval.equals(l1, l2), isTrue);
    const setmapval = SetEquality<Map>(mapval);
    expect(setmapval.equals(s1, s2), isTrue);
  });

  group('DeepEquality', () {
    group('unordered', () {
      var colleq = const DeepCollectionEquality.unordered();

      test('with identical collection types', () {
        expect(colleq.equals(map1a['x'], map2a['x']), isTrue);
        expect(colleq.equals(map1a['y'], map2a['y']), isTrue);
        expect(colleq.equals(map1b['x'], map2b['x']), isTrue);
        expect(colleq.equals(map1b['y'], map2b['y']), isTrue);
        expect(colleq.equals(map1a, map2a), isTrue);
        expect(colleq.equals(map1b, map2b), isTrue);
        expect(colleq.equals(l1, l2), isTrue);
        expect(colleq.equals(s1, s2), isTrue);
      });

      // TODO: https://github.com/dart-lang/collection/issues/208
      test('comparing collections and iterables', () {
        expect(colleq.equals(l1, i1), isFalse);
        expect(colleq.equals(i1, l1), isFalse);
        expect(colleq.equals(s1, i1), isFalse);
        expect(colleq.equals(i1, s1), isTrue);
      });
    });

    group('ordered', () {
      var colleq = const DeepCollectionEquality();

      test('with identical collection types', () {
        expect(colleq.equals(l1, l1.toList()), isTrue);
        expect(colleq.equals(s1, s1.toSet()), isTrue);
        expect(
            colleq.equals(map1b, map1b.map((k, v) => MapEntry(k, v))), isTrue);
        expect(colleq.equals(i1, i1.map((i) => i)), isTrue);
        expect(colleq.equals(map1a, map2a), isFalse);
        expect(colleq.equals(map1b, map2b), isFalse);
        expect(colleq.equals(l1, l2), isFalse);
        expect(colleq.equals(s1, s2), isFalse);
      });

      // TODO: https://github.com/dart-lang/collection/issues/208
      test('comparing collections and iterables', () {
        expect(colleq.equals(l1, i1), isFalse);
        expect(colleq.equals(i1, l1), isTrue);
        expect(colleq.equals(s1, i1), isFalse);
        expect(colleq.equals(i1, s1), isTrue);
      });
    });
  });

  test('CaseInsensitiveEquality', () {
    var equality = const CaseInsensitiveEquality();
    expect(equality.equals('foo', 'foo'), isTrue);
    expect(equality.equals('fOo', 'FoO'), isTrue);
    expect(equality.equals('FoO', 'fOo'), isTrue);
    expect(equality.equals('foo', 'bar'), isFalse);
    expect(equality.equals('fÕÕ', 'fõõ'), isFalse);

    expect(equality.hash('foo'), equals(equality.hash('foo')));
    expect(equality.hash('fOo'), equals(equality.hash('FoO')));
    expect(equality.hash('FoO'), equals(equality.hash('fOo')));
    expect(equality.hash('foo'), isNot(equals(equality.hash('bar'))));
    expect(equality.hash('fÕÕ'), isNot(equals(equality.hash('fõõ'))));
  });

  group('EqualityBy should use a derived value for ', () {
    var firstEquality = EqualityBy<List<String>, String>((e) => e.first);
    var firstInsensitiveEquality = EqualityBy<List<String>, String>(
        (e) => e.first, const CaseInsensitiveEquality());
    var firstObjectEquality = EqualityBy<List<Object>, Object>(
        (e) => e.first, const IterableEquality());

    test('equality', () {
      expect(firstEquality.equals(['foo', 'foo'], ['foo', 'bar']), isTrue);
      expect(firstEquality.equals(['foo', 'foo'], ['bar', 'bar']), isFalse);
    });

    test('equality with an inner equality', () {
      expect(firstInsensitiveEquality.equals(['fOo'], ['FoO']), isTrue);
      expect(firstInsensitiveEquality.equals(['foo'], ['ffõõ']), isFalse);
    });

    test('hash', () {
      expect(firstEquality.hash(['foo', 'bar']), 'foo'.hashCode);
    });

    test('hash with an inner equality', () {
      expect(firstInsensitiveEquality.hash(['fOo']),
          const CaseInsensitiveEquality().hash('foo'));
    });

    test('isValidKey', () {
      expect(firstEquality.isValidKey(['foo']), isTrue);
      expect(firstEquality.isValidKey('foo'), isFalse);
      expect(firstEquality.isValidKey([1]), isFalse);
    });

    test('isValidKey with an inner equality', () {
      expect(firstObjectEquality.isValidKey([[]]), isTrue);
      expect(firstObjectEquality.isValidKey([{}]), isFalse);
    });
  });

  test('Equality accepts null', () {
    var ie = IterableEquality();
    var le = ListEquality();
    var se = SetEquality();
    var me = MapEquality();
    expect(ie.equals(null, null), true);
    expect(ie.equals([], null), false);
    expect(ie.equals(null, []), false);
    expect(ie.hash(null), null.hashCode);

    expect(le.equals(null, null), true);
    expect(le.equals([], null), false);
    expect(le.equals(null, []), false);
    expect(le.hash(null), null.hashCode);

    expect(se.equals(null, null), true);
    expect(se.equals({}, null), false);
    expect(se.equals(null, {}), false);
    expect(se.hash(null), null.hashCode);

    expect(me.equals(null, null), true);
    expect(me.equals({}, null), false);
    expect(me.equals(null, {}), false);
    expect(me.hash(null), null.hashCode);
  });
}

/// Wrapper objects for an `id` value.
///
/// Compares the `id` value by equality and for comparison.
/// Allows creating simple objects that are equal without being identical.
class Element implements Comparable<Element> {
  final Comparable id;
  const Element(this.id);
  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) => other is Element && id == other.id;
  @override
  int compareTo(other) => id.compareTo(other.id);
}
