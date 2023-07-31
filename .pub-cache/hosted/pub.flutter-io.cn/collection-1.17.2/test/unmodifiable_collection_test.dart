// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:test/test.dart';

// Test unmodifiable collection views.
// The collections should pass through the operations that are allowed,
// an throw on the ones that aren't without affecting the original.

void main() {
  var list = <int>[];
  testUnmodifiableList(list, UnmodifiableListView(list), 'empty');
  list = [42];
  testUnmodifiableList(list, UnmodifiableListView(list), 'single-42');
  list = [7];
  testUnmodifiableList(list, UnmodifiableListView(list), 'single!42');
  list = [1, 42, 10];
  testUnmodifiableList(list, UnmodifiableListView(list), 'three-42');
  list = [1, 7, 10];
  testUnmodifiableList(list, UnmodifiableListView(list), 'three!42');

  list = [];
  testNonGrowableList(list, NonGrowableListView(list), 'empty');
  list = [42];
  testNonGrowableList(list, NonGrowableListView(list), 'single-42');
  list = [7];
  testNonGrowableList(list, NonGrowableListView(list), 'single!42');
  list = [1, 42, 10];
  testNonGrowableList(list, NonGrowableListView(list), 'three-42');
  list = [1, 7, 10];
  testNonGrowableList(list, NonGrowableListView(list), 'three!42');

  var aSet = <int>{};
  testUnmodifiableSet(aSet, UnmodifiableSetView(aSet), 'empty');
  aSet = {};
  testUnmodifiableSet(aSet, const UnmodifiableSetView.empty(), 'const empty');
  aSet = {42};
  testUnmodifiableSet(aSet, UnmodifiableSetView(aSet), 'single-42');
  aSet = {7};
  testUnmodifiableSet(aSet, UnmodifiableSetView(aSet), 'single!42');
  aSet = {1, 42, 10};
  testUnmodifiableSet(aSet, UnmodifiableSetView(aSet), 'three-42');
  aSet = {1, 7, 10};
  testUnmodifiableSet(aSet, UnmodifiableSetView(aSet), 'three!42');
}

void testUnmodifiableList(List<int> original, List<int> wrapped, String name) {
  name = 'unmodifiable-list-$name';
  testIterable(original, wrapped, name);
  testReadList(original, wrapped, name);
  testNoWriteList(original, wrapped, name);
  testNoChangeLengthList(original, wrapped, name);
}

void testNonGrowableList(List<int> original, List<int> wrapped, String name) {
  name = 'nongrowable-list-$name';
  testIterable(original, wrapped, name);
  testReadList(original, wrapped, name);
  testWriteList(original, wrapped, name);
  testNoChangeLengthList(original, wrapped, name);
}

void testUnmodifiableSet(Set<int> original, Set<int> wrapped, String name) {
  name = 'unmodifiable-set-$name';
  testIterable(original, wrapped, name);
  testReadSet(original, wrapped, name);
  testNoChangeSet(original, wrapped, name);
}

