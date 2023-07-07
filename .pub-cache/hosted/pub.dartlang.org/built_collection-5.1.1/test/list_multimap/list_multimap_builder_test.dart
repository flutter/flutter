// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/src/list_multimap.dart';
import 'package:test/test.dart';

import '../performance.dart';

void main() {
  group('ListMultimapBuilder', () {
    test('allows <dynamic, dynamic>', () {
      ListMultimapBuilder<dynamic, dynamic>();
    });

    test('allows <Object, Object>', () {
      ListMultimapBuilder<Object, Object>();
    });

    test('throws on null key add', () {
      expect(() => ListMultimapBuilder<int, String>().add(null as dynamic, '0'),
          throwsA(anything));
    });

    test('nullable does not throw on null key add', () {
      var builder = ListMultimapBuilder<int?, String>();
      builder.add(null, '0');
      expect(builder[null].build(), ['0']);
    });

    test('throws on null value add', () {
      expect(() => ListMultimapBuilder<int, String>().add(0, null as dynamic),
          throwsA(anything));
    });

    test('nullable does not throw on null value add', () {
      var builder = ListMultimapBuilder<int, String?>();
      builder.add(0, null);
      expect(builder[0].build(), [null]);
    });

    test('throws on wrong type value addValues', () {
      expect(
          () => ListMultimapBuilder<int, String>()
              .addValues(0, List<String>.from([0])),
          throwsA(anything));
    });

    test('has replace method that replaces all data', () {
      expect(
          (ListMultimapBuilder<int, String>()
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
          (ListMultimapBuilder<int, int>()..addIterable([1, 2, 3]))
              .build()
              .toMap(),
          {
            1: [1],
            2: [2],
            3: [3]
          });
      expect(
          (ListMultimapBuilder<int, int>()
                ..addIterable([1, 2, 3], key: (int element) => element + 1))
              .build()
              .toMap(),
          {
            2: [1],
            3: [2],
            4: [3]
          });
      expect(
          (ListMultimapBuilder<int, int>()
                ..addIterable([1, 2, 3], value: (int element) => element + 1))
              .build()
              .toMap(),
          {
            1: [2],
            2: [3],
            3: [4]
          });
      expect(
          (ListMultimapBuilder<int, int>()
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

    test('does not mutate BuiltListMultimap following reuse of underlying Map',
        () {
      var multimap = BuiltListMultimap<int, String>({
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

    test('converts to BuiltListMultimap without copying', () {
      var makeLongListMultimapBuilder = () {
        var result = ListMultimapBuilder<int, int>();
        for (var i = 0; i != 100000; ++i) {
          result.add(0, i);
        }
        return result;
      };
      var longListMultimapBuilder = makeLongListMultimapBuilder();
      var buildLongListMultimapBuilder = () => longListMultimapBuilder.build();

      expectMuchFaster(
          buildLongListMultimapBuilder, makeLongListMultimapBuilder);
    });

    test('does not mutate BuiltListMultimap following mutates after build', () {
      var multimapBuilder = ListMultimapBuilder<int, String>({
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

    test('returns identical BuiltListMultimap on repeated build', () {
      var multimapBuilder = ListMultimapBuilder<int, String>({
        1: ['1', '2', '3']
      });
      expect(multimapBuilder.build(), same(multimapBuilder.build()));
    });

    // Modification of existing data.

    test('adds to copied lists', () {
      var multimap = BuiltListMultimap<int, String>({
        1: ['1']
      });
      var multimapBuilder = multimap.toBuilder();
      expect((multimapBuilder..add(1, '2')).build().toMap(), {
        1: ['1', '2']
      });
    });

    test('removes from copied lists', () {
      var multimap = BuiltListMultimap<int, String>({
        1: ['1', '2', '3']
      });
      var multimapBuilder = multimap.toBuilder();
      expect(multimapBuilder.remove(1, '2'), true);
      expect(multimapBuilder.build().toMap(), {
        1: ['1', '3']
      });
    });

    test('removes from copied lists to empty', () {
      var multimap = BuiltListMultimap<int, String>({
        1: ['1']
      });
      var multimapBuilder = multimap.toBuilder();
      expect(multimapBuilder.remove(1, '1'), true);
      expect(multimapBuilder.build().toMap(), {});
    });

    test('removes all from copied lists', () {
      var value = ['1', '2', '3'];
      var multimap = BuiltListMultimap<int, String>({1: value});
      var multimapBuilder = multimap.toBuilder();
      expect(multimapBuilder.removeAll(1).toList(), value);
      expect(multimapBuilder.build().toMap(), {});
    });

    test('clears copied lists', () {
      var multimap = BuiltListMultimap<int, String>({
        1: ['1', '2', '3']
      });
      var multimapBuilder = multimap.toBuilder();
      expect((multimapBuilder..clear()).build().toMap(), {});
    });

    // Map.

    test('has a method like ListMultimap.add', () {
      expect(
          (ListMultimapBuilder<int, String>({
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
          (BuiltListMultimap<int, String>({
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

    test('has a method like ListMultimap.addValues', () {
      expect(
          (ListMultimapBuilder<int, String>({
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
          (BuiltListMultimap<int, String>({
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

    test('has a method like ListMultimap.remove', () {
      var builder = ListMultimapBuilder<int, String>({
        1: ['1'],
        2: ['2', '3']
      });
      expect(builder.remove(2, '3'), true);
      expect(builder.remove(2, '3'), false);
      expect(builder.remove(2, '7'), false);
      expect(builder.build().toMap(), {
        1: ['1'],
        2: ['2']
      });
      expect(
          (BuiltListMultimap<int, String>({
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

    test('has a method like ListMultimap.removeAll', () {
      var value = ['2', '3'];
      var builder = ListMultimapBuilder<int, String>({
        1: ['1'],
        2: value
      });
      expect(builder.removeAll(2).toList(), value);
      expect(builder.removeAll(2).toList(), []);
      expect(builder.removeAll(3).toList(), []);
      expect(builder.build().toMap(), {
        1: ['1']
      });
      expect(
          (BuiltListMultimap<int, String>({
            1: ['1'],
            2: value
          }).toBuilder()
                ..removeAll(2))
              .build()
              .toMap(),
          {
            1: ['1']
          });
    });

    test('removeAll does not detach ListBuilder', () {
      var builder = ListMultimapBuilder<int, String>({
        1: ['1'],
        2: ['2', '3'],
      });
      var listBuilder = builder[2];
      builder.removeAll(2);
      expect(listBuilder.build().toList(), []);

      listBuilder.add('4');
      expect(builder.build()[2].toList(), ['4']);
    });

    test('has a method like ListMultimap.clear', () {
      expect(
          (ListMultimapBuilder<int, String>({
            1: ['1'],
            2: ['2']
          })
                ..clear())
              .build()
              .toMap(),
          {});
      expect(
          (BuiltListMultimap<int, String>({
            1: ['1'],
            2: ['2']
          }).toBuilder()
                ..clear())
              .build()
              .toMap(),
          {});
    });

    test('has a method like ListMultimap[] which can be used to read values',
        () {
      expect(
          BuiltListMultimap<int, String>({
            1: ['1'],
            2: ['2'],
            3: ['3']
          }).toBuilder()[2].build().toList(),
          ['2']);
      expect(
          BuiltListMultimap<int, String>({
            1: ['1'],
            2: ['2'],
            3: ['3']
          }).toBuilder()[4].build().toList(),
          []);
    });

    test('has a method like ListMultimap[] which can be used to write values',
        () {
      var builder = BuiltListMultimap<int, String>().toBuilder();
      builder[1].add('1');
      expect(builder.build()[1], ['1']);
    });
  });
}
