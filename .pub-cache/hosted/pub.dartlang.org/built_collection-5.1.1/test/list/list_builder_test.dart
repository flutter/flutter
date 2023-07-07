// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' show Random;

import 'package:built_collection/src/list.dart';
import 'package:test/test.dart';

import '../performance.dart';

void main() {
  group('ListBuilder', () {
    test('allows <dynamic>', () {
      ListBuilder<dynamic>();
    });

    test('allows <Object>', () {
      ListBuilder<Object>();
    });

    test('throws on null assign', () {
      var builder = ListBuilder<int>([0]);
      expect(() => builder[0] = null as dynamic, throwsA(anything));
      expect(builder.build(), orderedEquals([0]));
    });

    test('nullable does not throw on null assign', () {
      var builder = ListBuilder<int?>([0]);
      builder[0] = null;
      expect(builder.build(), orderedEquals([null]));
    });

    test('throws on null first', () {
      var builder = ListBuilder<int>([0]);
      expect(() => builder.first = null as dynamic, throwsA(anything));
      expect(builder.build(), orderedEquals([0]));
    });

    test('nullable does not throw on null first', () {
      var builder = ListBuilder<int?>([0]);
      builder.first = null;
      expect(builder.build(), orderedEquals([null]));
    });

    test('throws on null last', () {
      var builder = ListBuilder<int>([0]);
      expect(() => builder.last = null as dynamic, throwsA(anything));
      expect(builder.build(), orderedEquals([0]));
    });

    test('nullable does not throw on null last', () {
      var builder = ListBuilder<int?>([0]);
      builder.last = null;
      expect(builder.build(), orderedEquals([null]));
    });

    test('throws on null add', () {
      var builder = ListBuilder<int>();
      expect(() => builder.add(null as dynamic), throwsA(anything));
      expect(builder.build(), isEmpty);
    });

    test('nullable does not throw on null add', () {
      var builder = ListBuilder<int?>();
      builder.add(null);
      expect(builder.build(), [null]);
    });

    test('throws on null addAll', () {
      var builder = ListBuilder<int>();
      expect(() => builder.addAll([0, 1, null as dynamic]), throwsA(anything));
      expect(builder.build(), isEmpty);
    });

    test('nullable does not throw on null addAll', () {
      var builder = ListBuilder<int?>();
      builder.addAll([0, 1, null]);
      expect(builder.build(), [0, 1, null]);
    });

    test('throws on null insert', () {
      var builder = ListBuilder<int>();
      expect(() => builder.insert(0, null as dynamic), throwsA(anything));
      expect(builder.build(), isEmpty);
    });

    test('nullable does not throw on null insert', () {
      var builder = ListBuilder<int?>();
      builder.insert(0, null);
      expect(builder.build(), [null]);
    });

    test('throws on null insertAll', () {
      var builder = ListBuilder<int>();
      expect(() => builder.insertAll(0, [0, 1, null as dynamic]),
          throwsA(anything));
      expect(builder.build(), isEmpty);
    });

    test('nullable does not throw on null insertAll', () {
      var builder = ListBuilder<int?>();
      builder.insertAll(0, [0, 1, null]);
      expect(builder.build(), [0, 1, null]);
    });

    test('throws on null setAll', () {
      var builder = ListBuilder<int>([0, 1, 2]);
      expect(
          () => builder.setAll(0, [0, 1, null as dynamic]), throwsA(anything));
      expect(builder.build(), orderedEquals([0, 1, 2]));
    });

    test('nullable does not throw on null setAll', () {
      var builder = ListBuilder<int?>([0, 1, 2]);
      builder.setAll(0, [0, 1, null]);
      expect(builder.build(), orderedEquals([0, 1, null]));
    });

    test('throws on null setRange', () {
      var builder = ListBuilder<int>([0, 1, 2]);
      expect(() => builder.setRange(0, 3, [0, 1, null as dynamic]),
          throwsA(anything));
      expect(builder.build(), orderedEquals([0, 1, 2]));
    });

    test('nullable does not throw on null setRange', () {
      var builder = ListBuilder<int?>([0, 1, 2]);
      builder.setRange(0, 3, [0, 1, null]);
      expect(builder.build(), orderedEquals([0, 1, null]));
    });

    test('throws on null fillRange', () {
      var builder = ListBuilder<int>([0, 1, 2]);
      expect(() => builder.fillRange(0, 3, null as dynamic), throwsA(anything));
      expect(builder.build(), orderedEquals([0, 1, 2]));
    });

    test('nullable does not throw on null fillRange', () {
      var builder = ListBuilder<int?>([0, 1, 2]);
      builder.fillRange(0, 3, null);
      expect(builder.build(), orderedEquals([null, null, null]));
    });

    test('throws on null replaceRange', () {
      var builder = ListBuilder<int>([0, 1, 2]);
      expect(() => builder.replaceRange(0, 3, [0, 1, null as dynamic]),
          throwsA(anything));
      expect(builder.build(), orderedEquals([0, 1, 2]));
    });

    test('nullable does not throw on null replaceRange', () {
      var builder = ListBuilder<int?>([0, 1, 2]);
      builder.replaceRange(0, 3, [0, 1, null]);
      expect(builder.build(), orderedEquals([0, 1, null]));
    });

    test('throws on null map', () {
      var builder = ListBuilder<int>([0, 1, 2]);
      expect(() => builder.map((x) => null as dynamic), throwsA(anything));
      expect(builder.build(), orderedEquals([0, 1, 2]));
    });

    test('nullable does not throw on null map', () {
      var builder = ListBuilder<int?>([0, 1, 2]);
      builder.map((x) => null);
      expect(builder.build(), orderedEquals([null, null, null]));
    });

    test('throws on null expand', () {
      var builder = ListBuilder<int>([0, 1, 2]);
      expect(
          () => builder.expand((x) => [x, null as dynamic]), throwsA(anything));
      expect(builder.build(), orderedEquals([0, 1, 2]));
    });

    test('nullable does not throw on null expand', () {
      var builder = ListBuilder<int?>([0, 1, 2]);
      builder.expand((x) => [x, null]);
      expect(builder.build(), orderedEquals([0, null, 1, null, 2, null]));
    });

    test('throws on wrong type addAll', () {
      var builder = ListBuilder<int>();
      expect(
          () => builder.addAll(List<int>.from([0, 1, '0'])), throwsA(anything));
      expect(builder.build(), isEmpty);
    });

    test('throws on wrong type insertAll', () {
      var builder = ListBuilder<int>();
      expect(() => builder.insertAll(0, List<int>.from([0, 1, '0'])),
          throwsA(anything));
      expect(builder.build(), isEmpty);
    });

    test('throws on wrong type setAll', () {
      var builder = ListBuilder<int>([0, 1, 2]);
      expect(() => builder.setAll(0, List<int>.from([0, 1, '0'])),
          throwsA(anything));
      expect(builder.build(), orderedEquals([0, 1, 2]));
    });

    test('throws on wrong type setRange', () {
      var builder = ListBuilder<int>([0, 1, 2]);
      expect(() => builder.setRange(0, 2, List<int>.from([0, 1, '0'])),
          throwsA(anything));
      expect(builder.build(), orderedEquals([0, 1, 2]));
    });

    test('throws on wrong type replaceRange', () {
      var builder = ListBuilder<int>([0, 1, 2]);
      expect(() => builder.replaceRange(0, 2, List<int>.from([0, 1, '0'])),
          throwsA(anything));
      expect(builder.build(), orderedEquals([0, 1, 2]));
    });

    test('has replace method that replaces all data', () {
      expect((ListBuilder<int>()..replace([0, 1, 2])).build(), [0, 1, 2]);
    });

    // Lazy copies.

    test('does not mutate BuiltList when modifying ListBuilder assign', () {
      var list = BuiltList<int>([1, 2]);
      var listBuilder = list.toBuilder();
      listBuilder[0] = 3;
      expect(list, [1, 2]);
    });

    test('does not mutate BuiltList when modifying ListBuilder first', () {
      var list = BuiltList<int>([1, 2]);
      var listBuilder = list.toBuilder();
      listBuilder.first = 3;
      expect(list, [1, 2]);
    });

    test('does not mutate BuiltList when modifying ListBuilder last', () {
      var list = BuiltList<int>([1, 2]);
      var listBuilder = list.toBuilder();
      listBuilder.last = 3;
      expect(list, [1, 2]);
    });

    test('does not mutate BuiltList when modifying ListBuilder add', () {
      var list = BuiltList<int>([1, 2]);
      var listBuilder = list.toBuilder();
      listBuilder.add(3);
      expect(list, [1, 2]);
    });

    test('does not mutate BuiltList when modifying ListBuilder addAll', () {
      var list = BuiltList<int>([1, 2]);
      var listBuilder = list.toBuilder();
      listBuilder.addAll([3, 4]);
      expect(list, [1, 2]);
    });

    test('does not mutate BuiltList when modifying ListBuilder insert', () {
      var list = BuiltList<int>([1, 2]);
      var listBuilder = list.toBuilder();
      listBuilder.insert(0, 3);
      expect(list, [1, 2]);
    });

    test('does not mutate BuiltList when modifying ListBuilder insertAll', () {
      var list = BuiltList<int>([1, 2]);
      var listBuilder = list.toBuilder();
      listBuilder.insertAll(0, [3, 4]);
      expect(list, [1, 2]);
    });

    test('does not mutate BuiltList when modifying ListBuilder setAll', () {
      var list = BuiltList<int>([1, 2]);
      var listBuilder = list.toBuilder();
      listBuilder.setAll(0, [3, 4]);
      expect(list, [1, 2]);
    });

    test('does not mutate BuiltList when modifying ListBuilder setRange', () {
      var list = BuiltList<int>([1, 2]);
      var listBuilder = list.toBuilder();
      listBuilder.setRange(0, 2, [3, 4, 5]);
      expect(list, [1, 2]);
    });

    test('does not mutate BuiltList when modifying ListBuilder fillRange', () {
      var list = BuiltList<int>([1, 2]);
      var listBuilder = list.toBuilder();
      listBuilder.fillRange(0, 2, 3);
      expect(list, [1, 2]);
    });

    test('does not mutate BuiltList when modifying ListBuilder replaceRange',
        () {
      var list = BuiltList<int>([1, 2]);
      var listBuilder = list.toBuilder();
      listBuilder.replaceRange(0, 2, [3, 4]);
      expect(list, [1, 2]);
    });

    test('does not mutate BuiltList when modifying ListBuilder map', () {
      var list = BuiltList<int>([1, 2]);
      var listBuilder = list.toBuilder();
      listBuilder.map((x) => 3);
      expect(list, [1, 2]);
    });

    test('does not mutate BuiltList when modifying ListBuilder expand', () {
      var list = BuiltList<int>([1, 2]);
      var listBuilder = list.toBuilder();
      listBuilder.expand((x) => [3, 4]);
      expect(list, [1, 2]);
    });

    test('converts to BuiltList without copying', () {
      var makeLongListBuilder =
          () => ListBuilder<int>(List<int>.filled(1000000, 0));
      var longListBuilder = makeLongListBuilder();
      var buildLongListBuilder = () => longListBuilder.build();

      expectMuchFaster(buildLongListBuilder, makeLongListBuilder);
    });

    test('does not mutate BuiltList following mutates after build', () {
      var listBuilder = ListBuilder<int>([1, 2]);

      var list1 = listBuilder.build();
      expect(list1, [1, 2]);

      listBuilder.add(3);
      expect(list1, [1, 2]);
    });

    // List.

    test('has a method like List[]', () {
      var listBuilder = ListBuilder<int>([1, 2]);
      ++listBuilder[0];
      --listBuilder[1];
      expect(listBuilder.build(), [2, 1]);
    });

    test('has a method like List[]=', () {
      expect((ListBuilder<int>([1])..[0] = 2).build(), [2]);
      expect((BuiltList<int>([1]).toBuilder()..[0] = 2).build(), [2]);
    });

    test('has a property like List.first', () {
      var builder = BuiltList<int>([1, 2, 3]).toBuilder();
      expect(builder.first, 1);
      builder.first = 2;
      expect(builder.build().first, 2);
    });

    test('has a property like List.last', () {
      var builder = BuiltList<int>([1, 2, 3]).toBuilder();
      expect(builder.last, 3);
      builder.last = 2;
      expect(builder.build().last, 2);
    });

    test('has a method like List.length', () {
      expect(ListBuilder<int>([1, 2]).length, 2);
      expect(BuiltList<int>([1, 2]).toBuilder().length, 2);

      expect(ListBuilder<int>().length, 0);
      expect(BuiltList<int>().toBuilder().length, 0);
    });

    test('has a method like List.isEmpty', () {
      expect(ListBuilder<int>([1, 2]).isEmpty, false);
      expect(BuiltList<int>([1, 2]).toBuilder().isEmpty, false);

      expect(ListBuilder<int>().isEmpty, true);
      expect(BuiltList<int>().toBuilder().isEmpty, true);
    });

    test('has a method like List.isNotEmpty', () {
      expect(ListBuilder<int>([1, 2]).isNotEmpty, true);
      expect(BuiltList<int>([1, 2]).toBuilder().isNotEmpty, true);

      expect(ListBuilder<int>().isNotEmpty, false);
      expect(BuiltList<int>().toBuilder().isNotEmpty, false);
    });

    test('has a method like List.add', () {
      expect((ListBuilder<int>()..add(1)).build(), [1]);
      expect((BuiltList<int>().toBuilder()..add(1)).build(), [1]);
    });

    test('has a method like List.addAll', () {
      expect((ListBuilder<int>()..addAll([1, 2])).build(), [1, 2]);
      expect((BuiltList<int>().toBuilder()..addAll([1, 2])).build(), [1, 2]);
    });

    test('has a method like List.reversed that updates in place', () {
      expect((ListBuilder<int>([1, 2])..reverse()).build(), [2, 1]);
      expect((BuiltList<int>([1, 2]).toBuilder()..reverse()).build(), [2, 1]);
    });

    test('has a method like List.sort', () {
      expect((ListBuilder<int>([2, 1])..sort()).build(), [1, 2]);
      expect(
          (ListBuilder<int>([1, 2])..sort((int x, int y) => x < y ? 1 : -1))
              .build(),
          [2, 1]);

      expect((BuiltList<int>([2, 1]).toBuilder()..sort()).build(), [1, 2]);
      expect(
          (BuiltList<int>([1, 2]).toBuilder()
                ..sort((int x, int y) => x < y ? 1 : -1))
              .build(),
          [2, 1]);
    });

    test('has a method like List.shuffle', () {
      expect((ListBuilder<int>([1, 2])..shuffle(_AlwaysZeroRandom())).build(),
          [2, 1]);
      expect(
          (BuiltList<int>([1, 2]).toBuilder()..shuffle(_AlwaysZeroRandom()))
              .build(),
          [2, 1]);
    });

    test('has a method like List.clear', () {
      expect((ListBuilder<int>([1, 2])..clear()).build(), []);
      expect((BuiltList<int>([1, 2]).toBuilder()..clear()).build(), []);
    });

    test('has a method like List.insert', () {
      expect((ListBuilder<int>([1, 2])..insert(1, 3)).build(), [1, 3, 2]);
      expect((BuiltList<int>([1, 2]).toBuilder()..insert(1, 3)).build(),
          [1, 3, 2]);
    });

    test('has a method like List.insertAll', () {
      expect((ListBuilder<int>([1, 2])..insertAll(1, [3, 4])).build(),
          [1, 3, 4, 2]);
      expect((BuiltList<int>([1, 2]).toBuilder()..insertAll(1, [3, 4])).build(),
          [1, 3, 4, 2]);
    });

    test('has a method like List.setAll', () {
      expect((ListBuilder<int>([1, 2])..setAll(0, [3, 4])).build(), [3, 4]);
      expect((BuiltList<int>([1, 2]).toBuilder()..setAll(0, [3, 4])).build(),
          [3, 4]);
    });

    test('has a method like List.remove', () {
      expect(ListBuilder<int>([1, 2]).remove(2), true);
      expect(ListBuilder<int>([1, 2]).remove(3), false);
      expect((ListBuilder<int>([1, 2])..remove(2)).build(), [1]);
      expect((BuiltList<int>([1, 2]).toBuilder()..remove(2)).build(), [1]);
    });

    test('has a method like List.removeAt', () {
      expect(ListBuilder<int>([1, 2]).removeAt(1), 2);
      expect((ListBuilder<int>([1, 2])..removeAt(1)).build(), [1]);
      expect((BuiltList<int>([1, 2]).toBuilder()..removeAt(1)).build(), [1]);
    });

    test('has a method like List.removeLast', () {
      expect(ListBuilder<int>([1, 2]).removeLast(), 2);
      expect((ListBuilder<int>([1, 2])..removeLast()).build(), [1]);
      expect((BuiltList<int>([1, 2]).toBuilder()..removeLast()).build(), [1]);
    });

    test('has a method like List.removeWhere', () {
      expect(
          (ListBuilder<int>([1, 2])..removeWhere((x) => x == 1)).build(), [2]);
      expect(
          (BuiltList<int>([1, 2]).toBuilder()..removeWhere((x) => x == 1))
              .build(),
          [2]);
    });

    test('has a method like List.retainWhere', () {
      expect(
          (ListBuilder<int>([1, 2])..retainWhere((x) => x == 1)).build(), [1]);
      expect(
          (BuiltList<int>([1, 2]).toBuilder()..retainWhere((x) => x == 1))
              .build(),
          [1]);
    });

    test('has a method like List.sublist that updates in place', () {
      expect((ListBuilder<int>([1, 2])..sublist(1)).build(), [2]);
      expect((ListBuilder<int>([1, 2])..sublist(1, 1)).build(), []);

      expect((BuiltList<int>([1, 2]).toBuilder()..sublist(1)).build(), [2]);
      expect((BuiltList<int>([1, 2]).toBuilder()..sublist(1, 1)).build(), []);
    });

    test('has a method like List.setRange', () {
      expect((ListBuilder<int>([1, 2])..setRange(0, 1, [3])).build(), [3, 2]);
      expect((ListBuilder<int>([1, 2])..setRange(0, 1, [3, 4], 1)).build(),
          [4, 2]);

      expect((BuiltList<int>([1, 2]).toBuilder()..setRange(0, 1, [3])).build(),
          [3, 2]);
      expect(
          (BuiltList<int>([1, 2]).toBuilder()..setRange(0, 1, [3, 4], 1))
              .build(),
          [4, 2]);
    });

    test('has a method like List.removeRange', () {
      expect((ListBuilder<int>([1, 2])..removeRange(0, 1)).build(), [2]);
      expect(
          (BuiltList<int>([1, 2]).toBuilder()..removeRange(0, 1)).build(), [2]);
    });

    test('has a method like List.fillRange that requires a value', () {
      expect((ListBuilder<int>([1, 2])..fillRange(0, 2, 3)).build(), [3, 3]);
      expect((BuiltList<int>([1, 2]).toBuilder()..fillRange(0, 2, 3)).build(),
          [3, 3]);
    });

    test('has a method like List.replaceRange', () {
      expect((ListBuilder<int>([1, 2])..replaceRange(0, 1, [2, 3])).build(),
          [2, 3, 2]);
      expect(
          (BuiltList<int>([1, 2]).toBuilder()..replaceRange(0, 1, [2, 3]))
              .build(),
          [2, 3, 2]);
    });

    // Iterable.

    test('has a method like Iterable.map that updates in place', () {
      expect((ListBuilder<int>([1, 2])..map((x) => x + 1)).build(), [2, 3]);
      expect((BuiltList<int>([1, 2]).toBuilder()..map((x) => x + 1)).build(),
          [2, 3]);
    });

    test('has a method like Iterable.where that updates in place', () {
      expect((ListBuilder<int>([1, 2])..where((x) => x == 2)).build(), [2]);
      expect((BuiltList<int>([1, 2]).toBuilder()..where((x) => x == 2)).build(),
          [2]);
    });

    test('has a method like Iterable.expand that updates in place', () {
      expect((ListBuilder<int>([1, 2])..expand((x) => [x, x + 1])).build(),
          [1, 2, 2, 3]);
      expect(
          (BuiltList<int>([1, 2]).toBuilder()..expand((x) => [x, x + 1]))
              .build(),
          [1, 2, 2, 3]);
    });

    test('has a method like Iterable.take that updates in place', () {
      expect((ListBuilder<int>([1, 2])..take(1)).build(), [1]);
      expect((BuiltList<int>([1, 2]).toBuilder()..take(1)).build(), [1]);
    });

    test('has a method like Iterable.takeWhile that updates in place', () {
      expect((ListBuilder<int>([1, 2])..takeWhile((x) => x == 1)).build(), [1]);
      expect(
          (BuiltList<int>([1, 2]).toBuilder()..takeWhile((x) => x == 1))
              .build(),
          [1]);
    });

    test('has a method like Iterable.skip that updates in place', () {
      expect((ListBuilder<int>([1, 2])..skip(1)).build(), [2]);
      expect((BuiltList<int>([1, 2]).toBuilder()..skip(1)).build(), [2]);
    });

    test('has a method like Iterable.skipWhile that updates in place', () {
      expect((ListBuilder<int>([1, 2])..skipWhile((x) => x == 1)).build(), [2]);
      expect(
          (BuiltList<int>([1, 2]).toBuilder()..skipWhile((x) => x == 1))
              .build(),
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
        ListBuilder<int>().addAll(onceIterable);
      });

      test('insertAll', () {
        ListBuilder<int>().insertAll(0, onceIterable);
      });

      test('setAll', () {
        ListBuilder<int>()
          ..addAll([0])
          ..setAll(0, onceIterable);
      });

      test('setRange', () {
        ListBuilder<int>()
          ..addAll([0])
          ..setRange(0, 1, onceIterable);
      });

      test('replaceRange', () {
        ListBuilder<int>()
          ..addAll([0])
          ..replaceRange(0, 1, onceIterable);
      });
    });
  });
}

class _AlwaysZeroRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.0;

  @override
  int nextInt(int max) => 0;
}
