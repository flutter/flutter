// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeadCodeTest);
    defineReflectiveTests(DeadCodeTest_Language218);
    defineReflectiveTests(DeadCodeWithoutNullSafetyTest);
  });
}

@reflectiveTest
class DeadCodeTest extends PubPackageResolutionTest
    with DeadCodeTestCases, DeadCodeTestCases_Language212 {
  test_deadPattern_ifCase_logicalOrPattern_leftAlwaysMatches() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case int() || 0) {}
}
''', [
      error(HintCode.DEAD_CODE, 35, 4),
    ]);
  }

  test_deadPattern_ifCase_logicalOrPattern_leftAlwaysMatches_nested() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case (int() || 0) && 1) {}
}
''', [
      error(HintCode.DEAD_CODE, 36, 4),
    ]);
  }

  test_deadPattern_ifCase_logicalOrPattern_leftAlwaysMatches_nested2() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case <int>[int() || 0, 1]) {}
}
''', [
      error(HintCode.DEAD_CODE, 45, 4),
    ]);
  }

  test_deadPattern_switchExpression_logicalOrPattern() async {
    await assertErrorsInCode(r'''
Object f(int x) {
  return switch (x) {
    int() || 0 => 0,
  };
}
''', [
      error(HintCode.DEAD_CODE, 50, 4),
    ]);
  }

  test_deadPattern_switchExpression_logicalOrPattern_nextCases() async {
    await assertErrorsInCode(r'''
Object f(int x) {
  return switch (x) {
    int() || 0 => 0,
    int() => 1,
    _ => 2,
  };
}
''', [
      error(HintCode.DEAD_CODE, 50, 4),
      error(HintCode.DEAD_CODE, 65, 10),
      error(HintCode.DEAD_CODE, 81, 6),
    ]);
  }

  test_deadPattern_switchStatement_logicalOrPattern() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case int() || 0:
      break;
  }
}
''', [
      error(HintCode.DEAD_CODE, 46, 4),
    ]);
  }

  test_deadPattern_switchStatement_nextCases() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case int() || 0:
    case 1:
    default:
      break;
  }
}
''', [
      error(HintCode.DEAD_CODE, 46, 4),
      error(HintCode.DEAD_CODE, 56, 4),
      error(HintCode.DEAD_CODE, 68, 7),
    ]);
  }

  test_deadPattern_switchStatement_nextCases2() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case int() || 42:
    case int() || 1:
    case 2:
      break;
  }
}
''', [
      error(HintCode.DEAD_CODE, 46, 5),
      error(HintCode.DEAD_CODE, 57, 4),
      error(HintCode.DEAD_CODE, 78, 4),
    ]);
  }

  test_ifElement_patternAssignment() async {
    await assertErrorsInCode(r'''
void f(int a) {
  [if (false) (a) = 0];
}
''', [
      error(HintCode.DEAD_CODE, 30, 7),
    ]);
  }
}

