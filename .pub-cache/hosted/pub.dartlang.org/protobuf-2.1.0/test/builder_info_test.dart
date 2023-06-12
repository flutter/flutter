// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

void main() {
  group('className', () {
    final qualifiedmessageName = 'proto.test.TestMessage';
    final expectedMessageName = 'TestMessage';
    test('truncates qualifiedMessageName containing dots', () {
      final info = BuilderInfo(qualifiedmessageName);
      expect(info.messageName, expectedMessageName);
    });

    test('uses qualifiedMessageName if it contains no dots', () {
      final info = BuilderInfo(expectedMessageName);
      expect(info.messageName, expectedMessageName);
    });
  });
}
