// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MetadataResolutionTest);
  });
}

@reflectiveTest
class MetadataResolutionTest extends PubPackageResolutionTest {
  ImportFindElement get import_a {
    return findElement.importFind('package:test/a.dart');
  }

  test_at_genericFunctionType_formalParameter() async {
    await assertNoErrorsInCode(r'''
const a = 42;
List<void Function(@a int b)> f() => [];
''');

    var annotation = findNode.annotation('@a');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: a
    staticElement: self::@getter::a
    staticType: null
  element: self::@getter::a
''');
    _assertAnnotationValueText(annotation, '''
int 42
''');
  }

  test_location_partDirective() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    await assertNoErrorsInCode(r'''
@foo
part 'a.dart';
const foo = 42;
''');

    var annotation = findNode.annotation('@foo');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: foo
    staticElement: self::@getter::foo
    staticType: null
  element: self::@getter::foo
''');

    var annotationElement = annotation.elementAnnotation!;
    _assertElementAnnotationValueText(annotationElement, r'''
int 42
''');
  }

  test_location_partOfDirective() async {
    var libPath = newFile('$testPackageLibPath/lib.dart', r'''
part 'part.dart';
''').path;

    var partPath = newFile('$testPackageLibPath/part.dart', r'''
@foo
part of 'lib.dart';
const foo = 42;
void f() {}
''').path;

    // Resolve the library, so that the part knows its library.
    await resolveFile2(libPath);

    await resolveFile2(partPath);
    assertNoErrorsInResult();

    var annotation = findNode.annotation('@foo');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: foo
    staticElement: package:test/lib.dart::@getter::foo
    staticType: null
  element: package:test/lib.dart::@getter::foo
''');

    var annotationElement = annotation.elementAnnotation!;
    _assertElementAnnotationValueText(annotationElement, r'''
int 42
''');
  }

  test_onEnumConstant() async {
    await assertNoErrorsInCode(r'''
enum E {
  @v
  v;
}
''');

    var annotation = findNode.annotation('@v');
    assertResolvedNodeText(annotation, '''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: v
    staticElement: self::@enum::E::@getter::v
    staticType: null
  element: self::@enum::E::@getter::v
''');

    _assertAnnotationValueText(annotation, '''
E
  _name: String v
  index: int 0
''');
  }

  test_onFieldFormal() async {
    await assertNoErrorsInCode(r'''
class A {
  final Object f;
  const A(this.f);
}

class B {
  final int f;
  B({@A( A(0) ) required this.f});
}
''');
    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    staticElement: self::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      InstanceCreationExpression
        constructorName: ConstructorName
          type: NamedType
            name: SimpleIdentifier
              token: A
              staticElement: self::@class::A
              staticType: null
            type: A
          staticElement: self::@class::A::@constructor::•
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            IntegerLiteral
              literal: 0
              parameter: self::@class::A::@constructor::•::@parameter::f
              staticType: int
          rightParenthesis: )
        parameter: self::@class::A::@constructor::•::@parameter::f
        staticType: A
    rightParenthesis: )
  element: self::@class::A::@constructor::•
''');
    _assertAnnotationValueText(annotation, r'''
A
  f: A
    f: int 0
''');
  }

  test_onLocalVariable() async {
    await assertNoErrorsInCode(r'''
class A {
  final int a;
  const A(this.a);
}

void f() {
  @A(3)
  int? x;
  print(x);
}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, '''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    staticElement: self::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 3
        parameter: self::@class::A::@constructor::•::@parameter::a
        staticType: int
    rightParenthesis: )
  element: self::@class::A::@constructor::•
''');

    final localVariable = findElement.localVar('x');
    final annotationOnElement = localVariable.metadata.single;
    _assertElementAnnotationValueText(annotationOnElement, '''
A
  a: int 3
''');
  }

  test_optIn_fromOptOut_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A(int a);
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

@A(0)
void f() {}
''');

    assertResolvedNodeText(findNode.annotation('@A'), r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    staticElement: package:test/a.dart::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: package:test/a.dart::@class::A::@constructor::•::@parameter::a
          isLegacy: true
        staticType: int*
    rightParenthesis: )
  element: ConstructorMember
    base: package:test/a.dart::@class::A::@constructor::•
    isLegacy: true
