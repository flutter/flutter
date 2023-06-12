// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeadCodeTest);
    defineReflectiveTests(DeadCodeWithoutNullSafetyTest);
  });
}

@reflectiveTest
class DeadCodeTest extends PubPackageResolutionTest with DeadCodeTestCases {
  test_assert_dead_message() async {
    // We don't warn if an assert statement is live but its message is dead,
    // because this results in nuisance warnings for desirable assertions (e.g.
    // a `!= null` assertion that is redundant with strong checking but still
    // useful with weak checking).
    await assertErrorsInCode('''
void f(Object waldo) {
  assert(waldo != null, "Where's Waldo?");
}
''', [
      error(HintCode.UNNECESSARY_NULL_COMPARISON_TRUE, 38, 7),
    ]);
  }

  test_flowEnd_tryStatement_body() async {
    await assertErrorsInCode(r'''
Never foo() => throw 0;

main() {
  try {
    foo();
    1;
  } catch (_) {
    2;
  }
  3;
}
''', [
      error(HintCode.DEAD_CODE, 57, 2),
    ]);
  }

  test_invokeNever_functionExpressionInvocation_getter_propertyAccess() async {
    await assertErrorsInCode(r'''
class A {
  Never get f => throw 0;
}
void g(A a) {
  a.f(0);
  print(1);
}
''', [
      error(HintCode.RECEIVER_OF_TYPE_NEVER, 54, 3),
      error(HintCode.DEAD_CODE, 57, 16),
    ]);
  }

  test_invokeNever_functionExpressionInvocation_parenthesizedExpression() async {
    await assertErrorsInCode(r'''
void g(Never f) {
  (f)(0);
  print(1);
}
''', [
      error(HintCode.RECEIVER_OF_TYPE_NEVER, 20, 3),
      error(HintCode.DEAD_CODE, 23, 16),
    ]);
  }

  test_invokeNever_functionExpressionInvocation_simpleIdentifier() async {
    await assertErrorsInCode(r'''
void g(Never f) {
  f(0);
  print(1);
}
''', [
      error(HintCode.RECEIVER_OF_TYPE_NEVER, 20, 1),
      error(HintCode.DEAD_CODE, 21, 16),
    ]);
  }

  test_returnTypeNever_function() async {
    await assertErrorsInCode(r'''
Never foo() => throw 0;

main() {
  foo();
  1;
}
''', [
      error(HintCode.DEAD_CODE, 45, 2),
    ]);
  }

  test_returnTypeNever_getter() async {
    await assertErrorsInCode(r'''
Never get foo => throw 0;

main() {
  foo;
  2;
}
''', [
      error(HintCode.DEAD_CODE, 45, 2),
    ]);
  }

  @FailingTest(reason: '@alwaysThrows is not supported in flow analysis')
  @override
  test_statementAfterAlwaysThrowsFunction() async {
    return super.test_statementAfterAlwaysThrowsFunction();
  }

  @FailingTest(reason: '@alwaysThrows is not supported in flow analysis')
  @override
  test_statementAfterAlwaysThrowsMethod() async {
    return super.test_statementAfterAlwaysThrowsMethod();
  }

  test_switchStatement_exhaustive() async {
    await assertErrorsInCode(r'''
enum Foo { a, b }

int f(Foo foo) {
  switch (foo) {
    case Foo.a: return 0;
    case Foo.b: return 1;
  }
  return -1;
}
''', [
      error(HintCode.DEAD_CODE, 111, 10),
    ]);
  }
}

mixin DeadCodeTestCases on PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_afterForEachWithBreakLabel() async {
    await assertNoErrorsInCode(r'''
f(List<Object> values) {
  named: {
    for (var x in values) {
      if (x == 42) {
        break named;
      }
    }
    return;
  }
  print('not dead');
}
''');
  }

  test_afterForWithBreakLabel() async {
    await assertNoErrorsInCode(r'''
f() {
  named: {
    for (int i = 0; i < 7; i++) {
      if (i == 42)
        break named;
    }
    return;
  }
  print('not dead');
}
''');
  }

  test_afterTryCatch() async {
    await assertNoErrorsInCode(r'''
main() {
  try {
    return f();
  } catch (e) {
    print(e);
  }
  print('not dead');
}
f() {
  throw 'foo';
}
''');
  }

  test_deadBlock_conditionalElse() async {
    await assertErrorsInCode(r'''
f() {
  true ? 1 : 2;
}''', [
      error(HintCode.DEAD_CODE, 19, 1),
    ]);
  }

  test_deadBlock_conditionalElse_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = true;
