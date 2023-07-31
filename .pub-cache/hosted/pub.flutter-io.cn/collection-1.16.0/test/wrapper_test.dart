// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests wrapper utilities.

@TestOn('vm')
import 'dart:collection';
import 'dart:mirrors';

import 'package:collection/collection.dart';
import 'package:test/test.dart';

// Test that any member access/call on the wrapper object is equal to
// an expected access on the wrapped object.
// This is implemented by capturing accesses using noSuchMethod and comparing
// them to expected accesses captured previously.

// Compare two Invocations for having equal type and arguments.
void testInvocations(Invocation i1, Invocation i2) {
  var name = '${i1.memberName}';
  expect(i1.isGetter, equals(i2.isGetter), reason: name);
  expect(i1.isSetter, equals(i2.isSetter), reason: name);
  expect(i1.memberName, equals(i2.memberName), reason: name);
  expect(i1.positionalArguments, equals(i2.positionalArguments), reason: name);
  expect(i1.namedArguments, equals(i2.namedArguments), reason: name);
}

/// Utility class to record a member access and a member access on a wrapped
/// object, and compare them for equality.
///
/// Use as `(expector..someAccess()).equals.someAccess();`.
/// Alle the intercepted member accesses returns `null`.
abstract class Expector {
  dynamic wrappedChecker(Invocation i);
  // After calling any member on the Expector, equals is an object that expects
  // the *same* invocation on the wrapped object.
  dynamic equals;

  InstanceMirror get mirror;

  @override
  dynamic noSuchMethod(Invocation actual) {
    equals = wrappedChecker(actual);
    return mirror.delegate(actual);
  }

  @override
  String toString() {
    // Cannot return an _Equals object since toString must return a String.
    // Just set equals and return a string.
    equals = wrappedChecker(toStringInvocation);
    return '';
  }
}

// Parameterization of noSuchMethod. Calls [_action] on every
// member invocation.
class InvocationChecker {
  final Invocation _expected;
  final InstanceMirror _instanceMirror;

  InvocationChecker(this._expected, this._instanceMirror);

  @override
  dynamic noSuchMethod(Invocation actual) {
    testInvocations(_expected, actual);
    return _instanceMirror.delegate(actual);
  }

  @override
  String toString() {
    testInvocations(_expected, toStringInvocation);
    return '';
  }
  // Could also handle runtimeType, hashCode and == the same way as
  // toString, but we are not testing them since collections generally
  // don't override those and so the wrappers don't forward those.
}

