// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../summary/resolved_ast_printer.dart';
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  element: self::@getter::a
  name: SimpleIdentifier
    staticElement: self::@getter::a
    staticType: null
    token: a
''');
    _assertAnnotationValueText(annotation, '''
int 42
''');
  }

  test_location_partDirective() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
part of 'test.dart';
''');

    await assertNoErrorsInCode(r'''
@foo
part 'a.dart';
const foo = 42;
''');

    var annotation = findNode.annotation('@foo');
    assertElement2(
      annotation,
      declaration: findElement.topGet('foo'),
    );

    var annotationElement = annotation.elementAnnotation!;
    _assertElementAnnotationValueText(annotationElement, r'''
int 42
''');
  }

  test_location_partOfDirective() async {
    var libPath = newFile('$testPackageLibPath/lib.dart', content: r'''
part 'part.dart';
''').path;

    var partPath = newFile('$testPackageLibPath/part.dart', content: r'''
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
    assertElement2(
      annotation,
      declaration: findElement.topGet('foo'),
    );

    var annotationElement = annotation.elementAnnotation!;
    _assertElementAnnotationValueText(annotationElement, r'''
int 42
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      InstanceCreationExpression
        argumentList: ArgumentList
          arguments
            IntegerLiteral
              literal: 0
              staticType: int
          leftParenthesis: (
          rightParenthesis: )
        constructorName: ConstructorName
          staticElement: self::@class::A::@constructor::•
          type: NamedType
            name: SimpleIdentifier
              staticElement: self::@class::A
              staticType: null
              token: A
            type: A
        staticType: A
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: self::@class::A::@constructor::•
  name: SimpleIdentifier
    staticElement: self::@class::A
    staticType: null
    token: A
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
    _assertResolvedNodeText(annotation, '''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 3
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: self::@class::A::@constructor::•
  name: SimpleIdentifier
    staticElement: self::@class::A
    staticType: null
    token: A
''');

    final localVariable = findElement.localVar('x');
    final annotationOnElement = localVariable.metadata.single;
    _assertElementAnnotationValueText(annotationOnElement, '''
A
  a: int 3
''');
  }

  test_optIn_fromOptOut_class() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
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

    assertElement2(
      findNode.simple('A('),
      declaration: import_a.class_('A'),
    );

    assertElement2(
      findNode.annotation('@A'),
      declaration: import_a.unnamedConstructor('A'),
      isLegacy: true,
    );
  }

  test_optIn_fromOptOut_class_constructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
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

    assertElement2(
      findNode.simple('A.named('),
      declaration: import_a.class_('A'),
    );

    assertElement2(
      findNode.annotation('@A'),
      declaration: import_a.constructor('named', of: 'A'),
      isLegacy: true,
    );

    _assertElementAnnotationValueText(
        findElement.function('f').metadata[0], r'''
A*
  a: int 42
''');
  }

  test_optIn_fromOptOut_class_constructor_withDefault() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
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

    assertElement2(
      findNode.simple('A.named('),
      declaration: import_a.class_('A'),
    );

    assertElement2(
      findNode.annotation('@A'),
      declaration: import_a.constructor('named', of: 'A'),
      isLegacy: true,
    );

    _assertElementAnnotationValueText(
        findElement.function('f').metadata[0], r'''
A*
  a: int 42
''');
  }

  test_optIn_fromOptOut_class_getter() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
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

    assertElement2(
      findNode.simple('A.foo'),
      declaration: import_a.class_('A'),
    );

    assertElement2(
      findNode.annotation('@A.foo'),
      declaration: import_a.getter('foo'),
      isLegacy: true,
    );

    _assertElementAnnotationValueText(
        findElement.function('f').metadata[0], r'''
int 42
''');
  }

  test_optIn_fromOptOut_getter() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
const foo = 42;
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

@foo
void f() {}
''');

    assertElement2(
      findNode.annotation('@foo'),
      declaration: import_a.topGet('foo'),
      isLegacy: true,
    );

    _assertElementAnnotationValueText(
        findElement.function('f').metadata[0], r'''
