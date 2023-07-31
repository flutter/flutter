// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinInstantiateTest);
  });
}

@reflectiveTest
class MixinInstantiateTest extends PubPackageResolutionTest {
  test_namedConstructor() async {
    await assertErrorsInCode(r'''
mixin M {
  M.named() {}
}

main() {
  new M.named();
}
''', [
      error(ParserErrorCode.MIXIN_DECLARES_CONSTRUCTOR, 12, 1),
      error(CompileTimeErrorCode.MIXIN_INSTANTIATE, 43, 1),
    ]);

    var node = findNode.instanceCreation('M.named();');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: M
        staticElement: self::@mixin::M
        staticType: null
      type: M
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: self::@mixin::M::@constructor::named
      staticType: null
    staticElement: self::@mixin::M::@constructor::named
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: M
''');
  }

  test_namedConstructor_undefined() async {
    await assertErrorsInCode(r'''
mixin M {}

main() {
  new M.named();
}
''', [
      error(CompileTimeErrorCode.MIXIN_INSTANTIATE, 27, 1),
    ]);

    var creation = findNode.instanceCreation('M.named();');
    var m = findElement.mixin('M');
    assertElement(creation.constructorName.type.name, m);
  }

  test_unnamedConstructor() async {
    await assertErrorsInCode(r'''
mixin M {}

main() {
  new M();
}
''', [
      error(CompileTimeErrorCode.MIXIN_INSTANTIATE, 27, 1),
    ]);

    var node = findNode.instanceCreation('M();');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: M
        staticElement: self::@mixin::M
        staticType: null
      type: M
    staticElement: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: M
''');
  }
}
