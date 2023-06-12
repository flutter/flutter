// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/resolver/exit_detector.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../ast/parse_base.dart';
import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExitDetectorParsedStatementTest);
    defineReflectiveTests(ExitDetectorResolvedStatementTest);
    defineReflectiveTests(ExitDetectorForCodeAsUiTest);
  });
}

/// Tests for the [ExitDetector] that require that the control flow and spread
/// experiments be enabled.
@reflectiveTest
class ExitDetectorForCodeAsUiTest extends ParseBase {
  test_for_condition() async {
    _assertTrue('[for (; throw 0;) 0]');
  }

  test_for_implicitTrue() async {
    _assertTrue('[for (;;) 0]');
  }

  test_for_initialization() async {
    _assertTrue('[for (i = throw 0;;) 0]');
  }

  test_for_true() async {
    _assertTrue('[for (; true; ) 0]');
  }

  test_for_true_if_return() async {
    _assertTrue('[for (; true; ) if (true) throw 42]');
  }

  test_for_true_noBreak() async {
    _assertTrue('[for (; true; ) 0]');
  }

  test_for_updaters() async {
    _assertTrue('[for (;; i++, throw 0) 1]');
  }

  test_for_variableDeclaration() async {
    _assertTrue('[for (int i = throw 0;;) 1]');
  }

  test_forEach() async {
    _assertFalse('[for (element in list) 0]');
  }

  test_forEach_throw() async {
    _assertTrue('[for (element in throw 42) 0]');
  }

  test_if_false_else_throw() async {
    _assertTrue('[if (false) 0 else throw 42]');
  }

  test_if_false_noThrow() async {
    _assertFalse('[if (false) 0]');
  }

  test_if_false_throw() async {
    _assertFalse('[if (false) throw 42]');
  }

  test_if_noThrow() async {
    _assertFalse('[if (c) i++]');
  }

  test_if_throw() async {
    _assertFalse('[if (c) throw 42]');
  }

  test_if_true_noThrow() async {
    _assertFalse('[if (true) 0]');
  }

  test_if_true_throw() async {
    _assertTrue('[if (true) throw 42]');
  }

  test_ifElse_bothThrow() async {
    _assertTrue("[if (c) throw 0 else throw 1]");
  }

  test_ifElse_elseThrow() async {
    _assertFalse('[if (c) 0 else throw 42]');
  }

  test_ifElse_noThrow() async {
    _assertFalse('[if (c) 0 else 1]');
  }

  test_ifElse_thenThrow() async {
    _assertFalse('[if (c) throw 42 else 0]');
  }

  void _assertFalse(String expressionCode) {
    _assertHasReturn(expressionCode, false);
  }

  void _assertHasReturn(String expressionCode, bool expected) {
    var path = convertPath('/test/lib/test.dart');

    newFile(path, '''
void f() { // ref
  $expressionCode;
}
''');

    var parseResult = parseUnit(path);
    expect(parseResult.errors, isEmpty);

    var findNode = FindNode(parseResult.content, parseResult.unit);

    var block = findNode.block('{ // ref');
    var statement = block.statements.single as ExpressionStatement;
    var expression = statement.expression;

    var actual = ExitDetector.exits(expression);
    expect(actual, expected);
  }

  void _assertTrue(String expressionCode) {
    _assertHasReturn(expressionCode, true);
  }
}

/// Tests for the [ExitDetector] that do not require that the AST be resolved.
///
/// See [ExitDetectorResolvedStatementTest] for tests that require the AST to be resolved.
@reflectiveTest
class ExitDetectorParsedStatementTest extends ParseBase {
  test_asExpression() async {
    _assertFalse('a as Object;');
  }

  test_asExpression_throw() async {
    _assertTrue('throw 42 as Object;');
  }

  test_assertStatement() async {
    _assertFalse("assert(a);");
  }

  test_assertStatement_throw() async {
    _assertFalse('assert((throw 0));');
  }

  test_assignmentExpression() async {
    _assertFalse('v = 1;');
  }

  @failingTest
  test_assignmentExpression_compound_lazy() async {
    _assertFalse('v ||= false;');
  }

  test_assignmentExpression_lhs_throw() async {
    _assertTrue('a[throw 42] = 0;');
  }

  test_assignmentExpression_rhs_throw() async {
    _assertTrue('v = throw 42;');
  }

