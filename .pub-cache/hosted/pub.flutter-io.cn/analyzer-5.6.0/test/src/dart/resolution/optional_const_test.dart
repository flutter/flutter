// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionalConstDriverResolutionTest);
  });
}

@reflectiveTest
class OptionalConstDriverResolutionTest extends PubPackageResolutionTest {
  test_instantiateToBounds_notPrefixed_named() async {
    var node = await _resolveImplicitConst('B.named()');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: B
        staticElement: package:test/a.dart::@class::B
        staticType: null
      type: B<num>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: package:test/a.dart::@class::B::@constructor::named
        substitution: {T: num}
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::B::@constructor::named
      substitution: {T: num}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: B<num>
''');
  }

  test_instantiateToBounds_notPrefixed_unnamed() async {
    var node = await _resolveImplicitConst('B()');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: B
        staticElement: package:test/a.dart::@class::B
        staticType: null
      type: B<num>
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::B::@constructor::new
      substitution: {T: num}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: B<num>
''');
  }

  test_instantiateToBounds_prefixed_named() async {
    var node = await _resolveImplicitConst('p.B.named()', prefix: 'p');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
          staticElement: package:test/b.dart::@prefix::p
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: B
          staticElement: package:test/a.dart::@class::B
          staticType: null
        staticElement: package:test/a.dart::@class::B
        staticType: null
      type: B<num>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: package:test/a.dart::@class::B::@constructor::named
        substitution: {T: num}
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::B::@constructor::named
      substitution: {T: num}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: B<num>
''');
  }

  test_instantiateToBounds_prefixed_unnamed() async {
    var node = await _resolveImplicitConst('p.B()', prefix: 'p');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
          staticElement: package:test/b.dart::@prefix::p
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: B
          staticElement: package:test/a.dart::@class::B
          staticType: null
        staticElement: package:test/a.dart::@class::B
        staticType: null
      type: B<num>
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::B::@constructor::new
      substitution: {T: num}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: B<num>
''');
  }

  test_notPrefixed_named() async {
    var node = await _resolveImplicitConst('A.named()');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: A
        staticElement: package:test/a.dart::@class::A
        staticType: null
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: package:test/a.dart::@class::A::@constructor::named
      staticType: null
    staticElement: package:test/a.dart::@class::A::@constructor::named
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A
''');
  }

  test_notPrefixed_unnamed() async {
    var node = await _resolveImplicitConst('A()');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: SimpleIdentifier
        token: A
        staticElement: package:test/a.dart::@class::A
        staticType: null
      type: A
    staticElement: package:test/a.dart::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A
''');
  }

  test_prefixed_named() async {
    var node = await _resolveImplicitConst('p.A.named()', prefix: 'p');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
          staticElement: package:test/b.dart::@prefix::p
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: A
          staticElement: package:test/a.dart::@class::A
          staticType: null
        staticElement: package:test/a.dart::@class::A
        staticType: null
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: package:test/a.dart::@class::A::@constructor::named
      staticType: null
    staticElement: package:test/a.dart::@class::A::@constructor::named
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A
''');
  }

  test_prefixed_unnamed() async {
    var node = await _resolveImplicitConst('p.A()', prefix: 'p');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
          staticElement: package:test/b.dart::@prefix::p
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: A
          staticElement: package:test/a.dart::@class::A
          staticType: null
        staticElement: package:test/a.dart::@class::A
        staticType: null
      type: A
    staticElement: package:test/a.dart::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A
''');
  }

  test_prefixed_unnamed_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C<T> {
  const C();
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as p;

const x = p.C<int>();
''');

    var node = findNode.instanceCreation('p.C<int>()');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
          staticElement: self::@prefix::p
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: C
          staticElement: package:test/a.dart::@class::C
          staticType: null
        staticElement: package:test/a.dart::@class::C
        staticType: null
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int
        rightBracket: >
      type: C<int>
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::C::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: C<int>
''');
  }

  Future<InstanceCreationExpression> _resolveImplicitConst(String expr,
      {String? prefix}) async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  const A();
  const A.named();
}
class B<T extends num> {
  const B();
  const B.named();
}
''');

    if (prefix != null) {
      newFile('$testPackageLibPath/b.dart', '''
import 'a.dart' as $prefix;
const a = $expr;
''');
    } else {
      newFile('$testPackageLibPath/b.dart', '''
import 'a.dart';
const a = $expr;
''');
    }

    await resolveTestCode(r'''
import 'b.dart';
var v = a;
''');

    var vg = findNode.simple('a;').staticElement as PropertyAccessorElement;
    var v = vg.variable as ConstVariableElement;

    var creation = v.constantInitializer as InstanceCreationExpression;
    return creation;
  }
}
