// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/dependency/library_builder.dart'
    hide buildLibrary;
import 'package:analyzer/src/dart/analysis/dependency/node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeclaredNodesTest);
  });
}

@reflectiveTest
class DeclaredNodesTest extends BaseDependencyTest {
  test_api_tokens_include_enclosingClass() async {
    var library = await buildTestLibrary(a, r'''
class A {
  void foo() {}
}

class B {
  void foo() {}
}
''');
    _assertDifferentApiTokenSignature(
      getNode(library, name: 'foo', memberOf: 'A'),
      getNode(library, name: 'foo', memberOf: 'B'),
    );
  }

  test_api_tokens_include_enclosingEnum() async {
    var library = await buildTestLibrary(a, r'''
enum A {
  foo
}

enum B {
  foo
}
''');
    _assertDifferentApiTokenSignature(
      getNode(library, name: 'foo', memberOf: 'A'),
      getNode(library, name: 'foo', memberOf: 'B'),
    );
    _assertDifferentApiTokenSignature(
      getNode(library, name: 'index', memberOf: 'A'),
      getNode(library, name: 'index', memberOf: 'B'),
    );
    _assertDifferentApiTokenSignature(
      getNode(library, name: 'values', memberOf: 'A'),
      getNode(library, name: 'values', memberOf: 'B'),
    );
  }

  test_api_tokens_include_enclosingLibrary_class() async {
    var aLib = await buildTestLibrary(a, 'class C {}');
    var bLib = await buildTestLibrary(b, 'class C {}');
    _assertDifferentApiTokenSignature(
      getNode(aLib, name: 'C'),
      getNode(bLib, name: 'C'),
    );
  }

  test_api_tokens_include_enclosingLibrary_enum() async {
    var aLib = await buildTestLibrary(a, 'enum Foo {a, b, c}');
    var bLib = await buildTestLibrary(b, 'enum Foo {a, b, c}');
    _assertDifferentApiTokenSignature(
      getNode(aLib, name: 'Foo'),
      getNode(bLib, name: 'Foo'),
    );
  }

  test_api_tokens_include_enclosingLibrary_function() async {
    var aLib = await buildTestLibrary(a, 'void foo() {}');
    var bLib = await buildTestLibrary(b, 'void foo() {}');
    _assertDifferentApiTokenSignature(
      getNode(aLib, name: 'foo'),
      getNode(bLib, name: 'foo'),
    );
  }

  test_api_tokens_include_functionOrMethod() async {
    var library = await buildTestLibrary(a, r'''
void foo() {}

class C {
  void foo() {}
}
''');
    var fooFunction = getNode(library, name: 'foo');
    var fooMethod = getNode(library, name: 'foo', memberOf: 'C');
    expect(
      fooFunction.api.tokenSignatureHex,
      isNot(fooMethod.api.tokenSignatureHex),
    );
  }

