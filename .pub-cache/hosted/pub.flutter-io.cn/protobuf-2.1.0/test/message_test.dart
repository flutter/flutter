// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests for GeneratedMessage methods.
library message_test;

import 'package:matcher/src/interfaces.dart';
import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart' show test, expect, predicate, throwsA;

import 'mock_util.dart' show MockMessage, mockInfo;

class Rec extends MockMessage {
  @override
  BuilderInfo get info_ => _info;
  static final _info = mockInfo('Rec', () => Rec());
  @override
  Rec createEmptyInstance() => Rec();
}

Matcher throwsError(Type expectedType, String expectedMessage) =>
    throwsA(predicate((dynamic x) {
      expect(x.runtimeType, expectedType);
      expect(x!.message, expectedMessage);
      return true;
    }));

void main() {
  test('getField with invalid tag throws exception', () {
    var r = Rec();
    expect(() {
      r.getField(123);
    }, throwsError(ArgumentError, 'tag 123 not defined in Rec'));
  });

  test('getDefaultForField with invalid tag throws exception', () {
    var r = Rec();
    expect(() {
      r.getDefaultForField(123);
    }, throwsError(ArgumentError, 'tag 123 not defined in Rec'));
  });

  test('operator== and hashCode works for frozen message', () {
    final a = Rec()
      ..val = 123
      ..int32s.addAll([1, 2, 3])
      ..freeze();
    final b = Rec()
      ..val = 123
      ..int32s.addAll([1, 2, 3]);

    expect(a.hashCode, b.hashCode);
    expect(a == b, true);
    expect(b == a, true);
  });

  test('isFrozen works', () {
    final a = Rec()
      ..val = 123
      ..int32s.addAll([1, 2, 3])
      ..child = (Rec()..val = 100);
    expect(a.isFrozen, false);
    a.child.freeze();
    expect(a.child.isFrozen, true);
    expect(a.isFrozen, false);
    a.freeze();
    expect(a.isFrozen, true);
  });

  test('operator== and hashCode work for a simple record', () {
    var a = Rec();
    expect(a == a, true);

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
}
