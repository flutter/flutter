// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/test_support.dart';
import 'linter_context_impl_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResolveNameInScopeTest);
  });
}

@reflectiveTest
class ResolveNameInScopeTest extends AbstractLinterContextTest {
  @override
  Future<void> resolve(
    String content, [
    List<ExpectedError> expectedErrors = const [],
  ]) async {
    await super.resolve(content);
    assertErrorsInResolvedUnit(result, expectedErrors);
  }

  test_class_getter_different_fromExtends_thisClassSetter() async {
    await resolve('''
class A {
  int get foo => 0;
}

class B extends A {
  set foo(int _) {}

  void bar() {
    this.foo;
  }
}
''');
    _checkGetterDifferent(findElement.setter('foo'));
  }

  test_class_getter_different_importScope() async {
    newFile('$testPackageLibPath/a.dart', r'''
set foo(int _) {}
''');
    await resolve('''
import 'a.dart';

class A {
  int get foo => 0;
}

class B extends A {
  void bar() {
    this.foo;
  }
}
''', [
      error(HintCode.UNUSED_IMPORT, 7, 8),
    ]);
    var import = findElement.importFind('package:test/a.dart');
    _checkGetterDifferent(import.topSet('foo'));
  }

  test_class_getter_fromExtends_blockBody() async {
    await resolve('''
class A {
  int get foo => 0;
}

class B extends A {
  void bar(int foo) {
    this.foo;
  }
}
''');
    _checkGetterRequested(
      findElement.parameter('foo'),
    );
  }

  test_class_getter_fromExtends_expressionBody() async {
    await resolve('''
class A {
  int get foo => 0;
}

class B extends A {
  void bar(int foo) => this.foo;
}
''');
    _checkGetterRequested(
      findElement.parameter('foo'),
    );
  }

  test_class_getter_none_fromExtends() async {
    await resolve('''
class A {
  int get foo => 0;
}

class B extends A {
  void bar() {
    this.foo;
  }
}
''');
    _checkGetterNone();
  }

  test_class_getter_requested_importScope() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get foo => 0;
''');
    await resolve('''
import 'a.dart';

class A {
  int get foo => 0;
}

class B extends A {
  void bar() {
    this.foo;
  }
}
''', [
      error(HintCode.UNUSED_IMPORT, 7, 8),
    ]);
    var import = findElement.importFind('package:test/a.dart');
    _checkGetterRequested(import.topGet('foo'));
  }

  test_class_getter_requested_thisClass() async {
    await resolve('''
class A {
  int get foo => 0;

  void bar() {
    this.foo;
  }
}
''');
    _checkGetterRequested(findElement.getter('foo'));
  }

  test_class_method_different_fromExtends_topSetter() async {
    await resolve('''
class A {
  void foo() {}
}

abstract class B extends A {
  void bar() {
    this.foo();
  }
}

set foo(int _) {}
''');
    _checkMethodDifferent(findElement.topSet('foo'));
  }

  test_class_method_none_fromExtends() async {
    await resolve('''
class A {
  void foo() {}
}

class B extends A {
  void bar() {
    this.foo();
  }
}
''');
    _checkMethodNone();
  }

  test_class_method_none_fromExtension() async {
    await resolve('''
extension E on A {
  void foo() {}
}

class A {
  void bar() {
    this.foo();
  }
}
''');
    _checkMethodNone();
  }

  test_class_method_requested_formalParameter_constructor() async {
    await resolve('''
class A {
  void foo() {}

  A(int foo) {
    this.foo();
  }
}
''');
    _checkMethodRequested(findElement.parameter('foo'));
  }

  test_class_method_requested_formalParameter_method() async {
    await resolve('''
class A {
  void foo() {}

