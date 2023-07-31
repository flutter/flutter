// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/yaml.dart';
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';
import 'package:yaml/src/event.dart';
import 'package:yaml/yaml.dart';

main() {
  group('yaml', () {
    group('merge', () {
      test('map', () {
        expect(
            merge({
              'one': true,
              'two': false,
              'three': {
                'nested': {'four': true, 'six': true}
              }
            }, {
              'three': {
                'nested': {'four': false, 'five': true},
                'five': true
              },
              'seven': true
            }),
            equals(wrap({
              'one': true,
              'two': false,
              'three': {
                'nested': {'four': false, 'five': true, 'six': true},
                'five': true
              },
              'seven': true
            })));
      });

      test('list', () {
        expect(merge([1, 2, 3], [2, 3, 4, 5]), equals(wrap([1, 2, 3, 4, 5])));
      });

      test('list w/ promotion', () {
        expect(
            merge(['one', 'two', 'three'], {'three': false, 'four': true}),
            equals(wrap(
                {'one': true, 'two': true, 'three': false, 'four': true})));
        expect(merge({'one': false, 'two': false}, ['one', 'three']),
            equals(wrap({'one': true, 'two': false, 'three': true})));
      });

      test('map w/ list promotion', () {
        var map1 = {
          'one': ['a', 'b', 'c']
        };
        var map2 = {
          'one': {'a': true, 'b': false}
        };
        var map3 = {
          'one': {'a': true, 'b': false, 'c': true}
        };
        expect(merge(map1, map2), wrap(map3));
      });

      test('map w/ no promotion', () {
        var map1 = {
          'one': ['a', 'b', 'c']
        };
        var map2 = {
          'one': {'a': 'foo', 'b': 'bar'}
        };
        var map3 = {
          'one': {'a': 'foo', 'b': 'bar'}
        };
        expect(merge(map1, map2), wrap(map3));
      });

      test('map w/ no promotion (2)', () {
        var map1 = {
          'one': {'a': 'foo', 'b': 'bar'}
        };
        var map2 = {
          'one': ['a', 'b', 'c']
        };
        var map3 = {
          'one': ['a', 'b', 'c']
        };
        expect(merge(map1, map2), wrap(map3));
      });

      test('object', () {
        expect(merge(1, 2), 2);
        expect(merge(1, 'foo'), 'foo');
        expect(merge({'foo': 1}, 'foo'), 'foo');
      });
    });
  });
}

final Merger merger = Merger();

bool containsKey(Map<dynamic, YamlNode> map, dynamic key) =>
    _getValue(map, key) != null;

void expectEquals(YamlNode? actual, YamlNode? expected) {
  if (expected is YamlScalar) {
    actual!;
    expect(actual, TypeMatcher<YamlScalar>());
    expect(expected.value, actual.value);
  } else if (expected is YamlList) {
    if (actual is YamlList) {
      expect(actual.length, expected.length);
      List<YamlNode> expectedNodes = expected.nodes;
      List<YamlNode> actualNodes = actual.nodes;
      for (int i = 0; i < expectedNodes.length; i++) {
        expectEquals(actualNodes[i], expectedNodes[i]);
      }
    } else {
      fail('Expected a YamlList, found ${actual.runtimeType}');
    }
  } else if (expected is YamlMap) {
    if (actual is YamlMap) {
      expect(actual.length, expected.length);
      Map<dynamic, YamlNode> expectedNodes = expected.nodes;
      Map<dynamic, YamlNode> actualNodes = actual.nodes;
      for (var expectedKey in expectedNodes.keys) {
        if (!containsKey(actualNodes, expectedKey)) {
          fail('Missing key $expectedKey');
        }
      }
      for (var actualKey in actualNodes.keys) {
        if (!containsKey(expectedNodes, actualKey)) {
          fail('Extra key $actualKey');
        }
      }
      for (var expectedKey in expectedNodes.keys) {
        expectEquals(_getValue(actualNodes, expectedKey),
            _getValue(expectedNodes, expectedKey));
      }
    } else {
      fail('Expected a YamlMap, found ${actual.runtimeType}');
    }
  } else {
    fail('Unknown type of node: ${expected.runtimeType}');
  }
}

Object merge(Object o1, Object o2) => merger.merge(wrap(o1), wrap(o2)).value;

Object valueOf(Object object) => object is YamlNode ? object.value : object;

YamlNode wrap(Object value) {
  if (value is List) {
    var wrappedElements = value.map((e) => wrap(e)).toList();
    return YamlList.internal(
        wrappedElements, _FileSpanMock.instance, CollectionStyle.BLOCK);
  } else if (value is Map) {
    Map<dynamic, YamlNode> wrappedEntries = <dynamic, YamlNode>{};
    value.forEach((k, v) {
      wrappedEntries[wrap(k)] = wrap(v);
    });
    return YamlMap.internal(
        wrappedEntries, _FileSpanMock.instance, CollectionStyle.BLOCK);
  } else {
    return YamlScalar.internal(
        value, ScalarEvent(_FileSpanMock.instance, '', ScalarStyle.PLAIN));
  }
}

YamlNode? _getValue(Map map, Object key) {
  Object keyValue = valueOf(key);
  for (var existingKey in map.keys) {
    if (valueOf(existingKey) == keyValue) {
      return map[existingKey];
    }
  }
  return null;
}

class _FileSpanMock implements FileSpan {
  static final FileSpan instance = _FileSpanMock();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
