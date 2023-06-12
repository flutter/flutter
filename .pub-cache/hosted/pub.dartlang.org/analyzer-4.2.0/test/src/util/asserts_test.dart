// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/asserts.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisTaskTest);
  });
}

@reflectiveTest
class AnalysisTaskTest {
  void test_notNull_notNull() {
    notNull(this);
  }

  void test_notNull_null_hasDescription() {
    expect(() => notNull(null, 'desc'), throwsArgumentError);
  }

  void test_notNull_null_noDescription() {
    expect(() => notNull(null), throwsArgumentError);
  }
}
