#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide Duration;

import 'package:test/test.dart';

import '../out/protos/proto3_optional.pb.dart';

void main() {
  test('optional fields have presence', () {
    var f = Foo();
    expect(f.hasOptionalSubmessage(), isFalse);
    f.optionalSubmessage = Submessage();
    expect(f.hasOptionalSubmessage(), isTrue);
  });
}
