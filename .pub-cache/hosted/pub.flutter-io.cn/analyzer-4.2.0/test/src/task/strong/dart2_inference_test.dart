// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/function_ast_visitor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(Dart2InferenceTest);
  });
}

/// Tests for Dart2 inference rules back-ported from FrontEnd.
///
/// https://github.com/dart-lang/sdk/issues/31638
@reflectiveTest
class Dart2InferenceTest extends PubPackageResolutionTest {
  test_bool_assert() async {
    var code = r'''
T f<T>(int _) => null;

main() {
  assert(f(1));
  assert(f(2), f(3));
}

class C {
  C() : assert(f(4)),
        assert(f(5), f(6));
}
''';
    await resolveTestCode(code);
    MethodInvocation invocation(String search) {
      return findNode.methodInvocation(search);
    }

    assertInvokeType(invocation('f(1));'), 'bool Function(int)');

    assertInvokeType(invocation('f(2)'), 'bool Function(int)');
    assertInvokeType(invocation('f(3)'), 'dynamic Function(int)');

    assertInvokeType(invocation('f(4)'), 'bool Function(int)');

    assertInvokeType(invocation('f(5)'), 'bool Function(int)');
    assertInvokeType(invocation('f(6)'), 'dynamic Function(int)');
  }

  test_bool_logical() async {
    var code = r'''
T f<T>() => null;

var v1 = f() || f(); // 1
var v2 = f() && f(); // 2

main() {
  var v1 = f() || f(); // 3
  var v2 = f() && f(); // 4
}
''';
    await resolveTestCode(code);
    void assertType(String prefix) {
      var invocation = findNode.methodInvocation(prefix);
      assertInvokeType(invocation, 'bool Function()');
    }

    assertType('f() || f(); // 1');
    assertType('f(); // 1');
    assertType('f() && f(); // 2');
    assertType('f(); // 2');

    assertType('f() || f(); // 3');
    assertType('f(); // 3');
    assertType('f() && f(); // 4');
    assertType('f(); // 4');
  }

  test_bool_statement() async {
    var code = r'''
T f<T>() => null;

main() {
  while (f()) {} // 1
  do {} while (f()); // 2
  if (f()) {} // 3
  for (; f(); ) {} // 4
}
''';
    await resolveTestCode(code);
    void assertType(String prefix) {
      var invocation = findNode.methodInvocation(prefix);
      assertInvokeType(invocation, 'bool Function()');
    }

    assertType('f()) {} // 1');
    assertType('f());');
    assertType('f()) {} // 3');
    assertType('f(); ) {} // 4');
  }

  test_closure_downwardReturnType_arrow() async {
    var code = r'''
void main() {
  List<int> Function() g;
  g = () => 42;
}
''';
    await resolveTestCode(code);
    Expression closure = findNode.expression('() => 42');
    assertType(closure, 'List<int> Function()');
  }

  test_closure_downwardReturnType_block() async {
    var code = r'''
void main() {
  List<int> Function() g;
  g = () { // mark
    return 42;
  };
}
''';
    await resolveTestCode(code);
    Expression closure = findNode.expression('() { // mark');
    assertType(closure, 'List<int> Function()');
  }

