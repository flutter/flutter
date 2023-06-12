// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/index.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IndexTest);
  });
}

class ExpectedLocation {
  final int offset;
  final int length;
  final bool isQualified;

  ExpectedLocation(this.offset, this.length, this.isQualified);

  @override
  String toString() {
    return '(offset=$offset; length=$length; isQualified=$isQualified)';
  }
}

@reflectiveTest
class IndexTest extends PubPackageResolutionTest with _IndexMixin {
  test_fieldFormalParameter_noSuchField() async {
    await _indexTestUnit('''
class B<T> {
  B({this.x}) {}

  foo() {
    B<int>(x: 1);
  }
}
''');
    // No exceptions.
  }

  test_hasAncestor_ClassDeclaration() async {
    await _indexTestUnit('''
class A {}
class B1 extends A {}
class B2 implements A {}
class C1 extends B1 {}
class C2 extends B2 {}
class C3 implements B1 {}
class C4 implements B2 {}
class M extends Object with A {}
''');
    ClassElement classElementA = findElement.class_('A');
    assertThat(classElementA)
      ..isAncestorOf('B1 extends A')
      ..isAncestorOf('B2 implements A')
      ..isAncestorOf('C1 extends B1')
      ..isAncestorOf('C2 extends B2')
      ..isAncestorOf('C3 implements B1')
      ..isAncestorOf('C4 implements B2')
      ..isAncestorOf('M extends Object with A');
  }

  test_hasAncestor_ClassTypeAlias() async {
    await _indexTestUnit('''
class A {}
class B extends A {}
class C1 = Object with A;
class C2 = Object with B;
''');
    ClassElement classElementA = findElement.class_('A');
    ClassElement classElementB = findElement.class_('B');
    assertThat(classElementA)
      ..isAncestorOf('C1 = Object with A')
      ..isAncestorOf('C2 = Object with B');
    assertThat(classElementB).isAncestorOf('C2 = Object with B');
  }

  test_hasAncestor_MixinDeclaration() async {
    await _indexTestUnit('''
class A {}
class B extends A {}

mixin M1 on A {}
mixin M2 on B {}
mixin M3 implements A {}
mixin M4 implements B {}
mixin M5 on M2 {}
''');
    ClassElement classElementA = findElement.class_('A');
    assertThat(classElementA)
      ..isAncestorOf('B extends A')
      ..isAncestorOf('M1 on A')
      ..isAncestorOf('M2 on B')
      ..isAncestorOf('M3 implements A')
      ..isAncestorOf('M4 implements B')
      ..isAncestorOf('M5 on M2');
  }

  test_isExtendedBy_ClassDeclaration_isQualified() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;
class B extends p.A {} // 2
''');
    ClassElement elementA = importFindLib().class_('A');
    assertThat(elementA).isExtendedAt('A {} // 2', true);
  }

  test_isExtendedBy_ClassDeclaration_Object() async {
    await _indexTestUnit('''
class A {}
''');
    ClassElement elementA = findElement.class_('A');
    ClassElement elementObject = elementA.supertype!.element;
    assertThat(elementObject).isExtendedAt('A {}', true, length: 0);
  }

  test_isExtendedBy_ClassDeclaration_TypeAliasElement() async {
    await _indexTestUnit('''
class A<T> {}
typedef B = A<int>;
class C extends B {}
''');
    var B = findElement.typeAlias('B');
    assertThat(B)
      ..isExtendedAt('B {}', false)
      ..isReferencedAt('B {}', false);
  }

  test_isExtendedBy_ClassTypeAlias() async {
    await _indexTestUnit('''
class A {}
class B {}
class C = A with B;
''');
    ClassElement elementA = findElement.class_('A');
    assertThat(elementA)
      ..isExtendedAt('A with', false)
      ..isReferencedAt('A with', false);
  }

  test_isExtendedBy_ClassTypeAlias_isQualified() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;
class B {}
class C = p.A with B;
''');
    ClassElement elementA = importFindLib().class_('A');
    assertThat(elementA)
      ..isExtendedAt('A with', true)
      ..isReferencedAt('A with', true);
  }

  test_isImplementedBy_ClassDeclaration() async {
    await _indexTestUnit('''
class A {} // 1
class B implements A {} // 2
''');
    ClassElement elementA = findElement.class_('A');
    assertThat(elementA)
      ..isImplementedAt('A {} // 2', false)
      ..isReferencedAt('A {} // 2', false);
  }

  test_isImplementedBy_ClassDeclaration_isQualified() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;
class B implements p.A {} // 2
''');
    ClassElement elementA = importFindLib().class_('A');
    assertThat(elementA)
      ..isImplementedAt('A {} // 2', true)
      ..isReferencedAt('A {} // 2', true);
  }

  test_isImplementedBy_ClassDeclaration_TypeAliasElement() async {
    await _indexTestUnit('''
class A<T> {}
typedef B = A<int>;
class C implements B {}
''');
    var B = findElement.typeAlias('B');
    assertThat(B)
      ..isImplementedAt('B {}', false)
      ..isReferencedAt('B {}', false);
  }

  test_isImplementedBy_ClassTypeAlias() async {
    await _indexTestUnit('''
class A {} // 1
class B {} // 2
class C = Object with A implements B; // 3
''');
    ClassElement elementB = findElement.class_('B');
    assertThat(elementB)
      ..isImplementedAt('B; // 3', false)
      ..isReferencedAt('B; // 3', false);
  }

  test_isImplementedBy_enum() async {
    await _indexTestUnit('''
class A {} // 1
enum E implements A { // 2
  v;
}
''');
    ClassElement elementA = findElement.class_('A');
    assertThat(elementA)
      ..isImplementedAt('A { // 2', false)
      ..isReferencedAt('A { // 2', false);
  }

  test_isImplementedBy_MixinDeclaration_implementsClause() async {
    await _indexTestUnit('''
class A {} // 1
mixin M implements A {} // 2
''');
    ClassElement elementA = findElement.class_('A');
    assertThat(elementA)
      ..isImplementedAt('A {} // 2', false)
      ..isReferencedAt('A {} // 2', false);
  }

  test_isImplementedBy_MixinDeclaration_onClause() async {
    await _indexTestUnit('''