void testIterable(Iterable<int> original, Iterable<int> wrapped, String name) {
  test('$name - any', () {
    expect(wrapped.any((x) => true), equals(original.any((x) => true)));
    expect(wrapped.any((x) => false), equals(original.any((x) => false)));
  });

  test('$name - contains', () {
    expect(wrapped.contains(0), equals(original.contains(0)));
  });

  test('$name - elementAt', () {
    if (original.isEmpty) {
      expect(() => wrapped.elementAt(0), throwsRangeError);
    } else {
      expect(wrapped.elementAt(0), equals(original.elementAt(0)));
    }
  });

  test('$name - every', () {
    expect(wrapped.every((x) => true), equals(original.every((x) => true)));
    expect(wrapped.every((x) => false), equals(original.every((x) => false)));
  });

  test('$name - expand', () {
    expect(
        wrapped.expand((x) => [x, x]), equals(original.expand((x) => [x, x])));
  });

  test('$name - first', () {
    if (original.isEmpty) {
      expect(() => wrapped.first, throwsStateError);
    } else {
      expect(wrapped.first, equals(original.first));
    }
  });

  test('$name - firstWhere', () {
    if (original.isEmpty) {
      expect(() => wrapped.firstWhere((_) => true), throwsStateError);
    } else {
      expect(wrapped.firstWhere((_) => true),
          equals(original.firstWhere((_) => true)));
    }
    expect(() => wrapped.firstWhere((_) => false), throwsStateError);
  });

  test('$name - fold', () {
    expect(wrapped.fold(0, (dynamic x, y) => x + y),
        equals(original.fold(0, (dynamic x, y) => x + y)));
  });

  test('$name - forEach', () {
    var wrapCtr = 0;
    var origCtr = 0;
    // ignore: avoid_function_literals_in_foreach_calls
    wrapped.forEach((x) {
      wrapCtr += x;
    });
    // ignore: avoid_function_literals_in_foreach_calls
    original.forEach((x) {
      origCtr += x;
    });
    expect(wrapCtr, equals(origCtr));
  });

  test('$name - isEmpty', () {
    expect(wrapped.isEmpty, equals(original.isEmpty));
  });

  test('$name - isNotEmpty', () {
    expect(wrapped.isNotEmpty, equals(original.isNotEmpty));
  });

  test('$name - iterator', () {
    Iterator wrapIter = wrapped.iterator;
    Iterator origIter = original.iterator;
    while (origIter.moveNext()) {
      expect(wrapIter.moveNext(), equals(true));
      expect(wrapIter.current, equals(origIter.current));
    }
    expect(wrapIter.moveNext(), equals(false));
  });

  test('$name - join', () {
    expect(wrapped.join(''), equals(original.join('')));
    expect(wrapped.join('-'), equals(original.join('-')));
  });

  test('$name - last', () {
    if (original.isEmpty) {
      expect(() => wrapped.last, throwsStateError);
    } else {
      expect(wrapped.last, equals(original.last));
    }
  });

  test('$name - lastWhere', () {
    if (original.isEmpty) {
      expect(() => wrapped.lastWhere((_) => true), throwsStateError);
    } else {
      expect(wrapped.lastWhere((_) => true),
          equals(original.lastWhere((_) => true)));
    }
    expect(() => wrapped.lastWhere((_) => false), throwsStateError);
  });

  test('$name - length', () {
    expect(wrapped.length, equals(original.length));
  });

  test('$name - map', () {
    expect(wrapped.map((x) => '[$x]'), equals(original.map((x) => '[$x]')));
  });

  test('$name - reduce', () {
    if (original.isEmpty) {
      expect(() => wrapped.reduce((x, y) => x + y), throwsStateError);
    } else {
      expect(wrapped.reduce((x, y) => x + y),
          equals(original.reduce((x, y) => x + y)));
    }
  });

  test('$name - single', () {
    if (original.length != 1) {
      expect(() => wrapped.single, throwsStateError);
    } else {
      expect(wrapped.single, equals(original.single));
    }
  });

  test('$name - singleWhere', () {
    if (original.length != 1) {
      expect(() => wrapped.singleWhere((_) => true), throwsStateError);
    } else {
      expect(wrapped.singleWhere((_) => true),
          equals(original.singleWhere((_) => true)));
    }
    expect(() => wrapped.singleWhere((_) => false), throwsStateError);
  });

  test('$name - skip', () {
    expect(wrapped.skip(0), orderedEquals(original.skip(0)));
    expect(wrapped.skip(1), orderedEquals(original.skip(1)));
    expect(wrapped.skip(5), orderedEquals(original.skip(5)));
  });

  test('$name - skipWhile', () {
    expect(wrapped.skipWhile((x) => true),
        orderedEquals(original.skipWhile((x) => true)));
    expect(wrapped.skipWhile((x) => false),
        orderedEquals(original.skipWhile((x) => false)));
    expect(wrapped.skipWhile((x) => x != 42),
        orderedEquals(original.skipWhile((x) => x != 42)));
  });

  test('$name - take', () {
    expect(wrapped.take(0), orderedEquals(original.take(0)));
    expect(wrapped.take(1), orderedEquals(original.take(1)));
    expect(wrapped.take(5), orderedEquals(original.take(5)));
  });

  test('$name - takeWhile', () {
    expect(wrapped.takeWhile((x) => true),
        orderedEquals(original.takeWhile((x) => true)));
    expect(wrapped.takeWhile((x) => false),
        orderedEquals(original.takeWhile((x) => false)));
    expect(wrapped.takeWhile((x) => x != 42),
        orderedEquals(original.takeWhile((x) => x != 42)));
  });

  test('$name - toList', () {
    expect(wrapped.toList(), orderedEquals(original.toList()));
    expect(wrapped.toList(growable: false),
        orderedEquals(original.toList(growable: false)));
  });

  test('$name - toSet', () {
    expect(wrapped.toSet(), unorderedEquals(original.toSet()));
  });

  test('$name - where', () {
    expect(
        wrapped.where((x) => true), orderedEquals(original.where((x) => true)));
    expect(wrapped.where((x) => false),
        orderedEquals(original.where((x) => false)));
    expect(wrapped.where((x) => x != 42),
        orderedEquals(original.where((x) => x != 42)));
  });
}

