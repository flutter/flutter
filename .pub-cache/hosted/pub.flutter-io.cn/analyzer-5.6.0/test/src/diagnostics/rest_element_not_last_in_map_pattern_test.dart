// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RestElementNotLastInMapPatternTest);
  });
}

@reflectiveTest
class RestElementNotLastInMapPatternTest extends PubPackageResolutionTest {
  test_notLast() async {
    await assertErrorsInCode(r'''
void f(Map<int, String> x) {
  if (x case {..., 0: _}) {}
}
''', [
      error(CompileTimeErrorCode.REST_ELEMENT_NOT_LAST_IN_MAP_PATTERN, 43, 3),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    RestPatternElement
      operator: ...
    MapPatternEntry
      key: IntegerLiteral
        literal: 0
        staticType: int
      separator: :
      value: WildcardPattern
        name: _
        matchedValueType: String
  rightBracket: }
  matchedValueType: Map<int, String>
  requiredType: Map<int, String>
''');
  }
}