  test_await_false() async {
    _assertFalse('await x;');
  }

  test_await_throw_true() async {
    _assertTrue('bool b = await (throw 42 || true);');
  }

  test_binaryExpression_and() async {
    _assertFalse('a && b;');
  }

  test_binaryExpression_and_lhs() async {
    _assertTrue('throw 42 && b;');
  }

  test_binaryExpression_and_rhs() async {
    _assertFalse('a && (throw 42);');
  }

  test_binaryExpression_and_rhs2() async {
    _assertFalse('false && (throw 42);');
  }

  test_binaryExpression_and_rhs3() async {
    _assertTrue('true && (throw 42);');
  }

  test_binaryExpression_ifNull() async {
    _assertFalse('a ?? b;');
  }

  test_binaryExpression_ifNull_lhs() async {
    _assertTrue('throw 42 ?? b;');
  }

  test_binaryExpression_ifNull_rhs() async {
    _assertFalse('a ?? (throw 42);');
  }

  test_binaryExpression_ifNull_rhs2() async {
    _assertFalse('null ?? (throw 42);');
  }

  test_binaryExpression_or() async {
    _assertFalse('a || b;');
  }

  test_binaryExpression_or_lhs() async {
    _assertTrue('throw 42 || b;');
  }

  test_binaryExpression_or_rhs() async {
    _assertFalse('a || (throw 42);');
  }

  test_binaryExpression_or_rhs2() async {
    _assertFalse('true || (throw 42);');
  }

  test_binaryExpression_or_rhs3() async {
    _assertTrue('false || (throw 42);');
  }

  test_block_empty() async {
    _assertFalse('{}');
  }

  test_block_noReturn() async {
    _assertFalse('{ int i = 0; }');
  }

  test_block_return() async {
    _assertTrue('{ return 0; }');
  }

  test_block_returnNotLast() async {
    _assertTrue('{ return 0; throw 42; }');
  }

  test_block_throwNotLast() async {
    _assertTrue('{ throw 0; x = null; }');
  }

  test_cascadeExpression_argument() async {
    _assertTrue('a..b(throw 42);');
  }

  test_cascadeExpression_index() async {
    _assertTrue('a..[throw 42];');
  }

  test_cascadeExpression_target() async {
    _assertTrue('throw a..b();');
  }

  test_conditional_ifElse_bothThrows() async {
    _assertTrue('c ? throw 42 : throw 42;');
  }

  test_conditional_ifElse_elseThrows() async {
    _assertFalse('c ? i : throw 42;');
  }

  test_conditional_ifElse_noThrow() async {
    _assertFalse('c ? i : j;');
  }

  test_conditional_ifElse_thenThrow() async {
    _assertFalse('c ? throw 42 : j;');
  }

  test_conditionalAccess() async {
    _assertFalse('a?.b;');
  }

  test_conditionalAccess_lhs() async {
    _assertTrue('(throw 42)?.b;');
  }

  test_conditionalAccessAssign() async {
    _assertFalse('a?.b = c;');
  }

  test_conditionalAccessAssign_lhs() async {
    _assertTrue('(throw 42)?.b = c;');
  }

  test_conditionalAccessAssign_rhs() async {
    _assertFalse('a?.b = throw 42;');
  }

  test_conditionalAccessAssign_rhs2() async {
    _assertFalse("null?.b = throw 42;");
  }

  test_conditionalAccessIfNullAssign() async {
    _assertFalse('a?.b ??= c;');
  }

  test_conditionalAccessIfNullAssign_lhs() async {
    _assertTrue('(throw 42)?.b ??= c;');
  }

  test_conditionalAccessIfNullAssign_rhs() async {
    _assertFalse('a?.b ??= throw 42;');
  }

  test_conditionalAccessIfNullAssign_rhs2() async {
    _assertFalse('null?.b ??= throw 42;');
  }

  test_conditionalCall() async {
    _assertFalse('a?.b(c);');
  }

  test_conditionalCall_lhs() async {
    _assertTrue('(throw 42)?.b(c);');
  }

  test_conditionalCall_rhs() async {
    _assertFalse('a?.b(throw 42);');
  }

  test_conditionalCall_rhs2() async {
    _assertFalse('null?.b(throw 42);');
  }

  test_doStatement_break_and_throw() async {
    _assertFalse('''
{
  do {
    if (1 == 1) break;
    throw 42;
  } while (0 == 1);
}
''');
  }