class A {} // 1
mixin M on A {} // 2
''');
    ClassElement elementA = findElement.class_('A');
    assertThat(elementA)
      ..isImplementedAt('A {} // 2', false)
      ..isReferencedAt('A {} // 2', false);
  }

  test_isInvokedBy_FunctionElement() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
foo() {}
''');
    await _indexTestUnit('''
import 'lib.dart';
import 'lib.dart' as pref;
main() {
  pref.foo(); // q
  foo(); // nq
}''');
    FunctionElement element = importFindLib().topFunction('foo');
    assertThat(element)
      ..isInvokedAt('foo(); // q', true)
      ..isInvokedAt('foo(); // nq', false);
  }

  test_isInvokedBy_FunctionElement_synthetic_loadLibrary() async {
    await _indexTestUnit('''
import 'dart:math' deferred as math;
main() {
  math.loadLibrary(); // 1
  math.loadLibrary(); // 2
}
''');
    LibraryElement mathLib = findElement.import('dart:math').importedLibrary!;
    FunctionElement element = mathLib.loadLibraryFunction;
    assertThat(element).isInvokedAt('loadLibrary(); // 1', true);
    assertThat(element).isInvokedAt('loadLibrary(); // 2', true);
  }

  test_isInvokedBy_MethodElement_class() async {
    await _indexTestUnit('''
class A {
  foo() {}
  main() {
    this.foo(); // q
    foo(); // nq
  }
}''');
    MethodElement element = findElement.method('foo');
    assertThat(element)
      ..isInvokedAt('foo(); // q', true)
      ..isInvokedAt('foo(); // nq', false);
  }

  test_isInvokedBy_MethodElement_enum() async {
    await _indexTestUnit('''
enum E {
  v;
  void foo() {}
  void bar() {
    this.foo(); // q1
    foo(); // nq
  }
}
void f(E e) {
  e.foo(); // q2
}
''');
    assertThat(findElement.method('foo'))
      ..isInvokedAt('foo(); // q1', true)
      ..isInvokedAt('foo(); // nq', false)
      ..isInvokedAt('foo(); // q2', true);
  }

  test_isInvokedBy_MethodElement_ofNamedExtension_instance() async {
    await _indexTestUnit('''
extension E on int {
  void foo() {}
}

main() {
  0.foo();
}
''');
    MethodElement element = findElement.method('foo');
    assertThat(element).isInvokedAt('foo();', true);
  }

  test_isInvokedBy_MethodElement_ofNamedExtension_static() async {
    await _indexTestUnit('''
extension E on int {
  static void foo() {}
}

main() {
  E.foo();
}
''');
    MethodElement element = findElement.method('foo');
    assertThat(element).isInvokedAt('foo();', true);
  }

  test_isInvokedBy_MethodElement_ofUnnamedExtension_instance() async {
    await _indexTestUnit('''
extension on int {
  void foo() {} // int
}

extension on double {
  void foo() {} // double
}

main() {
  0.foo(); // int ref
  (1.2).foo(); // double ref
}
''');

    var intMethod = findNode.methodDeclaration('foo() {} // int');
    assertThat(intMethod.declaredElement!)
        .isInvokedAt('foo(); // int ref', true);

    var doubleMethod = findNode.methodDeclaration('foo() {} // double');
    assertThat(doubleMethod.declaredElement!)
        .isInvokedAt('foo(); // double ref', true);
  }

  test_isInvokedBy_MethodElement_propagatedType() async {
    await _indexTestUnit('''
class A {
  foo() {}
}
main() {
  var a = new A();
  a.foo();
}
''');
    MethodElement element = findElement.method('foo');
    assertThat(element).isInvokedAt('foo();', true);
  }

  test_isInvokedBy_operator_class_binary() async {
    await _indexTestUnit('''
class A {
  operator +(other) => this;
}
main(A a) {
  print(a + 1);
  a += 2;
  ++a;
  a++;
}
''');
    MethodElement element = findElement.method('+');
    assertThat(element)
      ..isInvokedAt('+ 1', true, length: 1)
      ..isInvokedAt('+= 2', true, length: 2)
      ..isInvokedAt('++a', true, length: 2)
      ..isInvokedAt('++;', true, length: 2);
  }

  test_isInvokedBy_operator_class_index() async {
    await _indexTestUnit('''
class A {
  operator [](i) => null;
  operator []=(i, v) {}
}
main(A a) {
  print(a[0]);
  a[1] = 42;
}
''');
    MethodElement readElement = findElement.method('[]');
    MethodElement writeElement = findElement.method('[]=');
    assertThat(readElement).isInvokedAt('[0]', true, length: 1);
    assertThat(writeElement).isInvokedAt('[1]', true, length: 1);
  }

  test_isInvokedBy_operator_class_prefix() async {
    await _indexTestUnit('''
class A {
  A operator ~() => this;
}
main(A a) {
  print(~a);
}
''');
    MethodElement element = findElement.method('~');
    assertThat(element).isInvokedAt('~a', true, length: 1);
  }

  test_isInvokedBy_operator_enum_binary() async {
    await _indexTestUnit('''
enum E {
  v;
  int operator +(other) => 0;
}
void f(E e) {
  e + 1;
  e += 2;
  ++e;
  e++;
}
''');
    assertThat(findElement.method('+'))
      ..isInvokedAt('+ 1', true, length: 1)
      ..isInvokedAt('+= 2', true, length: 2)
      ..isInvokedAt('++e', true, length: 2)
      ..isInvokedAt('++;', true, length: 2);
  }

  test_isInvokedBy_operator_enum_index() async {
    await _indexTestUnit('''
enum E {
  v;
  int operator [](int index) => 0;
  operator []=(int index, int value) {}
}
void f(E e) {
  e[0];
  e[1] = 42;
}
''');
    MethodElement readElement = findElement.method('[]');
    MethodElement writeElement = findElement.method('[]=');
    assertThat(readElement).isInvokedAt('[0]', true, length: 1);
    assertThat(writeElement).isInvokedAt('[1]', true, length: 1);
  }

  test_isInvokedBy_operator_enum_prefix() async {
    await _indexTestUnit('''
enum E {
  e;
  int operator ~() => 0;
}
void f(E e) {
  ~e;
}
''');
    MethodElement element = findElement.method('~');
    assertThat(element).isInvokedAt('~e', true, length: 1);
  }

  test_isMixedBy_ClassDeclaration_TypeAliasElement() async {
    await _indexTestUnit('''
class A<T> {}
typedef B = A<int>;
class C extends Object with B {}
''');
    var B = findElement.typeAlias('B');
    assertThat(B)
      ..isMixedInAt('B {}', false)
      ..isReferencedAt('B {}', false);
  }

  test_isMixedInBy_ClassDeclaration_class() async {
    await _indexTestUnit('''
class A {} // 1
class B extends Object with A {} // 2
''');
    ClassElement elementA = findElement.class_('A');
    assertThat(elementA)
      ..isMixedInAt('A {} // 2', false)
      ..isReferencedAt('A {} // 2', false);
  }

  test_isMixedInBy_ClassDeclaration_isQualified() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;
class B extends Object with p.A {} // 2
''');
    ClassElement elementA = importFindLib().class_('A');
    assertThat(elementA).isMixedInAt('A {} // 2', true);
  }

  test_isMixedInBy_ClassDeclaration_mixin() async {
    await _indexTestUnit('''
mixin A {} // 1
class B extends Object with A {} // 2
''');
    ClassElement elementA = findElement.mixin('A');
    assertThat(elementA)
      ..isMixedInAt('A {} // 2', false)
      ..isReferencedAt('A {} // 2', false);
  }

  test_isMixedInBy_ClassTypeAlias_class() async {
    await _indexTestUnit('''
class A {} // 1
class B = Object with A; // 2
''');
    ClassElement elementA = findElement.class_('A');
    assertThat(elementA).isMixedInAt('A; // 2', false);
  }

  test_isMixedInBy_ClassTypeAlias_mixin() async {
    await _indexTestUnit('''
mixin A {} // 1
class B = Object with A; // 2
''');
    ClassElement elementA = findElement.mixin('A');
    assertThat(elementA).isMixedInAt('A; // 2', false);
  }

  test_isMixedInBy_enum_mixin() async {
    await _indexTestUnit('''
mixin M {} // 1
enum E with M { // 2
  v
}
''');
    assertThat(findElement.mixin('M'))
      ..isMixedInAt('M { // 2', false)
      ..isReferencedAt('M { // 2', false);
  }

  test_isReferencedAt_PropertyAccessorElement_field_call() async {
    await _indexTestUnit('''
class A {
  var field;
  main() {
    this.field(); // q
    field(); // nq
  }
}''');
    FieldElement field = findElement.field('field');
    assertThat(field.getter!)
      ..isReferencedAt('field(); // q', true)
      ..isReferencedAt('field(); // nq', false);
  }

  test_isReferencedAt_PropertyAccessorElement_getter_call() async {
    await _indexTestUnit('''
class A {
  get ggg => null;
  main() {
    this.ggg(); // q
    ggg(); // nq
  }
}''');
    PropertyAccessorElement element = findElement.getter('ggg');
    assertThat(element)
      ..isReferencedAt('ggg(); // q', true)
      ..isReferencedAt('ggg(); // nq', false);
  }

  test_isReferencedBy_ClassElement() async {
    await _indexTestUnit('''