int 42
''');
  }

  test_optIn_fromOptOut_prefix_class() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
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

    assertElement2(
      findNode.simple('A('),
      declaration: import_a.class_('A'),
    );

    assertElement2(
      findNode.annotation('@a.A'),
      declaration: import_a.unnamedConstructor('A'),
      isLegacy: true,
    );
  }

  test_optIn_fromOptOut_prefix_class_constructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
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

    assertElement2(
      findNode.simple('A.named('),
      declaration: import_a.class_('A'),
    );

    assertElement2(
      findNode.annotation('@a.A'),
      declaration: import_a.constructor('named', of: 'A'),
      isLegacy: true,
    );
  }

  test_optIn_fromOptOut_prefix_class_getter() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
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

    assertElement2(
      findNode.simple('A.foo'),
      declaration: import_a.class_('A'),
    );

    assertElement2(
      findNode.annotation('@a.A'),
      declaration: import_a.getter('foo'),
      isLegacy: true,
    );
  }

  test_optIn_fromOptOut_prefix_getter() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
const foo = 0;
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' as a;

@a.foo
void f() {}
''');

    assertElement2(
      findNode.annotation('@a.foo'),
      declaration: import_a.topGet('foo'),
      isLegacy: true,
    );
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: self::@class::A::@constructor::named
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: self::@class::A::@constructor::named
      staticType: null
      token: named
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@class::A
      staticType: null
      token: A
    staticElement: self::@class::A::@constructor::named
    staticType: null
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  element: self::@class::A::@getter::foo
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: self::@class::A::@getter::foo
      staticType: null
      token: foo
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@class::A
      staticType: null
      token: A
    staticElement: self::@class::A::@getter::foo
    staticType: null
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: self::@class::A::@constructor::•
  name: SimpleIdentifier
    staticElement: self::@class::A
    staticType: null
    token: A
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: int}
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
      token: named
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@class::A
      staticType: null
      token: A
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: int}
  name: SimpleIdentifier
    staticElement: self::@class::A
    staticType: null
    token: A
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

    _assertResolvedNodeText(findNode.annotation('@A'), r'''
Annotation
  atSign: @
  element: self::@class::A::@getter::foo
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: self::@class::A::@getter::foo
      staticType: null
      token: foo
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@class::A
      staticType: null
      token: A
    staticElement: self::@class::A::@getter::foo
    staticType: null
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: dynamic}
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
      token: named
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@class::A
      staticType: null
      token: A
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: dynamic}
    staticType: null
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  element: self::@class::A::@getter::foo
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: self::@class::A::@getter::foo
      staticType: null
      token: foo
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@class::A
      staticType: null
      token: A
    staticElement: self::@class::A::@getter::foo
    staticType: null
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  constructorName: SimpleIdentifier
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
    token: named
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: int}
  name: SimpleIdentifier
    staticElement: self::@class::A
    staticType: null
    token: A
  typeArguments: TypeArgumentList
    arguments
      NamedType
        name: SimpleIdentifier
          staticElement: dart:core::@class::int
          staticType: null
          token: int
        type: int
    leftBracket: <
    rightBracket: >
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: int}
  name: SimpleIdentifier
    staticElement: self::@class::A
    staticType: null
    token: A
  typeArguments: TypeArgumentList
    arguments
      NamedType
        name: SimpleIdentifier
          staticElement: dart:core::@class::int
          staticType: null
          token: int
        type: int
    leftBracket: <
    rightBracket: >
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: dynamic}
  name: SimpleIdentifier
    staticElement: self::@class::A
    staticType: null
    token: A
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::B::@constructor::•
    substitution: {T: int}
  name: SimpleIdentifier
    staticElement: self::@class::B
    staticType: null
    token: B
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::B::@constructor::•
    substitution: {T: int}
  name: SimpleIdentifier
    staticElement: self::@class::B
    staticType: null
    token: B
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::B::@constructor::•
    substitution: {T: int}
  name: SimpleIdentifier
    staticElement: self::@class::B
    staticType: null
    token: B
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::B::@constructor::•
    substitution: {T: int}
  name: SimpleIdentifier
    staticElement: self::@class::B
    staticType: null
    token: B
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::B::@constructor::•
    substitution: {T: int}
  name: SimpleIdentifier
    staticElement: self::@class::B
    staticType: null
    token: B
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::B::@constructor::•
    substitution: {T: int}
  name: SimpleIdentifier
    staticElement: self::@class::B
    staticType: null
    token: B
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::B::@constructor::•
    substitution: {T: int}
  name: SimpleIdentifier
    staticElement: self::@class::B
    staticType: null
    token: B
  typeArguments: TypeArgumentList
    arguments
      NamedType
        name: SimpleIdentifier
          staticElement: dart:core::@class::int
          staticType: null
          token: int
        type: int
    leftBracket: <
    rightBracket: >
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
''');
  }

  test_value_otherLibrary_implicitConst() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
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
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  final int f;
  const A.named(this.f);
}
''');

    newFile('$testPackageLibPath/b.dart', content: r'''
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
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  final int f;
  const A(this.f);
}
''');

    newFile('$testPackageLibPath/b.dart', content: r'''
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
    newFile('$testPackageLibPath/a.dart', content: r'''
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  constructorName: SimpleIdentifier
    staticElement: package:test/a.dart::@class::A::@getter::foo
    staticType: null
    token: foo
  element: package:test/a.dart::@class::A::@getter::foo
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: package:test/a.dart::@typeAlias::B
      staticType: null
      token: B
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@prefix::prefix
      staticType: null
      token: prefix
    staticElement: package:test/a.dart::@typeAlias::B
    staticType: null
''');
    _assertAnnotationValueText(annotation, '''
int 42
''');
  }

  test_value_prefix_typeAlias_generic_class_generic_all_inference_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  constructorName: SimpleIdentifier
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
    token: named
  element: ConstructorMember
    base: package:test/a.dart::@class::A::@constructor::named
    substitution: {T: int}
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: package:test/a.dart::@typeAlias::B
      staticType: null
      token: B
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@prefix::prefix
      staticType: null
      token: prefix
    staticElement: package:test/a.dart::@typeAlias::B
    staticType: null
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
    newFile('$testPackageLibPath/a.dart', content: r'''
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: package:test/a.dart::@class::A::@constructor::•
    substitution: {T: int}
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: package:test/a.dart::@typeAlias::B
      staticType: null
      token: B
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@prefix::prefix
      staticType: null
      token: prefix
    staticElement: package:test/a.dart::@typeAlias::B
    staticType: null
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
    newFile('$testPackageLibPath/a.dart', content: r'''
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  constructorName: SimpleIdentifier
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
    token: named
  element: ConstructorMember
    base: package:test/a.dart::@class::A::@constructor::named
    substitution: {T: int}
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: package:test/a.dart::@typeAlias::B
      staticType: null
      token: B
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@prefix::prefix
      staticType: null
      token: prefix
    staticElement: package:test/a.dart::@typeAlias::B
    staticType: null
  typeArguments: TypeArgumentList
    arguments
      NamedType
        name: SimpleIdentifier
          staticElement: dart:core::@class::int
          staticType: null
          token: int
        type: int
    leftBracket: <
    rightBracket: >
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
    newFile('$testPackageLibPath/a.dart', content: r'''
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: package:test/a.dart::@class::A::@constructor::•
    substitution: {T: int}
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: package:test/a.dart::@typeAlias::B
      staticType: null
      token: B
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@prefix::prefix
      staticType: null
      token: prefix
    staticElement: package:test/a.dart::@typeAlias::B
    staticType: null
  typeArguments: TypeArgumentList
    arguments
      NamedType
        name: SimpleIdentifier
          staticElement: dart:core::@class::int
          staticType: null
          token: int
        type: int
    leftBracket: <
    rightBracket: >
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  element: self::@class::A::@getter::foo
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: self::@class::A::@getter::foo
      staticType: null
      token: foo
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@typeAlias::B
      staticType: null
      token: B
    staticElement: self::@class::A::@getter::foo
    staticType: null
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
      DoubleLiteral
        literal: 1.2
        staticType: double
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  constructorName: SimpleIdentifier
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int, U: double}
    staticType: null
    token: named
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: int, U: double}
  name: SimpleIdentifier
    staticElement: self::@typeAlias::B
    staticType: null
    token: B
  typeArguments: TypeArgumentList
    arguments
      NamedType
        name: SimpleIdentifier
          staticElement: dart:core::@class::int
          staticType: null
          token: int
        type: int
    leftBracket: <
    rightBracket: >
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
      DoubleLiteral
        literal: 1.2
        staticType: double
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: int, U: double}
  name: SimpleIdentifier
    staticElement: self::@typeAlias::B
    staticType: null
    token: B
  typeArguments: TypeArgumentList
    arguments
      NamedType
        name: SimpleIdentifier
          staticElement: dart:core::@class::int
          staticType: null
          token: int
        type: int
    leftBracket: <
    rightBracket: >
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: int}
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
      token: named
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@typeAlias::B
      staticType: null
      token: B
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: int}
  name: SimpleIdentifier
    staticElement: self::@typeAlias::B
    staticType: null
    token: B
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  constructorName: SimpleIdentifier
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
    token: named
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: int}
  name: SimpleIdentifier
    staticElement: self::@typeAlias::B
    staticType: null
    token: B
  typeArguments: TypeArgumentList
    arguments
      NamedType
        name: SimpleIdentifier
          staticElement: dart:core::@class::int
          staticType: null
          token: int
        type: int
    leftBracket: <
    rightBracket: >
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: int}
  name: SimpleIdentifier
    staticElement: self::@typeAlias::B
    staticType: null
    token: B
  typeArguments: TypeArgumentList
    arguments
      NamedType
        name: SimpleIdentifier
          staticElement: dart:core::@class::int
          staticType: null
          token: int
        type: int
    leftBracket: <
    rightBracket: >
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::A::@constructor::named
    substitution: {T: int}
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
      token: named
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@typeAlias::B
      staticType: null
      token: B
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: ConstructorMember
    base: self::@class::A::@constructor::•
    substitution: {T: int}
  name: SimpleIdentifier
    staticElement: self::@typeAlias::B
    staticType: null
    token: B
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: self::@class::A::@constructor::named
  name: PrefixedIdentifier
    identifier: SimpleIdentifier
      staticElement: self::@class::A::@constructor::named
      staticType: null
      token: named
    period: .
    prefix: SimpleIdentifier
      staticElement: self::@typeAlias::B
      staticType: null
      token: B
    staticElement: self::@class::A::@constructor::named
    staticType: null
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
    _assertResolvedNodeText(annotation, r'''
Annotation
  arguments: ArgumentList
    arguments
      IntegerLiteral
        literal: 42
        staticType: int
    leftParenthesis: (
    rightParenthesis: )
  atSign: @
  element: self::@class::A::@constructor::•
  name: SimpleIdentifier
    staticElement: self::@typeAlias::B
    staticType: null
    token: B
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

  void _assertDartObjectText(DartObject? object, String expected) {
    var buffer = StringBuffer();
    _DartObjectPrinter(buffer).write(object as DartObjectImpl?, '');
    var actual = buffer.toString();
    if (actual != expected) {
      print(buffer);
    }
    expect(actual, expected);
  }

  void _assertElementAnnotationValueText(
    ElementAnnotation annotation,
    String expected,
  ) {
    var value = annotation.computeConstantValue();
    _assertDartObjectText(value, expected);
  }

  void _assertResolvedNodeText(AstNode node, String expected) {
    var actual = _resolvedNodeText(node);
    if (actual != expected) {
      print(actual);
    }
    expect(actual, expected);
  }

  String _resolvedNodeText(AstNode node) {
    var buffer = StringBuffer();
    node.accept(
      ResolvedAstPrinter(
        selfUriStr: result.uri.toString(),
        sink: buffer,
        indent: '',
      ),
    );
    return buffer.toString();
  }
}

class _DartObjectPrinter {
  final StringBuffer sink;

  _DartObjectPrinter(this.sink);

  void write(DartObjectImpl? object, String indent) {
    if (object != null) {
      var type = object.type;
      if (type.isDartCoreDouble) {
        sink.write('double ');
        sink.writeln(object.toDoubleValue());
      } else if (type.isDartCoreInt) {
        sink.write('int ');
        sink.writeln(object.toIntValue());
      } else if (object.isUserDefinedObject) {
        var newIndent = '$indent  ';
        var typeStr = type.getDisplayString(withNullability: true);
        sink.writeln(typeStr);
        var fields = object.fields;
        if (fields != null) {
          var sortedFields = SplayTreeMap.of(fields);
          for (var entry in sortedFields.entries) {
            sink.write(newIndent);
            sink.write('${entry.key}: ');
            write(entry.value, newIndent);
          }
        }
      } else {
        throw UnimplementedError();
      }
    } else {
      sink.writeln('<null>');
    }
  }
}