  test_doStatement_continue_and_throw() async {
    _assertFalse('''
{
  do {
    if (1 == 1) continue;
    throw 42;
  } while (0 == 1);
}
''');
  }

  test_doStatement_continueDoInSwitch_and_throw() async {
    _assertFalse('''
{
  D: do {
    switch (1) {
      L: case 0: continue D;
      M: case 1: break;
    }
    throw 42;
  } while (0 == 1);
}''');
  }

  test_doStatement_continueInSwitch_and_throw() async {
    _assertFalse('''
{
  do {
    switch (1) {
      L: case 0: continue;
      M: case 1: break;
    }
    throw 42;
  } while (0 == 1);
}''');
  }

  test_doStatement_return() async {
    _assertTrue('{ do { return null; } while (1 == 2); }');
  }

  test_doStatement_throwCondition() async {
    _assertTrue('{ do {} while (throw 42); }');
  }

  test_doStatement_true_break() async {
    _assertFalse('{ do { break; } while (true); }');
  }

  test_doStatement_true_continue() async {
    _assertTrue('{ do { continue; } while (true); }');
  }

  test_doStatement_true_continueWithLabel() async {
    _assertTrue('{ x: do { continue x; } while (true); }');
  }

  test_doStatement_true_if_return() async {
    _assertTrue('{ do { if (true) {return null;} } while (true); }');
  }

  test_doStatement_true_noBreak() async {
    _assertTrue('{ do {} while (true); }');
  }

  test_doStatement_true_return() async {
    _assertTrue('{ do { return null; } while (true);  }');
  }

  test_emptyStatement() async {
    _assertFalse(';');
  }

  test_forEachStatement() async {
    _assertFalse('for (element in list) {}');
  }

  test_forEachStatement_throw() async {
    _assertTrue('for (element in throw 42) {}');
  }

  test_forStatement_condition() async {
    _assertTrue('for (; throw 0;) {}');
  }

  test_forStatement_implicitTrue() async {
    _assertTrue('for (;;) {}');
  }

  test_forStatement_implicitTrue_break() async {
    _assertFalse('for (;;) { break; }');
  }

  test_forStatement_implicitTrue_if_break() async {
    _assertFalse('''
{
  for (;;) {
    if (1==2) {
      var a = 1;
    } else {
      break;
    }
  }
}
''');
  }

  test_forStatement_initialization() async {
    _assertTrue('for (i = throw 0;;) {}');
  }

  test_forStatement_true() async {
    _assertTrue('for (; true; ) {}');
  }

  test_forStatement_true_break() async {
    _assertFalse('{ for (; true; ) { break; } }');
  }

  test_forStatement_true_continue() async {
    _assertTrue('{ for (; true; ) { continue; } }');
  }

  test_forStatement_true_if_return() async {
    _assertTrue('{ for (; true; ) { if (true) {return null;} } }');
  }

  test_forStatement_true_noBreak() async {
    _assertTrue('{ for (; true; ) {} }');
  }

  test_forStatement_updaters() async {
    _assertTrue('for (;; i++, throw 0) {}');
  }

  test_forStatement_variableDeclaration() async {
    _assertTrue('for (int i = throw 0;;) {}');
  }

  test_functionExpression() async {
    _assertFalse('(){};');
  }

  test_functionExpression_bodyThrows() async {
    _assertFalse('(int i) => throw 42;');
  }

  test_functionExpressionInvocation() async {
    _assertFalse('f(g);');
  }

  test_functionExpressionInvocation_argumentThrows() async {
    _assertTrue('f(throw 42);');
  }

  test_functionExpressionInvocation_targetThrows() async {
    _assertTrue("(throw 42)(g);");
  }

  test_functionReference() async {
    _assertFalse('a<int>;');
  }

  test_functionReference_method() async {
    _assertFalse('(a).m<int>;');
  }

  test_functionReference_method_throw() async {
    _assertTrue('(throw 42).m<int>;');
  }

  test_identifier_prefixedIdentifier() async {
    _assertFalse('a.b;');
  }

  test_identifier_simpleIdentifier() async {
    _assertFalse('a;');
  }

  test_if_false_else_return() async {
    _assertTrue('if (false) {} else { return 0; }');
  }

  test_if_false_noReturn() async {
    _assertFalse('if (false) {}');
  }