  void bar(int foo) {
    this.foo();
  }
}
''');
    _checkMethodRequested(findElement.parameter('foo'));
  }

  test_class_method_requested_fromExtends_topLevelFunction() async {
    await resolve('''
class A {
  void foo() {}
}

class B extends A {
  void bar() {
    this.foo();
  }
}

void foo() {}
''');
    _checkMethodRequested(findElement.topFunction('foo'));
  }

  test_class_method_requested_fromExtends_topLevelVariable() async {
    await resolve('''
class A {
  void foo() {}
}

abstract class B extends A {
  void bar() {
    this.foo();
  }
}

var foo = 0;
''');
    _checkMethodRequested(findElement.topGet('foo'));
  }

  test_class_method_requested_fromExtension_topLevelVariable() async {
    await resolve('''
extension E on A {
  void foo() {}
}

class A {
  void bar() {
    this.foo();
  }
}

var foo = 0;
''');
    _checkMethodRequested(findElement.topGet('foo'));
  }

  test_class_method_requested_importScope() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');
    await resolve('''
import 'a.dart';

class A {
  void foo() {}
}

class B extends A {
  void bar() {
    this.foo();
  }
}
''', [
      error(HintCode.UNUSED_IMPORT, 7, 8),
    ]);
    var import = findElement.importFind('package:test/a.dart');
    _checkMethodRequested(import.topFunction('foo'));
  }

  test_class_method_requested_localVariable_catchClause() async {
    await resolve('''
class A {
  void foo() {}

  void bar() {
    try {
     // empty
    } catch (foo) {
      this.foo();
    }
  }
}
''');
    _checkMethodRequestedLocalVariable();
  }

  test_class_method_requested_localVariable_enclosingBlock() async {
    await resolve('''
class A {
  void foo() {}

