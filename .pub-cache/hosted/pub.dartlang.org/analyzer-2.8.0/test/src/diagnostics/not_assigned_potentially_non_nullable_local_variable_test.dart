// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      NotInitializedPotentiallyNonNullableLocalVariableTest,
    );
  });
}

@reflectiveTest
class NotInitializedPotentiallyNonNullableLocalVariableTest
    extends PubPackageResolutionTest {
  test_assignment_leftExpression() async {
    await assertErrorsInCode(r'''
void f() {
  List<int> v;
  v[0] = (v = [1, 2])[1];
  v;
}
''', [
      _notAssignedError(28, 1),
    ]);
  }

  test_assignment_leftLocal_compound() async {
    await assertErrorsInCode(r'''
void f() {
  int v;
  v += 1;
  v;
}
''', [
      _notAssignedError(22, 1),
    ]);
  }

  test_assignment_leftLocal_compound_assignInRight() async {
    await assertErrorsInCode(r'''
void f() {
  int v;
  v += (v = v);
}
''', [
      _notAssignedError(22, 1),
      _notAssignedError(32, 1),
    ]);
  }

  test_assignment_leftLocal_pure_eq() async {
    await assertNoErrorsInCode(r'''
void f() {
  int v;
  v = 0;
  v;
}
''');
  }

  test_assignment_leftLocal_pure_eq_self() async {
    await assertErrorsInCode(r'''
void f() {
  int v;
  v = v;
}
''', [
      _notAssignedError(26, 1),
    ]);
  }

  test_assignment_leftLocal_pure_questionEq() async {
    await assertErrorsInCode(r'''
void f() {
  int v;
  v ??= 0;
}
''', [
      _notAssignedError(22, 1),
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 28, 1),
    ]);
  }

  test_assignment_leftLocal_pure_questionEq_self() async {
    await assertErrorsInCode(r'''
void f() {
  int v;
  v ??= v;
}
''', [
      _notAssignedError(22, 1),
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 28, 1),
      _notAssignedError(28, 1),
    ]);
  }

  test_basic() async {
    await assertNoErrorsInCode('''
void f() {
  int v;
  v = 0;
  v;
}
''');
  }

  test_binaryExpression_ifNull_left() async {
    await assertErrorsInCode(r'''
void f() {
  int v;
  (v = 0) ?? 0;
  v;
}
''', [
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 33, 1),
    ]);
  }

  test_binaryExpression_ifNull_right() async {
    await assertErrorsInCode(r'''
void f(int a) {
  int v;
  a ?? (v = 0);
  v;
}
''', [
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 32, 7),
      _notAssignedError(43, 1),
    ]);
  }

  test_binaryExpression_logicalAnd_left() async {
    await assertNoErrorsInCode(r'''
void f(bool c) {
  int v;
  ((v = 0) >= 0) && c;
  v;
}
''');
  }

  test_binaryExpression_logicalAnd_right() async {
    await assertErrorsInCode(r'''
void f(bool c) {
  int v;
  c && ((v = 0) >= 0);
  v;
}
''', [
      _notAssignedError(51, 1),
    ]);
  }

  test_binaryExpression_logicalOr_left() async {
    await assertNoErrorsInCode(r'''
void f(bool c) {
  int v;
  ((v = 0) >= 0) || c;
  v;
}
''');
  }

  test_binaryExpression_logicalOr_right() async {
    await assertErrorsInCode(r'''
void f(bool c) {
  int v;
  c || ((v = 0) >= 0);
  v;
}
''', [
      _notAssignedError(51, 1),
    ]);
  }

  test_binaryExpression_plus_left() async {
    await assertNoErrorsInCode(r'''
main() {
  int v;
  (v = 0) + 1;
  v;
}
''');
  }

  test_binaryExpression_plus_right() async {
    await assertNoErrorsInCode(r'''
main() {
  int v;
  1 + (v = 0);
  v;
}
''');
  }

  test_conditional_both() async {
    await assertNoErrorsInCode(r'''
f(bool b) {
  int v;
  b ? (v = 1) : (v = 2);
  v;
}
''');
  }

  test_conditional_else() async {
    await assertErrorsInCode(r'''
f(bool b) {
  int v;
  b ? 1 : (v = 2);
  v;
}
''', [
      _notAssignedError(42, 1),
    ]);
  }

  test_conditional_then() async {
    await assertErrorsInCode(r'''
f(bool b) {
  int v;
  b ? (v = 1) : 2;
  v;
}
''', [
      _notAssignedError(42, 1),
    ]);
  }

  test_conditionalExpression_condition() async {
    await assertNoErrorsInCode(r'''
main() {
  int v;
  (v = 0) >= 0 ? 1 : 2;
  v;
}
''');
  }

  test_doWhile_break_afterAssignment() async {
    await assertNoErrorsInCode(r'''
void f(bool b) {
  int v;
  do {
    v = 0;
    v;
    if (b) break;
  } while (b);
  v;
}
''');
  }

  test_doWhile_break_beforeAssignment() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v;
  do {
    if (b) break;
    v = 0;
  } while (b);
  v;
}
''', [
      _notAssignedError(79, 1),
    ]);
  }

  test_doWhile_breakOuterFromInner() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v1, v2, v3;
  L1: do {
    do {
      v1 = 0;
      if (b) break L1;
      v2 = 0;
      v3 = 0;
    } while (b);
    v2;
  } while (b);
  v1;
  v3;
}
''', [
      _notAssignedError(168, 2),
    ]);
  }

  test_doWhile_condition() async {
    await assertErrorsInCode(r'''
void f() {
  int v1, v2;
  do {
    v1; // assigned in the condition, but not yet
  } while ((v1 = 0) + (v2 = 0) >= 0);
  v2;
}
''', [
      _notAssignedError(36, 2),
    ]);
  }

  test_doWhile_condition_break() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v;
  do {
    if (b) break;
  } while ((v = 0) >= 0);
  v;
}
''', [
      _notAssignedError(79, 1),
    ]);
  }

  test_doWhile_condition_break_continue() async {
    await assertErrorsInCode(r'''
