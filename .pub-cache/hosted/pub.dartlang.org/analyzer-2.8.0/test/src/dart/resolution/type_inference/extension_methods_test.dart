// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';
import '../resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionMethodsTest);
  });
}

@reflectiveTest
class ExtensionMethodsTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, ExtensionMethodsTestCases {}

mixin ExtensionMethodsTestCases on ResolutionTest {
  test_implicit_getter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  List<T> get foo => <T>[];
}

void f(A<int> a) {
  a.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('.foo');
    assertMember(
      prefixedIdentifier,
      findElement.getter('foo', of: 'E'),
      {'T': 'int'},
    );
    assertType(prefixedIdentifier, 'List<int>');
  }

  test_implicit_method() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  a.foo(1.0);
}
''');
    // TODO(scheglov) We need to instantiate "foo" fully.
    var invocation = findNode.methodInvocation('foo(1.0)');
    assertMember(
      invocation,
      findElement.method('foo', of: 'E'),
      {'T': 'int'},
    );
//    assertMember(
//      invocation,
//      findElement.method('foo', of: 'E'),
//      {'T': 'int', 'U': 'double'},
//    );
    assertInvokeType(invocation, 'Map<int, double> Function(double)');
    assertType(invocation, 'Map<int, double>');
  }

  test_implicit_method_internal() async {
    await assertNoErrorsInCode(r'''
extension E<T> on List<T> {
  List<T> foo() => this;
  List<T> bar(List<T> other) => other.foo();
}
''');
    assertMethodInvocation2(
      findNode.methodInvocation('other.foo()'),
      element: elementMatcher(
        findElement.method('foo'),
        substitution: {'T': 'T'},
      ),
      typeArgumentTypes: [],
      invokeType: 'List<T> Function()',
      type: 'List<T>',
    );
  }

  test_implicit_method_onTypeParameter() async {
    await assertNoErrorsInCode('''
extension E<T> on T {
  Map<T, U> foo<U>(U value) => <T, U>{};
}

