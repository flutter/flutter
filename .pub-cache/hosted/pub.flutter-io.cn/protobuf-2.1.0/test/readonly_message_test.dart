#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library readonly_message_test;

import 'package:protobuf/protobuf.dart'
    show
        BuilderInfo,
        GeneratedMessage,
        PbFieldType,
        UnknownFieldSetField,
        frozenMessageModificationHandler,
        defaultFrozenMessageModificationHandler;
import 'package:test/test.dart';

Matcher throwsError(Type expectedType, Matcher expectedMessage) =>
    throwsA(predicate((dynamic x) {
      expect(x.runtimeType, expectedType);
      expect(x!.message, expectedMessage);
      return true;
    }));

class Rec extends GeneratedMessage {
  static Rec getDefault() => Rec()..freeze();
  static Rec create() => Rec();
  @override
  Rec createEmptyInstance() => Rec();

  @override
  BuilderInfo info_ = BuilderInfo('rec')
    ..a(1, 'value', PbFieldType.O3)
    ..pc<Rec>(2, 'sub', PbFieldType.PM, subBuilder: Rec.create)
    ..p<int>(10, 'ints', PbFieldType.P3);

  int get value => $_get(0, 0);
  set value(int v) {
    $_setUnsignedInt32(0, v);
  }

  bool hasValue() => $_has(0);

  List<Rec> get sub => $_getList<Rec>(1);

  List<int> get ints => $_getList<int>(2);

  @override
  Rec clone() => Rec()..mergeFromMessage(this);

  @override
  Rec copyWith(void Function(Rec) updates) {
    final builder = toBuilder();
    updates(builder as Rec);
    return builder.freeze() as Rec;
  }
}