class A {
  static var field;
}
main(A p) {
  A v;
  new A(); // 2
  A.field = 1;
  print(A.field); // 3
}
''');
    ClassElement element = findElement.class_('A');
    assertThat(element)
      ..isReferencedAt('A p) {', false)
      ..isReferencedAt('A v;', false)
      ..isReferencedAt('A(); // 2', false)
      ..isReferencedAt('A.field = 1;', false)
      ..isReferencedAt('A.field); // 3', false);
  }

  test_isReferencedBy_ClassElement_enum() async {
    await _indexTestUnit('''
enum MyEnum {a}

main(MyEnum p) {
  MyEnum v;
  MyEnum.a;
}
''');
    ClassElement element = findElement.enum_('MyEnum');
    assertThat(element)
      ..isReferencedAt('MyEnum p) {', false)
      ..isReferencedAt('MyEnum v;', false)
      ..isReferencedAt('MyEnum.a;', false);
  }

  test_isReferencedBy_ClassElement_fromExtension() async {
    await _indexTestUnit('''
class A<T> {}

extension E on A<int> {}
''');
    ClassElement element = findElement.class_('A');
    assertThat(element).isReferencedAt('A<int>', false);
  }

  test_isReferencedBy_ClassElement_implicitNew() async {
    await _indexTestUnit('''
class A {}
main() {
  A(); // invalid code, but still a reference
}''');
    ClassElement element = findElement.class_('A');
    assertThat(element).isReferencedAt('A();', false);
  }

  test_isReferencedBy_ClassElement_inGenericAnnotation() async {
    await _indexTestUnit('''
class A<T> {
  const A();
}

@A<A>()
void f() {}
''');
    assertThat(findElement.class_('A'))
      ..isReferencedAt('A<A', false)
      ..isReferencedAt('A>()', false);
  }

  test_isReferencedBy_ClassElement_inTypeAlias() async {
    await _indexTestUnit('''
class A<T> {}