  test_if_false_return() async {
    _assertFalse('if (false) { return 0; }');
  }

  test_if_noReturn() async {
    _assertFalse('if (c) i++;');
  }

  test_if_return() async {
    _assertFalse('if (c) return 0;');
  }

  test_if_true_noReturn() async {
    _assertFalse('if (true) {}');
  }

  test_if_true_return() async {
    _assertTrue('if (true) { return 0; }');
  }

  test_ifElse_bothReturn() async {
    _assertTrue('if (c) return 0; else return 1;');
  }

  test_ifElse_elseReturn() async {
    _assertFalse('if (c) i++; else return 1;');
  }

  test_ifElse_noReturn() async {
    _assertFalse('if (c) i++; else j++;');
  }

  test_ifElse_thenReturn() async {
    _assertFalse('if (c) return 0; else j++;');
  }

  test_ifNullAssign() async {
    _assertFalse('a ??= b;');
  }

  test_ifNullAssign_rhs() async {
    _assertFalse('a ??= throw 42;');
  }

  test_indexExpression() async {
    _assertFalse('a[b];');
  }

  test_indexExpression_index() async {
    _assertTrue('a[throw 42];');
  }

  test_indexExpression_target() async {
    _assertTrue("(throw 42)[b];");
  }

  test_instanceCreationExpression() async {
    _assertFalse('new A(b);');
  }

  test_instanceCreationExpression_argumentThrows() async {
    _assertTrue('new A(throw 42);');
  }

  test_isExpression() async {
    _assertFalse('A is B;');
  }

  test_isExpression_throws() async {
    _assertTrue('throw 42 is B;');
  }

  test_labeledStatement() async {
    _assertFalse('label: a;');
  }

  test_labeledStatement_throws() async {
    _assertTrue('label: throw 42;');
  }

  test_literal_boolean() async {
    _assertFalse('true;');
  }

  test_literal_double() async {
    _assertFalse('1.1;');
  }

  test_literal_integer() async {
    _assertFalse('1;');
  }

  test_literal_null() async {
    _assertFalse('null;');
  }

  test_literal_String() async {
    _assertFalse('"str";');
  }

  test_methodInvocation() async {
    _assertFalse('a.b(c);');
  }

  test_methodInvocation_argument() async {
    _assertTrue('a.b(throw 42);');
  }

  test_methodInvocation_target() async {
    _assertTrue("(throw 42).b(c);");
  }

  test_parenthesizedExpression() async {
    _assertFalse('(a);');
  }

  test_parenthesizedExpression_throw() async {
    _assertTrue('(throw 42);');
  }

  test_propertyAccess() async {
    _assertFalse('new Object().a;');
  }

  test_propertyAccess_throws() async {
    _assertTrue('(throw 42).a;');
  }

  test_rethrow() async {
    _assertTrue('rethrow;');
  }

  test_return() async {
    _assertTrue('return 0;');
  }

  test_superExpression() async {
    _assertFalse('super.a;');
  }

  test_switch_allReturn() async {
    _assertTrue('switch (i) { case 0: return 0; default: return 1; }');
  }

  test_switch_defaultWithNoStatements() async {
    _assertFalse('switch (i) { case 0: return 0; default: }');
  }

  test_switch_fallThroughToNotReturn() async {
    _assertFalse(r'''
switch (i) {
  case 0:
  case 1:
    break;
  default:
    return 1;
}
''');
  }

  test_switch_fallThroughToReturn() async {
    _assertTrue(r'''
switch (i) {
  case 0:
  case 1:
    return 0;
  default:
    return 1;
}
''');
  }

  @failingTest
  test_switch_includesContinue() async {
    _assertTrue('''
switch (i) {
  zero: case 0: return 0;
  case 1: continue zero;
  default: return 1;
}''');
  }

  test_switch_noDefault() async {
    _assertFalse('switch (i) { case 0: return 0; }');
  }

  // The ExitDetector could conceivably follow switch continue labels and
  // determine that `case 0` exits, `case 1` continues to an exiting case, and
  // `default` exits, so the switch exits.
  test_switch_nonReturn() async {
    _assertFalse('switch (i) { case 0: i++; default: return 1; }');
  }

  test_thisExpression() async {
    _assertFalse('this.a;');
  }

  test_throwExpression() async {
    _assertTrue('throw new Object();');
  }

