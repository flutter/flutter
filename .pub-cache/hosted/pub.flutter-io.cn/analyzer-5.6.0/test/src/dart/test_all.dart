// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis/test_all.dart' as analysis;
import 'ast/test_all.dart' as ast;
import 'constant/test_all.dart' as constant;
import 'element/test_all.dart' as element;
import 'micro/test_all.dart' as micro;
import 'resolution/test_all.dart' as resolution;
import 'resolver/test_all.dart' as resolver;
import 'sdk/test_all.dart' as sdk;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    analysis.main();
    ast.main();
    constant.main();
    element.main();
    micro.main();
    resolution.main();
    resolver.main();
    sdk.main();
  }, name: 'dart');
}