void f(bool b1, b2) {
  int v1, v2, v3, v4, v5, v6;
  do {
    v1 = 0; // visible outside, visible to the condition
    if (b1) break;
    v2 = 0; // not visible outside, visible to the condition
    v3 = 0; // not visible outside, visible to the condition
    if (b2) continue;
    v4 = 0; // not visible
    v5 = 0; // not visible
  } while ((v6 = v1 + v2 + v4) == 0); // has break => v6 is not visible outside
  v1;
  v3;
  v5;
  v6;
}
''', [
      _notAssignedError(360, 2),
      _notAssignedError(421, 2),
      _notAssignedError(427, 2),
      _notAssignedError(433, 2),
    ]);
  }

  test_doWhile_condition_continue() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v1, v2, v3, v4;
  do {
    v1 = 0; // visible outside, visible to the condition
    if (b) continue;
    v2 = 0; // not visible
    v3 = 0; // not visible
  } while ((v4 = v1 + v2) == 0); // no break => v4 visible outside
  v1;
  v3;
  v4;
}
''', [
      _notAssignedError(200, 2),
      _notAssignedError(253, 2),
    ]);
  }

  test_doWhile_continue_beforeAssignment() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v;
  do {
    if (b) continue;
    v = 0;
  } while (b);
  v;
}
''', [
      _notAssignedError(82, 1),
    ]);
  }

  test_doWhile_true_assignInBreak() async {
    await assertNoErrorsInCode(r'''
void f(bool b) {
  int v;
  do {
    if (b) {
      v = 0;
      break;
    }
  } while (true);
  v;
}
''');
  }

  test_for_body() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v;
  for (; b;) {
    v = 0;
  }
  v;
}
''', [
      _notAssignedError(58, 1),
    ]);
  }

  test_for_break() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v1, v2;
  for (; b;) {
    v1 = 0;
    if (b) break;
    v2 = 0;
  }
  v1;
  v2;
}
''', [
      _notAssignedError(94, 2),
      _notAssignedError(100, 2),
    ]);
  }

  test_for_break_updaters() async {
    await assertNoErrorsInCode(r'''
