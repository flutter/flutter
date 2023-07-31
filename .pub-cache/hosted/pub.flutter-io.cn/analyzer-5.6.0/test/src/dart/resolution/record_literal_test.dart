// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordLiteralTest);
  });
}

@reflectiveTest
class RecordLiteralTest extends PubPackageResolutionTest {
  test_field_rewrite_named() async {
    await assertNoErrorsInCode(r'''
void f((int, String) r) {
  (f1: r.$1, );
}
''');

    final node = findNode.recordLiteral('(f1');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          staticType: null
        colon: :
      expression: PropertyAccess
        target: SimpleIdentifier
          token: r
          staticElement: self::@function::f::@parameter::r
          staticType: (int, String)
        operator: .
        propertyName: SimpleIdentifier
          token: $1
          staticElement: <null>
          staticType: int
        staticType: int
  rightParenthesis: )
  staticType: ({int f1})
''');
  }

  test_field_rewrite_positional() async {
    await assertNoErrorsInCode(r'''
void f((int, String) r) {
  (r.$1, );
}
''');

    final node = findNode.recordLiteral('(r');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    PropertyAccess
      target: SimpleIdentifier
        token: r
        staticElement: self::@function::f::@parameter::r
        staticType: (int, String)
      operator: .
      propertyName: SimpleIdentifier
        token: $1
        staticElement: <null>
        staticType: int
      staticType: int
  rightParenthesis: )
  staticType: (int)
''');
  }

  test_hasContext_implicitCallReference_named() async {
    await assertNoErrorsInCode(r'''
class A {
  void call() {}
}

final a = A();
final ({void Function() f1}) x = (f1: a);
''');

    final node = findNode.recordLiteral('(f1');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          staticType: null
        colon: :
      expression: ImplicitCallReference
        expression: SimpleIdentifier
          token: a
          staticElement: self::@getter::a
          staticType: A
        staticElement: self::@class::A::@method::call
        staticType: void Function()
  rightParenthesis: )
  staticType: ({void Function() f1})
''');
  }

  test_hasContext_implicitCallReference_positional() async {
    await assertNoErrorsInCode(r'''
class A {
  void call() {}
}

final a = A();
final (void Function(), ) x = (a, );
''');

    final node = findNode.recordLiteral('(a');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    ImplicitCallReference
      expression: SimpleIdentifier
        token: a
        staticElement: self::@getter::a
        staticType: A
      staticElement: self::@class::A::@method::call
      staticType: void Function()
  rightParenthesis: )
  staticType: (void Function())
''');
  }

  test_hasContext_implicitCast_fromDynamic_named() async {
    await assertNoErrorsInCode(r'''
final dynamic a = 0;
final ({int f1}) x = (f1: a);
''');

    final node = findNode.recordLiteral('(f1');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          staticType: null
        colon: :
      expression: SimpleIdentifier
        token: a
        staticElement: self::@getter::a
        staticType: int
  rightParenthesis: )
  staticType: ({int f1})
''');
  }

  test_hasContext_implicitCast_fromDynamic_positional() async {
    await assertNoErrorsInCode(r'''
final dynamic a = 0;
final (int, ) x = (a, );
''');

    final node = findNode.recordLiteral('(a');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    SimpleIdentifier
      token: a
      staticElement: self::@getter::a
      staticType: int
  rightParenthesis: )
  staticType: (int)
''');
  }

  test_hasContext_mixed() async {
    await assertNoErrorsInCode(r'''
class A1 {}
class A2 {}
class A3 {}
class A4 {}
class A5 {}

final (A1, A2, A3, {A4 f1, A5 f2}) x = (g(), f1: g(), g(), f2: g(), g());

T g<T>() => throw 0;
''');

    final node = findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: self::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: A1 Function()
      staticType: A1
      typeArgumentTypes
        A1
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: self::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: A4 Function()
        staticType: A4
        typeArgumentTypes
          A4
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: self::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: A2 Function()
      staticType: A2
      typeArgumentTypes
        A2
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f2
          staticElement: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: self::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: A5 Function()
        staticType: A5
        typeArgumentTypes
          A5
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: self::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: A3 Function()
      staticType: A3
      typeArgumentTypes
        A3
  rightParenthesis: )
  staticType: (A1, A2, A3, {A4 f1, A5 f2})
