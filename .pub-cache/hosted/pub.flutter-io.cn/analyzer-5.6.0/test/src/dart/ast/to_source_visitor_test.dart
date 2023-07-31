// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/to_source_visitor.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/feature_sets.dart';
import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ToSourceVisitorTest);
  });
}

@reflectiveTest
class ToSourceVisitorTest extends ParserDiagnosticsTest {
  void test_visitAdjacentStrings() {
    var findNode = _parseStringToFindNode(r'''
var v = 'a' 'b';
''');
    _assertSource(
      "'a' 'b'",
      findNode.adjacentStrings("'a'"),
    );
  }

  void test_visitAnnotation_constant() {
    final code = '@A';
    final findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource(code, findNode.annotation(code));
  }

  void test_visitAnnotation_constructor() {
    final code = '@A.foo()';
    final findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource(code, findNode.annotation(code));
  }

  void test_visitAnnotation_constructor_generic() {
    final code = '@A<int>.foo()';
    final findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource(code, findNode.annotation(code));
  }

  void test_visitArgumentList() {
    final code = '(0, 1)';
    final findNode = _parseStringToFindNode('''
final x = f$code;
''');
    _assertSource(code, findNode.argumentList(code));
  }

  void test_visitAsExpression() {
    var findNode = _parseStringToFindNode(r'''
var v = a as T;
''');
    _assertSource(
      'a as T',
      findNode.as_('as T'),
    );
  }

  void test_visitAssertStatement() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  assert(a);
}
''');
    _assertSource(
      'assert (a);',
      findNode.assertStatement('assert'),
    );
  }

  void test_visitAssertStatement_withMessage() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  assert(a, b);
}
''');
    _assertSource(
      'assert (a, b);',
      findNode.assertStatement('assert'),
    );
  }

  void test_visitAssignedVariablePattern() {
    var findNode = _parseStringToFindNode('''
void f(int foo) {
  (foo) = 0;
}
''');
    _assertSource('foo', findNode.assignedVariablePattern('foo) = 0'));
  }

  void test_visitAssignmentExpression() {
    final code = 'a = b';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.assignment(code));
  }

  void test_visitAugmentationImportDirective() {
    var findNode = _parseStringToFindNode(r'''
import augment 'a.dart';
''');
    _assertSource(
      "import augment 'a.dart';",
      findNode.augmentationImportDirective('import'),
    );
  }

  void test_visitAwaitExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() async => await e;
''');
    _assertSource(
      'await e',
      findNode.awaitExpression('await e'),
    );
  }

  void test_visitBinaryExpression() {
    var findNode = _parseStringToFindNode(r'''
var v = a + b;
''');
    _assertSource(
      'a + b',
      findNode.binary('a + b'),
    );
  }

  void test_visitBinaryExpression_precedence() {
    var findNode = _parseStringToFindNode(r'''
var v = a * (b + c);
''');
    _assertSource(
      'a * (b + c)',
      findNode.binary('a *'),
    );
  }

  void test_visitBlock_empty() {
    final code = '{}';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.block(code));
  }

  void test_visitBlock_nonEmpty() {
    final code = '{foo(); bar();}';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.block(code));
  }

  void test_visitBlockFunctionBody_async() {
    final code = 'async {}';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.blockFunctionBody(code));
  }

  void test_visitBlockFunctionBody_async_star() {
    final code = 'async* {}';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.blockFunctionBody(code));
  }

  void test_visitBlockFunctionBody_simple() {
    final code = '{}';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.blockFunctionBody(code));
  }

  void test_visitBlockFunctionBody_sync_star() {
    final code = 'sync* {}';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.blockFunctionBody(code));
  }

  void test_visitBooleanLiteral_false() {
    final code = 'false';
    final findNode = _parseStringToFindNode('''
final v = $code;
''');
    _assertSource(code, findNode.booleanLiteral(code));
  }

  void test_visitBooleanLiteral_true() {
    final code = 'true';
    final findNode = _parseStringToFindNode('''
final v = $code;
''');
    _assertSource(code, findNode.booleanLiteral(code));
  }

  void test_visitBreakStatement_label() {
    final code = 'break L;';
    final findNode = _parseStringToFindNode('''
void f() {
  L: while (true) {
    $code
  }
}
''');
    _assertSource(code, findNode.breakStatement(code));
  }

  void test_visitBreakStatement_noLabel() {
    final code = 'break;';
    final findNode = _parseStringToFindNode('''