''');
  }

  test_optIn_fromOptOut_class_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int a;
  const A.named(this.a);
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

@A.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: package:test/a.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: package:test/a.dart::@class::A::@constructor::named
        isLegacy: true
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::A::@constructor::named
      isLegacy: true
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: package:test/a.dart::@class::A::@constructor::named::@parameter::a
          isLegacy: true
        staticType: int*
    rightParenthesis: )
  element: ConstructorMember
    base: package:test/a.dart::@class::A::@constructor::named
    isLegacy: true
''');

    _assertElementAnnotationValueText(
        findElement.function('f').metadata[0], r'''
A*
  a: int 42
''');
  }

  test_optIn_fromOptOut_class_constructor_withDefault() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int a;
  const A.named({this.a = 42});
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

@A.named()
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: package:test/a.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: package:test/a.dart::@class::A::@constructor::named
        isLegacy: true
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::A::@constructor::named
      isLegacy: true
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: ConstructorMember
    base: package:test/a.dart::@class::A::@constructor::named
    isLegacy: true
''');

    _assertElementAnnotationValueText(
        findElement.function('f').metadata[0], r'''
A*
  a: int 42
''');
  }

  test_optIn_fromOptOut_class_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const foo = 42;
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

@A.foo
void f() {}
''');

    assertResolvedNodeText(findNode.annotation('@A'), r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: package:test/a.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: PropertyAccessorMember
        base: package:test/a.dart::@class::A::@getter::foo
        isLegacy: true
      staticType: null
    staticElement: PropertyAccessorMember
      base: package:test/a.dart::@class::A::@getter::foo
      isLegacy: true
    staticType: null
  element: PropertyAccessorMember
    base: package:test/a.dart::@class::A::@getter::foo
    isLegacy: true
''');

    _assertElementAnnotationValueText(
        findElement.function('f').metadata[0], r'''
int 42
''');
  }

  test_optIn_fromOptOut_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
const foo = 42;
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

@foo
void f() {}
''');

    assertResolvedNodeText(findNode.annotation('@foo'), r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: foo
    staticElement: PropertyAccessorMember
      base: package:test/a.dart::@getter::foo
      isLegacy: true
    staticType: null
  element: PropertyAccessorMember
    base: package:test/a.dart::@getter::foo
    isLegacy: true
''');

    _assertElementAnnotationValueText(
        findElement.function('f').metadata[0], r'''
int 42
''');
  }

  test_optIn_fromOptOut_prefix_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A(int a);
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' as a;

@a.A(0)
void f() {}
''');

    assertResolvedNodeText(findNode.annotation('@a.A'), r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@prefix::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: A
      staticElement: package:test/a.dart::@class::A
      staticType: null
    staticElement: package:test/a.dart::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: package:test/a.dart::@class::A::@constructor::•::@parameter::a
          isLegacy: true
        staticType: int*
    rightParenthesis: )
  element: ConstructorMember
    base: package:test/a.dart::@class::A::@constructor::•
    isLegacy: true
''');
  }

  test_optIn_fromOptOut_prefix_class_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named(int a);
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' as a;

@a.A.named(0)
void f() {}
''');

    assertResolvedNodeText(findNode.annotation('@a.A'), r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@prefix::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: A
      staticElement: package:test/a.dart::@class::A
      staticType: null
    staticElement: package:test/a.dart::@class::A
    staticType: null
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::A::@constructor::named
      isLegacy: true
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: package:test/a.dart::@class::A::@constructor::named::@parameter::a
          isLegacy: true
        staticType: int*
    rightParenthesis: )
  element: ConstructorMember
    base: package:test/a.dart::@class::A::@constructor::named
    isLegacy: true