typedef B = A<int>;
''');
    assertThat(findElement.class_('A')).isReferencedAt('A<int', false);
    assertThat(intElement).isReferencedAt('int>;', false);
  }

  test_isReferencedBy_ClassElement_invocation_isQualified() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;
main() {
  p.A(); // invalid code, but still a reference
}''');
    Element element = importFindLib().class_('A');
    assertThat(element).isReferencedAt('A();', true);
  }

  test_isReferencedBy_ClassElement_invocationTypeArgument() async {
    await _indexTestUnit('''
class A {}
void f<T>() {}
main() {
  f<A>();
}
''');
    ClassElement element = findElement.class_('A');
    assertThat(element).isReferencedAt('A>();', false);
  }

  test_isReferencedBy_ClassTypeAlias() async {
    await _indexTestUnit('''
class A {}
class B = Object with A;
main(B p) {
  B v;
}
''');
    ClassElement element = findElement.class_('B');
    assertThat(element)
      ..isReferencedAt('B p) {', false)
      ..isReferencedAt('B v;', false);
  }

  test_isReferencedBy_CompilationUnitElement_export() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await _indexTestUnit('''
export 'lib.dart';
''');
    var element = findElement.export('package:test/lib.dart').exportedLibrary!;
    assertThat(element).isReferencedAt("'lib.dart'", true, length: 10);
  }

  test_isReferencedBy_CompilationUnitElement_import() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await _indexTestUnit('''
import 'lib.dart';
''');
    var element = findElement.import('package:test/lib.dart').importedLibrary!;
    assertThat(element).isReferencedAt("'lib.dart'", true, length: 10);
  }

  test_isReferencedBy_CompilationUnitElement_part() async {
    newFile('$testPackageLibPath/my_unit.dart', 'part of my_lib;');
    await _indexTestUnit('''
library my_lib;
part 'my_unit.dart';
''');
    var element = findElement.part('my_unit.dart');
    assertThat(element).isReferencedAt("'my_unit.dart';", true, length: 14);
  }

  test_isReferencedBy_CompilationUnitElement_part_inPart() async {
    newFile('$testPackageLibPath/a.dart', 'part of lib;');
    newFile('$testPackageLibPath/b.dart', '''
library lib;
part 'a.dart';
''');
    await _indexTestUnit('''
part 'b.dart';
''');
    // No exception, even though a.dart is a part of b.dart part.
  }

  test_isReferencedBy_ConstructorElement_class_named() async {
    await _indexTestUnit('''
/// [new A.foo] 1
class A {
  A.foo() {}
  A.bar() : this.foo(); // 2
}
class B extends A {
  B() : super.foo(); // 3
  factory B.bar() = A.foo; // 4
}
void f() {
  A.foo(); // 5
  A.foo; // 6
}
''');
    var element = findElement.constructor('foo');
    assertThat(element)
      ..hasRelationCount(6)
      ..isReferencedAt('.foo] 1', true, length: 4)
      ..isInvokedAt('.foo(); // 2', true, length: 4)
      ..isInvokedAt('.foo(); // 3', true, length: 4)
      ..isReferencedAt('.foo; // 4', true, length: 4)
      ..isInvokedAt('.foo(); // 5', true, length: 4)
      ..isReferencedByConstructorTearOffAt('.foo; // 6', length: 4);
  }

  test_isReferencedBy_ConstructorElement_class_namedOnlyWithDot() async {
    await _indexTestUnit('''
class A {
  A.named() {}
}
main() {
  new A.named();
}
''');
    // has ".named()", but does not have "named()"
    var constructorName = findNode.constructorName('.named();');
    var offsetWithoutDot = constructorName.name!.offset;
    var offsetWithDot = constructorName.period!.offset;
    expect(index.usedElementOffsets, isNot(contains(offsetWithoutDot)));
    expect(index.usedElementOffsets, contains(offsetWithDot));
  }

  test_isReferencedBy_ConstructorElement_class_redirection() async {
    await _indexTestUnit('''
class A {
  A() : this.bar(); // 1
  A.foo() : this(); // 2
  A.bar();
}
''');
    var constA = findElement.unnamedConstructor('A');
    var constA_bar = findElement.constructor('bar');
    assertThat(constA).isInvokedAt('(); // 2', true, length: 0);
    assertThat(constA_bar).isInvokedAt('.bar(); // 1', true, length: 4);
  }

  test_isReferencedBy_ConstructorElement_class_unnamed_declared() async {
    await _indexTestUnit('''
/// [new A] 1
class A {
  A() {}
  A.other() : this(); // 2
}
class B extends A {
  B() : super(); // 3
  factory B.other() = A; // 4
}
void f() {
  A(); // 5
  A.new; // 6
}
''');
    var element = findElement.unnamedConstructor('A');
    assertThat(element)
      ..hasRelationCount(6)
      ..isReferencedAt('] 1', true, length: 0)
      ..isInvokedAt('(); // 2', true, length: 0)
      ..isInvokedAt('(); // 3', true, length: 0)
      ..isReferencedAt('; // 4', true, length: 0)
      ..isInvokedAt('(); // 5', true, length: 0)
      ..isReferencedByConstructorTearOffAt('.new; // 6', length: 4);
  }

  test_isReferencedBy_ConstructorElement_class_unnamed_declared_new() async {
    await _indexTestUnit('''
/// [new A] 1
class A {
  A.new() {}
  A.other() : this(); // 2
}
class B extends A {
  B() : super(); // 3
  factory B.bar() = A; // 4
}
void f() {
  A(); // 5
  A.new; // 6
}
''');
    var element = findElement.unnamedConstructor('A');
    assertThat(element)
      ..hasRelationCount(6)
      ..isReferencedAt('] 1', true, length: 0)
      ..isInvokedAt('(); // 2', true, length: 0)
      ..isInvokedAt('(); // 3', true, length: 0)
      ..isReferencedAt('; // 4', true, length: 0)
      ..isInvokedAt('(); // 5', true, length: 0)
      ..isReferencedByConstructorTearOffAt('.new; // 6', length: 4);
  }

  test_isReferencedBy_ConstructorElement_class_unnamed_synthetic() async {
    await _indexTestUnit('''
/// [new A] 1
class A {}
class B extends A {
  B() : super(); // 2
  factory B.bar() = A; // 3
}
void f() {
  A(); // 4
  A.new; // 5
}
''');
    var element = findElement.unnamedConstructor('A');
    assertThat(element)
      ..hasRelationCount(5)
      ..isReferencedAt('] 1', true, length: 0)
      ..isInvokedAt('(); // 2', true, length: 0)
      ..isReferencedAt('; // 3', true, length: 0)
      ..isInvokedAt('(); // 4', true, length: 0)
      ..isReferencedByConstructorTearOffAt('.new; // 5', length: 4);
  }

  test_isReferencedBy_ConstructorElement_classTypeAlias() async {
    await _indexTestUnit('''
class M {}
class A implements B {
  A() {}
  A.named() {}
}
class B = A with M;
class C = B with M;
main() {
  new B(); // B1
  new B.named(); // B2
  new C(); // C1
  new C.named(); // C2
}
''');
    var constA = findElement.unnamedConstructor('A');
    var constA_named = findElement.constructor('named', of: 'A');
    assertThat(constA)
      ..isInvokedAt('(); // B1', true, length: 0)
      ..isInvokedAt('(); // C1', true, length: 0);
    assertThat(constA_named)
      ..isInvokedAt('.named(); // B2', true, length: 6)
      ..isInvokedAt('.named(); // C2', true, length: 6);
  }

  test_isReferencedBy_ConstructorElement_classTypeAlias_cycle() async {
    await _indexTestUnit('''
class M {}
class A = B with M;
class B = A with M;
main() {
  new A();
  new B();
}
''');
    // No additional validation, but it should not fail with stack overflow.
  }

  test_isReferencedBy_ConstructorElement_enum_named() async {
    await _indexTestUnit('''
/// [new E.foo] 1
enum E {
  v.foo(); // 2
  E.foo();
  E.bar() : this.foo(); // 3
}
''');
    var element = findElement.constructor('foo');
    assertThat(element)
      ..hasRelationCount(3)
      ..isReferencedAt('.foo] 1', true, length: 4)
      ..isInvokedAt('.foo(); // 2', true, length: 4)
      ..isInvokedAt('.foo(); // 3', true, length: 4);
  }

  test_isReferencedBy_ConstructorElement_enum_unnamed_declared() async {
    await _indexTestUnit('''
/// [new E] 1
enum E {
  v1, // 2
  v2(), // 3
  v3.new(); // 4
  E();
  E.other() : this(); // 5
}
''');
    var element = findElement.unnamedConstructor('E');
    assertThat(element)
      ..hasRelationCount(5)
      ..isReferencedAt('] 1', true, length: 0)
      ..isInvokedByEnumConstantWithoutArgumentsAt(', // 2', length: 0)
      ..isInvokedAt('(), // 3', true, length: 0)
      ..isInvokedAt('.new(); // 4', true, length: 4)
      ..isInvokedAt('(); // 5', true, length: 0);
  }

  test_isReferencedBy_ConstructorElement_enum_unnamed_declared_new() async {
    await _indexTestUnit('''
/// [new E] 1
enum E {
  v1, // 2
  v2(), // 3
  v3.new(); // 4
  E.new() {}
  E.other() : this(); // 5
}
''');
    var element = findElement.unnamedConstructor('E');
    assertThat(element)
      ..hasRelationCount(5)
      ..isReferencedAt('] 1', true, length: 0)
      ..isInvokedByEnumConstantWithoutArgumentsAt(', // 2', length: 0)
      ..isInvokedAt('(), // 3', true, length: 0)
      ..isInvokedAt('.new(); // 4', true, length: 4)
      ..isInvokedAt('(); // 5', true, length: 0);
  }

  test_isReferencedBy_ConstructorElement_enum_unnamed_synthetic() async {
    await _indexTestUnit('''
/// [new E] 1
enum E {
  v1, // 2
  v2(), // 3
  v3.new(); // 4
}
''');
    var element = findElement.unnamedConstructor('E');
    assertThat(element)
      ..hasRelationCount(4)
      ..isReferencedAt('] 1', true, length: 0)
      ..isInvokedByEnumConstantWithoutArgumentsAt(', // 2', length: 0)
      ..isInvokedAt('(), // 3', true, length: 0)
      ..isInvokedAt('.new(); // 4', true, length: 4);
  }

  test_isReferencedBy_DynamicElement() async {
    await _indexTestUnit('''
dynamic f() {
}''');
    expect(index.usedElementOffsets, isEmpty);
  }

  test_isReferencedBy_ExtensionElement() async {
    await _indexTestUnit('''
extension E on int {
  void foo() {}
}

main() {
  E(0).foo();
}
''');
    ExtensionElement element = findElement.extension_('E');
    assertThat(element).isReferencedAt('E(0).foo()', false);
  }

  test_isReferencedBy_FieldElement_class() async {
    await _indexTestUnit('''
class A {
  var field;
  A({this.field});
  m() {
    field = 2; // nq
    print(field); // nq
  }
}
main(A a) {
  a.field = 3; // q
  print(a.field); // q
  new A(field: 4);
}
''');
    FieldElement field = findElement.field('field');
    PropertyAccessorElement getter = field.getter!;
    PropertyAccessorElement setter = field.setter!;
    // A()
    assertThat(field).isWrittenAt('field});', true);
    // m()
    assertThat(setter).isReferencedAt('field = 2; // nq', false);
    assertThat(getter).isReferencedAt('field); // nq', false);
    // main()
    assertThat(setter).isReferencedAt('field = 3; // q', true);
    assertThat(getter).isReferencedAt('field); // q', true);
    assertThat(field).isReferencedAt('field: 4', true);
  }

  test_isReferencedBy_FieldElement_class_multiple() async {
    await _indexTestUnit('''
class A {
  var aaa;
  var bbb;
  A(this.aaa, this.bbb) {}
  m() {
    print(aaa);
    aaa = 1;
    print(bbb);
    bbb = 2;
  }
}
''');
    // aaa
    {
      FieldElement field = findElement.field('aaa');
      PropertyAccessorElement getter = field.getter!;
      PropertyAccessorElement setter = field.setter!;
      assertThat(field).isWrittenAt('aaa, ', true);
      assertThat(getter).isReferencedAt('aaa);', false);
      assertThat(setter).isReferencedAt('aaa = 1;', false);
    }
    // bbb
    {
      FieldElement field = findElement.field('bbb');
      PropertyAccessorElement getter = field.getter!;
      PropertyAccessorElement setter = field.setter!;
      assertThat(field).isWrittenAt('bbb) {}', true);
      assertThat(getter).isReferencedAt('bbb);', false);
      assertThat(setter).isReferencedAt('bbb = 2;', false);
    }
  }

  test_isReferencedBy_FieldElement_class_synthetic_hasGetter() async {
    await _indexTestUnit('''
class A {
  A() : f = 42;
  int get f => 0;
}
''');
    ClassElement element2 = findElement.class_('A');
    assertThat(element2.getField('f')!).isWrittenAt('f = 42', true);
  }

  test_isReferencedBy_FieldElement_class_synthetic_hasGetterSetter() async {
    await _indexTestUnit('''
class A {
  A() : f = 42;
  int get f => 0;
  set f(_) {}
}
''');
    ClassElement element2 = findElement.class_('A');
    assertThat(element2.getField('f')!).isWrittenAt('f = 42', true);
  }

  test_isReferencedBy_FieldElement_class_synthetic_hasSetter() async {
    await _indexTestUnit('''
class A {
  A() : f = 42;
  set f(_) {}
}
''');
    ClassElement element2 = findElement.class_('A');
    assertThat(element2.getField('f')!).isWrittenAt('f = 42', true);
  }

  test_isReferencedBy_FieldElement_enum() async {
    await _indexTestUnit('''
enum E {
  v;
  int? field; // a compile-time error
  E({this.field});
  void foo() {
    field = 2; // nq
    field; // nq
  }
}
void f(E e) {
  e.field = 3; // q
  e.field; // q
  E(field: 4);
}
''');
    FieldElement field = findElement.field('field');
    PropertyAccessorElement getter = field.getter!;
    PropertyAccessorElement setter = field.setter!;
    // E()
    assertThat(field).isWrittenAt('field});', true);
    // foo()
    assertThat(setter).isReferencedAt('field = 2; // nq', false);
    assertThat(getter).isReferencedAt('field; // nq', false);
    // f()
    assertThat(setter).isReferencedAt('field = 3; // q', true);
    assertThat(getter).isReferencedAt('field; // q', true);
    assertThat(field).isReferencedAt('field: 4', true);
  }

  test_isReferencedBy_FieldElement_enum_index() async {
    await _indexTestUnit('''
enum MyEnum {
  A, B, C
}
main() {
  print(MyEnum.values);
  print(MyEnum.A.index);
  print(MyEnum.A);
  print(MyEnum.B);
}
''');
    ClassElement enumElement = findElement.enum_('MyEnum');
    assertThat(enumElement.getGetter('values')!)
        .isReferencedAt('values);', true);
    assertThat(typeProvider.enumElement!.getGetter('index')!)
        .isReferencedAt('index);', true);
    assertThat(enumElement.getGetter('A')!).isReferencedAt('A);', true);
    assertThat(enumElement.getGetter('B')!).isReferencedAt('B);', true);
  }

  test_isReferencedBy_FieldElement_enum_synthetic_hasGetter() async {
    await _indexTestUnit('''
enum E {
  v;
  E() : f = 42;
  int get f => 0;
}
''');
    assertThat(findElement.field('f')).isWrittenAt('f = 42', true);
  }

  test_isReferencedBy_FieldElement_enum_synthetic_hasGetterSetter() async {
    await _indexTestUnit('''
enum E {
  v;
  E() : f = 42;
  int get f => 0;
  set f(_) {}
}
''');
    assertThat(findElement.field('f')).isWrittenAt('f = 42', true);
  }

  test_isReferencedBy_FieldElement_enum_synthetic_hasSetter() async {
    await _indexTestUnit('''
enum E {
  v;
  E() : f = 42;
  set f(_) {}
}
''');
    assertThat(findElement.field('f')).isWrittenAt('f = 42', true);
  }

  test_isReferencedBy_FunctionElement() async {
    await _indexTestUnit('''
foo() {}
main() {
  print(foo);
  print(foo());
}
''');
    FunctionElement element = findElement.topFunction('foo');
    assertThat(element)
      ..isReferencedAt('foo);', false)
      ..isInvokedAt('foo());', false);
  }

  test_isReferencedBy_FunctionElement_with_LibraryElement() async {
    newFile('$testPackageLibPath/foo.dart', r'''
bar() {}
''');
    await _indexTestUnit('''
import "foo.dart";
main() {
  bar();
}
''');

    var importFind = findElement.importFind('package:test/foo.dart');
    assertThat(importFind.importedLibrary)
        .isReferencedAt('"foo.dart";', true, length: 10);

    FunctionElement bar = importFind.topFunction('bar');
    assertThat(bar).isInvokedAt('bar();', false);
  }

  test_isReferencedBy_FunctionTypeAliasElement() async {
    await _indexTestUnit('''
typedef A();
main(A p) {
}
''');
    Element element = findElement.typeAlias('A');
    assertThat(element).isReferencedAt('A p) {', false);
  }

  /// There was a bug in the AST structure, when single [Comment] was cloned and
  /// assigned to both [FieldDeclaration] and [VariableDeclaration].
  ///
  /// This caused duplicate indexing.
  /// Here we test that the problem is fixed one way or another.
  test_isReferencedBy_identifierInComment() async {
    await _indexTestUnit('''
class A {}
/// [A] text
var myVariable = null;
''');
    Element element = findElement.class_('A');
    assertThat(element).isReferencedAt('A] text', false);
  }

  test_isReferencedBy_MethodElement_class() async {
    await _indexTestUnit('''
class A {
  method() {}
  main() {
    print(this.method); // q
    print(method); // nq
  }
}''');
    MethodElement element = findElement.method('method');
    assertThat(element)
      ..isReferencedAt('method); // q', true)
      ..isReferencedAt('method); // nq', false);
  }

  test_isReferencedBy_MethodElement_enum() async {
    await _indexTestUnit('''
enum E {
  v;
  void foo() {}
  void bar() {
    this.foo; // q1
    foo; // nq
  }
}
void f(E e) {
  e.foo; // q2
}
''');
    assertThat(findElement.method('foo'))
      ..isReferencedAt('foo; // q1', true)
      ..isReferencedAt('foo; // nq', false)
      ..isReferencedAt('foo; // q2', true);
  }

  test_isReferencedBy_MultiplyDefinedElement() async {
    newFile('$testPackageLibPath/a1.dart', 'class A {}');
    newFile('$testPackageLibPath/a2.dart', 'class A {}');
    await _indexTestUnit('''
import 'a1.dart';
import 'a2.dart';
A v = null;
''');
  }

  test_isReferencedBy_NeverElement() async {
    await _indexTestUnit('''
Never f() {
}''');
    expect(index.usedElementOffsets, isEmpty);
  }

  test_isReferencedBy_ParameterElement() async {
    await _indexTestUnit('''
foo({var p}) {}
main() {
  foo(p: 1);
}
''');
    Element element = findElement.parameter('p');
    assertThat(element).isReferencedAt('p: 1', true);
  }

  test_isReferencedBy_ParameterElement_genericFunctionType() async {
    await _indexTestUnit('''
typedef F = void Function({int? p});

void main(F f) {
  f(p: 0);
}
''');
    // We should not crash because of reference to "p" - a named parameter
    // of a generic function type.
  }

  test_isReferencedBy_ParameterElement_genericFunctionType_call() async {
    await _indexTestUnit('''
typedef F<T> = void Function({T? test});

main(F<int> f) {
  f.call(test: 0);
}
''');
    // No exceptions.
  }

  test_isReferencedBy_ParameterElement_multiplyDefined_generic() async {
    newFile('/test/lib/a.dart', r'''
void foo<T>({T? a}) {}
''');
    newFile('/test/lib/b.dart', r'''
void foo<T>({T? a}) {}
''');
    await _indexTestUnit(r"""
import 'a.dart';
import 'b.dart';

void main() {
  foo(a: 0);
}
""");
    // No exceptions.
  }

  test_isReferencedBy_ParameterElement_ofConstructor_super_named() async {
    await _indexTestUnit('''
class A {
  A({required int a});
}
class B extends A {
  B({required super.a}); // ref
}
''');
    var element = findElement.unnamedConstructor('A').parameter('a');
    assertThat(element).isReferencedAt('a}); // ref', true);
  }

  test_isReferencedBy_ParameterElement_ofConstructor_super_positional() async {
    await _indexTestUnit('''
class A {
  A(int a);
}
class B extends A {
  B(super.a); // ref
}
''');
    var element = findElement.unnamedConstructor('A').parameter('a');
    assertThat(element).isReferencedAt('a); // ref', true);
  }

  test_isReferencedBy_ParameterElement_optionalNamed_ofConstructor_genericClass() async {
    await _indexTestUnit('''
class A<T> {
  A({T? test});
}

main() {
  A(test: 0);
}
''');
    Element element = findElement.parameter('test');
    assertThat(element).isReferencedAt('test: 0', true);
  }

  test_isReferencedBy_ParameterElement_optionalNamed_ofMethod_genericClass() async {
    await _indexTestUnit('''
class A<T> {
  void foo({T? test}) {}
}

main(A<int> a) {
  a.foo(test: 0);
}
''');
    Element element = findElement.parameter('test');
    assertThat(element).isReferencedAt('test: 0', true);
  }

  test_isReferencedBy_ParameterElement_optionalNamed_ofTopFunction() async {
    await _indexTestUnit('''
void foo({int? test}) {}

void() {
  foo(test: 0);
}
''');
    Element element = findElement.parameter('test');
    assertThat(element).isReferencedAt('test: 0', true);
  }

  test_isReferencedBy_ParameterElement_optionalNamed_ofTopFunction_anywhere() async {
    await _indexTestUnit('''
void foo(int a, int b, {int? test}) {}

void() {
  foo(1, test: 0, 2);
}
''');
    Element element = findElement.parameter('test');
    assertThat(element).isReferencedAt('test: 0', true);
  }

  test_isReferencedBy_ParameterElement_optionalPositional() async {
    await _indexTestUnit('''
foo([p]) {
  p; // 1
}
main() {
  foo(1); // 2
}
''');
    Element element = findElement.parameter('p');
    assertThat(element)
      ..hasRelationCount(1)
      ..isReferencedAt('1); // 2', true, length: 0);
  }

  test_isReferencedBy_ParameterElement_requiredNamed_ofTopFunction() async {
    await _indexTestUnit('''
void foo({required int test}) {}

void() {
  foo(test: 0);
}
''');
    Element element = findElement.parameter('test');
    assertThat(element).isReferencedAt('test: 0', true);
  }

  test_isReferencedBy_PropertyAccessor_ofNamedExtension_instance() async {
    await _indexTestUnit('''
extension E on int {
  int get foo => 0;
  void set foo(int _) {}
}

main() {
  0.foo;
  0.foo = 0;
}
''');
    PropertyAccessorElement getter = findElement.getter('foo');
    PropertyAccessorElement setter = findElement.setter('foo');
    assertThat(getter).isReferencedAt('foo;', true);
    assertThat(setter).isReferencedAt('foo = 0;', true);
  }

  test_isReferencedBy_PropertyAccessor_ofNamedExtension_static() async {
    await _indexTestUnit('''
extension E on int {
  static int get foo => 0;
  static void set foo(int _) {}
}

main() {
  0.foo;
  0.foo = 0;
}
''');
    PropertyAccessorElement getter = findElement.getter('foo');
    PropertyAccessorElement setter = findElement.setter('foo');
    assertThat(getter).isReferencedAt('foo;', true);
    assertThat(setter).isReferencedAt('foo = 0;', true);
  }

  test_isReferencedBy_PropertyAccessor_ofUnnamedExtension_instance() async {
    await _indexTestUnit('''
extension on int {
  int get foo => 0; // int getter
  void set foo(int _) {} // int setter
}

extension on double {
  int get foo => 0; // double getter
  void set foo(int _) {} // double setter
}

main() {
  0.foo; // int getter ref
  0.foo = 0; // int setter ref
  (1.2).foo; // double getter ref
  (1.2).foo = 0; // double setter ref
}
''');

    var intGetter = findNode.methodDeclaration('0; // int getter');
    var intSetter = findNode.methodDeclaration('{} // int setter');
    assertThat(intGetter.declaredElement!)
        .isReferencedAt('foo; // int getter ref', true);
    assertThat(intSetter.declaredElement!)
        .isReferencedAt('foo = 0; // int setter ref', true);

    var doubleGetter = findNode.methodDeclaration('0; // double getter');
    var doubleSetter = findNode.methodDeclaration('{} // double setter');
    assertThat(doubleGetter.declaredElement!)
        .isReferencedAt('foo; // double getter ref', true);
    assertThat(doubleSetter.declaredElement!)
        .isReferencedAt('foo = 0; // double setter ref', true);
  }

  test_isReferencedBy_synthetic_leastUpperBound() async {
    await _indexTestUnit('''
int f1({int p}) => 1;
int f2({int p}) => 2;
main(bool b) {
  var f = b ? f1 : f2;
  f(p: 0);
}''');
    // We should not crash because of reference to "p" - a named parameter
    // of a synthetic LUB FunctionElement created for "f".
  }

  test_isReferencedBy_TopLevelVariableElement() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
