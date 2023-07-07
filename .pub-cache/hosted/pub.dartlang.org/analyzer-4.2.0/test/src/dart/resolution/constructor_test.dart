// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorResolutionTest);
  });
}

@reflectiveTest
class ConstructorResolutionTest extends PubPackageResolutionTest {
  test_factory_redirect_generic_instantiated() async {
    await assertNoErrorsInCode(r'''
class A<T> implements B<T> {
  A(T a);
}
class B<U> {
  factory B(U a) = A<U>;
}

B<int> b = B(0);
''');
    var classB_constructor = findElement.class_('B').unnamedConstructor!;
    assertMember(
      classB_constructor.redirectedConstructor,
      findElement.unnamedConstructor('A'),
      {'T': 'U'},
    );

    var B_int = findElement.topVar('b').type as InterfaceType;
    var B_int_constructor = B_int.constructors.single;
    var B_int_redirect = B_int_constructor.redirectedConstructor!;
    assertMember(
      B_int_redirect,
      findElement.unnamedConstructor('A'),
      {'T': 'int'},
    );
    assertType(B_int_redirect.returnType, 'A<int>');
  }

  test_formalParameterScope_type() async {
    await assertNoErrorsInCode('''
class a {}

class B {
  B(a a) {
    a;
  }
}
''');

    assertElement(
      findNode.simple('a a'),
      findElement.class_('a'),
    );

    assertElement(
      findNode.simple('a;'),
      findElement.parameter('a'),
    );
  }

  test_initializer_field_functionExpression_blockBody() async {
    await resolveTestCode(r'''
class C {
  var x;
  C(int a) : x = (() {return a + 1;})();
}
''');
    assertElement(findNode.simple('a + 1'), findElement.parameter('a'));
  }

  test_initializer_field_functionExpression_expressionBody() async {
    await resolveTestCode(r'''
class C {
  final int x;
  C(int a) : x = (() => a + 1)();
}
''');
    assertElement(findNode.simple('a + 1'), findElement.parameter('a'));
  }
}