''');
  }

  test_optIn_fromOptOut_prefix_class_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const foo = 0;
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' as a;

@a.A.foo
void f() {}
''');

    assertResolvedNodeText(findNode.annotation('@a.A'), r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@prefix::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: A
      staticElement: package:test/a.dart::@class::A
      staticType: null
    staticElement: package:test/a.dart::@class::A
    staticType: null
  period: .
  constructorName: SimpleIdentifier
    token: foo
    staticElement: PropertyAccessorMember
      base: package:test/a.dart::@class::A::@getter::foo
      isLegacy: true
    staticType: null
  element: PropertyAccessorMember
    base: package:test/a.dart::@class::A::@getter::foo
    isLegacy: true
''');
  }

  test_optIn_fromOptOut_prefix_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
const foo = 0;
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' as a;

@a.foo
void f() {}
''');

    assertResolvedNodeText(findNode.annotation('@a'), r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@prefix::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: PropertyAccessorMember
        base: package:test/a.dart::@getter::foo
        isLegacy: true
      staticType: null
    staticElement: PropertyAccessorMember
      base: package:test/a.dart::@getter::foo
      isLegacy: true
    staticType: null
  element: PropertyAccessorMember
    base: package:test/a.dart::@getter::foo
    isLegacy: true
''');
  }

  test_value_class_inference_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  final int f;
  const A.named(this.f);
}

@A.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: self::@class::A::@constructor::named
      staticType: null
    staticElement: self::@class::A::@constructor::named
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: self::@class::A::@constructor::named::@parameter::f
        staticType: int
    rightParenthesis: )
  element: self::@class::A::@constructor::named
''');
    _assertAnnotationValueText(annotation, '''
A
  f: int 42
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
    );
  }

  test_value_class_staticConstField() async {
    await assertNoErrorsInCode(r'''
class A {
  static const int foo = 42;
}

@A.foo
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@getter::foo
      staticType: null
    staticElement: self::@class::A::@getter::foo
    staticType: null
  element: self::@class::A::@getter::foo
''');
    _assertAnnotationValueText(annotation, '''
int 42
''');
  }

  test_value_class_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
 class A {
  final int f;
  const A(this.f);
}

@A(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    staticElement: self::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: self::@class::A::@constructor::•::@parameter::f
        staticType: int
    rightParenthesis: )
  element: self::@class::A::@constructor::•
''');
    _assertAnnotationValueText(annotation, r'''
A
  f: int 42
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
    );
  }

  test_value_genericClass_downwards_inference_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final List<List<T>> f;
  const A.named(this.f);
}

@A.named([])
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: Object?}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: Object?}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      ListLiteral
        leftBracket: [
        rightBracket: ]
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::named::@parameter::f
          substitution: {T: Object?}
        staticType: List<List<Object?>>
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: Object?}
''');
    _assertAnnotationValueText(annotation, '''
A<Object?>
  f: List
    elementType: List<Object?>
''');
    assertElement2(
      findNode.listLiteral('[]').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
      substitution: {'T': 'Object?'},
    );
  }

  test_value_genericClass_downwards_inference_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final List<List<T>> f;
  const A(this.f);
}

@A([])
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    staticElement: self::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      ListLiteral
        leftBracket: [
        rightBracket: ]
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::•::@parameter::f
          substitution: {T: Object?}
        staticType: List<List<Object?>>
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: Object?}
''');
    _assertAnnotationValueText(annotation, r'''
A<Object?>
  f: List
    elementType: List<Object?>
''');
    assertElement2(
      findNode.listLiteral('[]').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
      substitution: {'T': 'Object?'},
    );
  }

  test_value_genericClass_inference_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

@A.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::named::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, '''
A<int>
  f: int 42
''');
    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
      substitution: {'T': 'int'},
    );
  }

  test_value_genericClass_inference_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

@A(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    staticElement: self::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::•::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
''');
    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
      substitution: {'T': 'int'},
    );
  }

  test_value_genericClass_instanceGetter() async {
    await resolveTestCode(r'''
class A<T> {
  T get foo {}
}

@A.foo
void f() {}
''');

    assertResolvedNodeText(findNode.annotation('@A'), r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@getter::foo
      staticType: null
    staticElement: self::@class::A::@getter::foo
    staticType: null
  element: self::@class::A::@getter::foo
''');
  }

  test_value_genericClass_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final int f;
  const A.named(this.f);
}

@A.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: dynamic}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::named::@parameter::f
          substitution: {T: dynamic}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: dynamic}
''');
    _assertAnnotationValueText(annotation, '''
A<dynamic>
  f: int 42
''');
  }

  test_value_genericClass_staticGetter() async {
    await resolveTestCode(r'''
class A<T> {
  static T get foo {}
}

@A.foo
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@getter::foo
      staticType: null
    staticElement: self::@class::A::@getter::foo
    staticType: null
  element: self::@class::A::@getter::foo
''');
    _assertAnnotationValueText(annotation, '''
<null>
''');
  }

  test_value_genericClass_typeArguments_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