void testReadList(List original, List wrapped, String name) {
  test('$name - length', () {
    expect(wrapped.length, equals(original.length));
  });

  test('$name - isEmpty', () {
    expect(wrapped.isEmpty, equals(original.isEmpty));
  });

  test('$name - isNotEmpty', () {
    expect(wrapped.isNotEmpty, equals(original.isNotEmpty));
  });

  test('$name - []', () {
    if (original.isEmpty) {
      expect(() {
        wrapped[0];
      }, throwsRangeError);
    } else {
      expect(wrapped[0], equals(original[0]));
    }
  });

  test('$name - indexOf', () {
    expect(wrapped.indexOf(42), equals(original.indexOf(42)));
  });

  test('$name - lastIndexOf', () {
    expect(wrapped.lastIndexOf(42), equals(original.lastIndexOf(42)));
  });

  test('$name - getRange', () {
    var len = original.length;
    expect(wrapped.getRange(0, len), equals(original.getRange(0, len)));
    expect(wrapped.getRange(len ~/ 2, len),
        equals(original.getRange(len ~/ 2, len)));
    expect(
        wrapped.getRange(0, len ~/ 2), equals(original.getRange(0, len ~/ 2)));
  });

  test('$name - sublist', () {
    var len = original.length;
    expect(wrapped.sublist(0), equals(original.sublist(0)));
    expect(wrapped.sublist(len ~/ 2), equals(original.sublist(len ~/ 2)));
    expect(wrapped.sublist(0, len ~/ 2), equals(original.sublist(0, len ~/ 2)));
  });

  test('$name - asMap', () {
    expect(wrapped.asMap(), equals(original.asMap()));
  });
}

void testNoWriteList(List<int> original, List<int> wrapped, String name) {
  var copy = List.of(original);

  void testThrows(name, thunk) {
    test(name, () {
      expect(thunk, throwsUnsupportedError);
      // No modifications happened.
      expect(original, equals(copy));
    });
  }

  testThrows('$name - []= throws', () {
    wrapped[0] = 42;
  });

  testThrows('$name - sort throws', () {
    wrapped.sort();
  });

  testThrows('$name - fillRange throws', () {
    wrapped.fillRange(0, wrapped.length, 42);
  });

  testThrows('$name - setRange throws', () {
    wrapped.setRange(
        0, wrapped.length, Iterable.generate(wrapped.length, (i) => i));
  });

  testThrows('$name - setAll throws', () {
    wrapped.setAll(0, Iterable.generate(wrapped.length, (i) => i));
  });
}

void testWriteList(List<int> original, List wrapped, String name) {
  var copy = List.of(original);

  test('$name - []=', () {
    if (original.isNotEmpty) {
      var originalFirst = original[0];
      wrapped[0] = originalFirst + 1;
      expect(original[0], equals(originalFirst + 1));
      original[0] = originalFirst;
    } else {
      expect(() {
        wrapped[0] = 42;
      }, throwsRangeError);
    }
  });

  test('$name - sort', () {
    var sortCopy = List.of(original);
    sortCopy.sort();
    wrapped.sort();
    expect(original, orderedEquals(sortCopy));
    original.setAll(0, copy);
  });

  test('$name - fillRange', () {
    wrapped.fillRange(0, wrapped.length, 37);
    for (var i = 0; i < original.length; i++) {
      expect(original[i], equals(37));
    }
    original.setAll(0, copy);
  });

  test('$name - setRange', () {
    List reverseList = original.reversed.toList();
    wrapped.setRange(0, wrapped.length, reverseList);
    expect(original, equals(reverseList));
    original.setAll(0, copy);
  });

  test('$name - setAll', () {
    List reverseList = original.reversed.toList();
    wrapped.setAll(0, reverseList);
    expect(original, equals(reverseList));
    original.setAll(0, copy);
  });
}

void testNoChangeLengthList(
    List<int> original, List<int> wrapped, String name) {
  var copy = List.of(original);

  void testThrows(String name, thunk) {
    test(name, () {
      expect(thunk, throwsUnsupportedError);
      // No modifications happened.
      expect(original, equals(copy));
    });
  }

  testThrows('$name - length= throws', () {
    wrapped.length = 100;
  });

  testThrows('$name - add throws', () {
    wrapped.add(42);
  });

  testThrows('$name - addAll throws', () {
    wrapped.addAll([42]);
  });

  testThrows('$name - insert throws', () {
    wrapped.insert(0, 42);
  });

  testThrows('$name - insertAll throws', () {
    wrapped.insertAll(0, [42]);
  });

  testThrows('$name - remove throws', () {
    wrapped.remove(42);
  });

  testThrows('$name - removeAt throws', () {
    wrapped.removeAt(0);
  });

  testThrows('$name - removeLast throws', () {
    wrapped.removeLast();
  });

  testThrows('$name - removeWhere throws', () {
    wrapped.removeWhere((element) => false);
  });

  testThrows('$name - retainWhere throws', () {
    wrapped.retainWhere((element) => true);
  });

  testThrows('$name - removeRange throws', () {
    wrapped.removeRange(0, wrapped.length);
  });

  testThrows('$name - replaceRange throws', () {
    wrapped.replaceRange(0, wrapped.length, [42]);
  });

  testThrows('$name - clear throws', () {
    wrapped.clear();
  });
}