f() {
  DEBUG ? 1 : 2;
}''');
  }

  test_deadBlock_conditionalElse_nested() async {
    // Test that a dead else-statement can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  true ? true : false && false;
}''', [
      error(HintCode.DEAD_CODE, 22, 14),
    ]);
  }

  test_deadBlock_conditionalIf() async {
    await assertErrorsInCode(r'''
f() {
  false ? 1 : 2;
}''', [
      error(HintCode.DEAD_CODE, 16, 1),
    ]);
  }

  test_deadBlock_conditionalIf_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = false;
f() {
  DEBUG ? 1 : 2;
}''');
  }

  test_deadBlock_conditionalIf_nested() async {
    // Test that a dead then-statement can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  false ? false && false : true;
}''', [
      error(HintCode.DEAD_CODE, 16, 14),
    ]);
  }

  test_deadBlock_else() async {
    await assertErrorsInCode(r'''
f() {
  if(true) {} else {}
}''', [
      error(HintCode.DEAD_CODE, 25, 2),
    ]);
  }

  test_deadBlock_else_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = true;
f() {
  if(DEBUG) {} else {}
}''');
  }

  test_deadBlock_else_nested() async {
    // Test that a dead else-statement can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  if(true) {} else {if (false) {}}
}''', [
      error(HintCode.DEAD_CODE, 25, 15),
    ]);
  }

  test_deadBlock_if() async {
    await assertErrorsInCode(r'''
f() {
  if(false) {}
}''', [
      error(HintCode.DEAD_CODE, 18, 2),
    ]);
  }

  test_deadBlock_if_debugConst_prefixedIdentifier() async {
    await assertNoErrorsInCode(r'''
class A {
  static const bool DEBUG = false;
}
f() {
  if(A.DEBUG) {}
}''');
  }

  test_deadBlock_if_debugConst_prefixedIdentifier2() async {
    newFile('$testPackageLibPath/lib2.dart', content: r'''
class A {
  static const bool DEBUG = false;
}''');
    await assertNoErrorsInCode(r'''
import 'lib2.dart';
f() {
  if(A.DEBUG) {}
}''');
  }

  test_deadBlock_if_debugConst_propertyAccessor() async {
    newFile('$testPackageLibPath/lib2.dart', content: r'''
class A {
  static const bool DEBUG = false;
}''');
    await assertNoErrorsInCode(r'''
import 'lib2.dart' as LIB;
f() {
  if(LIB.A.DEBUG) {}
}''');
  }

  test_deadBlock_if_debugConst_simpleIdentifier() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = false;
f() {
  if(DEBUG) {}
}''');
  }

  test_deadBlock_if_nested() async {
    // Test that a dead then-statement can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  if(false) {if(false) {}}
}''', [
      error(HintCode.DEAD_CODE, 18, 14),
    ]);
  }

  test_deadBlock_ifElement() async {
    await assertErrorsInCode(r'''
f() {
  [
    if (false) 2,
  ];
}''', [
      error(HintCode.DEAD_CODE, 25, 1),
    ]);
  }

  test_deadBlock_ifElement_else() async {
    await assertErrorsInCode(r'''
f() {
  [
    if (true) 2
    else 3,
  ];
}''', [
      error(HintCode.DEAD_CODE, 35, 1),
    ]);
  }

  test_deadBlock_while() async {
    await assertErrorsInCode(r'''
f() {
  while(false) {}
}''', [
      error(HintCode.DEAD_CODE, 21, 2),
    ]);
  }

  test_deadBlock_while_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = false;