@A<int>.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    staticElement: self::@class::A
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
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::named::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, '''
A<int>
  f: int 42
''');
    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
      substitution: {'T': 'int'},
    );
  }

  test_value_genericClass_typeArguments_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

@A<int>(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    staticElement: self::@class::A
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
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::•::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
''');
    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
      substitution: {'T': 'int'},
    );
  }

  test_value_genericClass_unnamedConstructor_noGenericMetadata() async {
    writeTestPackageConfig(PackageConfigFileBuilder(), languageVersion: '2.12');
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A(this.f);
}

@A(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    staticElement: self::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::•::@parameter::f
          substitution: {T: dynamic}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: dynamic}
''');
    _assertAnnotationValueText(annotation, r'''
A<dynamic>
  f: int 42
''');
    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
      substitution: {'T': 'dynamic'},
    );
  }

  test_value_genericMixinApplication_inference_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

@B(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    staticElement: self::@class::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: ParameterMember
          base: self::@class::B::@constructor::•::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::B::@constructor::•
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor_classTypeAlias() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

@B(42)
class C<T> = D with E;

class D {}
class E {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    staticElement: self::@class::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: ParameterMember
          base: self::@class::B::@constructor::•::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::B::@constructor::•
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor_functionTypeAlias() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

@B(42)
typedef T F<T>();
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    staticElement: self::@class::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: ParameterMember
          base: self::@class::B::@constructor::•::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::B::@constructor::•
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor_functionTypedFormalParameter() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

f(@B(42) g()) {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    staticElement: self::@class::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: ParameterMember
          base: self::@class::B::@constructor::•::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::B::@constructor::•
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor_genericTypeAlias() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

@B(42)
typedef F = void Function();
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    staticElement: self::@class::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: ParameterMember
          base: self::@class::B::@constructor::•::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::B::@constructor::•
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor_methodDeclaration() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

class C {
  @B(42)
  m() {}
}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    staticElement: self::@class::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: ParameterMember
          base: self::@class::B::@constructor::•::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::B::@constructor::•
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
''');
  }

  test_value_genericMixinApplication_typeArguments_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

@B<int>(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    staticElement: self::@class::B
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
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: ParameterMember
          base: self::@class::B::@constructor::•::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::B::@constructor::•
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
''');
  }

  test_value_otherLibrary_implicitConst() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A(this.f);
}

class B {
  final A a;
  const B(this.a);
}

@B( A(42) )
class C {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart';

void f(C c) {}
''');

    var classC = findNode.namedType('C c').name.staticElement!;
    var annotation = classC.metadata.single;
    _assertElementAnnotationValueText(annotation, r'''
B
  a: A
    f: int 42
''');
  }

  test_value_otherLibrary_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A.named(this.f);
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

@A.named(42)
class B {}
''');

    await assertNoErrorsInCode(r'''
import 'b.dart';

void f(B b) {}
''');

    var classB = findNode.namedType('B b').name.staticElement!;
    var annotation = classB.metadata.single;
    _assertElementAnnotationValueText(annotation, r'''
A
  f: int 42
''');
  }

  test_value_otherLibrary_unnamedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A(this.f);
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

@A(42)
class B {}
''');

    await assertNoErrorsInCode(r'''
import 'b.dart';

void f(B b) {}
''');

    var classB = findNode.namedType('B b').name.staticElement!;
    var annotation = classB.metadata.single;
    _assertElementAnnotationValueText(annotation, r'''
A
  f: int 42
