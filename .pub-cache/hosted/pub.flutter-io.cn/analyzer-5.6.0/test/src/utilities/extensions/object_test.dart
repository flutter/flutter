// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullableObjectExtensionTest);
  });
}

@reflectiveTest
class NullableObjectExtensionTest {
  test_ifTypeOrNull_int() {
    expect(0.ifTypeOrNull<int>(), 0);
    expect(0.ifTypeOrNull<num>(), 0);
    expect(0.ifTypeOrNull<Object>(), 0);
    expect(0.ifTypeOrNull<String>(), isNull);
  }

  test_ifTypeOrNull_null() {
    expect(null.ifTypeOrNull<Object>(), isNull);
    expect(null.ifTypeOrNull<int>(), isNull);
  }
}
