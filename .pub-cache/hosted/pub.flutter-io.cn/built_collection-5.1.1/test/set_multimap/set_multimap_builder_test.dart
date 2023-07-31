// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/src/set_multimap.dart';
import 'package:test/test.dart';

import '../performance.dart';

void main() {
  group('SetMultimapBuilder', () {
    test('allows <dynamic, dynamic>', () {
      SetMultimapBuilder<dynamic, dynamic>();
    });

    test('allows <Object, Object>', () {
      SetMultimapBuilder<Object, Object>();
    });

    test('throws on null key add', () {
      expect(() => SetMultimapBuilder<int, String>().add(null as dynamic, '0'),
          throwsA(anything));
    });

    test('nullable does not throw on null key add', () {
      var builder = SetMultimapBuilder<int?, String>();
      builder.add(null, '0');
      expect(builder.build()[null], {'0'});
    });

    test('throws on null value add', () {
      expect(() => SetMultimapBuilder<int, String>().add(0, null as dynamic),
          throwsA(anything));
    });

    test('nullable does not throw on null value add', () {
      var builder = SetMultimapBuilder<int, String?>();
      builder.add(0, null);
      expect(builder.build()[0], {null});
    });

    test('throws on wrong type value addValues', () {
      expect(
          () => SetMultimapBuilder<int, String>().addValues(0, List.from([0])),
          throwsA(anything));
    });

    test('has replace method that replaces all data', () {
      expect(
          (SetMultimapBuilder<int, String>()
                ..replace({
                  1: ['1'],
                  2: ['2']
                }))
              .build()
              .toMap(),
          {
            1: ['1'],
            2: ['2']
          });
    });

    test('has addIterable method like Map.fromIterable', () {
      expect(
          (SetMultimapBuilder<int, int>()..addIterable([1, 2, 3]))
              .build()
              .toMap(),
          {
            1: [1],
            2: [2],
            3: [3]
          });
      expect(
          (SetMultimapBuilder<int, int>()
                ..addIterable([1, 2, 3], key: (int element) => element + 1))
              .build()
              .toMap(),
          {
            2: [1],
            3: [2],
            4: [3]
          });
      expect(
          (SetMultimapBuilder<int, int>()
                ..addIterable([1, 2, 3], value: (int element) => element + 1))
              .build()
              .toMap(),
          {
            1: [2],
            2: [3],
            3: [4]
          });
      expect(
          (SetMultimapBuilder<int, int>()
                ..addIterable([1, 2, 3],
                    values: (int element) => <int>[element, element + 1]))
              .build()
              .toMap(),
          {
            1: [1, 2],
            2: [2, 3],
            3: [3, 4]
          });
    });

    // Lazy copies.

    test('does not mutate BuiltSetMultimap following reuse of underlying Map',
        () {
      var multimap = BuiltSetMultimap<int, String>({
        1: ['1'],
        2: ['2']
      });
      var multimapBuilder = multimap.toBuilder();
      multimapBuilder.add(3, '3');
      expect(
          multimap.toMap(),
          ({
            1: ['1'],
            2: ['2']
          }));
    });

    test('converts to BuiltSetMultimap without copying', () {
      var makeLongSetMultimapBuilder = () {
        var result = SetMultimapBuilder<int, int>();
        for (var i = 0; i != 100000; ++i) {
          result.add(0, i);
        }
        return result;
      };
      var longSetMultimapBuilder = makeLongSetMultimapBuilder();
      var buildLongSetMultimapBuilder = () => longSetMultimapBuilder.build();

      expectMuchFaster(buildLongSetMultimapBuilder, makeLongSetMultimapBuilder);
    });

    test('does not mutate BuiltSetMultimap following mutates after build', () {
      var multimapBuilder = SetMultimapBuilder<int, String>({
        1: ['1'],
        2: ['2']
      });

      var map1 = multimapBuilder.build();
      expect(
          map1.toMap(),
          ({
            1: ['1'],
            2: ['2']
          }));

      multimapBuilder.add(3, '3');
      expect(
          map1.toMap(),
          ({
            1: ['1'],
            2: ['2']
          }));

      multimapBuilder.build();
      expect(
          map1.toMap(),
          ({
            1: ['1'],
            2: ['2']
          }));

      multimapBuilder.add(4, '4');
      expect(
          map1.toMap(),
          ({
            1: ['1'],
            2: ['2']
          }));

      multimapBuilder.build();
      expect(
          map1.toMap(),
          ({
            1: ['1'],
            2: ['2']
          }));
    });

    test('returns identical BuiltSetMultimap on repeated build', () {
      var multimapBuilder = SetMultimapBuilder<int, String>({
        1: ['1', '2', '3']
      });
      expect(multimapBuilder.build(), same(multimapBuilder.build()));
    });

    // Modification of existing data.

    test('adds to copied sets', () {
      var multimap = BuiltSetMultimap<int, String>({
        1: ['1']
      });
      var multimapBuilder = multimap.toBuilder();
      expect((multimapBuilder..add(1, '2')).build().toMap(), {
        1: ['1', '2']
      });
    });

    test('removes from copied sets', () {
      var multimap = BuiltSetMultimap<int, String>({
        1: ['1', '2', '3']
      });
      var multimapBuilder = multimap.toBuilder();
      expect((multimapBuilder..remove(1, '2')).build().toMap(), {
        1: ['1', '3']
      });
    });

    test('removes from copied sets to empty', () {
      var multimap = BuiltSetMultimap<int, String>({
        1: ['1']
      });
      var multimapBuilder = multimap.toBuilder();
      expect((multimapBuilder..remove(1, '1')).build().toMap(), {});
    });

    test('removes all from copied sets', () {
      var multimap = BuiltSetMultimap<int, String>({
        1: ['1', '2', '3']
      });
      var multimapBuilder = multimap.toBuilder();
      expect((multimapBuilder..removeAll(1)).build().toMap(), {});
    });

    test('clears copied sets', () {
      var multimap = BuiltSetMultimap<int, String>({
        1: ['1', '2', '3']
      });
      var multimapBuilder = multimap.toBuilder();
      expect((multimapBuilder..clear()).build().toMap(), {});
    });

    // Map.

    test('has a method like SetMultimap.add', () {
      expect(
          (SetMultimapBuilder<int, String>({
            1: ['1']
          })
                ..add(2, '2'))
              .build()
              .toMap(),
          ({
            1: ['1'],
            2: ['2']
          }));
      expect(
          (BuiltSetMultimap<int, String>({
            1: ['1']
          }).toBuilder()
                ..add(2, '2'))
              .build()
              .toMap(),
          ({
            1: ['1'],
            2: ['2']
          }));
    });

    test('has a method like SetMultimap.addValues', () {
      expect(
          (SetMultimapBuilder<int, String>({
            1: ['1']
          })
                ..addValues(2, ['2', '3']))
              .build()
              .toMap(),
          ({
            1: ['1'],
            2: ['2', '3']
          }));
      expect(
          (BuiltSetMultimap<int, String>({
            1: ['1']
          }).toBuilder()
                ..addValues(2, ['2', '3']))
              .build()
              .toMap(),
          ({
            1: ['1'],
            2: ['2', '3']
          }));
    });

    test('has a method like SetMultimap.remove that returns nothing', () {
      expect(
          (SetMultimapBuilder<int, String>({
            1: ['1'],
            2: ['2', '3']
          })
                ..remove(2, '3'))
              .build()
              .toMap(),
          {
            1: ['1'],
            2: ['2']
          });
      expect(
          (BuiltSetMultimap<int, String>({
            1: ['1'],
            2: ['2', '3']
          }).toBuilder()
                ..remove(2, '3'))
              .build()
              .toMap(),
          {
            1: ['1'],
            2: ['2']
          });
    });

    test('has a method like SetMultimap.removeAll that returns nothing', () {
      expect(
          (SetMultimapBuilder<int, String>({
            1: ['1'],
            2: ['2', '3']
          })
                ..removeAll(2))
              .build()
              .toMap(),
          {
            1: ['1']
          });
      expect(
          (BuiltSetMultimap<int, String>({
            1: ['1'],
            2: ['2', '3']
          }).toBuilder()
                ..removeAll(2))
              .build()
              .toMap(),
          {
            1: ['1']
          });
    });

    test('has a method like SetMultimap.clear', () {
      expect(
          (SetMultimapBuilder<int, String>({
            1: ['1'],
            2: ['2']
          })
                ..clear())
              .build()
              .toMap(),
          {});
      expect(
          (BuiltSetMultimap<int, String>({
            1: ['1'],
            2: ['2']
          }).toBuilder()
                ..clear())
              .build()
              .toMap(),
          {});
    });
  });
}
