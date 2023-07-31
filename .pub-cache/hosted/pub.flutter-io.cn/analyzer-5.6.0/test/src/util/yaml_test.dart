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

Object merge(Object o1, Object o2) =>
    merger.merge(wrap(o1), wrap(o2)).valueOrThrow;

YamlNode wrap(Object? value) {
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

class _FileSpanMock implements FileSpan {
  static final FileSpan instance = _FileSpanMock();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