  void bar() {
    var foo = 0;
    {
      this.foo();
    }
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 50, 3),
    ]);
    _checkMethodRequestedLocalVariable();
  }

  test_class_method_requested_localVariable_forEachElement() async {
    await resolve('''
class A {
  int foo() => 0;

  List<int> bar() {
    return [ for (var foo in []) this.foo() ];
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 71, 3),
    ]);
    _checkMethodRequestedLocalVariable();
  }

  test_class_method_requested_localVariable_forEachStatement() async {
    await resolve('''
class A {
  void foo() {}

  void bar() {
    for (var foo in []) {
      this.foo();
    }
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 55, 3),
    ]);
    _checkMethodRequestedLocalVariable();
  }

  test_class_method_requested_localVariable_forLoopStatement() async {
    await resolve('''
class A {
  void foo() {}

  void bar() {
    for (var foo = 0;;) {
      this.foo();
    }
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 55, 3),
    ]);
    _checkMethodRequestedLocalVariable();
  }

  test_class_method_requested_localVariable_thisBlock_after() async {
    await resolve('''
class A {
  void foo() {}

  void bar() {
    this.foo();
    var foo = 0;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 66, 3),
    ]);
    _checkMethodRequestedLocalVariable();
  }

  test_class_method_requested_localVariable_thisBlock_before() async {
    await resolve('''
class A {
  void foo() {}

  void bar() {
    var foo = 0;
    this.foo();
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 50, 3),
    ]);
    _checkMethodRequestedLocalVariable();
  }

  test_class_method_requested_thisClass() async {
    await resolve('''
class A {
  void foo() {}

  void bar() {
    this.foo();
  }
}
''');
    _checkMethodRequested(findElement.method('foo'));
  }

  test_class_method_requested_typeParameter_method() async {
    await resolve('''
class A {
  void foo() {}

  void bar<foo>() {
    this.foo();
  }
}
''');
    _checkMethodRequested(findElement.typeParameter('foo'));
  }

  test_class_method_typeParameter() async {
    await resolve('''
class A {
  void foo<T>(int T) {}
}
''');
    var node = findNode.simpleFormalParameter('T)');
    _resultRequested(node, 'T', false, findElement.typeParameter('T'));
  }

  test_class_setter_different_formalParameter_constructor() async {
    await resolve('''
class A {
  set foo(int _) {}

  A(int foo) {
    this.foo = 0;
  }
}
''');
    _checkSetterDifferent(findElement.parameter('foo'));
  }

  test_class_setter_different_fromExtends_topLevelFunction() async {
    await resolve('''
class A {
  set foo(int _) {}
}

class B extends A {
  void bar() {
    this.foo = 0;
  }
}

void foo() {}
''');
    _checkSetterDifferent(findElement.topFunction('foo'));
  }

  test_class_setter_different_fromExtends_topLevelGetter() async {
    await resolve('''
class A {
  set foo(int _) {}
}

class B extends A {
  void bar() {
    this.foo = 0;
  }
}

int get foo => 0;
''');
    _checkSetterDifferent(findElement.topGet('foo'));
  }

  test_class_setter_none_fromExtends() async {
    await resolve('''
class A {
  set foo(int _) {}
}

class B extends A {
  void bar() {
    this.foo = 0;
  }
}
''');
    _checkSetterNone();
  }

  test_class_setter_requested_fromExtends_topLevelVariable() async {
    await resolve('''
class A {
  set foo(int _) {}
}

class B extends A {
  void bar() {
    this.foo = 0;
  }
}

var foo = 0;
''');
    _checkSetterRequested(findElement.topSet('foo'));
  }

  test_class_setter_requested_importScope() async {
    newFile('$testPackageLibPath/a.dart', r'''
set foo(int _) {}
''');
    await resolve('''
import 'a.dart';

class A {
  set foo(int _) {}
}

class B extends A {
  void bar() {
    this.foo = 0;
  }
}
''', [
      error(HintCode.UNUSED_IMPORT, 7, 8),
    ]);
    var import = findElement.importFind('package:test/a.dart');
    _checkSetterRequested(import.topSet('foo'));
  }

  test_class_setter_requested_thisClass() async {
    await resolve('''
class A {
  set foo(int _) {}

  void bar() {
    this.foo = 0;
  }
}
''');
    _checkSetterRequested(findElement.setter('foo'));
  }

  test_class_setter_requested_thisClass_topLevelFunction() async {
    await resolve('''
class A {
  set foo(int _) {}

  void bar() {
    this.foo = 0;
  }
}

void foo() {}
''');
    _checkSetterRequested(findElement.setter('foo'));
  }

  test_class_typeParameter_inConstructor() async {
    await resolve('''
class A<T> {
  A(int T) {}
}
''');
    var node = findNode.simpleFormalParameter('T)');
    _resultRequested(node, 'T', false, findElement.typeParameter('T'));
  }

  test_class_typeParameter_inField() async {
    await resolve('''
class A<T> {
  T? a;
}
''');
    var node = findNode.simple('T?');
    _resultRequested(node, 'T', false, findElement.typeParameter('T'));
  }

  test_class_typeParameter_inMethod() async {
    await resolve('''
class A<T> {
  void foo(int T) {}
}
''');
    var node = findNode.simpleFormalParameter('T)');
    _resultRequested(node, 'T', false, findElement.typeParameter('T'));
  }

  test_class_typeParameter_inSetter() async {
    await resolve('''
class A<T> {
  set foo(int T) {}
}
''');
    var node = findNode.simpleFormalParameter('T)');
    _resultRequested(node, 'T', false, findElement.typeParameter('T'));
  }

  test_extension_method_none_fromExtended() async {
    await resolve('''
class A {
  void foo() {}
}

extension on A {
  void bar() {
    this.foo();
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 53, 3),
    ]);
    _checkMethodNone();
  }

  test_extension_method_requested_formalParameter_method() async {
    await resolve('''
class A {}

extension on A {
  void foo() {}

  void bar(int foo) {
    this.foo();
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 53, 3),
    ]);
    _checkMethodRequested(findElement.parameter('foo'));
  }

  test_extension_method_requested_fromExtended_topLevelVariable() async {
    await resolve('''
class A {
  void foo() {}
}

extension on A {
  void bar() {
    this.foo();
  }
}

var foo = 0;
''', [
      error(HintCode.UNUSED_ELEMENT, 53, 3),
    ]);
    _checkMethodRequested(findElement.topGet('foo'));
  }

  test_extension_method_requested_fromThisExtension() async {
    await resolve('''
class A {}

extension on A {
  void foo() {}

  void bar() {
    this.foo();
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 53, 3),
    ]);
    _checkMethodRequested(findElement.method('foo'));
  }

  test_extension_typeParameter_inMethod() async {
    await resolve('''
extension E<T> on int {
  void foo(int T) {}
}
''');
    var node = findNode.simpleFormalParameter('T)');
    _resultRequested(node, 'T', false, findElement.typeParameter('T'));
  }

  test_function_typeParameter() async {
    await resolve('''
void foo<T>(int T) {}
''');
    var node = findNode.simpleFormalParameter('T)');
    _resultRequested(node, 'T', false, findElement.typeParameter('T'));
  }

  test_genericFunctionType_typeParameter() async {
    await resolve('''
void foo(void Function<T>(String T) b) {}
''');
    var node = findNode.simpleFormalParameter('T)');
    var T = findNode.typeParameter('T>').declaredElement!;
    _resultRequested(node, 'T', false, T);
  }

  test_genericTypeAlias_typeParameter() async {
    await resolve('''
typedef A<T> = List<T>;
''');
    var node = findNode.simple('T>;');
    _resultRequested(node, 'T', false, findElement.typeParameter('T'));
  }

  test_mixin_method_requested_formalParameter_method() async {
    await resolve('''
mixin M {
  void foo() {}

  void bar(int foo) {
    this.foo();
  }
}
''');
    _checkMethodRequested(findElement.parameter('foo'));
  }

  test_mixin_method_requested_thisClass() async {
    await resolve('''
mixin M {
  void foo() {}

  void bar() {
    this.foo();
  }
}
''');
    _checkMethodRequested(findElement.method('foo'));
  }

  test_mixin_typeParameter_inField() async {
    await resolve('''
mixin A<T> {
  T? a;
}
''');
    var node = findNode.simple('T?');
    _resultRequested(node, 'T', false, findElement.typeParameter('T'));
  }

  test_mixin_typeParameter_inMethod() async {
    await resolve('''
mixin A<T> {
  void foo(int T) {}
}
''');
    var node = findNode.simpleFormalParameter('T)');
    _resultRequested(node, 'T', false, findElement.typeParameter('T'));
  }

  void _checkGetterDifferent(Element expected) {
    var node = findNode.this_('this.foo;');
    _resultDifferent(node, 'foo', false, expected);
  }

  void _checkGetterNone() {
    var node = findNode.this_('this.foo;');
    _resultNone(node, 'foo', false);
  }

  void _checkGetterRequested(Element expected) {
    var node = findNode.this_('this.foo;');
    _resultRequested(node, 'foo', false, expected);
  }

  void _checkMethodDifferent(Element expected) {
    var node = findNode.this_('this.foo()');
    _resultDifferent(node, 'foo', false, expected);
  }

  void _checkMethodNone() {
    var node = findNode.this_('this.foo()');
    _resultNone(node, 'foo', false);
  }

  void _checkMethodRequested(Element expected) {
    var node = findNode.this_('this.foo()');
    _resultRequested(node, 'foo', false, expected);
  }

  void _checkMethodRequestedLocalVariable() {
    _checkMethodRequested(findElement.localVar('foo'));
  }

  void _checkSetterDifferent(Element expected) {
    var node = findNode.this_('this.foo = 0;');
    _resultDifferent(node, 'foo', true, expected);
  }

  void _checkSetterNone() {
    var node = findNode.this_('this.foo = 0;');
    _resultNone(node, 'foo', true);
  }

  void _checkSetterRequested(Element expected) {
    var node = findNode.this_('this.foo = 0;');
    _resultRequested(node, 'foo', true, expected);
  }

  void _resultDifferent(AstNode node, String id, bool setter, Element element) {
    var result = context.resolveNameInScope(id, setter, node);
    if (!result.isDifferentName || result.element != element) {
      fail('Expected different $element, actual: $result');
    }
  }

  void _resultNone(AstNode node, String id, bool setter) {
    var result = context.resolveNameInScope(id, setter, node);
    if (!result.isNone) {
      fail('Expected none, actual: $result');
    }
  }

  void _resultRequested(AstNode node, String id, bool setter, Element element) {
    var result = context.resolveNameInScope(id, setter, node);
    if (!result.isRequestedName || result.element != element) {
      fail('Expected requested $element, actual: $result');
    }
  }
}
