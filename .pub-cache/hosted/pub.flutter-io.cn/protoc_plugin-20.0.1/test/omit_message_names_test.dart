// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../out/protos/google/protobuf/unittest.pb.dart';

@pragma('dart2js:noInline')
String constant() => 'SHOULD_BE_PRESENT';

Future<void> main() async {
  test('message name available depending on environment', () {
    expect(
        TestAllTypes_NestedMessage().info_.qualifiedMessageName,
        const bool.fromEnvironment('protobuf.omit_message_names')
            ? ''
            : 'protobuf_unittest.TestAllTypes.NestedMessage');
    expect(constant(), 'SHOULD_BE_PRESENT');
  });
}
