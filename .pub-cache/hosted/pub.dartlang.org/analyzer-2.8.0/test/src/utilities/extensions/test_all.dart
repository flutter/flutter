// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'collection_test.dart' as collection;
import 'string_test.dart' as string;

main() {
  defineReflectiveSuite(() {
    collection.main();
    string.main();
  }, name: 'extensions');
}