f() {
  while(DEBUG) {}
}''');
  }

  test_deadBlock_while_nested() async {
    // Test that a dead while body can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  while(false) {if(false) {}}
}''', [
      error(HintCode.DEAD_CODE, 21, 14),
    ]);
  }

  test_deadCatch_catchFollowingCatch() async {
    await assertErrorsInCode(r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {}
}''', [
      error(HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, 39, 12),
    ]);
  }

  test_deadCatch_catchFollowingCatch_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await assertErrorsInCode(r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {if(false) {}}
}''', [
      error(HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, 39, 24),
    ]);
  }

  test_deadCatch_catchFollowingCatch_object() async {
    await assertErrorsInCode(r'''
f() {
  try {} on Object catch (e) {} catch (e) {}
}''', [
      error(HintCode.UNUSED_CATCH_CLAUSE, 32, 1),
      error(HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, 38, 12),
    ]);
  }

  test_deadCatch_catchFollowingCatch_object_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  try {} on Object catch (e) {} catch (e) {if(false) {}}
}''', [
      error(HintCode.UNUSED_CATCH_CLAUSE, 32, 1),
      error(HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, 38, 24),
    ]);
  }

  test_deadCatch_onCatchSubtype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {}
}''', [
      error(HintCode.UNUSED_CATCH_CLAUSE, 59, 1),
      error(HintCode.DEAD_CODE_ON_CATCH_SUBTYPE, 65, 17),
      error(HintCode.UNUSED_CATCH_CLAUSE, 77, 1),
    ]);
  }

  test_deadCatch_onCatchSubtype_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {if(false) {}}
}''', [
      error(HintCode.UNUSED_CATCH_CLAUSE, 59, 1),
      error(HintCode.DEAD_CODE_ON_CATCH_SUBTYPE, 65, 29),
      error(HintCode.UNUSED_CATCH_CLAUSE, 77, 1),
    ]);
  }

  test_deadCatch_onCatchSupertype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
f() {
  try {} on B catch (e) {} on A catch (e) {} catch (e) {}
}
''', [
      error(HintCode.UNUSED_CATCH_CLAUSE, 59, 1),
      error(HintCode.UNUSED_CATCH_CLAUSE, 77, 1),
    ]);
  }

  test_deadOperandLHS_and() async {
    await assertErrorsInCode(r'''
f() {
  bool b = false && false;
  print(b);
}''', [
      error(HintCode.DEAD_CODE, 26, 5),
    ]);
  }

  test_deadOperandLHS_and_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = false;
f() {
  bool b = DEBUG && false;
  print(b);
}''');
  }

  test_deadOperandLHS_and_nested() async {
    await assertErrorsInCode(r'''
f() {
  bool b = false && (false && false);
  print(b);
}''', [
      error(HintCode.DEAD_CODE, 26, 16),
    ]);
  }

  test_deadOperandLHS_or() async {
    await assertErrorsInCode(r'''
f() {
  bool b = true || true;
  print(b);
}''', [
      error(HintCode.DEAD_CODE, 25, 4),
    ]);
  }

  test_deadOperandLHS_or_debugConst() async {
    await assertErrorsInCode(r'''
const bool DEBUG = true;
f() {
  bool b = DEBUG || true;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 38, 1),
    ]);
  }

  test_deadOperandLHS_or_nested() async {
    await assertErrorsInCode(r'''
f() {
  bool b = true || (false && false);
  print(b);
}''', [
      error(HintCode.DEAD_CODE, 25, 16),
    ]);
  }

  test_documentationComment() async {
    await assertNoErrorsInCode(r'''
/// text
int f() => 0;
''');
  }

  test_flowEnd_forStatement() async {
    await assertErrorsInCode(r'''
main() {
  for (var v in [0, 1, 2]) {
    v;
    return;
    1;
  }
  2;
}
''', [
      error(HintCode.DEAD_CODE, 61, 2),
    ]);
  }

  test_flowEnd_ifStatement() async {
    await assertErrorsInCode(r'''
void f(bool a) {
  if (a) {
    return;
    1;
  }
  2;
}
''', [
      error(HintCode.DEAD_CODE, 44, 2),
    ]);
  }

  test_flowEnd_tryStatement_catchClause() async {
    await assertErrorsInCode(r'''
main() {
  try {
    1;
  } catch (_) {
    return;
    2;
  }
  3;
}
''', [
      error(HintCode.DEAD_CODE, 56, 2),
    ]);
  }

  test_flowEnd_tryStatement_finally() async {
    var expectedErrors = expectedErrorsByNullability(
      nullable: [
        error(HintCode.DEAD_CODE, 61, 11),
      ],
      legacy: [
        error(HintCode.DEAD_CODE, 61, 2),
        error(HintCode.DEAD_CODE, 70, 2),
      ],
    );
    await assertErrorsInCode(r'''
main() {
  try {
    1;
  } finally {
    2;
    return;
    3;
  }
  4;
}
''', expectedErrors);
  }

  test_statementAfterAlwaysThrowsFunction() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@alwaysThrows
