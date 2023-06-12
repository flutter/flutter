// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';
import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SimpleResolverTest);
  });
}

@reflectiveTest
class SimpleResolverTest extends PubPackageResolutionTest {
  test_argumentResolution_required_matching() async {
    await resolveTestCode(r'''
class A {
  void f() {
    g(1, 2, 3);
  }
  void g(a, b, c) {}
}''');
    await _validateArgumentResolution([0, 1, 2]);
  }

  test_argumentResolution_required_tooFew() async {
    await resolveTestCode(r'''
class A {
  void f() {
    g(1, 2);
  }
  void g(a, b, c) {}
}''');
    await _validateArgumentResolution([0, 1]);
  }

  test_argumentResolution_required_tooMany() async {
    await resolveTestCode(r'''
class A {
  void f() {
    g(1, 2, 3);
  }
  void g(a, b) {}
}''');
    await _validateArgumentResolution([0, 1, -1]);
  }

  test_argumentResolution_requiredAndNamed_extra() async {
    await resolveTestCode('''
class A {
  void f() {
    g(1, 2, c: 3, d: 4);
  }
  void g(a, b, {c}) {}
}''');
    await _validateArgumentResolution([0, 1, 2, -1]);
  }

  test_argumentResolution_requiredAndNamed_matching() async {
    await resolveTestCode(r'''
class A {
  void f() {
    g(1, 2, c: 3);
  }
  void g(a, b, {c}) {}
}''');
    await _validateArgumentResolution([0, 1, 2]);
  }

  test_argumentResolution_requiredAndNamed_missing() async {
    await resolveTestCode('''
class A {
  void f() {
    g(1, 2, d: 3);
  }
  void g(a, b, {c, d}) {}
}''');
    await _validateArgumentResolution([0, 1, 3]);
  }

  test_argumentResolution_requiredAndPositional_fewer() async {
    await resolveTestCode('''
class A {
  void f() {
    g(1, 2, 3);
  }
  void g(a, b, [c, d]) {}
}''');
    await _validateArgumentResolution([0, 1, 2]);
  }

  test_argumentResolution_requiredAndPositional_matching() async {
    await resolveTestCode(r'''
class A {
  void f() {
    g(1, 2, 3, 4);
  }
  void g(a, b, [c, d]) {}
}''');
    await _validateArgumentResolution([0, 1, 2, 3]);
  }

  test_argumentResolution_requiredAndPositional_more() async {
    await resolveTestCode(r'''
class A {
  void f() {
    g(1, 2, 3, 4);
  }
  void g(a, b, [c]) {}
}''');
    await _validateArgumentResolution([0, 1, 2, -1]);
  }

  test_argumentResolution_setter_propagated() async {
    await resolveTestCode(r'''
main() {
  var a = new A();
  a.sss = 0;
}
class A {
  set sss(x) {}
}''');
    var rhs = findNode.assignment(' = 0;').rightHandSide;
    expect(
      rhs.staticParameterElement,
      findElement.parameter('x'),
    );
  }

  test_argumentResolution_setter_propagated_propertyAccess() async {
    await resolveTestCode(r'''
main() {
  var a = new A();
  a.b.sss = 0;
}
class A {
  B b = new B();
}
class B {
  set sss(x) {}
}''');
    var rhs = findNode.assignment(' = 0;').rightHandSide;
    expect(
      rhs.staticParameterElement,
      findElement.parameter('x'),
    );
  }

  test_argumentResolution_setter_static() async {
    await resolveTestCode(r'''
main() {
  A a = new A();
  a.sss = 0;
}
class A {
  set sss(x) {}
}''');
    var rhs = findNode.assignment(' = 0;').rightHandSide;
    expect(
      rhs.staticParameterElement,
      findElement.parameter('x'),
    );
  }

  test_argumentResolution_setter_static_propertyAccess() async {
    await resolveTestCode(r'''
main() {
  A a = new A();
  a.b.sss = 0;
}
class A {
  B b = new B();
}
class B {
  set sss(x) {}
}''');
    var rhs = findNode.assignment(' = 0;').rightHandSide;
    expect(
      rhs.staticParameterElement,
      findElement.parameter('x'),
    );
  }