  test_tryStatement_noReturn() async {
    _assertFalse('try {} catch (e, s) {} finally {}');
  }

  test_tryStatement_noReturn_noFinally() async {
    _assertFalse('try {} catch (e, s) {}');
  }

  test_tryStatement_return_catch() async {
    _assertFalse('try {} catch (e, s) { return 1; } finally {}');
  }

  test_tryStatement_return_catch_noFinally() async {
    _assertFalse('try {} catch (e, s) { return 1; }');
  }

  test_tryStatement_return_finally() async {
    _assertTrue('try {} catch (e, s) {} finally { return 1; }');
  }

  test_tryStatement_return_try_noCatch() async {
    _assertTrue('try { return 1; } finally {}');
  }

  test_tryStatement_return_try_oneCatchDoesNotExit() async {
    _assertFalse('try { return 1; } catch (e, s) {} finally {}');
  }

  test_tryStatement_return_try_oneCatchDoesNotExit_noFinally() async {
    _assertFalse('try { return 1; } catch (e, s) {}');
  }

  test_tryStatement_return_try_oneCatchExits() async {
    _assertTrue('''
try {
  return 1;
} catch (e, s) {
  return 1;
} finally {}
''');
  }

  test_tryStatement_return_try_oneCatchExits_noFinally() async {
    _assertTrue('try { return 1; } catch (e, s) { return 1; }');
  }

  test_tryStatement_return_try_twoCatchesDoExit() async {
    _assertTrue('''
try { return 1; }
on int catch (e, s) { return 1; }
on String catch (e, s) { return 1; }
finally {}
''');
  }

  test_tryStatement_return_try_twoCatchesDoExit_noFinally() async {
    _assertTrue('''
try { return 1; }
on int catch (e, s) { return 1; }
on String catch (e, s) { return 1; }
''');
  }

  test_tryStatement_return_try_twoCatchesDoNotExit() async {
    _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) {}
finally {}
''');
  }

  test_tryStatement_return_try_twoCatchesDoNotExit_noFinally() async {
    _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) {}
''');
  }

  test_tryStatement_return_try_twoCatchesMixed() async {
    _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) { return 1; }
finally {}
''');
  }

  test_tryStatement_return_try_twoCatchesMixed_noFinally() async {
    _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) { return 1; }
''');
  }

  test_variableDeclarationStatement_noInitializer() async {
    _assertFalse('int i;');
  }

  test_variableDeclarationStatement_noThrow() async {
    _assertFalse('int i = 0;');
  }

  test_variableDeclarationStatement_throw() async {
    _assertTrue('int i = throw new Object();');
  }

  test_whileStatement_false_nonReturn() async {
    _assertFalse("{ while (false) {} }");
  }

  test_whileStatement_throwCondition() async {
    _assertTrue('{ while (throw 42) {} }');
  }

  test_whileStatement_true_break() async {
    _assertFalse('{ while (true) { break; } }');
  }

  test_whileStatement_true_break_and_throw() async {
    _assertFalse('{ while (true) { if (1==1) break; throw 42; } }');
  }

  test_whileStatement_true_continue() async {
    _assertTrue('{ while (true) { continue; } }');
  }

  test_whileStatement_true_continueWithLabel() async {
    _assertTrue('{ x: while (true) { continue x; } }');
  }

  test_whileStatement_true_doStatement_scopeRequired() async {
    _assertTrue('{ while (true) { x: do { continue x; } while (true); } }');
  }

  test_whileStatement_true_if_return() async {
    _assertTrue('{ while (true) { if (true) {return null;} } }');
  }

  test_whileStatement_true_noBreak() async {
    _assertTrue('{ while (true) {} }');
  }

  test_whileStatement_true_return() async {
    _assertTrue('{ while (true) { return null; } }');
  }

  test_whileStatement_true_throw() async {
    _assertTrue('{ while (true) { throw 42; } }');
  }

  void _assertFalse(String code) {
    _assertHasReturn(code, false);
  }

  void _assertHasReturn(String statementCode, bool expected) {
    var path = convertPath('/test/lib/test.dart');

    newFile(path, '''
void f() { // ref
  $statementCode
}
''');

    var parseResult = parseUnit(path);
    expect(parseResult.errors, isEmpty);

    var findNode = FindNode(parseResult.content, parseResult.unit);

    var block = findNode.block('{ // ref');
    var statement = block.statements.single;

    var actual = ExitDetector.exits(statement);
    expect(actual, expected);
  }

  void _assertTrue(String code) {
    _assertHasReturn(code, true);
  }
}