void f(String a) {
  a.foo(0);
}
''');
    // TODO(scheglov) We need to instantiate "foo" fully.
    var invocation = findNode.methodInvocation('foo(0)');
    assertMember(
      invocation,
      findElement.method('foo', of: 'E'),
      {'T': 'String'},
    );
//    assertMember(
//      invocation,
//      findElement.method('foo', of: 'E'),
//      {'T': 'int', 'U': 'double'},
//    );
    assertInvokeType(invocation, 'Map<String, int> Function(int)');
    assertType(invocation, 'Map<String, int>');
  }

  test_implicit_method_tearOff() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  a.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('foo;');
    assertMember(
      prefixedIdentifier,
      findElement.method('foo', of: 'E'),
      {'T': 'int'},
    );
    assertType(prefixedIdentifier, 'Map<int, U> Function<U>(U)');
  }

  test_implicit_setter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  set foo(T value) {}
}

void f(A<int> a) {
  a.foo = 0;
}
''');
    var propertyAccess = findNode.prefixed('.foo =');

    assertAssignment(
      findNode.assignment('foo ='),
      readElement: null,
      readType: null,
      writeElement: elementMatcher(
        findElement.setter('foo', of: 'E'),
        substitution: {'T': 'int'},
      ),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );

    if (hasAssignmentLeftResolution) {
      assertMember(
        propertyAccess,
        findElement.setter('foo', of: 'E'),
        {'T': 'int'},
      );
    }
  }

  test_implicit_targetTypeParameter_hasBound_methodInvocation() async {
    await assertNoErrorsInCode('''
extension Test<T> on T {
  T Function(T) test() => throw 0;
}

void f<S extends num>(S x) {
  x.test();
}
''');

    if (result.libraryElement.isNonNullableByDefault) {
      assertMethodInvocation2(
        findNode.methodInvocation('test();'),
        element: elementMatcher(
          findElement.method('test'),
          substitution: {'T': 'S'},
        ),
        typeArgumentTypes: [],
        invokeType: 'S Function(S) Function()',
        type: 'S Function(S)',
      );
    } else {
      assertMethodInvocation2(
        findNode.methodInvocation('test();'),
        element: elementMatcher(
          findElement.method('test'),
          substitution: {'T': 'num'},
        ),
        typeArgumentTypes: [],
        invokeType: 'num Function(num) Function()',
        type: 'num Function(num)',
      );
    }
  }

  test_implicit_targetTypeParameter_hasBound_propertyAccess_getter() async {
    await assertNoErrorsInCode('''
extension Test<T> on T {
  T Function(T) get test => throw 0;
}

void f<S extends num>(S x) {
  (x).test;
}
''');

    if (result.libraryElement.isNonNullableByDefault) {
      assertPropertyAccess2(
        findNode.propertyAccess('.test'),
        element: elementMatcher(
          findElement.getter('test'),
          substitution: {'T': 'S'},
        ),
        type: 'S Function(S)',
      );
    } else {
      assertPropertyAccess2(
        findNode.propertyAccess('.test'),
        element: elementMatcher(
          findElement.getter('test'),
          substitution: {'T': 'num'},
        ),
        type: 'num Function(num)',
      );
    }
  }

  test_implicit_targetTypeParameter_hasBound_propertyAccess_setter() async {
    await assertNoErrorsInCode('''
extension Test<T> on T {
  void set test(T _) {}
}

T g<T>() => throw 0;

void f<S extends num>(S x) {
  (x).test = g();
}
''');

    if (result.libraryElement.isNonNullableByDefault) {
      assertAssignment(
        findNode.assignment('(x).test'),
        readElement: null,
        readType: null,
        writeElement: elementMatcher(
          findElement.setter('test'),
          substitution: {'T': 'S'},
        ),
        writeType: 'S',
        operatorElement: null,
        type: 'S',
      );

      if (hasAssignmentLeftResolution) {
        assertPropertyAccess2(
          findNode.propertyAccess('.test'),
          element: elementMatcher(
            findElement.setter('test'),
            substitution: {'T': 'S'},
          ),
          type: 'S',
        );
      }

      assertTypeArgumentTypes(
        findNode.methodInvocation('g()'),
        ['S'],
      );
    } else {
      assertAssignment(
        findNode.assignment('(x).test'),
        readElement: null,
        readType: null,
        writeElement: elementMatcher(
          findElement.setter('test'),
          substitution: {'T': 'num'},
        ),
        writeType: 'num',
        operatorElement: null,
        type: 'num',
      );

      if (hasAssignmentLeftResolution) {
        assertPropertyAccess2(
          findNode.propertyAccess('.test'),
          element: elementMatcher(
            findElement.setter('test'),
            substitution: {'T': 'num'},
          ),
          type: 'num',
        );
      }

      assertTypeArgumentTypes(
        findNode.methodInvocation('g()'),
        ['num'],
      );
    }
  }

  test_override_downward_hasTypeArguments() async {
    await assertNoErrorsInCode('''
extension E<T> on Set<T> {
  void foo() {}
}

main() {
  E<int>({}).foo();
}
''');
    var literal = findNode.setOrMapLiteral('{}).');
    assertType(literal, 'Set<int>');
  }

  test_override_downward_hasTypeArguments_wrongNumber() async {
    await assertErrorsInCode('''
extension E<T> on Set<T> {
  void foo() {}
}

main() {
  E<int, bool>({}).foo();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION, 58,
          11),
    ]);
    var literal = findNode.setOrMapLiteral('{}).');
    assertType(literal, 'Set<dynamic>');
  }

  test_override_downward_noTypeArguments() async {
    await assertNoErrorsInCode('''
extension E<T> on Set<T> {
  void foo() {}
}

main() {
  E({}).foo();
}
''');
    var literal = findNode.setOrMapLiteral('{}).');
    assertType(literal, 'Set<dynamic>');
  }

  test_override_hasTypeArguments_getter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  List<T> get foo => <T>[];
}

void f(A<int> a) {
  E<num>(a).foo;
}
''');
    var override = findNode.extensionOverride('E<num>(a)');
    assertElement(override, findElement.extension_('E'));
    assertElementTypes(override.typeArgumentTypes, ['num']);
    assertType(override.extendedType, 'A<num>');

    var propertyAccess = findNode.propertyAccess('.foo');
    assertMember(
      propertyAccess,
      findElement.getter('foo', of: 'E'),
      {'T': 'num'},
    );
    assertType(propertyAccess, 'List<num>');
  }

  test_override_hasTypeArguments_method() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  E<num>(a).foo(1.0);
}
''');
    var override = findNode.extensionOverride('E<num>(a)');
    assertElement(override, findElement.extension_('E'));
    assertElementTypes(override.typeArgumentTypes, ['num']);
    assertType(override.extendedType, 'A<num>');

    // TODO(scheglov) We need to instantiate "foo" fully.
    var invocation = findNode.methodInvocation('foo(1.0)');
    assertMember(
      invocation,
      findElement.method('foo', of: 'E'),
      {'T': 'num'},
    );
//    assertMember(
//      invocation,
//      findElement.method('foo', of: 'E'),
//      {'T': 'int', 'U': 'double'},
//    );
    assertInvokeType(invocation, 'Map<num, double> Function(double)');
  }

  test_override_hasTypeArguments_method_tearOff() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  E<num>(a).foo;
}
''');
    var propertyAccess = findNode.propertyAccess('foo;');
    assertMember(
      propertyAccess,
      findElement.method('foo', of: 'E'),
      {'T': 'num'},
    );
    assertType(propertyAccess, 'Map<num, U> Function<U>(U)');
  }

  test_override_hasTypeArguments_setter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  set foo(T value) {}
}

