// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/json_helper.dart';

import '../../src/common.dart';

void main() {
  group('JsonHelper', () {
    group('can decode', () {
      test('nested maps', () {
        const String str = '{"a":{"b":1}}';
        expect(JsonHelper.fromJson(str)['a']['b'].asInt, equals(1));
      });
      test('nested arrays', () {
        const String str = '[1, [2,3, [4,5]]]';
        expect(JsonHelper.fromJson(str)[1][2][1].asInt, equals(5));
      });
      test('nested arrays and maps', () {
        expect(
          JsonHelper.fromJson('{"a":[1,2,{"b":"c"}]}')['a'][2]['b'].asString,
          equals('c'),
        );
      });
      test('json double', () {
        final JsonHelper helper = JsonHelper.fromJson('0.1');
        expect(helper.asDouble, equals(0.1));
        expect(() => helper.asInt, throwsA(isA<TypeError>()));
      });
      test('json int', () {
        final JsonHelper helper = JsonHelper.fromJson('1');
        expect(helper.asInt, equals(1));
        expect(() => helper.asDouble, throwsA(isA<TypeError>()));
      });
      test('json num', () {
        final JsonHelper helper = JsonHelper.fromJson('1.1111');
        expect(helper.asNum, equals(1.1111));
      });
      test('json string', () {
        final JsonHelper helper = JsonHelper.fromJson('"str"');
        expect(helper.asString, equals('str'));
      });
      test('json bool', () {
        final JsonHelper helper = JsonHelper.fromJson('true');
        expect(helper.asBool, equals(true));
      });
      test('json array', () {
        final JsonHelper helper = JsonHelper.fromJson('[{},{},123]');
        expect(helper.asList, isA<List<dynamic>>());
      });
      test('json object', () {
        final JsonHelper helper = JsonHelper.fromJson('{"123":{},"abc":{}}');
        expect(helper.asMap, isA<Map<String, dynamic>>());
      });
    });
    group('can filter', () {
      test('by list element', () {
        final JsonHelper helper =
            JsonHelper.fromJson('[1,0.1,3,4,"abc","def"]');
        expect(
          helper.filterList((dynamic p) => (p as int).isOdd).asList,
          equals(<dynamic>[1, 3]),
        );
      });
      test('by map entry', () {
        final JsonHelper helper =
            JsonHelper.fromJson('{"k1":"abc","a2":23,"k3":123}');
        expect(
          helper
              .filterMap((MapEntry<String, dynamic> p) =>
                  p.key.contains('k') && (p.value as int) > 100)
              .asMap,
          equals(<String, dynamic>{'k3': 123}),
        );
      });
      test('by list index', () {
        final JsonHelper helper =
            JsonHelper.fromJson('[1,0.1,3,4,"abc","def"]');
        expect(
          helper.filterByIndex((int i) => i < 2).asList,
          equals(<dynamic>[1, 0.1]),
        );
      });
      test('by map key', () {
        final JsonHelper helper =
            JsonHelper.fromJson('{"k1":"abc","a2":123,"k3":123}');
        expect(
          helper
              .filterByKey(
                (String k) => k.contains('k'),
              )
              .asMap,
          equals(<String, dynamic>{'k3': 123, 'k1': 'abc'}),
        );
      });
    });
  });
}
