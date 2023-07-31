// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../out/protos/google/protobuf/unittest.pb.dart';

@pragma('dart2js:noInline')
String constant() => 'SHOULD_BE_PRESENT';

Future<void> main() async {
  test('enum name available depending on environment', () {
    var proto = TestAllTypes()..optionalForeignMessage = ForeignMessage();

    expect(
        proto.toString(),
        const bool.fromEnvironment('protobuf.omit_field_names')
            ? '19: {\n}\n'
            : 'optionalForeignMessage: {\n}\n');
    expect(constant(), 'SHOULD_BE_PRESENT');
  });
}
