// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/src/list.dart';
import 'package:built_collection/src/list_multimap.dart';
import 'package:built_collection/src/internal/test_helpers.dart';
import 'package:test/test.dart';

import '../performance.dart';

void main() {
  group('BuiltListMultimap', () {
    test('instantiates empty by default', () {
      var multimap = BuiltListMultimap<int, String>();
      expect(multimap.isEmpty, isTrue);
      expect(multimap.isNotEmpty, isFalse);
    });

    test('allows <dynamic, dynamic>', () {
      BuiltListMultimap<dynamic, dynamic>();
    });

    test('can be instantiated from ListMultimap', () {
      BuiltListMultimap<int, String>({});
    });

    test('reports non-emptiness', () {
      var map = BuiltListMultimap<int, String>({
        1: ['1']
      });
      expect(map.isEmpty, isFalse);
      expect(map.isNotEmpty, isTrue);
    });

    test(
        'can be instantiated from ListMultimap '
        'then converted back to equal ListMultimap', () {
      var mutableMultimap = _ListMultimap<int, String>();
      mutableMultimap.add(1, '1');
      var multimap = BuiltListMultimap<int, String>(mutableMultimap);
      expect(multimap.toMap(), mutableMultimap.asMap());
    });

    test('throws on wrong type key', () {
      expect(
          () => BuiltListMultimap<int, String>({
                '1': ['1']
              }),
          throwsA(anything));
    });

    test('throws on wrong type value iterable', () {
      expect(() => BuiltListMultimap<int, String>({1: 1}), throwsA(anything));
    });

    test('throws on wrong type value', () {
      expect(
          () => BuiltListMultimap<int, String>({
                1: [1]
              }),
          throwsA(anything));
    });

    test('does not keep a mutable ListMultimap', () {
      var mutableMultimap = _ListMultimap<int, String>();
      mutableMultimap.add(1, '1');
      var multimap = BuiltListMultimap<int, String>(mutableMultimap);
      mutableMultimap.clear();
      expect(multimap.toMap(), {
        1: ['1']
      });
    });

    test('copies from BuiltListMultimap instances of different type', () {
      var multimap1 = BuiltListMultimap<Object, Object>();
      var multimap2 = BuiltListMultimap<int, String>(multimap1);
      expect(multimap1, isNot(same(multimap2)));
    });

    test('can be converted to Map<K, BuiltList<V>>', () {
      expect(
        BuiltListMultimap<int, String>().toMap(),
        const TypeMatcher<Map<int, BuiltList<String>>>(),
      );
      expect(
        BuiltListMultimap<int, String>().toMap(),
        isNot(const TypeMatcher<Map<int, BuiltList<int>>>()),
      );
      expect(
        BuiltListMultimap<int, String>().toMap(),
        isNot(const TypeMatcher<Map<String, BuiltList<String>>>()),
      );
    });

    test('can be converted to an UnmodifiableMapView', () {
      var immutableMap = BuiltListMultimap<int, String>().asMap();
      expect(immutableMap, const TypeMatcher<Map<int, Iterable<String>>>());
      expect(() => immutableMap[1] = ['Hello'], throwsUnsupportedError);
      expect(immutableMap, isEmpty);
    });

    test('can be converted to ListMultimapBuilder<K, V>', () {
      expect(
        BuiltListMultimap<int, String>().toBuilder(),
        const TypeMatcher<ListMultimapBuilder<int, String>>(),
      );
      expect(
        BuiltListMultimap<int, String>().toBuilder(),
        isNot(const TypeMatcher<ListMultimapBuilder<int, int>>()),
      );
      expect(
        BuiltListMultimap<int, String>().toBuilder(),
        isNot(const TypeMatcher<ListMultimapBuilder<String, String>>()),
      );
    });

    test(
        'can be converted to ListMultimapBuilder<K, V> and back to ListMultimap<K, V>',
        () {
      expect(
        BuiltListMultimap<int, String>().toBuilder().build(),
        const TypeMatcher<BuiltListMultimap<int, String>>(),
      );
      expect(
        BuiltListMultimap<int, String>().toBuilder().build(),
        isNot(const TypeMatcher<BuiltListMultimap<int, int>>()),
      );
      expect(
        BuiltListMultimap<int, String>().toBuilder().build(),
        isNot(const TypeMatcher<BuiltListMultimap<String, String>>()),
      );
    });

    test('throws on null keys', () {
      expect(
          () => BuiltListMultimap<int, String>({
                null: ['1']
              }),
          throwsA(anything));
    });

    test('nullable does not throw on null keys', () {
      expect(
          BuiltListMultimap<int?, String>({
            null: ['1']
          }).asMap(),
          {
            null: ['1']
          });
    });

    test('throws on null value iterables', () {
      expect(
          () => BuiltListMultimap<int, String>({1: null}), throwsA(anything));
    });

    test('nullable also throws on null value iterables', () {
      expect(
          () => BuiltListMultimap<int, String?>({1: null}), throwsA(anything));
    });

    test('throws on null values', () {
      expect(
          () => BuiltListMultimap<int, String>({
                1: [null]
              }),
          throwsA(anything));
    });

    test('nullable does not throw on null values', () {
      expect(
          BuiltListMultimap<int, String?>({
            1: [null]
          }).asMap(),
          {
            1: [null]
          });
    });

    test('hashes to same value for same contents', () {
      var multimap1 = BuiltListMultimap<int, String>({
        1: ['1'],
        2: ['2', '2'],
        3: ['3']
      });
      var multimap2 = BuiltListMultimap<int, String>({
        1: ['1'],
        2: ['2', '2'],
        3: ['3']
      });

      expect(multimap1.hashCode, multimap2.hashCode);
    });

    test('hashes to different value for different keys', () {
      var multimap1 = BuiltListMultimap<int, String>({
        1: ['1'],
        2: ['2', '2'],
        3: ['3']
      });
      var multimap2 = BuiltListMultimap<int, String>({
        1: ['1'],
        2: ['2', '2'],
        4: ['3']
      });

      expect(multimap1.hashCode, isNot(multimap2.hashCode));
    });

    test('hashes to different value for different values', () {
      var multimap1 = BuiltListMultimap<int, String>({
        1: ['1'],
        2: ['2', '2'],
        3: ['3']
      });
      var multimap2 = BuiltListMultimap<int, String>({
        1: ['1'],
        2: ['2', '3'],
        3: ['3']
      });

      expect(multimap1.hashCode, isNot(multimap2.hashCode));
    });

    test('caches hash', () {
      var hashCodeSpy = HashCodeSpy();
      var multimap = BuiltListMultimap<Object, Object>({
        1: [hashCodeSpy]
      });

      hashCodeSpy.hashCodeSeen = 0;
      multimap.hashCode;
      multimap.hashCode;
      expect(hashCodeSpy.hashCodeSeen, 1);
    });

    test('compares equal to same instance', () {
      var multimap = BuiltListMultimap<int, String>({
        1: ['1'],
        2: ['2', '2'],
        3: ['3']
      });

      expect(multimap == multimap, isTrue);
    });

    test('compares equal to same contents', () {
      var multimap1 = BuiltListMultimap<int, String>({
        1: ['1'],
        2: ['2', '2'],
        3: ['3']
      });
      var multimap2 = BuiltListMultimap<int, String>({
        1: ['1'],
        2: ['2', '2'],
        3: ['3']
      });

      expect(multimap1 == multimap2, isTrue);
    });

    test('compares not equal to different type', () {
      expect(
          // ignore: unrelated_type_equality_checks
          BuiltListMultimap<int, String>({
                1: ['1'],
                2: ['2'],
                3: ['3']
              }) ==
              '',
          isFalse);
    });

    test('compares not equal to different length BuiltListMultimap', () {
      expect(
          BuiltListMultimap<int, String>({
                1: ['1'],
                2: ['2'],
                3: ['3']
              }) ==
              BuiltListMultimap<int, String>({
                1: ['1'],
                2: ['2']
              }),
          isFalse);
    });

    test('compares not equal to different hashcode BuiltListMultimap', () {
      expect(
          BuiltCollectionTestHelpers.overridenHashcodeBuiltListMultimap({
                1: ['1'],
                2: ['2'],
                3: ['3']
              }, 0) ==
              BuiltCollectionTestHelpers.overridenHashcodeBuiltListMultimap({
                1: ['1'],
                2: ['2'],
                3: ['3']
              }, 1),
          isFalse);
    });

    test('compares not equal to different content BuiltListMultimap', () {
      expect(
          BuiltCollectionTestHelpers.overridenHashcodeBuiltListMultimap({
                1: ['1'],
                2: ['2'],
                3: ['3']
              }, 0) ==
              BuiltCollectionTestHelpers.overridenHashcodeBuiltListMultimap({
                1: ['1'],
                2: ['2'],
                3: ['3', '4']
              }, 0),
          isFalse);
    });

    test('compares without throwing for same hashcode different key type', () {
      expect(
          // ignore: unrelated_type_equality_checks
          BuiltCollectionTestHelpers.overridenHashcodeBuiltListMultimap({
                1: ['1']
              }, 0) ==
              BuiltCollectionTestHelpers
                  .overridenHashcodeBuiltListMultimapWithStringKeys({
                '1': ['1']
              }, 0),
          false);
    });

    test('provides toString() for debugging', () {
      expect(
          BuiltListMultimap<int, String>({
            1: ['1'],
            2: ['2'],
            3: ['3']
          }).toString(),
          '{1: [1], 2: [2], 3: [3]}');
    });

    test('preserves key order', () {
      expect(
          BuiltListMultimap<int, String>({
            1: ['1'],
            2: ['2'],
            3: ['3']
          }).keys,
          [1, 2, 3]);
      expect(
          BuiltListMultimap<int, String>({
            3: ['3'],
            2: ['2'],
            1: ['1']
          }).keys,
          [3, 2, 1]);
    });

    // Lazy copies.

    test('reuses BuiltListMultimap instances of the same type', () {
      var multimap1 = BuiltListMultimap<int, String>();
      var multimap2 = BuiltListMultimap<int, String>(multimap1);
      expect(multimap1, same(multimap2));
    });

    test('does not reuse BuiltListMultimap instances with subtype key type',
        () {
      var multimap1 = BuiltListMultimap<_ExtendsA, String>();
      var multimap2 = BuiltListMultimap<_A, String>(multimap1);
      expect(multimap1, isNot(same(multimap2)));
    });

    test(
        'does not reuse BuiltListMultimultimap instances with subtype value type',
        () {
      var multimap1 = BuiltListMultimap<String, _ExtendsA>();
      var multimap2 = BuiltListMultimap<String, _A>(multimap1);
      expect(multimap1, isNot(same(multimap2)));
    });

    test('can be reused via ListMultimapBuilder if there are no changes', () {
      var multimap1 = BuiltListMultimap<Object, Object>();
      var multimap2 = multimap1.toBuilder().build();
      expect(multimap1, same(multimap2));
    });

    test('converts to ListMultimapBuilder from correct type without copying',
        () {
      var makeLongListMultimap = () {
        var result = ListMultimapBuilder<int, int>();
        for (var i = 0; i != 100000; ++i) {
          result.add(i, i);
        }
        return result.build();
      };
      var longListMultimap = makeLongListMultimap();
      var longListMultimapToListMultimapBuilder = longListMultimap.toBuilder;

      expectMuchFaster(
          longListMultimapToListMultimapBuilder, makeLongListMultimap);
    });

    test('converts to ListMultimapBuilder from wrong type by copying', () {
      var makeLongListMultimap = () {
        var result = ListMultimapBuilder<Object, Object>();
        for (var i = 0; i != 100000; ++i) {
          result.add(i, i);
        }
        return result.build();
      };
      var longListMultimap = makeLongListMultimap();
      var longListMultimapToListMultimapBuilder =
          () => ListMultimapBuilder<int, int>(longListMultimap);

      expectNotMuchFaster(
          longListMultimapToListMultimapBuilder, makeLongListMultimap);
    });

    test('has fast toMap', () {
      var makeLongListMultimap = () {
        var result = ListMultimapBuilder<int, int>();
        for (var i = 0; i != 100000; ++i) {
          result.add(i, i);
        }
        return result.build();
      };
      var longListMultimap = makeLongListMultimap();
      var longListMultimapToListMultimap = () => longListMultimap.toMap();

      expectMuchFaster(longListMultimapToListMultimap, makeLongListMultimap);
    });

    test('checks for reference identity', () {
      var makeLongListMultimap = () {
        var result = ListMultimapBuilder<int, int>();
        for (var i = 0; i != 100000; ++i) {
          result.add(i, i);
        }
        return result.build();
      };
      var longListMultimap = makeLongListMultimap();
      var otherLongListMultimap = makeLongListMultimap();

      expectMuchFaster(() => longListMultimap == longListMultimap,
          () => longListMultimap == otherLongListMultimap);
    });

    test('is not mutated when Map from toMap is mutated', () {
      var multimap = BuiltListMultimap<int, String>();
      multimap.toMap()[1] = BuiltList<String>(['1']);
      expect(multimap.isEmpty, isTrue);
    });

    test('has build constructor', () {
      expect(
          BuiltListMultimap<int, String>.build((b) => b.add(0, '0')).toMap(), {
        0: ['0']
      });
    });

    test('has rebuild method', () {
      expect(
          BuiltListMultimap<int, String>({
            0: ['0']
          }).rebuild((b) => b.add(1, '1')).toMap(),
          {
            0: ['0'],
            1: ['1']
          });
    });

    // ListMultimap.

    test('has a method like ListMultimap[]', () {
      expect(
          BuiltListMultimap<int, String>({
            1: ['1'],
            2: ['2'],
            3: ['3']
          })[2],
          ['2']);
      expect(
          BuiltListMultimap<int, String>({
            1: ['1'],
            2: ['2'],
            3: ['3']
          })[4],
          []);
    });

    test('returns stable empty BuiltLists', () {
      var multimap = BuiltListMultimap<int, String>();
      expect(multimap[1], same(multimap[1]));
      expect(multimap[1], same(multimap[2]));
    });

    test('has a method like ListMultimap.length', () {
      expect(
          BuiltListMultimap<int, String>({
            1: ['1'],
            2: ['2'],
            3: ['3']
          }).length,
          3);
    });

    test('has a method like ListMultimap.containsKey', () {
      expect(
          BuiltListMultimap<int, String>({
            1: ['1'],
            2: ['2'],
            3: ['3']
          }).containsKey(3),
          isTrue);
      expect(
          BuiltListMultimap<int, String>({
            1: ['1'],
            2: ['2'],
            3: ['3']
          }).containsKey(4),
          isFalse);
    });

    test('has a method like ListMultimap.containsValue', () {
      expect(
          BuiltListMultimap<int, String>({
            1: ['1'],
            2: ['2'],
            3: ['3']
          }).containsValue('3'),
          isTrue);
      expect(
          BuiltListMultimap<int, String>({
            1: ['1'],
            2: ['2'],
            3: ['3']
          }).containsValue('4'),
          isFalse);
    });

    test('has a method like ListMultimap.forEach', () {
      var totalKeys = 0;
      var concatenatedValues = '';
      BuiltListMultimap<int, String>({
        1: ['1'],
        2: ['2'],
        3: ['3', '4']
      }).forEach((key, value) {
        totalKeys += key;
        concatenatedValues += value;
      });

      expect(totalKeys, 9);
      expect(concatenatedValues, '1234');
    });

    test('has a method like ListMultimap.forEachKey', () {
      var totalKeys = 0;
      var concatenatedValues = '';
      BuiltListMultimap<int, String>({
        1: ['1'],
        2: ['2'],
        3: ['3', '4']
      }).forEachKey((key, values) {
        totalKeys += key;
        concatenatedValues += values.reduce((x, y) => x + y);
      });

      expect(totalKeys, 6);
      expect(concatenatedValues, '1234');
    });

    test('has a method like ListMultimap.keys', () {
      expect(
          BuiltListMultimap<int, String>({
            1: ['1'],
            2: ['2'],
            3: ['3']
          }).keys,
          [1, 2, 3]);
    });

    test('has a method like ListMultimap.values', () {
      expect(
          BuiltListMultimap<int, String>({
            1: ['1'],
            2: ['2', '2'],
            3: ['3']
          }).values,
          ['1', '2', '2', '3']);
    });

    test('has stable keys', () {
      var multimap = BuiltListMultimap<int, String>({
        1: ['1'],
        2: ['2'],
        3: ['3']
      });
      expect(multimap.keys, same(multimap.keys));
    });

    test('has stable values', () {
      var multimap = BuiltListMultimap<int, String>({
        1: ['1'],
        2: ['2'],
        3: ['3']
      });
      expect(multimap.values, same(multimap.values));
    });
  });
}

class _A {}

class _ExtendsA extends _A {}

// All the methods from `ListMultimap` that we care about, to avoid taking a
// dependency on `quiver`.
class _ListMultimap<K, V> {
  final Map<K, List<V>> _map = {};

  void add(K key, V value) {
    _map[key] ??= [];
    _map[key]!.add(value);
  }

  Iterable<K> get keys => _map.keys;
  Iterable<V> operator [](K key) => _map[key] ?? <V>[];

  void clear() => _map.clear();

  Map<K, List<V>> asMap() => _map;
}
