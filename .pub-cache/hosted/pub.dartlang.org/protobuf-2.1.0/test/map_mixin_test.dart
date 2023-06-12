#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Unit tests for PbMapMixin.
// There are more tests in the dart-protoc-plugin package.
library map_mixin_test;

import 'dart:collection' show MapMixin;

import 'package:protobuf/protobuf.dart';
import 'package:protobuf/src/protobuf/mixins/map_mixin.dart';
import 'package:test/test.dart' show expect, same, test, throwsArgumentError;

import 'mock_util.dart' show MockMessage, mockInfo;

// A minimal protobuf implementation compatible with PbMapMixin.
class Rec extends MockMessage with MapMixin, PbMapMixin {
  @override
  BuilderInfo get info_ => _info;
  static final _info = mockInfo('Rec', () => Rec());
  @override
  Rec createEmptyInstance() => Rec();

  @override
  String toString() => 'Rec($val, "$str")';
}

void main() {
  test('PbMapMixin methods return default field values', () {
    var r = Rec();

    expect(r.isEmpty, false);
    expect(r.isNotEmpty, true);
    expect(r.keys, ['val', 'str', 'child', 'int32s', 'int64', 'enm']);

    expect(r['val'], 42);
    expect(r['str'], '');
    expect(r['child'].runtimeType, Rec);
    expect(r['child'].toString(), 'Rec(42, "")');
    expect(r['int32s'], []);

    var v = r.values;
    expect(v.length, 6);
    expect(v.first, 42);
    expect(v.toList()[1], '');
    expect(v.toList()[3].toString(), '[]');
    expect(v.toList()[4], 0);
    expect(v.toList()[5].name, 'a');
  });

  test('operator []= sets record fields', () {
    var r = Rec();

    r['val'] = 123;
    expect(r.val, 123);
    expect(r['val'], 123);

    r['str'] = 'hello';
    expect(r.str, 'hello');
    expect(r['str'], 'hello');

    var child = Rec();
    r['child'] = child;
    expect(r.child, same(child));
    expect(r['child'], same(child));

    expect(() => r['int32s'] = 123, throwsArgumentError);
    r['int32s'].add(123);
    expect(r['int32s'], [123]);
    expect(r['int32s'], same(r['int32s']));
  });

  test('operator== and hashCode work for Map mixin', () {
    var a = Rec();
    expect(a == a, true);
    expect(a == {}, false);
    expect({} == a, false);

    var b = Rec();
    expect(a.info_ == b.info_, true, reason: 'BuilderInfo should be the same');
    expect(a == b, true);
    expect(a.hashCode, b.hashCode);

    a.val = 123;
    expect(a == b, false);
    b.val = 123;
    expect(a == b, true);
    expect(a.hashCode, b.hashCode);

    a.child = Rec();
    expect(a == b, false);
    b.child = Rec();
    expect(a == b, true);
    expect(a.hashCode, b.hashCode);
  });

  test("protobuf doesn't compare equal to a map with the same values", () {
    var a = Rec();
    expect(a == Map.from(a), false);
    expect(Map.from(a) == a, false);
  });

  test("reading protobuf values shouldn't change equality", () {
    var a = Rec();
    var b = Rec();
    expect(a == b, true);
    Map.from(a);
    expect(a == b, true);
  });
}
