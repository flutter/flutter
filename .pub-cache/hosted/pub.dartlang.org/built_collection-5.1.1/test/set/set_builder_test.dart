// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:collection' show SplayTreeSet;
import 'package:built_collection/src/internal/null_safety.dart';
import 'package:built_collection/src/set.dart';
import 'package:test/test.dart';

import '../performance.dart';

void main() {
  group('SetBuilder', () {
    test('allows <dynamic>', () {
      SetBuilder<dynamic>();
    });

    test('allows <Object>', () {
      SetBuilder<Object>();
    });

    test('throws on null add', () {
      var builder = SetBuilder<int>();
      expect(() => builder.add(null as dynamic), throwsA(anything));
      expect(builder.build(), isEmpty);
    });

    test('nullable does not throw on null add', () {
      var builder = SetBuilder<int?>();
      builder.add(null);
      expect(builder.build(), {null});
    });

    test('throws on null addAll', () {
      var builder = SetBuilder<int>();
      expect(() => builder.addAll([0, 1, null as dynamic]), throwsA(anything));
      expect(builder.build(), isEmpty);
    });

    test('nullable does not throw on null addAll', () {
      var builder = SetBuilder<int?>();
      builder.addAll([0, 1, null]);
      expect(builder.build(), orderedEquals([0, 1, null]));
    });

    test('throws on null map', () {
      var builder = SetBuilder<int>([0, 1, 2]);
      expect(() => builder.map((x) => null as dynamic), throwsA(anything));
      expect(builder.build(), orderedEquals([0, 1, 2]));
    });

    test('nullable does not throw on null map', () {
      var builder = SetBuilder<int?>([0, 1, 2]);
      builder.map((x) => null);
      expect(builder.build(), orderedEquals([null]));
    });

    test('throws on null expand', () {
      var builder = SetBuilder<int>([0, 1, 2]);
      expect(
          () => builder.expand((x) => [x, null as dynamic]), throwsA(anything));
      expect(builder.build(), orderedEquals([0, 1, 2]));
    });

    test('nullable does not throw on null expand', () {
      var builder = SetBuilder<int?>([0, 1, 2]);
      builder.expand((x) => [x, null]);
      expect(builder.build(), orderedEquals([0, null, 1, 2]));
    });

    test('throws on null withBase', () {
      var builder = SetBuilder<int>([2, 0, 1]);
      expect(() => builder.withBase(null as dynamic), throwsA(anything));
      expect(builder.build(), orderedEquals([2, 0, 1]));
    });

    test('throws on wrong type addAll', () {
      // Legacy mode allows List.from to add incorrect types to List, so wrong
      // type is allowed; just pass.
      if (!isSoundMode) return;

      var builder = SetBuilder<int>();
      expect(
          () => builder.addAll(List<int>.from([0, 1, '0'])), throwsA(anything));
      expect(builder.build(), isEmpty);
    });

    test('has replace method that replaces all data', () {
      expect((SetBuilder<int>()..replace([0, 1, 2])).build(), [0, 1, 2]);
    });

    test('reuses BuiltSet passed to replace if it has the same base', () {
      var treeSetBase = () => SplayTreeSet<int>();
      var set = BuiltSet<int>.build((b) => b
        ..withBase(treeSetBase)
        ..addAll([1, 2]));
      var builder = SetBuilder<int>()
        ..withBase(treeSetBase)
        ..replace(set);
      expect(builder.build(), same(set));
    });

    test("doesn't reuse BuiltSet passed to replace if it has a different base",
        () {
      var set = BuiltSet<int>.build((b) => b
        ..withBase(() => SplayTreeSet<int>())
        ..addAll([1, 2]));
      var builder = SetBuilder<int>()..replace(set);
      expect(builder.build(), isNot(same(set)));
    });

    test('has withBase method that changes the underlying set type', () {
      var builder = SetBuilder<int>([2, 0, 1]);
      builder.withBase(() => SplayTreeSet<int>());
      expect(builder.build(), orderedEquals([0, 1, 2]));
    });

    test('has withDefaultBase method that resets the underlying set type', () {
      var builder = SetBuilder<int>()
        ..withBase(() => SplayTreeSet<int>())
        ..withDefaultBase()
        ..addAll([2, 0, 1]);
      expect(builder.build(), orderedEquals([2, 0, 1]));
    });

    // Lazy copies.

    test('does not mutate BuiltSet following reuse of underlying Set', () {
      var set = BuiltSet<int>([1, 2]);
      var setBuilder = set.toBuilder();
      setBuilder.add(3);
      expect(set, [1, 2]);
    });

    test('converts to BuiltSet without copying', () {
      var makeLongSetBuilder = () =>
          SetBuilder<int>(Set<int>.from(List<int>.generate(100000, (x) => x)));
      var longSetBuilder = makeLongSetBuilder();
      var buildLongSetBuilder = () => longSetBuilder.build();

      expectMuchFaster(buildLongSetBuilder, makeLongSetBuilder);
    });

    test('does not mutate BuiltSet following mutates after build', () {
      var setBuilder = SetBuilder<int>([1, 2]);

      var set1 = setBuilder.build();
      expect(set1, [1, 2]);

      setBuilder.add(3);
      expect(set1, [1, 2]);
    });

    test('returns identical BuiltSet on repeated build', () {
      var setBuilder = SetBuilder<int>([1, 2]);
      expect(setBuilder.build(), same(setBuilder.build()));
    });

    // Set.

    test('has a method like Set.length', () {
      expect(SetBuilder<int>([1, 2]).length, 2);
      expect(BuiltSet<int>([1, 2]).toBuilder().length, 2);

      expect(SetBuilder<int>([]).length, 0);
      expect(BuiltSet<int>([]).toBuilder().length, 0);
    });

    test('has a method like Set.isEmpty', () {
      expect(SetBuilder<int>([1, 2]).isEmpty, false);
      expect(BuiltSet<int>([1, 2]).toBuilder().isEmpty, false);

      expect(SetBuilder<int>().isEmpty, true);
      expect(BuiltSet<int>().toBuilder().isEmpty, true);
    });

    test('has a method like Set.isNotEmpty', () {
      expect(SetBuilder<int>([1, 2]).isNotEmpty, true);
      expect(BuiltSet<int>([1, 2]).toBuilder().isNotEmpty, true);

      expect(SetBuilder<int>().isNotEmpty, false);
      expect(BuiltSet<int>().toBuilder().isNotEmpty, false);
    });

    test('has a method like Set.add', () {
      expect((SetBuilder<int>()..add(1)).build(), [1]);
      expect((BuiltSet<int>().toBuilder()..add(1)).build(), [1]);
      expect(SetBuilder<int>().add(1), true);
      expect((SetBuilder<int>()..add(1)).add(1), false);
    });

    test('has a method like Set.addAll', () {
      expect((SetBuilder<int>()..addAll([1, 2])).build(), [1, 2]);
      expect((BuiltSet<int>().toBuilder()..addAll([1, 2])).build(), [1, 2]);
    });

    test('has a method like Set.clear', () {
      expect((SetBuilder<int>([1, 2])..clear()).build(), []);
      expect((BuiltSet<int>([1, 2]).toBuilder()..clear()).build(), []);
    });

    test('has a method like Set.remove', () {
      expect(SetBuilder<int>([1, 2]).remove(2), true);
      expect(SetBuilder<int>([1, 2]).remove(3), false);
      expect((SetBuilder<int>([1, 2])..remove(2)).build(), [1]);
      expect((BuiltSet<int>([1, 2]).toBuilder()..remove(2)).build(), [1]);
    });

    test('has a method like Set.removeAll', () {
      expect((SetBuilder<int>([1, 2])..removeAll([2])).build(), [1]);
      expect((BuiltSet<int>([1, 2]).toBuilder()..removeAll([2])).build(), [1]);
    });

    test('has a method like Set.removeWhere', () {
      expect(
          (SetBuilder<int>([1, 2])..removeWhere((x) => x == 1)).build(), [2]);
      expect(
          (BuiltSet<int>([1, 2]).toBuilder()..removeWhere((x) => x == 1))
              .build(),
          [2]);
    });

    test('has a method like Set.retainAll', () {
      expect((SetBuilder<int>([1, 2])..retainAll([1])).build(), [1]);
      expect((BuiltSet<int>([1, 2]).toBuilder()..retainAll([1])).build(), [1]);
    });

    test('has a method like Set.retainWhere', () {
      expect(
          (SetBuilder<int>([1, 2])..retainWhere((x) => x == 1)).build(), [1]);
      expect(
          (BuiltSet<int>([1, 2]).toBuilder()..retainWhere((x) => x == 1))
              .build(),
          [1]);
    });

    // Iterable.

    test('has a method like Iterable.map that updates in place', () {
      expect((SetBuilder<int>([1, 2])..map((x) => x + 1)).build(), [2, 3]);
      expect((BuiltSet<int>([1, 2]).toBuilder()..map((x) => x + 1)).build(),
          [2, 3]);
    });

    test('has a method like Iterable.where that updates in place', () {
      expect((SetBuilder<int>([1, 2])..where((x) => x == 2)).build(), [2]);
      expect((BuiltSet<int>([1, 2]).toBuilder()..where((x) => x == 2)).build(),
          [2]);
    });

    test('has a method like Iterable.expand that updates in place', () {
      expect((SetBuilder<int>([1, 2])..expand((x) => [x, x + 2])).build(),
          [1, 3, 2, 4]);
      expect(
          (BuiltSet<int>([1, 2]).toBuilder()..expand((x) => [x, x + 2]))
              .build(),
          [1, 3, 2, 4]);
    });

    test('has a method like Iterable.take that updates in place', () {
      expect((SetBuilder<int>([1, 2])..take(1)).build(), [1]);
      expect((BuiltSet<int>([1, 2]).toBuilder()..take(1)).build(), [1]);
    });

    test('has a method like Iterable.takeWhile that updates in place', () {
      expect((SetBuilder<int>([1, 2])..takeWhile((x) => x == 1)).build(), [1]);
      expect(
          (BuiltSet<int>([1, 2]).toBuilder()..takeWhile((x) => x == 1)).build(),
          [1]);
    });

    test('has a method like Iterable.skip that updates in place', () {
      expect((SetBuilder<int>([1, 2])..skip(1)).build(), [2]);
      expect((BuiltSet<int>([1, 2]).toBuilder()..skip(1)).build(), [2]);
    });

    test('has a method like Iterable.skipWhile that updates in place', () {
      expect((SetBuilder<int>([1, 2])..skipWhile((x) => x == 1)).build(), [2]);
      expect(
          (BuiltSet<int>([1, 2]).toBuilder()..skipWhile((x) => x == 1)).build(),
          [2]);
    });

    group('iterates at most once in', () {
      late Iterable<int> onceIterable;
      setUp(() {
        var count = 0;
        onceIterable = [1].map((x) {
          ++count;
          if (count > 1) throw StateError('Iterated twice.');
          return x;
        });
      });

      test('addAll', () {
        SetBuilder<int>().addAll(onceIterable);
      });
    });
  });
}