void testReadSet(Set<int> original, Set<int> wrapped, String name) {
  var copy = Set.of(original);

  test('$name - containsAll', () {
    expect(wrapped.containsAll(copy), isTrue);
    expect(wrapped.containsAll(copy.toList()), isTrue);
    expect(wrapped.containsAll([]), isTrue);
    expect(wrapped.containsAll([42]), equals(original.containsAll([42])));
  });

  test('$name - intersection', () {
    expect(wrapped.intersection({}), isEmpty);
    expect(wrapped.intersection(copy), unorderedEquals(original));
    expect(
        wrapped.intersection({42}), Set.of(original.contains(42) ? [42] : []));
  });

  test('$name - union', () {
    expect(wrapped.union({}), unorderedEquals(original));
    expect(wrapped.union(copy), unorderedEquals(original));
    expect(wrapped.union({42}), equals(original.union({42})));
  });

  test('$name - difference', () {
    expect(wrapped.difference({}), unorderedEquals(original));
    expect(wrapped.difference(copy), isEmpty);
    expect(wrapped.difference({42}), equals(original.difference({42})));
  });
}

void testNoChangeSet(Set<int> original, Set<int> wrapped, String name) {
  var originalElements = original.toList();

  void testThrows(name, thunk) {
    test(name, () {
      expect(thunk, throwsUnsupportedError);
      // No modifications happened.
      expect(original.toList(), equals(originalElements));
    });
  }

  testThrows('$name - add throws', () {
    wrapped.add(42);
  });

  testThrows('$name - addAll throws', () {
    wrapped.addAll([42]);
  });

  testThrows('$name - addAll empty throws', () {
    wrapped.addAll([]);
  });

  testThrows('$name - remove throws', () {
    wrapped.remove(42);
  });

  testThrows('$name - removeAll throws', () {
    wrapped.removeAll([42]);
  });

  testThrows('$name - removeAll empty throws', () {
    wrapped.removeAll([]);
  });

  testThrows('$name - retainAll throws', () {
    wrapped.retainAll([42]);
  });

  testThrows('$name - removeWhere throws', () {
    wrapped.removeWhere((_) => false);
  });

  testThrows('$name - retainWhere throws', () {
    wrapped.retainWhere((_) => true);
  });

  testThrows('$name - clear throws', () {
    wrapped.clear();
  });
}

void testReadMap(Map<int, int> original, Map<int, int> wrapped, String name) {
  test('$name length', () {
    expect(wrapped.length, equals(original.length));
  });

  test('$name isEmpty', () {
    expect(wrapped.isEmpty, equals(original.isEmpty));
  });

  test('$name isNotEmpty', () {
    expect(wrapped.isNotEmpty, equals(original.isNotEmpty));
  });

  test('$name operator[]', () {
    expect(wrapped[0], equals(original[0]));
    expect(wrapped[999], equals(original[999]));
  });

  test('$name containsKey', () {
    expect(wrapped.containsKey(0), equals(original.containsKey(0)));
    expect(wrapped.containsKey(999), equals(original.containsKey(999)));
  });

  test('$name containsValue', () {
    expect(wrapped.containsValue(0), equals(original.containsValue(0)));
    expect(wrapped.containsValue(999), equals(original.containsValue(999)));
  });

  test('$name forEach', () {
    var origCnt = 0;
    var wrapCnt = 0;
    wrapped.forEach((k, v) {
      wrapCnt += 1 << k + 3 * v;
    });
    original.forEach((k, v) {
      origCnt += 1 << k + 3 * v;
    });
    expect(wrapCnt, equals(origCnt));
  });

  test('$name keys', () {
    expect(wrapped.keys, orderedEquals(original.keys));
  });

  test('$name values', () {
    expect(wrapped.values, orderedEquals(original.values));
  });
}

void testNoChangeMap(
    Map<int, int> original, Map<int, int> wrapped, String name) {
  var copy = Map.of(original);

  void testThrows(name, thunk) {
    test(name, () {
      expect(thunk, throwsUnsupportedError);
      // No modifications happened.
      expect(original, equals(copy));
    });
  }

  testThrows('$name operator[]= throws', () {
    wrapped[0] = 42;
  });

  testThrows('$name putIfAbsent throws', () {
    wrapped.putIfAbsent(0, () => 42);
  });

  testThrows('$name addAll throws', () {
    wrapped.addAll({42: 42});
  });

  testThrows('$name addAll empty throws', () {
    wrapped.addAll({});
  });

  testThrows('$name remove throws', () {
    wrapped.remove(0);
  });

  testThrows('$name clear throws', () {
    wrapped.clear();
  });
}