void f() {
  while (true) {
    $code
  }
}
''');
    _assertSource(code, findNode.breakStatement(code));
  }

  void test_visitCascadeExpression_field() {
    final code = 'a..b..c';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.cascade(code));
  }

  void test_visitCascadeExpression_index() {
    final code = 'a..[0]..[1]';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.cascade(code));
  }

  void test_visitCascadeExpression_method() {
    final code = 'a..b()..c()';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.cascade(code));
  }

  void test_visitCastPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case y as int:
      break;
  }
}
''');
    _assertSource(
      'y as int',
      findNode.castPattern('as '),
    );
  }

  void test_visitCatchClause_catch_noStack() {
    final code = 'catch (e) {}';
    final findNode = _parseStringToFindNode('''
void f() {
  try {}
  $code
}
''');
    _assertSource(code, findNode.catchClause(code));
  }

  void test_visitCatchClause_catch_stack() {
    final code = 'catch (e, s) {}';
    final findNode = _parseStringToFindNode('''
void f() {
  try {}
  $code
}
''');
    _assertSource(code, findNode.catchClause(code));
  }

  void test_visitCatchClause_on() {
    final code = 'on E {}';
    final findNode = _parseStringToFindNode('''
void f() {
  try {}
  $code
}
''');
    _assertSource(code, findNode.catchClause(code));
  }

  void test_visitCatchClause_on_catch() {
    final code = 'on E catch (e) {}';
    final findNode = _parseStringToFindNode('''
void f() {
  try {}
  $code
}
''');
    _assertSource(code, findNode.catchClause(code));
  }

  void test_visitClassDeclaration_abstract() {
    final code = 'abstract class C {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_abstractAugment() {
    final code = 'augment abstract class C {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classDeclaration('class C'));
  }

  void test_visitClassDeclaration_abstractMacro() {
    final code = 'abstract macro class C {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_augment() {
    var findNode = _parseStringToFindNode(r'''
augment class A {}
''');
    _assertSource(
      'augment class A {}',
      findNode.classDeclaration('class A'),
    );
  }

  void test_visitClassDeclaration_base() {
    var findNode = _parseStringToFindNode(r'''
base class A {}
''');
    _assertSource(
      'base class A {}',
      findNode.classDeclaration('class A'),
    );
  }

  void test_visitClassDeclaration_empty() {
    final code = 'class C {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_extends() {
    final code = 'class C extends A {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_extends_implements() {
    final code = 'class C extends A implements B {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_extends_with() {
    final code = 'class C extends A with M {}';
    final findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_extends_with_implements() {
    final code = 'class C extends A with M implements B {}';
    final findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_final() {
    var findNode = _parseStringToFindNode(r'''
final class A {}
''');
    _assertSource(
      'final class A {}',
      findNode.classDeclaration('class A'),
    );
  }

  void test_visitClassDeclaration_implements() {
    final code = 'class C implements B {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_interface() {
    var findNode = _parseStringToFindNode(r'''
interface class A {}
''');
    _assertSource(
      'interface class A {}',
      findNode.classDeclaration('class A'),
    );
  }

  void test_visitClassDeclaration_macro() {
    var findNode = _parseStringToFindNode(r'''
macro class A {}
''');
    _assertSource(
      'macro class A {}',
      findNode.classDeclaration('class A'),
    );
  }

  void test_visitClassDeclaration_mixin() {
    var findNode = _parseStringToFindNode(r'''
mixin class A {}
''');
    _assertSource(
      'mixin class A {}',
      findNode.classDeclaration('class A'),
    );
  }

  void test_visitClassDeclaration_multipleMember() {
    final code = 'class C {var a; var b;}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters() {
    final code = 'class C<E> {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters_extends() {
    final code = 'class C<E> extends A {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters_extends_implements() {
    final code = 'class C<E> extends A implements B {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters_extends_with() {
    final code = 'class C<E> extends A with M {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters_extends_with_implements() {
    final code = 'class C<E> extends A with M implements B {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters_implements() {
    final code = 'class C<E> implements B {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_sealed() {
    var findNode = _parseStringToFindNode(r'''
sealed class A {}
''');
    _assertSource(
      'sealed class A {}',
      findNode.classDeclaration('class A'),
    );
  }

  void test_visitClassDeclaration_singleMember() {
    final code = 'class C {var a;}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_withMetadata() {
    final code = '@deprecated class C {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassTypeAlias_abstract() {
    final code = 'abstract class C = S with M;';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_abstract_implements() {
    final code = 'abstract class C = S with M implements I;';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_abstractAugment() {
    // TODO(scheglov) Is this the right order of modifiers?
    final code = 'augment abstract class C = S with M;';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias('class C'));
  }

  void test_visitClassTypeAlias_abstractMacro() {
    final code = 'abstract macro class C = S with M;';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_augment() {
    var findNode = _parseStringToFindNode(r'''
augment class A = S with M;
''');
    _assertSource(
      'augment class A = S with M;',
      findNode.classTypeAlias('class A'),
    );
  }

  void test_visitClassTypeAlias_base() {
    var findNode = _parseStringToFindNode(r'''
base class A = S with M;
''');
    _assertSource(
      'base class A = S with M;',
      findNode.classTypeAlias('class A'),
    );
  }

  void test_visitClassTypeAlias_final() {
    var findNode = _parseStringToFindNode(r'''
final class A = S with M;
''');
    _assertSource(
      'final class A = S with M;',
      findNode.classTypeAlias('class A'),
    );
  }

  void test_visitClassTypeAlias_generic() {
    final code = 'class C<E> = S<E> with M<E>;';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_implements() {
    final code = 'class C = S with M implements I;';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_interface() {
    var findNode = _parseStringToFindNode(r'''
interface class A = S with M;
''');
    _assertSource(
      'interface class A = S with M;',
      findNode.classTypeAlias('class A'),
    );
  }

  void test_visitClassTypeAlias_macro() {
    var findNode = _parseStringToFindNode(r'''
macro class A = S with M;
''');
    _assertSource(
      'macro class A = S with M;',
      findNode.classTypeAlias('class A'),
    );
  }

  void test_visitClassTypeAlias_minimal() {
    final code = 'class C = S with M;';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_mixin() {
    var findNode = _parseStringToFindNode(r'''
mixin class A = S with M;
''');
    _assertSource(
      'mixin class A = S with M;',
      findNode.classTypeAlias('class A'),
    );
  }

  void test_visitClassTypeAlias_parameters_abstract() {
    final code = 'abstract class C<E> = S with M;';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_parameters_abstract_implements() {
    final code = 'abstract class C<E> = S with M implements I;';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_parameters_implements() {
    final code = 'class C<E> = S with M implements I;';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_sealed() {
    var findNode = _parseStringToFindNode(r'''
sealed class A = S with M;
''');
    _assertSource(
      'sealed class A = S with M;',
      findNode.classTypeAlias('class A'),
    );
  }

  void test_visitClassTypeAlias_withMetadata() {
    final code = '@deprecated class A = S with M;';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitComment() {
    final code = r'''
/// foo
/// bar
''';
    final findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource('', findNode.comment(code));
  }

  void test_visitCommentReference() {
    final code = 'x';
    final findNode = _parseStringToFindNode('''
/// [$code]
void f() {}
''');
    _assertSource('', findNode.commentReference(code));
  }

  void test_visitCompilationUnit_declaration() {
    final code = 'var a;';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.unit);
  }

  void test_visitCompilationUnit_directive() {
    final code = 'library my;';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.unit);
  }

  void test_visitCompilationUnit_directive_declaration() {
    final code = 'library my; var a;';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.unit);
  }

  void test_visitCompilationUnit_empty() {
    final code = '';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.unit);
  }

  void test_visitCompilationUnit_libraryWithoutName() {
    final code = 'library ;';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.unit);
  }

  void test_visitCompilationUnit_script() {
    final findNode = _parseStringToFindNode('''
#!/bin/dartvm
''');
    _assertSource('#!/bin/dartvm', findNode.unit);
  }

  void test_visitCompilationUnit_script_declaration() {
    final findNode = _parseStringToFindNode('''
#!/bin/dartvm
var a;
''');
    _assertSource('#!/bin/dartvm var a;', findNode.unit);
  }

  void test_visitCompilationUnit_script_directive() {
    final findNode = _parseStringToFindNode('''
#!/bin/dartvm
library my;
''');
    _assertSource('#!/bin/dartvm library my;', findNode.unit);
  }

  void test_visitCompilationUnit_script_directives_declarations() {
    final findNode = _parseStringToFindNode('''
#!/bin/dartvm
library my;
var a;
''');
    _assertSource('#!/bin/dartvm library my; var a;', findNode.unit);
  }

  void test_visitConditionalExpression() {
    final code = 'a ? b : c';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.conditionalExpression(code));
  }

  void test_visitConstantPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  if (x case true) {}
}
''');
    _assertSource(
      'true',
      findNode.constantPattern('true'),
    );
  }

  void test_visitConstructorDeclaration_const() {
    final code = 'const A();';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_external() {
    final code = 'external A();';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_minimal() {
    final code = 'A();';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_multipleInitializers() {
    final code = 'A() : a = b, c = d {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_multipleParameters() {
    final code = 'A(int a, double b);';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_named() {
    final code = 'A.foo();';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_singleInitializer() {
    final code = 'A() : a = b;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_withMetadata() {
    final code = '@deprecated C() {}';
    final findNode = _parseStringToFindNode('''
class C {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorFieldInitializer_withoutThis() {
    final code = 'a = 0';
    final findNode = _parseStringToFindNode('''
class C {
  C() : $code;
}
''');
    _assertSource(code, findNode.constructorFieldInitializer(code));
  }

  void test_visitConstructorFieldInitializer_withThis() {
    final code = 'this.a = 0';
    final findNode = _parseStringToFindNode('''
class C {
  C() : $code;
}
''');
    _assertSource(code, findNode.constructorFieldInitializer(code));
  }

  void test_visitConstructorName_named_prefix() {
    final code = 'prefix.A.foo';
    final findNode = _parseStringToFindNode('''
final x = new $code();
''');
    _assertSource(code, findNode.constructorName(code));
  }

  void test_visitConstructorName_unnamed_noPrefix() {
    final code = 'A';
    final findNode = _parseStringToFindNode('''
final x = new $code();
''');
    _assertSource(code, findNode.constructorName(code));
  }

  void test_visitConstructorName_unnamed_prefix() {
    final code = 'prefix.A';
    final findNode = _parseStringToFindNode('''
final x = new $code();
''');
    _assertSource(code, findNode.constructorName(code));
  }

  void test_visitContinueStatement_label() {
    final code = 'continue L;';
    final findNode = _parseStringToFindNode('''
void f() {
  L: while (true) {
    $code
  }
}
''');
    _assertSource(code, findNode.continueStatement('continue'));
  }

  void test_visitContinueStatement_noLabel() {
    final code = 'continue;';
    final findNode = _parseStringToFindNode('''
void f() {
  while (true) {
    $code
  }
}
''');
    _assertSource(code, findNode.continueStatement('continue'));
  }

  void test_visitDeclaredVariablePattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case int? a:
      break;
  }
}
''');
    _assertSource(
      'int? a',
      findNode.declaredVariablePattern('int?'),
    );
  }

  void test_visitDefaultFormalParameter_annotation() {
    final code = '@deprecated p = 0';
    final findNode = _parseStringToFindNode('''
void f([$code]) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitDefaultFormalParameter_named_noValue() {
    final code = 'int? a';
    final findNode = _parseStringToFindNode('''
void f({$code}) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitDefaultFormalParameter_named_value() {
    final code = 'int? a = 0';
    final findNode = _parseStringToFindNode('''
void f({$code}) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitDefaultFormalParameter_positional_noValue() {
    final code = 'int? a';
    final findNode = _parseStringToFindNode('''
void f([$code]) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitDefaultFormalParameter_positional_value() {
    final code = 'int? a = 0';
    final findNode = _parseStringToFindNode('''
void f([$code]) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitDoStatement() {
    final code = 'do {} while (true);';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.doStatement(code));
  }

  void test_visitDoubleLiteral() {
    final code = '3.14';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.doubleLiteral(code));
  }

  void test_visitEmptyFunctionBody() {
    final code = ';';
    final findNode = _parseStringToFindNode('''
void f() {
  ;
}
''');
    _assertSource(code, findNode.emptyStatement(code));
  }

  void test_visitEmptyStatement() {
    final code = ';';
    final findNode = _parseStringToFindNode('''
abstract class A {
  void foo();
}
''');
    _assertSource(code, findNode.emptyFunctionBody(code));
  }

  void test_visitEnumDeclaration_constant_arguments_named() {
    var findNode = _parseStringToFindNode(r'''
enum E {
  v<double>.named(42)
}
''');
    _assertSource(
      'enum E {v<double>.named(42)}',
      findNode.enumDeclaration('enum E'),
    );
  }

  void test_visitEnumDeclaration_constant_arguments_unnamed() {
    var findNode = _parseStringToFindNode(r'''
enum E {
  v<double>(42)
}
''');
    _assertSource(
      'enum E {v<double>(42)}',
      findNode.enumDeclaration('enum E'),
    );
  }

  void test_visitEnumDeclaration_constants_multiple() {
    var findNode = _parseStringToFindNode(r'''
enum E {one, two}
''');
    _assertSource(
      'enum E {one, two}',
      findNode.enumDeclaration('E'),
    );
  }

  void test_visitEnumDeclaration_constants_single() {
    var findNode = _parseStringToFindNode(r'''
enum E {one}
''');
    _assertSource(
      'enum E {one}',
      findNode.enumDeclaration('E'),
    );
  }

  void test_visitEnumDeclaration_field_constructor() {
    var findNode = _parseStringToFindNode(r'''
enum E {
  one, two;
  final int field;
  E(this.field);
}
''');
    _assertSource(
      'enum E {one, two; final int field; E(this.field);}',
      findNode.enumDeclaration('enum E'),
    );
  }

  void test_visitEnumDeclaration_method() {
    var findNode = _parseStringToFindNode(r'''
enum E {
  one, two;
  void myMethod() {}
  int get myGetter => 0;
}
''');
    _assertSource(
      'enum E {one, two; void myMethod() {} int get myGetter => 0;}',
      findNode.enumDeclaration('enum E'),
    );
  }

  void test_visitEnumDeclaration_withoutMembers() {
    var findNode = _parseStringToFindNode(r'''
enum E<T> with M1, M2 implements I1, I2 {one, two}
''');
    _assertSource(
      'enum E<T> with M1, M2 implements I1, I2 {one, two}',
      findNode.enumDeclaration('E'),
    );
  }

  void test_visitExportDirective_combinator() {
    final code = "export 'a.dart' show A;";
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.export(code));
  }

  void test_visitExportDirective_combinators() {
    final code = "export 'a.dart' show A hide B;";
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.export(code));
  }

  void test_visitExportDirective_configurations() {
    var unit = parseString(content: r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''').unit;
    var directive = unit.directives[0] as ExportDirective;
    _assertSource(
      "export 'foo.dart'"
      " if (dart.library.io) 'foo_io.dart'"
      " if (dart.library.html) 'foo_html.dart';",
      directive,
    );
  }

  void test_visitExportDirective_minimal() {
    final code = "export 'a.dart';";
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.export(code));
  }

  void test_visitExportDirective_withMetadata() {
    final code = '@deprecated export "a.dart";';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.export(code));
  }

  void test_visitExpressionFunctionBody_async() {
    final code = 'async => 0;';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.expressionFunctionBody(code));
  }

  void test_visitExpressionFunctionBody_async_star() {
    final code = 'async* => 0;';
    final parseResult = parseStringWithErrors('''
void f() $code
''');
    final node = parseResult.findNode.expressionFunctionBody(code);
    _assertSource(code, node);
  }

  void test_visitExpressionFunctionBody_simple() {
    final code = '=> 0;';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.expressionFunctionBody(code));
  }

  void test_visitExpressionStatement() {
    final code = '1 + 2;';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.expressionStatement(code));
  }

  void test_visitExtendsClause() {
    final code = 'extends A';
    final findNode = _parseStringToFindNode('''
class C $code {}
''');
    _assertSource(code, findNode.extendsClause(code));
  }

  void test_visitExtensionDeclaration_empty() {
    final code = 'extension E on C {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.extensionDeclaration(code));
  }

  void test_visitExtensionDeclaration_multipleMember() {
    final code = 'extension E on C {static var a; static var b;}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.extensionDeclaration(code));
  }

  void test_visitExtensionDeclaration_parameters() {
    final code = 'extension E<T> on C {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.extensionDeclaration(code));
  }

  void test_visitExtensionDeclaration_singleMember() {
    final code = 'extension E on C {static var a;}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.extensionDeclaration(code));
  }

  void test_visitExtensionOverride_prefixedName_noTypeArgs() {
    // TODO(scheglov) restore
    // _assertSource(
    //     'p.E(o)',
    //     AstTestFactory.extensionOverride(
    //         extensionName: AstTestFactory.identifier5('p', 'E'),
    //         argumentList: AstTestFactory.argumentList(
    //             [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionOverride_prefixedName_typeArgs() {
    // TODO(scheglov) restore
    // _assertSource(
    //     'p.E<A>(o)',
    //     AstTestFactory.extensionOverride(
    //         extensionName: AstTestFactory.identifier5('p', 'E'),
    //         typeArguments: AstTestFactory.typeArgumentList(
    //             [AstTestFactory.namedType4('A')]),
    //         argumentList: AstTestFactory.argumentList(
    //             [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionOverride_simpleName_noTypeArgs() {
    // TODO(scheglov) restore
    // _assertSource(
    //     'E(o)',
    //     AstTestFactory.extensionOverride(
    //         extensionName: AstTestFactory.identifier3('E'),
    //         argumentList: AstTestFactory.argumentList(
    //             [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionOverride_simpleName_typeArgs() {
    // TODO(scheglov) restore
    // _assertSource(
    //     'E<A>(o)',
    //     AstTestFactory.extensionOverride(
    //         extensionName: AstTestFactory.identifier3('E'),
    //         typeArguments: AstTestFactory.typeArgumentList(
    //             [AstTestFactory.namedType4('A')]),
    //         argumentList: AstTestFactory.argumentList(
    //             [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionTypeDeclaration_empty() {
    final code = 'extension type E on C {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.extensionDeclaration(code));
  }

  void test_visitExtensionTypeDeclaration_multipleMember() {
    final code = 'extension type E on C {static var a; static var b;}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.extensionDeclaration(code));
  }

  void test_visitExtensionTypeDeclaration_parameters() {
    final code = 'extension type E<T> on C {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.extensionDeclaration(code));
  }

  void test_visitExtensionTypeDeclaration_singleMember() {
    final code = 'extension type E on C {static var a;}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.extensionDeclaration(code));
  }

  void test_visitFieldDeclaration_abstract() {
    final code = 'abstract var a;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.fieldDeclaration(code));
  }

  void test_visitFieldDeclaration_external() {
    final code = 'external var a;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.fieldDeclaration(code));
  }

  void test_visitFieldDeclaration_instance() {
    final code = 'var a;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.fieldDeclaration(code));
  }

  void test_visitFieldDeclaration_static() {
    final code = 'static var a;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.fieldDeclaration(code));
  }

  void test_visitFieldDeclaration_withMetadata() {
    final code = '@deprecated var a;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.fieldDeclaration(code));
  }

  void test_visitFieldFormalParameter_annotation() {
    final code = '@deprecated this.foo';
    final findNode = _parseStringToFindNode('''
class A {
  final int foo;
  A($code);
}
''');
    _assertSource(code, findNode.fieldFormalParameter(code));
  }

  void test_visitFieldFormalParameter_functionTyped() {
    final code = 'A this.a(b)';
    final findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.fieldFormalParameter(code));
  }

  void test_visitFieldFormalParameter_functionTyped_typeParameters() {
    final code = 'A this.a<E, F>(b)';
    final findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.fieldFormalParameter(code));
  }

  void test_visitFieldFormalParameter_keyword() {
    final code = 'var this.a';
    final findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.fieldFormalParameter(code));
  }

  void test_visitFieldFormalParameter_keywordAndType() {
    final code = 'final A this.a';
    final findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.fieldFormalParameter(code));
  }

  void test_visitFieldFormalParameter_type() {
    final code = 'A this.a';
    final findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.fieldFormalParameter(code));
  }

  void test_visitFieldFormalParameter_type_covariant() {
    final code = 'covariant A this.a';
    final findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.fieldFormalParameter(code));
  }

  void test_visitForEachPartsWithIdentifier() {
    final code = 'e in []';
    final findNode = _parseStringToFindNode('''
void f() {
  for ($code) {}
}
''');
    _assertSource(code, findNode.forEachPartsWithIdentifier(code));
  }

  @failingTest
  void test_visitForEachPartsWithPattern() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitForEachStatement_declared() {
    final code = 'for (final a in b) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForEachStatement_variable() {
    final code = 'for (a in b) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForEachStatement_variable_await() {
    final code = 'await for (final a in b) {}';
    final findNode = _parseStringToFindNode('''
void f() async {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForElement() {
    final code = 'for (e in []) 0';
    final findNode = _parseStringToFindNode('''
final v = [ $code ];
''');
    _assertSource(code, findNode.forElement(code));
  }

  void test_visitFormalParameterList_empty() {
    final code = '()';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_n() {
    final code = '({a = 0})';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_namedRequired() {
    final code = '({required a, required int b})';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_nn() {
    final code = '({int a = 0, b = 1})';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_p() {
    final code = '([a = 0])';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_pp() {
    final code = '([a = 0, b = 1])';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_r() {
    final code = '(int a)';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rn() {
    final code = '(a, {b = 1})';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rnn() {
    final code = '(a, {b = 1, c = 2})';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rp() {
    final code = '(a, [b = 1])';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rpp() {
    final code = '(a, [b = 1, c = 2])';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rr() {
    final code = '(int a, int b)';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rrn() {
    final code = '(a, b, {c = 2})';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rrnn() {
    final code = '(a, b, {c = 2, d = 3})';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rrp() {
    final code = '(a, b, [c = 2])';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rrpp() {
    final code = '(a, b, [c = 2, d = 3])';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitForPartsWithDeclarations() {
    final code = 'var v = 0; v < 10; v++';
    final findNode = _parseStringToFindNode('''
void f() {
  for ($code) {}
}
''');
    _assertSource(code, findNode.forPartsWithDeclarations(code));
  }

  void test_visitForPartsWithExpression() {
    final code = 'v = 0; v < 10; v++';
    final findNode = _parseStringToFindNode('''
void f() {
  for ($code) {}
}
''');
    _assertSource(code, findNode.forPartsWithExpression(code));
  }

  @failingTest
  void test_visitForPartsWithPattern() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitForStatement() {
    final code = 'for (var v in [0]) {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_c() {
    final code = 'for (; c;) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_cu() {
    final code = 'for (; c; u) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_e() {
    final code = 'for (e;;) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_ec() {
    final code = 'for (e; c;) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_ecu() {
    final code = 'for (e; c; u) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_eu() {
    final code = 'for (e;; u) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_i() {
    final code = 'for (var i;;) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_ic() {
    final code = 'for (var i; c;) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_icu() {
    final code = 'for (var i; c; u) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_iu() {
    final code = 'for (var i;; u) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_u() {
    final code = 'for (;; u) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitFunctionDeclaration_external() {
    final code = 'external void f();';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_getter() {
    final code = 'get foo {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_local_blockBody() {
    final code = 'void foo() {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_local_expressionBody() {
    final code = 'int foo() => 42;';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_normal() {
    final code = 'void foo() {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_setter() {
    final code = 'set foo(int _) {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_typeParameters() {
    final code = 'void foo<T>() {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_withMetadata() {
    final code = '@deprecated void f() {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclarationStatement() {
    final code = 'void foo() {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionExpression() {
    final code = '() {}';
    final findNode = _parseStringToFindNode('''
final f = $code;
''');
    _assertSource(code, findNode.functionExpression(code));
  }

  void test_visitFunctionExpression_typeParameters() {
    final code = '<T>() {}';
    final findNode = _parseStringToFindNode('''
final f = $code;
''');
    _assertSource(code, findNode.functionExpression(code));
  }

  void test_visitFunctionExpressionInvocation_minimal() {
    final code = '(a)()';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.functionExpressionInvocation(code));
  }

  void test_visitFunctionExpressionInvocation_typeArguments() {
    final code = '(a)<int>()';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.functionExpressionInvocation(code));
  }

  void test_visitFunctionTypeAlias_generic() {
    final code = 'typedef A F<B>();';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.functionTypeAlias(code));
  }

  void test_visitFunctionTypeAlias_nonGeneric() {
    final code = 'typedef A F();';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.functionTypeAlias(code));
  }

  void test_visitFunctionTypeAlias_withMetadata() {
    final code = '@deprecated typedef void F();';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionTypeAlias(code));
  }

  void test_visitFunctionTypedFormalParameter_annotation() {
    final code = '@deprecated g()';
    final findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.functionTypedFormalParameter(code));
  }

  void test_visitFunctionTypedFormalParameter_noType() {
    final code = 'int f()';
    final findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.functionTypedFormalParameter(code));
  }

  void test_visitFunctionTypedFormalParameter_nullable() {
    final code = 'T f()?';
    final findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.functionTypedFormalParameter(code));
  }

  void test_visitFunctionTypedFormalParameter_type() {
    final code = 'T f()';
    final findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.functionTypedFormalParameter(code));
  }

  void test_visitFunctionTypedFormalParameter_type_covariant() {
    final code = 'covariant T f()?';
    final findNode = _parseStringToFindNode('''
class A {
  void foo($code) {}
}
''');
    _assertSource(code, findNode.functionTypedFormalParameter(code));
  }

  void test_visitFunctionTypedFormalParameter_typeParameters() {
    final code = 'T f<E>()';
    final findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.functionTypedFormalParameter(code));
  }

  void test_visitGenericFunctionType() {
    final code = 'int Function<T>(T)';
    final findNode = _parseStringToFindNode('''
void f($code x) {}
''');
    _assertSource(code, findNode.genericFunctionType(code));
  }

  void test_visitGenericFunctionType_withQuestion() {
    final code = 'int Function<T>(T)?';
    final findNode = _parseStringToFindNode('''
void f($code x) {}
''');
    _assertSource(code, findNode.genericFunctionType(code));
  }

  void test_visitGenericTypeAlias() {
    final code = 'typedef X<S> = S Function<T>(T);';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.genericTypeAlias(code));
  }

  void test_visitIfElement_else() {
    final code = 'if (b) 1 else 0';
    final findNode = _parseStringToFindNode('''
final v = [ $code ];
''');
    _assertSource(code, findNode.ifElement(code));
  }

  void test_visitIfElement_then() {
    final code = 'if (b) 1';
    final findNode = _parseStringToFindNode('''
final v = [ $code ];
''');
    _assertSource(code, findNode.ifElement(code));
  }

  void test_visitIfStatement_withElse() {
    final code = 'if (c) {} else {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.ifStatement(code));
  }

  void test_visitIfStatement_withoutElse() {
    final code = 'if (c) {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.ifStatement(code));
  }

  void test_visitImplementsClause_multiple() {
    final code = 'implements A, B';
    final findNode = _parseStringToFindNode('''
class C $code {}
''');
    _assertSource(code, findNode.implementsClause(code));
  }

  void test_visitImplementsClause_single() {
    final code = 'implements A';
    final findNode = _parseStringToFindNode('''
class C $code {}
''');
    _assertSource(code, findNode.implementsClause(code));
  }

  void test_visitImportDirective_combinator() {
    final code = "import 'a.dart' show A;";
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_combinators() {
    final code = "import 'a.dart' show A hide B;";
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_configurations() {
    var unit = parseString(content: r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''').unit;
    var directive = unit.directives[0] as ImportDirective;
    _assertSource(
      "import 'foo.dart'"
      " if (dart.library.io) 'foo_io.dart'"
      " if (dart.library.html) 'foo_html.dart';",
      directive,
    );
  }

  void test_visitImportDirective_deferred() {
    final code = "import 'a.dart' deferred as p;";
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_minimal() {
    final code = "import 'a.dart';";
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_prefix() {
    final code = "import 'a.dart' as p;";
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_prefix_combinator() {
    final code = "import 'a.dart' as p show A;";
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_prefix_combinators() {
    final code = "import 'a.dart' as p show A hide B;";
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_withMetadata() {
    final code = '@deprecated import "a.dart";';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportHideCombinator_multiple() {
    final code = 'hide A, B';
    final findNode = _parseStringToFindNode('''
import 'a.dart' $code;
''');
    _assertSource(code, findNode.hideCombinator(code));
  }

  void test_visitImportHideCombinator_single() {
    final code = 'hide A';
    final findNode = _parseStringToFindNode('''
import 'a.dart' $code;
''');
    _assertSource(code, findNode.hideCombinator(code));
  }

  void test_visitImportShowCombinator_multiple() {
    final code = 'show A, B';
    final findNode = _parseStringToFindNode('''
import 'a.dart' $code;
''');
    _assertSource(code, findNode.showCombinator(code));
  }

  void test_visitImportShowCombinator_single() {
    final code = 'show A';
    final findNode = _parseStringToFindNode('''
import 'a.dart' $code;
''');
    _assertSource(code, findNode.showCombinator(code));
  }

  void test_visitIndexExpression() {
    final code = 'a[0]';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.index(code));
  }

  void test_visitInstanceCreationExpression_const() {
    final code = 'const A()';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.instanceCreation(code));
  }

  void test_visitInstanceCreationExpression_named() {
    final code = 'new A.foo()';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.instanceCreation(code));
  }

  void test_visitInstanceCreationExpression_unnamed() {
    final code = 'new A()';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.instanceCreation(code));
  }

  void test_visitIntegerLiteral() {
    final code = '42';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.integerLiteral(code));
  }

  void test_visitInterpolationExpression_expression() {
    final code = r'${foo}';
    final findNode = _parseStringToFindNode('''
final x = "$code";
''');
    _assertSource(code, findNode.interpolationExpression(code));
  }

  void test_visitInterpolationExpression_identifier() {
    final code = r'$foo';
    final findNode = _parseStringToFindNode('''
final x = "$code";
''');
    _assertSource(code, findNode.interpolationExpression(code));
  }

  void test_visitInterpolationString() {
    final code = "ccc'";
    final findNode = _parseStringToFindNode('''
final x = 'a\${bb}$code;
''');
    _assertSource(code, findNode.interpolationString(code));
  }

  void test_visitIsExpression_negated() {
    final code = 'a is! int';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.isExpression(code));
  }

  void test_visitIsExpression_normal() {
    final code = 'a is int';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.isExpression(code));
  }

  void test_visitLabel() {
    final code = 'myLabel:';
    final findNode = _parseStringToFindNode('''
void f() {
  $code for (final x in []) {}
}
''');
    _assertSource(code, findNode.label(code));
  }

  void test_visitLabeledStatement_multiple() {
    final code = 'a: b: return;';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.labeledStatement(code));
  }

  void test_visitLabeledStatement_single() {
    final code = 'a: return;';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.labeledStatement(code));
  }

  void test_visitLibraryAugmentationDirective() {
    var findNode = _parseStringToFindNode(r'''
library augment 'a.dart';
''');
    _assertSource(
      "library augment 'a.dart';",
      findNode.libraryAugmentation('library'),
    );
  }

  void test_visitLibraryDirective() {
    var code = 'library my;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.library(code));
  }

  void test_visitLibraryDirective_withMetadata() {
    final code = '@deprecated library my;';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.library(code));
  }

  void test_visitLibraryIdentifier_multiple() {
    var code = 'a.b.c';
    var findNode = _parseStringToFindNode('''
library $code;
''');
    _assertSource(code, findNode.libraryIdentifier(code));
  }

  void test_visitLibraryIdentifier_single() {
    var code = 'my';
    var findNode = _parseStringToFindNode('''
library $code;
''');
    _assertSource(code, findNode.libraryIdentifier(code));
  }

  void test_visitListLiteral_complex() {
    final code = '<int>[0, for (e in []) 0, if (b) 1, ...[0]]';
    final findNode = _parseStringToFindNode('''
final v = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListLiteral_const() {
    final code = 'const []';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListLiteral_empty() {
    final code = '[]';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListLiteral_nonEmpty() {
    final code = '[0, 1, 2]';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListLiteral_withConst_withoutTypeArgs() {
    final code = 'const [0]';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListLiteral_withConst_withTypeArgs() {
    final code = 'const <int>[0]';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListLiteral_withoutConst_withoutTypeArgs() {
    final code = '[0]';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListLiteral_withoutConst_withTypeArgs() {
    final code = '<int>[0]';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListPattern_empty() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case []:
      break;
  }
}
''');
    _assertSource(
      '[]',
      findNode.listPattern('[]'),
    );
  }

  void test_visitListPattern_nonEmpty() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case [1, 2]:
      break;
  }
}
''');
    _assertSource(
      '[1, 2]',
      findNode.listPattern('1'),
    );
  }

  void test_visitListPattern_withTypeArguments() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case <int>[]:
      break;
  }
}
''');
    _assertSource(
      '<int>[]',
      findNode.listPattern('[]'),
    );
  }

  void test_visitLogicalAndPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case int? _ && double? _ && Object? _:
      break;
  }
}
''');
    _assertSource(
      'int? _ && double? _ && Object? _',
      findNode.logicalAndPattern('Object?'),
    );
  }

  void test_visitLogicalOrPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case int? _ || double? _ || Object? _:
      break;
  }
}
''');
    _assertSource(
      'int? _ || double? _ || Object? _',
      findNode.logicalOrPattern('Object?'),
    );
  }

  void test_visitMapLiteral_const() {
    final code = 'const {}';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitMapLiteral_empty() {
    final code = '{}';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitMapLiteral_nonEmpty() {
    final code = '{0 : a, 1 : b, 2 : c}';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitMapLiteralEntry() {
    final code = '0 : a';
    final findNode = _parseStringToFindNode('''
final x = {$code};
''');
    _assertSource(code, findNode.mapLiteralEntry(code));
  }

  void test_visitMapPattern_empty() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case {}:
      break;
  }
}
''');
    _assertSource(
      '{}',
      findNode.mapPattern('{}'),
    );
  }

  void test_visitMapPattern_notEmpty() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case {1: 2}:
      break;
  }
}
''');
    _assertSource(
      '{1: 2}',
      findNode.mapPattern('1'),
    );
  }

  void test_visitMapPattern_withTypeArguments() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case <int, int>{}:
      break;
  }
}
''');
    _assertSource(
      '<int, int>{}',
      findNode.mapPattern('{}'),
    );
  }

  void test_visitMapPatternEntry() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case {1: 2}:
      break;
  }
}
''');
    _assertSource(
      '1: 2',
      findNode.mapPatternEntry('1'),
    );
  }

  void test_visitMethodDeclaration_external() {
    final code = 'external foo();';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_external_returnType() {
    final code = 'external int foo();';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_getter() {
    final code = 'get foo => 0;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_getter_returnType() {
    final code = 'int get foo => 0;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_minimal() {
    final code = 'foo() {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_multipleParameters() {
    final code = 'void foo(int a, double b) {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_operator() {
    final code = 'operator +(int other) {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_operator_returnType() {
    final code = 'int operator +(int other) => 0;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_returnType() {
    final code = 'int foo() => 0;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_setter() {
    final code = 'set foo(int _) {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_setter_returnType() {
    final code = 'void set foo(int _) {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_static() {
    final code = 'static foo() {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_static_returnType() {
    final code = 'static void foo() {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_typeParameters() {
    final code = 'void foo<T>() {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_withMetadata() {
    final code = '@deprecated void foo() {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodInvocation_conditional() {
    final code = 'a?.foo()';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.methodInvocation(code));
  }

  void test_visitMethodInvocation_noTarget() {
    final code = 'foo()';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.methodInvocation(code));
  }

  void test_visitMethodInvocation_target() {
    final code = 'a.foo()';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.methodInvocation(code));
  }

  void test_visitMethodInvocation_typeArguments() {
    final code = 'foo<int>()';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.methodInvocation(code));
  }

  void test_visitMixinDeclaration_base() {
    var findNode = _parseStringToFindNode(r'''
base mixin M {}
''');
    _assertSource(
      'base mixin M {}',
      findNode.mixinDeclaration('mixin M'),
    );
  }

  void test_visitMixinDeclaration_final() {
    var findNode = _parseStringToFindNode(r'''
final mixin M {}
''');
    _assertSource(
      'final mixin M {}',
      findNode.mixinDeclaration('mixin M'),
    );
  }

  void test_visitMixinDeclaration_interface() {
    var findNode = _parseStringToFindNode(r'''
interface mixin M {}
''');
    _assertSource(
      'interface mixin M {}',
      findNode.mixinDeclaration('mixin M'),
    );
  }

  void test_visitMixinDeclaration_sealed() {
    var findNode = _parseStringToFindNode(r'''
sealed mixin M {}
''');
    _assertSource(
      'sealed mixin M {}',
      findNode.mixinDeclaration('mixin M'),
    );
  }

  void test_visitNamedExpression() {
    final code = 'a: 0';
    final findNode = _parseStringToFindNode('''
void f() {
  foo($code);
}
''');
    _assertSource(code, findNode.namedExpression(code));
  }

  void test_visitNamedFormalParameter() {
    final code = 'var a = 0';
    final findNode = _parseStringToFindNode('''
void f({$code}) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitNativeClause() {
    final code = "native 'code'";
    final findNode = _parseStringToFindNode('''
class A $code {}
''');
    _assertSource(code, findNode.nativeClause(code));
  }

  void test_visitNativeFunctionBody() {
    final code = "native 'code';";
    final findNode = _parseStringToFindNode('''
void foo() $code
''');
    _assertSource(code, findNode.nativeFunctionBody(code));
  }

  void test_visitNullLiteral() {
    final code = 'null';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.nullLiteral(code));
  }

  void test_visitObjectPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case C(f: 1):
      break;
  }
}
''');
    _assertSource(
      'C(f: 1)',
      findNode.objectPattern('C'),
    );
  }

  void test_visitParenthesizedExpression() {
    final code = '(a)';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.parenthesized(code));
  }

  void test_visitParenthesizedPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case (3):
      break;
  }
}
''');
    _assertSource(
      '(3)',
      findNode.parenthesizedPattern('(3'),
    );
  }

  void test_visitPartDirective() {
    final code = "part 'a.dart';";
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.part(code));
  }

  void test_visitPartDirective_withMetadata() {
    final code = '@deprecated part "a.dart";';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.part(code));
  }

  void test_visitPartOfDirective_name() {
    var unit = parseString(content: 'part of l;').unit;
    var directive = unit.directives[0] as PartOfDirective;
    _assertSource("part of l;", directive);
  }

  void test_visitPartOfDirective_uri() {
    var unit = parseString(content: "part of 'a.dart';").unit;
    var directive = unit.directives[0] as PartOfDirective;
    _assertSource("part of 'a.dart';", directive);
  }

  void test_visitPartOfDirective_withMetadata() {
    final code = '@deprecated part of my.lib;';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.partOf(code));
  }

  @failingTest
  void test_visitPatternAssignment() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitPatternAssignmentStatement() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitPatternField_named() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case (a: 1):
      break;
  }
}
''');
    _assertSource(
      'a: 1',
      findNode.patternField('1'),
    );
  }

  void test_visitPatternField_positional() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case (1,):
      break;
  }
}
''');
    _assertSource(
      '1',
      findNode.patternField('1'),
    );
  }

  void test_visitPatternFieldName() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case (b: 2):
      break;
  }
}
''');
    _assertSource(
      'b:',
      findNode.patternFieldName('b:'),
    );
  }

  @failingTest
  void test_visitPatternVariableDeclaration() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitPatternVariableDeclarationStatement() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitPositionalFormalParameter() {
    final code = 'var a = 0';
    final findNode = _parseStringToFindNode('''