''');
  }

  test_hasContext_named() async {
    await assertNoErrorsInCode(r'''
final ({int f1, String f2}) x = (f1: g(), f2: g());

T g<T>() => throw 0;
''');

    final node = findNode.recordLiteral('(f1:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: self::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: int Function()
        staticType: int
        typeArgumentTypes
          int
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f2
          staticElement: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: self::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: String Function()
        staticType: String
        typeArgumentTypes
          String
  rightParenthesis: )
  staticType: ({int f1, String f2})
''');
  }

  test_hasContext_named_differentOrder() async {
    await assertNoErrorsInCode(r'''
final ({int f1, String f2}) x = (f2: g(), f1: g());

T g<T>() => throw 0;
''');

    final node = findNode.recordLiteral('(f2:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f2
          staticElement: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: self::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: String Function()
        staticType: String
        typeArgumentTypes
          String
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: self::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: int Function()
        staticType: int
        typeArgumentTypes
          int
  rightParenthesis: )
  staticType: ({int f1, String f2})
''');
  }

  test_hasContext_notRecordType() async {
    await assertNoErrorsInCode(r'''
final Object x = (g(), g());

T g<T>() => throw 0;
''');

    final node = findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: self::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: dynamic Function()
      staticType: dynamic
      typeArgumentTypes
        dynamic
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: self::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: dynamic Function()
      staticType: dynamic
      typeArgumentTypes
        dynamic
  rightParenthesis: )
  staticType: (dynamic, dynamic)
''');
  }

  test_hasContext_positional() async {
    await assertNoErrorsInCode(r'''
final (int, String) x = (g(), g());

T g<T>() => throw 0;
''');

    final node = findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: self::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
      typeArgumentTypes
        int
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: self::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: String Function()
      staticType: String
      typeArgumentTypes
        String
  rightParenthesis: )
  staticType: (int, String)
''');
  }

  test_noContext_empty() async {
    await assertNoErrorsInCode(r'''
final x = ();
''');

    final node = findNode.recordLiteral('()');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  rightParenthesis: )
  staticType: ()
''');
  }

  test_noContext_mixed() async {
    await assertNoErrorsInCode(r'''
final x = (0, f1: 1, 2, f2: 3, 4);
''');

    final node = findNode.recordLiteral('(0,');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
      staticType: int
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          staticType: null
        colon: :
      expression: IntegerLiteral
        literal: 1
        staticType: int
    IntegerLiteral
      literal: 2
      staticType: int
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f2
          staticElement: <null>
          staticType: null
        colon: :
      expression: IntegerLiteral
        literal: 3
        staticType: int
    IntegerLiteral
      literal: 4
      staticType: int
  rightParenthesis: )
  staticType: (int, int, int, {int f1, int f2})
''');
  }

  test_noContext_named() async {
    await assertNoErrorsInCode(r'''
final x = (f1: 0, f2: true);
''');

    final node = findNode.recordLiteral('(f1:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          staticType: null
        colon: :
      expression: IntegerLiteral
        literal: 0
        staticType: int
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f2
          staticElement: <null>
          staticType: null
        colon: :
      expression: BooleanLiteral
        literal: true
        staticType: bool
  rightParenthesis: )
  staticType: ({int f1, bool f2})
''');
  }

  test_noContext_positional() async {
    await assertNoErrorsInCode(r'''
final x = (0, true);
''');

    final node = findNode.recordLiteral('(0,');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
      staticType: int
    BooleanLiteral
      literal: true
      staticType: bool
  rightParenthesis: )
  staticType: (int, bool)
''');
  }
}