var V;
''');
    await _indexTestUnit('''
import 'lib.dart' show V; // imp
import 'lib.dart' as pref;
main() {
  pref.V = 5; // q
  print(pref.V); // q
  V = 5; // nq
  print(V); // nq
}''');
    TopLevelVariableElement variable = importFindLib().topVar('V');
    assertThat(variable).isReferencedAt('V; // imp', true);
    assertThat(variable.getter!)
      ..isReferencedAt('V); // q', true)
      ..isReferencedAt('V); // nq', false);
    assertThat(variable.setter!)
      ..isReferencedAt('V = 5; // q', true)
      ..isReferencedAt('V = 5; // nq', false);
  }

  test_isReferencedBy_TopLevelVariableElement_synthetic_hasGetterSetter() async {
    newFile('$testPackageLibPath/lib.dart', '''
int get V => 0;
void set V(_) {}
''');
    await _indexTestUnit('''
import 'lib.dart' show V;
''');
    TopLevelVariableElement element = importFindLib().topVar('V');
    assertThat(element).isReferencedAt('V;', true);
  }

  test_isReferencedBy_TopLevelVariableElement_synthetic_hasSetter() async {
    newFile('$testPackageLibPath/lib.dart', '''
void set V(_) {}
''');
    await _indexTestUnit('''
