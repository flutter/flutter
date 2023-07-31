// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/referenced_names.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ComputeReferencedNamesTest);
    defineReflectiveTests(ComputeSubtypedNamesTest);
  });
}

@reflectiveTest
class ComputeReferencedNamesTest extends ParserTestCase {
  test_class_constructor() {
    Set<String> names = _computeReferencedNames('''
class U {
  U.named(A a, B b) {
    C c = null;
  }
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_class_constructor_parameters() {
    Set<String> names = _computeReferencedNames('''
class U {
  U(A a) {
    a;
    b;
  }
}
''');
    expect(names, unorderedEquals(['A', 'b']));
  }

  test_class_field() {
    Set<String> names = _computeReferencedNames('''
class U {
  A f = new B();
}
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_class_getter() {
    Set<String> names = _computeReferencedNames('''
class U {
  A get a => new B();
}
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_class_members() {
    Set<String> names = _computeReferencedNames('''
class U {
  int a;
  int get b;
  set c(_) {}
  m(D d) {
    a;
    b;
    c = 1;
    m();
  }
}
''');
    expect(names, unorderedEquals(['int', 'D']));
  }

  test_class_members_dontHideQualified() {
    Set<String> names = _computeReferencedNames('''
class U {
  int a;
  int get b;
  set c(_) {}
  m(D d) {
    d.a;
    d.b;
    d.c;
  }
}
''');
    expect(names, unorderedEquals(['int', 'D', 'a', 'b', 'c']));
  }

  test_class_method() {
    Set<String> names = _computeReferencedNames('''
class U {
  A m(B p) {
    C v = 0;
  }
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_class_method_localVariables() {
    Set<String> names = _computeReferencedNames('''
class U {
  A m() {
    B b = null;
    b;
    {
      C c = null;
      b;
      c;
    }
    d;
  }
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'd']));
  }

  test_class_method_parameters() {
    Set<String> names = _computeReferencedNames('''
class U {
  m(A a) {
    a;
    b;
  }
}
''');
    expect(names, unorderedEquals(['A', 'b']));
  }

  test_class_method_parameters_dontHideNamedExpressionName() {
    Set<String> names = _computeReferencedNames('''
main() {
  var p;
  new C(p: p);
}
''');
    expect(names, unorderedEquals(['C', 'p']));
  }

  test_class_method_typeParameters() {
    Set<String> names = _computeReferencedNames('''
class U {
  A m<T>(B b, T t) {
    C c = 0;
  }
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_class_setter() {
    Set<String> names = _computeReferencedNames('''
class U {
  set a(A a) {
    B b = null;
  }
}
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_class_typeParameters() {
    Set<String> names = _computeReferencedNames('''
class U<T> {
  T f = new A<T>();
}
''');
    expect(names, unorderedEquals(['A']));
  }

  test_instantiatedNames_importPrefix() {
    Set<String> names = _computeReferencedNames('''
import 'a.dart' as p1;
import 'b.dart' as p2;
main() {
  new p1.A();
  new p1.A.c1();
  new p1.B();
  new p2.C();
  new D();
  new D.c2();
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'D', 'c1', 'c2']));
  }

  test_localFunction() {
    Set<String> names = _computeReferencedNames('''
f(A a) {
  g(B b) {}
}
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_superToSubs_importPrefix() {
    Set<String> names = _computeReferencedNames('''
import 'a.dart' as p1;
import 'b.dart' as p2;
class U extends p1.A with p2.B implements p2.C {}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_topLevelVariable() {
    Set<String> names = _computeReferencedNames('''
A v = new B(c);
''');
    expect(names, unorderedEquals(['A', 'B', 'c']));
  }

  test_topLevelVariable_multiple() {
    Set<String> names = _computeReferencedNames('''
A v1 = new B(c), v2 = new D<E>(f);
''');
    expect(names, unorderedEquals(['A', 'B', 'c', 'D', 'E', 'f']));
  }

  test_unit_classTypeAlias() {
    Set<String> names = _computeReferencedNames('''
class U = A with B implements C;
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_unit_classTypeAlias_typeParameters() {
    Set<String> names = _computeReferencedNames('''
class U<T1, T2 extends D> = A<T1> with B<T2> implements C<T1, T2>;
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'D']));
  }

  test_unit_function() {
    Set<String> names = _computeReferencedNames('''
A f(B b) {
  C c = 0;
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_unit_function_doc() {
    Set<String> names = _computeReferencedNames('''
/**
 * Documentation [C.d] reference.
 */
A f(B b) {}
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'd']));
  }

  test_unit_function_dontHideQualified() {
    Set<String> names = _computeReferencedNames('''
class U {
  int a;
  int get b;
  set c(_) {}
  m(D d) {
    d.a;
    d.b;
    d.c;
  }
}
''');
    expect(names, unorderedEquals(['int', 'D', 'a', 'b', 'c']));
  }

  test_unit_function_localFunction_parameter() {
    Set<String> names = _computeReferencedNames('''
A f() {
  B g(x) {
    x;
    return null;
  }
  return null;
}
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_unit_function_localFunctions() {
    Set<String> names = _computeReferencedNames('''
A f() {
  B b = null;
  C g() {}
  g();
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_unit_function_localsDontHideQualified() {
    Set<String> names = _computeReferencedNames('''
f(A a, B b) {
  var v = 0;
  a.v;
  a.b;
}
''');
    expect(names, unorderedEquals(['A', 'B', 'v', 'b']));
  }

  test_unit_function_localVariables() {
    Set<String> names = _computeReferencedNames('''
A f() {
  B b = null;
  b;
  {
    C c = null;
    b;
    c;
  }
  d;
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'd']));
  }

  test_unit_function_parameters() {
    Set<String> names = _computeReferencedNames('''
A f(B b) {
  C c = 0;
  b;
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_unit_function_parameters_dontHideQualified() {
    Set<String> names = _computeReferencedNames('''
f(x, C g()) {
  g().x;
}
''');
    expect(names, unorderedEquals(['C', 'x']));
  }

  test_unit_function_typeParameters() {
    Set<String> names = _computeReferencedNames('''
A f<T>(B b, T t) {
  C c = 0;
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  test_unit_functionTypeAlias() {
    Set<String> names = _computeReferencedNames('''
typedef A F(B B, C c(D d));
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'D']));
  }

  test_unit_functionTypeAlias_typeParameters() {
    Set<String> names = _computeReferencedNames('''
typedef A F<T>(B b, T t);
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_unit_getter() {
    Set<String> names = _computeReferencedNames('''
A get aaa {
  return new B();
}
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_unit_setter() {
    Set<String> names = _computeReferencedNames('''
set aaa(A a) {
  B b = null;
}
''');
    expect(names, unorderedEquals(['A', 'B']));
  }

  test_unit_topLevelDeclarations() {
    Set<String> names = _computeReferencedNames('''
class L1 {}
class L2 = A with B implements C;
A L3() => null;
typedef A L4(B b);
A get L5 => null;
set L6(_) {}
A L7, L8;
main() {
  L1;
  L2;
  L3;
  L4;
  L5;
  L6;
  L7;
  L8;
}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  Set<String> _computeReferencedNames(String code) {
    CompilationUnit unit = parseCompilationUnit2(code);
    return computeReferencedNames(unit);
  }
}

@reflectiveTest
class ComputeSubtypedNamesTest extends ParserTestCase {
  void test_classDeclaration() {
    Set<String> names = _computeSubtypedNames('''
import 'lib.dart';
class X extends A {}
class Y extends A with B {}
class Z implements A, B, C {}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  void test_classTypeAlias() {
    Set<String> names = _computeSubtypedNames('''
import 'lib.dart';
class X = A with B implements C, D, E;
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'D', 'E']));
  }

  void test_mixinDeclaration() {
    Set<String> names = _computeSubtypedNames('''
import 'lib.dart';
mixin M on A, B implements C, D {}
''');
    expect(names, unorderedEquals(['A', 'B', 'C', 'D']));
  }

  void test_prefixed() {
    Set<String> names = _computeSubtypedNames('''
import 'lib.dart' as p;
class X extends p.A with p.B implements p.C {}
''');
    expect(names, unorderedEquals(['A', 'B', 'C']));
  }

  void test_typeArguments() {
    Set<String> names = _computeSubtypedNames('''
import 'lib.dart';
class X extends A<B> {}
''');
    expect(names, unorderedEquals(['A']));
  }

  Set<String> _computeSubtypedNames(String code) {
    CompilationUnit unit = parseCompilationUnit2(code);
    return computeSubtypedNames(unit);
  }
}