void main() {
  test('can write a read-only message', () {
    expect(Rec.getDefault().writeToBuffer(), []);
    expect(Rec.getDefault().writeToJson(), '{}');
  });

  test("can't merge to a read-only message", () {
    expect(
        () => Rec.getDefault().mergeFromJson('{"1":1}'),
        throwsError(UnsupportedError,
            equals('Attempted to change a read-only message (rec)')));
  });

  test("can't set a field on a read-only message", () {
    expect(
        () => Rec.getDefault().setField(1, 456),
        throwsError(UnsupportedError,
            equals('Attempted to change a read-only message (rec)')));
  });

  test('can set a field on a read-only message with a custom read-only handler',
      () {
    try {
      var called = 0;

      frozenMessageModificationHandler =
          (String messageName, [String? methodName]) {
        expect(messageName, 'rec');
        expect(methodName, isNull);
        called++;
      };

      Rec.getDefault().setField(1, 456);
      expect(called, 1);
    } finally {
      frozenMessageModificationHandler =
          defaultFrozenMessageModificationHandler;
    }
  });

  test('eagerly computes hashCode if a custom read-only handler is used', () {
    try {
      final message = Rec.getDefault();
      final initialHashCode = message.hashCode;

      frozenMessageModificationHandler =
          (String messageName, [String? methodName]) {};
      message.setField(1, 456);
      final modifiedHashCode = message.hashCode;
      expect(initialHashCode == modifiedHashCode, isFalse);
    } finally {
      frozenMessageModificationHandler =
          defaultFrozenMessageModificationHandler;
    }
  });

  test("can't clear a read-only message", () {
    expect(
        () => Rec.getDefault().clear(),
        throwsError(UnsupportedError,
            equals('Attempted to change a read-only message (rec)')));
  });

  test("can't clear a field on a read-only message", () {
    expect(
        () => Rec.getDefault().clearField(1),
        throwsError(UnsupportedError,
            equals('Attempted to change a read-only message (rec)')));
  });

  test("can't modify repeated fields on a read-only message", () {
    expect(() => Rec.getDefault().sub.add(Rec.create()),
        throwsError(UnsupportedError, contains('add')));
    var r = Rec.create()
      ..ints.add(10)
      ..freeze();
    expect(
        () => r.ints.clear(),
        throwsError(UnsupportedError,
            equals('Cannot call clear on an unmodifiable list')));
    expect(
        () => r.ints[0] = 2,
        throwsError(UnsupportedError,
            equals('Cannot call set on an unmodifiable list')));
    expect(() => r.sub.add(Rec.create()),
        throwsError(UnsupportedError, contains('add')));

    r = Rec.create()
      ..sub.add(Rec.create())
      ..freeze();
    expect(
        () => r.sub.add(Rec.create()),
        throwsError(UnsupportedError,
            equals('Cannot call add on an unmodifiable list')));
    expect(() => r.ints.length = 20,
        throwsError(UnsupportedError, contains('length')));
  });

  test("can't modify sub-messages on a read-only message", () {
    var subMessage = Rec.create()..value = 1;
    var r = Rec.create()
      ..sub.add(Rec.create()..sub.add(subMessage))
      ..freeze();
    expect(r.sub[0].sub[0].value, 1);
    expect(
        () => subMessage.value = 2,
        throwsError(UnsupportedError,
            equals('Attempted to change a read-only message (rec)')));
  });

  test("can't modify unknown fields on a read-only message", () {
    expect(
        () => Rec.getDefault().unknownFields.clear(),
        throwsError(
            UnsupportedError,
            equals(
                'Attempted to call clear on a read-only message (UnknownFieldSet)')));
  });

  test('can rebuild a frozen message with merge', () {
    final orig = Rec.create()
      ..value = 10
      ..freeze();
    final rebuilt = orig.copyWith((m) => m.mergeFromJson('{"1": 7}'));
    expect(identical(orig, rebuilt), false);
    expect(orig.value, 10);
    expect(rebuilt.value, 7);
  });

  test('can set a field while rebuilding a frozen message', () {
    final orig = Rec.create()
      ..value = 10
      ..freeze();
    final rebuilt = orig.copyWith((m) => m.value = 7);
    expect(identical(orig, rebuilt), false);
    expect(orig.value, 10);
    expect(rebuilt.value, 7);
  });

  test('can clear while rebuilding a frozen message', () {
    final orig = Rec.create()
      ..value = 10
      ..freeze();
    final rebuilt = orig.copyWith((m) => m.clear());
    expect(identical(orig, rebuilt), false);
    expect(orig.value, 10);
    expect(orig.hasValue(), true);
    expect(rebuilt.hasValue(), false);
  });

  test('can clear a field while rebuilding a frozen message', () {
    final orig = Rec.create()
      ..value = 10
      ..freeze();
    final rebuilt = orig.copyWith((m) => m.clearField(1));
    expect(identical(orig, rebuilt), false);
    expect(orig.value, 10);
    expect(orig.hasValue(), true);
    expect(rebuilt.hasValue(), false);
  });

  test('can modify repeated fields while rebuilding a frozen message', () {
    var orig = Rec.create()
      ..ints.add(10)
      ..freeze();
    var rebuilt = orig.copyWith((m) => m.ints.add(12));
    expect(identical(orig, rebuilt), false);
    expect(orig.ints, [10]);
    expect(rebuilt.ints, [10, 12]);

    rebuilt = orig.copyWith((m) => m.ints.clear());
    expect(orig.ints, [10]);
    expect(rebuilt.ints, []);

    rebuilt = orig.copyWith((m) => m.ints[0] = 2);
    expect(orig.ints, [10]);
    expect(rebuilt.ints, [2]);

    orig = Rec.create()
      ..sub.add(Rec.create())
      ..freeze();
    rebuilt = orig.copyWith((m) => m.sub.add(Rec.create()));
    expect(orig.sub.length, 1);
    expect(rebuilt.sub.length, 2);
  });

  test('cannot modify sub-messages while rebuilding a frozen message', () {
    final subMessage = Rec.create()..value = 1;
    final orig = Rec.create()
      ..sub.add(Rec.create()..sub.add(subMessage))
      ..freeze();

    final rebuilt = orig.copyWith((m) {
      expect(
          () => subMessage.value = 5,
          throwsError(UnsupportedError,
              equals('Attempted to change a read-only message (rec)')));
      expect(
          () => m.sub[0].sub[0].value = 2,
          throwsError(UnsupportedError,
              equals('Attempted to change a read-only message (rec)')));
      m.sub[0] = m.sub[0].copyWith(
          (m2) => m2.sub[0] = m2.sub[0].copyWith((m3) => m3.value = 2));
    });
    expect(identical(subMessage, orig.sub[0].sub[0]), true);
    expect(identical(subMessage, rebuilt.sub[0].sub[0]), false);
    expect(orig.sub[0].sub[0].value, 1);
    expect(rebuilt.sub[0].sub[0].value, 2);
  });

  test('can modify unknown fields while rebuilding a frozen message', () {
    final orig = Rec.create()
      ..unknownFields.addField(20, UnknownFieldSetField()..fixed32s.add(1));
    final rebuilt = orig.copyWith((m) => m.unknownFields.clear());
    expect(orig.unknownFields.hasField(20), true);
    expect(rebuilt.unknownFields.hasField(20), false);
  });
}