void f(A<int> a) {
  E<num>(a).foo = 1.2;
}
''');
    var override = findNode.extensionOverride('E<num>(a)');
    assertElement(override, findElement.extension_('E'));
    assertElementTypes(override.typeArgumentTypes, ['num']);
    assertType(override.extendedType, 'A<num>');

    assertAssignment(
      findNode.assignment('foo ='),
      readElement: null,
      readType: null,
      writeElement: elementMatcher(
        findElement.setter('foo', of: 'E'),
        substitution: {'T': 'num'},
      ),
      writeType: 'num',
      operatorElement: null,
      type: 'double',
    );

    if (hasAssignmentLeftResolution) {
      var propertyAccess = findNode.propertyAccess('.foo =');
      assertMember(
        propertyAccess,
        findElement.setter('foo', of: 'E'),
        {'T': 'num'},
      );
    }
  }

  test_override_inferTypeArguments_error_couldNotInfer() async {
    await assertErrorsInCode('''
extension E<T extends num> on T {
  void foo() {}
}

f(String s) {
  E(s).foo();
}
''', [
      error(CompileTimeErrorCode.COULD_NOT_INFER, 69, 1),
    ]);
    var override = findNode.extensionOverride('E(s)');
    assertElementTypes(override.typeArgumentTypes, ['String']);
    assertType(override.extendedType, 'String');
  }

  test_override_inferTypeArguments_getter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  List<T> get foo => <T>[];
}

void f(A<int> a) {
  E(a).foo;
}
''');
    var override = findNode.extensionOverride('E(a)');
    assertElement(override, findElement.extension_('E'));
    assertElementTypes(override.typeArgumentTypes, ['int']);
    assertType(override.extendedType, 'A<int>');

    var propertyAccess = findNode.propertyAccess('.foo');
    assertMember(
      propertyAccess,
      findElement.getter('foo', of: 'E'),
      {'T': 'int'},
    );
    assertType(propertyAccess, 'List<int>');
  }

  test_override_inferTypeArguments_method() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  E(a).foo(1.0);
}
''');
    var override = findNode.extensionOverride('E(a)');
    assertElement(override, findElement.extension_('E'));
    assertElementTypes(override.typeArgumentTypes, ['int']);
    assertType(override.extendedType, 'A<int>');

    // TODO(scheglov) We need to instantiate "foo" fully.
    var invocation = findNode.methodInvocation('foo(1.0)');
    assertMember(
      invocation,
      findElement.method('foo', of: 'E'),
      {'T': 'int'},
    );
//    assertMember(
//      invocation,
//      findElement.method('foo', of: 'E'),
//      {'T': 'int', 'U': 'double'},
//    );
    assertInvokeType(invocation, 'Map<int, double> Function(double)');
  }

  test_override_inferTypeArguments_method_tearOff() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  E(a).foo;
}
''');
    var override = findNode.extensionOverride('E(a)');
    assertElement(override, findElement.extension_('E'));
    assertElementTypes(override.typeArgumentTypes, ['int']);
    assertType(override.extendedType, 'A<int>');

    var propertyAccess = findNode.propertyAccess('foo;');
    assertMember(
      propertyAccess,
      findElement.method('foo', of: 'E'),
      {'T': 'int'},
    );
    assertType(propertyAccess, 'Map<int, U> Function<U>(U)');
  }

  test_override_inferTypeArguments_setter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  set foo(T value) {}
}

void f(A<int> a) {
  E(a).foo = 0;
}
''');
    var override = findNode.extensionOverride('E(a)');
    assertElement(override, findElement.extension_('E'));
    assertElementTypes(override.typeArgumentTypes, ['int']);
    assertType(override.extendedType, 'A<int>');

    assertAssignment(
      findNode.assignment('foo ='),
      readElement: null,
      readType: null,
      writeElement: elementMatcher(
        findElement.setter('foo', of: 'E'),
        substitution: {'T': 'int'},
      ),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );

    if (hasAssignmentLeftResolution) {
      var propertyAccess = findNode.propertyAccess('.foo =');
      assertMember(
        propertyAccess,
        findElement.setter('foo', of: 'E'),
        {'T': 'int'},
      );
    }
  }
}
