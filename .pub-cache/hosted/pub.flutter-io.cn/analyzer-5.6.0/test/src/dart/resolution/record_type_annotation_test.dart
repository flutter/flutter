// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordTypeAnnotationTest);
  });
}

@reflectiveTest
class RecordTypeAnnotationTest extends PubPackageResolutionTest {
  test_class_method_formalParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo((int, String) a) {}
}
''');

    final node = findNode.recordTypeAnnotation('(int');
    assertResolvedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: String
          staticElement: dart:core::@class::String
          staticType: null
        type: String
  rightParenthesis: )
  type: (int, String)
''');
  }

  test_class_method_returnType() async {
    await assertNoErrorsInCode(r'''
class A {
  (int, String) foo() => throw 0;
}
''');

    final node = findNode.recordTypeAnnotation('(int');
    assertResolvedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: String
          staticElement: dart:core::@class::String
          staticType: null
        type: String
  rightParenthesis: )
  type: (int, String)
''');
  }

  test_localFunction_formalParameter() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_element
  void g((int, String) a) {}
}
''');

    final node = findNode.recordTypeAnnotation('(int');
    assertResolvedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: String
          staticElement: dart:core::@class::String
          staticType: null
        type: String
  rightParenthesis: )
  type: (int, String)
''');
  }

  test_localFunction_returnType() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_element
  (int, String) g() => throw 0;
}
''');

    final node = findNode.recordTypeAnnotation('(int');
    assertResolvedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: String
          staticElement: dart:core::@class::String
          staticType: null
        type: String
  rightParenthesis: )
  type: (int, String)
''');
  }

  test_localVariable_mixed() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  (int, String, {bool f3}) x;
}
''');

    final node = findNode.recordTypeAnnotation('(int');
    assertResolvedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: String
          staticElement: dart:core::@class::String
          staticType: null
        type: String
  namedFields: RecordTypeAnnotationNamedFields
    leftBracket: {
    fields
      RecordTypeAnnotationNamedField
        type: NamedType
          name: SimpleIdentifier
            token: bool
            staticElement: dart:core::@class::bool
            staticType: null
          type: bool
        name: f3
    rightBracket: }
  rightParenthesis: )
  type: (int, String, {bool f3})
''');
  }

  test_localVariable_named() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  ({int f1, String f2}) x;
}
''');

    final node = findNode.recordTypeAnnotation('({int');
    assertResolvedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  namedFields: RecordTypeAnnotationNamedFields
    leftBracket: {
    fields
      RecordTypeAnnotationNamedField
        type: NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
        name: f1
      RecordTypeAnnotationNamedField
        type: NamedType
          name: SimpleIdentifier
            token: String
            staticElement: dart:core::@class::String
            staticType: null
          type: String
        name: f2
    rightBracket: }
  rightParenthesis: )
  type: ({int f1, String f2})
''');
  }

  test_localVariable_positional() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  (int, String) x;
}
''');

    final node = findNode.recordTypeAnnotation('(int');
    assertResolvedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: String
          staticElement: dart:core::@class::String
          staticType: null
        type: String
  rightParenthesis: )
  type: (int, String)
''');
  }

  test_topFunction_formalParameter() async {
    await assertNoErrorsInCode(r'''
void f((int, String) a) {}
''');

    final node = findNode.recordTypeAnnotation('(int');
    assertResolvedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: String
          staticElement: dart:core::@class::String
          staticType: null
        type: String
  rightParenthesis: )
  type: (int, String)
''');
  }

  test_topFunction_nullable() async {
    await assertNoErrorsInCode(r'''
(int, String)? f() => throw 0;
''');

    final node = findNode.recordTypeAnnotation('(int');
    assertResolvedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: String
          staticElement: dart:core::@class::String
          staticType: null
        type: String
  rightParenthesis: )
  question: ?
  type: (int, String)?
''');
  }

  test_topFunction_returnType() async {
    await assertNoErrorsInCode(r'''
(int, String) f() => throw 0;
''');

    final node = findNode.recordTypeAnnotation('(int');
    assertResolvedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: String
          staticElement: dart:core::@class::String
          staticType: null
        type: String
  rightParenthesis: )
  type: (int, String)
''');
  }

  test_typeArgument() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  final x = <(int, String)>[];
}
''');

    final node = findNode.recordTypeAnnotation('(int');
    assertResolvedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: SimpleIdentifier
          token: String
          staticElement: dart:core::@class::String
          staticType: null
        type: String
  rightParenthesis: )
  type: (int, String)
''');
  }
}
