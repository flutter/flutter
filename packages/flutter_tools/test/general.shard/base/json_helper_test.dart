// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/json_helper.dart';

import '../../src/common.dart';

void main() {
  group('JsonHelper', () {
    test('can decode nested maps', () {
      const String str = '{"a":{"b":1}}';
      expect(JsonHelper.fromJson(str)['a']['b'].asInt, equals(1));
    });
    test('can decode nested arrays', () {
      const String str = '[1, [2,3, [4,5]]]';
      expect(JsonHelper.fromJson(str)[1][2][1].asInt, equals(5));
    });
    test('can decode nested arrays and maps', (){
      expect(JsonHelper.fromJson('{"a":[1,2,{"b":"c"}]}')['a'][2]['b'].asString, equals('c'));
    });
    test('can decode json double', () {
      final JsonHelper helper = JsonHelper.fromJson('0.1');
      expect(helper.asDouble, equals(0.1));
      expect(() => helper.asInt, throwsA(isA<TypeError>()));
    });
    test('can decode json int', () {
      final JsonHelper helper = JsonHelper.fromJson('1');
      expect(helper.asInt, equals(1));
      expect(() => helper.asDouble, throwsA(isA<TypeError>()));
    });
    test('can decode json num', () {
      final JsonHelper helper = JsonHelper.fromJson('1.1111');
      expect(helper.asNum, equals(1.1111));
    });
    test('can decode json string', () {
      final JsonHelper helper = JsonHelper.fromJson('"str"');
      expect(helper.asString, equals('str'));
    });
    test('can decode json bool', () {
      final JsonHelper helper = JsonHelper.fromJson('true');
      expect(helper.asBool, equals(true));
    });
    test('can decode json array', () {
      final JsonHelper helper = JsonHelper.fromJson('[{},{},123]');
      expect(helper.asList, isA<List<dynamic>>());
    });
    test('can decode json object', () {
      final JsonHelper helper = JsonHelper.fromJson('{"123":{},"abc":{}}');
      expect(helper.asMap, isA<Map<String,dynamic>>());
    });
  });
}