void f([$code]) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitPostfixExpression() {
    final code = 'a++';
    var findNode = _parseStringToFindNode('''
int f() {
  $code;
}
''');
    _assertSource(code, findNode.postfix(code));
  }

  void test_visitPostfixPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case true!:
      break;
  }
}
''');
    _assertSource(
      'true!',
      findNode.nullAssertPattern('true'),
    );
  }

  void test_visitPrefixedIdentifier() {
    final code = 'foo.bar';
    var findNode = _parseStringToFindNode('''
int f() {
  $code;
}
''');
    _assertSource(code, findNode.prefixed(code));
  }

  void test_visitPrefixExpression() {
    final code = '-foo';
    var findNode = _parseStringToFindNode('''
int f() {
  $code;
}
''');
    _assertSource(code, findNode.prefix(code));
  }

  void test_visitPrefixExpression_precedence() {
    var findNode = _parseStringToFindNode(r'''
var v = !(a == b);
''');
    _assertSource(
      '!(a == b)',
      findNode.prefix('!'),
    );
  }

  void test_visitPropertyAccess() {
    final code = '(foo).bar';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.propertyAccess(code));
  }

  void test_visitPropertyAccess_conditional() {
    final code = 'foo?.bar';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.propertyAccess(code));
  }

  void test_visitRecordLiteral_mixed() {
    final code = '(0, true, a: 0, b: true)';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(
      code,
      findNode.recordLiteral(code),
    );
  }

  void test_visitRecordLiteral_named() {
    final code = '(a: 0, b: true)';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(
      code,
      findNode.recordLiteral(code),
    );
  }

  void test_visitRecordLiteral_positional() {
    final code = '(0, true)';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(
      code,
      findNode.recordLiteral(code),
    );
  }

  void test_visitRecordPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case (1, 2):
      break;
  }
}
''');
    _assertSource(
      '(1, 2)',
      findNode.recordPattern('(1'),
    );
  }

  void test_visitRecordTypeAnnotation_mixed() {
    final code = '(int, bool, {int a, bool b})';
    var findNode = _parseStringToFindNode('''
$code f() {}
''');
    _assertSource(
      code,
      findNode.recordTypeAnnotation(code),
    );
  }

  void test_visitRecordTypeAnnotation_named() {
    final code = '({int a, bool b})';
    var findNode = _parseStringToFindNode('''
$code f() {}
''');
    _assertSource(
      code,
      findNode.recordTypeAnnotation(code),
    );
  }

  void test_visitRecordTypeAnnotation_positional() {
    final code = '(int, bool)';
    var findNode = _parseStringToFindNode('''
$code f() {}
''');
    _assertSource(
      code,
      findNode.recordTypeAnnotation(code),
    );
  }

  void test_visitRecordTypeAnnotation_positional_nullable() {
    final code = '(int, bool)?';
    var findNode = _parseStringToFindNode('''
$code f() {}
''');
    _assertSource(
      code,
      findNode.recordTypeAnnotation(code),
    );
  }

  void test_visitRedirectingConstructorInvocation_named() {
    final code = 'this.named()';
    var findNode = _parseStringToFindNode('''
class A {
  A() : $code;
}
''');
    _assertSource(
      code,
      findNode.redirectingConstructorInvocation(code),
    );
  }

  void test_visitRedirectingConstructorInvocation_unnamed() {
    final code = 'this()';
    var findNode = _parseStringToFindNode('''
class A {
  A.named() : $code;
}
''');
    _assertSource(
      code,
      findNode.redirectingConstructorInvocation(code),
    );
  }

  void test_visitRelationalPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case > 3:
      break;
  }
}
''');
    _assertSource(
      '> 3',
      findNode.relationalPattern('>'),
    );
  }

  void test_visitRethrowExpression() {
    final code = 'rethrow';
    var findNode = _parseStringToFindNode('''
