// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/utilities/extensions/stream.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StreamExtensionTest);
  });
}

@reflectiveTest
class StreamExtensionTest {
  test_whereType() async {
    var result = await Stream<Object?>.fromIterable([0, '1', 2])
        .whereType<int>()
        .toList();
    expect(result, [0, 2]);
  }
}
