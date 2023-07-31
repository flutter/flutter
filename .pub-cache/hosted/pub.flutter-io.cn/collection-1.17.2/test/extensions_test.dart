// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show pow, Random;

import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  group('Iterable', () {
    group('of any', () {
      group('.whereNot', () {
        test('empty', () {
          expect(iterable([]).whereNot(unreachable), isEmpty);
        });
        test('none', () {
          expect(iterable([1, 3, 5]).whereNot((e) => e.isOdd), isEmpty);
        });
        test('all', () {
          expect(iterable([1, 3, 5]).whereNot((e) => e.isEven),
              iterable([1, 3, 5]));
        });
        test('some', () {
          expect(iterable([1, 2, 3, 4]).whereNot((e) => e.isEven),
              iterable([1, 3]));
        });
      });
      group('.sorted', () {
        test('empty', () {
          expect(iterable(<int>[]).sorted(unreachable), []);
        });
        test('singleton', () {
          expect(iterable([1]).sorted(unreachable), [1]);
        });
        test('multiple', () {
          expect(iterable([5, 2, 4, 3, 1]).sorted(cmpInt), [1, 2, 3, 4, 5]);
        });
      });
      group('.sortedBy', () {
        test('empty', () {
          expect(iterable(<int>[]).sortedBy(unreachable), []);
        });
        test('singleton', () {
          expect(iterable(<int>[1]).sortedBy(unreachable), [1]);
        });
        test('multiple', () {
          expect(iterable(<int>[3, 20, 100]).sortedBy(toString), [100, 20, 3]);
        });
      });
      group('.sortedByCompare', () {
        test('empty', () {
          expect(
              iterable(<int>[]).sortedByCompare(unreachable, unreachable), []);
        });
        test('singleton', () {
          expect(iterable(<int>[2]).sortedByCompare(unreachable, unreachable),
              [2]);
        });
        test('multiple', () {
          expect(
              iterable(<int>[30, 2, 100])
                  .sortedByCompare(toString, cmpParseInverse),
              [100, 30, 2]);
        });
      });
      group('isSorted', () {
        test('empty', () {
          expect(iterable(<int>[]).isSorted(unreachable), true);
        });
        test('single', () {
          expect(iterable([1]).isSorted(unreachable), true);
        });
        test('same', () {
          expect(iterable([1, 1, 1, 1]).isSorted(cmpInt), true);
          expect(iterable([1, 0, 1, 0]).isSorted(cmpMod(2)), true);
        });
        test('multiple', () {
          expect(iterable([1, 2, 3, 4]).isSorted(cmpInt), true);
          expect(iterable([4, 3, 2, 1]).isSorted(cmpIntInverse), true);
          expect(iterable([1, 2, 3, 0]).isSorted(cmpInt), false);
          expect(iterable([4, 1, 2, 3]).isSorted(cmpInt), false);
          expect(iterable([4, 3, 2, 1]).isSorted(cmpInt), false);
        });
      });
      group('.isSortedBy', () {
        test('empty', () {
          expect(iterable(<int>[]).isSortedBy(unreachable), true);
        });
        test('single', () {
          expect(iterable([1]).isSortedBy(toString), true);
        });
        test('same', () {
          expect(iterable([1, 1, 1, 1]).isSortedBy(toString), true);
        });
        test('multiple', () {
          expect(iterable([1, 2, 3, 4]).isSortedBy(toString), true);
          expect(iterable([4, 3, 2, 1]).isSortedBy(toString), false);
          expect(iterable([1000, 200, 30, 4]).isSortedBy(toString), true);
          expect(iterable([1, 2, 3, 0]).isSortedBy(toString), false);
          expect(iterable([4, 1, 2, 3]).isSortedBy(toString), false);
          expect(iterable([4, 3, 2, 1]).isSortedBy(toString), false);
        });
      });
      group('.isSortedByCompare', () {
        test('empty', () {
          expect(iterable(<int>[]).isSortedByCompare(unreachable, unreachable),
              true);
        });
        test('single', () {
          expect(iterable([1]).isSortedByCompare(toString, unreachable), true);
        });
        test('same', () {
          expect(iterable([1, 1, 1, 1]).isSortedByCompare(toString, cmpParse),
              true);
        });
        test('multiple', () {
          expect(iterable([1, 2, 3, 4]).isSortedByCompare(toString, cmpParse),
              true);
          expect(
              iterable([4, 3, 2, 1])
                  .isSortedByCompare(toString, cmpParseInverse),
              true);
          expect(
              iterable([1000, 200, 30, 4])
                  .isSortedByCompare(toString, cmpString),
              true);
          expect(iterable([1, 2, 3, 0]).isSortedByCompare(toString, cmpParse),
              false);
          expect(iterable([4, 1, 2, 3]).isSortedByCompare(toString, cmpParse),
              false);
          expect(iterable([4, 3, 2, 1]).isSortedByCompare(toString, cmpParse),
              false);
        });
      });
      group('.forEachIndexed', () {
        test('empty', () {
          iterable([]).forEachIndexed(unreachable);
        });
        test('single', () {
          var log = [];
          iterable(['a']).forEachIndexed((i, s) {
            log
              ..add(i)
              ..add(s);
          });
          expect(log, [0, 'a']);
        });
        test('multiple', () {
          var log = [];
          iterable(['a', 'b', 'c']).forEachIndexed((i, s) {
            log
              ..add(i)
              ..add(s);
          });
          expect(log, [0, 'a', 1, 'b', 2, 'c']);
        });
      });
      group('.forEachWhile', () {
        test('empty', () {
          iterable([]).forEachWhile(unreachable);
        });
        test('single true', () {
          var log = [];
          iterable(['a']).forEachWhile((s) {
            log.add(s);
            return true;
          });
          expect(log, ['a']);
        });
        test('single false', () {
          var log = [];
          iterable(['a']).forEachWhile((s) {
            log.add(s);
            return false;
          });
          expect(log, ['a']);
        });
        test('multiple one', () {
          var log = [];
          iterable(['a', 'b', 'c']).forEachWhile((s) {
            log.add(s);
            return false;
          });
          expect(log, ['a']);
        });
        test('multiple all', () {
          var log = [];
          iterable(['a', 'b', 'c']).forEachWhile((s) {
            log.add(s);
            return true;
          });
          expect(log, ['a', 'b', 'c']);
        });
        test('multiple some', () {
          var log = [];
          iterable(['a', 'b', 'c']).forEachWhile((s) {
            log.add(s);
            return s != 'b';
          });
          expect(log, ['a', 'b']);
        });
      });
      group('.forEachIndexedWhile', () {
        test('empty', () {
          iterable([]).forEachIndexedWhile(unreachable);
        });
        test('single true', () {
          var log = [];
          iterable(['a']).forEachIndexedWhile((i, s) {
            log
              ..add(i)
              ..add(s);
            return true;
          });
          expect(log, [0, 'a']);
        });
        test('single false', () {
          var log = [];
          iterable(['a']).forEachIndexedWhile((i, s) {
            log
              ..add(i)
              ..add(s);
            return false;
          });
          expect(log, [0, 'a']);
        });
        test('multiple one', () {
          var log = [];
          iterable(['a', 'b', 'c']).forEachIndexedWhile((i, s) {
            log
              ..add(i)
              ..add(s);
            return false;
          });
          expect(log, [0, 'a']);
        });
        test('multiple all', () {
          var log = [];
          iterable(['a', 'b', 'c']).forEachIndexedWhile((i, s) {
            log
              ..add(i)
              ..add(s);
            return true;
          });
          expect(log, [0, 'a', 1, 'b', 2, 'c']);
        });
        test('multiple some', () {
          var log = [];
          iterable(['a', 'b', 'c']).forEachIndexedWhile((i, s) {
            log
              ..add(i)
              ..add(s);
            return s != 'b';
          });
          expect(log, [0, 'a', 1, 'b']);
        });
      });
      group('.mapIndexed', () {
        test('empty', () {
          expect(iterable(<String>[]).mapIndexed(unreachable), isEmpty);
        });
        test('multiple', () {
          expect(iterable(<String>['a', 'b']).mapIndexed((i, s) => [i, s]), [
            [0, 'a'],
            [1, 'b']
          ]);
        });
      });
      group('.whereIndexed', () {
        test('empty', () {
          expect(iterable(<String>[]).whereIndexed(unreachable), isEmpty);
        });
        test('none', () {
          var trace = [];
          int log(int a, int b) {
            trace
              ..add(a)
              ..add(b);
            return b;
          }

          expect(
              iterable(<int>[1, 3, 5, 7])
                  .whereIndexed((i, x) => log(i, x).isEven),
              isEmpty);
          expect(trace, [0, 1, 1, 3, 2, 5, 3, 7]);
        });
        test('all', () {
          expect(iterable(<int>[1, 3, 5, 7]).whereIndexed((i, x) => x.isOdd),
              [1, 3, 5, 7]);
        });
        test('some', () {
          expect(iterable(<int>[1, 3, 5, 7]).whereIndexed((i, x) => i.isOdd),
              [3, 7]);
        });
      });
      group('.whereNotIndexed', () {
        test('empty', () {
          expect(iterable(<int>[]).whereNotIndexed(unreachable), isEmpty);
        });
        test('none', () {
          var trace = [];
          int log(int a, int b) {
            trace
              ..add(a)
              ..add(b);
            return b;
          }

          expect(
              iterable(<int>[1, 3, 5, 7])
                  .whereNotIndexed((i, x) => log(i, x).isOdd),
              isEmpty);
          expect(trace, [0, 1, 1, 3, 2, 5, 3, 7]);
        });
        test('all', () {
          expect(
              iterable(<int>[1, 3, 5, 7]).whereNotIndexed((i, x) => x.isEven),
              [1, 3, 5, 7]);
        });
        test('some', () {
          expect(iterable(<int>[1, 3, 5, 7]).whereNotIndexed((i, x) => i.isOdd),
              [1, 5]);
        });
      });
      group('.expandIndexed', () {
        test('empty', () {
          expect(iterable(<int>[]).expandIndexed(unreachable), isEmpty);
        });
        test('empty result', () {
          expect(iterable(['a', 'b']).expandIndexed((i, v) => []), isEmpty);
        });
        test('larger result', () {
          expect(iterable(['a', 'b']).expandIndexed((i, v) => ['$i', v]),
              ['0', 'a', '1', 'b']);
        });
        test('varying result', () {
          expect(
              iterable(['a', 'b'])
                  .expandIndexed((i, v) => i.isOdd ? ['$i', v] : []),
              ['1', 'b']);
        });
      });
      group('.reduceIndexed', () {
        test('empty', () {
          expect(() => iterable([]).reduceIndexed((i, a, b) => a),
              throwsStateError);
        });
        test('single', () {
          expect(iterable([1]).reduceIndexed(unreachable), 1);
        });
        test('multiple', () {
          expect(
              iterable([1, 4, 2])
                  .reduceIndexed((i, p, v) => p + (pow(i + 1, v) as int)),
              1 + 16 + 9);
        });
      });
      group('.foldIndexed', () {
        test('empty', () {
          expect(iterable([]).foldIndexed(0, unreachable), 0);
        });
        test('single', () {
          expect(
              iterable([1]).foldIndexed('x', (i, a, b) => '$a:$i:$b'), 'x:0:1');
        });
        test('mulitple', () {
          expect(iterable([1, 3, 9]).foldIndexed('x', (i, a, b) => '$a:$i:$b'),
              'x:0:1:1:3:2:9');
        });
      });
      group('.firstWhereOrNull', () {
        test('empty', () {
          expect(iterable([]).firstWhereOrNull(unreachable), null);
        });
        test('none', () {
          expect(iterable([1, 3, 7]).firstWhereOrNull(isEven), null);
        });
        test('single', () {
          expect(iterable([0, 1, 2]).firstWhereOrNull(isOdd), 1);
        });
        test('first of multiple', () {
          expect(iterable([0, 1, 3]).firstWhereOrNull(isOdd), 1);
        });
      });
      group('.firstWhereIndexedOrNull', () {
        test('empty', () {
          expect(iterable([]).firstWhereIndexedOrNull(unreachable), null);
        });
        test('none', () {
          expect(
              iterable([1, 3, 7]).firstWhereIndexedOrNull((i, x) => x.isEven),
              null);
          expect(iterable([1, 3, 7]).firstWhereIndexedOrNull((i, x) => i < 0),
              null);
        });
        test('single', () {
          expect(iterable([0, 3, 6]).firstWhereIndexedOrNull((i, x) => x.isOdd),
              3);
          expect(
              iterable([0, 3, 6]).firstWhereIndexedOrNull((i, x) => i == 1), 3);
        });
        test('first of multiple', () {
          expect(iterable([0, 3, 7]).firstWhereIndexedOrNull((i, x) => x.isOdd),
              3);
          expect(
              iterable([0, 3, 7]).firstWhereIndexedOrNull((i, x) => i.isEven),
              0);
        });
      });
      group('.firstOrNull', () {
        test('empty', () {
          expect(iterable([]).firstOrNull, null);
        });
        test('single', () {
          expect(iterable([1]).firstOrNull, 1);
        });
        test('first of multiple', () {
          expect(iterable([1, 3, 5]).firstOrNull, 1);
        });
      });
      group('.lastWhereOrNull', () {
        test('empty', () {
          expect(iterable([]).lastWhereOrNull(unreachable), null);
        });
        test('none', () {
          expect(iterable([1, 3, 7]).lastWhereOrNull(isEven), null);
        });
        test('single', () {
          expect(iterable([0, 1, 2]).lastWhereOrNull(isOdd), 1);
        });
        test('last of multiple', () {
          expect(iterable([0, 1, 3]).lastWhereOrNull(isOdd), 3);
        });
      });
      group('.lastWhereIndexedOrNull', () {
        test('empty', () {
          expect(iterable([]).lastWhereIndexedOrNull(unreachable), null);
        });
        test('none', () {
          expect(iterable([1, 3, 7]).lastWhereIndexedOrNull((i, x) => x.isEven),
              null);
          expect(iterable([1, 3, 7]).lastWhereIndexedOrNull((i, x) => i < 0),
              null);
        });
        test('single', () {
          expect(
              iterable([0, 3, 6]).lastWhereIndexedOrNull((i, x) => x.isOdd), 3);
          expect(
              iterable([0, 3, 6]).lastWhereIndexedOrNull((i, x) => i == 1), 3);
        });
        test('last of multiple', () {
          expect(
              iterable([0, 3, 7]).lastWhereIndexedOrNull((i, x) => x.isOdd), 7);
          expect(iterable([0, 3, 7]).lastWhereIndexedOrNull((i, x) => i.isEven),
              7);
        });
      });
      group('.lastOrNull', () {
        test('empty', () {
          expect(iterable([]).lastOrNull, null);
        });
        test('single', () {
          expect(iterable([1]).lastOrNull, 1);
        });
        test('last of multiple', () {
          expect(iterable([1, 3, 5]).lastOrNull, 5);
        });
      });
      group('.singleWhereOrNull', () {
        test('empty', () {
          expect(iterable([]).singleWhereOrNull(unreachable), null);
        });
        test('none', () {
          expect(iterable([1, 3, 7]).singleWhereOrNull(isEven), null);
        });
        test('single', () {
          expect(iterable([0, 1, 2]).singleWhereOrNull(isOdd), 1);
        });
        test('multiple', () {
          expect(iterable([0, 1, 3]).singleWhereOrNull(isOdd), null);
        });
      });
      group('.singleWhereIndexedOrNull', () {
        test('empty', () {
          expect(iterable([]).singleWhereIndexedOrNull(unreachable), null);
        });
        test('none', () {
          expect(
              iterable([1, 3, 7]).singleWhereIndexedOrNull((i, x) => x.isEven),
              null);
          expect(iterable([1, 3, 7]).singleWhereIndexedOrNull((i, x) => i < 0),
              null);
        });
        test('single', () {
          expect(
              iterable([0, 3, 6]).singleWhereIndexedOrNull((i, x) => x.isOdd),
              3);
          expect(iterable([0, 3, 6]).singleWhereIndexedOrNull((i, x) => i == 1),
              3);
        });
        test('multiple', () {
          expect(
              iterable([0, 3, 7]).singleWhereIndexedOrNull((i, x) => x.isOdd),
              null);
          expect(
              iterable([0, 3, 7]).singleWhereIndexedOrNull((i, x) => i.isEven),
              null);
        });
      });
      group('.singleOrNull', () {
        test('empty', () {
          expect(iterable([]).singleOrNull, null);
        });
        test('single', () {
          expect(iterable([1]).singleOrNull, 1);
        });
        test('multiple', () {
          expect(iterable([1, 3, 5]).singleOrNull, null);
        });
      });
      group('.lastBy', () {
        test('empty', () {
          expect(iterable([]).lastBy((dynamic _) {}), {});
        });
        test('single', () {
          expect(iterable([1]).lastBy(toString), {
            '1': 1,
          });
        });
        test('multiple', () {
          expect(
            iterable([1, 2, 3, 4, 5]).lastBy((x) => x.isEven),
            {
              false: 5,
              true: 4,
            },
          );
        });
      });
      group('.groupFoldBy', () {
        test('empty', () {
          expect(iterable([]).groupFoldBy(unreachable, unreachable), {});
        });
        test('single', () {
          expect(iterable([1]).groupFoldBy(toString, (p, v) => [p, v]), {
            '1': [null, 1]
          });
        });
        test('multiple', () {
          expect(
              iterable([1, 2, 3, 4, 5]).groupFoldBy<bool, String>(
                  (x) => x.isEven, (p, v) => p == null ? '$v' : '$p:$v'),
              {true: '2:4', false: '1:3:5'});
        });
      });
      group('.groupSetsBy', () {
        test('empty', () {
          expect(iterable([]).groupSetsBy(unreachable), {});
        });
        test('multiple same', () {
          expect(iterable([1, 1]).groupSetsBy(toString), {
            '1': {1}
          });
        });
        test('multiple', () {
          expect(iterable([1, 2, 3, 4, 5, 1]).groupSetsBy((x) => x % 3), {
            1: {1, 4},
            2: {2, 5},
            0: {3}
          });
        });
      });
      group('.groupListsBy', () {
        test('empty', () {
          expect(iterable([]).groupListsBy(unreachable), {});
        });
        test('multiple saame', () {
          expect(iterable([1, 1]).groupListsBy(toString), {
            '1': [1, 1]
          });
        });
        test('multiple', () {
          expect(iterable([1, 2, 3, 4, 5, 1]).groupListsBy((x) => x % 3), {
            1: [1, 4, 1],
            2: [2, 5],
            0: [3]
          });
        });
      });
      group('.splitBefore', () {
        test('empty', () {
          expect(iterable([]).splitBefore(unreachable), []);
        });
        test('single', () {
          expect(iterable([1]).splitBefore(unreachable), [
            [1]
          ]);
        });
        test('no split', () {
          var trace = [];
          bool log(x) {
            trace.add(x);
            return false;
          }

          expect(iterable([1, 2, 3]).splitBefore(log), [
            [1, 2, 3]
          ]);
          expect(trace, [2, 3]);
        });
        test('all splits', () {
          expect(iterable([1, 2, 3]).splitBefore((x) => true), [
            [1],
            [2],
            [3]
          ]);
        });
        test('some splits', () {
          expect(iterable([1, 2, 3]).splitBefore((x) => x.isEven), [
            [1],
            [2, 3]
          ]);
        });
      });
      group('.splitBeforeIndexed', () {
        test('empty', () {
          expect(iterable([]).splitBeforeIndexed(unreachable), []);
        });
        test('single', () {
          expect(iterable([1]).splitBeforeIndexed(unreachable), [
            [1]
          ]);
        });
        test('no split', () {
          var trace = [];
          bool log(i, x) {
            trace
              ..add('$i')
              ..add(x);
            return false;
          }

          expect(iterable([1, 2, 3]).splitBeforeIndexed(log), [
            [1, 2, 3]
          ]);
          expect(trace, ['1', 2, '2', 3]);
        });
        test('all splits', () {
          expect(iterable([1, 2, 3]).splitBeforeIndexed((i, x) => true), [
            [1],
            [2],
            [3]
          ]);
        });
        test('some splits', () {
          expect(iterable([1, 2, 3]).splitBeforeIndexed((i, x) => x.isEven), [
            [1],
            [2, 3]
          ]);
          expect(iterable([1, 2, 3]).splitBeforeIndexed((i, x) => i.isEven), [
            [1, 2],
            [3]
          ]);
        });
      });
      group('.splitAfter', () {
        test('empty', () {
          expect(iterable([]).splitAfter(unreachable), []);
        });
        test('single', () {
          expect(iterable([1]).splitAfter((x) => false), [
            [1]
          ]);
          expect(iterable([1]).splitAfter((x) => true), [
            [1]
          ]);
        });
        test('no split', () {
          var trace = [];
          bool log(x) {
            trace.add(x);
            return false;
          }

          expect(iterable([1, 2, 3]).splitAfter(log), [
            [1, 2, 3]
          ]);
          expect(trace, [1, 2, 3]);
        });
        test('all splits', () {
          expect(iterable([1, 2, 3]).splitAfter((x) => true), [
            [1],
            [2],
            [3]
          ]);
        });
        test('some splits', () {
          expect(iterable([1, 2, 3]).splitAfter((x) => x.isEven), [
            [1, 2],
            [3]
          ]);
        });
      });
      group('.splitAfterIndexed', () {
        test('empty', () {
          expect(iterable([]).splitAfterIndexed(unreachable), []);
        });
        test('single', () {
          expect(iterable([1]).splitAfterIndexed((i, x) => true), [
            [1]
          ]);
          expect(iterable([1]).splitAfterIndexed((i, x) => false), [
            [1]
          ]);
        });
        test('no split', () {
          var trace = [];
          bool log(i, x) {
            trace
              ..add('$i')
              ..add(x);
            return false;
          }

          expect(iterable([1, 2, 3]).splitAfterIndexed(log), [
            [1, 2, 3]
          ]);
          expect(trace, ['0', 1, '1', 2, '2', 3]);
        });
        test('all splits', () {
          expect(iterable([1, 2, 3]).splitAfterIndexed((i, x) => true), [
            [1],
            [2],
            [3]
          ]);
        });
        test('some splits', () {
          expect(iterable([1, 2, 3]).splitAfterIndexed((i, x) => x.isEven), [
            [1, 2],
            [3]
          ]);
          expect(iterable([1, 2, 3]).splitAfterIndexed((i, x) => i.isEven), [
            [1],
            [2, 3]
          ]);
        });
      });
      group('.splitBetween', () {
        test('empty', () {
          expect(iterable([]).splitBetween(unreachable), []);
        });
        test('single', () {
          expect(iterable([1]).splitBetween(unreachable), [
            [1]
          ]);
        });
        test('no split', () {
          var trace = [];
          bool log(x, y) {
            trace.add([x, y]);
            return false;
          }

          expect(iterable([1, 2, 3]).splitBetween(log), [
            [1, 2, 3]
          ]);
          expect(trace, [
            [1, 2],
            [2, 3]
          ]);
        });
        test('all splits', () {
          expect(iterable([1, 2, 3]).splitBetween((x, y) => true), [
            [1],
            [2],
            [3]
          ]);
        });
        test('some splits', () {
          expect(iterable([1, 2, 4]).splitBetween((x, y) => (x ^ y).isEven), [
            [1, 2],
            [4]
          ]);
        });
      });
      group('.splitBetweenIndexed', () {
        test('empty', () {
          expect(iterable([]).splitBetweenIndexed(unreachable), []);
        });
        test('single', () {
          expect(iterable([1]).splitBetweenIndexed(unreachable), [
            [1]
          ]);
        });
        test('no split', () {
          var trace = [];
          bool log(i, x, y) {
            trace.add([i, x, y]);
            return false;
          }

          expect(iterable([1, 2, 3]).splitBetweenIndexed(log), [
            [1, 2, 3]
          ]);
          expect(trace, [
            [1, 1, 2],
            [2, 2, 3]
          ]);
        });
        test('all splits', () {
          expect(iterable([1, 2, 3]).splitBetweenIndexed((i, x, y) => true), [
            [1],
            [2],
            [3]
          ]);
        });
        test('some splits', () {
          expect(
              iterable([1, 2, 4])
                  .splitBetweenIndexed((i, x, y) => (x ^ y).isEven),
              [
                [1, 2],
                [4]
              ]);
          expect(
              iterable([1, 2, 4])
                  .splitBetweenIndexed((i, x, y) => (i ^ y).isEven),
              [
                [1, 2],
                [4]
              ]);
        });
      });
      group('none', () {
        test('empty', () {
          expect(iterable([]).none(unreachable), true);
        });
        test('single', () {
          expect(iterable([1]).none(isEven), true);
          expect(iterable([1]).none(isOdd), false);
        });
        test('multiple', () {
          expect(iterable([1, 3, 5, 7, 9, 11]).none(isEven), true);
          expect(iterable([1, 3, 5, 7, 9, 10]).none(isEven), false);
          expect(iterable([0, 3, 5, 7, 9, 11]).none(isEven), false);
          expect(iterable([0, 2, 4, 6, 8, 10]).none(isEven), false);
        });
      });
    });
    group('of nullable', () {
      group('.whereNotNull', () {
        test('empty', () {
          expect(iterable(<int?>[]).whereNotNull(), isEmpty);
        });
        test('single', () {
          expect(iterable(<int?>[null]).whereNotNull(), isEmpty);
          expect(iterable(<int?>[1]).whereNotNull(), [1]);
        });
        test('multiple', () {
          expect(iterable(<int?>[1, 3, 5]).whereNotNull(), [1, 3, 5]);
          expect(iterable(<int?>[null, null, null]).whereNotNull(), isEmpty);
          expect(
              iterable(<int?>[1, null, 3, null, 5]).whereNotNull(), [1, 3, 5]);
        });
      });
    });
    group('of number', () {
      group('.sum', () {
        test('empty', () {
          expect(iterable(<int>[]).sum, same(0));
          expect(iterable(<double>[]).sum, same(0.0));
          expect(iterable(<num>[]).sum, same(0));
        });
        test('single', () {
          expect(iterable(<int>[1]).sum, same(1));
          expect(iterable(<double>[1.2]).sum, same(1.2));
          expect(iterable(<num>[1]).sum, same(1));
          expect(iterable(<num>[1.2]).sum, same(1.2));
        });
        test('multiple', () {
          expect(iterable(<int>[1, 2, 4]).sum, 7);
          expect(iterable(<double>[1.2, 3.5]).sum, 4.7);
          expect(iterable(<num>[1, 3, 5]).sum, same(9));
          expect(iterable(<num>[1.2, 3.5]).sum, 4.7);
          expect(iterable(<num>[1.2, 2, 3.5]).sum, 6.7);
        });
      });
      group('average', () {
        test('empty', () {
          expect(() => iterable(<int>[]).average, throwsStateError);
          expect(() => iterable(<double>[]).average, throwsStateError);
          expect(() => iterable(<num>[]).average, throwsStateError);
        });
        test('single', () {
          expect(iterable(<int>[4]).average, same(4.0));
          expect(iterable(<double>[3.5]).average, 3.5);
          expect(iterable(<num>[4]).average, same(4.0));
          expect(iterable(<num>[3.5]).average, 3.5);
        });
        test('multiple', () {
          expect(iterable(<int>[1, 3, 5]).average, same(3.0));
          expect(iterable(<int>[1, 3, 5, 9]).average, 4.5);
          expect(iterable(<double>[1.0, 3.0, 5.0, 9.0]).average, 4.5);
          expect(iterable(<num>[1, 3, 5, 9]).average, 4.5);
        });
      });
      group('.min', () {
        test('empty', () {
          expect(() => iterable(<int>[]).min, throwsStateError);
          expect(() => iterable(<double>[]).min, throwsStateError);
          expect(() => iterable(<num>[]).min, throwsStateError);
        });
        test('single', () {
          expect(iterable(<int>[1]).min, 1);
          expect(iterable(<double>[1.0]).min, 1.0);
          expect(iterable(<num>[1.0]).min, 1.0);
        });
        test('multiple', () {
          expect(iterable(<int>[3, 1, 2]).min, 1);
          expect(iterable(<double>[3.0, 1.0, 2.5]).min, 1.0);
          expect(iterable(<num>[3, 1, 2.5]).min, 1.0);
        });
        test('nan', () {
          expect(iterable(<double>[3.0, 1.0, double.nan]).min, isNaN);
          expect(iterable(<num>[3.0, 1, double.nan]).min, isNaN);
        });
      });
      group('.minOrNull', () {
        test('empty', () {
          expect(iterable(<int>[]).minOrNull, null);
          expect(iterable(<double>[]).minOrNull, null);
          expect(iterable(<num>[]).minOrNull, null);
        });
        test('single', () {
          expect(iterable(<int>[1]).minOrNull, 1);
          expect(iterable(<double>[1.0]).minOrNull, 1.0);
          expect(iterable(<num>[1.0]).minOrNull, 1.0);
        });
        test('multiple', () {
          expect(iterable(<int>[3, 1, 2]).minOrNull, 1);
          expect(iterable(<double>[3.0, 1.0, 2.5]).minOrNull, 1.0);
          expect(iterable(<num>[3, 1, 2.5]).minOrNull, 1.0);
        });
        test('nan', () {
          expect(iterable(<double>[3.0, 1.0, double.nan]).minOrNull, isNaN);
          expect(iterable(<num>[3.0, 1, double.nan]).minOrNull, isNaN);
        });
      });
      group('.max', () {
        test('empty', () {
          expect(() => iterable(<int>[]).max, throwsStateError);
          expect(() => iterable(<double>[]).max, throwsStateError);
          expect(() => iterable(<num>[]).max, throwsStateError);
        });
        test('single', () {
          expect(iterable(<int>[1]).max, 1);
          expect(iterable(<double>[1.0]).max, 1.0);
          expect(iterable(<num>[1.0]).max, 1.0);
        });
        test('multiple', () {
          expect(iterable(<int>[3, 1, 2]).max, 3);
          expect(iterable(<double>[3.0, 1.0, 2.5]).max, 3.0);
          expect(iterable(<num>[3, 1, 2.5]).max, 3);
        });
        test('nan', () {
          expect(iterable(<double>[3.0, 1.0, double.nan]).max, isNaN);
          expect(iterable(<num>[3.0, 1, double.nan]).max, isNaN);
        });
      });
      group('.maxOrNull', () {
        test('empty', () {
          expect(iterable(<int>[]).maxOrNull, null);
          expect(iterable(<double>[]).maxOrNull, null);
          expect(iterable(<num>[]).maxOrNull, null);
        });
        test('single', () {
          expect(iterable(<int>[1]).maxOrNull, 1);
          expect(iterable(<double>[1.0]).maxOrNull, 1.0);
          expect(iterable(<num>[1.0]).maxOrNull, 1.0);
        });
        test('multiple', () {
          expect(iterable(<int>[3, 1, 2]).maxOrNull, 3);
          expect(iterable(<double>[3.0, 1.0, 2.5]).maxOrNull, 3.0);
          expect(iterable(<num>[3, 1, 2.5]).maxOrNull, 3);
        });
        test('nan', () {
          expect(iterable(<double>[3.0, 1.0, double.nan]).maxOrNull, isNaN);
          expect(iterable(<num>[3.0, 1, double.nan]).maxOrNull, isNaN);
        });
      });
    });
    group('of iterable', () {
      group('.flattened', () {
        var empty = iterable(<int>[]);
        test('empty', () {
          expect(iterable(<Iterable<int>>[]).flattened, []);
        });
        test('multiple empty', () {
          expect(iterable([empty, empty, empty]).flattened, []);
        });
        test('single value', () {
          expect(
              iterable(<Iterable>[
                iterable([1])
              ]).flattened,
              [1]);
        });
        test('multiple', () {
          expect(
              iterable(<Iterable>[
                iterable([1, 2]),
                empty,
                iterable([3, 4])
              ]).flattened,
              [1, 2, 3, 4]);
        });
      });
    });
    group('of comparable', () {
      group('.min', () {
        test('empty', () {
          expect(() => iterable(<String>[]).min, throwsStateError);
        });
        test('single', () {
          expect(iterable(<String>['a']).min, 'a');
        });
        test('multiple', () {
          expect(iterable(<String>['c', 'a', 'b']).min, 'a');
        });
      });
      group('.minOrNull', () {
        test('empty', () {
          expect(iterable(<String>[]).minOrNull, null);
        });
        test('single', () {
          expect(iterable(<String>['a']).minOrNull, 'a');
        });
        test('multiple', () {
          expect(iterable(<String>['c', 'a', 'b']).minOrNull, 'a');
        });
      });
      group('.max', () {
        test('empty', () {
          expect(() => iterable(<String>[]).max, throwsStateError);
        });
        test('single', () {
          expect(iterable(<String>['a']).max, 'a');
        });
        test('multiple', () {
          expect(iterable(<String>['b', 'c', 'a']).max, 'c');
        });
      });
      group('.maxOrNull', () {
        test('empty', () {
          expect(iterable(<String>[]).maxOrNull, null);
        });
        test('single', () {
          expect(iterable(<String>['a']).maxOrNull, 'a');
        });
        test('multiple', () {
          expect(iterable(<String>['b', 'c', 'a']).maxOrNull, 'c');
        });
      });
    });
    group('.sorted', () {
      test('empty', () {
        expect(iterable(<String>[]).sorted(unreachable), []);
        expect(iterable(<String>[]).sorted(), []);
      });
      test('singleton', () {
        expect(iterable(['a']).sorted(unreachable), ['a']);
        expect(iterable(['a']).sorted(), ['a']);
      });
      test('multiple', () {
        expect(iterable(<String>['5', '2', '4', '3', '1']).sorted(cmpParse),
            ['1', '2', '3', '4', '5']);
        expect(
            iterable(<String>['5', '2', '4', '3', '1']).sorted(cmpParseInverse),
            ['5', '4', '3', '2', '1']);
        expect(iterable(<String>['5', '2', '4', '3', '1']).sorted(),
            ['1', '2', '3', '4', '5']);
        // Large enough to trigger quicksort.
        var i256 = Iterable<int>.generate(256, (i) => i ^ 0x55);
        var sorted256 = [...i256]..sort();
        expect(i256.sorted(cmpInt), sorted256);
      });
    });
    group('.isSorted', () {
      test('empty', () {
        expect(iterable(<String>[]).isSorted(unreachable), true);
        expect(iterable(<String>[]).isSorted(), true);
      });
      test('single', () {
        expect(iterable(['1']).isSorted(unreachable), true);
        expect(iterable(['1']).isSorted(), true);
      });
      test('same', () {
        expect(iterable(['1', '1', '1', '1']).isSorted(cmpParse), true);
        expect(iterable(['1', '2', '0', '3']).isSorted(cmpStringLength), true);
        expect(iterable(['1', '1', '1', '1']).isSorted(), true);
      });
      test('multiple', () {
        expect(iterable(['1', '2', '3', '4']).isSorted(cmpParse), true);
        expect(iterable(['1', '2', '3', '4']).isSorted(), true);
        expect(iterable(['4', '3', '2', '1']).isSorted(cmpParseInverse), true);
        expect(iterable(['1', '2', '3', '0']).isSorted(cmpParse), false);
        expect(iterable(['1', '2', '3', '0']).isSorted(), false);
        expect(iterable(['4', '1', '2', '3']).isSorted(cmpParse), false);
        expect(iterable(['4', '1', '2', '3']).isSorted(), false);
        expect(iterable(['4', '3', '2', '1']).isSorted(cmpParse), false);
        expect(iterable(['4', '3', '2', '1']).isSorted(), false);
      });
    });
    group('.sample', () {
      test('errors', () {
        expect(() => iterable([1]).sample(-1), throwsRangeError);
      });
      test('empty', () {
        var empty = iterable(<int>[]);
        expect(empty.sample(0), []);
        expect(empty.sample(5), []);
      });
      test('single', () {
        var single = iterable([1]);
        expect(single.sample(0), []);
        expect(single.sample(1), [1]);
        expect(single.sample(5), [1]);
      });
      test('multiple', () {
        var multiple = iterable([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
        expect(multiple.sample(0), []);
        var one = multiple.sample(1);
        expect(one, hasLength(1));
        expect(one.first, inInclusiveRange(1, 10));
        var some = multiple.sample(3);
        expect(some, hasLength(3));
        expect(some[0], inInclusiveRange(1, 10));
        expect(some[1], inInclusiveRange(1, 10));
        expect(some[2], inInclusiveRange(1, 10));
        expect(some[0], isNot(some[1]));
        expect(some[0], isNot(some[2]));
        expect(some[1], isNot(some[2]));

        var seen = <int>{};
        do {
          seen.addAll(multiple.sample(3));
        } while (seen.length < 10);
        // Should eventually terminate.
      });
      test('random', () {
        // Passing in a `Random` makes result deterministic.
        var multiple = iterable([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
        var seed = 12345;
        var some = multiple.sample(5, Random(seed));
        for (var i = 0; i < 10; i++) {
          var other = multiple.sample(5, Random(seed));
          expect(other, some);
        }
      });
    });
    group('.elementAtOrNull', () {
      test('empty', () async {
        expect(iterable([]).elementAtOrNull(0), isNull);
      });
      test('negative index', () async {
        expect(() => iterable([1]).elementAtOrNull(-1),
            throwsA(isA<RangeError>()));
      });
      test('index within range', () async {
        expect(iterable([1]).elementAtOrNull(0), 1);
      });
      test('index too high', () async {
        expect(iterable([1]).elementAtOrNull(1), isNull);
      });
    });
    group('.slices', () {
      test('empty', () {
        expect(iterable(<int>[]).slices(1), []);
      });
      test('with the same length as the iterable', () {
        expect(iterable([1, 2, 3]).slices(3), [
          [1, 2, 3]
        ]);
      });
      test('with a longer length than the iterable', () {
        expect(iterable([1, 2, 3]).slices(5), [
          [1, 2, 3]
        ]);
      });
      test('with a shorter length than the iterable', () {
        expect(iterable([1, 2, 3]).slices(2), [
          [1, 2],
          [3]
        ]);
      });
      test('with length divisible by the iterable\'s', () {
        expect(iterable([1, 2, 3, 4]).slices(2), [
          [1, 2],
          [3, 4]
        ]);
      });
      test('refuses negative length', () {
        expect(() => iterable([1]).slices(-1), throwsRangeError);
      });
      test('refuses length 0', () {
        expect(() => iterable([1]).slices(0), throwsRangeError);
      });
    });
  });

  group('Comparator', () {
    test('.inverse', () {
      var cmpStringInv = cmpString.inverse;
      expect(cmpString('a', 'b'), isNegative);
      expect(cmpStringInv('a', 'b'), isPositive);
      expect(cmpString('aa', 'a'), isPositive);
      expect(cmpStringInv('aa', 'a'), isNegative);
      expect(cmpString('a', 'a'), isZero);
      expect(cmpStringInv('a', 'a'), isZero);
    });
    test('.compareBy', () {
      var cmpByLength = cmpInt.compareBy((String s) => s.length);
      expect(cmpByLength('a', 'b'), 0);
      expect(cmpByLength('aa', 'b'), isPositive);
      expect(cmpByLength('b', 'aa'), isNegative);
      var cmpByInverseLength = cmpIntInverse.compareBy((String s) => s.length);
      expect(cmpByInverseLength('a', 'b'), 0);
      expect(cmpByInverseLength('aa', 'b'), isNegative);
      expect(cmpByInverseLength('b', 'aa'), isPositive);
    });

    test('.then', () {
      var cmpLengthFirst = cmpStringLength.then(cmpString);
      var strings = ['a', 'aa', 'ba', 'ab', 'b', 'aaa'];
      strings.sort(cmpString);
      expect(strings, ['a', 'aa', 'aaa', 'ab', 'b', 'ba']);
      strings.sort(cmpLengthFirst);
      expect(strings, ['a', 'b', 'aa', 'ab', 'ba', 'aaa']);

      int cmpFirstLetter(String s1, String s2) =>
          s1.runes.first - s2.runes.first;
      var cmpLetterLength = cmpFirstLetter.then(cmpStringLength);
      var cmpLengthLetter = cmpStringLength.then(cmpFirstLetter);
      strings = ['a', 'ab', 'b', 'ba', 'aaa'];
      strings.sort(cmpLetterLength);
      expect(strings, ['a', 'ab', 'aaa', 'b', 'ba']);
      strings.sort(cmpLengthLetter);
      expect(strings, ['a', 'b', 'ab', 'ba', 'aaa']);
    });
  });

  group('List', () {
    group('of any', () {
      group('.binarySearch', () {
        test('empty', () {
          expect(<int>[].binarySearch(1, unreachable), -1);
        });
        test('single', () {
          expect([0].binarySearch(1, cmpInt), -1);
          expect([1].binarySearch(1, cmpInt), 0);
          expect([2].binarySearch(1, cmpInt), -1);
        });
        test('multiple', () {
          expect([1, 2, 3, 4, 5, 6].binarySearch(3, cmpInt), 2);
          expect([6, 5, 4, 3, 2, 1].binarySearch(3, cmpIntInverse), 3);
        });
      });
      group('.binarySearchByCompare', () {
        test('empty', () {
          expect(<int>[].binarySearchByCompare(1, toString, cmpParse), -1);
        });
        test('single', () {
          expect([0].binarySearchByCompare(1, toString, cmpParse), -1);
          expect([1].binarySearchByCompare(1, toString, cmpParse), 0);
          expect([2].binarySearchByCompare(1, toString, cmpParse), -1);
        });
        test('multiple', () {
          expect(
              [1, 2, 3, 4, 5, 6].binarySearchByCompare(3, toString, cmpParse),
              2);
          expect(
              [6, 5, 4, 3, 2, 1]
                  .binarySearchByCompare(3, toString, cmpParseInverse),
              3);
        });
      });
      group('.binarySearchBy', () {
        test('empty', () {
          expect(<int>[].binarySearchBy(1, toString), -1);
        });
        test('single', () {
          expect([0].binarySearchBy(1, toString), -1);
          expect([1].binarySearchBy(1, toString), 0);
          expect([2].binarySearchBy(1, toString), -1);
        });
        test('multiple', () {
          expect([1, 2, 3, 4, 5, 6].binarySearchBy(3, toString), 2);
        });
      });

      group('.lowerBound', () {
        test('empty', () {
          expect(<int>[].lowerBound(1, unreachable), 0);
        });
        test('single', () {
          expect([0].lowerBound(1, cmpInt), 1);
          expect([1].lowerBound(1, cmpInt), 0);
          expect([2].lowerBound(1, cmpInt), 0);
        });
        test('multiple', () {
          expect([1, 2, 3, 4, 5, 6].lowerBound(3, cmpInt), 2);
          expect([6, 5, 4, 3, 2, 1].lowerBound(3, cmpIntInverse), 3);
          expect([1, 2, 4, 5, 6].lowerBound(3, cmpInt), 2);
          expect([6, 5, 4, 2, 1].lowerBound(3, cmpIntInverse), 3);
        });
      });
      group('.lowerBoundByCompare', () {
        test('empty', () {
          expect(<int>[].lowerBoundByCompare(1, toString, cmpParse), 0);
        });
        test('single', () {
          expect([0].lowerBoundByCompare(1, toString, cmpParse), 1);
          expect([1].lowerBoundByCompare(1, toString, cmpParse), 0);
          expect([2].lowerBoundByCompare(1, toString, cmpParse), 0);
        });
        test('multiple', () {
          expect(
              [1, 2, 3, 4, 5, 6].lowerBoundByCompare(3, toString, cmpParse), 2);
          expect(
              [6, 5, 4, 3, 2, 1]
                  .lowerBoundByCompare(3, toString, cmpParseInverse),
              3);
          expect([1, 2, 4, 5, 6].lowerBoundByCompare(3, toString, cmpParse), 2);
          expect(
              [6, 5, 4, 2, 1].lowerBoundByCompare(3, toString, cmpParseInverse),
              3);
        });
      });
      group('.lowerBoundBy', () {
        test('empty', () {
          expect(<int>[].lowerBoundBy(1, toString), 0);
        });
        test('single', () {
          expect([0].lowerBoundBy(1, toString), 1);
          expect([1].lowerBoundBy(1, toString), 0);
          expect([2].lowerBoundBy(1, toString), 0);
        });
        test('multiple', () {
          expect([1, 2, 3, 4, 5, 6].lowerBoundBy(3, toString), 2);
          expect([1, 2, 4, 5, 6].lowerBoundBy(3, toString), 2);
        });
      });
      group('sortRange', () {
        test('errors', () {
          expect(() => [1].sortRange(-1, 1, cmpInt), throwsArgumentError);
          expect(() => [1].sortRange(0, 2, cmpInt), throwsArgumentError);
          expect(() => [1].sortRange(1, 0, cmpInt), throwsArgumentError);
        });
        test('empty range', () {
          <int>[].sortRange(0, 0, unreachable);
          var list = [3, 2, 1];
          list.sortRange(0, 0, unreachable);
          list.sortRange(3, 3, unreachable);
          expect(list, [3, 2, 1]);
        });
        test('single', () {
          [1].sortRange(0, 1, unreachable);
          var list = [3, 2, 1];
          list.sortRange(0, 1, unreachable);
          list.sortRange(1, 2, unreachable);
          list.sortRange(2, 3, unreachable);
        });
        test('multiple', () {
          var list = [9, 8, 7, 6, 5, 4, 3, 2, 1];
          list.sortRange(2, 5, cmpInt);
          expect(list, [9, 8, 5, 6, 7, 4, 3, 2, 1]);
          list.sortRange(4, 8, cmpInt);
          expect(list, [9, 8, 5, 6, 2, 3, 4, 7, 1]);
          list.sortRange(3, 6, cmpIntInverse);
          expect(list, [9, 8, 5, 6, 3, 2, 4, 7, 1]);
        });
      });
      group('.sortBy', () {
        test('empty', () {
          expect(<int>[]..sortBy(unreachable), []);
        });
        test('singleton', () {
          expect([1]..sortBy(unreachable), [1]);
        });
        test('multiple', () {
          expect([3, 20, 100]..sortBy(toString), [100, 20, 3]);
        });
        group('range', () {
          test('errors', () {
            expect(() => [1].sortBy(toString, -1, 1), throwsArgumentError);
            expect(() => [1].sortBy(toString, 0, 2), throwsArgumentError);
            expect(() => [1].sortBy(toString, 1, 0), throwsArgumentError);
          });
          test('empty', () {
            expect([5, 7, 4, 2, 3]..sortBy(unreachable, 2, 2), [5, 7, 4, 2, 3]);
          });
          test('singleton', () {
            expect([5, 7, 4, 2, 3]..sortBy(unreachable, 2, 3), [5, 7, 4, 2, 3]);
          });
          test('multiple', () {
            expect(
                [5, 7, 40, 2, 3]..sortBy((a) => '$a', 1, 4), [5, 2, 40, 7, 3]);
          });
        });
      });
      group('.sortByCompare', () {
        test('empty', () {
          expect(<int>[]..sortByCompare(unreachable, unreachable), []);
        });
        test('singleton', () {
          expect([2]..sortByCompare(unreachable, unreachable), [2]);
        });
        test('multiple', () {
          expect([30, 2, 100]..sortByCompare(toString, cmpParseInverse),
              [100, 30, 2]);
        });
        group('range', () {
          test('errors', () {
            expect(() => [1].sortByCompare(toString, cmpParse, -1, 1),
                throwsArgumentError);
            expect(() => [1].sortByCompare(toString, cmpParse, 0, 2),
                throwsArgumentError);
            expect(() => [1].sortByCompare(toString, cmpParse, 1, 0),
                throwsArgumentError);
          });
          test('empty', () {
            expect(
                [3, 5, 7, 3, 1]..sortByCompare(unreachable, unreachable, 2, 2),
                [3, 5, 7, 3, 1]);
          });
          test('singleton', () {
            expect(
                [3, 5, 7, 3, 1]..sortByCompare(unreachable, unreachable, 2, 3),
                [3, 5, 7, 3, 1]);
          });
          test('multiple', () {
            expect(
                [3, 5, 7, 30, 1]
                  ..sortByCompare(toString, cmpParseInverse, 1, 4),
                [3, 30, 7, 5, 1]);
          });
        });
      });
      group('.shuffleRange', () {
        test('errors', () {
          expect(() => [1].shuffleRange(-1, 1), throwsArgumentError);
          expect(() => [1].shuffleRange(0, 2), throwsArgumentError);
          expect(() => [1].shuffleRange(1, 0), throwsArgumentError);
        });
        test('empty range', () {
          expect(<int>[]..shuffleRange(0, 0), []);
          expect([1, 2, 3, 4]..shuffleRange(0, 0), [1, 2, 3, 4]);
          expect([1, 2, 3, 4]..shuffleRange(4, 4), [1, 2, 3, 4]);
        });
        test('singleton range', () {
          expect([1, 2, 3, 4]..shuffleRange(0, 1), [1, 2, 3, 4]);
          expect([1, 2, 3, 4]..shuffleRange(3, 4), [1, 2, 3, 4]);
        });
        test('multiple', () {
          var list = [1, 2, 3, 4, 5];
          do {
            list.shuffleRange(0, 3);
            expect(list.getRange(3, 5), [4, 5]);
            expect(list.getRange(0, 3), unorderedEquals([1, 2, 3]));
          } while (ListEquality().equals(list.sublist(0, 3), [1, 2, 3]));
          // Won't terminate if shuffle *never* moves a value.
        });
      });
      group('.reverseRange', () {
        test('errors', () {
          expect(() => [1].reverseRange(-1, 1), throwsArgumentError);
          expect(() => [1].reverseRange(0, 2), throwsArgumentError);
          expect(() => [1].reverseRange(1, 0), throwsArgumentError);
        });
        test('empty range', () {
          expect(<int>[]..reverseRange(0, 0), []);
          expect([1, 2, 3, 4]..reverseRange(0, 0), [1, 2, 3, 4]);
          expect([1, 2, 3, 4]..reverseRange(4, 4), [1, 2, 3, 4]);
        });
        test('singleton range', () {
          expect([1, 2, 3, 4]..reverseRange(0, 1), [1, 2, 3, 4]);
          expect([1, 2, 3, 4]..reverseRange(3, 4), [1, 2, 3, 4]);
        });
        test('multiple', () {
          var list = [1, 2, 3, 4, 5];
          list.reverseRange(0, 3);
          expect(list, [3, 2, 1, 4, 5]);
          list.reverseRange(3, 5);
          expect(list, [3, 2, 1, 5, 4]);
          list.reverseRange(0, 5);
          expect(list, [4, 5, 1, 2, 3]);
        });
      });
      group('.swap', () {
        test('errors', () {
          expect(() => [1].swap(0, 1), throwsArgumentError);
          expect(() => [1].swap(1, 1), throwsArgumentError);
          expect(() => [1].swap(1, 0), throwsArgumentError);
          expect(() => [1].swap(-1, 0), throwsArgumentError);
        });
        test('self swap', () {
          expect([1]..swap(0, 0), [1]);
          expect([1, 2, 3]..swap(1, 1), [1, 2, 3]);
        });
        test('actual swap', () {
          expect([1, 2, 3]..swap(0, 2), [3, 2, 1]);
          expect([1, 2, 3]..swap(2, 0), [3, 2, 1]);
          expect([1, 2, 3]..swap(2, 1), [1, 3, 2]);
          expect([1, 2, 3]..swap(1, 2), [1, 3, 2]);
          expect([1, 2, 3]..swap(0, 1), [2, 1, 3]);
          expect([1, 2, 3]..swap(1, 0), [2, 1, 3]);
        });
      });
      group('.slice', () {
        test('errors', () {
          expect(() => [1].slice(-1, 1), throwsArgumentError);
          expect(() => [1].slice(0, 2), throwsArgumentError);
          expect(() => [1].slice(1, 0), throwsArgumentError);
          var l = <int>[1];
          var slice = l.slice(0, 1);
          l.removeLast();
          expect(() => slice.first, throwsConcurrentModificationError);
        });
        test('empty', () {
          expect([].slice(0, 0), isEmpty);
        });
        test('modify', () {
          var list = [1, 2, 3, 4, 5, 6, 7, 8, 9];
          var slice = list.slice(2, 6);
          expect(slice, [3, 4, 5, 6]);
          slice.sort(cmpIntInverse);
          expect(slice, [6, 5, 4, 3]);
          expect(list, [1, 2, 6, 5, 4, 3, 7, 8, 9]);
        });
      });
      group('equals', () {
        test('empty', () {
          expect(<Object>[].equals(<int>[]), true);
        });
        test('non-empty', () {
          expect([1, 2.5, 'a'].equals([1.0, 2.5, 'a']), true);
          expect([1, 2.5, 'a'].equals([1.0, 2.5, 'b']), false);
          expect(
              [
                [1]
              ].equals([
                [1]
              ]),
              false);
          expect(
              [
                [1]
              ].equals([
                [1]
              ], const ListEquality()),
              true);
        });
      });
      group('.forEachIndexed', () {
        test('empty', () {
          [].forEachIndexed(unreachable);
        });
        test('single', () {
          var log = [];
          ['a'].forEachIndexed((i, s) {
            log
              ..add(i)
              ..add(s);
          });
          expect(log, [0, 'a']);
        });
        test('multiple', () {
          var log = [];
          ['a', 'b', 'c'].forEachIndexed((i, s) {
            log
              ..add(i)
              ..add(s);
          });
          expect(log, [0, 'a', 1, 'b', 2, 'c']);
        });
      });
      group('.forEachWhile', () {
        test('empty', () {
          [].forEachWhile(unreachable);
        });
        test('single true', () {
          var log = [];
          ['a'].forEachWhile((s) {
            log.add(s);
            return true;
          });
          expect(log, ['a']);
        });
        test('single false', () {
          var log = [];
          ['a'].forEachWhile((s) {
            log.add(s);
            return false;
          });
          expect(log, ['a']);
        });
        test('multiple one', () {
          var log = [];
          ['a', 'b', 'c'].forEachWhile((s) {
            log.add(s);
            return false;
          });
          expect(log, ['a']);
        });
        test('multiple all', () {
          var log = [];
          ['a', 'b', 'c'].forEachWhile((s) {
            log.add(s);
            return true;
          });
          expect(log, ['a', 'b', 'c']);
        });
        test('multiple some', () {
          var log = [];
          ['a', 'b', 'c'].forEachWhile((s) {
            log.add(s);
            return s != 'b';
          });
          expect(log, ['a', 'b']);
        });
      });
      group('.forEachIndexedWhile', () {
        test('empty', () {
          [].forEachIndexedWhile(unreachable);
        });
        test('single true', () {
          var log = [];
          ['a'].forEachIndexedWhile((i, s) {
            log
              ..add(i)
              ..add(s);
            return true;
          });
          expect(log, [0, 'a']);
        });
        test('single false', () {
          var log = [];
          ['a'].forEachIndexedWhile((i, s) {
            log
              ..add(i)
              ..add(s);
            return false;
          });
          expect(log, [0, 'a']);
        });
        test('multiple one', () {
          var log = [];
          ['a', 'b', 'c'].forEachIndexedWhile((i, s) {
            log
              ..add(i)
              ..add(s);
            return false;
          });
          expect(log, [0, 'a']);
        });
        test('multiple all', () {
          var log = [];
          ['a', 'b', 'c'].forEachIndexedWhile((i, s) {
            log
              ..add(i)
              ..add(s);
            return true;
          });
          expect(log, [0, 'a', 1, 'b', 2, 'c']);
        });
        test('multiple some', () {
          var log = [];
          ['a', 'b', 'c'].forEachIndexedWhile((i, s) {
            log
              ..add(i)
              ..add(s);
            return s != 'b';
          });
          expect(log, [0, 'a', 1, 'b']);
        });
      });
      group('.mapIndexed', () {
        test('empty', () {
          expect(<String>[].mapIndexed(unreachable), isEmpty);
        });
        test('multiple', () {
          expect(<String>['a', 'b'].mapIndexed((i, s) => [i, s]), [
            [0, 'a'],
            [1, 'b']
          ]);
        });
      });
      group('.whereIndexed', () {
        test('empty', () {
          expect(<String>[].whereIndexed(unreachable), isEmpty);
        });
        test('none', () {
          var trace = [];
          int log(int a, int b) {
            trace
              ..add(a)
              ..add(b);
            return b;
          }

          expect(<int>[1, 3, 5, 7].whereIndexed((i, x) => log(i, x).isEven),
              isEmpty);
          expect(trace, [0, 1, 1, 3, 2, 5, 3, 7]);
        });
        test('all', () {
          expect(
              <int>[1, 3, 5, 7].whereIndexed((i, x) => x.isOdd), [1, 3, 5, 7]);
        });
        test('some', () {
          expect(<int>[1, 3, 5, 7].whereIndexed((i, x) => i.isOdd), [3, 7]);
        });
      });
      group('.whereNotIndexed', () {
        test('empty', () {
          expect(<int>[].whereNotIndexed(unreachable), isEmpty);
        });
        test('none', () {
          var trace = [];
          int log(int a, int b) {
            trace
              ..add(a)
              ..add(b);
            return b;
          }

          expect(<int>[1, 3, 5, 7].whereNotIndexed((i, x) => log(i, x).isOdd),
              isEmpty);
          expect(trace, [0, 1, 1, 3, 2, 5, 3, 7]);
        });
        test('all', () {
          expect(<int>[1, 3, 5, 7].whereNotIndexed((i, x) => x.isEven),
              [1, 3, 5, 7]);
        });
        test('some', () {
          expect(<int>[1, 3, 5, 7].whereNotIndexed((i, x) => i.isOdd), [1, 5]);
        });
      });
      group('.expandIndexed', () {
        test('empty', () {
          expect(<int>[].expandIndexed(unreachable), isEmpty);
        });
        test('empty result', () {
          expect(['a', 'b'].expandIndexed((i, v) => []), isEmpty);
        });
        test('larger result', () {
          expect(['a', 'b'].expandIndexed((i, v) => ['$i', v]),
              ['0', 'a', '1', 'b']);
        });
        test('varying result', () {
          expect(['a', 'b'].expandIndexed((i, v) => i.isOdd ? ['$i', v] : []),
              ['1', 'b']);
        });
      });
      group('.elementAtOrNull', () {
        test('empty', () async {
          expect([].elementAtOrNull(0), isNull);
        });
        test('negative index', () async {
          expect(() => [1].elementAtOrNull(-1), throwsA(isA<RangeError>()));
        });
        test('index within range', () async {
          expect([1].elementAtOrNull(0), 1);
        });
        test('index too high', () async {
          expect([1].elementAtOrNull(1), isNull);
        });
      });
      group('.slices', () {
        test('empty', () {
          expect(<int>[].slices(1), []);
        });
        test('with the same length as the iterable', () {
          expect([1, 2, 3].slices(3), [
            [1, 2, 3]
          ]);
        });
        test('with a longer length than the iterable', () {
          expect([1, 2, 3].slices(5), [
            [1, 2, 3]
          ]);
        });
        test('with a shorter length than the iterable', () {
          expect([1, 2, 3].slices(2), [
            [1, 2],
            [3]
          ]);
        });
        test('with length divisible by the iterable\'s', () {
          expect([1, 2, 3, 4].slices(2), [
            [1, 2],
            [3, 4]
          ]);
        });
        test('refuses negative length', () {
          expect(() => [1].slices(-1), throwsRangeError);
        });
        test('refuses length 0', () {
          expect(() => [1].slices(0), throwsRangeError);
        });
      });
    });
    group('on comparable', () {
      group('.binarySearch', () {
        test('empty', () {
          expect(<String>[].binarySearch('1', unreachable), -1);
          expect(<String>[].binarySearch('1'), -1);
        });
        test('single', () {
          expect(['0'].binarySearch('1', cmpString), -1);
          expect(['1'].binarySearch('1', cmpString), 0);
          expect(['2'].binarySearch('1', cmpString), -1);
          expect(
              ['0'].binarySearch(
                '1',
              ),
              -1);
          expect(
              ['1'].binarySearch(
                '1',
              ),
              0);
          expect(
              ['2'].binarySearch(
                '1',
              ),
              -1);
        });
        test('multiple', () {
          expect(
              ['1', '2', '3', '4', '5', '6'].binarySearch('3', cmpString), 2);
          expect(['1', '2', '3', '4', '5', '6'].binarySearch('3'), 2);
          expect(
              ['6', '5', '4', '3', '2', '1'].binarySearch('3', cmpParseInverse),
              3);
        });
      });
    });
    group('.lowerBound', () {
      test('empty', () {
        expect(<String>[].lowerBound('1', unreachable), 0);
      });
      test('single', () {
        expect(['0'].lowerBound('1', cmpString), 1);
        expect(['1'].lowerBound('1', cmpString), 0);
        expect(['2'].lowerBound('1', cmpString), 0);
        expect(['0'].lowerBound('1'), 1);
        expect(['1'].lowerBound('1'), 0);
        expect(['2'].lowerBound('1'), 0);
      });
      test('multiple', () {
        expect(['1', '2', '3', '4', '5', '6'].lowerBound('3', cmpParse), 2);
        expect(['1', '2', '3', '4', '5', '6'].lowerBound('3'), 2);
        expect(
            ['6', '5', '4', '3', '2', '1'].lowerBound('3', cmpParseInverse), 3);
        expect(['1', '2', '4', '5', '6'].lowerBound('3', cmpParse), 2);
        expect(['1', '2', '4', '5', '6'].lowerBound('3'), 2);
        expect(['6', '5', '4', '2', '1'].lowerBound('3', cmpParseInverse), 3);
      });
    });
    group('sortRange', () {
      test('errors', () {
        expect(() => [1].sortRange(-1, 1, cmpInt), throwsArgumentError);
        expect(() => [1].sortRange(0, 2, cmpInt), throwsArgumentError);
        expect(() => [1].sortRange(1, 0, cmpInt), throwsArgumentError);
      });
      test('empty range', () {
        <int>[].sortRange(0, 0, unreachable);
        var list = [3, 2, 1];
        list.sortRange(0, 0, unreachable);
        list.sortRange(3, 3, unreachable);
        expect(list, [3, 2, 1]);
      });
      test('single', () {
        [1].sortRange(0, 1, unreachable);
        var list = [3, 2, 1];
        list.sortRange(0, 1, unreachable);
        list.sortRange(1, 2, unreachable);
        list.sortRange(2, 3, unreachable);
      });
      test('multiple', () {
        var list = [9, 8, 7, 6, 5, 4, 3, 2, 1];
        list.sortRange(2, 5, cmpInt);
        expect(list, [9, 8, 5, 6, 7, 4, 3, 2, 1]);
        list.sortRange(4, 8, cmpInt);
        expect(list, [9, 8, 5, 6, 2, 3, 4, 7, 1]);
        list.sortRange(3, 6, cmpIntInverse);
        expect(list, [9, 8, 5, 6, 3, 2, 4, 7, 1]);
      });
    });
  });
}

/// Creates a plain iterable not implementing any other class.
Iterable<T> iterable<T>(Iterable<T> values) sync* {
  yield* values;
}

Never unreachable([_, __, ___]) => fail('Unreachable');

String toString(Object? o) => '$o';

/// Compares values equal if they have the same remainder mod [mod].
int Function(int, int) cmpMod(int mod) => (a, b) => a ~/ mod - b ~/ mod;

/// Compares strings lexically.
int cmpString(String a, String b) => a.compareTo(b);

/// Compares strings inverse lexically.
int cmpStringInverse(String a, String b) => b.compareTo(a);

/// Compares strings by length.
int cmpStringLength(String a, String b) => a.length - b.length;

/// Compares strings by their integer numeral content.
int cmpParse(String s1, String s2) => cmpInt(int.parse(s1), int.parse(s2));

/// Compares strings inversely by their integer numeral content.
int cmpParseInverse(String s1, String s2) =>
    cmpIntInverse(int.parse(s1), int.parse(s2));

/// Compares integers by size.
int cmpInt(int a, int b) => a - b;

/// Compares integers by inverse size.
int cmpIntInverse(int a, int b) => b - a;

/// Tests an integer for being even.
bool isEven(int x) => x.isEven;

/// Tests an integer for being odd.
bool isOdd(int x) => x.isOdd;
