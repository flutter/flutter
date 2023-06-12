// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis/test_all.dart' as analysis;
import 'ast/test_all.dart' as ast;
import 'element/test_all.dart' as element;
import 'sdk/test_all.dart' as sdk;

main() {
  defineReflectiveSuite(() {
    analysis.main();
    ast.main();
    element.main();
    sdk.main();
  }, name: 'dart');
}
