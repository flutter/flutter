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

library quiver.collection.treeset_test;

import 'package:quiver/src/collection/treeset.dart';
import 'package:test/test.dart';

/// Matcher that verifies an [Error] is thrown.
final throwsError = throwsA(isA<Error>());

void main() {
  group('TreeSet', () {
    group('when empty', () {
      late TreeSet<num> tree;
      setUp(() {
        tree = TreeSet<num>();
      });
      test('should actually be empty', () => expect(tree, isEmpty));
      test('should not contain an element',
          () => expect(tree.lookup(0), isNull));
      test('has no element when iterating forward', () {
        var i = tree.iterator;
        expect(i.moveNext(), isFalse, reason: 'moveNext reports an element');
        expect(() => i.current, throwsError);
      });
      test('has no element when iterating backward', () {
        var i = tree.iterator;
        expect(i.movePrevious(), isFalse,
            reason: 'movePrevious reports an element');
        expect(() => i.current, throwsError);
      });
    });

    group('with [10, 20, 15]', () {
      late AvlTreeSet<num> tree;
      setUp(() {
        tree = TreeSet<num>() as AvlTreeSet<num>;
        tree.addAll([10, 20, 15]);
      });
      test('lookup succeeds for inserted elements', () {
        expect(tree.lookup(10), equals(10), reason: 'missing 10');
        expect(tree.lookup(15), equals(15), reason: 'missing 15');
        expect(tree.lookup(20), equals(20), reason: 'missing 20');
      });
      test('order is correct', () {
        AvlNode ten = debugGetNode(tree, 10)!;
        AvlNode twenty = debugGetNode(tree, 20)!;
        AvlNode fifteen = debugGetNode(tree, 15)!;
        expect(ten.predecessor, isNull, reason: '10 is the smalled element');
        expect(ten.successor, equals(fifteen), reason: '15 should follow 10');
        expect(ten.successor!.successor, equals(twenty),
            reason: '20 should follow 10');

        expect(twenty.successor, isNull, reason: '20 is the largest element');
        expect(twenty.predecessor, equals(fifteen), reason: '15 is before 20');
        expect(twenty.predecessor!.predecessor, equals(ten),
            reason: '10 is before 15');
      });
    });

    group('First & Last', () {
      test('for num tree', () {
        var tree = TreeSet<num>();
        tree.add(1);
        tree.add(2);
        tree.add(3);
        expect(tree.first, 1);
        expect(tree.last, 3);
      });

      test('for String tree', () {
        var tree = TreeSet<String>();
        tree.add('abc');
        tree.add('aaa');
        tree.add('zzz');
        expect(tree.first, 'aaa');
        expect(tree.last, 'zzz');
      });
    });

    group('with repeated elements', () {
      late TreeSet<num> tree;
      setUp(() {
        tree = TreeSet<num>()..addAll([10, 20, 15, 21, 30, 20]);
      });

      test('only contains subset', () {
        var it = tree.iterator;
        var testList = List.from([10, 15, 20, 21, 30]);
        while (it.moveNext()) {
          expect(it.current, equals(testList.removeAt(0)));
        }
        expect(testList.length, equals(0), reason: 'valid subset seen in tree');
      });
    });

    group('iteration', () {
      late TreeSet<num> tree;
      setUp(() {
        tree = TreeSet<num>()..addAll([10, 20, 15, 21, 30]);
      });

      test('works bidirectionally', () {
        var it = tree.iterator;
        while (it.moveNext()) {}
        expect(it.movePrevious(), isTrue,
            reason: 'we can backup after walking the entire list');
        expect(it.current, equals(30),
            reason: 'the last element is what we expect');
        while (it.movePrevious()) {}
        expect(it.moveNext(), isTrue,
            reason: 'we can move next after walking to the front of the set');
        expect(it.current, equals(10),
            reason: 'the first element is what we expect');
      });

      group('from', () {
        test('non-inserted midpoint works forward', () {
          var it = tree.fromIterator(19);
          expect(() => it.current, throwsError);
          expect(it.moveNext(), isTrue, reason: 'moveNext() from spot works');
          expect(it.current, equals(20));
        });

        test('non-inserted midpoint works for movePrevious()', () {
          var it = tree.fromIterator(19);
          expect(() => it.current, throwsError);
          expect(it.movePrevious(), isTrue,
              reason: 'movePrevious() from spot works');
          expect(it.current, equals(15));
        });

        test('non-inserted midpoint works reversed', () {
          var it = tree.fromIterator(19, reversed: true);
          expect(() => it.current, throwsError);
          expect(it.moveNext(), isTrue, reason: 'moveNext() from spot works');
          expect(it.current, equals(15));
        });

        test('non-inserted midpoint works reversed, movePrevious()', () {
          var it = tree.fromIterator(19, reversed: true);
          expect(() => it.current, throwsError);
          expect(it.movePrevious(), isTrue,
              reason: 'movePrevious() from spot works');
          expect(it.current, equals(20));
        });

        test('inserted midpoint works forward', () {
          var it = tree.fromIterator(20);
          expect(() => it.current, throwsError);
          expect(it.moveNext(), isTrue, reason: 'moveNext() from spot works');
          expect(it.current, equals(20));
        });

        test('inserted midpoint works reversed', () {
          var it = tree.fromIterator(20, reversed: true);
          expect(() => it.current, throwsError);
          expect(it.moveNext(), isTrue, reason: 'moveNext() from spot works');
          expect(it.current, equals(20));
        });

        test('after the set', () {
          var it = tree.fromIterator(100);
          expect(() => it.current, throwsError);
          expect(it.moveNext(), isFalse, reason: 'not following items');
          expect(it.movePrevious(), isTrue, reason: 'backwards movement valid');
          expect(it.current, equals(30));
        });

        test('before the set', () {
          var it = tree.fromIterator(0);
          expect(() => it.current, throwsError);
          expect(it.movePrevious(), isFalse, reason: 'not previous items');
          expect(it.moveNext(), isTrue, reason: 'forwards movement valid');
          expect(it.current, equals(10));
        });

        test('inserted midpoint, non-inclusive, works forward', () {
          var it = tree.fromIterator(20, inclusive: false);
          expect(() => it.current, throwsError);
          expect(it.moveNext(), isTrue, reason: 'moveNext() from spot works');
          expect(it.current, equals(21));
        });

        test('inserted endpoint, non-inclusive, works forward', () {
          var it = tree.fromIterator(30, inclusive: false);
          expect(() => it.current, throwsError);
          expect(it.moveNext(), isFalse, reason: 'moveNext() from spot works');

          it = tree.fromIterator(10, inclusive: false);
          expect(() => it.current, throwsError);
          expect(it.moveNext(), isTrue, reason: 'moveNext() from spot works');
          expect(it.current, equals(15),
              reason: 'non-inclusive start should be 15');
        });

        test('inserted endpoint, non-inclusive, works backward', () {
          var it = tree.fromIterator(10, inclusive: false);
          expect(() => it.current, throwsError);
          expect(it.movePrevious(), isFalse,
              reason: 'movePrevious() from spot is null');

          it = tree.fromIterator(30, inclusive: false);
          expect(() => it.current, throwsError);
          expect(it.movePrevious(), isTrue,
              reason: 'moveNext() from spot works');
          expect(it.current, equals(21));
        });

        test('inserted midpoint, non-inclusive, reversed, works forward', () {
          var it = tree.fromIterator(20, inclusive: false, reversed: true);
          expect(() => it.current, throwsError);
          expect(it.moveNext(), isTrue, reason: 'moveNext() from spot works');
          expect(it.current, equals(15));
        });

        test('inserted endpoint, non-inclusive, reversed, works forward', () {
          var it = tree.fromIterator(30, inclusive: false, reversed: true);
          expect(() => it.current, throwsError);
          expect(it.moveNext(), isTrue, reason: 'moveNext() from spot works');
          expect(it.current, equals(21));

          it = tree.fromIterator(10, inclusive: false, reversed: true);
          expect(() => it.current, throwsError);
          expect(it.moveNext(), isFalse, reason: 'moveNext() works');
        });

        test('inserted endpoint, non-inclusive, reversed, works backward', () {
          var it = tree.fromIterator(10, inclusive: false, reversed: true);
          expect(() => it.current, throwsError);
          expect(it.movePrevious(), isTrue,
              reason: 'moveNext() from spot works');
          expect(it.current, equals(15));

          it = tree.fromIterator(30, inclusive: false, reversed: true);
          expect(() => it.current, throwsError);
          expect(it.movePrevious(), isFalse,
              reason: 'moveNext() from spot works');
        });
      });

      group('fails', () {
        late Iterator<num> it;
        setUp(() => it = tree.iterator);

        test('after tree is cleared', () {
          tree.clear();
          dynamic error;
          try {
            it.moveNext();
          } catch (e) {
            error = e;
          }
          expect(error, isConcurrentModificationError);
        });

        test('after inserting an element', () {
          tree.add(101);
          dynamic error;
          try {
            it.moveNext();
          } catch (e) {
            error = e;
          }
          expect(error, isConcurrentModificationError);
        });

        test('after removing an element', () {
          tree.remove(10);
          dynamic error;
          try {
            it.moveNext();
          } catch (e) {
            error = e;
          }
          expect(error, isConcurrentModificationError);
        });
      });

      group('still works', () {
        late Iterator<num> it;
        setUp(() => it = tree.iterator);

        test('when removing non-existing element', () {
          tree.remove(42);
          dynamic error;
          try {
            it.moveNext();
          } catch (e) {
            error = e;
          }
          expect(error, isNull, reason: 'set was not modified');
        });
        test('when adding an already existing element', () {
          tree.add(10);
          dynamic error;
          try {
            it.moveNext();
          } catch (e) {
            error = e;
          }
          expect(error, isNull, reason: 'set was not modified');
        });
      });
    });

    group('removal', () {
      late TreeSet<num> tree;

      test('remove from empty tree', () {
        tree = TreeSet();
        tree.remove(10);
        expect(tree, isEmpty);
      });

      test('remove from tree', () {
        tree = TreeSet()..addAll([10, 20, 15, 21, 30, 20]);
        tree.remove(42);
        expect(tree.toList(), equals([10, 15, 20, 21, 30]));

        tree.remove(10);
        expect(tree.toList(), equals([15, 20, 21, 30]));

        tree.remove(30);
        expect(tree.toList(), equals([15, 20, 21]));

        tree.remove(20);
        expect(tree.toList(), equals([15, 21]));
      });

      test('remove root', () {
        tree = TreeSet()
          ..addAll([1, 3, 5, 6, 2, 4])
          ..removeAll([1, 3]);
        expect(tree.toList(), equals([2, 4, 5, 6]));
      });

      test('removeAll from tree', () {
        tree = TreeSet()..addAll([10, 20, 15, 21, 30, 20]);
        tree.removeAll([42]);
        expect(tree.toList(), equals([10, 15, 20, 21, 30]));

        tree.removeAll([10, 30]);
        expect(tree.toList(), equals([15, 20, 21]));

        tree.removeAll([21, 20, 15]);
        expect(tree, isEmpty);
      });

      test('removeWhere from tree', () {
        tree = TreeSet()..addAll([10, 20, 15, 21, 30, 20]);
        tree.removeWhere((e) => e % 10 == 2);
        expect(tree.toList(), equals([10, 15, 20, 21, 30]));

        tree.removeWhere((e) => e % 10 == 0);
        expect(tree.toList(), equals([15, 21]));

        tree.removeWhere((e) => e % 10 > 0);
        expect(tree, isEmpty);
      });

      test('retainAll from tree', () {
        tree = TreeSet()..addAll([10, 20, 15, 21, 30, 20]);
        tree.retainAll([10, 30]);
        expect(tree.toList(), equals([10, 30]));

        tree.retainAll([42]);
        expect(tree, isEmpty);
      });

      test('retainWhere from tree', () {
        tree = TreeSet()..addAll([10, 20, 15, 21, 30, 20]);
        tree.retainWhere((e) => e % 1 == 0);
        expect(tree.toList(), equals([10, 15, 20, 21, 30]));

        tree.retainWhere((e) => e % 10 == 0);
        expect(tree.toList(), equals([10, 20, 30]));

        tree.retainWhere((e) => e % 10 > 0);
        expect(tree, isEmpty);
      });
    });

    group('set math', () {
      /// NOTE: set math with sorted sets should have a performance benefit;
      /// we do not check the performance, only that the resulting math
      /// is equivalent to non-sorted sets.

      late TreeSet<num> tree;
      late List<num> expectedUnion;
      late List<num> expectedIntersection;
      late List<num> expectedDifference;
      late Set<num> nonSortedTestSet;
      late TreeSet<num> sortedTestSet;

      setUp(() {
        tree = TreeSet()..addAll([10, 20, 15, 21, 30, 20]);
        expectedUnion = [10, 15, 18, 20, 21, 22, 30];
        expectedIntersection = [10, 15];
        expectedDifference = [20, 21, 30];
        nonSortedTestSet = Set.from([10, 18, 22, 15]);
        sortedTestSet = TreeSet()..addAll(nonSortedTestSet);
      });

      test(
          'union with non sorted set',
          () => expect(
              tree.union(nonSortedTestSet).toList(), equals(expectedUnion)));
      test(
          'union with sorted set',
          () => expect(
              tree.union(sortedTestSet).toList(), equals(expectedUnion)));
      test(
          'intersection with non sorted set',
          () => expect(tree.intersection(nonSortedTestSet).toList(),
              equals(expectedIntersection)));
      test(
          'intersection with sorted set',
          () => expect(tree.intersection(sortedTestSet).toList(),
              equals(expectedIntersection)));
      test(
          'difference with non sorted set',
          () => expect(tree.difference(nonSortedTestSet).toList(),
              equals(expectedDifference)));
      test(
          'difference with sorted set',
          () => expect(tree.difference(sortedTestSet).toList(),
              equals(expectedDifference)));
    });

    group('AVL implementation', () {
      /// NOTE: This is implementation specific testing for coverage.
      /// Users do not have access to [AvlNode] or [AvlTreeSet]
      test('RightLeftRotation', () {
        AvlTreeSet<num> tree = TreeSet<num>() as AvlTreeSet<num>;
        tree.add(10);
        tree.add(20);
        tree.add(15);

        AvlNode ten = debugGetNode(tree, 10)!;
        AvlNode twenty = debugGetNode(tree, 20)!;
        AvlNode fifteen = debugGetNode(tree, 15)!;

        expect(ten.parent, equals(fifteen));
        expect(ten.hasLeft, isFalse);
        expect(ten.hasRight, isFalse);
        expect(ten.balance, equals(0));

        expect(twenty.parent, equals(fifteen));
        expect(twenty.hasLeft, isFalse);
        expect(twenty.hasRight, isFalse);
        expect(twenty.balance, equals(0));

        expect(fifteen.hasParent, isFalse);
        expect(fifteen.left, equals(ten));
        expect(fifteen.right, equals(twenty));
        expect(fifteen.balance, equals(0));
      });
      test('LeftRightRotation', () {
        AvlTreeSet<num> tree = TreeSet<num>() as AvlTreeSet<num>;
        tree.add(30);
        tree.add(10);
        tree.add(20);

        AvlNode thirty = debugGetNode(tree, 30)!;
        AvlNode ten = debugGetNode(tree, 10)!;
        AvlNode twenty = debugGetNode(tree, 20)!;

        expect(thirty.parent, equals(twenty));
        expect(thirty.hasLeft, isFalse);
        expect(thirty.hasRight, isFalse);
        expect(thirty.balance, equals(0));

        expect(ten.parent, equals(twenty));
        expect(ten.hasLeft, isFalse);
        expect(ten.hasRight, isFalse);
        expect(ten.balance, equals(0));

        expect(twenty.hasParent, isFalse);
        expect(twenty.left, equals(ten));
        expect(twenty.right, equals(thirty));
        expect(twenty.balance, equals(0));
      });

      test('AVL-LeftRotation', () {
        AvlTreeSet<num> tree = TreeSet<num>() as AvlTreeSet<num>;
        tree.add(1);
        tree.add(2);
        tree.add(3);

        AvlNode one = debugGetNode(tree, 1)!;
        AvlNode two = debugGetNode(tree, 2)!;
        AvlNode three = debugGetNode(tree, 3)!;

        expect(one.parent, equals(two));
        expect(one.hasLeft, isFalse);
        expect(one.hasRight, isFalse);
        expect(one.balance, equals(0));

        expect(three.parent, equals(two));
        expect(three.hasLeft, isFalse);
        expect(three.hasRight, isFalse);
        expect(three.balance, equals(0));

        expect(two.hasParent, isFalse);
        expect(two.left, equals(one));
        expect(two.right, equals(three));
        expect(two.balance, equals(0));
      });

      test('AVL-RightRotation', () {
        AvlTreeSet<num> tree = TreeSet<num>() as AvlTreeSet<num>;
        tree.add(3);
        tree.add(2);
        tree.add(1);

        AvlNode one = debugGetNode(tree, 1)!;
        AvlNode two = debugGetNode(tree, 2)!;
        AvlNode three = debugGetNode(tree, 3)!;

        expect(one.parent, equals(two));
        expect(one.hasLeft, isFalse);
        expect(one.hasRight, isFalse);
        expect(one.balance, equals(0));

        expect(three.parent, equals(two));
        expect(three.hasLeft, isFalse);
        expect(three.hasRight, isFalse);
        expect(three.balance, equals(0));

        expect(two.hasParent, isFalse);
        expect(two.left, equals(one));
        expect(two.right, equals(three));
        expect(two.balance, equals(0));
      });
    });

    group('nearest search', () {
      late TreeSet<num> tree;
      setUp(() {
        tree = TreeSet<num>(comparator: (num left, num right) {
          return left - right as int;
        })
          ..addAll([300, 200, 100]);
      });

      test('NEAREST is sane', () {
        var val = tree.nearest(199);
        expect(val, equals(200), reason: '199 is closer to 200');
        val = tree.nearest(201);
        expect(val, equals(200), reason: '201 is 200');
        val = tree.nearest(150);
        expect(val, equals(100), reason: '150 defaults to lower 100');
      });

      test('LESS_THAN is sane', () {
        var val = tree.nearest(199, nearestOption: TreeSearch.LESS_THAN);
        expect(val, equals(100), reason: '199 rounds down to 100');
      });

      test('GREATER_THAN is sane', () {
        var val = tree.nearest(101, nearestOption: TreeSearch.GREATER_THAN);
        expect(val, equals(200), reason: '101 rounds up to 200');
      });
    });
  });
}