  test_compoundAssignment_simpleIdentifier_topLevel() async {
    await assertErrorsInCode(r'''
class A {}

class B extends A {
  B operator +(int i) => this;
}

B get topLevel => new B();

void set topLevel(A value) {}

main() {
  var /*@type=B*/ v = topLevel += 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 152, 1),
    ]);
    _assertTypeAnnotations();
  }

  test_forIn_identifier() async {
    var code = r'''
T f<T>() => null;

class A {}

A aTopLevel;
void set aTopLevelSetter(A value) {}

class C {
  A aField;
  void set aSetter(A value) {}
  void test() {
    A aLocal;
    for (aLocal in f()) {} // local
    for (aField in f()) {} // field
    for (aSetter in f()) {} // setter
    for (aTopLevel in f()) {} // top variable
    for (aTopLevelSetter in f()) {} // top setter
  }
}''';
    await resolveTestCode(code);
    void assertInvocationType(String prefix) {
      var invocation = findNode.methodInvocation(prefix);
      assertType(invocation, 'Iterable<A>');
    }

    assertInvocationType('f()) {} // local');
    assertInvocationType('f()) {} // field');
    assertInvocationType('f()) {} // setter');
    assertInvocationType('f()) {} // top variable');
    assertInvocationType('f()) {} // top setter');
  }

  test_forIn_variable_implicitlyTyped() async {
    var code = r'''
class A {}
class B extends A {}

List<T> f<T extends A>(List<T> items) => items;

void test(List<A> listA, List<B> listB) {
  for (var a1 in f(listA)) {} // 1
  for (A a2 in f(listA)) {} // 2
  for (var b1 in f(listB)) {} // 3
  for (A b2 in f(listB)) {} // 4
  for (B b3 in f(listB)) {} // 5
}
''';
    await resolveTestCode(code);
    void assertTypes(
        String vSearch, String vType, String fSearch, String fType) {
      var node = findNode.simple(vSearch);

      var element = node.staticElement as LocalVariableElement;
      assertType(element.type, vType);

      var invocation = findNode.methodInvocation(fSearch);
      assertType(invocation, fType);
    }

    assertTypes('a1 in', 'A', 'f(listA)) {} // 1', 'List<A>');
    assertTypes('a2 in', 'A', 'f(listA)) {} // 2', 'List<A>');
    assertTypes('b1 in', 'B', 'f(listB)) {} // 3', 'List<B>');
    assertTypes('b2 in', 'A', 'f(listB)) {} // 4', 'List<A>');
    assertTypes('b3 in', 'B', 'f(listB)) {} // 5', 'List<B>');
  }

  test_implicitVoidReturnType_default() async {
    var code = r'''
class C {
  set x(_) {}
  operator []=(int index, double value) => null;
}
''';
    await resolveTestCode(code);
    ClassElement c = findElement.class_('C');

    PropertyAccessorElement x = c.accessors[0];
    expect(x.returnType, VoidTypeImpl.instance);

    MethodElement operator = c.methods[0];
    expect(operator.displayName, '[]=');
    expect(operator.returnType, VoidTypeImpl.instance);
  }

  test_implicitVoidReturnType_derived() async {
    var code = r'''
class Base {
  dynamic set x(_) {}
  dynamic operator[]=(int x, int y) => null;
}
class Derived extends Base {
  set x(_) {}
  operator[]=(int x, int y) {}
}''';
    await resolveTestCode(code);
    ClassElement c = findElement.class_('Derived');

    PropertyAccessorElement x = c.accessors[0];
    expect(x.returnType, VoidTypeImpl.instance);

    MethodElement operator = c.methods[0];
    expect(operator.displayName, '[]=');
    expect(operator.returnType, VoidTypeImpl.instance);
  }

  test_listMap_empty() async {
    var code = r'''
var x = [];
var y = {};
''';
    await resolveTestCode(code);
    var xNode = findNode.simple('x = ');
    var xElement = xNode.staticElement as VariableElement;
    assertType(xElement.type, 'List<dynamic>');

    var yNode = findNode.simple('y = ');
    var yElement = yNode.staticElement as VariableElement;
    assertType(yElement.type, 'Map<dynamic, dynamic>');
  }

  test_listMap_null() async {
    var code = r'''
var x = [null];
var y = {null: null};
''';
    await resolveTestCode(code);
    var xNode = findNode.simple('x = ');
    var xElement = xNode.staticElement as VariableElement;
    assertType(xElement.type, 'List<Null>');

    var yNode = findNode.simple('y = ');
    var yElement = yNode.staticElement as VariableElement;
    assertType(yElement.type, 'Map<Null, Null>');
  }

  test_switchExpression_asContext_forCases() async {
    var code = r'''
class C<T> {
  const C();
}

void test(C<int> x) {
  switch (x) {
    case const C():
      break;
    default:
      break;
  }
}''';
    await resolveTestCode(code);
    var node = findNode.instanceCreation('const C():');
    assertType(node, 'C<int>');
  }

  test_voidType_method() async {
    var code = r'''
class C {
  void m() {}
}
var x = new C().m();
main() {
  var y = new C().m();
}
''';
    await resolveTestCode(code);
    var xNode = findNode.simple('x = ');
    var xElement = xNode.staticElement as VariableElement;
    expect(xElement.type, VoidTypeImpl.instance);

    var yNode = findNode.simple('y = ');
    var yElement = yNode.staticElement as VariableElement;
    expect(yElement.type, VoidTypeImpl.instance);
  }

  test_voidType_topLevelFunction() async {
    var code = r'''
void f() {}
var x = f();
main() {
  var y = f();
}
''';
    await resolveTestCode(code);
    var xNode = findNode.simple('x = ');
    var xElement = xNode.staticElement as VariableElement;
    expect(xElement.type, VoidTypeImpl.instance);

    var yNode = findNode.simple('y = ');
    var yElement = yNode.staticElement as VariableElement;
    expect(yElement.type, VoidTypeImpl.instance);
  }

  void _assertTypeAnnotations() {
    var code = result.content;
    var unit = result.unit;

    var types = <int, String>{};
    {
      int lastIndex = 0;
      while (true) {
        const prefix = '/*@type=';
        int openIndex = code.indexOf(prefix, lastIndex);
        if (openIndex == -1) {
          break;
        }
        int closeIndex = code.indexOf('*/', openIndex + 1);
        expect(closeIndex, isPositive);
        types[openIndex] =
            code.substring(openIndex + prefix.length, closeIndex);
        lastIndex = closeIndex;
      }
    }

    unit.accept(FunctionAstVisitor(
      simpleIdentifier: (node) {
        var comment = node.token.precedingComments;
        if (comment != null) {
          var expectedType = types[comment.offset];
          if (expectedType != null) {
            var element = node.staticElement as VariableElement;
            String actualType = typeString(element.type);
            expect(actualType, expectedType, reason: '@${comment.offset}');
          }
        }
      },
    ));
  }
}
