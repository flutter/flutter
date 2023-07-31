// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LogicalOrPatternResolutionTest);
  });
}

@reflectiveTest
class LogicalOrPatternResolutionTest extends PubPackageResolutionTest {
  test_ifCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case int _ || double _) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: WildcardPattern
    type: NamedType
      name: SimpleIdentifier
        token: int
        staticElement: dart:core::@class::int
        staticType: null
      type: int
    name: _
    matchedValueType: dynamic
  operator: ||
  rightOperand: WildcardPattern
    type: NamedType
      name: SimpleIdentifier
        token: double
        staticElement: dart:core::@class::double
        staticType: null
      type: double
    name: _
    matchedValueType: dynamic
  matchedValueType: dynamic
''');
  }

  test_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int _ || double _:
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: WildcardPattern
    type: NamedType
      name: SimpleIdentifier
        token: int
        staticElement: dart:core::@class::int
        staticType: null
      type: int
    name: _
    matchedValueType: dynamic
  operator: ||
  rightOperand: WildcardPattern
    type: NamedType
      name: SimpleIdentifier
        token: double
        staticElement: dart:core::@class::double
        staticType: null
      type: double
    name: _
    matchedValueType: dynamic
  matchedValueType: dynamic
''');
  }
}