void a() {
  throw 'msg';
}

f() {
  print(1);
  a();
  print(2);
}''', [
      error(HintCode.DEAD_CODE, 104, 9),
    ]);
  }

  @failingTest
  test_statementAfterAlwaysThrowsGetter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @alwaysThrows
  int get a {
    throw 'msg';
  }

f() {
  print(1);
  new C().a;
  print(2);
}''', [
      error(HintCode.DEAD_CODE, 129, 9),
    ]);
  }

  test_statementAfterAlwaysThrowsMethod() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @alwaysThrows
  void a() {
    throw 'msg';
  }
}

f() {
  print(1);
  new C().a();
  print(2);
}''', [
      error(HintCode.DEAD_CODE, 132, 9),
    ]);
  }

  test_statementAfterBreak_inDefaultCase() async {
    await assertErrorsInCode(r'''
f(v) {
  switch(v) {
    case 1:
    default:
      break;
      print(1);
  }
}''', [
      error(HintCode.DEAD_CODE, 65, 9),
    ]);
  }

  test_statementAfterBreak_inForEachStatement() async {
    await assertErrorsInCode(r'''
f() {
  var list;
  for(var l in list) {
    break;
    print(l);
  }
}''', [
      error(HintCode.DEAD_CODE, 56, 9),
    ]);
  }

  test_statementAfterBreak_inForStatement() async {
    await assertErrorsInCode(r'''
f() {
  for(;;) {
    break;
    print(1);
  }
}''', [
      error(HintCode.DEAD_CODE, 33, 9),
    ]);
  }

  test_statementAfterBreak_inSwitchCase() async {
    await assertErrorsInCode(r'''
f(v) {
  switch(v) {
    case 1:
      break;
      print(1);
  }
}''', [
      error(HintCode.DEAD_CODE, 52, 9),
    ]);
  }

  test_statementAfterBreak_inWhileStatement() async {
    await assertErrorsInCode(r'''
f(v) {
  while(v) {
    break;
    print(1);
  }
}''', [
      error(HintCode.DEAD_CODE, 35, 9),
    ]);
  }

  test_statementAfterContinue_inForEachStatement() async {
    await assertErrorsInCode(r'''
f() {
  var list;
  for(var l in list) {
    continue;
    print(l);
  }
}''', [
      error(HintCode.DEAD_CODE, 59, 9),
    ]);
  }

  test_statementAfterContinue_inForStatement() async {
    await assertErrorsInCode(r'''
f() {
  for(;;) {
    continue;
    print(1);
  }
}''', [
      error(HintCode.DEAD_CODE, 36, 9),
    ]);
  }

  test_statementAfterContinue_inWhileStatement() async {
    await assertErrorsInCode(r'''
f(v) {
  while(v) {
    continue;
    print(1);
  }
}''', [
      error(HintCode.DEAD_CODE, 38, 9),
    ]);
  }

  test_statementAfterExitingIf_returns() async {
    await assertErrorsInCode(r'''
f() {
  if (1 > 2) {
    return;
  } else {
    return;
  }
  print(1);
}''', [
      error(HintCode.DEAD_CODE, 62, 9),
    ]);
  }

  test_statementAfterIfWithoutElse() async {
    await assertNoErrorsInCode(r'''
f() {
  if (1 < 0) {
    return;
  }
  print(1);
}''');
  }

  test_statementAfterRethrow() async {
    await assertErrorsInCode(r'''
f() {
  try {
    print(1);
  } catch (e) {
    rethrow;
    print(2);
  }
}''', [
      error(HintCode.DEAD_CODE, 61, 9),
    ]);
  }

  test_statementAfterReturn_function() async {
    await assertErrorsInCode(r'''
