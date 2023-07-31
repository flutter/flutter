// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/index.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IndexTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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
  void assertElementIndexText(Element element, String expected) {
    var actual = _getRelationsText(element);
    if (actual != expected) {
      print(actual);
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

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
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
17 2:7 |B1| IS_ANCESTOR_OF
28 2:18 |A| IS_EXTENDED_BY
28 2:18 |A| IS_REFERENCED_BY
39 3:7 |B2| IS_ANCESTOR_OF
53 3:21 |A| IS_IMPLEMENTED_BY
53 3:21 |A| IS_REFERENCED_BY
64 4:7 |C1| IS_ANCESTOR_OF
87 5:7 |C2| IS_ANCESTOR_OF
110 6:7 |C3| IS_ANCESTOR_OF
136 7:7 |C4| IS_ANCESTOR_OF
162 8:7 |M| IS_ANCESTOR_OF
184 8:29 |A| IS_MIXED_IN_BY
184 8:29 |A| IS_REFERENCED_BY
''');
  }

  test_hasAncestor_ClassTypeAlias() async {
    await _indexTestUnit('''
class A {}
class B extends A {}
class C1 = Object with A;
class C2 = Object with B;
''');

    final elementA = findElement.class_('A');
    assertElementIndexText(elementA, r'''
17 2:7 |B| IS_ANCESTOR_OF
27 2:17 |A| IS_EXTENDED_BY
27 2:17 |A| IS_REFERENCED_BY
38 3:7 |C1| IS_ANCESTOR_OF
55 3:24 |A| IS_MIXED_IN_BY
55 3:24 |A| IS_REFERENCED_BY
64 4:7 |C2| IS_ANCESTOR_OF
''');

    final elementB = findElement.class_('B');
    assertElementIndexText(elementB, r'''
64 4:7 |C2| IS_ANCESTOR_OF
81 4:24 |B| IS_MIXED_IN_BY
81 4:24 |B| IS_REFERENCED_BY
''');
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
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
17 2:7 |B| IS_ANCESTOR_OF
27 2:17 |A| IS_EXTENDED_BY
27 2:17 |A| IS_REFERENCED_BY
39 4:7 |M1| IS_ANCESTOR_OF
45 4:13 |A| CONSTRAINS
45 4:13 |A| IS_REFERENCED_BY
56 5:7 |M2| IS_ANCESTOR_OF
73 6:7 |M3| IS_ANCESTOR_OF
87 6:21 |A| IS_IMPLEMENTED_BY
87 6:21 |A| IS_REFERENCED_BY
98 7:7 |M4| IS_ANCESTOR_OF
123 8:7 |M5| IS_ANCESTOR_OF
''');
  }

  test_isConstraint_MixinDeclaration_onClause() async {
    await _indexTestUnit('''
class A {} // 1
mixin M on A {} // 2
''');
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
22 2:7 |M| IS_ANCESTOR_OF
27 2:12 |A| CONSTRAINS
27 2:12 |A| IS_REFERENCED_BY
''');
  }

  test_isExtendedBy_ClassDeclaration_isQualified() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;
class B extends p.A {} // 2
''');
    final element = importFindLib().class_('A');
    assertElementIndexText(element, r'''
30 2:7 |B| IS_ANCESTOR_OF
42 2:19 |A| IS_EXTENDED_BY qualified
42 2:19 |A| IS_REFERENCED_BY qualified
Prefixes: p
''');
  }

  test_isExtendedBy_ClassDeclaration_Object() async {
    await _indexTestUnit('''
class A {}
''');
    final elementA = findElement.class_('A');
    final elementObject = elementA.supertype!.element;
    assertElementIndexText(elementObject, r'''
6 1:7 |A| IS_ANCESTOR_OF
6 1:7 || IS_EXTENDED_BY qualified
''');
  }

  test_isExtendedBy_ClassDeclaration_TypeAliasElement() async {
    await _indexTestUnit('''
class A<T> {}
typedef B = A<int>;
class C extends B {}
''');
    final element = findElement.typeAlias('B');
    assertElementIndexText(element, r'''
50 3:17 |B| IS_EXTENDED_BY
50 3:17 |B| IS_REFERENCED_BY
''');
  }

  test_isExtendedBy_ClassTypeAlias() async {
    await _indexTestUnit('''
class A {}
class B {}
class C = A with B;
''');
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
28 3:7 |C| IS_ANCESTOR_OF
32 3:11 |A| IS_EXTENDED_BY
32 3:11 |A| IS_REFERENCED_BY
''');
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
    final element = importFindLib().class_('A');
    assertElementIndexText(element, r'''
41 3:7 |C| IS_ANCESTOR_OF
47 3:13 |A| IS_EXTENDED_BY qualified
47 3:13 |A| IS_REFERENCED_BY qualified
Prefixes: p
''');
  }

  test_isImplementedBy_ClassDeclaration() async {
    await _indexTestUnit('''
class A {} // 1
class B implements A {} // 2
''');
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
22 2:7 |B| IS_ANCESTOR_OF
35 2:20 |A| IS_IMPLEMENTED_BY
35 2:20 |A| IS_REFERENCED_BY
''');
  }

  test_isImplementedBy_ClassDeclaration_isQualified() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;
class B implements p.A {} // 2
''');
    final element = importFindLib().class_('A');
    assertElementIndexText(element, r'''
30 2:7 |B| IS_ANCESTOR_OF
45 2:22 |A| IS_IMPLEMENTED_BY qualified
45 2:22 |A| IS_REFERENCED_BY qualified
Prefixes: p
''');
  }

  test_isImplementedBy_ClassDeclaration_TypeAliasElement() async {
    await _indexTestUnit('''
class A<T> {}
typedef B = A<int>;
class C implements B {}
''');
    final element = findElement.typeAlias('B');
    assertElementIndexText(element, r'''