  test_class_constructor() async {
    var library = await buildTestLibrary(a, r'''
class C {
  C();
  C.named();
}
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(
        aUri,
        'C',
        NodeKind.CLASS,
        classMembers: [
          ExpectedNode(aUri, '', NodeKind.CONSTRUCTOR),
          ExpectedNode(aUri, 'named', NodeKind.CONSTRUCTOR),
        ],
      ),
    ]);
  }

  test_class_constructor_api_tokens_notSame_annotation() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.CONSTRUCTOR,
      'class X {  X.foo();  }',
      'class X {  @deprecated X.foo();  }',
      memberOf: 'X',
    );
  }

  test_class_constructor_api_tokens_notSame_parameter_add() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.CONSTRUCTOR,
      'class X {  X.foo();  }',
      'class X {  X.foo(int a);  }',
      memberOf: 'X',
    );
  }

  test_class_constructor_api_tokens_notSame_parameter_name_edit_named() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.CONSTRUCTOR,
      'class X {  X.foo({int a});  }',
      'class X {  X.foo({int b});  }',
      memberOf: 'X',
    );
  }

  test_class_constructor_api_tokens_notSame_parameter_type() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.CONSTRUCTOR,
      'class X {  X.foo(int a);  }',
      'class X {  X.foo(double a);  }',
      memberOf: 'X',
    );
  }

  test_class_constructor_api_tokens_same_body() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.CONSTRUCTOR,
      'class X {  X.foo() { print(1); }  }',
      'class X {  X.foo() { print(2); }  }',
      memberOf: 'X',
    );
  }

  test_class_constructor_api_tokens_same_body_add() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.CONSTRUCTOR,
      'class X {  X.foo();  }',
      'class X {  X.foo() {}  }',
      memberOf: 'X',
    );
  }

  test_class_constructor_api_tokens_same_parameter_name_edit_required() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.CONSTRUCTOR,
      'class X {  X.foo(int a);  }',
      'class X {  X.foo(int b);  }',
      memberOf: 'X',
    );
  }

  test_class_constructor_default() async {
    var library = await buildTestLibrary(a, r'''
class C {}
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(
        aUri,
        'C',
        NodeKind.CLASS,
        classMembers: [
          ExpectedNode(aUri, '', NodeKind.CONSTRUCTOR),
        ],
      ),
    ]);
  }

  test_class_field() async {
    var library = await buildTestLibrary(a, r'''
class C {
  int a = 1;
  int b = 2, c = 3;
}
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(
        aUri,
        'C',
        NodeKind.CLASS,
        classMembers: [
          ExpectedNode(aUri, '', NodeKind.CONSTRUCTOR),
          ExpectedNode(aUri, 'a', NodeKind.GETTER),
          ExpectedNode(aUri, 'b', NodeKind.GETTER),
          ExpectedNode(aUri, 'c', NodeKind.GETTER),
          ExpectedNode(aUri, 'a=', NodeKind.SETTER),
          ExpectedNode(aUri, 'b=', NodeKind.SETTER),
          ExpectedNode(aUri, 'c=', NodeKind.SETTER),
        ],
      ),
    ]);
  }

  test_class_field_api_tokens_notSame_annotation() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'class X {  int foo = 0;  }',
      'class X {  @deprecated int foo = 0;  }',
      memberOf: 'X',
    );
  }

  test_class_field_api_tokens_notSame_const() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'class X {  int foo = 0;  }',
      'class X {  const int foo = 0;  }',
      memberOf: 'X',
    );
  }

  test_class_field_api_tokens_same_final() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.GETTER,
      'class X {  int foo = 0;  }',
      'class X {  final int foo = 0;  }',
      memberOf: 'X',
    );
  }

  test_class_field_api_tokens_typed_notSame_type() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'class X {  int foo = 0;  }',
      'class X {  num foo = 1;  }',
      memberOf: 'X',
    );
  }

  test_class_field_api_tokens_typed_same_initializer() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.GETTER,
      'class X {  int foo = 0;  }',
      'class X {  int foo = 1;  }',
      memberOf: 'X',
    );
  }

  test_class_field_api_tokens_untyped_notSame_initializer() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'class X {  var foo = 0;  }',
      'class X {  var foo = 1.0;  }',
      memberOf: 'X',
    );
  }

  test_class_field_const() async {
    var library = await buildTestLibrary(a, r'''
class X {
  const foo = 1;
  const bar = 2;
}
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(
        aUri,
        'X',
        NodeKind.CLASS,
        classMembers: [
          ExpectedNode(aUri, '', NodeKind.CONSTRUCTOR),
          ExpectedNode(aUri, 'foo', NodeKind.GETTER),
          ExpectedNode(aUri, 'bar', NodeKind.GETTER),
        ],
      ),
    ]);
  }

  test_class_field_const_api_tokens_typed_notSame_initializer() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'class X {  const int foo = 0;  }',
      'class X {  const int foo = 1;  }',
      memberOf: 'X',
    );
  }

  test_class_field_final() async {
    var library = await buildTestLibrary(a, r'''
class X {
  final foo = 1;
  final bar = 2;
}
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(
        aUri,
        'X',
        NodeKind.CLASS,
        classMembers: [
          ExpectedNode(aUri, '', NodeKind.CONSTRUCTOR),
          ExpectedNode(aUri, 'foo', NodeKind.GETTER),
          ExpectedNode(aUri, 'bar', NodeKind.GETTER),
        ],
      ),
    ]);
  }

  test_class_field_final_api_tokens_typed_notSame_initializer_constClass() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'class X {  final int foo = 0;  const X();  }',
      'class X {  final int foo = 1;  const X();  }',
      memberOf: 'X',
    );
  }

  test_class_field_final_api_tokens_typed_same_initializer() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.GETTER,
      'class X {  final int foo = 0;  }',
      'class X {  final int foo = 1;  }',
      memberOf: 'X',
    );
  }

  test_class_field_final_api_tokens_untyped_notSame_initializer() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'class X {  final foo = 0;  }',
      'class X {  final foo = 1.0;  }',
      memberOf: 'X',
    );
  }

  test_class_getter() async {
    var library = await buildTestLibrary(a, r'''
class C {
  int get foo => 0;
  int get bar => 0;
}
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(
        aUri,
        'C',
        NodeKind.CLASS,
        classMembers: [
          ExpectedNode(aUri, '', NodeKind.CONSTRUCTOR),
          ExpectedNode(aUri, 'foo', NodeKind.GETTER),
          ExpectedNode(aUri, 'bar', NodeKind.GETTER),
        ],
      ),
    ]);
  }

  test_class_getter_api_tokens_notSame_returnType() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'class X {  int get foo => null;  }',
      'class X {  double get foo => null;  }',
      memberOf: 'X',
    );
  }

  test_class_method() async {
    var library = await buildTestLibrary(a, r'''
class C {
  void foo() {}
  void bar() {}
}
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(
        aUri,
        'C',
        NodeKind.CLASS,
        classMembers: [
          ExpectedNode(aUri, '', NodeKind.CONSTRUCTOR),
          ExpectedNode(aUri, 'foo', NodeKind.METHOD),
          ExpectedNode(aUri, 'bar', NodeKind.METHOD),
        ],
      ),
    ]);
  }

  test_class_method_api_tokens_notSame_annotation() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.METHOD,
      'class X {  void foo() {}  }',
      'class X {  @deprecated void foo() {}  }',
      memberOf: 'X',
    );
  }

  test_class_method_api_tokens_notSame_parameter_add() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.METHOD,
      'class X {  void foo() {}  }',
      'class X {  void foo(int a) {}  }',
      memberOf: 'X',
    );
  }

  test_class_method_api_tokens_notSame_parameter_name_edit_named() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.METHOD,
      'class X {  void foo({int a}) {}  }',
      'class X {  void foo({int b}) {}  }',
      memberOf: 'X',
    );
  }

  test_class_method_api_tokens_notSame_parameter_type() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.METHOD,
      'class X {  void foo(int a) {}  }',
      'class X {  void foo(double a) {}  }',
      memberOf: 'X',
    );
  }

  test_class_method_api_tokens_notSame_returnType() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.METHOD,
      'class X {  int foo() {}  }',
      'class X {  double foo() {}  }',
      memberOf: 'X',
    );
  }

  test_class_method_api_tokens_notSame_typeParameter_add() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.METHOD,
      'class X {  void foo() {}  }',
      'class X {  void foo<T>() {}  }',
      memberOf: 'X',
    );
  }

  test_class_method_api_tokens_notSame_typeParameter_bound_add() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.METHOD,
      'class X {  void foo<T>() {}  }',
      'class X {  void foo<T extends num>() {}  }',
      memberOf: 'X',
    );
  }

  test_class_method_api_tokens_same_async_add() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.METHOD,
      'class X {  foo() {}  }',
      'class X {  foo() async {}  }',
      memberOf: 'X',
    );
  }

  test_class_method_api_tokens_same_body() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.METHOD,
      'class X {  void foo() { print(1); }  }',
      'class X {  void foo() { print(2); }  }',
      memberOf: 'X',
    );
  }

  test_class_method_api_tokens_same_parameter_name_edit_required() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.METHOD,
      'class X {  void foo(int a) {}  }',
      'class X {  void foo(int b) {}  }',
      memberOf: 'X',
    );
  }

  test_class_setter() async {
    var library = await buildTestLibrary(a, r'''
class C {
  set foo(_) {}
  set bar(_) {}
}
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(
        aUri,
        'C',
        NodeKind.CLASS,
        classMembers: [
          ExpectedNode(aUri, '', NodeKind.CONSTRUCTOR),
          ExpectedNode(aUri, 'foo', NodeKind.SETTER),
          ExpectedNode(aUri, 'bar', NodeKind.SETTER),
        ],
      ),
    ]);
  }

  test_class_setter_api_tokens_notSame_returnType() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.SETTER,
      'class X {  set foo(int a) {}  }',
      'class X {  set foo(double a) {}  }',
      memberOf: 'X',
    );
  }

  test_class_setter_api_tokens_same_parameter_name() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.SETTER,
      'class X {  set foo(int a) {}  }',
      'class X {  set foo(int b) {}  }',
      memberOf: 'X',
    );
  }

  test_class_typeParameter() async {
    var library = await buildTestLibrary(a, r'''
class A<T> {}
class B<T, U> {}
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(
        aUri,
        'A',
        NodeKind.CLASS,
        classMembers: [
          ExpectedNode(aUri, '', NodeKind.CONSTRUCTOR),
        ],
        classTypeParameters: [
          ExpectedNode(aUri, 'T', NodeKind.TYPE_PARAMETER),
        ],
      ),
      ExpectedNode(
        aUri,
        'B',
        NodeKind.CLASS,
        classMembers: [
          ExpectedNode(aUri, '', NodeKind.CONSTRUCTOR),
        ],
        classTypeParameters: [
          ExpectedNode(aUri, 'T', NodeKind.TYPE_PARAMETER),
          ExpectedNode(aUri, 'U', NodeKind.TYPE_PARAMETER),
        ],
      ),
    ]);
  }

  test_class_typeParameter_api_tokens_notSame_annotation() async {
    await _assertApiTokenSignatureNotSame(
      'T',
      NodeKind.TYPE_PARAMETER,
      'class X<T> {}',
      'class X<@deprecate T> {}',
      typeParameterOf: 'X',
    );
  }

  test_class_typeParameter_api_tokens_notSame_bound_add() async {
    await _assertApiTokenSignatureNotSame(
      'T',
      NodeKind.TYPE_PARAMETER,
      'class X<T> {}',
      'class X<T extends num> {}',
      typeParameterOf: 'X',
    );
  }

  test_class_typeParameter_api_tokens_notSame_bound_edit() async {
    await _assertApiTokenSignatureNotSame(
      'T',
      NodeKind.TYPE_PARAMETER,
      'class X<T extends num> {}',
      'class X<T extends int> {}',
      typeParameterOf: 'X',
    );
  }

  test_library_export() async {
    var library = await buildTestLibrary(a, r'''
export 'dart:math';
export 'package:aaa/aaa.dart';
export 'package:bbb/bbb.dart' show b1, b2 hide b3;
''');
    _assertExports(library, [
      Export(Uri.parse('dart:math'), []),
      Export(Uri.parse('package:aaa/aaa.dart'), []),
      Export(Uri.parse('package:bbb/bbb.dart'), [
        Combinator(true, ['b1', 'b2']),
        Combinator(false, ['b3']),
      ]),
    ]);
  }

  test_library_import() async {
    var library = await buildTestLibrary(a, r'''
import 'dart:math';
import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart' as b;
import 'package:ccc/ccc.dart' show c1, c2 hide c3;
''');
    _assertImports(library, [
      Import(Uri.parse('dart:math'), null, []),
      Import(Uri.parse('package:aaa/aaa.dart'), null, []),
      Import(Uri.parse('package:bbb/bbb.dart'), 'b', []),
      Import(Uri.parse('package:ccc/ccc.dart'), null, [
        Combinator(true, ['c1', 'c2']),
        Combinator(false, ['c3']),
      ]),
      Import(Uri.parse('dart:core'), null, []),
    ]);
  }

  test_library_import_core_explicit() async {
    var library = await buildTestLibrary(a, r'''
import 'dart:core' hide List;
''');
    _assertImports(library, [
      Import(Uri.parse('dart:core'), null, [
        Combinator(false, ['List']),
      ]),
    ]);
  }

  test_library_import_core_implicit() async {
    var library = await buildTestLibrary(a, '');
    _assertImports(library, [
      Import(Uri.parse('dart:core'), null, []),
    ]);
  }

  test_unit_class() async {
    var library = await buildTestLibrary(a, r'''
class Foo {}
class Bar {}
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(aUri, 'Foo', NodeKind.CLASS, classMembers: [
        ExpectedNode(aUri, '', NodeKind.CONSTRUCTOR),
      ]),
      ExpectedNode(aUri, 'Bar', NodeKind.CLASS, classMembers: [
        ExpectedNode(aUri, '', NodeKind.CONSTRUCTOR),
      ]),
    ]);
  }

  test_unit_class_api_tokens_notSame_annotation() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X {}',
      '@deprecated class X {}',
    );
  }

  test_unit_class_api_tokens_notSame_extends_add() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X {}',
      'class X extends A {}',
    );
  }

  test_unit_class_api_tokens_notSame_extends_edit() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X extends A {}',
      'class X extends B {}',
    );
  }

  test_unit_class_api_tokens_notSame_extends_replace() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X extends A {}',
      'class X implements A {}',
    );
  }

  test_unit_class_api_tokens_notSame_extends_typeArgument() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X extends A {}',
      'class X extends A<int> {}',
    );
  }

  test_unit_class_api_tokens_notSame_implements_add() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X {}',
      'class X implements A {}',
    );
  }

  test_unit_class_api_tokens_notSame_implements_edit() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X implements A {}',
      'class X implements B {}',
    );
  }

  test_unit_class_api_tokens_notSame_implements_remove() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X implements A {}',
      'class X {}',
    );
  }

  test_unit_class_api_tokens_notSame_implements_remove2() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X implements A, B {}',
      'class X implements B {}',
    );
  }

  test_unit_class_api_tokens_notSame_implements_typeArgument() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X implements A {}',
      'class X implements A<int> {}',
    );
  }

  test_unit_class_api_tokens_notSame_typeParameter_add() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X {}',
      'class X<T> {}',
    );
  }

  test_unit_class_api_tokens_notSame_typeParameter_add2() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X<T> {}',
      'class X<T, U> {}',
    );
  }

  test_unit_class_api_tokens_notSame_typeParameter_bound_add() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X<T> {}',
      'class X<T extends num> {}',
    );
  }

  test_unit_class_api_tokens_notSame_with_add() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X extends A {}',
      'class X extends A with B {}',
    );
  }

  test_unit_class_api_tokens_notSame_with_edit() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X extends A with B {}',
      'class X extends A with C {}',
    );
  }

  test_unit_class_api_tokens_notSame_with_typeArgument() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS,
      'class X extends A with B {}',
      'class X extends A with B<int> {}',
    );
  }

  test_unit_class_api_tokens_same_body() async {
    await _assertApiTokenSignatureSame(
      'X',
      NodeKind.CLASS,
      'class X {  }',
      'class X { void foo() {} }',
    );
  }

  test_unit_classTypeAlias() async {
    var library = await buildTestLibrary(a, r'''
class X = Object with M;
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(aUri, 'X', NodeKind.CLASS_TYPE_ALIAS),
    ]);
  }

  test_unit_classTypeAlias_api_tokens_notSame_implements_add() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS_TYPE_ALIAS,
      'class X = A with M;',
      'class X = A with M implements I;',
    );
  }

  test_unit_classTypeAlias_api_tokens_notSame_implements_edit() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS_TYPE_ALIAS,
      'class X = A with M implements I;',
      'class X = A with M implements J;',
    );
  }

  test_unit_classTypeAlias_api_tokens_notSame_implements_remove() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS_TYPE_ALIAS,
      'class X = A with M implements I;',
      'class X = A with M;',
    );
  }

  test_unit_classTypeAlias_api_tokens_notSame_implements_typeArgument() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS_TYPE_ALIAS,
      'class X = A with M implements I;',
      'class X = A with M implements I<int>;',
    );
  }

  test_unit_classTypeAlias_api_tokens_notSame_super() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS_TYPE_ALIAS,
      'class X = A with M;',
      'class X = B with M;',
    );
  }

  test_unit_classTypeAlias_api_tokens_notSame_super_typeArgument() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS_TYPE_ALIAS,
      'class X = A with M;',
      'class X = A<int> with M;',
    );
  }

  test_unit_classTypeAlias_api_tokens_notSame_typeParameter_add() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS_TYPE_ALIAS,
      'class X = A with M;',
      'class X<T> = A with M;',
    );
  }

  test_unit_classTypeAlias_api_tokens_notSame_typeParameter_add2() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS_TYPE_ALIAS,
      'class X<T> = A with M;',
      'class X<T, U> = A with M;',
    );
  }

  test_unit_classTypeAlias_api_tokens_notSame_typeParameter_bound_add() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS_TYPE_ALIAS,
      'class X<T> = A with M;',
      'class X<T extends num> = A with M;',
    );
  }

  test_unit_classTypeAlias_api_tokens_notSame_with_add() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS_TYPE_ALIAS,
      'class X = A with M;',
      'class X = A with M, N;',
    );
  }

  test_unit_classTypeAlias_api_tokens_notSame_with_edit() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS_TYPE_ALIAS,
      'class X = A with M;',
      'class X = A with N;',
    );
  }

  test_unit_classTypeAlias_api_tokens_notSame_with_typeArgument() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.CLASS_TYPE_ALIAS,
      'class X = A with M;',
      'class X = A with M<int>;',
    );
  }

  test_unit_enumDeclaration() async {
    var library = await buildTestLibrary(a, r'''
enum Foo {a, b, c}
enum Bar {d, e, f}
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(
        aUri,
        'Foo',
        NodeKind.ENUM,
        classMembers: [
          ExpectedNode(aUri, 'a', NodeKind.GETTER),
          ExpectedNode(aUri, 'b', NodeKind.GETTER),
          ExpectedNode(aUri, 'c', NodeKind.GETTER),
          ExpectedNode(aUri, 'index', NodeKind.GETTER),
          ExpectedNode(aUri, 'values', NodeKind.GETTER),
        ],
      ),
      ExpectedNode(
        aUri,
        'Bar',
        NodeKind.ENUM,
        classMembers: [
          ExpectedNode(aUri, 'd', NodeKind.GETTER),
          ExpectedNode(aUri, 'e', NodeKind.GETTER),
          ExpectedNode(aUri, 'f', NodeKind.GETTER),
          ExpectedNode(aUri, 'index', NodeKind.GETTER),
          ExpectedNode(aUri, 'values', NodeKind.GETTER),
        ],
      ),
    ]);
  }

  test_unit_function() async {
    var library = await buildTestLibrary(a, r'''
void foo() {}
void bar() {}
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(aUri, 'foo', NodeKind.FUNCTION),
      ExpectedNode(aUri, 'bar', NodeKind.FUNCTION),
    ]);
  }

  test_unit_function_api_tokens_notSame_annotation() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.FUNCTION,
      'void foo() {}',
      '@deprecated void foo() {}',
    );
  }

  test_unit_function_api_tokens_notSame_parameter_add() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.FUNCTION,
      'void foo() {}',
      'void foo(int a) {}',
    );
  }

  test_unit_function_api_tokens_notSame_parameter_name_edit_named() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.FUNCTION,
      'void foo({int a}) {}',
      'void foo({int b}) {}',
    );
  }

  test_unit_function_api_tokens_notSame_parameter_type() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.FUNCTION,
      'void foo(int a) {}',
      'void foo(double a) {}',
    );
  }

  test_unit_function_api_tokens_notSame_returnType() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.FUNCTION,
      'int foo() {}',
      'num foo() {}',
    );
  }

  test_unit_function_api_tokens_notSame_typeParameter_add() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.FUNCTION,
      'void foo() {}',
      'void foo<T>() {}',
    );
  }

  test_unit_function_api_tokens_notSame_typeParameter_bound_add() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.FUNCTION,
      'void foo<T>() {}',
      'void foo<T extends num>() {}',
    );
  }

  test_unit_function_api_tokens_same_async_add() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.FUNCTION,
      'foo() {}',
      'foo() async {}',
    );
  }

  test_unit_function_api_tokens_same_body() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.FUNCTION,
      'void foo() { print(1); }',
      'void foo() { print(2); }',
    );
  }

  test_unit_function_api_tokens_same_parameter_name_edit_required() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.FUNCTION,
      'void foo(int a) {}',
      'void foo(int b) {}',
    );
  }

  test_unit_function_api_tokens_same_syncStar_add() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.FUNCTION,
      'foo() {}',
      'foo() sync* {}',
    );
  }

  test_unit_functionTypeAlias() async {
    var library = await buildTestLibrary(a, r'''
typedef void Foo();
typedef void Bar();
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(aUri, 'Foo', NodeKind.FUNCTION_TYPE_ALIAS),
      ExpectedNode(aUri, 'Bar', NodeKind.FUNCTION_TYPE_ALIAS),
    ]);
  }

  test_unit_functionTypeAlias_api_tokens_notSame_annotation() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.FUNCTION_TYPE_ALIAS,
      'typedef void Foo();',
      '@deprecated typedef void Foo();',
    );
  }

  test_unit_functionTypeAlias_api_tokens_notSame_parameter_add() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.FUNCTION_TYPE_ALIAS,
      'typedef void Foo();',
      'typedef void Foo(int a);',
    );
  }

  test_unit_functionTypeAlias_api_tokens_notSame_parameter_name_edit_named() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.FUNCTION_TYPE_ALIAS,
      'typedef void Foo({int a});',
      'typedef void Foo({int b});',
    );
  }

  test_unit_functionTypeAlias_api_tokens_notSame_parameter_type() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.FUNCTION_TYPE_ALIAS,
      'typedef void Foo(int a);',
      'typedef void Foo(double a);',
    );
  }

  test_unit_functionTypeAlias_api_tokens_notSame_returnType() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.FUNCTION_TYPE_ALIAS,
      'typedef int Foo();',
      'typedef num Foo();',
    );
  }

  test_unit_functionTypeAlias_api_tokens_notSame_typeParameter_add() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.FUNCTION_TYPE_ALIAS,
      'typedef void Foo();',
      'typedef void Foo<T>();',
    );
  }

  test_unit_functionTypeAlias_api_tokens_notSame_typeParameter_bound_add() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.FUNCTION_TYPE_ALIAS,
      'typedef void Foo<T>();',
      'typedef void Foo<T extends num>();',
    );
  }

  test_unit_functionTypeAlias_api_tokens_same_comment() async {
    await _assertApiTokenSignatureSame(
      'Foo',
      NodeKind.FUNCTION_TYPE_ALIAS,
      'typedef int Foo();',
      '/* text */ typedef int Foo();',
    );
  }

  test_unit_functionTypeAlias_api_tokens_same_parameter_name_edit_required() async {
    await _assertApiTokenSignatureSame(
      'Foo',
      NodeKind.FUNCTION_TYPE_ALIAS,
      'typedef void Foo(int a);',
      'typedef void Foo(int b);',
    );
  }

  test_unit_genericTypeAlias() async {
    var library = await buildTestLibrary(a, r'''
typedef Foo = void Function();
typedef Bar = void Function();
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(aUri, 'Foo', NodeKind.GENERIC_TYPE_ALIAS),
      ExpectedNode(aUri, 'Bar', NodeKind.GENERIC_TYPE_ALIAS),
    ]);
  }

  test_unit_genericTypeAlias_api_tokens_notSame_annotation() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.GENERIC_TYPE_ALIAS,
      'typedef Foo = void Function();',
      '@deprecated typedef Foo = void Function();',
    );
  }

  test_unit_genericTypeAlias_api_tokens_notSame_parameter_add() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.GENERIC_TYPE_ALIAS,
      'typedef Foo = void Function();',
      'typedef Foo = void Function(int);',
    );
  }

  test_unit_genericTypeAlias_api_tokens_notSame_parameter_kind() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.GENERIC_TYPE_ALIAS,
      'typedef Foo = void Function(int a);',
      'typedef Foo = void Function([int a]);',
    );
  }

  test_unit_genericTypeAlias_api_tokens_notSame_parameter_name_add_positional() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.GENERIC_TYPE_ALIAS,
      'typedef Foo = void Function([int]);',
      'typedef Foo = void Function([int a]);',
    );
  }

  test_unit_genericTypeAlias_api_tokens_notSame_parameter_name_edit_named() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.GENERIC_TYPE_ALIAS,
      'typedef Foo = void Function({int a});',
      'typedef Foo = void Function({int b});',
    );
  }

  test_unit_genericTypeAlias_api_tokens_notSame_parameter_name_edit_positional() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.GENERIC_TYPE_ALIAS,
      'typedef Foo = void Function([int]);',
      'typedef Foo = void Function([int a]);',
    );
  }

  test_unit_genericTypeAlias_api_tokens_notSame_returnType() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.GENERIC_TYPE_ALIAS,
      'typedef Foo = int Function();',
      'typedef Foo = double Function();',
    );
  }

  test_unit_genericTypeAlias_api_tokens_notSame_typeParameter2_add() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.GENERIC_TYPE_ALIAS,
      'typedef Foo = void Function();',
      'typedef Foo = void Function<T>();',
    );
  }

  test_unit_genericTypeAlias_api_tokens_notSame_typeParameter2_bound_add() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.GENERIC_TYPE_ALIAS,
      'typedef Foo = void Function<T>();',
      'typedef Foo = void Function<T extends num>();',
    );
  }

  test_unit_genericTypeAlias_api_tokens_notSame_typeParameter_add() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.GENERIC_TYPE_ALIAS,
      'typedef Foo = void Function();',
      'typedef Foo<T> = void Function();',
    );
  }

  test_unit_genericTypeAlias_api_tokens_notSame_typeParameter_bound_add() async {
    await _assertApiTokenSignatureNotSame(
      'Foo',
      NodeKind.GENERIC_TYPE_ALIAS,
      'typedef Foo<T> = void Function();',
      'typedef Foo<T extends num> = void Function();',
    );
  }

  test_unit_genericTypeAlias_api_tokens_same_parameter_name_add_required() async {
    await _assertApiTokenSignatureSame(
      'Foo',
      NodeKind.GENERIC_TYPE_ALIAS,
      'typedef Foo = void Function(int);',
      'typedef Foo = void Function(int a);',
    );
  }

  test_unit_genericTypeAlias_api_tokens_same_parameter_name_edit_required() async {
    await _assertApiTokenSignatureSame(
      'Foo',
      NodeKind.GENERIC_TYPE_ALIAS,
      'typedef Foo = void Function(int a);',
      'typedef Foo = void Function(int b);',
    );
  }

  test_unit_getter() async {
    var library = await buildTestLibrary(a, r'''
int get foo => 0;
int get bar => 0;
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(aUri, 'foo', NodeKind.GETTER),
      ExpectedNode(aUri, 'bar', NodeKind.GETTER),
    ]);
  }

  test_unit_getter_api_tokens_notSame_annotation() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'int get foo => 0;',
      '@deprecated int get foo => 0;',
    );
  }

  test_unit_getter_api_tokens_notSame_returnType() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'int get foo => 0;',
      'num get foo => 0;',
    );
  }

  test_unit_getter_api_tokens_same_body() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.GETTER,
      'int get foo => 0;',
      'int get foo => 1;',
    );
  }

  test_unit_mixin() async {
    var library = await buildTestLibrary(a, r'''
mixin Foo {}
mixin Bar {}
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(aUri, 'Foo', NodeKind.MIXIN, classMembers: const []),
      ExpectedNode(aUri, 'Bar', NodeKind.MIXIN, classMembers: const []),
    ]);
  }

  test_unit_mixin_api_tokens_notSame_annotation() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.MIXIN,
      'mixin X {}',
      '@deprecated mixin X {}',
    );
  }

  test_unit_mixin_api_tokens_notSame_implements_add() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.MIXIN,
      'mixin X {}',
      'mixin X implements A {}',
    );
  }

  test_unit_mixin_api_tokens_notSame_implements_edit() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.MIXIN,
      'mixin X implements A {}',
      'mixin X implements B {}',
    );
  }

  test_unit_mixin_api_tokens_notSame_implements_remove() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.MIXIN,
      'mixin X implements A {}',
      'mixin X {}',
    );
  }

  test_unit_mixin_api_tokens_notSame_implements_remove2() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.MIXIN,
      'mixin X implements A, B {}',
      'mixin X implements B {}',
    );
  }

  test_unit_mixin_api_tokens_notSame_implements_typeArgument() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.MIXIN,
      'mixin X implements A {}',
      'mixin X implements A<int> {}',
    );
  }

  test_unit_mixin_api_tokens_notSame_on_add() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.MIXIN,
      'mixin X {}',
      'mixin X on A {}',
    );
  }

  test_unit_mixin_api_tokens_notSame_on_add2() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.MIXIN,
      'mixin X on A {}',
      'mixin X on A, B {}',
    );
  }

  test_unit_mixin_api_tokens_notSame_on_edit() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.MIXIN,
      'mixin X on A {}',
      'mixin X on B {}',
    );
  }

  test_unit_mixin_api_tokens_notSame_on_replace() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.MIXIN,
      'mixin X on A {}',
      'mixin X implements A {}',
    );
  }

  test_unit_mixin_api_tokens_notSame_on_typeArgument() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.MIXIN,
      'mixin X on A {}',
      'mixin X on A<int> {}',
    );
  }

  test_unit_mixin_api_tokens_notSame_typeParameter_add() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.MIXIN,
      'mixin X {}',
      'mixin X<T> {}',
    );
  }

  test_unit_mixin_api_tokens_notSame_typeParameter_add2() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.MIXIN,
      'mixin X<T> {}',
      'mixin X<T, U> {}',
    );
  }

  test_unit_mixin_api_tokens_notSame_typeParameter_bound_add() async {
    await _assertApiTokenSignatureNotSame(
      'X',
      NodeKind.MIXIN,
      'mixin X<T> {}',
      'mixin X<T extends num> {}',
    );
  }

  test_unit_mixin_api_tokens_same_body() async {
    await _assertApiTokenSignatureSame(
      'X',
      NodeKind.MIXIN,
      'mixin X {  }',
      'mixin X { void foo() {} }',
    );
  }

  test_unit_setter() async {
    var library = await buildTestLibrary(a, r'''
void set foo(_) {}
void set bar(_) {}
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(aUri, 'foo=', NodeKind.SETTER),
      ExpectedNode(aUri, 'bar=', NodeKind.SETTER),
    ]);
  }

  test_unit_setter_api_tokens_notSame_annotation() async {
    await _assertApiTokenSignatureNotSame(
      'foo=',
      NodeKind.SETTER,
      'set foo(int a) {}',
      '@deprecated set foo(int a) {}',
    );
  }

  test_unit_setter_api_tokens_notSame_parameter_type() async {
    await _assertApiTokenSignatureNotSame(
      'foo=',
      NodeKind.SETTER,
      'set foo(int a) {}',
      'set foo(num a) {}',
    );
  }

  test_unit_setter_api_tokens_same_body() async {
    await _assertApiTokenSignatureSame(
      'foo=',
      NodeKind.SETTER,
      'set foo(int a) { print(0); }',
      'set foo(int a) { print(1); }',
    );
  }

  test_unit_variable() async {
    var library = await buildTestLibrary(a, r'''
int a = 1;
int b = 2, c = 3;
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(aUri, 'a', NodeKind.GETTER),
      ExpectedNode(aUri, 'b', NodeKind.GETTER),
      ExpectedNode(aUri, 'c', NodeKind.GETTER),
      ExpectedNode(aUri, 'a=', NodeKind.SETTER),
      ExpectedNode(aUri, 'b=', NodeKind.SETTER),
      ExpectedNode(aUri, 'c=', NodeKind.SETTER),
    ]);
  }

  test_unit_variable_api_tokens_notSame_annotation() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'int foo = 0;',
      '@deprecated int foo = 0;',
    );
  }

  test_unit_variable_api_tokens_notSame_const() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'int foo = 0;',
      'const int foo = 0;',
    );
  }

  test_unit_variable_api_tokens_same_final() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.GETTER,
      'int foo = 0;',
      'final int foo = 0;',
    );
  }

  test_unit_variable_api_tokens_typed_notSame_type() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'int foo = 0;',
      'num foo = 1;',
    );
  }

  test_unit_variable_api_tokens_typed_same_initializer() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.GETTER,
      'int foo = 0;',
      'int foo = 1;',
    );
  }

  test_unit_variable_api_tokens_untyped_notSame_initializer() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'var foo = 0;',
      'var foo = 1.0;',
    );
  }

  test_unit_variable_const() async {
    var library = await buildTestLibrary(a, r'''
const foo = 1;
const bar = 2;
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(aUri, 'foo', NodeKind.GETTER),
      ExpectedNode(aUri, 'bar', NodeKind.GETTER),
    ]);
  }

  test_unit_variable_const_api_tokens_typed_notSame_initializer() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'const int foo = 0;',
      'const int foo = 1;',
    );
  }

  test_unit_variable_final() async {
    var library = await buildTestLibrary(a, r'''
final foo = 1;
final bar = 2;
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(aUri, 'foo', NodeKind.GETTER),
      ExpectedNode(aUri, 'bar', NodeKind.GETTER),
    ]);
  }

  test_unit_variable_final_api_tokens_typed_same_initializer() async {
    await _assertApiTokenSignatureSame(
      'foo',
      NodeKind.GETTER,
      'final int foo = 0;',
      'final int foo = 1;',
    );
  }

  test_unit_variable_final_api_tokens_untyped_notSame_initializer() async {
    await _assertApiTokenSignatureNotSame(
      'foo',
      NodeKind.GETTER,
      'final foo = 0;',
      'final foo = 1.0;',
    );
  }

  test_unit_variable_final_withoutValue() async {
    var library = await buildTestLibrary(a, r'''
final foo;
final bar;
''');
    assertNodes(library.declaredNodes, [
      ExpectedNode(aUri, 'foo', NodeKind.GETTER),
      ExpectedNode(aUri, 'bar', NodeKind.GETTER),
    ]);
  }

  Future<void> _assertApiTokenSignatureNotSame(
      String name, NodeKind kind, String codeBefore, String codeAfter,
      {String? memberOf, String? typeParameterOf}) async {
    Node getNodeLocal(Library library) {
      return getNode(
        library,
        name: name,
        kind: kind,
        memberOf: memberOf,
        typeParameterOf: typeParameterOf,
      );
    }

    var libraryBefore = await buildTestLibrary(a, codeBefore);
    var nodeBefore = getNodeLocal(libraryBefore);

    var libraryAfter = await buildTestLibrary(a, codeAfter);
    var nodeAfter = getNodeLocal(libraryAfter);

    expect(
      nodeAfter.api.tokenSignatureHex,
      isNot(nodeBefore.api.tokenSignatureHex),
    );
  }

  Future<void> _assertApiTokenSignatureSame(
      String name, NodeKind kind, String codeBefore, String codeAfter,
      {String? memberOf, String? typeParameterOf}) async {
    Node getNodeLocal(Library library) {
      return getNode(
        library,
        name: name,
        kind: kind,
        memberOf: memberOf,
        typeParameterOf: typeParameterOf,
      );
    }

    var libraryBefore = await buildTestLibrary(a, codeBefore);
    var nodeBefore = getNodeLocal(libraryBefore);

    var libraryAfter = await buildTestLibrary(a, codeAfter);
    var nodeAfter = getNodeLocal(libraryAfter);

    expect(
      nodeAfter.api.tokenSignatureHex,
      nodeBefore.api.tokenSignatureHex,
    );
  }

  static _assertDifferentApiTokenSignature(Node a, Node b) {
    expect(
      a.api.tokenSignatureHex,
      isNot(b.api.tokenSignatureHex),
    );
  }

  static void _assertExports(Library library, List<Export> expectedExports) {
    var actualExports = library.exports;
    expect(actualExports, hasLength(expectedExports.length));
    for (var i = 0; i < actualExports.length; ++i) {
      var actual = actualExports[i];
      var expected = expectedExports[i];
      if (actual.uri != expected.uri ||
          !_equalCombinators(actual.combinators, expected.combinators)) {
        fail('Expected: $expected\nActual: $actual');
      }
    }
  }

  static void _assertImports(Library library, List<Import> expectedImports) {
    var actualImports = library.imports;
    expect(actualImports, hasLength(expectedImports.length));
    for (var i = 0; i < actualImports.length; ++i) {
      var actual = actualImports[i];
      var expected = expectedImports[i];
      if (actual.uri != expected.uri ||
          actual.prefix != expected.prefix ||
          !_equalCombinators(actual.combinators, expected.combinators)) {
        fail('Expected: $expected\nActual: $actual');
      }
    }
  }

  static bool _equalCombinators(List<Combinator> actualCombinators,
      List<Combinator> expectedCombinators) {
    if (actualCombinators.length != expectedCombinators.length) {
      return false;
    }

    for (var i = 0; i < actualCombinators.length; i++) {
      var actualCombinator = actualCombinators[i];
      var expectedCombinator = expectedCombinators[i];
      if (actualCombinator.isShow != expectedCombinator.isShow) {
        return false;
      }

      var actualNames = actualCombinator.names;
      var expectedNames = expectedCombinator.names;
      if (actualNames.length != expectedNames.length) {
        return false;
      }
      for (var j = 0; j < actualNames.length; j++) {
        if (actualNames[j] != expectedNames[j]) {
          return false;
        }
      }
    }

    return true;
  }
}
