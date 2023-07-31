#!/usr/bin/env dart
// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'package:test/test.dart';

import '../out/protos/foo.pb.dart';
import '../out/protos/map_field.pb.dart' as map;

Future<T> sendReceive<T>(T object) async {
  final rp = ReceivePort();
  rp.sendPort.send(object);
  return (await rp.first) as T;
}

Future main() async {
  test('Normal proto can be transferred via ports', () async {
    final object = Outer()
      ..inner = (Inner()..value = 'pip')
      ..inners.add(Inner()..value = 'pop');

    final clone = await sendReceive(object);

    // Ensure the clone is actually containing the same data.
    expect(clone, equals(object));
    expect(clone.toString(), equals(object.toString()));
    expect(clone.toDebugString(), equals(object.toDebugString()));
    expect(clone.writeToBuffer(), equals(object.writeToBuffer()));

    // Ensure the actual objects got transitively cloned, but the metadata in
    // the `_info_` did not get cloned.
    expect(!identical(object, clone), true);
    expect(!identical(object.inner, clone.inner), true);
    expect(identical(object.info_, clone.info_), true);
  }, onPlatform: {'js': Skip('dart:isolate only works on Dart VM')});

  test('Map-using proto can be transferred via ports', () async {
    final object = map.TestMap()
      ..int32ToMessageField[42] = (map.TestMap_MessageValue()
        ..value = 1
        ..secondValue = 2);

    final clone = await sendReceive(object);

    // Ensure the clone is actually containing the same data.
    expect(clone, equals(object));
    expect(clone.toString(), equals(object.toString()));
    expect(clone.toDebugString(), equals(object.toDebugString()));
    expect(clone.writeToBuffer(), equals(object.writeToBuffer()));

    // Ensure the actual objects got transitively cloned, but the metadata in
    // the `_info_` did not get cloned.
    expect(!identical(object, clone), true);
    expect(identical(object.info_, clone.info_), true);
  }, onPlatform: {'js': Skip('dart:isolate only works on Dart VM')});
}