53 3:20 |B| IS_IMPLEMENTED_BY
53 3:20 |B| IS_REFERENCED_BY
''');
  }

  test_isImplementedBy_ClassTypeAlias() async {
    await _indexTestUnit('''
class A {} // 1
class B {} // 2
class C = Object with A implements B; // 3
''');
    final element = findElement.class_('B');
    assertElementIndexText(element, r'''
38 3:7 |C| IS_ANCESTOR_OF
67 3:36 |B| IS_IMPLEMENTED_BY
67 3:36 |B| IS_REFERENCED_BY
''');
  }

  test_isImplementedBy_enum() async {
    await _indexTestUnit('''
class A {} // 1
enum E implements A { // 2
  v;
}
''');
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
21 2:6 |E| IS_ANCESTOR_OF
34 2:19 |A| IS_IMPLEMENTED_BY
34 2:19 |A| IS_REFERENCED_BY
''');
  }

  test_isImplementedBy_MixinDeclaration_implementsClause() async {
    await _indexTestUnit('''
class A {} // 1
mixin M implements A {} // 2
''');
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
22 2:7 |M| IS_ANCESTOR_OF
35 2:20 |A| IS_IMPLEMENTED_BY
35 2:20 |A| IS_REFERENCED_BY
''');
  }

  test_isInvokedBy_FunctionElement() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
foo() {}
''');
    await _indexTestUnit('''
import 'lib.dart';
import 'lib.dart' as pref;
void f() {
  pref.foo(); // q
  foo(); // nq
}''');
    final element = importFindLib().topFunction('foo');
    assertElementIndexText(element, r'''
64 4:8 |foo| IS_INVOKED_BY qualified
78 5:3 |foo| IS_INVOKED_BY
''');
  }

  test_isInvokedBy_FunctionElement_synthetic_loadLibrary() async {
    await _indexTestUnit('''
import 'dart:math' deferred as math;
void f() {
  math.loadLibrary(); // 1
  math.loadLibrary(); // 2
}
''');
    LibraryElement mathLib = findElement.import('dart:math').importedLibrary!;
    final element = mathLib.loadLibraryFunction;
    assertElementIndexText(element, r'''
55 3:8 |loadLibrary| IS_INVOKED_BY qualified
82 4:8 |loadLibrary| IS_INVOKED_BY qualified
''');
  }

  test_isInvokedBy_MethodElement_class() async {
    await _indexTestUnit('''
class A {
  foo() {}
  void m() {
    this.foo(); // q
    foo(); // nq
  }
}''');
    final element = findElement.method('foo');
    assertElementIndexText(element, r'''
43 4:10 |foo| IS_INVOKED_BY qualified
59 5:5 |foo| IS_INVOKED_BY
''');
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
    final element = findElement.method('foo');
    assertElementIndexText(element, r'''
54 5:10 |foo| IS_INVOKED_BY qualified
71 6:5 |foo| IS_INVOKED_BY
108 10:5 |foo| IS_INVOKED_BY qualified
''');
  }

  test_isInvokedBy_MethodElement_ofNamedExtension_instance() async {
    await _indexTestUnit('''
extension E on int {
  void foo() {}
}

void f() {
  0.foo();
}
''');
    final element = findElement.method('foo');
    assertElementIndexText(element, r'''
55 6:5 |foo| IS_INVOKED_BY qualified
''');
  }

  test_isInvokedBy_MethodElement_ofNamedExtension_static() async {
    await _indexTestUnit('''
extension E on int {
  static void foo() {}
}

void f() {
  E.foo();
}
''');
    final element = findElement.method('foo');
    assertElementIndexText(element, r'''
62 6:5 |foo| IS_INVOKED_BY qualified
''');
  }

  test_isInvokedBy_MethodElement_ofUnnamedExtension_instance() async {
    await _indexTestUnit('''
extension on int {
  void foo() {} // int
}

extension on double {
  void foo() {} // double
}

void f() {
  0.foo(); // int ref
  (1.2).foo(); // double ref
}
''');

    var intMethod = findNode.methodDeclaration('foo() {} // int');
    assertElementIndexText(intMethod.declaredElement!, r'''
111 10:5 |foo| IS_INVOKED_BY qualified
''');

    var doubleMethod = findNode.methodDeclaration('foo() {} // double');
    assertElementIndexText(doubleMethod.declaredElement!, r'''
137 11:9 |foo| IS_INVOKED_BY qualified
''');
  }

  test_isInvokedBy_MethodElement_propagatedType() async {
    await _indexTestUnit('''
class A {
  foo() {}
}
void f() {
  var a = new A();
  a.foo();
}
''');
    final element = findElement.method('foo');
    assertElementIndexText(element, r'''
57 6:5 |foo| IS_INVOKED_BY qualified
''');
  }

  test_isInvokedBy_operator_class_binary() async {
    await _indexTestUnit('''
class A {
  operator +(other) => this;
}
void f(A a) {
  print(a + 1);
  a += 2;
  ++a;
  a++;
}
''');
    final element = findElement.method('+');
    assertElementIndexText(element, r'''
65 5:11 |+| IS_INVOKED_BY qualified
75 6:5 |+=| IS_INVOKED_BY qualified
83 7:3 |++| IS_INVOKED_BY qualified
91 8:4 |++| IS_INVOKED_BY qualified
''');
  }

  test_isInvokedBy_operator_class_index() async {
    await _indexTestUnit('''
class A {
  operator [](i) => null;
  operator []=(i, v) {}
}
void f(A a) {
  print(a[0]);
  a[1] = 42;
}
''');
    final readElement = findElement.method('[]');
    assertElementIndexText(readElement, r'''
85 6:10 |[| IS_INVOKED_BY qualified
''');

    final writeElement = findElement.method('[]=');
    assertElementIndexText(writeElement, r'''
94 7:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_isInvokedBy_operator_class_prefix() async {
    await _indexTestUnit('''
class A {
  A operator ~() => this;
}
void f(A a) {
  print(~a);
}
''');
    final element = findElement.method('~');
    assertElementIndexText(element, r'''
60 5:9 |~| IS_INVOKED_BY qualified
''');
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
    final element = findElement.method('+');
    assertElementIndexText(element, r'''
64 6:5 |+| IS_INVOKED_BY qualified
73 7:5 |+=| IS_INVOKED_BY qualified
81 8:3 |++| IS_INVOKED_BY qualified
89 9:4 |++| IS_INVOKED_BY qualified
''');
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
    final readElement = findElement.method('[]');
    assertElementIndexText(readElement, r'''
108 7:4 |[| IS_INVOKED_BY qualified
''');

    final writeElement = findElement.method('[]=');
    assertElementIndexText(writeElement, r'''
116 8:4 |[| IS_INVOKED_BY qualified
''');
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
    final element = findElement.method('~');
    assertElementIndexText(element, r'''
57 6:3 |~| IS_INVOKED_BY qualified
''');
  }

  test_isMixedBy_ClassDeclaration_TypeAliasElement() async {
    await _indexTestUnit('''
class A<T> {}
typedef B = A<int>;
class C extends Object with B {}
''');
    final element = findElement.typeAlias('B');
    assertElementIndexText(element, r'''
62 3:29 |B| IS_MIXED_IN_BY
62 3:29 |B| IS_REFERENCED_BY
''');
  }

  test_isMixedInBy_ClassDeclaration_class() async {
    await _indexTestUnit('''
class A {} // 1
class B extends Object with A {} // 2
''');
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
22 2:7 |B| IS_ANCESTOR_OF
44 2:29 |A| IS_MIXED_IN_BY
44 2:29 |A| IS_REFERENCED_BY
''');
  }

  test_isMixedInBy_ClassDeclaration_isQualified() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;
class B extends Object with p.A {} // 2
''');
    final element = importFindLib().class_('A');
    assertElementIndexText(element, r'''
30 2:7 |B| IS_ANCESTOR_OF
54 2:31 |A| IS_MIXED_IN_BY qualified
54 2:31 |A| IS_REFERENCED_BY qualified
Prefixes: p
''');
  }

  test_isMixedInBy_ClassDeclaration_mixin() async {
    await _indexTestUnit('''
mixin A {} // 1
class B extends Object with A {} // 2
''');
    final element = findElement.mixin('A');
    assertElementIndexText(element, r'''
22 2:7 |B| IS_ANCESTOR_OF
44 2:29 |A| IS_MIXED_IN_BY
44 2:29 |A| IS_REFERENCED_BY
''');
  }

  test_isMixedInBy_ClassTypeAlias_class() async {
    await _indexTestUnit('''
class A {} // 1
class B = Object with A; // 2
''');
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
22 2:7 |B| IS_ANCESTOR_OF
38 2:23 |A| IS_MIXED_IN_BY
38 2:23 |A| IS_REFERENCED_BY
''');
  }

  test_isMixedInBy_ClassTypeAlias_mixin() async {
    await _indexTestUnit('''
mixin A {} // 1
class B = Object with A; // 2
''');
    final element = findElement.mixin('A');
    assertElementIndexText(element, r'''
22 2:7 |B| IS_ANCESTOR_OF
38 2:23 |A| IS_MIXED_IN_BY
38 2:23 |A| IS_REFERENCED_BY
''');
  }

  test_isMixedInBy_enum_mixin() async {
    await _indexTestUnit('''
mixin M {} // 1
enum E with M { // 2
  v
}
''');
    final element = findElement.mixin('M');
    assertElementIndexText(element, r'''
21 2:6 |E| IS_ANCESTOR_OF
28 2:13 |M| IS_MIXED_IN_BY
28 2:13 |M| IS_REFERENCED_BY
''');
  }

  test_isReferencedAt_PropertyAccessorElement_field_call() async {
    await _indexTestUnit('''
class A {
  var field;
  void m() {
    this.field(); // q
    field(); // nq
  }
}''');
    final element = findElement.getter('field');
    assertElementIndexText(element, r'''
45 4:10 |field| IS_REFERENCED_BY qualified
63 5:5 |field| IS_REFERENCED_BY
''');
  }

  test_isReferencedAt_PropertyAccessorElement_getter_call() async {
    await _indexTestUnit('''
class A {
  get ggg => null;
  void m() {
    this.ggg(); // q
    ggg(); // nq
  }
}''');
    PropertyAccessorElement element = findElement.getter('ggg');
    assertElementIndexText(element, r'''
51 4:10 |ggg| IS_REFERENCED_BY qualified
67 5:5 |ggg| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_class_getter_in_objectPattern() async {
    await _indexTestUnit('''
void f(Object? x) {
  if (x case A(foo: 0)) {}
  if (x case A(: var foo)) {}
}

class A {
  int get foo => 0;
}
''');
    final element = findElement.getter('foo');
    assertElementIndexText(element, r'''
35 2:16 |foo| IS_REFERENCED_BY qualified
62 3:16 || IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_class_method_in_objectPattern() async {
    await _indexTestUnit('''
void f(Object? x) {
  if (x case A(foo: _)) {}
  if (x case A(: var foo)) {}
}

class A {
  void foo() {}
}
''');
    final element = findElement.method('foo');
    assertElementIndexText(element, r'''
35 2:16 |foo| IS_REFERENCED_BY qualified
62 3:16 || IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_ClassElement() async {
    await _indexTestUnit('''
class A {
  static var field;
}
void f(A p) {
  A v;
  new A(); // 2
  A.field = 1;
  print(A.field); // 3
}
''');
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
39 4:8 |A| IS_REFERENCED_BY
48 5:3 |A| IS_REFERENCED_BY
59 6:7 |A| IS_REFERENCED_BY
71 7:3 |A| IS_REFERENCED_BY
92 8:9 |A| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_ClassElement_enum() async {
    await _indexTestUnit('''
enum MyEnum {a}

void f(MyEnum p) {
  MyEnum v;
  MyEnum.a;
}
''');
    final element = findElement.enum_('MyEnum');
    assertElementIndexText(element, r'''
24 3:8 |MyEnum| IS_REFERENCED_BY
38 4:3 |MyEnum| IS_REFERENCED_BY
50 5:3 |MyEnum| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_ClassElement_fromExtension() async {
    await _indexTestUnit('''
class A<T> {}

extension E on A<int> {}
''');
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
30 3:16 |A| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_ClassElement_implicitNew() async {
    await _indexTestUnit('''
class A {}
void f() {
  A(); // invalid code, but still a reference
}''');
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
24 3:3 |A| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_ClassElement_inGenericAnnotation() async {
    await _indexTestUnit('''
class A<T> {
  const A();
}

@A<A>()
void f() {}
''');
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
21 2:9 |A| IS_REFERENCED_BY
30 5:2 |A| IS_REFERENCED_BY
32 5:4 |A| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_ClassElement_inRecordTypeAnnotation_named() async {
    await _indexTestUnit('''
class A {}

void f(({int foo, A bar}) r) {}
''');
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
30 3:19 |A| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_ClassElement_inRecordTypeAnnotation_positional() async {
    await _indexTestUnit('''
class A {}

void f((int, A) r) {}
''');
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
25 3:14 |A| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_ClassElement_inTypeAlias() async {
    await _indexTestUnit('''
class A<T> {}

typedef B = A<int>;
''');
    final elementA = findElement.class_('A');
    assertElementIndexText(elementA, r'''
27 3:13 |A| IS_REFERENCED_BY
''');

    assertElementIndexText(intElement, r'''
29 3:15 |int| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_ClassElement_invocation_isQualified() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;
void f() {
  p.A(); // invalid code, but still a reference
}''');
    final element = importFindLib().class_('A');
    assertElementIndexText(element, r'''
39 3:5 |A| IS_REFERENCED_BY qualified
Prefixes: p
''');
  }

  test_isReferencedBy_ClassElement_invocationTypeArgument() async {
    await _indexTestUnit('''
class A {}
void f<T>() {}
void g() {
  f<A>();
}
''');
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
41 4:5 |A| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_ClassTypeAlias() async {
    await _indexTestUnit('''
class A {}
class B = Object with A;
void f(B p) {
  B v;
}
''');
    final element = findElement.class_('B');
    assertElementIndexText(element, r'''
43 3:8 |B| IS_REFERENCED_BY
52 4:3 |B| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_commentReference() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart';

/// An [A].
void f(A a) {}
''');
    final element = findElement.function('f').parameters[0].type.element!;
    assertElementIndexText(element, r'''
28 3:9 |A| IS_REFERENCED_BY
39 4:8 |A| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_commentReference_withPrefix() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;

/// A [p.A].
void f(p.A a) {}
''');
    final element = findElement.function('f').parameters[0].type.element!;
    assertElementIndexText(element, r'''
34 3:10 |A| IS_REFERENCED_BY qualified
47 4:10 |A| IS_REFERENCED_BY qualified
Prefixes: p
''');
  }

  test_isReferencedBy_CompilationUnitElement_export() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await _indexTestUnit('''
export 'lib.dart';
''');
    final element =
        findElement.export('package:test/lib.dart').exportedLibrary!;
    assertElementIndexText(element, r'''
7 1:8 |'lib.dart'| IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_CompilationUnitElement_import() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await _indexTestUnit('''
import 'lib.dart';
''');
    final element =
        findElement.import('package:test/lib.dart').importedLibrary!;
    assertElementIndexText(element, r'''
7 1:8 |'lib.dart'| IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_CompilationUnitElement_part() async {
    newFile('$testPackageLibPath/my_unit.dart', 'part of my_lib;');
    await _indexTestUnit('''
library my_lib;
part 'my_unit.dart';
''');
    final element = findElement.part('package:test/my_unit.dart');
    assertElementIndexText(element, r'''
21 2:6 |'my_unit.dart'| IS_REFERENCED_BY qualified
''');
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
    final element = findElement.constructor('foo');
    assertElementIndexText(element, r'''
10 1:11 |.foo| IS_REFERENCED_BY qualified
57 4:17 |.foo| IS_INVOKED_BY qualified
105 7:14 |.foo| IS_INVOKED_BY qualified
139 8:22 |.foo| IS_REFERENCED_BY qualified
166 11:4 |.foo| IS_INVOKED_BY qualified
182 12:4 |.foo| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
''');
  }

  test_isReferencedBy_ConstructorElement_class_namedOnlyWithDot() async {
    await _indexTestUnit('''
class A {
  A.named() {}
}
void f() {
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
    final constructor = findElement.unnamedConstructor('A');
    assertElementIndexText(constructor, r'''
51 3:17 || IS_INVOKED_BY qualified
''');

    final constructor_bar = findElement.constructor('bar');
    assertElementIndexText(constructor_bar, r'''
22 2:13 |.bar| IS_INVOKED_BY qualified
''');
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
    final element = findElement.unnamedConstructor('A');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
51 4:19 || IS_INVOKED_BY qualified
95 7:14 || IS_INVOKED_BY qualified
127 8:24 || IS_REFERENCED_BY qualified
150 11:4 || IS_INVOKED_BY qualified
162 12:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
''');
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
    final element = findElement.unnamedConstructor('A');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
55 4:19 || IS_INVOKED_BY qualified
99 7:14 || IS_INVOKED_BY qualified
129 8:22 || IS_REFERENCED_BY qualified
152 11:4 || IS_INVOKED_BY qualified
164 12:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
''');
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
    final element = findElement.unnamedConstructor('A');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
58 4:14 || IS_INVOKED_BY qualified
88 5:22 || IS_REFERENCED_BY qualified
111 8:4 || IS_INVOKED_BY qualified
123 9:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
''');
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
void f() {
  new B(); // B1
  new B.named(); // B2
  new C(); // C1
  new C.named(); // C2
}
''');
    final constructor = findElement.unnamedConstructor('A');
    assertElementIndexText(constructor, r'''
118 9:8 || IS_INVOKED_BY qualified
158 11:8 || IS_INVOKED_BY qualified
''');

    final constructor_named = findElement.constructor('named', of: 'A');
    assertElementIndexText(constructor_named, r'''
135 10:8 |.named| IS_INVOKED_BY qualified
175 12:8 |.named| IS_INVOKED_BY qualified
''');
  }

  test_isReferencedBy_ConstructorElement_classTypeAlias_cycle() async {
    await _indexTestUnit('''
class M {}
class A = B with M;
class B = A with M;
void f() {
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
    final element = findElement.constructor('foo');
    assertElementIndexText(element, r'''
10 1:11 |.foo| IS_REFERENCED_BY qualified
30 3:4 |.foo| IS_INVOKED_BY qualified
70 5:17 |.foo| IS_INVOKED_BY qualified
''');
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
    final element = findElement.unnamedConstructor('E');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
27 3:5 || IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
38 4:5 || IS_INVOKED_BY qualified
51 5:5 |.new| IS_INVOKED_BY qualified
89 7:19 || IS_INVOKED_BY qualified
''');
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
    final element = findElement.unnamedConstructor('E');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
27 3:5 || IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
38 4:5 || IS_INVOKED_BY qualified
51 5:5 |.new| IS_INVOKED_BY qualified
95 7:19 || IS_INVOKED_BY qualified
''');
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
    final element = findElement.unnamedConstructor('E');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
27 3:5 || IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
38 4:5 || IS_INVOKED_BY qualified
51 5:5 |.new| IS_INVOKED_BY qualified
''');
  }

  test_isReferencedBy_DynamicElement() async {
    await _indexTestUnit('''
dynamic f() {
}''');
    expect(index.usedElementOffsets, isEmpty);
  }

  test_isReferencedBy_enumConstant() async {
    newFile('$testPackageLibPath/lib.dart', '''
enum E {
  c;
}
''');
    await _indexTestUnit('''
import 'lib.dart';

void f(E e) {
  f(E.c);
}
''');
    final element = findElement.function('f').parameters[0].type.element!;
    assertElementIndexText(element, r'''
27 3:8 |E| IS_REFERENCED_BY
38 4:5 |E| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_enumConstant_withMultiplePrefixes() async {
    newFile('$testPackageLibPath/lib.dart', '''
enum E {
  c;
}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;
import 'lib.dart' as q;

void f(p.E e) {
  f(q.E.c);
}
''');
    final element = findElement.function('f').parameters[0].type.element!;
    assertElementIndexText(element, r'''
58 4:10 |E| IS_REFERENCED_BY qualified
71 5:7 |E| IS_REFERENCED_BY qualified
Prefixes: p,q
''');
  }

  test_isReferencedBy_enumConstant_withPrefix() async {
    newFile('$testPackageLibPath/lib.dart', '''
enum E {
  c;
}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;

void f(p.E e) {
  f(p.E.c);
}
''');
    final element = findElement.function('f').parameters[0].type.element!;
    assertElementIndexText(element, r'''
34 3:10 |E| IS_REFERENCED_BY qualified
47 4:7 |E| IS_REFERENCED_BY qualified
Prefixes: p
''');
  }

  test_isReferencedBy_ExtensionElement() async {
    await _indexTestUnit('''
extension E on int {
  void foo() {}
}

void f() {
  E(0).foo();
}
''');
    final element = findElement.extension_('E');
    assertElementIndexText(element, r'''
53 6:3 |E| IS_REFERENCED_BY
''');
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
void f(A a) {
  a.field = 3; // q
  print(a.field); // q
  new A(field: 4);
}
''');
    final field = findElement.field('field');
    final getter = field.getter!;
    final setter = field.setter!;

    assertElementIndexText(field, r'''
33 3:11 |field| IS_WRITTEN_BY qualified
''');

    assertElementIndexText(getter, r'''
81 6:11 |field| IS_REFERENCED_BY
145 11:11 |field| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(setter, r'''
54 5:5 |field| IS_REFERENCED_BY
119 10:5 |field| IS_REFERENCED_BY qualified
''');
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
      final field = findElement.field('aaa');
      final getter = field.getter!;
      final setter = field.setter!;
      assertElementIndexText(field, r'''
41 4:10 |aaa| IS_WRITTEN_BY qualified
''');
      assertElementIndexText(getter, r'''
77 6:11 |aaa| IS_REFERENCED_BY
''');
      assertElementIndexText(setter, r'''
87 7:5 |aaa| IS_REFERENCED_BY
''');
    }
    // bbb
    {
      final field = findElement.field('bbb');
      final getter = field.getter!;
      final setter = field.setter!;
      assertElementIndexText(field, r'''
51 4:20 |bbb| IS_WRITTEN_BY qualified
''');
      assertElementIndexText(getter, r'''
106 8:11 |bbb| IS_REFERENCED_BY
''');
      assertElementIndexText(setter, r'''
116 9:5 |bbb| IS_REFERENCED_BY
''');
    }
  }

  test_isReferencedBy_FieldElement_class_synthetic_hasGetter() async {
    await _indexTestUnit('''
class A {
  A() : f = 42;
  int get f => 0;
}
''');
    final element = findElement.field('f');
    assertElementIndexText(element, r'''
18 2:9 |f| IS_WRITTEN_BY qualified
''');
  }

  test_isReferencedBy_FieldElement_class_synthetic_hasGetterSetter() async {
    await _indexTestUnit('''
class A {
  A() : f = 42;
  int get f => 0;
  set f(_) {}
}
''');
    final element = findElement.field('f');
    assertElementIndexText(element, r'''
18 2:9 |f| IS_WRITTEN_BY qualified
''');
  }

  test_isReferencedBy_FieldElement_class_synthetic_hasSetter() async {
    await _indexTestUnit('''
class A {
  A() : f = 42;
  set f(_) {}
}
''');
    final element = findElement.field('f');
    assertElementIndexText(element, r'''
18 2:9 |f| IS_WRITTEN_BY qualified
''');
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
    final field = findElement.field('field');
    final getter = field.getter!;
    final setter = field.setter!;

    assertElementIndexText(field, r'''
62 4:11 |field| IS_WRITTEN_BY qualified
''');

    assertElementIndexText(getter, r'''
111 7:5 |field| IS_REFERENCED_BY
168 12:5 |field| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(setter, r'''
90 6:5 |field| IS_REFERENCED_BY
148 11:5 |field| IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_FieldElement_enum_index() async {
    await _indexTestUnit('''
enum MyEnum {
  A, B, C
}
void f() {
  print(MyEnum.values);
  print(MyEnum.A.index);
  print(MyEnum.A);
  print(MyEnum.B);
}
''');

    assertElementIndexText(findElement.getter('values'), r'''
52 5:16 |values| IS_REFERENCED_BY qualified
''');

    var index = typeProvider.enumElement!.getGetter('index')!;
    assertElementIndexText(index, r'''
78 6:18 |index| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(findElement.getter('A'), r'''
76 6:16 |A| IS_REFERENCED_BY qualified
101 7:16 |A| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(findElement.getter('B'), r'''
120 8:16 |B| IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_FieldElement_enum_synthetic_hasGetter() async {
    await _indexTestUnit('''
enum E {
  v;
  E() : f = 42;
  int get f => 0;
}
''');
    final element = findElement.field('f');
    assertElementIndexText(element, r'''
22 3:9 |f| IS_WRITTEN_BY qualified
''');
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
    final element = findElement.field('f');
    assertElementIndexText(element, r'''
22 3:9 |f| IS_WRITTEN_BY qualified
''');
  }

  test_isReferencedBy_FieldElement_enum_synthetic_hasSetter() async {
    await _indexTestUnit('''
enum E {
  v;
  E() : f = 42;
  set f(_) {}
}
''');
    final element = findElement.field('f');
    assertElementIndexText(element, r'''
22 3:9 |f| IS_WRITTEN_BY qualified
''');
  }

  test_isReferencedBy_FunctionElement() async {
    await _indexTestUnit('''
foo() {}
void f() {
  print(foo);
  print(foo());
}
''');
    final element = findElement.topFunction('foo');
    assertElementIndexText(element, r'''
28 3:9 |foo| IS_REFERENCED_BY
42 4:9 |foo| IS_INVOKED_BY
''');
  }

  test_isReferencedBy_FunctionElement_with_LibraryElement() async {
    newFile('$testPackageLibPath/foo.dart', r'''
bar() {}
''');
    await _indexTestUnit('''
import "foo.dart";
void f() {
  bar();
}
''');

    var importFind = findElement.importFind('package:test/foo.dart');
    assertElementIndexText(importFind.importedLibrary, r'''
7 1:8 |"foo.dart"| IS_REFERENCED_BY qualified
''');

    FunctionElement bar = importFind.topFunction('bar');
    assertElementIndexText(bar, r'''
32 3:3 |bar| IS_INVOKED_BY
''');
  }

  test_isReferencedBy_FunctionTypeAliasElement() async {
    await _indexTestUnit('''
typedef A();
void f(A p) {
}
''');
    final element = findElement.typeAlias('A');
    assertElementIndexText(element, r'''
20 2:8 |A| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_getter_withPrefix() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {
  static int get f => 0;
}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;

int f() => p.A.f;

class B extends p.A {}
''');
    final element = findElement.class_('B').supertype!.element;
    assertElementIndexText(element, r'''
38 3:14 |A| IS_REFERENCED_BY qualified
50 5:7 |B| IS_ANCESTOR_OF
62 5:19 |A| IS_EXTENDED_BY qualified
62 5:19 |A| IS_REFERENCED_BY qualified
Prefixes: p
''');
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
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
16 2:6 |A| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_MethodElement_class() async {
    await _indexTestUnit('''
class A {
  method() {}
  void m() {
    print(this.method); // q
    print(method); // nq
  }
}''');
    final element = findElement.method('method');
    assertElementIndexText(element, r'''
52 4:16 |method| IS_REFERENCED_BY qualified
76 5:11 |method| IS_REFERENCED_BY
''');
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
    final element = findElement.method('foo');
    assertElementIndexText(element, r'''
54 5:10 |foo| IS_REFERENCED_BY qualified
69 6:5 |foo| IS_REFERENCED_BY
104 10:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_methodInvocation_withPrefix() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {
  static void m() {}
}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;

void f() => p.A.m();

class B extends p.A {}
''');
    final element = findElement.class_('B').supertype!.element;
    assertElementIndexText(element, r'''
39 3:15 |A| IS_REFERENCED_BY qualified
53 5:7 |B| IS_ANCESTOR_OF
65 5:19 |A| IS_EXTENDED_BY qualified
65 5:19 |A| IS_REFERENCED_BY qualified
Prefixes: p
''');
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
void f() {
  foo(p: 1);
}
''');
    final element = findElement.parameter('p');
    assertElementIndexText(element, r'''
33 3:7 |p| IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_ParameterElement_genericFunctionType() async {
    await _indexTestUnit('''
typedef F = void Function({int? p});

void g(F f) {
  f(p: 0);
}
''');
    // We should not crash because of reference to "p" - a named parameter
    // of a generic function type.
  }

  test_isReferencedBy_ParameterElement_genericFunctionType_call() async {
    await _indexTestUnit('''
typedef F<T> = void Function({T? test});

void g(F<int> f) {
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

void f() {
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
    final element = findElement.unnamedConstructor('A').parameter('a');
    assertElementIndexText(element, r'''
75 5:21 |a| IS_REFERENCED_BY qualified
''');
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
    final element = findElement.unnamedConstructor('A').parameter('a');
    assertElementIndexText(element, r'''
54 5:11 |a| IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_ParameterElement_optionalNamed_ofConstructor_genericClass() async {
    await _indexTestUnit('''
class A<T> {
  A({T? test});
}

void f() {
  A(test: 0);
}
''');
    final element = findElement.parameter('test');
    assertElementIndexText(element, r'''
47 6:5 |test| IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_ParameterElement_optionalNamed_ofMethod_genericClass() async {
    await _indexTestUnit('''
class A<T> {
  void foo({T? test}) {}
}

void f(A<int> a) {
  a.foo(test: 0);
}
''');
    final element = findElement.parameter('test');
    assertElementIndexText(element, r'''
68 6:9 |test| IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_ParameterElement_optionalNamed_ofTopFunction() async {
    await _indexTestUnit('''
void foo({int? test}) {}

void() {
  foo(test: 0);
}
''');
    final element = findElement.parameter('test');
    assertElementIndexText(element, r'''
41 4:7 |test| IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_ParameterElement_optionalNamed_ofTopFunction_anywhere() async {
    await _indexTestUnit('''
void foo(int a, int b, {int? test}) {}

void() {
  foo(1, test: 0, 2);
}
''');
    final element = findElement.parameter('test');
    assertElementIndexText(element, r'''
58 4:10 |test| IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_ParameterElement_optionalPositional() async {
    await _indexTestUnit('''
foo([p]) {
  p; // 1
}
void f() {
  foo(1); // 2
}
''');
    final element = findElement.parameter('p');
    assertElementIndexText(element, r'''
40 5:7 || IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_ParameterElement_requiredNamed_ofTopFunction() async {
    await _indexTestUnit('''
void foo({required int test}) {}

void() {
  foo(test: 0);
}
''');
    final element = findElement.parameter('test');
    assertElementIndexText(element, r'''
49 4:7 |test| IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_PropertyAccessor_ofNamedExtension_instance() async {
    await _indexTestUnit('''
extension E on int {
  int get foo => 0;
  void set foo(int _) {}
}

void f() {
  0.foo;
  0.foo = 0;
}
''');
    final getter = findElement.getter('foo');
    final setter = findElement.setter('foo');

    assertElementIndexText(getter, r'''
84 7:5 |foo| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(setter, r'''
93 8:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_PropertyAccessor_ofNamedExtension_static() async {
    await _indexTestUnit('''
extension E on int {
  static int get foo => 0;
  static void set foo(int _) {}
}

void f() {
  0.foo;
  0.foo = 0;
}
''');
    final getter = findElement.getter('foo');
    final setter = findElement.setter('foo');

    assertElementIndexText(getter, r'''
98 7:5 |foo| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(setter, r'''
107 8:5 |foo| IS_REFERENCED_BY qualified
''');
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

void f() {
  0.foo; // int getter ref
  0.foo = 0; // int setter ref
  (1.2).foo; // double getter ref
  (1.2).foo = 0; // double setter ref
}
''');

    var intGetter = findNode.methodDeclaration('0; // int getter');
    var intSetter = findNode.methodDeclaration('{} // int setter');
    assertElementIndexText(intGetter.declaredElement!, r'''
214 12:5 |foo| IS_REFERENCED_BY qualified
''');
    assertElementIndexText(intSetter.declaredElement!, r'''
241 13:5 |foo| IS_REFERENCED_BY qualified
''');

    var doubleGetter = findNode.methodDeclaration('0; // double getter');
    var doubleSetter = findNode.methodDeclaration('{} // double setter');
    assertElementIndexText(doubleGetter.declaredElement!, r'''
276 14:9 |foo| IS_REFERENCED_BY qualified
''');
    assertElementIndexText(doubleSetter.declaredElement!, r'''
310 15:9 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_setter_withPrefix() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {
  static int f = 0;
}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;

void f(int i) => p.A.f = i;

class B extends p.A {}
''');
    final element = findElement.class_('B').supertype!.element;
    assertElementIndexText(element, r'''
44 3:20 |A| IS_REFERENCED_BY qualified
60 5:7 |B| IS_ANCESTOR_OF
72 5:19 |A| IS_EXTENDED_BY qualified
72 5:19 |A| IS_REFERENCED_BY qualified
Prefixes: p
''');
  }

  test_isReferencedBy_simpleIdentifier_withPrefix() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await _indexTestUnit('''
import 'lib.dart' as p;

var t = p.A;

class B extends p.A {}
''');
    final element = findElement.class_('B').supertype!.element;
    assertElementIndexText(element, r'''
35 3:11 |A| IS_REFERENCED_BY qualified
45 5:7 |B| IS_ANCESTOR_OF
57 5:19 |A| IS_EXTENDED_BY qualified
57 5:19 |A| IS_REFERENCED_BY qualified
Prefixes: p
''');
  }

  test_isReferencedBy_synthetic_leastUpperBound() async {
    await _indexTestUnit('''
int f1({int p}) => 1;
int f2({int p}) => 2;
void g(bool b) {
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
void f() {
  pref.V = 5; // q
  print(pref.V); // q
  V = 5; // nq
  print(V); // nq
}''');
    TopLevelVariableElement variable = importFindLib().topVar('V');

    assertElementIndexText(variable, r'''
23 1:24 |V| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(variable.getter!, r'''
103 5:14 |V| IS_REFERENCED_BY qualified
135 7:9 |V| IS_REFERENCED_BY
Prefixes: pref
''');

    assertElementIndexText(variable.setter!, r'''
78 4:8 |V| IS_REFERENCED_BY qualified
114 6:3 |V| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_TopLevelVariableElement_synthetic_hasGetterSetter() async {
    newFile('$testPackageLibPath/lib.dart', '''
int get V => 0;
void set V(_) {}
''');
    await _indexTestUnit('''
import 'lib.dart' show V;
''');
    final element = importFindLib().topVar('V');
    assertElementIndexText(element, r'''
23 1:24 |V| IS_REFERENCED_BY qualified
''');
  }

  test_isReferencedBy_TopLevelVariableElement_synthetic_hasSetter() async {
    newFile('$testPackageLibPath/lib.dart', '''
void set V(_) {}
''');
    await _indexTestUnit('''
import 'lib.dart' show V;
''');
    final element = importFindLib().topVar('V');
    assertElementIndexText(element, r'''
23 1:24 |V| IS_REFERENCED_BY qualified
''');
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
    final element = findElement.typeAlias('B');
    assertElementIndexText(element, r'''
94 8:8 |B| IS_REFERENCED_BY
103 9:3 |B| IS_REFERENCED_BY
110 10:3 |B| IS_REFERENCED_BY
122 11:3 |B| IS_REFERENCED_BY
137 12:3 |B| IS_REFERENCED_BY
153 13:3 |B| IS_REFERENCED_BY
''');
  }

  test_isReferencedBy_typeInVariableList() async {
    await _indexTestUnit('''
class A {}
A myVariable = null;
''');
    final element = findElement.class_('A');
    assertElementIndexText(element, r'''
11 2:1 |A| IS_REFERENCED_BY
''');
  }

  test_isWrittenBy_FieldElement() async {
    await _indexTestUnit('''
class A {
  int field;
  A.foo({this.field});
  A.bar() : field = 5;
}
''');
    final element = findElement.field('field');
    assertElementIndexText(element, r'''
37 3:15 |field| IS_WRITTEN_BY qualified
58 4:13 |field| IS_WRITTEN_BY qualified
''');
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
void f(p) {
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
void f(C c) {
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
void f(p) {
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
void f() {
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

  String _getRelationsText(Element element) {
    final lineInfo = result.lineInfo;
    final elementId = _findElementId(element);

    final relations = <_Relation>[];
    for (var i = 0; i < index.usedElementOffsets.length; i++) {
      if (index.usedElements[i] == elementId) {
        relations.add(
          _Relation(
            kind: index.usedElementKinds[i],
            offset: index.usedElementOffsets[i],
            length: index.usedElementLengths[i],
            isQualified: index.usedElementIsQualifiedFlags[i],
          ),
        );
      }
    }

    final sortedRelations = relations.sorted((a, b) {
      final byOffset = a.offset - b.offset;
      if (byOffset != 0) {
        return byOffset;
      }
      return a.kind.name.compareTo(b.kind.name);
    });

    // Verify that there are no duplicate relations.
    var lastOffset = -1;
    var lastLength = -1;
    IndexRelationKind? lastKind;
    for (final relation in sortedRelations) {
      if (relation.offset == lastOffset &&
          relation.length == lastLength &&
          relation.kind == lastKind) {
        fail('Duplicate relation: $relation');
      }
      lastOffset = relation.offset;
      lastLength = relation.length;
      lastKind = relation.kind;
    }

    final buffer = StringBuffer();
    for (final relation in sortedRelations) {
      final offset = relation.offset;
      final length = relation.length;
      final location = lineInfo.getLocation(offset);
      final snippet = result.content.substring(offset, offset + length);
      buffer.write(offset);
      buffer.write(' ');
      buffer.write(location.lineNumber);
      buffer.write(':');
      buffer.write(location.columnNumber);
      buffer.write(' ');
      buffer.write('|$snippet|');
      buffer.write(' ');
      buffer.write(relation.kind.name);
      if (relation.isQualified) {
        buffer.write(' qualified');
      }
      buffer.writeln();
    }

    final prefixes = index.elementImportPrefixes[elementId];
    if (prefixes.isNotEmpty) {
      buffer.writeln('Prefixes: $prefixes');
    }

    return buffer.toString();
  }
}

mixin _IndexMixin on PubPackageResolutionTest {
  late AnalysisDriverUnitIndex index;

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
    var buffer = StringBuffer();
    for (int i = 0; i < index.usedElementOffsets.length; i++) {
      buffer.write('  id = ');
      buffer.write(index.usedElements[i]);
      buffer.write(' kind = ');
      buffer.write(index.usedElementKinds[i]);
      buffer.write(' offset = ');
      buffer.write(index.usedElementOffsets[i]);
      buffer.write(' length = ');
      buffer.write(index.usedElementLengths[i]);
      buffer.write(' isQualified = ');
      buffer.writeln(index.usedElementIsQualifiedFlags[i]);
    }
    fail('$msg in\n${buffer.toString()}');
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

  _Relation({
    required this.kind,
    required this.offset,
    required this.length,
    required this.isQualified,
  });

  @override
  String toString() {
    return '_Relation{kind: $kind, offset: $offset, length: $length, '
        'isQualified: $isQualified})';
  }
}
