// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListExtensionTest);
  });
}

@reflectiveTest
class ListExtensionTest {
  test_addIfNotNull_notNull() {
    var elements = [0, 1];
    elements.addIfNotNull(2);
    expect(elements, [0, 1, 2]);
  }

  test_addIfNotNull_null() {
    var elements = [0, 1];
    elements.addIfNotNull(null);
    expect(elements, [0, 1]);
  }
}