  test_breakTarget_labeled() async {
    // Verify that the target of the label is correctly found and is recorded
    // as the unlabeled portion of the statement.
    await resolveTestCode(r'''
void f() {
  loop1: while (true) {
    loop2: for (int i = 0; i < 10; i++) {
      break loop1;
      break loop2;
    }
  }
}
''');
    var break1 = findNode.breakStatement('break loop1;');
    var whileStatement = findNode.whileStatement('while (');
    expect(break1.target, same(whileStatement));

    var break2 = findNode.breakStatement('break loop2;');
    var forStatement = findNode.forStatement('for (');
    expect(break2.target, same(forStatement));
  }

  test_breakTarget_unlabeledBreakFromDo() async {
    await resolveTestCode('''
void f() {
  do {
    break;
  } while (true);
}
''');
    var doStatement = findNode.doStatement('do {');
    var breakStatement = findNode.breakStatement('break;');
    expect(breakStatement.target, same(doStatement));
  }

  test_breakTarget_unlabeledBreakFromFor() async {
    await resolveTestCode(r'''
void f() {
  for (int i = 0; i < 10; i++) {
    break;
  }
}
''');
    var forStatement = findNode.forStatement('for (');
    var breakStatement = findNode.breakStatement('break;');
    expect(breakStatement.target, same(forStatement));
  }

  test_breakTarget_unlabeledBreakFromForEach() async {
    await resolveTestCode('''
void f() {
  for (x in []) {
    break;
  }
}
''');
    var forStatement = findNode.forStatement('for (');
    var breakStatement = findNode.breakStatement('break;');
    expect(breakStatement.target, same(forStatement));
  }

  test_breakTarget_unlabeledBreakFromSwitch() async {
    await resolveTestCode(r'''
void f() {
  while (true) {
    switch (0) {
      case 0:
        break;
    }
  }
}
''');
    var switchStatement = findNode.switchStatement('switch (');
    var breakStatement = findNode.breakStatement('break;');
    expect(breakStatement.target, same(switchStatement));
  }

  test_breakTarget_unlabeledBreakFromWhile() async {
    await resolveTestCode(r'''
void f() {
  while (true) {
    break;
  }
}
''');
    var whileStatement = findNode.whileStatement('while (');
    var breakStatement = findNode.breakStatement('break;');
    expect(breakStatement.target, same(whileStatement));
  }

  test_breakTarget_unlabeledBreakToOuterFunction() async {
    // Verify that unlabeled break statements can't resolve to loops in an
    // outer function.
    await resolveTestCode(r'''
void f() {
  while (true) {
    void g() {
      break;
    }
  }
}
''');
    var breakStatement = findNode.breakStatement('break;');
    expect(breakStatement.target, isNull);
  }

  test_class_definesCall() async {
    await assertNoErrorsInCode(r'''
class A {
  int call(int x) { return x; }
}
int f(A a) {
  return a(0);
}''');
  }

  test_class_extends_implements() async {
    await assertNoErrorsInCode(r'''
class A extends B implements C {}
class B {}
class C {}''');
  }

  test_continueTarget_labeled() async {
    // Verify that the target of the label is correctly found and is recorded
    // as the unlabeled portion of the statement.
    await resolveTestCode('''
void f() {
  loop1: while (true) {
    loop2: for (int i = 0; i < 10; i++) {
      continue loop1;
      continue loop2;
    }
  }
}
''');
    var continue1 = findNode.continueStatement('continue loop1');
    var whileStatement = findNode.whileStatement('while (');
    expect(continue1.target, same(whileStatement));

    var continue2 = findNode.continueStatement('continue loop2');
    var forStatement = findNode.forStatement('for (');
    expect(continue2.target, same(forStatement));
  }

  test_continueTarget_unlabeledContinueFromDo() async {
    await resolveTestCode('''
void f() {
  do {
    continue;
  } while (true);
}
''');
    var doStatement = findNode.doStatement('do {');
    var continueStatement = findNode.continueStatement('continue;');
    expect(continueStatement.target, same(doStatement));
  }

  test_continueTarget_unlabeledContinueFromFor() async {
    await resolveTestCode('''
void f() {
  for (int i = 0; i < 10; i++) {
    continue;
  }
}
''');
    var forStatement = findNode.forStatement('for (');
    var continueStatement = findNode.continueStatement('continue;');
    expect(continueStatement.target, same(forStatement));
  }