f() {
  print(1);
  return;
  print(2);
}''', [
      error(HintCode.DEAD_CODE, 30, 9),
    ]);
  }

  test_statementAfterReturn_function_local() async {
    await assertErrorsInCode(r'''
f() {
  void g() {
    print(1);
    return;
    print(2);
  }
  g();
}''', [
      error(HintCode.DEAD_CODE, 49, 9),
    ]);
  }

  test_statementAfterReturn_functionExpression() async {
    await assertErrorsInCode(r'''
f() {
  () {
    print(1);
    return;
    print(2);
  };
}''', [
      error(HintCode.DEAD_CODE, 43, 9),
    ]);
  }

  test_statementAfterReturn_ifStatement() async {
    await assertErrorsInCode(r'''
f(bool b) {
  if(b) {
    print(1);
    return;
    print(2);
  }
}''', [
      error(HintCode.DEAD_CODE, 52, 9),
    ]);
  }

  test_statementAfterReturn_method() async {
    await assertErrorsInCode(r'''
class A {
  m() {
    print(1);
    return;
    print(2);
  }
}''', [
      error(HintCode.DEAD_CODE, 48, 9),
    ]);
  }

  test_statementAfterReturn_nested() async {
    await assertErrorsInCode(r'''
f() {
  print(1);
  return;
  if(false) {}
}''', [
      error(HintCode.DEAD_CODE, 30, 12),
    ]);
  }

  test_statementAfterReturn_twoReturns() async {
    await assertErrorsInCode(r'''
f() {
  print(1);
  return;
  print(2);
  return;
  print(3);
}''', [
      error(HintCode.DEAD_CODE, 30, 31),
    ]);
  }

  test_statementAfterThrow() async {
    await assertErrorsInCode(r'''
f() {
  print(1);
  throw 'Stop here';
  print(2);
}''', [
      error(HintCode.DEAD_CODE, 41, 9),
    ]);
  }

  test_switchCase_final_break() async {
    var expectedErrors = expectedErrorsByNullability(nullable: [
      error(HintCode.DEAD_CODE, 96, 6),
    ], legacy: []);
    await assertErrorsInCode(r'''
void f(int a) {
  switch (a) {
    case 0:
      try {} finally {
        return;
      }
      break;
  }
}
''', expectedErrors);
  }

  test_switchCase_final_continue() async {
    var expectedErrors = expectedErrorsByNullability(nullable: [
      error(HintCode.DEAD_CODE, 140, 9),
    ], legacy: []);
    await assertErrorsInCode(r'''
void f(int a) {
  for (var i = 0; i < 2; i++) {
    switch (a) {
      case 0:
        try {} finally {
          return;
        }
        continue;
    }
  }
}
''', expectedErrors);
  }

  test_switchCase_final_rethrow() async {
    var expectedErrors = expectedErrorsByNullability(nullable: [
      error(HintCode.DEAD_CODE, 142, 8),
    ], legacy: []);
    await assertErrorsInCode(r'''
void f(int a) {
  try {
    // empty
  } on int {
    switch (a) {
      case 0:
        try {} finally {
          return;
        }
        rethrow;
    }
  }
}
''', expectedErrors);
  }

  test_switchCase_final_return() async {
    var expectedErrors = expectedErrorsByNullability(nullable: [
      error(HintCode.DEAD_CODE, 96, 7),
    ], legacy: []);
    await assertErrorsInCode(r'''
void f(int a) {
  switch (a) {
    case 0:
      try {} finally {
        return;
      }
      return;
  }
}
''', expectedErrors);
  }

  test_switchCase_final_throw() async {
    var expectedErrors = expectedErrorsByNullability(nullable: [
      error(HintCode.DEAD_CODE, 96, 8),
    ], legacy: []);
    await assertErrorsInCode(r'''
void f(int a) {
  switch (a) {
    case 0:
      try {} finally {
        return;
      }
      throw 0;
  }
}
''', expectedErrors);
  }
}

@reflectiveTest
class DeadCodeWithoutNullSafetyTest extends PubPackageResolutionTest
    with DeadCodeTestCases, WithoutNullSafetyMixin {}