import 'lib.dart' show V;
''');
    TopLevelVariableElement element = importFindLib().topVar('V');
    assertThat(element).isReferencedAt('V;', true);
  }

  test_isReferencedBy_TypeAliasElement() async {
    await _indexTestUnit('''
class A<T> {
  static int field = 0;
  static void method() {}
}

typedef B = A<int>;

void f(B p) {
  B v;
  B(); // 2
  B.field = 1;
  B.field; // 3
  B.method(); // 4
}
''');
    var element = findElement.typeAlias('B');
    assertThat(element)
      ..isReferencedAt('B p) {', false)
      ..isReferencedAt('B v;', false)
      ..isReferencedAt('B(); // 2', false)
      ..isReferencedAt('B.field = 1;', false)
      ..isReferencedAt('B.field; // 3', false)
      ..isReferencedAt('B.method(); // 4', false);
  }

  test_isReferencedBy_typeInVariableList() async {
    await _indexTestUnit('''
class A {}
A myVariable = null;
''');
    Element element = findElement.class_('A');
    assertThat(element).isReferencedAt('A myVariable', false);
  }

  test_isWrittenBy_FieldElement() async {
    await _indexTestUnit('''
class A {
  int field;
  A.foo({this.field});
  A.bar() : field = 5;
}
''');
    FieldElement element = findElement.field('field');
    assertThat(element)
      ..isWrittenAt('field})', true)
      ..isWrittenAt('field = 5', true);
  }

  test_subtypes_classDeclaration() async {
    String libP = 'package:test/lib.dart;package:test/lib.dart';
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
class C {}
class D {}
class E {}
''');
    await _indexTestUnit('''
import 'lib.dart';

class X extends A {
  X();
  X.namedConstructor();

  int field1, field2;
  int get getter1 => null;
  void set setter1(_) {}
  void method1() {}

  static int staticField;
  static void staticMethod() {}
}

class Y extends Object with B, C {
  void methodY() {}
}

class Z implements E, D {
  void methodZ() {}
}
''');

    expect(index.supertypes, hasLength(6));
    expect(index.subtypes, hasLength(6));

    _assertSubtype(0, 'dart:core;dart:core;Object', 'Y', ['methodY']);
    _assertSubtype(
      1,
      '$libP;A',
      'X',
      ['field1', 'field2', 'getter1', 'method1', 'setter1'],
    );
    _assertSubtype(2, '$libP;B', 'Y', ['methodY']);
    _assertSubtype(3, '$libP;C', 'Y', ['methodY']);
    _assertSubtype(4, '$libP;D', 'Z', ['methodZ']);
    _assertSubtype(5, '$libP;E', 'Z', ['methodZ']);
  }

  test_subtypes_classTypeAlias() async {
    String libP = 'package:test/lib.dart;package:test/lib.dart';
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
class C {}
class D {}
''');
    await _indexTestUnit('''
import 'lib.dart';

class X = A with B, C;
class Y = A with B implements C, D;
''');

    expect(index.supertypes, hasLength(7));
    expect(index.subtypes, hasLength(7));

    _assertSubtype(0, '$libP;A', 'X', []);
    _assertSubtype(1, '$libP;A', 'Y', []);
    _assertSubtype(2, '$libP;B', 'X', []);
    _assertSubtype(3, '$libP;B', 'Y', []);
    _assertSubtype(4, '$libP;C', 'X', []);
    _assertSubtype(5, '$libP;C', 'Y', []);
    _assertSubtype(6, '$libP;D', 'Y', []);
  }

  test_subtypes_dynamic() async {
    await _indexTestUnit('''
class X extends dynamic {
  void foo() {}
}
''');

    expect(index.supertypes, isEmpty);
    expect(index.subtypes, isEmpty);
  }

  test_subtypes_enum_implements() async {
    String libP = 'package:test/test.dart;package:test/test.dart';
    await _indexTestUnit('''
class A {}

enum E implements A {
  v;
  void foo() {}
}
''');

    expect(index.subtypes, hasLength(1));
    _assertSubtype(0, '$libP;A', 'E', ['foo']);
  }

  test_subtypes_enum_with() async {
    String libP = 'package:test/test.dart;package:test/test.dart';
    await _indexTestUnit('''
mixin M {}

enum E with M {
  v;
  void foo() {}
}
''');

    expect(index.subtypes, hasLength(1));
    _assertSubtype(0, '$libP;M', 'E', ['foo']);
  }

  test_subtypes_mixinDeclaration() async {
    String libP = 'package:test/lib.dart;package:test/lib.dart';
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
class C {}
class D {}
class E {}
''');
    await _indexTestUnit('''
import 'lib.dart';

mixin X on A implements B, C {}
mixin Y on A, B implements C;
''');

    expect(index.supertypes, hasLength(6));
    expect(index.subtypes, hasLength(6));

    _assertSubtype(0, '$libP;A', 'X', []);
    _assertSubtype(1, '$libP;A', 'Y', []);
    _assertSubtype(2, '$libP;B', 'X', []);
    _assertSubtype(3, '$libP;B', 'Y', []);
    _assertSubtype(4, '$libP;C', 'X', []);
    _assertSubtype(5, '$libP;C', 'Y', []);
  }

  test_usedName_inLibraryIdentifier() async {
    await _indexTestUnit('''
library aaa.bbb.ccc;
class C {
  var bbb;
}
main(p) {
  p.bbb = 1;
}
''');
    assertThatName('bbb')
      ..isNotUsed('bbb.ccc', IndexRelationKind.IS_READ_BY)
      ..isUsedQ('bbb = 1;', IndexRelationKind.IS_WRITTEN_BY);
  }

  test_usedName_qualified_resolved() async {
    await _indexTestUnit('''
class C {
  var x;
}
main(C c) {
  c.x; // 1
  c.x = 1;
  c.x += 2;
  c.x();
}
''');
    assertThatName('x')
      ..isNotUsedQ('x; // 1', IndexRelationKind.IS_READ_BY)
      ..isNotUsedQ('x = 1;', IndexRelationKind.IS_WRITTEN_BY)
      ..isNotUsedQ('x += 2;', IndexRelationKind.IS_READ_WRITTEN_BY)
      ..isNotUsedQ('x();', IndexRelationKind.IS_INVOKED_BY);
  }

  test_usedName_qualified_unresolved() async {
    await _indexTestUnit('''
main(p) {
  p.x;
  p.x = 1;
  p.x += 2;
  p.x();
}
''');
    assertThatName('x')
      ..isUsedQ('x;', IndexRelationKind.IS_READ_BY)
      ..isUsedQ('x = 1;', IndexRelationKind.IS_WRITTEN_BY)
      ..isUsedQ('x += 2;', IndexRelationKind.IS_READ_WRITTEN_BY)
      ..isUsedQ('x();', IndexRelationKind.IS_INVOKED_BY);
  }

  test_usedName_unqualified_resolved() async {
    await _indexTestUnit('''
class C {
  var x;
  m() {
    x; // 1
    x = 1;
    x += 2;
    x();
  }
}
''');
    assertThatName('x')
      ..isNotUsedQ('x; // 1', IndexRelationKind.IS_READ_BY)
      ..isNotUsedQ('x = 1;', IndexRelationKind.IS_WRITTEN_BY)
      ..isNotUsedQ('x += 2;', IndexRelationKind.IS_READ_WRITTEN_BY)
      ..isNotUsedQ('x();', IndexRelationKind.IS_INVOKED_BY);
  }

  test_usedName_unqualified_unresolved() async {
    await _indexTestUnit('''
main() {
  x;
  x = 1;
  x += 2;
  x();
}
''');
    assertThatName('x')
      ..isUsed('x;', IndexRelationKind.IS_READ_BY)
      ..isUsed('x = 1;', IndexRelationKind.IS_WRITTEN_BY)
      ..isUsed('x += 2;', IndexRelationKind.IS_READ_WRITTEN_BY)
      ..isUsed('x();', IndexRelationKind.IS_INVOKED_BY);
  }
}