''');
  }

  test_value_prefix_typeAlias_class_staticConstField() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const int foo = 42;
}

typedef B = A;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

@prefix.B.foo
void f() {}
''');

    var annotation = findNode.annotation('@prefix.B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: self::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: B
      staticElement: package:test/a.dart::@typeAlias::B
      staticType: null
    staticElement: package:test/a.dart::@typeAlias::B
    staticType: null
  period: .
  constructorName: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::@class::A::@getter::foo
    staticType: null
  element: package:test/a.dart::@class::A::@getter::foo
''');
    _assertAnnotationValueText(annotation, '''
int 42
''');
  }

  test_value_prefix_typeAlias_generic_class_generic_all_inference_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

typedef B<U> = A<U>;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

@prefix.B.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@prefix.B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: self::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: B
      staticElement: package:test/a.dart::@typeAlias::B
      staticType: null
    staticElement: package:test/a.dart::@typeAlias::B
    staticType: null
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: package:test/a.dart::@class::A::@constructor::named::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: package:test/a.dart::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.importFind('package:test/a.dart').parameter('f'),
      substitution: {'T': 'int'},
    );
  }

  test_value_prefix_typeAlias_generic_class_generic_all_inference_unnamedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  final T f;
  const A(this.f);
}

typedef B<U> = A<U>;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

@prefix.B(42)
void f() {}
''');

    var annotation = findNode.annotation('@prefix.B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: self::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: B
      staticElement: package:test/a.dart::@typeAlias::B
      staticType: null
    staticElement: package:test/a.dart::@typeAlias::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: package:test/a.dart::@class::A::@constructor::•::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: package:test/a.dart::@class::A::@constructor::•
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.importFind('package:test/a.dart').parameter('f'),
      substitution: {'T': 'int'},
    );
  }

  test_value_prefix_typeAlias_generic_class_generic_all_typeArguments_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

typedef B<U> = A<U>;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

@prefix.B<int>.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@prefix.B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: self::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: B
      staticElement: package:test/a.dart::@typeAlias::B
      staticType: null
    staticElement: package:test/a.dart::@typeAlias::B
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
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: package:test/a.dart::@class::A::@constructor::named::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: package:test/a.dart::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.importFind('package:test/a.dart').parameter('f'),
      substitution: {'T': 'int'},
    );
  }

  test_value_prefix_typeAlias_generic_class_generic_all_typeArguments_unnamedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  final T f;
  const A(this.f);
}

typedef B<U> = A<U>;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

@prefix.B<int>(42)
void f() {}
''');

    var annotation = findNode.annotation('@prefix.B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: self::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: B
      staticElement: package:test/a.dart::@typeAlias::B
      staticType: null
    staticElement: package:test/a.dart::@typeAlias::B
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
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: package:test/a.dart::@class::A::@constructor::•::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: package:test/a.dart::@class::A::@constructor::•
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.importFind('package:test/a.dart').parameter('f'),
      substitution: {'T': 'int'},
    );
  }

  test_value_typeAlias_class_staticConstField() async {
    await assertNoErrorsInCode(r'''
class A {
  static const int foo = 42;
}

typedef B = A;

@B.foo
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      staticElement: self::@typeAlias::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@getter::foo
      staticType: null
    staticElement: self::@class::A::@getter::foo
    staticType: null
  element: self::@class::A::@getter::foo
''');
    _assertAnnotationValueText(annotation, '''
