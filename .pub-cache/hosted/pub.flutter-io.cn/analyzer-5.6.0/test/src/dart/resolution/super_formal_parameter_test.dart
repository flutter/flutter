// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperFormalParameterTest);
  });
}

@reflectiveTest
class SuperFormalParameterTest extends PubPackageResolutionTest {
  test_element_typeParameterSubstitution_chained() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A({int? key});
}

class B<U> extends A<U> {
  B({super.key});
}

class C<V> extends B<V> {
  C({super.key});
}
''');

    final C = findElement.unnamedConstructor('C');
    final C_key = C.superFormalParameter('key');

    final B_key_member = C_key.superConstructorParameter;
    B_key_member as SuperFormalParameterMember;

    final B = findElement.unnamedConstructor('B');
    final B_key = B.superFormalParameter('key');
    assertElement2(
      B_key_member,
      declaration: B_key,
      substitution: {'U': 'V'},
    );

    final A_key_member = B_key_member.superConstructorParameter;
    A_key_member as ParameterMember;

    final A = findElement.unnamedConstructor('A');
    final A_key = A.parameter('key');
    assertElement2(
      A_key_member,
      declaration: A_key,
      substitution: {
        'T': 'V',
        'U': 'V',
      },
    );
  }

  test_functionTyped() async {
    await assertNoErrorsInCode(r'''
class A {
  A(Object a);
}

class B extends A {
  B(T super.a<T>(int b));
}
''');

    final node = findNode.superFormalParameter('super.');
    assertResolvedNodeText(node, r'''
SuperFormalParameter
  type: NamedType
    name: SimpleIdentifier
      token: T
      staticElement: T@62
      staticType: null
    type: T
  superKeyword: super
  period: .
  name: a
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredElement: T@62
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
      name: b
      declaredElement: self::@class::B::@constructor::new::@parameter::a::@parameter::b
      declaredElementType: int
    rightParenthesis: )
  declaredElement: self::@class::B::@constructor::new::@parameter::a
  declaredElementType: T Function<T>(int)
''');
  }

  test_invalid_notConstructor() async {
    await assertErrorsInCode(r'''
void f(super.a) {}
''', [
      error(CompileTimeErrorCode.INVALID_SUPER_FORMAL_PARAMETER_LOCATION, 7, 5),
    ]);

    final node = findNode.superFormalParameter('super.');
    assertResolvedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: a
  declaredElement: self::@function::f::@parameter::a
  declaredElementType: dynamic
''');
  }

  test_optionalNamed() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? a});
}

class B extends A {
  B({super.a});
}
''');

    final node = findNode.superFormalParameter('super.');
    assertResolvedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: a
  declaredElement: self::@class::B::@constructor::new::@parameter::a
  declaredElementType: int?
''');
  }

  test_optionalPositional() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? a]);
}

class B extends A {
  B([super.a]);
}
''');

    final node = findNode.superFormalParameter('super.');
    assertResolvedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: a
  declaredElement: self::@class::B::@constructor::new::@parameter::a
  declaredElementType: int?
''');
  }

  test_requiredNamed() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int a});
}

class B extends A {
  B({required super.a});
}
''');

    final node = findNode.superFormalParameter('super.');
    assertResolvedNodeText(node, r'''
SuperFormalParameter
  requiredKeyword: required
  superKeyword: super
  period: .
  name: a
  declaredElement: self::@class::B::@constructor::new::@parameter::a
  declaredElementType: int
''');
  }

  test_requiredPositional() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

class B extends A {
  B(super.a);
}
''');

    final node = findNode.superFormalParameter('super.');
    assertResolvedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: a
  declaredElement: self::@class::B::@constructor::new::@parameter::a
  declaredElementType: int
''');
  }

  test_scoping_inBody() async {
    await assertNoErrorsInCode(r'''
class A {
  final int a;
  A(this.a);
}

class B extends A {
  B(super.a) {
    a; // ref
  }
}
''');

    final node = findNode.simple('a; // ref');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  staticElement: self::@class::A::@getter::a
  staticType: int
''');
  }

  test_scoping_inInitializer() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

class B extends A {
  var f;
  B(super.a) : f = ((){ a; });
}
''');

    final node = findNode.simple('a; }');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  staticElement: self::@class::B::@constructor::new::@parameter::a
  staticType: int
''');
  }
}