  test_continueTarget_unlabeledContinueFromForEach() async {
    await resolveTestCode(r'''
void f() {
  for (x in []) {
    continue;
  }
}
''');
    var forStatement = findNode.forStatement('for (');
    var continueStatement = findNode.continueStatement('continue;');
    expect(continueStatement.target, same(forStatement));
  }

  test_continueTarget_unlabeledContinueFromWhile() async {
    await resolveTestCode(r'''
void f() {
  while (true) {
    continue;
  }
}
''');
    var whileStatement = findNode.whileStatement('while (');
    var continueStatement = findNode.continueStatement('continue;');
    expect(continueStatement.target, same(whileStatement));
  }

  test_continueTarget_unlabeledContinueSkipsSwitch() async {
    await resolveTestCode(r'''
void f() {
  while (true) {
    switch (0) {
      case 0:
        continue;
    }
  }
}
''');
    var whileStatement = findNode.whileStatement('while (');
    var continueStatement = findNode.continueStatement('continue;');
    expect(continueStatement.target, same(whileStatement));
  }

  test_continueTarget_unlabeledContinueToOuterFunction() async {
    // Verify that unlabeled continue statements can't resolve to loops in an
    // outer function.
    await resolveTestCode(r'''
void f() {
  while (true) {
    void g() {
      continue;
    }
  }
}
''');
    var continueStatement = findNode.continueStatement('continue;');
    expect(continueStatement.target, isNull);
  }

  test_empty() async {
    await assertNoErrorsInCode('');
  }

  test_entryPoint_exported() async {
    newFile('$testPackageLibPath/a.dart', r'''
main() {}
''');

    await assertNoErrorsInCode(r'''
export 'a.dart';
''');

    var library = result.libraryElement;
    var main = library.entryPoint!;

    expect(main, isNotNull);
    expect(main.library, isNot(same(library)));
  }

  test_entryPoint_local() async {
    await assertNoErrorsInCode(r'''
main() {}
''');

    var library = result.libraryElement;
    var main = library.entryPoint!;

    expect(main, isNotNull);
    expect(main.library, same(library));
  }

  test_entryPoint_none() async {
    await assertNoErrorsInCode('');

    var library = result.libraryElement;
    expect(library.entryPoint, isNull);
  }

  test_enum_externalLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum EEE {A, B, C}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart';

void f(EEE e) {}
''');
    verifyTestResolved();
  }

  test_extractedMethodAsConstant() async {
    await assertNoErrorsInCode(r'''
abstract class Comparable<T> {
  int compareTo(T other);
  static int compare(Comparable a, Comparable b) => a.compareTo(b);
}
class A {
  void sort([compare = Comparable.compare]) {}
}''');
    verifyTestResolved();
  }

  test_fieldFormalParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  int x;
  int y;
  A(this.x) : y = x {}
}''');
    verifyTestResolved();

    var xParameter = findNode.fieldFormalParameter('this.x');

    var xParameterElement =
        xParameter.declaredElement as FieldFormalParameterElement;
    expect(xParameterElement.field, findElement.field('x'));

    assertElement(
      findNode.simple('x {}'),
      xParameterElement,
    );
  }

  test_forEachLoops_nonConflicting() async {
    await assertErrorsInCode(r'''
f() {
  List list = [1,2,3];
  for (int x in list) {}
  for (int x in list) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 40, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 65, 1),
    ]);
    verifyTestResolved();
  }

  test_forLoops_nonConflicting() async {
    await assertNoErrorsInCode(r'''
f() {
  for (int i = 0; i < 3; i++) {
  }
  for (int i = 0; i < 3; i++) {
  }
}''');
    verifyTestResolved();
  }

  test_functionTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef bool P(e);
class A {
  late P p;
  m(e) {
    if (p(e)) {}
  }
}''');
    verifyTestResolved();
  }

  test_getter_fromMixins_bare_identifier() async {
    await assertNoErrorsInCode('''
class B {}
class M1 {
  get x => null;
}
class M2 {
  get x => null;
}
class C extends B with M1, M2 {
  f() {
    return x;
  }
}
''');
    verifyTestResolved();

    // Verify that the getter for "x" in C.f() refers to the getter defined in
    // M2.
    expect(
      findNode.simple('x;').staticElement,
      findElement.getter('x', of: 'M2'),
    );
  }

  test_getter_fromMixins_property_access() async {
    await assertErrorsInCode('''
class B {}
class M1 {
  get x => null;
}
class M2 {
  get x => null;
}
class C extends B with M1, M2 {}
void main() {
  var y = new C().x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 124, 1),
    ]);
    verifyTestResolved();

    // Verify that the getter for "x" in "new C().x" refers to the getter
    // defined in M2.
    expect(
      findNode.simple('x;').staticElement,
      findElement.getter('x', of: 'M2'),
    );
  }

  test_import_hide() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
set foo(value) {}
class A {}''');

    newFile('$testPackageLibPath/lib2.dart', r'''
set foo(value) {}''');

    await assertNoErrorsInCode(r'''
import 'lib1.dart' hide foo;
import 'lib2.dart';

main() {
  foo = 0;
}
A a = A();''');
    verifyTestResolved();
  }

  test_import_prefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