@reflectiveTest
class DeadCodeTest_Language218 extends PubPackageResolutionTest
    with
        WithLanguage218Mixin,
        DeadCodeTestCases,
        DeadCodeTestCases_Language212 {}

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

  test_assert() async {
    await assertErrorsInCode(r'''
void f() {
  return;
  assert (true);
}
''', [
      error(HintCode.DEAD_CODE, 23, 14),
    ]);
  }

  test_class_field_initializer_listLiteral() async {
    // Based on https://github.com/dart-lang/sdk/issues/49701
    await assertErrorsInCode(
      '''
Never f() { throw ''; }

class C {
  static final x = [1, 2, f(), 4];
}
''',
      isNullSafetyEnabled ? [error(HintCode.DEAD_CODE, 66, 2)] : [],
    );
  }

  test_continueInSwitch() async {
    await assertNoErrorsInCode(r'''
void f(int i) {
  for (;; 1) {
    switch (i) {
      default:
        continue;
    }
  }
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
    newFile('$testPackageLibPath/lib2.dart', r'''
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
    newFile('$testPackageLibPath/lib2.dart', r'''
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
      error(WarningCode.UNUSED_CATCH_CLAUSE, 32, 1),
      error(HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, 38, 12),
    ]);
  }

  test_deadCatch_catchFollowingCatch_object_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await assertErrorsInCode(r'''
f() {
  try {} on Object catch (e) {} catch (e) {if(false) {}}
}''', [
      error(WarningCode.UNUSED_CATCH_CLAUSE, 32, 1),
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
      error(WarningCode.UNUSED_CATCH_CLAUSE, 59, 1),
      error(HintCode.DEAD_CODE_ON_CATCH_SUBTYPE, 65, 17),
      error(WarningCode.UNUSED_CATCH_CLAUSE, 77, 1),
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
      error(WarningCode.UNUSED_CATCH_CLAUSE, 59, 1),
      error(HintCode.DEAD_CODE_ON_CATCH_SUBTYPE, 65, 29),
      error(WarningCode.UNUSED_CATCH_CLAUSE, 77, 1),
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
      error(WarningCode.UNUSED_CATCH_CLAUSE, 59, 1),
      error(WarningCode.UNUSED_CATCH_CLAUSE, 77, 1),
    ]);
  }

  test_deadOperandLHS_and() async {
    await assertErrorsInCode(r'''
f() {
  bool b = false && false;
  print(b);
}''', [
      error(HintCode.DEAD_CODE, 23, 8),
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
      error(HintCode.DEAD_CODE, 23, 19),
    ]);
  }

  test_deadOperandLHS_or() async {
    await assertErrorsInCode(r'''
f() {
  bool b = true || true;
  print(b);
}''', [
      error(HintCode.DEAD_CODE, 22, 7),
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
      error(HintCode.DEAD_CODE, 22, 19),
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

  test_forStatement() async {
    await assertErrorsInCode(r'''
void f() {
  return;
  for (;;) {}
}
''', [
      error(HintCode.DEAD_CODE, 23, 11),
    ]);
  }

  test_ifStatement_noCase_conditionFalse() async {
    await assertErrorsInCode(r'''
void f() {
  if (false) {
    1;
  } else {
    2;
  }
  3;
}
''', [
      error(HintCode.DEAD_CODE, 24, 12),
    ]);
  }

  test_ifStatement_noCase_conditionTrue() async {
    await assertErrorsInCode(r'''
void f() {
  if (true) {
    1;
  } else {
    2;
  }
  3;
}
''', [
      error(HintCode.DEAD_CODE, 41, 12),
    ]);
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

  test_topLevelVariable_initializer_listLiteral() async {
    // Based on https://github.com/dart-lang/sdk/issues/49701
    await assertErrorsInCode(
      '''
Never f() { throw ''; }

var x = [1, 2, f(), 4];
''',
      isNullSafetyEnabled ? [error(HintCode.DEAD_CODE, 45, 2)] : [],
    );
  }

  test_yield() async {
    await assertErrorsInCode(r'''
Iterable<int> f() sync* {
  return;
  yield 1;
}''', [
      error(HintCode.DEAD_CODE, 38, 8),
    ]);
  }
}

/// We require [DeadCodeTestCases] to force the test class to mix in
/// [DeadCodeTestCases] before [DeadCodeTestCases_Language212], so that we
/// don't miss these tests.
mixin DeadCodeTestCases_Language212 on DeadCodeTestCases {
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

  test_assigned_methodInvocation() async {
    await assertErrorsInCode(r'''
void f() {
  int? i = 1;
  i?.truncate();
}
''', [
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 28, 2),
    ]);
  }

  test_doWhile() async {
    await assertErrorsInCode(r'''
void f(bool c) {
  do {
    print(c);
    return;
  } while (c);
}
''', [
      error(HintCode.DEAD_CODE, 19, 4),
      error(HintCode.DEAD_CODE, 52, 12),
    ]);
  }

  test_doWhile_break() async {
    await assertErrorsInCode(r'''
void f(bool c) {
  do {
    if (c) {
     break;
    }
    return;
  } while (c);
  print('');
}
''', [
      error(HintCode.DEAD_CODE, 19, 4),
      error(HintCode.DEAD_CODE, 69, 12),
    ]);
  }

  test_doWhile_break_doLabel() async {
    await assertErrorsInCode(r'''
void f(bool c) {
  label:
  do {
    if (c) {
      break label;
    }
    return;
  } while (c);
  print('');
}
''', [
      error(HintCode.DEAD_CODE, 28, 4),
      error(HintCode.DEAD_CODE, 85, 12),
    ]);
  }

  test_doWhile_break_inner() async {
    await assertErrorsInCode(r'''
void f(bool c) {
  do {
    while (c) {
      break;
    }
    return;
  } while (c);
  print('');
}
''', [
      error(HintCode.DEAD_CODE, 19, 4),
      error(HintCode.DEAD_CODE, 73, 12),
      error(HintCode.DEAD_CODE, 88, 10),
    ]);
  }

  Future<void> test_doWhile_break_outerDoLabel() async {
    await assertErrorsInCode(r'''
void f(bool c) {
  label:
  do {
    do {
      if (c) {
        break label;
      }
      return;
    } while (c);
    print('');
  } while (c);
  print('');
}
''', [
      error(HintCode.DEAD_CODE, 37, 4),
      error(HintCode.DEAD_CODE, 104, 12),
      error(HintCode.DEAD_CODE, 121, 38),
    ]);
  }

  Future<void> test_doWhile_break_outerLabel() async {
    await assertErrorsInCode(r'''
void f(bool c) {
  label: {
    do {
      if (c) {
       break label;
      }
      return;
    } while (c);
    print('');
  }
}
''', [
      error(HintCode.DEAD_CODE, 32, 4),
      error(HintCode.DEAD_CODE, 98, 12),
      error(HintCode.DEAD_CODE, 115, 14),
    ]);
  }

  test_doWhile_statements() async {
    await assertErrorsInCode(r'''
void f(bool c) {
  do {
    print(c);
    return;
  } while (c);
  print('2');
}
''', [
      error(HintCode.DEAD_CODE, 19, 4),
      error(HintCode.DEAD_CODE, 52, 12),
      error(HintCode.DEAD_CODE, 67, 11),
    ]);
  }

  test_flowEnd_block_forStatement_updaters() async {
    await assertErrorsInCode(r'''
void f() {
  for (;; 1) {
    return;
    2;
  }
}
''', [
      error(HintCode.DEAD_CODE, 21, 1),
      error(HintCode.DEAD_CODE, 42, 2),
    ]);
  }

  test_flowEnd_block_forStatement_updaters_multiple() async {
    await assertErrorsInCode(r'''
void f() {
  for (;; 1, 2) {
    return;
  }
}
''', [
      error(HintCode.DEAD_CODE, 21, 4),
    ]);
  }

  test_flowEnd_forParts_condition_exists() async {
    await assertErrorsInCode(r'''
void f() {
  for (; throw 0; 1) {}
}
''', [
      error(HintCode.DEAD_CODE, 29, 1),
      error(HintCode.DEAD_CODE, 32, 2),
    ]);
  }

  test_flowEnd_forParts_updaters_assignmentExpression() async {
    await assertErrorsInCode(r'''
void f() {
  for (var i = 0;; i = i + 1) {
    return;
  }
}
''', [
      error(HintCode.DEAD_CODE, 30, 9),
    ]);
  }

  test_flowEnd_forParts_updaters_binaryExpression() async {
    await assertErrorsInCode(r'''
void f() {
  for (var i = 0;; i + 1) {
    return;
  }
}
''', [
      error(HintCode.DEAD_CODE, 30, 5),
    ]);
  }

  test_flowEnd_forParts_updaters_cascadeExpression() async {
    await assertErrorsInCode(r'''
void f() {
  for (var i = 0;; i..sign) {
    return;
  }
}
''', [
      error(HintCode.DEAD_CODE, 30, 7),
    ]);
  }

  test_flowEnd_forParts_updaters_conditionalExpression() async {
    await assertErrorsInCode(r'''
void f() {
  for (var i = 0;; i > 1 ? i : i) {
    return;
  }
}
''', [
      error(HintCode.DEAD_CODE, 30, 13),
    ]);
  }

  test_flowEnd_forParts_updaters_indexExpression() async {
    await assertErrorsInCode(r'''
void f(List<int> values) {
  for (;; values[0]) {
    return;
  }
}
''', [
      error(HintCode.DEAD_CODE, 37, 9),
    ]);
  }

  test_flowEnd_forParts_updaters_instanceCreationExpression() async {
    await assertErrorsInCode(r'''
class C {}
void f() {
  for (;; C()) {
    return;
  }
}
''', [
      error(HintCode.DEAD_CODE, 32, 3),
    ]);
  }

  test_flowEnd_forParts_updaters_methodInvocation() async {
    await assertErrorsInCode(r'''
void f() {
  for (var i = 0;; i.toString()) {
    return;
  }
}
''', [
      error(HintCode.DEAD_CODE, 30, 12),
    ]);
  }

  test_flowEnd_forParts_updaters_postfixExpression() async {
    await assertErrorsInCode(r'''
void f() {
  for (var i = 0;; i++) {
    return;
  }
}
''', [
      error(HintCode.DEAD_CODE, 30, 3),
    ]);
  }

  test_flowEnd_forParts_updaters_prefixedIdentifier() async {
    await assertErrorsInCode(r'''
import 'dart:math' as m;

void f() {
  for (;; m.Point) {
    return;
  }
}
''', [
      error(HintCode.DEAD_CODE, 47, 7),
    ]);
  }

  test_flowEnd_forParts_updaters_prefixExpression() async {
    await assertErrorsInCode(r'''
void f() {
  for (var i = 0;; ++i) {
    return;
  }
}
''', [
      error(HintCode.DEAD_CODE, 30, 3),
    ]);
  }

  test_flowEnd_forParts_updaters_propertyAccess() async {
    await assertErrorsInCode(r'''
void f() {
  for (var i = 0;; (i).sign) {
    return;
  }
}
''', [
      error(HintCode.DEAD_CODE, 30, 8),
    ]);
  }

  test_flowEnd_forParts_updaters_throw() async {
    await assertErrorsInCode(r'''
void f() {
  for (;; 0, throw 1, 2) {}
}
''', [
      error(HintCode.DEAD_CODE, 33, 1),
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
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 54, 3),
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
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 20, 3),
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
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 20, 1),
      error(HintCode.DEAD_CODE, 21, 16),
    ]);
  }

  test_notUnassigned_propertyAccess() async {
    await assertNoErrorsInCode(r'''
void f(int? i) {
  (i)?.sign;
}
''');
  }

  test_potentiallyAssigned_propertyAccess() async {
    await assertNoErrorsInCode(r'''
void f(bool b) {
  int? i;
  if (b) {
    i = 1;
  }
  (i)?.sign;
}
''');
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

  test_try_finally() async {
    await assertErrorsInCode('''
main() {
  try {
    foo();
    print('dead');
  } finally {
    print('alive');
  }
  print('dead');
}
Never foo() => throw 'exception';
''', [
      error(HintCode.DEAD_CODE, 32, 14),
      error(HintCode.DEAD_CODE, 87, 14),
    ]);
  }

  test_unassigned_cascadeExpression_indexExpression() async {
    await assertErrorsInCode(r'''
void f() {
  List<int>? l;
  l?..[0]..length;
}
''', [
      error(HintCode.DEAD_CODE, 29, 15),
    ]);
  }

  test_unassigned_cascadeExpression_methodInvocation() async {
    await assertErrorsInCode(r'''
void f() {
  int? i;
  i?..toInt()..isEven;
}
''', [
      error(HintCode.DEAD_CODE, 23, 19),
    ]);
  }

  test_unassigned_cascadeExpression_propertyAccess() async {
    await assertErrorsInCode(r'''
void f() {
  int? i;
  i?..sign..isEven;
}
''', [
      error(HintCode.DEAD_CODE, 23, 16),
    ]);
  }

  test_unassigned_indexExpression() async {
    await assertErrorsInCode(r'''
void f() {
  List<int>? l;
  l?[0];
}
''', [
      error(HintCode.DEAD_CODE, 29, 5),
    ]);
  }

  test_unassigned_indexExpression_indexExpression() async {
    await assertErrorsInCode(r'''
void f() {
  List<List<int>>? l;
  l?[0][0];
}
''', [
      error(HintCode.DEAD_CODE, 35, 8),
    ]);
  }

  test_unassigned_methodInvocation() async {
    await assertErrorsInCode(r'''
void f() {
  int? i;
  i?.truncate();
}
''', [
      error(HintCode.DEAD_CODE, 23, 13),
    ]);
  }

  test_unassigned_methodInvocation_methodInvocation() async {
    await assertErrorsInCode(r'''
void f() {
  int? i;
  i?.truncate().truncate();
}
''', [
      error(HintCode.DEAD_CODE, 23, 24),
    ]);
  }

  test_unassigned_methodInvocation_propertyAccess() async {
    await assertErrorsInCode(r'''
void f() {
  int? i;
  i?.truncate().sign;
}
''', [
      error(HintCode.DEAD_CODE, 23, 18),
    ]);
  }

  test_unassigned_propertyAccess() async {
    await assertErrorsInCode(r'''
void f() {
  int? i;
  (i)?.sign;
}
''', [
      error(HintCode.DEAD_CODE, 23, 9),
    ]);
  }

  test_unassigned_propertyAccess_propertyAccess() async {
    await assertErrorsInCode(r'''
void f() {
  int? i;
  (i)?.sign.sign;
}
''', [
      error(HintCode.DEAD_CODE, 23, 14),
    ]);
  }
}

@reflectiveTest
class DeadCodeWithoutNullSafetyTest extends PubPackageResolutionTest
    with DeadCodeTestCases, WithoutNullSafetyMixin {}