int 42
''');
  }

  test_value_typeAlias_generic_class_generic_1of2_typeArguments_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  final T t;
  final U u;
  const A.named(this.t, this.u);
}

typedef B<T> = A<T, double>;

@B<int>.named(42, 1.2)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    staticElement: self::@typeAlias::B
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
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int, U: double}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::named::@parameter::t
          substitution: {T: int, U: double}
        staticType: int
      DoubleLiteral
        literal: 1.2
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::named::@parameter::u
          substitution: {T: int, U: double}
        staticType: double
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: int, U: double}
''');
    _assertAnnotationValueText(annotation, r'''
A<int, double>
  t: int 42
  u: double 1.2
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('t'),
      substitution: {'T': 'int', 'U': 'double'},
    );

    assertElement2(
      findNode.doubleLiteral('1.2').staticParameterElement,
      declaration: findElement.fieldFormalParameter('u'),
      substitution: {'T': 'int', 'U': 'double'},
    );
  }

  test_value_typeAlias_generic_class_generic_1of2_typeArguments_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  final T t;
  final U u;
  const A(this.t, this.u);
}

typedef B<T> = A<T, double>;

@B<int>(42, 1.2)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    staticElement: self::@typeAlias::B
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
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::•::@parameter::t
          substitution: {T: int, U: double}
        staticType: int
      DoubleLiteral
        literal: 1.2
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::•::@parameter::u
          substitution: {T: int, U: double}
        staticType: double
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: int, U: double}
''');
    _assertAnnotationValueText(annotation, r'''
A<int, double>
  t: int 42
  u: double 1.2
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('t'),
      substitution: {'T': 'int', 'U': 'double'},
    );

    assertElement2(
      findNode.doubleLiteral('1.2').staticParameterElement,
      declaration: findElement.fieldFormalParameter('u'),
      substitution: {'T': 'int', 'U': 'double'},
    );
  }

  test_value_typeAlias_generic_class_generic_all_inference_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

typedef B<U> = A<U>;

@B.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      staticElement: self::@typeAlias::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::named::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
      substitution: {'T': 'int'},
    );
  }

  test_value_typeAlias_generic_class_generic_all_inference_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A(this.f);
}

typedef B<U> = A<U>;

@B(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    staticElement: self::@typeAlias::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::•::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
      substitution: {'T': 'int'},
    );
  }

  test_value_typeAlias_generic_class_generic_all_typeArguments_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

typedef B<U> = A<U>;

@B<int>.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    staticElement: self::@typeAlias::B
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
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::named::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
      substitution: {'T': 'int'},
    );
  }

  test_value_typeAlias_generic_class_generic_all_typeArguments_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A(this.f);
}

typedef B<U> = A<U>;

@B<int>(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    staticElement: self::@typeAlias::B
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
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::•::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
      substitution: {'T': 'int'},
    );
  }

  test_value_typeAlias_notGeneric_class_generic_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

typedef B = A<int>;

@B.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      staticElement: self::@typeAlias::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::named::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
      substitution: {'T': 'int'},
    );
  }

  test_value_typeAlias_notGeneric_class_generic_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A(this.f);
}

typedef B = A<int>;

@B(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    staticElement: self::@typeAlias::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: self::@class::A::@constructor::•::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
      substitution: {'T': 'int'},
    );
  }

  test_value_typeAlias_notGeneric_class_notGeneric_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  final int f;
  const A.named(this.f);
}

typedef B = A;

@B.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      staticElement: self::@typeAlias::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: self::@class::A::@constructor::named
      staticType: null
    staticElement: self::@class::A::@constructor::named
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: self::@class::A::@constructor::named::@parameter::f
        staticType: int
    rightParenthesis: )
  element: self::@class::A::@constructor::named
''');
    _assertAnnotationValueText(annotation, r'''
A
  f: int 42
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
    );
  }

  test_value_typeAlias_notGeneric_class_notGeneric_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  final int f;
  const A(this.f);
}

typedef B = A;

@B(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    staticElement: self::@typeAlias::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: self::@class::A::@constructor::•::@parameter::f
        staticType: int
    rightParenthesis: )
  element: self::@class::A::@constructor::•
''');
    _assertAnnotationValueText(annotation, r'''
A
  f: int 42
''');

    assertElement2(
      findNode.integerLiteral('42').staticParameterElement,
      declaration: findElement.fieldFormalParameter('f'),
    );
  }

  void _assertAnnotationValueText(Annotation annotation, String expected) {
    var elementAnnotation = annotation.elementAnnotation!;
    _assertElementAnnotationValueText(elementAnnotation, expected);
  }

  void _assertElementAnnotationValueText(
    ElementAnnotation annotation,
    String expected,
  ) {
    var value = annotation.computeConstantValue();
    assertDartObjectText(value, expected);
  }
}