f(int x) {
  return x * x;
}''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as _a;
main() {
  _a.f(0);
}''');
    verifyTestResolved();
  }

  test_import_prefix_doesNotExist() async {
    //
    // The primary purpose of this test is to ensure that we are only getting a
    // single error generated when the only problem is that an imported file
    // does not exist.
    //
    await assertErrorsInCode('''
import 'missing.dart' as p;
int a = p.q + p.r.s;
String b = p.t(a) + p.u(v: 0);
p.T c = new p.T();
class D<E> extends p.T {
  D(int i) : super(i);
  p.U f = new p.V();
}
class F implements p.T {
  p.T m(p.U u) => null;
}
class G extends Object with p.V {}
class H extends D<p.W> {
  H(int i) : super(i);
}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);
    verifyTestResolved();
  }

  test_import_show_doesNotExist() async {
    //
    // The primary purpose of this test is to ensure that we are only getting a
    // single error generated when the only problem is that an imported file
    // does not exist.
    //
    await assertErrorsInCode('''
import 'missing.dart' show q, r, t, u, T, U, V, W;
int a = q + r.s;
String b = t(a) + u(v: 0);
T c = new T();
class D<E> extends T {
  D(int i) : super(i);
  U f = new V();
}
class F implements T {
  T m(U u) => null;
}
class G extends Object with V {}
class H extends D<W> {
  H(int i) : super(i);
}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);
  }

  test_import_spaceInUri() async {
    newFile('$testPackageLibPath/sub folder/a.dart', r'''
foo() {}''');

    await assertNoErrorsInCode(r'''
import 'sub folder/a.dart';

main() {
  foo();
}''');
    verifyTestResolved();
  }

  test_indexExpression_typeParameters() async {
    await assertNoErrorsInCode(r'''
f() {
  List<int> a = [];
  a[0];
  List<List<int>> b = [];
  b[0][0];
  List<List<List<int>>> c = [];
  c[0][0][0];
}''');
    verifyTestResolved();
  }

  test_indexExpression_typeParameters_invalidAssignmentWarning() async {
    await assertErrorsInCode(r'''
f() {
  List<List<int>> b = [];
  b[0][0] = 'hi';
}''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 44, 4),
    ]);
    verifyTestResolved();
  }

  test_indirectOperatorThroughCall() async {
    await assertNoErrorsInCode(r'''
class A {
  B call() { return new B(); }
}

class B {
  int operator [](int i) { return i; }
}

A f = new A();

g(int x) {}

main() {
  g(f()[0]);
}''');
    verifyTestResolved();
  }

  test_invoke_dynamicThroughGetter() async {
    await assertNoErrorsInCode(r'''
class A {
  List get X => [() => 0];
  m(A a) {
    X.last;
  }
}''');
    verifyTestResolved();
  }

  test_isValidMixin_badSuperclass() async {
    await assertErrorsInCode(r'''
class A extends B {}
class B {}
class C = Object with A;''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 54, 1),
    ]);
    verifyTestResolved();

    var a = findElement.class_('A');
    expect(a.isValidMixin, isFalse);
  }

  test_isValidMixin_constructor() async {
    await assertErrorsInCode(r'''
class A {
  A() {}
}
class C = Object with A;''', [
      error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 43, 1),
    ]);
    verifyTestResolved();

    var a = findElement.class_('A');
    expect(a.isValidMixin, isFalse);
  }

  test_isValidMixin_factoryConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  factory A() => throw 0;
}
class C = Object with A;''');
    verifyTestResolved();

    var a = findElement.class_('A');
    expect(a.isValidMixin, isTrue);
  }

  test_isValidMixin_super_toString() async {
    await assertNoErrorsInCode(r'''
class A {
  toString() {
    return super.toString();
  }
}
class C = Object with A;''');
    verifyTestResolved();

    var a = findElement.class_('A');
    expect(a.isValidMixin, isTrue);
  }

  test_isValidMixin_valid() async {
    await assertNoErrorsInCode('''
class A {}
class C = Object with A;''');
    verifyTestResolved();

    var a = findElement.class_('A');
    expect(a.isValidMixin, isTrue);
  }

  test_labels_switch() async {
    await assertNoErrorsInCode(r'''
void doSwitch(int target) {
  switch (target) {
    l0: case 0:
      continue l1;
    l1: case 1:
      continue l0;
    default:
      continue l1;
  }
}''');
    verifyTestResolved();
  }

  test_localVariable_types_invoked() async {
    await resolveTestCode(r'''
const A = null;
main() {
  var myVar = (int p) => 'foo';
  myVar(42);
}''');
    var node = findNode.simple('myVar(42)');
    assertType(node, 'String Function(int)');
  }

  test_metadata_class() async {
    await assertNoErrorsInCode(r'''
const A = null;
@A class C<A> {}''');
    verifyTestResolved();

    var annotations = findElement.class_('C').metadata;
    expect(annotations, hasLength(1));

    var cDeclaration = findNode.classDeclaration('C<A>');
    assertElement(
      cDeclaration.metadata[0].name,
      findElement.topGet('A'),
    );
  }

  test_metadata_classTypeAlias() async {
    await assertNoErrorsInCode(r'''
const A = null;
@A class C<A> = D with E;
class D {}
class E {}
''');
    verifyTestResolved();

    var annotations = findElement.class_('C').metadata;
    expect(annotations, hasLength(1));

    var cDeclaration = findNode.classTypeAlias('C<A>');
    assertElement(
      cDeclaration.metadata[0].name,
      findElement.topGet('A'),
    );
  }

  test_metadata_enum() async {
    await assertNoErrorsInCode('''
const A = null;
@A enum E { A, B }
''');
    verifyTestResolved();

    var annotations = findElement.enum_('E').metadata;
    expect(annotations, hasLength(1));

    var eDeclaration = findNode.enumDeclaration('E');
    assertElement(
      eDeclaration.metadata[0].name,
      findElement.topGet('A'),
    );
  }

  test_metadata_extension() async {
    await assertNoErrorsInCode(r'''
const A = null;
@A extension E<A> on List<A> {}''');
    verifyTestResolved();

    var annotations = findElement.extension_('E').metadata;
    expect(annotations, hasLength(1));

    var cDeclaration = findNode.extensionDeclaration('E<A>');
    assertElement(
      cDeclaration.metadata[0].name,
      findElement.topGet('A'),
    );
  }

  test_metadata_field() async {
    await assertNoErrorsInCode(r'''
const A = null;
class C {
  @A int f = 1;
}''');
    verifyTestResolved();

    var metadata = findElement.field('f').metadata;
    expect(metadata, hasLength(1));
  }

  test_metadata_fieldFormalParameter() async {
    await assertNoErrorsInCode(r'''
const A = null;
class C {
  int f;
  C(@A this.f);
}''');
    verifyTestResolved();

    var metadata = findElement.fieldFormalParameter('f').metadata;
    expect(metadata, hasLength(1));
  }

  test_metadata_function() async {
    await assertNoErrorsInCode(r'''
const A = null;
@A f() {}''');
    verifyTestResolved();

    var annotations = findElement.topFunction('f').metadata;
    expect(annotations, hasLength(1));
  }

  test_metadata_function_generic() async {
    await assertNoErrorsInCode(r'''
const A = null;
@A f<A>() {}''');
    verifyTestResolved();

    var annotations = findElement.topFunction('f').metadata;
    expect(annotations, hasLength(1));

    var fDeclaration = findNode.functionDeclaration('f<A>');
    assertElement(
      fDeclaration.metadata[0].name,
      findElement.topGet('A'),
    );
  }

  test_metadata_functionTypeAlias() async {
    await assertNoErrorsInCode('''
const A = null;
@A typedef F<A>(int A);
''');
    verifyTestResolved();

    var annotations = findElement.typeAlias('F').metadata;
    expect(annotations, hasLength(1));

    var fDeclaration = findNode.functionTypeAlias('F');
    assertElement(
      fDeclaration.metadata[0].name,
      findElement.topGet('A'),
    );
  }

  test_metadata_functionTypedParameter() async {
    await assertNoErrorsInCode(r'''
const A = null;
f(@A int p(int x)) {}''');
    verifyTestResolved();

    var metadata = findElement.parameter('p').metadata;
    expect(metadata, hasLength(1));
  }

  test_metadata_functionTypedParameter_generic() async {
    await assertNoErrorsInCode(r'''
const A = null;
f(@A int p<A>(int x)) {}''');
    verifyTestResolved();

    var annotations = findElement.parameter('p').metadata;
    expect(annotations, hasLength(1));

    var pDeclaration = findNode.functionTypedFormalParameter('p<A>');
    assertElement(
      pDeclaration.metadata[0].name,
      findElement.topGet('A'),
    );
  }

  test_metadata_genericTypeAlias() async {
    await assertNoErrorsInCode(r'''
const A = null;
@A typedef F<A> = A Function();
''');
    verifyTestResolved();

    var annotations = findElement.typeAlias('F').metadata;
    expect(annotations, hasLength(1));

    var fDeclaration = findNode.genericTypeAlias('F<A>');
    assertElement(
      fDeclaration.metadata[0].name,
      findElement.topGet('A'),
    );
  }

  test_metadata_libraryDirective() async {
    await assertNoErrorsInCode(r'''
@A library lib;
const A = null;''');
    verifyTestResolved();

    var metadata = result.libraryElement.metadata;
    expect(metadata, hasLength(1));
  }

  test_metadata_method() async {
    await assertNoErrorsInCode(r'''
const A = null;
class C {
  @A void m() {}
}''');
    verifyTestResolved();

    var metadata = findElement.method('m').metadata;
    expect(metadata, hasLength(1));
  }

  test_metadata_method_generic() async {
    await assertNoErrorsInCode(r'''
const A = null;
class C {
  @A void m<A>() {}
}''');
    verifyTestResolved();

    var annotations = findElement.method('m').metadata;
    expect(annotations, hasLength(1));

    var mDeclaration = findNode.methodDeclaration('m<A>');
    assertElement(
      mDeclaration.metadata[0].name,
      findElement.topGet('A'),
    );
  }

  test_metadata_mixin() async {
    await assertNoErrorsInCode(r'''
const A = null;
@A mixin M<A> on Object {}''');
    verifyTestResolved();

    var annotations = findElement.mixin('M').metadata;
    expect(annotations, hasLength(1));

    var mDeclaration = findNode.mixinDeclaration('M<A>');
    assertElement(
      mDeclaration.metadata[0].name,
      findElement.topGet('A'),
    );
  }

  test_metadata_namedParameter() async {
    await assertNoErrorsInCode(r'''
const A = null;
f({@A int p : 0}) {}''');
    verifyTestResolved();

    var metadata = findElement.parameter('p').metadata;
    expect(metadata, hasLength(1));
  }

  test_metadata_positionalParameter() async {
    await assertNoErrorsInCode(r'''
const A = null;
f([@A int p = 0]) {}''');
    verifyTestResolved();

    var metadata = findElement.parameter('p').metadata;
    expect(metadata, hasLength(1));
  }

  test_metadata_simpleParameter() async {
    await assertNoErrorsInCode(r'''
const A = null;
f(@A p1, @A int p2) {}''');
    verifyTestResolved();

    expect(findElement.parameter('p1').metadata, hasLength(1));
    expect(findElement.parameter('p2').metadata, hasLength(1));
  }

  test_metadata_typedef() async {
    await assertNoErrorsInCode(r'''
const A = null;
@A typedef F<A>();''');
    verifyTestResolved();

    expect(
      findElement.typeAlias('F').metadata,
      hasLength(1),
    );

    var actualElement = findNode.annotation('@A').name.staticElement;
    expect(actualElement, findElement.topGet('A'));
  }

  test_method_fromMixin() async {
    await assertNoErrorsInCode(r'''
class B {
  bar() => 1;
}
class A {
  foo() => 2;
}

class C extends B with A {
  bar() => super.bar();
  foo() => super.foo();
}''');
    verifyTestResolved();
  }

  test_method_fromMixins() async {
    await assertNoErrorsInCode('''
class B {}
class M1 {
  void f() {}
}
class M2 {
  void f() {}
}
class C extends B with M1, M2 {}
void main() {
  new C().f();
}
''');
    verifyTestResolved();

    expect(
      findNode.simple('f();').staticElement,
      findElement.method('f', of: 'M2'),
    );
  }

  test_method_fromMixins_bare_identifier() async {
    await assertNoErrorsInCode('''
class B {}
class M1 {
  void f() {}
}
class M2 {
  void f() {}
}
class C extends B with M1, M2 {
  void g() {
    f();
  }
}
''');
    verifyTestResolved();

    expect(
      findNode.simple('f();').staticElement,
      findElement.method('f', of: 'M2'),
    );
  }

  test_method_fromMixins_invoked_from_outside_class() async {
    await assertNoErrorsInCode('''
class B {}
class M1 {
  void f() {}
}
class M2 {
  void f() {}
}
class C extends B with M1, M2 {}
void main() {
  new C().f();
}
''');
    verifyTestResolved();

    expect(
      findNode.simple('f();').staticElement,
      findElement.method('f', of: 'M2'),
    );
  }

  test_method_fromSuperclassMixin() async {
    await assertNoErrorsInCode(r'''
class A {
  void m1() {}
}
class B extends Object with A {
}
class C extends B {
}
f(C c) {
  c.m1();
}''');
    verifyTestResolved();
  }

  test_methodCascades() async {
    await assertNoErrorsInCode(r'''
class A {
  void m1() {}
  void m2() {}
  void m() {
    A a = new A();
    a..m1()
     ..m2();
  }
}''');
    verifyTestResolved();
  }

  test_methodCascades_withSetter() async {
    await assertNoErrorsInCode(r'''
class A {
  String name = '';
  void m1() {}
  void m2() {}
  void m() {
    A a = new A();
    a..m1()
     ..name = 'name'
     ..m2();
  }
}''');
    verifyTestResolved();
  }

  test_resolveAgainstNull() async {
    await assertNoErrorsInCode(r'''
f(var p) {
  return null == p;
}''');
    verifyTestResolved();
  }

  test_setter_static() async {
    await assertNoErrorsInCode(r'''
set s(x) {
}

main() {
  s = 123;
}''');
    verifyTestResolved();
  }

  /// Verify that all of the identifiers in the [result] have been resolved.
  void verifyTestResolved() {
    var verifier = ResolutionVerifier();
    result.unit.accept(verifier);
    verifier.assertResolved();
  }

  /// Resolve the test file and verify that the arguments in a specific method
  /// invocation were correctly resolved.
  ///
  /// The file is expected to define a method named `g`, and has exactly one
  /// [MethodInvocation] in a statement ending with `);`. It is the arguments to
  /// that method invocation that are tested. The method invocation can contain
  /// errors.
  ///
  /// The arguments were resolved correctly if the number of expressions in the
  /// list matches the length of the array of indices and if, for each index in
  /// the array of indices, the parameter to which the argument expression was
  /// resolved is the parameter in the invoked method's list of parameters at
  /// that index. Arguments that should not be resolved to a parameter because
  /// of an error can be denoted by including a negative index in the array of
  /// indices.
  ///
  /// @param indices the array of indices used to associate arguments with
  ///          parameters
  /// @throws Exception if the source could not be resolved or if the structure
  ///           of the source is not valid
  Future<void> _validateArgumentResolution(List<int> indices) async {
    var g = findElement.method('g');
    var parameters = g.parameters;

    var invocation = findNode.methodInvocation(');');

    var arguments = invocation.argumentList.arguments;

    var argumentCount = arguments.length;
    expect(argumentCount, indices.length);

    for (var i = 0; i < argumentCount; i++) {
      var argument = arguments[i];
      var actualParameter = argument.staticParameterElement;

      var index = indices[i];
      if (index < 0) {
        expect(actualParameter, isNull);
      } else {
        var expectedParameter = parameters[index];
        expect(actualParameter, same(expectedParameter));
      }
    }
  }
}
