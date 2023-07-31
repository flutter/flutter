// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../out/protos/foo.pb.dart' as foo;
import '../out/protos/import_clash.pb.dart' as pb;

void main() {
  test('Import prefixes in generated files do not clash with fields', () {
    pb.Clasher().foo = foo.Foo();
  });
}
