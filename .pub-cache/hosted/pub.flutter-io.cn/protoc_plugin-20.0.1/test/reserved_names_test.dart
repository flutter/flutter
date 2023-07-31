#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library reserved_names_test;

import 'dart:collection' show MapMixin;
import 'dart:mirrors';

import 'package:protobuf/meta.dart'
    show GeneratedMessage_reservedNames, ProtobufEnum_reservedNames;
// Import the libraries we will access via the mirrors.
// ignore_for_file: unused_import
import 'package:protobuf/protobuf.dart' show GeneratedMessage, ProtobufEnum;
import 'package:protobuf/src/protobuf/mixins/event_mixin.dart'
    show PbEventMixin;
import 'package:protobuf/src/protobuf/mixins/map_mixin.dart' show PbMapMixin;
import 'package:protoc_plugin/mixins.dart' show findMixin;
import 'package:test/test.dart';

import 'mirror_util.dart' show findMemberNames;

// These names are no longer reserved but we keep them in
// `GeneratedMessage_reservedNames` to keep generated code backwards
// compatible. Remove in next major release.
const List<String> oldGeneratedMessageReservedNames = [
  'fromBuffer',
  'fromJson',
  r'$_defaultFor',
];

// These names are no longer reserved but we keep them in
// `ProtobufEnum_reservedNames` to keep generated code backwards compatible.
// Remove in next major release.
const List<String> oldProtobufEnumReservedNames = ['initByValue'];

void main() {
  test('GeneratedMessage reserved names are up to date', () {
    var actual = Set<String>.from(GeneratedMessage_reservedNames);
    var expected =
        findMemberNames('package:protobuf/protobuf.dart', #GeneratedMessage)
          ..addAll(oldGeneratedMessageReservedNames);

    expect(actual.toList()..sort(), equals(expected.toList()..sort()));
  });

  test('ProtobufEnum reserved names are up to date', () {
    var actual = Set<String>.from(ProtobufEnum_reservedNames);
    var expected =
        findMemberNames('package:protobuf/protobuf.dart', #ProtobufEnum)
          ..addAll(oldProtobufEnumReservedNames);

    expect(actual.toList()..sort(), equals(expected.toList()..sort()));
  });

  test("ReadonlyMessageMixin doesn't add any reserved names", () {
    var mixinNames = findMemberNames(
        'package:protobuf/protobuf.dart', #ReadonlyMessageMixin);
    var reservedNames = Set<String>.from(GeneratedMessage_reservedNames);
    for (var name in mixinNames) {
      if (name == 'ReadonlyMessageMixin' || name == 'unknownFields') continue;
      if (!reservedNames.contains(name)) {
        fail('name from ReadonlyMessageMixin is not reserved: $name');
      }
    }
  });

  test('PbMapMixin reserved names are up to date', () {
    var meta = findMixin('PbMapMixin')!;
    var actual = Set<String>.from(meta.findReservedNames());

    var expected = findMemberNames(meta.importFrom, #PbMapMixin)
      ..addAll(findMemberNames('dart:collection', #MapMixin))
      ..removeAll(GeneratedMessage_reservedNames);

    expect(
        actual.toList()..sort(), containsAllInOrder(expected.toList()..sort()));
  });

  test('PbEventMixin reserved names are up to date', () {
    var meta = findMixin('PbEventMixin')!;
    var actual = Set<String>.from(meta.findReservedNames());

    var expected = findMemberNames(meta.importFrom, #PbEventMixin)
      ..removeAll(GeneratedMessage_reservedNames);

    expect(actual.toList()..sort(), equals(expected.toList()..sort()));
  });
}
