import 'dart:math';

import 'package:hive/src/util/delegating_list_view_mixin.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  group('DelegatingIterable', () {
    late _TestList<String> testList;

    setUp(() {
      testList = _TestList(['a', 'b', 'cc']);
    });

    test('operator +', () {
      expect(testList + ['d', 'q'], ['a', 'b', 'cc', 'd', 'q']);
    });

    test('.any()', () {
      expect(testList.any((e) => e == 'b'), isTrue);
      expect(testList.any((e) => e == 'd'), isFalse);
    });

    test('.asMap()', () {
      expect(testList.asMap(), {0: 'a', 1: 'b', 2: 'cc'});
    });

    test('.cast()', () {
      List dynamicList = testList;
      expect(dynamicList.cast<String>(), isA<List<String>>());
    });

    test('.contains()', () {
      expect(testList.contains('b'), isTrue);
      expect(testList.contains('d'), isFalse);
    });

    test('.elementAt()', () {
      expect(testList.elementAt(1), 'b');
    });

    test('.every()', () {
      expect(testList.every((e) => e == 'b'), isFalse);
    });

    test('.expand()', () {
      expect(testList.expand((e) => e.codeUnits), [97, 98, 99, 99]);
    });

    test('.first()', () {
      expect(testList.first, 'a');
    });

    test('.firstWhere()', () {
      expect(testList.firstWhere((e) => e == 'b'), 'b');
      expect(testList.firstWhere((e) => e == 'd', orElse: () => 'e'), 'e');
    });

    test('.fold()', () {
      expect(testList.fold('z', (dynamic p, e) => p + e), 'zabcc');
    });

    test('.forEach()', () {
      final s = StringBuffer();
      testList.forEach(s.write);
      expect(s.toString(), 'abcc');
    });

    test('.getRange()', () {
      expect(testList.getRange(1, 2), ['b']);
    });

    test('.indexOf()', () {
      expect(testList.indexOf('b'), 1);
      expect(testList.indexOf('x'), -1);
    });

    test('.indexWhere()', () {
      expect(testList.indexWhere((e) => e == 'b'), 1);
      expect(testList.indexWhere((e) => e == 'x'), -1);
    });

    test('.isEmpty', () {
      expect(testList.isEmpty, isFalse);
      expect(_TestList([]).isEmpty, isTrue);
    });

    test('.isNotEmpty', () {
      expect(testList.isNotEmpty, isTrue);
      expect(_TestList([]).isNotEmpty, isFalse);
    });

    test('.followedBy()', () {
      expect(testList.followedBy(['d', 'e']), ['a', 'b', 'cc', 'd', 'e']);
      expect(testList.followedBy(testList), ['a', 'b', 'cc', 'a', 'b', 'cc']);
    });

    test('.forEach()', () {
      final it = testList.iterator;
      if (soundNullSafety) {
        expect(() => it.current, throwsA(anything));
      } else {
        expect(it.current, null);
      }
      expect(it.moveNext(), isTrue);
      expect(it.current, 'a');
      expect(it.moveNext(), isTrue);
      expect(it.current, 'b');
      expect(it.moveNext(), isTrue);
      expect(it.current, 'cc');
      expect(it.moveNext(), isFalse);
      if (soundNullSafety) {
        expect(() => it.current, throwsA(anything));
      } else {
        expect(it.current, null);
      }
    });

    test('.join()', () {
      expect(testList.join(), 'abcc');
      expect(testList.join(','), 'a,b,cc');
    });

    test('.indexOf()', () {
      expect(testList.lastIndexOf('b'), 1);
      expect(testList.lastIndexOf('x'), -1);
    });

    test('.indexWhere()', () {
      expect(testList.lastIndexWhere((e) => e == 'b'), 1);
      expect(testList.lastIndexWhere((e) => e == 'x'), -1);
    });

    test('.last', () {
      expect(testList.last, 'cc');
    });

    test('.lastWhere()', () {
      expect(testList.lastWhere((e) => e == 'b'), 'b');
      expect(testList.lastWhere((e) => e == 'd', orElse: () => 'e'), 'e');
    });

    test('.length', () {
      expect(testList.length, 3);
    });

    test('.map()', () {
      expect(testList.map((e) => e.toUpperCase()), ['A', 'B', 'CC']);
    });

    test('.reduce()', () {
      expect(testList.reduce((value, element) => value + element), 'abcc');
    });

    test('.reversed ', () {
      expect(testList.reversed, ['cc', 'b', 'a']);
    });

    test('single', () {
      expect(() => testList.single, throwsStateError);
      expect(_TestList(['a']).single, 'a');
    });

    test('.singleWhere()', () {
      expect(testList.singleWhere((e) => e == 'b'), 'b');
      expect(() => testList.singleWhere((e) => e == 'd'), throwsStateError);
      expect(testList.singleWhere((e) => e == 'd', orElse: () => 'X'), 'X');
    });

    test('.skip()', () {
      expect(testList.skip(1), ['b', 'cc']);
    });

    test('.skipWhile()', () {
      expect(testList.skipWhile((e) => e == 'a'), ['b', 'cc']);
    });

    test('.sublist()', () {
      expect(testList.sublist(1, 2), ['b']);
    });

    test('.take()', () {
      expect(testList.take(1), ['a']);
    });

    test('.skipWhile()', () {
      expect(testList.takeWhile((e) => e == 'a'), ['a']);
    });

    test('.toList()', () {
      expect(testList.toList(), ['a', 'b', 'cc']);
    });

    test('.toSet()', () {
      expect(testList.toSet(), <String>{'a', 'b', 'cc'});
    });

    test('.where()', () {
      expect(testList.where((e) => e.length == 1), ['a', 'b']);
    });

    test('.whereType()', () {
      expect(testList.whereType<String>(), ['a', 'b', 'cc']);
    });
  });
}

class _TestList<T> with DelegatingListViewMixin<T> {
  final List<T> _delegate;

  _TestList(this._delegate);

  @override
  List<T> get delegate => _delegate;

  @override
  void operator []=(int index, T value) => throw UnimplementedError();

  @override
  void add(T value) => throw UnimplementedError();

  @override
  void addAll(Iterable<T> iterable) => throw UnimplementedError();

  @override
  void clear() => throw UnimplementedError();

  @override
  void fillRange(int start, int end, [T? fillValue]) =>
      throw UnimplementedError();

  @override
  set first(T value) => throw UnimplementedError();

  @override
  void insert(int index, T element) => throw UnimplementedError();

  @override
  void insertAll(int index, Iterable<T> iterable) => throw UnimplementedError();

  @override
  set last(T value) => throw UnimplementedError();

  @override
  set length(int newLength) => throw UnimplementedError();

  @override
  bool remove(Object? value) => throw UnimplementedError();

  @override
  T removeAt(int index) => throw UnimplementedError();

  @override
  T removeLast() => throw UnimplementedError();

  @override
  void removeRange(int start, int end) => throw UnimplementedError();

  @override
  void removeWhere(bool Function(T element) test) => throw UnimplementedError();

  @override
  void replaceRange(int start, int end, Iterable<T> replacement) =>
      throw UnimplementedError();

  @override
  void retainWhere(bool Function(T element) test) => throw UnimplementedError();

  @override
  void setAll(int index, Iterable<T> iterable) => throw UnimplementedError();

  @override
  void setRange(int start, int end, Iterable<T> iterable,
          [int skipCount = 0]) =>
      throw UnimplementedError();

  @override
  void shuffle([Random? random]) => throw UnimplementedError();

  @override
  void sort([int Function(T a, T b)? compare]) => throw UnimplementedError();
}
