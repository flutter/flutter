#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart'
    show test, expect, predicate, same, throwsA, throwsArgumentError, isA;

import '../out/protos/map_api.pb.dart' as pb;
import '../out/protos/map_api2.pb.dart' as pb2;

void main() {
  test("message doesn't implement Map when turned off", () {
    expect(pb.NonMap(), predicate((x) => x is! Map));
    expect(pb2.NonMap2(), predicate((x) => x is! Map));
  });

  test('message implements Map when turned on', () {
    expect(pb.Rec(), predicate((x) => x is Map));
    expect(pb2.Rec2(), predicate((x) => x is Map));
  });

  test('operator [] returns null for unrecognized keys', () {
    var rec = pb.Rec();
    expect(rec['noSuchField'], null);
    expect(rec[1234], null);
    expect(rec[null], null);
  });

  test('operator [] returns default value when not set', () {
    var rec = pb.Rec();
    expect(rec['num'], 0);
    expect(rec['nums'], []);
    expect(rec['str'], '');
    expect(rec['msg'], predicate((x) => x is pb.NonMap));
  });

  test('operator [] returns new value when set', () {
    var rec = pb.Rec();
    rec.num = 42;
    expect(rec['num'], 42);
    rec.nums.add(123);
    expect(rec['nums'], [123]);
    rec.str = 'hello';
    expect(rec['str'], 'hello');
    var msg = pb.NonMap();
    rec.msg = msg;
    expect(rec['msg'], same(msg));
  });

  test('operator []= throws exception for invalid key', () {
    var rec = pb.Rec();
    expect(() {
      rec['unknown'] = 123;
    },
        throwsA(isA<ArgumentError>().having((p0) => p0.message, 'message',
            "field 'unknown' not found in protobuf_unittest.Rec")));
  });

  test('operator []= throws exception for repeated field', () {
    // Copying the values would be confusing.
    var rec = pb.Rec();
    expect(() {
      rec['nums'] = [1, 2];
    }, throwsArgumentError);
  });

  test('operator []= throws exception for invalid value type', () {
    var rec = pb.Rec();
    expect(() {
      rec['num'] = 'hello';
    }, throwsArgumentError);
    expect(() {
      rec['str'] = 123;
    }, throwsArgumentError);
  });

  test('operator []= sets the field', () {
    var rec = pb.Rec();
    rec['num'] = 123;
    expect(rec.num, 123);
    rec['str'] = 'hello';
    expect(rec.str, 'hello');
  });

  test('keys returns each field name (even when unset)', () {
    var rec = pb.Rec();
    expect(Set.from(rec.keys), {'msg', 'num', 'nums', 'str'});
  });

  test('containsKey returns true for fields that exist (even when unset)', () {
    var rec = pb.Rec();
    expect(rec.containsKey('unknown'), false);
    expect(rec.containsKey('str'), true);
    expect(rec.containsKey('num'), true);
    expect(rec.containsKey('nums'), true);
    expect(rec.containsKey('msg'), true);
  });

  test('length is constant', () {
    var rec = pb.Rec();
    expect(rec.length, 4);
    rec.str = 'hello';
    expect(rec.length, 4);
  });

  test("remove isn't supported", () {
    var rec = pb.Rec();
    rec.str = 'hello';
    expect(() {
      rec.remove('str');
    },
        throwsA(isA<UnsupportedError>().having((p0) => p0.message, 'message',
            'remove() not supported by protobuf_unittest.Rec')));
    expect(rec.str, 'hello');
  });

  test('clear sets each field to its default value (unlike a regular Map)', () {
    // We have little choice here since the clear() method already existed.
    var rec = pb.Rec();
    rec.str = 'hello';
    rec.num = 123;
    rec.nums.add(456);
    rec.clear();
    expect(rec.length, 4);
    expect(rec['str'], '');
    expect(rec['num'], 0);
    expect(rec['nums'], []);
  });

  test('addAll sets each field to a new value', () {
    var rec = pb.Rec();
    rec.addAll({'str': 'hello', 'num': 123});
    expect(rec['str'], 'hello');
    expect(rec['num'], 123);
  });

  test("addAll doesn't work for repeated fields", () {
    // It would be confusing to copy the values.
    var rec = pb.Rec();
    expect(() {
      rec.addAll({
        'nums': [1, 2, 3]
      });
    }, throwsArgumentError);
  });
}