void f() {
  try {} on int {
    $code;
  }
}
''');
    _assertSource(code, findNode.rethrow_(code));
  }

  void test_visitReturnStatement_expression() {
    final code = 'return 0;';
    var findNode = _parseStringToFindNode('''
int f() {
  $code
}
''');
    _assertSource(code, findNode.returnStatement(code));
  }

  void test_visitReturnStatement_noExpression() {
    final code = 'return;';
    var findNode = _parseStringToFindNode('''
int f() {
  $code
}
''');
    _assertSource(code, findNode.returnStatement(code));
  }

  void test_visitSetOrMapLiteral_map_complex() {
    final code =
        "<String, String>{'a' : 'b', for (c in d) 'e' : 'f', if (g) 'h' : 'i', ...{'j' : 'k'}}";
    final findNode = _parseStringToFindNode('''
final v = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_map_withConst_withoutTypeArgs() {
    final code = 'const {0 : a}';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_map_withConst_withTypeArgs() {
    final code = 'const <int, String>{0 : a}';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_map_withoutConst_withoutTypeArgs() {
    final code = '{0 : a}';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_map_withoutConst_withTypeArgs() {
    final code = '<int, String>{0 : a}';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_set_complex() {
    final code = '<int>{0, for (e in l) 0, if (b) 1, ...[0]}';
    final findNode = _parseStringToFindNode('''
final v = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_set_withConst_withoutTypeArgs() {
    final code = 'const {0}';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_set_withConst_withTypeArgs() {
    final code = 'const <int>{0}';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_set_withoutConst_withoutTypeArgs() {
    final code = '{0}';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_set_withoutConst_withTypeArgs() {
    final code = '<int>{0}';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSimpleFormalParameter_annotation() {
    final code = '@deprecated int x';
    final findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.simpleFormalParameter(code));
  }

  void test_visitSimpleFormalParameter_keyword() {
    final code = 'var a';
    final findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.simpleFormalParameter(code));
  }

  void test_visitSimpleFormalParameter_keyword_type() {
    final code = 'final int a';
    final findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.simpleFormalParameter(code));
  }

  void test_visitSimpleFormalParameter_type() {
    final code = 'int a';
    final findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.simpleFormalParameter(code));
  }

  void test_visitSimpleFormalParameter_type_covariant() {
    final code = 'covariant int a';
    final findNode = _parseStringToFindNode('''
class A {
  void foo($code) {}
}
''');
    _assertSource(code, findNode.simpleFormalParameter(code));
  }

  void test_visitSimpleIdentifier() {
    final code = 'foo';
    final findNode = _parseStringToFindNode('''
var x = $code;
''');
    _assertSource(code, findNode.simple(code));
  }

  void test_visitSimpleStringLiteral() {
    final code = "'str'";
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.simpleStringLiteral(code));
  }

  void test_visitSpreadElement_nonNullable() {
    final code = '...[0]';
    final findNode = _parseStringToFindNode('''
final x = [$code];
''');
    _assertSource(code, findNode.spreadElement(code));
  }

  void test_visitSpreadElement_nullable() {
    final code = '...?[0]';
    final findNode = _parseStringToFindNode('''
final x = [$code];
''');
    _assertSource(code, findNode.spreadElement(code));
  }

  void test_visitStringInterpolation() {
    final code = r"'a${bb}ccc'";
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.stringInterpolation(code));
  }

  void test_visitSuperConstructorInvocation() {
    final code = 'super(0)';
    final findNode = _parseStringToFindNode('''
class A extends B {
  A() : $code;
}
''');
    _assertSource(code, findNode.superConstructorInvocation(code));
  }

  void test_visitSuperConstructorInvocation_named() {
    final code = 'super.named(0)';
    final findNode = _parseStringToFindNode('''
class A extends B {
  A() : $code;
}
''');
    _assertSource(code, findNode.superConstructorInvocation(code));
  }

  void test_visitSuperExpression() {
    final findNode = _parseStringToFindNode('''
class A {
  void foo() {
    super.foo();
  }
}
''');
    _assertSource('super', findNode.super_('super.foo'));
  }

  void test_visitSuperFormalParameter_annotation() {
    final code = '@deprecated super.foo';
    final findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.superFormalParameter(code));
  }

  void test_visitSuperFormalParameter_functionTyped() {
    final code = 'int super.a(b)';
    final findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.superFormalParameter(code));
  }

  void test_visitSuperFormalParameter_functionTyped_typeParameters() {
    final code = 'int super.a<E, F>(b)';
    final findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.superFormalParameter(code));
  }

  void test_visitSuperFormalParameter_keyword() {
    final code = 'final super.foo';
    final findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.superFormalParameter(code));
  }

  void test_visitSuperFormalParameter_keywordAndType() {
    final code = 'final int super.a';
    final findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.superFormalParameter(code));
  }

  void test_visitSuperFormalParameter_type() {
    final code = 'int super.a';
    final findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.superFormalParameter(code));
  }

  void test_visitSuperFormalParameter_type_covariant() {
    final code = 'covariant int super.a';
    final findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.superFormalParameter(code));
  }

  void test_visitSwitchCase_multipleLabels() {
    final code = 'l1: l2: case a: {}';
    final findNode = _parseStringToFindNode('''
// @dart=2.18
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchCase(code));
  }

  void test_visitSwitchCase_multipleStatements() {
    final code = 'case a: foo(); bar();';
    final findNode = _parseStringToFindNode('''
// @dart=2.18
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchCase(code));
  }

  void test_visitSwitchCase_noLabels() {
    final code = 'case a: {}';
    final findNode = _parseStringToFindNode('''
// @dart=2.18
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchCase(code));
  }

  void test_visitSwitchCase_singleLabel() {
    final code = 'l1: case a: {}';
    final findNode = _parseStringToFindNode('''
// @dart=2.18
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchCase(code));
  }

  void test_visitSwitchDefault_multipleLabels() {
    final code = 'l1: l2: default: {}';
    final findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchDefault(code));
  }

  void test_visitSwitchDefault_multipleStatements() {
    final code = 'default: foo(); bar();';
    final findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchDefault(code));
  }

  void test_visitSwitchDefault_noLabels() {
    final code = 'default: {}';
    final findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchDefault(code));
  }

  void test_visitSwitchDefault_singleLabel() {
    final code = 'l1: default: {}';
    final findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchDefault(code));
  }

  @failingTest
  void test_visitSwitchExpression() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitSwitchExpressionCase() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitSwitchExpressionDefault() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitSwitchGuard() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitSwitchPatternCase_multipleLabels() {
    final code = 'l1: l2: case a: {}';
    final findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchPatternCase(code));
  }

  void test_visitSwitchPatternCase_multipleStatements() {
    final code = 'case a: foo(); bar();';
    final findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchPatternCase(code));
  }

  void test_visitSwitchPatternCase_noLabels() {
    final code = 'case a: {}';
    final findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchPatternCase(code));
  }

  void test_visitSwitchPatternCase_singleLabel() {
    final code = 'l1: case a: {}';
    final findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchPatternCase(code));
  }

  void test_visitSwitchStatement() {
    final code = 'switch (x) {case 0: foo(); default: bar();}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.switchStatement(code));
  }

  void test_visitSymbolLiteral_multiple() {
    final code = '#a.b.c';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.symbolLiteral(code));
  }

  void test_visitSymbolLiteral_single() {
    final code = '#a';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.symbolLiteral(code));
  }

  void test_visitThisExpression() {
    final code = 'this';
    final findNode = _parseStringToFindNode('''
class A {
  void foo() {
    $code;
  }
}
''');
    _assertSource(code, findNode.this_(code));
  }

  void test_visitThrowStatement() {
    final code = 'throw 0';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.throw_(code));
  }

  void test_visitTopLevelVariableDeclaration_external() {
    final code = 'external var a;';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.topLevelVariableDeclaration(code));
  }

  void test_visitTopLevelVariableDeclaration_multiple() {
    final code = 'var a = 0, b = 1;';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.topLevelVariableDeclaration(code));
  }

  void test_visitTopLevelVariableDeclaration_single() {
    final code = 'var a;';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.topLevelVariableDeclaration(code));
  }

  void test_visitTopLevelVariableDeclaration_withMetadata() {
    final code = '@deprecated var a;';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.topLevelVariableDeclaration(code));
  }

  void test_visitTryStatement_catch() {
    final code = 'try {} on E {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.tryStatement(code));
  }

  void test_visitTryStatement_catches() {
    final code = 'try {} on E {} on F {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.tryStatement(code));
  }

  void test_visitTryStatement_catchFinally() {
    final code = 'try {} on E {} finally {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.tryStatement(code));
  }

  void test_visitTryStatement_finally() {
    final code = 'try {} finally {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.tryStatement(code));
  }

  void test_visitTypeArgumentList_multiple() {
    final code = '<int, String>';
    final findNode = _parseStringToFindNode('''
final x = $code[];
''');
    _assertSource(code, findNode.typeArgumentList(code));
  }

  void test_visitTypeArgumentList_single() {
    final code = '<int>';
    final findNode = _parseStringToFindNode('''
final x = $code[];
''');
    _assertSource(code, findNode.typeArgumentList(code));
  }

  void test_visitTypeName_multipleArgs() {
    final code = 'Map<int, String>';
    final findNode = _parseStringToFindNode('''
final x = <$code>[];
''');
    _assertSource(code, findNode.namedType(code));
  }

  void test_visitTypeName_nestedArg() {
    final code = 'List<Set<int>>';
    final findNode = _parseStringToFindNode('''
final x = <$code>[];
''');
    _assertSource(code, findNode.namedType(code));
  }

  void test_visitTypeName_noArgs() {
    final code = 'int';
    final findNode = _parseStringToFindNode('''
final x = <$code>[];
''');
    _assertSource(code, findNode.namedType(code));
  }

  void test_visitTypeName_noArgs_withQuestion() {
    final code = 'int?';
    final findNode = _parseStringToFindNode('''
final x = <$code>[];
''');
    _assertSource(code, findNode.namedType(code));
  }

  void test_visitTypeName_singleArg() {
    final code = 'Set<int>';
    final findNode = _parseStringToFindNode('''
final x = <$code>[];
''');
    _assertSource(code, findNode.namedType(code));
  }

  void test_visitTypeName_singleArg_withQuestion() {
    final code = 'Set<int>?';
    final findNode = _parseStringToFindNode('''
final x = <$code>[];
''');
    _assertSource(code, findNode.namedType(code));
  }

  void test_visitTypeParameter_variance_contravariant() {
    final code = 'in T';
    final findNode = _parseStringToFindNode('''
class A<$code> {}
''', featureSet: FeatureSets.latestWithVariance);
    _assertSource(code, findNode.typeParameter(code));
  }

  void test_visitTypeParameter_variance_covariant() {
    final code = 'out T';
    final findNode = _parseStringToFindNode('''
class A<$code> {}
''', featureSet: FeatureSets.latestWithVariance);
    _assertSource(code, findNode.typeParameter(code));
  }

  void test_visitTypeParameter_variance_invariant() {
    final code = 'inout T';
    final findNode = _parseStringToFindNode('''
class A<$code> {}
''', featureSet: FeatureSets.latestWithVariance);
    _assertSource(code, findNode.typeParameter(code));
  }

  void test_visitTypeParameter_withExtends() {
    final code = 'T extends num';
    final findNode = _parseStringToFindNode('''
class A<$code> {}
''');
    _assertSource(code, findNode.typeParameter(code));
  }

  void test_visitTypeParameter_withMetadata() {
    final code = '@deprecated T';
    final findNode = _parseStringToFindNode('''
class A<$code> {}
''');
    _assertSource(code, findNode.typeParameter(code));
  }

  void test_visitTypeParameter_withoutExtends() {
    final code = 'T';
    final findNode = _parseStringToFindNode('''
class A<$code> {}
''', featureSet: FeatureSets.latestWithVariance);
    _assertSource(code, findNode.typeParameter(code));
  }

  void test_visitTypeParameterList_multiple() {
    final code = '<T, U>';
    final findNode = _parseStringToFindNode('''
class A$code {}
''');
    _assertSource(code, findNode.typeParameterList(code));
  }

  void test_visitTypeParameterList_single() {
    final code = '<T>';
    final findNode = _parseStringToFindNode('''
class A$code {}
''');
    _assertSource(code, findNode.typeParameterList(code));
  }

  void test_visitVariableDeclaration_initialized() {
    final code = 'foo = bar';
    final findNode = _parseStringToFindNode('''
var $code;
''', featureSet: FeatureSets.latestWithVariance);
    _assertSource(code, findNode.variableDeclaration(code));
  }

  void test_visitVariableDeclaration_uninitialized() {
    final code = 'foo';
    final findNode = _parseStringToFindNode('''
var $code;
''', featureSet: FeatureSets.latestWithVariance);
    _assertSource(code, findNode.variableDeclaration(code));
  }

  void test_visitVariableDeclarationList_const_type() {
    final code = 'const int a = 0, b = 0';
    final findNode = _parseStringToFindNode('''
$code;
''');
    _assertSource(code, findNode.variableDeclarationList(code));
  }

  void test_visitVariableDeclarationList_final_noType() {
    final code = 'final a = 0, b = 0';
    final findNode = _parseStringToFindNode('''
$code;
''');
    _assertSource(code, findNode.variableDeclarationList(code));
  }

  void test_visitVariableDeclarationList_type() {
    final code = 'int a, b';
    final findNode = _parseStringToFindNode('''
$code;
''');
    _assertSource(code, findNode.variableDeclarationList(code));
  }

  void test_visitVariableDeclarationList_var() {
    final code = 'var a, b';
    final findNode = _parseStringToFindNode('''
$code;
''');
    _assertSource(code, findNode.variableDeclarationList(code));
  }

  void test_visitVariableDeclarationStatement() {
    final code = 'int a';
    final findNode = _parseStringToFindNode('''
$code;
''');
    _assertSource(code, findNode.variableDeclarationList(code));
  }

  void test_visitWhileStatement() {
    final code = 'while (true) {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.whileStatement(code));
  }

  void test_visitWildcardPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case int? _:
      break;
  }
}
''');
    _assertSource(
      'int? _',
      findNode.wildcardPattern('int?'),
    );
  }

  void test_visitWithClause_multiple() {
    final code = 'with A, B, C';
    final findNode = _parseStringToFindNode('''
class X $code {}
''');
    _assertSource(code, findNode.withClause(code));
  }

  void test_visitWithClause_single() {
    final code = 'with M';
    final findNode = _parseStringToFindNode('''
class X $code {}
''');
    _assertSource(code, findNode.withClause(code));
  }

  void test_visitYieldStatement() {
    final code = 'yield e;';
    final findNode = _parseStringToFindNode('''
void f() sync* {
  $code
}
''');
    _assertSource(code, findNode.yieldStatement(code));
  }

  void test_visitYieldStatement_each() {
    final code = 'yield* e;';
    final findNode = _parseStringToFindNode('''
void f() sync* {
  $code
}
''');
    _assertSource(code, findNode.yieldStatement(code));
  }

  /// Assert that a [ToSourceVisitor] will produce the [expectedSource] when
  /// visiting the given [node].
  void _assertSource(String expectedSource, AstNode node) {
    StringBuffer buffer = StringBuffer();
    node.accept(ToSourceVisitor(buffer));
    expect(buffer.toString(), expectedSource);
  }

  /// TODO(scheglov) Use [parseStringWithErrors] everywhere? Or just there?
  FindNode _parseStringToFindNode(
    String content, {
    FeatureSet? featureSet,
  }) {
    var parseResult = parseString(
      content: content,
      featureSet: featureSet ?? FeatureSets.latestWithExperiments,
    );
    return FindNode(parseResult.content, parseResult.unit);
  }
}