class _ElementIndexAssert {
  final _IndexMixin test;
  final Element element;
  final List<_Relation> relations;

  _ElementIndexAssert(this.test, this.element, this.relations);

  void hasRelationCount(int expectedCount) {
    expect(relations, hasLength(expectedCount));
  }

  void isAncestorOf(String search, {int? length}) {
    test._assertHasRelation(
        element,
        relations,
        IndexRelationKind.IS_ANCESTOR_OF,
        test._expectedLocation(search, false, length: length));
  }

  void isExtendedAt(String search, bool isQualified, {int? length}) {
    test._assertHasRelation(
        element,
        relations,
        IndexRelationKind.IS_EXTENDED_BY,
        test._expectedLocation(search, isQualified, length: length));
  }

  void isImplementedAt(String search, bool isQualified, {int? length}) {
    test._assertHasRelation(
        element,
        relations,
        IndexRelationKind.IS_IMPLEMENTED_BY,
        test._expectedLocation(search, isQualified, length: length));
  }

  void isInvokedAt(String search, bool isQualified, {int? length}) {
    test._assertHasRelation(element, relations, IndexRelationKind.IS_INVOKED_BY,
        test._expectedLocation(search, isQualified, length: length));
  }

  void isInvokedByEnumConstantWithoutArgumentsAt(String search,
      {required int length}) {
    test._assertHasRelation(
      element,
      relations,
      IndexRelationKind.IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS,
      test._expectedLocation(search, true, length: length),
    );
  }