void f(bool b) {
  int v1, v2;
  for (; b; v1 + v2) {
    v1 = 0;
    if (b) break;
    v2 = 0;
  }
}
''');
  }

  test_for_condition() async {
    await assertNoErrorsInCode(r'''
void f() {
  int v;
  for (; (v = 0) >= 0;) {
    v;
  }
  v;
}
''');
  }

  test_for_continue() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v1, v2;
  for (; b;) {
    v1 = 0;
    if (b) continue;
    v2 = 0;
  }
  v1;
  v2;
}
''', [
      _notAssignedError(97, 2),
      _notAssignedError(103, 2),
    ]);
  }

  test_for_continue_updaters() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v1, v2;
  for (; b; v1 + v2) {
    v1 = 0;
    if (b) continue;
    v2 = 0;
  }
}
''', [
      _notAssignedError(48, 2),
    ]);
  }

  test_for_initializer_expression() async {
    await assertErrorsInCode(r'''
void f() {
  int v;
  for (v = 0;;) {
    v;
  }
  v;
}
''', [
      error(HintCode.DEAD_CODE, 51, 2),
    ]);
  }

  test_for_initializer_variable() async {
    await assertErrorsInCode(r'''
void f() {
  int v;
  for (var t = (v = 0);;) {
    v;
  }
  v;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 31, 1),
      error(HintCode.DEAD_CODE, 61, 2),
    ]);
  }

  test_for_updaters() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v1, v2, v3, v4;
  for (; b; v1 = 0, v2 = 0, v3 = 0, v4) {
    v1;
  }
  v2;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 31, 2),
      _notAssignedError(75, 2),
      _notAssignedError(85, 2),
      _notAssignedError(95, 2),
    ]);
  }

  test_for_updaters_afterBody() async {
    await assertNoErrorsInCode(r'''
void f(bool b) {
  int v;
  for (; b; v) {
    v = 0;
  }
}
''');
  }

  test_forEach() async {
    await assertErrorsInCode(r'''
void f() {
  List<int> v1;
  int v2;
  for (var _ in (v1 = [0, 1, 2])) {
    v2 = 0;
  }
  v1;
  v2;
}
''', [
      _notAssignedError(97, 2),
    ]);
  }

  test_forEach_break() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v1, v2;
  for (var _ in [0, 1, 2]) {
    v1 = 0;
    if (b) break;
    v2 = 0;
  }
  v1;
  v2;
}
''', [
      _notAssignedError(108, 2),
      _notAssignedError(114, 2),
    ]);
  }

  test_forEach_continue() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v1, v2;
  for (var _ in [0, 1, 2]) {
    v1 = 0;
    if (b) continue;
    v2 = 0;
  }
  v1;
  v2;
}
''', [
      _notAssignedError(111, 2),
      _notAssignedError(117, 2),
    ]);
  }

  test_functionExpression_closure_read() async {
    await assertErrorsInCode(r'''
void f() {
  int v1, v2;

  v1 = 0;

  [0, 1, 2].forEach((t) {
    v1;
    v2;
  });
}
''', [
      _notAssignedError(75, 2),
    ]);
  }

  test_functionExpression_closure_write() async {
    await assertErrorsInCode(r'''
void f() {
  int v;

  [0, 1, 2].forEach((t) {
    v = t;
  });

  v;
}
''', [
      _notAssignedError(67, 1),
    ]);
  }

  test_functionExpression_localFunction_local() async {
    await assertErrorsInCode(r'''
void f() {
  int v;

  v = 0;

  void f() {
    int v; // 1
    v;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(HintCode.UNUSED_ELEMENT, 38, 1),
      _notAssignedError(64, 1),
    ]);
  }

  test_functionExpression_localFunction_local2() async {
    await assertErrorsInCode(r'''
void f() {
  int v1;

  v1 = 0;

  void f() {
    int v2, v3;
    v2 = 0;
    v1;
    v2;
    v3;
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 40, 1),
      _notAssignedError(94, 2),
    ]);
  }

  test_functionExpression_localFunction_read() async {
    await assertErrorsInCode(r'''
void f() {
  int v1, v2;

  v1 = 0;

  void f() {
    v1;
    v2;
  }

  v2 = 0;
}
''', [
      error(HintCode.UNUSED_ELEMENT, 44, 1),
      _notAssignedError(62, 2),
    ]);
  }

  test_functionExpression_localFunction_write() async {
    await assertErrorsInCode(r'''
void f() {
  int v;

  void f() {
    v = 0;
  }

  v;
}
''', [
      error(HintCode.UNUSED_ELEMENT, 28, 1),
      _notAssignedError(52, 1),
    ]);
  }

  test_futureOr_questionArgument_none() async {
    await assertErrorsInCode('''
import 'dart:async';

f() {
  FutureOr<int?> v;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 45, 1),
    ]);
  }

  test_hasInitializer() async {
    await assertNoErrorsInCode('''
f() {
  int v = 0;
  v;
}
''');
  }

  test_if_condition() async {
    await assertNoErrorsInCode(r'''
main() {
  int v;
  if ((v = 0) >= 0) {
    v;
  } else {
    v;
  }
  v;
}
''');
  }

  test_if_condition_false() async {
    await assertErrorsInCode(r'''
void f() {
  int v;
  if (false) {
    // not assigned
  } else {
    v = 0;
  }
  v;
}
''', [
      error(HintCode.DEAD_CODE, 33, 25),
    ]);
  }

  test_if_condition_logicalAnd() async {
    await assertErrorsInCode(r'''
void f(bool b, int i) {
  int v;
  if (b && (v = i) > 0) {
    v;
  } else {
    v;
  }
  v;
}
''', [
      _notAssignedError(81, 1),
      _notAssignedError(90, 1),
    ]);
  }

  test_if_condition_logicalOr() async {
    await assertErrorsInCode(r'''
void f(bool b, int i) {
  int v;
  if (b || (v = i) > 0) {
    v;
  } else {
    v;
  }
  v;
}
''', [
      _notAssignedError(63, 1),
      _notAssignedError(90, 1),
    ]);
  }

  test_if_condition_notFalse() async {
    await assertNoErrorsInCode(r'''
void f() {
  int v;
  if (!false) {
    v = 0;
  }
  v;
}
''');
  }

  test_if_condition_notTrue() async {
    await assertErrorsInCode(r'''
void f() {
  int v;
  if (!true) {
    // not assigned
  } else {
    v = 0;
  }
  v;
}
''', [
      error(HintCode.DEAD_CODE, 33, 25),
    ]);
  }

  test_if_condition_true() async {
    await assertNoErrorsInCode(r'''
void f() {
  int v;
  if (true) {
    v = 0;
  }
  v;
}
''');
  }

  test_if_then() async {
    await assertErrorsInCode(r'''
void f(bool c) {
  int v;
  if (c) {
    v = 0;
  }
  v;
}
''', [
      _notAssignedError(54, 1),
    ]);
  }

  test_if_thenElse_all() async {
    await assertNoErrorsInCode(r'''
void f(bool c) {
  int v;
  if (c) {
    v = 0;
    v;
  } else {
    v = 0;
    v;
  }
  v;
}
''');
  }

  test_if_thenElse_else() async {
    await assertErrorsInCode(r'''
void f(bool c) {
  int v;
  if (c) {
    // not assigned
  } else {
    v = 0;
  }
  v;
}
''', [
      _notAssignedError(85, 1),
    ]);
  }

  test_if_thenElse_then() async {
    await assertErrorsInCode(r'''
void f(bool c) {
  int v;
  if (c) {
    v = 0;
  } else {
    // not assigned
  }
  v;
}
''', [
      _notAssignedError(85, 1),
    ]);
  }

  test_late() async {
    await assertNoErrorsInCode('''
f() {
  late int v;

  void g() {
    v = 0;
  }

  g();
  v;
}
''');
  }

  test_noInitializer() async {
    await assertErrorsInCode('''
f() {
  int v;
  v;
}
''', [
      _notAssignedError(17, 1),
    ]);
  }

  test_noInitializer_typeParameter() async {
    await assertErrorsInCode('''
f<T>() {
  T v;
  v;
}
''', [
      _notAssignedError(18, 1),
    ]);
  }

  test_notUsed() async {
    await assertErrorsInCode('''
void f() {
  int v;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
    ]);
  }

  test_nullable() async {
    await assertNoErrorsInCode('''
f() {
  int? v;
  v;
}
''');
  }

  test_switch_case1_default() async {
    await assertErrorsInCode(r'''
void f(int e) {
  int v;
  switch (e) {
    case 1:
      v = 0;
      break;
    case 2:
      // not assigned
      break;
    default:
      v = 0;
  }
  v;
}
''', [
      _notAssignedError(157, 1),
    ]);
  }

  test_switch_case2_default() async {
    await assertErrorsInCode(r'''
void f(int e) {
  int v1, v2;
  switch (e) {
    case 1:
      v1 = 0;
      v2 = 0;
      v1;
      break;
    default:
      v1 = 0;
      v1;
  }
  v1;
  v2;
}
''', [
      _notAssignedError(157, 2),
    ]);
  }

  test_switch_case_default_break() async {
    await assertErrorsInCode(r'''
void f(bool b, int e) {
  int v1, v2;
  switch (e) {
    case 1:
      v1 = 0;
      if (b) break;
      v2 = 0;
      break;
    default:
      v1 = 0;
      if (b) break;
      v2 = 0;
  }
  v1;
  v2;
}
''', [
      _notAssignedError(199, 2),
    ]);
  }

  test_switch_case_default_continue() async {
    // We don't analyze to which `case` we go from `continue L`,
    // but we don't have to. If all cases assign, then the variable is
    // removed from the unassigned set in the `breakState`. And if there is a
    // case when it is not assigned, then the variable will be left unassigned
    // in the `breakState`.
    await assertNoErrorsInCode(r'''
void f(int e) {
  int v;
  switch (e) {
    L: case 1:
      v = 0;
      break;
    case 2:
      continue L;
    default:
      v = 0;
  }
  v;
}
''');
  }

  test_switch_case_noDefault() async {
    await assertErrorsInCode(r'''
void f(int e) {
  int v;
  switch (e) {
    case 1:
      v = 0;
      break;
  }
  v;
}
''', [
      _notAssignedError(84, 1),
    ]);
  }

  test_switch_expression() async {
    await assertNoErrorsInCode(r'''
void f() {
  int v;
  switch (v = 0) {}
  v;
}
''');
  }

  test_tryCatch_body() async {
    await assertErrorsInCode(r'''
void f() {
  int v;
  try {
    v = 0;
  } catch (_) {
    // not assigned
  }
  v;
}
''', [
      _notAssignedError(81, 1),
    ]);
  }

  test_tryCatch_body_catch() async {
    await assertNoErrorsInCode(r'''
void f() {
  int v;
  try {
    g();
    v = 0;
  } catch (_) {
    v = 0;
  }
  v;
}

void g() {}
''');
  }

  test_tryCatch_body_catchRethrow() async {
    await assertNoErrorsInCode(r'''
void f() {
  int v;
  try {
    v = 0;
  } catch (_) {
    rethrow;
  }
  v;
}
''');
  }

  test_tryCatch_catch() async {
    await assertErrorsInCode(r'''
void f() {
  int v;
  try {
    // not assigned
  } catch (_) {
    v = 0;
  }
  v;
}
''', [
      _notAssignedError(81, 1),
    ]);
  }

  test_tryCatchFinally_body() async {
    await assertErrorsInCode(r'''
void f() {
  int v;
  try {
    v = 0;
  } catch (_) {
    // not assigned
  } finally {
    // not assigned
  }
  v;
}
''', [
      _notAssignedError(115, 1),
    ]);
  }

  test_tryCatchFinally_catch() async {
    await assertErrorsInCode(r'''
void f() {
  int v;
  try {
    // not assigned
  } catch (_) {
    v = 0;
  } finally {
    // not assigned
  }
  v;
}
''', [
      _notAssignedError(115, 1),
    ]);
  }

  test_tryCatchFinally_finally() async {
    await assertNoErrorsInCode(r'''
void f() {
  int v;
  try {
    // not assigned
  } catch (_) {
    // not assigned
  } finally {
    v = 0;
  }
  v;
}
''');
  }

  test_tryCatchFinally_useInFinally() async {
    await assertErrorsInCode(r'''
f() {
  int x;
  try {
    g(); // may throw an exception
    x = 1;
  } catch (_) {
    x = 1;
  } finally {
    x; // BAD
  }
}

void g() {}
''', [
      _notAssignedError(114, 1),
    ]);
  }

  test_tryFinally_body() async {
    await assertNoErrorsInCode(r'''
void f() {
  int v;
  try {
    v = 0;
  } finally {
    // not assigned
  }
  v;
}
''');
  }

  test_tryFinally_finally() async {
    await assertNoErrorsInCode(r'''
void f() {
  int v;
  try {
    // not assigned
  } finally {
    v = 0;
  }
  v;
}
''');
  }

  test_type_dynamic() async {
    await assertErrorsInCode('''
f() {
  dynamic v;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 16, 1),
    ]);
  }

  test_type_dynamicImplicit() async {
    await assertErrorsInCode('''
f() {
  var v;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
    ]);
  }

  test_type_void() async {
    await assertErrorsInCode('''
f() {
  void v;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
    ]);
  }

  test_while_condition() async {
    await assertNoErrorsInCode(r'''
void f() {
  int v;
  while ((v = 0) >= 0) {
    v;
  }
  v;
}
''');
  }

  test_while_condition_notTrue() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v;
  while (b) {
    v = 0;
    v;
  }
  v;
}
''', [
      _notAssignedError(64, 1),
    ]);
  }

  test_while_true_break_afterAssignment() async {
    await assertNoErrorsInCode(r'''
void f(bool b) {
  int v1, v2;
  while (true) {
    v1 = 0;
    v1;
    if (b) break;
    v2 = 0;
    v1;
    v2;
  }
  v1;
}
''');
  }

  test_while_true_break_beforeAssignment() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v;
  while (true) {
    if (b) break;
    v = 0;
    v;
  }
  v;
}
''', [
      _notAssignedError(85, 1),
    ]);
  }

  test_while_true_break_if() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v;
  while (true) {
    if (b) {
      v = 0;
      break;
    } else {
      v = 0;
      break;
    }
    v;
  }
  v;
}
''', [
      error(HintCode.DEAD_CODE, 131, 2),
    ]);
  }

  test_while_true_break_if2() async {
    await assertNoErrorsInCode(r'''
void f(bool b) {
  var v;
  while (true) {
    if (b) {
      break;
    } else {
      v = 0;
    }
    v;
  }
}
''');
  }

  test_while_true_break_if3() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v1, v2;
  while (true) {
    if (b) {
      v1 = 0;
      v2 = 0;
      if (b) break;
    } else {
      if (b) break;
      v1 = 0;
      v2 = 0;
    }
    v1;
  }
  v2;
}
''', [
      _notAssignedError(190, 2),
    ]);
  }

  test_while_true_breakOuterFromInner() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v1, v2, v3;
  L1: while (true) {
    L2: while (true) {
      v1 = 0;
      if (b) break L1;
      v2 = 0;
      v3 = 0;
      if (b) break L2;
    }
    v2;
  }
  v1;
  v3;
}
''', [
      _notAssignedError(193, 2),
    ]);
  }

  test_while_true_continue() async {
    await assertErrorsInCode(r'''
void f(bool b) {
  int v;
  while (true) {
    if (b) continue;
    v = 0;
  }
  v;
}
''', [
      error(HintCode.DEAD_CODE, 81, 2),
      error(
          CompileTimeErrorCode
              .NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE,
          81,
          1),
    ]);
  }

  test_while_true_noBreak() async {
    await assertErrorsInCode(r'''
void f() {
  int v;
  while (true) {
    // No assignment, but no break.
    // So, we don't exit the loop.
  }
  v;
}
''', [
      error(HintCode.DEAD_CODE, 114, 2),
      error(
          CompileTimeErrorCode
              .NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE,
          114,
          1),
    ]);
  }

  ExpectedError _notAssignedError(int offset, int length) {
    return error(
        CompileTimeErrorCode
            .NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE,
        offset,
        length);
  }
}