/// Tests for the [ExitDetector] that require that the AST be resolved.
///
/// See [ExitDetectorParsedStatementTest] for tests that do not require the AST to be resolved.
/// TODO(paulberry): migrate this test away from the task model.
/// See dartbug.com/35734.
@reflectiveTest
class ExitDetectorResolvedStatementTest extends PubPackageResolutionTest {
  test_forStatement_implicitTrue_breakWithLabel() async {
    await _assertNthStatementDoesNotExit(r'''
void f() {
  x: for (;;) {
    if (1 < 2) {
      break x;
    }
    return;
  }
}
''', 0);
  }

  test_switch_withEnum_false_noDefault() async {
    await _assertNthStatementDoesNotExit(r'''
enum E { A, B }
String f(E e) {
  var x;
  switch (e) {
    case A:
      x = 'A';
    case B:
      x = 'B';
  }
  return x;
}
''', 1);
  }

  test_switch_withEnum_false_withDefault() async {
    await _assertNthStatementDoesNotExit(r'''
enum E { A, B }
String f(E e) {
  var x;
  switch (e) {
    case A:
      x = 'A';
    default:
      x = '?';
  }
  return x;
}
''', 1);
  }

  test_switch_withEnum_true_noDefault() async {
    await _assertNthStatementDoesNotExit(r'''
enum E { A, B }
String f(E e) {
  switch (e) {
    case A:
      return 'A';
    case B:
      return 'B';
  }
}
''', 0);
  }

  test_switch_withEnum_true_withExitingDefault() async {
    await _assertNthStatementExits(r'''
enum E { A, B }
String f(E e) {
  switch (e) {
    case A:
      return 'A';
    default:
      return '?';
  }
}
''', 0);
  }

  test_switch_withEnum_true_withNonExitingDefault() async {
    await _assertNthStatementDoesNotExit(r'''
enum E { A, B }
String f(E e) {
  var x;
  switch (e) {
    case A:
      return 'A';
    default:
      x = '?';
  }
}
''', 1);
  }

  test_whileStatement_breakWithLabel() async {
    await _assertNthStatementDoesNotExit(r'''
void f() {
  x: while (true) {
    if (1 < 2) {
      break x;
    }
    return;
  }
}
''', 0);
  }

  test_whileStatement_breakWithLabel_afterExiting() async {
    await _assertNthStatementExits(r'''
void f() {
  x: while (true) {
    return;
    if (1 < 2) {
      break x;
    }
  }
}
''', 0);
  }

  test_whileStatement_switchWithBreakWithLabel() async {
    await _assertNthStatementDoesNotExit(r'''
void f() {
  x: while (true) {
    switch (true) {
      case false: break;
      case true: break x;
    }
  }
}
''', 0);
  }

  test_yieldStatement_plain() async {
    await _assertNthStatementDoesNotExit(r'''
void f() sync* {
  yield 1;
}
''', 0);
  }

  test_yieldStatement_star_plain() async {
    await _assertNthStatementDoesNotExit(r'''
void f() sync* {
  yield* 1;
}
''', 0);
  }

  test_yieldStatement_star_throw() async {
    await _assertNthStatementExits(r'''
void f() sync* {
  yield* throw '';
}
''', 0);
  }

  test_yieldStatement_throw() async {
    await _assertNthStatementExits(r'''
void f() sync* {
  yield throw '';
}
''', 0);
  }

  Future<void> _assertHasReturn(String code, int n, bool expected) async {
    await resolveTestCode(code);

    var function = result.unit.declarations.last as FunctionDeclaration;
    var body = function.functionExpression.body as BlockFunctionBody;
    Statement statement = body.block.statements[n];
    expect(ExitDetector.exits(statement), expected);
  }

  /// Assert that the [n]th statement in the last function declaration of
  /// [code] exits.
  Future<void> _assertNthStatementDoesNotExit(String code, int n) async {
    await _assertHasReturn(code, n, false);
  }

  /// Assert that the [n]th statement in the last function declaration of
  /// [code] does not exit.
  Future<void> _assertNthStatementExits(String code, int n) async {
    await _assertHasReturn(code, n, true);
  }
}