  void isMixedInAt(String search, bool isQualified, {int? length}) {
    test._assertHasRelation(
        element,
        relations,
        IndexRelationKind.IS_MIXED_IN_BY,
        test._expectedLocation(search, isQualified, length: length));
  }

  void isReferencedAt(String search, bool isQualified, {int? length}) {
    test._assertHasRelation(
        element,
        relations,
        IndexRelationKind.IS_REFERENCED_BY,
        test._expectedLocation(search, isQualified, length: length));
  }

  void isReferencedByConstructorTearOffAt(String search,
      {required int length}) {
    test._assertHasRelation(
      element,
      relations,
      IndexRelationKind.IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF,
      test._expectedLocation(search, true, length: length),
    );
  }

  void isWrittenAt(String search, bool isQualified, {int? length}) {
    test._assertHasRelation(element, relations, IndexRelationKind.IS_WRITTEN_BY,
        test._expectedLocation(search, isQualified, length: length));
  }
}

mixin _IndexMixin on PubPackageResolutionTest {
  late AnalysisDriverUnitIndex index;

  _ElementIndexAssert assertThat(Element element) {
    List<_Relation> relations = _getElementRelations(element);
    return _ElementIndexAssert(this, element, relations);
  }

  _NameIndexAssert assertThatName(String name) {
    return _NameIndexAssert(this, name);
  }

  /// Return [ImportFindElement] for 'package:test/lib.dart' import.
  ImportFindElement importFindLib() {
    return findElement.importFind(
      'package:test/lib.dart',
      mustBeUnique: false,
    );
  }

  /// Asserts that [index] has an item with the expected properties.
  void _assertHasRelation(
      Element element,
      List<_Relation> relations,
      IndexRelationKind expectedRelationKind,
      ExpectedLocation expectedLocation) {
    for (_Relation relation in relations) {
      if (relation.kind == expectedRelationKind &&
          relation.offset == expectedLocation.offset &&
          relation.length == expectedLocation.length &&
          relation.isQualified == expectedLocation.isQualified) {
        return;
      }
    }
    _failWithIndexDump(
        'not found\n$element $expectedRelationKind at $expectedLocation');
  }

  void _assertSubtype(
      int i, String superEncoded, String subName, List<String> members) {
    expect(index.strings[index.supertypes[i]], superEncoded);
    var subtype = index.subtypes[i];
    expect(index.strings[subtype.name], subName);
    expect(_decodeStringList(subtype.members), members);
  }

  void _assertUsedName(String name, IndexRelationKind kind,
      ExpectedLocation expectedLocation, bool isNot) {
    int nameId = _getStringId(name);
    for (int i = 0; i < index.usedNames.length; i++) {
      if (index.usedNames[i] == nameId &&
          index.usedNameKinds[i] == kind &&
          index.usedNameOffsets[i] == expectedLocation.offset &&
          index.usedNameIsQualifiedFlags[i] == expectedLocation.isQualified) {
        if (isNot) {
          _failWithIndexDump('Unexpected $name $kind at $expectedLocation');
        }
        return;
      }
    }
    if (isNot) {
      return;
    }
    _failWithIndexDump('Not found $name $kind at $expectedLocation');
  }

  List<String> _decodeStringList(List<int> stringIds) {
    return stringIds.map((i) => index.strings[i]).toList();
  }

  ExpectedLocation _expectedLocation(String search, bool isQualified,
      {int? length}) {
    int offset = findNode.offset(search);
    length ??= findNode.simple(search).length;
    return ExpectedLocation(offset, length, isQualified);
  }

  void _failWithIndexDump(String msg) {
    String packageIndexJsonString =
        JsonEncoder.withIndent('  ').convert(index.toJson());
    fail('$msg in\n$packageIndexJsonString');
  }

  /// Return the [element] identifier in [index] or fail.
  int _findElementId(Element element) {
    var unitId = _getUnitId(element);

    // Prepare the element that was put into the index.
    IndexElementInfo info = IndexElementInfo(element);
    element = info.element;

    // Prepare element's name components.
    var components = ElementNameComponents(element);
    var unitMemberId = _getStringId(components.unitMemberName);
    var classMemberId = _getStringId(components.classMemberName);
    var parameterId = _getStringId(components.parameterName);

    // Find the element's id.
    for (int elementId = 0;
        elementId < index.elementUnits.length;
        elementId++) {
      if (index.elementUnits[elementId] == unitId &&
          index.elementNameUnitMemberIds[elementId] == unitMemberId &&
          index.elementNameClassMemberIds[elementId] == classMemberId &&
          index.elementNameParameterIds[elementId] == parameterId &&
          index.elementKinds[elementId] == info.kind) {
        return elementId;
      }
    }
    _failWithIndexDump('Element $element is not referenced');
    return 0;
  }

  /// Return all relations with [element] in [index].
  List<_Relation> _getElementRelations(Element element) {
    int elementId = _findElementId(element);
    List<_Relation> relations = <_Relation>[];
    for (int i = 0; i < index.usedElementOffsets.length; i++) {
      if (index.usedElements[i] == elementId) {
        relations.add(_Relation(
            index.usedElementKinds[i],
            index.usedElementOffsets[i],
            index.usedElementLengths[i],
            index.usedElementIsQualifiedFlags[i]));
      }
    }
    return relations;
  }

  int _getStringId(String? str) {
    if (str == null) {
      return index.nullStringId;
    }

    int id = index.strings.indexOf(str);
    if (id < 0) {
      _failWithIndexDump('String "$str" is not referenced');
    }
    return id;
  }

  int _getUnitId(Element element) {
    CompilationUnitElement unitElement = getUnitElement(element);
    int libraryUriId = _getUriId(unitElement.library.source.uri);
    int unitUriId = _getUriId(unitElement.source.uri);
    expect(index.unitLibraryUris, hasLength(index.unitUnitUris.length));
    for (int i = 0; i < index.unitLibraryUris.length; i++) {
      if (index.unitLibraryUris[i] == libraryUriId &&
          index.unitUnitUris[i] == unitUriId) {
        return i;
      }
    }
    _failWithIndexDump('Unit $unitElement of $element is not referenced');
    return -1;
  }

  int _getUriId(Uri uri) {
    String str = uri.toString();
    return _getStringId(str);
  }

  Future<void> _indexTestUnit(String code) async {
    await resolveTestCode(code);

    var indexBuilder = indexUnit(result.unit);
    var indexBytes = indexBuilder.toBuffer();
    index = AnalysisDriverUnitIndex.fromBuffer(indexBytes);
  }
}

class _NameIndexAssert {
  final _IndexMixin test;
  final String name;

  _NameIndexAssert(this.test, this.name);

  void isNotUsed(String search, IndexRelationKind kind) {
    test._assertUsedName(
        name, kind, test._expectedLocation(search, false), true);
  }

  void isNotUsedQ(String search, IndexRelationKind kind) {
    test._assertUsedName(
        name, kind, test._expectedLocation(search, true), true);
  }

  void isUsed(String search, IndexRelationKind kind) {
    test._assertUsedName(
        name, kind, test._expectedLocation(search, false), false);
  }

  void isUsedQ(String search, IndexRelationKind kind) {
    test._assertUsedName(
        name, kind, test._expectedLocation(search, true), false);
  }
}

class _Relation {
  final IndexRelationKind kind;
  final int offset;
  final int length;
  final bool isQualified;

  _Relation(this.kind, this.offset, this.length, this.isQualified);

  @override
  String toString() {
    return '_Relation{kind: $kind, offset: $offset, length: $length, '
        'isQualified: $isQualified}lified)';
  }
}
