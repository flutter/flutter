// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'dart_style/test_all.dart' as dart_style;

main() {
  defineReflectiveSuite(() {
    dart_style.main();
  }, name: 'clients');
}