final toStringInvocation = Invocation.method(#toString, const []);

// InvocationCheckers with types Queue, Set, List or Iterable to allow them as
// argument to DelegatingIterable/Set/List/Queue.
class IterableInvocationChecker<T> extends InvocationChecker
    implements Iterable<T> {
  IterableInvocationChecker(Invocation expected, InstanceMirror mirror)
      : super(expected, mirror);
}

class ListInvocationChecker<T> extends InvocationChecker implements List<T> {
  ListInvocationChecker(Invocation expected, InstanceMirror mirror)
      : super(expected, mirror);
}

class SetInvocationChecker<T> extends InvocationChecker implements Set<T> {
  SetInvocationChecker(Invocation expected, InstanceMirror mirror)
      : super(expected, mirror);
}

class QueueInvocationChecker<T> extends InvocationChecker implements Queue<T> {
  QueueInvocationChecker(Invocation expected, InstanceMirror mirror)
      : super(expected, mirror);
}

class MapInvocationChecker<K, V> extends InvocationChecker
    implements Map<K, V> {
  MapInvocationChecker(Invocation expected, InstanceMirror mirror)
      : super(expected, mirror);
}

// Expector that wraps in DelegatingIterable.
class IterableExpector<T> extends Expector implements Iterable<T> {
  @override
  final InstanceMirror mirror;

  IterableExpector(Iterable<T> realInstance) : mirror = reflect(realInstance);

  @override
  dynamic wrappedChecker(Invocation i) =>
      DelegatingIterable<T>(IterableInvocationChecker<T>(i, mirror));
}

// Expector that wraps in DelegatingList.
class ListExpector<T> extends IterableExpector<T> implements List<T> {
  ListExpector(List<T> realInstance) : super(realInstance);

  @override
  dynamic wrappedChecker(Invocation i) =>
      DelegatingList<T>(ListInvocationChecker<T>(i, mirror));
}

// Expector that wraps in DelegatingSet.
class SetExpector<T> extends IterableExpector<T> implements Set<T> {
  SetExpector(Set<T> realInstance) : super(realInstance);

  @override
  dynamic wrappedChecker(Invocation i) =>
      DelegatingSet<T>(SetInvocationChecker<T>(i, mirror));
}

// Expector that wraps in DelegatingSet.
class QueueExpector<T> extends IterableExpector<T> implements Queue<T> {
  QueueExpector(Queue<T> realInstance) : super(realInstance);

  @override
  dynamic wrappedChecker(Invocation i) =>
      DelegatingQueue<T>(QueueInvocationChecker<T>(i, mirror));
}

// Expector that wraps in DelegatingMap.
class MapExpector<K, V> extends Expector implements Map<K, V> {
  @override
  final InstanceMirror mirror;

  MapExpector(Map<K, V> realInstance) : mirror = reflect(realInstance);

  @override
  dynamic wrappedChecker(Invocation i) =>
      DelegatingMap<K, V>(MapInvocationChecker<K, V>(i, mirror));
}

// Utility values to use as arguments in calls.
// ignore: prefer_void_to_null
Null func0() => null;
dynamic func1(dynamic x) => null;
dynamic func2(dynamic x, dynamic y) => null;
bool boolFunc(dynamic x) => true;
Iterable<dynamic> expandFunc(dynamic x) => [x];
dynamic foldFunc(dynamic previous, dynamic next) => previous;
int compareFunc(dynamic x, dynamic y) => 0;
var val = 10;

void main() {
  void testIterable(IterableExpector expect) {
    (expect..any(boolFunc)).equals.any(boolFunc);
    (expect..contains(val)).equals.contains(val);
    (expect..elementAt(0)).equals.elementAt(0);
    (expect..every(boolFunc)).equals.every(boolFunc);
    (expect..expand(expandFunc)).equals.expand(expandFunc);
    (expect..first).equals.first;
    // Default values of the Iterable interface will be added in the
    // second call to firstWhere, so we must record them in our
    // expectation (which doesn't have the interface implemented or
    // its default values).
    (expect..firstWhere(boolFunc, orElse: null)).equals.firstWhere(boolFunc);
    (expect..firstWhere(boolFunc, orElse: func0))
        .equals
        .firstWhere(boolFunc, orElse: func0);
    (expect..fold(42, foldFunc)).equals.fold(42, foldFunc);
    (expect..forEach(boolFunc)).equals.forEach(boolFunc);
    (expect..isEmpty).equals.isEmpty;
    (expect..isNotEmpty).equals.isNotEmpty;
    (expect..iterator).equals.iterator;
    (expect..join('')).equals.join();
    (expect..join('X')).equals.join('X');
    (expect..last).equals.last;
    (expect..lastWhere(boolFunc, orElse: null)).equals.lastWhere(boolFunc);
    (expect..lastWhere(boolFunc, orElse: func0))
        .equals
        .lastWhere(boolFunc, orElse: func0);
    (expect..length).equals.length;
    (expect..map(func1)).equals.map(func1);
    (expect..reduce(func2)).equals.reduce(func2);
    (expect..single).equals.single;
    (expect..singleWhere(boolFunc, orElse: null)).equals.singleWhere(boolFunc);
    (expect..skip(5)).equals.skip(5);
    (expect..skipWhile(boolFunc)).equals.skipWhile(boolFunc);
    (expect..take(5)).equals.take(5);
    (expect..takeWhile(boolFunc)).equals.takeWhile(boolFunc);
    (expect..toList(growable: true)).equals.toList();
    (expect..toList(growable: true)).equals.toList(growable: true);
    (expect..toList(growable: false)).equals.toList(growable: false);
    (expect..toSet()).equals.toSet();
    (expect..toString()).equals.toString();
    (expect..where(boolFunc)).equals.where(boolFunc);
  }

  void testList(ListExpector expect) {
    testIterable(expect);
    // Later expects require at least 5 items
    (expect..add(val)).equals.add(val);
    (expect..addAll([val, val, val, val])).equals.addAll([val, val, val, val]);

    (expect..[4]).equals[4];
    (expect..[4] = 5).equals[4] = 5;

    (expect..asMap()).equals.asMap();
    (expect..fillRange(4, 5, null)).equals.fillRange(4, 5);
    (expect..fillRange(4, 5, val)).equals.fillRange(4, 5, val);
    (expect..getRange(4, 5)).equals.getRange(4, 5);
    (expect..indexOf(val, 0)).equals.indexOf(val);
    (expect..indexOf(val, 4)).equals.indexOf(val, 4);
    (expect..insert(4, val)).equals.insert(4, val);
    (expect..insertAll(4, [val])).equals.insertAll(4, [val]);
    (expect..lastIndexOf(val, null)).equals.lastIndexOf(val);
    (expect..lastIndexOf(val, 4)).equals.lastIndexOf(val, 4);
    (expect..replaceRange(4, 5, [val])).equals.replaceRange(4, 5, [val]);
    (expect..retainWhere(boolFunc)).equals.retainWhere(boolFunc);
    (expect..reversed).equals.reversed;
    (expect..setAll(4, [val])).equals.setAll(4, [val]);
    (expect..setRange(4, 5, [val], 0)).equals.setRange(4, 5, [val]);
    (expect..setRange(4, 5, [val, val], 1))
        .equals
        .setRange(4, 5, [val, val], 1);
    (expect..sort()).equals.sort();
    (expect..sort(compareFunc)).equals.sort(compareFunc);
    (expect..sublist(4, null)).equals.sublist(4);
    (expect..sublist(4, 5)).equals.sublist(4, 5);

    // Do destructive apis last so other ones can work properly
    (expect..removeAt(4)).equals.removeAt(4);
    (expect..remove(val)).equals.remove(val);
    (expect..removeLast()).equals.removeLast();
    (expect..removeRange(4, 5)).equals.removeRange(4, 5);
    (expect..removeWhere(boolFunc)).equals.removeWhere(boolFunc);
    (expect..length = 5).equals.length = 5;
    (expect..clear()).equals.clear();
  }

  void testSet(SetExpector expect) {
    testIterable(expect);
    var set = <dynamic>{};
    (expect..add(val)).equals.add(val);
    (expect..addAll([val])).equals.addAll([val]);
    (expect..clear()).equals.clear();
    (expect..containsAll([val])).equals.containsAll([val]);
    (expect..difference(set)).equals.difference(set);
    (expect..intersection(set)).equals.intersection(set);
    (expect..remove(val)).equals.remove(val);
    (expect..removeAll([val])).equals.removeAll([val]);
    (expect..removeWhere(boolFunc)).equals.removeWhere(boolFunc);
    (expect..retainAll([val])).equals.retainAll([val]);
    (expect..retainWhere(boolFunc)).equals.retainWhere(boolFunc);
    (expect..union(set)).equals.union(set);
  }

  void testQueue(QueueExpector expect) {
    testIterable(expect);
    (expect..add(val)).equals.add(val);
    (expect..addAll([val])).equals.addAll([val]);
    (expect..addFirst(val)).equals.addFirst(val);
    (expect..addLast(val)).equals.addLast(val);
    (expect..remove(val)).equals.remove(val);
    (expect..removeFirst()).equals.removeFirst();
    (expect..removeLast()).equals.removeLast();
    (expect..clear()).equals.clear();
  }

  void testMap(MapExpector expect) {
    var map = {};
    (expect..[val]).equals[val];
    (expect..[val] = val).equals[val] = val;
    (expect..addAll(map)).equals.addAll(map);
    (expect..clear()).equals.clear();
    (expect..containsKey(val)).equals.containsKey(val);
    (expect..containsValue(val)).equals.containsValue(val);
    (expect..forEach(func2)).equals.forEach(func2);
    (expect..isEmpty).equals.isEmpty;
    (expect..isNotEmpty).equals.isNotEmpty;
    (expect..keys).equals.keys;
    (expect..length).equals.length;
    (expect..putIfAbsent(val, func0)).equals.putIfAbsent(val, func0);
    (expect..remove(val)).equals.remove(val);
    (expect..values).equals.values;
    (expect..toString()).equals.toString();
  }

  // Runs tests of Set behavior.
  //
  // [setUpSet] should return a set with two elements: "foo" and "bar".
  void testTwoElementSet(Set<String> Function() setUpSet) {
    group('with two elements', () {
      late Set<String> set;
      setUp(() => set = setUpSet());

      test('.any', () {
        expect(set.any((element) => element == 'foo'), isTrue);
        expect(set.any((element) => element == 'baz'), isFalse);
      });

      test('.elementAt', () {
        expect(set.elementAt(0), equals('foo'));
        expect(set.elementAt(1), equals('bar'));
        expect(() => set.elementAt(2), throwsRangeError);
      });

      test('.every', () {
        expect(set.every((element) => element == 'foo'), isFalse);
        expect(set.every((element) => true), isTrue);
      });

      test('.expand', () {
        expect(set.expand((element) {
          return [element.substring(0, 1), element.substring(1)];
        }), equals(['f', 'oo', 'b', 'ar']));
      });

      test('.first', () {
        expect(set.first, equals('foo'));
      });

      test('.firstWhere', () {
        expect(set.firstWhere((element) => true), equals('foo'));
        expect(set.firstWhere((element) => element.startsWith('b')),
            equals('bar'));
        expect(() => set.firstWhere((element) => element is int),
            throwsStateError);
        expect(set.firstWhere((element) => element is int, orElse: () => 'baz'),
            equals('baz'));
      });

      test('.fold', () {
        expect(
            set.fold(
                'start', (dynamic previous, element) => previous + element),
            equals('startfoobar'));
      });

      test('.forEach', () {
        var values = [];
        set.forEach(values.add);
        expect(values, equals(['foo', 'bar']));
      });

      test('.iterator', () {
        var values = [];
        for (var element in set) {
          values.add(element);
        }
        expect(values, equals(['foo', 'bar']));
      });

      test('.join', () {
        expect(set.join(', '), equals('foo, bar'));
      });

      test('.last', () {
        expect(set.last, equals('bar'));
      });

      test('.lastWhere', () {
        expect(set.lastWhere((element) => true), equals('bar'));
        expect(
            set.lastWhere((element) => element.startsWith('f')), equals('foo'));
        expect(
            () => set.lastWhere((element) => element is int), throwsStateError);
        expect(set.lastWhere((element) => element is int, orElse: () => 'baz'),
            equals('baz'));
      });

      test('.map', () {
        expect(
            set.map((element) => element.substring(1)), equals(['oo', 'ar']));
      });

      test('.reduce', () {
        expect(set.reduce((previous, element) => previous + element),
            equals('foobar'));
      });

      test('.singleWhere', () {
        expect(() => set.singleWhere((element) => element == 'baz'),
            throwsStateError);
        expect(set.singleWhere((element) => element == 'foo'), 'foo');
        expect(() => set.singleWhere((element) => true), throwsStateError);
      });

      test('.skip', () {
        expect(set.skip(0), equals(['foo', 'bar']));
        expect(set.skip(1), equals(['bar']));
        expect(set.skip(2), equals([]));
      });

      test('.skipWhile', () {
        expect(set.skipWhile((element) => element.startsWith('f')),
            equals(['bar']));
        expect(set.skipWhile((element) => element.startsWith('z')),
            equals(['foo', 'bar']));
        expect(set.skipWhile((element) => true), equals([]));
      });

      test('.take', () {
        expect(set.take(0), equals([]));
        expect(set.take(1), equals(['foo']));
        expect(set.take(2), equals(['foo', 'bar']));
      });

      test('.takeWhile', () {
        expect(set.takeWhile((element) => element.startsWith('f')),
            equals(['foo']));
        expect(set.takeWhile((element) => element.startsWith('z')), equals([]));
        expect(set.takeWhile((element) => true), equals(['foo', 'bar']));
      });

      test('.toList', () {
        expect(set.toList(), equals(['foo', 'bar']));
        expect(() => set.toList(growable: false).add('baz'),
            throwsUnsupportedError);
        expect(set.toList()..add('baz'), equals(['foo', 'bar', 'baz']));
      });

      test('.toSet', () {
        expect(set.toSet(), equals({'foo', 'bar'}));
      });

      test('.where', () {
        expect(
            set.where((element) => element.startsWith('f')), equals(['foo']));
        expect(set.where((element) => element.startsWith('z')), equals([]));
        expect(set.whereType<String>(), equals(['foo', 'bar']));
      });

      test('.containsAll', () {
        expect(set.containsAll(['foo', 'bar']), isTrue);
        expect(set.containsAll(['foo']), isTrue);
        expect(set.containsAll(['foo', 'bar', 'qux']), isFalse);
      });

      test('.difference', () {
        expect(set.difference({'foo', 'baz'}), equals({'bar'}));
      });

      test('.intersection', () {
        expect(set.intersection({'foo', 'baz'}), equals({'foo'}));
      });

      test('.union', () {
        expect(set.union({'foo', 'baz'}), equals({'foo', 'bar', 'baz'}));
      });
    });
  }

  test('Iterable', () {
    testIterable(IterableExpector([1]));
  });

  test('List', () {
    testList(ListExpector([1]));
  });

  test('Set', () {
    testSet(SetExpector({1}));
  });

  test('Queue', () {
    testQueue(QueueExpector(Queue.of([1])));
  });

  test('Map', () {
    testMap(MapExpector({'a': 'b'}));
  });

  group('MapKeySet', () {
    late Map<String, dynamic> map;
    late Set<String> set;

    setUp(() {
      map = <String, int>{};
      set = MapKeySet<String>(map);
    });

    testTwoElementSet(() {
      map['foo'] = 1;
      map['bar'] = 2;
      return set;
    });

    test('.single', () {
      expect(() => set.single, throwsStateError);
      map['foo'] = 1;
      expect(set.single, equals('foo'));
      map['bar'] = 1;
      expect(() => set.single, throwsStateError);
    });

    test('.toString', () {
      expect(set.toString(), equals('{}'));
      map['foo'] = 1;
      map['bar'] = 2;
      expect(set.toString(), equals('{foo, bar}'));
    });

    test('.contains', () {
      expect(set.contains('foo'), isFalse);
      map['foo'] = 1;
      expect(set.contains('foo'), isTrue);
    });

    test('.isEmpty', () {
      expect(set.isEmpty, isTrue);
      map['foo'] = 1;
      expect(set.isEmpty, isFalse);
    });

    test('.isNotEmpty', () {
      expect(set.isNotEmpty, isFalse);
      map['foo'] = 1;
      expect(set.isNotEmpty, isTrue);
    });

    test('.length', () {
      expect(set, hasLength(0));
      map['foo'] = 1;
      expect(set, hasLength(1));
      map['bar'] = 2;
      expect(set, hasLength(2));
    });

    test('is unmodifiable', () {
      expect(() => set.add('baz'), throwsUnsupportedError);
      expect(() => set.addAll(['baz', 'bang']), throwsUnsupportedError);
      expect(() => set.remove('foo'), throwsUnsupportedError);
      expect(() => set.removeAll(['baz', 'bang']), throwsUnsupportedError);
      expect(() => set.retainAll(['foo']), throwsUnsupportedError);
      expect(() => set.removeWhere((_) => true), throwsUnsupportedError);
      expect(() => set.retainWhere((_) => true), throwsUnsupportedError);
      expect(() => set.clear(), throwsUnsupportedError);
    });
  });

  group('MapValueSet', () {
    late Map<String, String> map;
    late Set<String> set;

    setUp(() {
      map = <String, String>{};
      set =
          MapValueSet<String, String>(map, (string) => string.substring(0, 1));
    });

    testTwoElementSet(() {
      map['f'] = 'foo';
      map['b'] = 'bar';
      return set;
    });

    test('.single', () {
      expect(() => set.single, throwsStateError);
      map['f'] = 'foo';
      expect(set.single, equals('foo'));
      map['b'] = 'bar';
      expect(() => set.single, throwsStateError);
    });

    test('.toString', () {
      expect(set.toString(), equals('{}'));
      map['f'] = 'foo';
      map['b'] = 'bar';
      expect(set.toString(), equals('{foo, bar}'));
    });

    test('.contains', () {
      expect(set.contains('foo'), isFalse);
      map['f'] = 'foo';
      expect(set.contains('foo'), isTrue);
      expect(set.contains('fblthp'), isTrue);
    });

    test('.isEmpty', () {
      expect(set.isEmpty, isTrue);
      map['f'] = 'foo';
      expect(set.isEmpty, isFalse);
    });

    test('.isNotEmpty', () {
      expect(set.isNotEmpty, isFalse);
      map['f'] = 'foo';
      expect(set.isNotEmpty, isTrue);
    });

    test('.length', () {
      expect(set, hasLength(0));
      map['f'] = 'foo';
      expect(set, hasLength(1));
      map['b'] = 'bar';
      expect(set, hasLength(2));
    });

    test('.lookup', () {
      map['f'] = 'foo';
      expect(set.lookup('fblthp'), equals('foo'));
      expect(set.lookup('bar'), isNull);
    });

    test('.add', () {
      set.add('foo');
      set.add('bar');
      expect(map, equals({'f': 'foo', 'b': 'bar'}));
    });

    test('.addAll', () {
      set.addAll(['foo', 'bar']);
      expect(map, equals({'f': 'foo', 'b': 'bar'}));
    });

    test('.clear', () {
      map['f'] = 'foo';
      map['b'] = 'bar';
      set.clear();
      expect(map, isEmpty);
    });

    test('.remove', () {
      map['f'] = 'foo';
      map['b'] = 'bar';
      set.remove('fblthp');
      expect(map, equals({'b': 'bar'}));
    });

    test('.removeAll', () {
      map['f'] = 'foo';
      map['b'] = 'bar';
      map['q'] = 'qux';
      set.removeAll(['fblthp', 'qux']);
      expect(map, equals({'b': 'bar'}));
    });

    test('.removeWhere', () {
      map['f'] = 'foo';
      map['b'] = 'bar';
      map['q'] = 'qoo';
      set.removeWhere((element) => element.endsWith('o'));
      expect(map, equals({'b': 'bar'}));
    });

    test('.retainAll', () {
      map['f'] = 'foo';
      map['b'] = 'bar';
      map['q'] = 'qux';
      set.retainAll(['fblthp', 'qux']);
      expect(map, equals({'f': 'foo', 'q': 'qux'}));
    });

    test('.retainAll respects an unusual notion of equality', () {
      map = HashMap<String, String>(
          equals: (value1, value2) =>
              value1.toLowerCase() == value2.toLowerCase(),
          hashCode: (value) => value.toLowerCase().hashCode);
      set =
          MapValueSet<String, String>(map, (string) => string.substring(0, 1));

      map['f'] = 'foo';
      map['B'] = 'bar';
      map['Q'] = 'qux';
      set.retainAll(['fblthp', 'qux']);
      expect(map, equals({'f': 'foo', 'Q': 'qux'}));
    });

    test('.retainWhere', () {
      map['f'] = 'foo';
      map['b'] = 'bar';
      map['q'] = 'qoo';
      set.retainWhere((element) => element.endsWith('o'));
      expect(map, equals({'f': 'foo', 'q': 'qoo'}));
    });
  });
}
