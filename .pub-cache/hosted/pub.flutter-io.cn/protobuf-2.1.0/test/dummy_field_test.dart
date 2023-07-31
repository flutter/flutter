// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

class Message extends GeneratedMessage {
  @override
  BuilderInfo get info_ => _i;
  static final _i = BuilderInfo('Message')
    ..add(0, 'dummy', null, null, null, null, null);
  @override
  Message createEmptyInstance() => Message();

  @override
  GeneratedMessage clone() => throw UnimplementedError();
}

void main() {
  test('Has no known fields', () {
    expect(Message().info_.fieldInfo, isEmpty);
  });
}
