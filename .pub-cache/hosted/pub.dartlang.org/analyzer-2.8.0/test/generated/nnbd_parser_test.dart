// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' show TokenType;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/ast_type_matchers.dart';
import 'parser_test_base.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NNBDParserTest);
  });
}

@reflectiveTest
class NNBDParserTest extends FastaParserTestCase {
  @override
  CompilationUnitImpl parseCompilationUnit(String content,
          {List<ErrorCode>? codes,
          List<ExpectedError>? errors,
          FeatureSet? featureSet}) =>
      super.parseCompilationUnit(content,
          codes: codes,
          errors: errors,
          featureSet: featureSet ?? FeatureSet.latestLanguageVersion());

  void test_assignment_complex() {
    parseCompilationUnit('D? foo(X? x) { X? x1; X? x2 = x + bar(7); }');
  }

  void test_assignment_complex2() {
    parseCompilationUnit(r'''
main() {
  A? a;
  String? s = '';
  a?..foo().length..x27 = s!..toString().length;
}
''');
  }

  void test_assignment_simple() {
    parseCompilationUnit('D? foo(X? x) { X? x1; X? x2 = x; }');
  }

  void test_bangBeforeFuctionCall1() {
    // https://github.com/dart-lang/sdk/issues/39776
    var unit = parseCompilationUnit('f() { Function? f1; f1!(42); }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement1 = body.block.statements[0] as VariableDeclarationStatement;
    expect(statement1.toSource(), "Function? f1;");
    var statement2 = body.block.statements[1] as ExpressionStatement;

    // expression is "f1!(42)"
    var expression = statement2.expression as FunctionExpressionInvocation;
    expect(expression.toSource(), "f1!(42)");

    var functionExpression = expression.function as PostfixExpression;
    var identifier = functionExpression.operand as SimpleIdentifier;
    expect(identifier.name, 'f1');
    expect(functionExpression.operator.lexeme, '!');

    expect(expression.typeArguments, null);

    expect(expression.argumentList.arguments.length, 1);
    var argument = expression.argumentList.arguments.single as IntegerLiteral;
    expect(argument.value, 42);
  }

  void test_bangBeforeFuctionCall2() {
    // https://github.com/dart-lang/sdk/issues/39776
    var unit = parseCompilationUnit('f() { Function f2; f2!<int>(42); }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement1 = body.block.statements[0] as VariableDeclarationStatement;
    expect(statement1.toSource(), "Function f2;");
    var statement2 = body.block.statements[1] as ExpressionStatement;

    // expression is "f2!<int>(42)"
    var expression = statement2.expression as FunctionExpressionInvocation;
    expect(expression.toSource(), "f2!<int>(42)");

    var functionExpression = expression.function as PostfixExpression;
    var identifier = functionExpression.operand as SimpleIdentifier;
    expect(identifier.name, 'f2');
    expect(functionExpression.operator.lexeme, '!');

    expect(expression.typeArguments!.arguments.length, 1);
    var typeArgument = expression.typeArguments!.arguments.single as NamedType;
    expect(typeArgument.name.name, "int");

    expect(expression.argumentList.arguments.length, 1);
    var argument = expression.argumentList.arguments.single as IntegerLiteral;
    expect(argument.value, 42);
  }

  void test_bangQuestionIndex() {
    // http://dartbug.com/41177
    CompilationUnit unit = parseCompilationUnit('f(dynamic a) { a!?[0]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;

    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpression;

    var index = expression.index as IntegerLiteral;
    expect(index.value, 0);

    var question = expression.question!;
    expect(question, isNotNull);
    expect(question.lexeme, "?");

    var target = expression.target as PostfixExpression;
    var identifier = target.operand as SimpleIdentifier;
    expect(identifier.name, 'a');
    expect(target.operator.lexeme, '!');
  }

  void test_binary_expression_statement() {
    final unit = parseCompilationUnit('D? foo(X? x) { X ?? x2; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as BinaryExpression;
    var lhs = expression.leftOperand as SimpleIdentifier;
    expect(lhs.name, 'X');
    expect(expression.operator.lexeme, '??');
    var rhs = expression.rightOperand as SimpleIdentifier;
    expect(rhs.name, 'x2');
  }

  void test_cascade_withNullCheck_indexExpression() {
    var unit = parseCompilationUnit('main() { a?..[27]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var cascade = statement.expression as CascadeExpression;
    var indexExpression = cascade.cascadeSections[0] as IndexExpression;
    expect(indexExpression.period!.lexeme, '?..');
    expect(indexExpression.toSource(), '?..[27]');
  }

  void test_cascade_withNullCheck_invalid() {
    parseCompilationUnit('main() { a..[27]?..x; }', errors: [
      expectedError(ParserErrorCode.NULL_AWARE_CASCADE_OUT_OF_ORDER, 16, 3),
    ]);
  }

  void test_cascade_withNullCheck_methodInvocation() {
    var unit = parseCompilationUnit('main() { a?..foo(); }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var cascade = statement.expression as CascadeExpression;
    var invocation = cascade.cascadeSections[0] as MethodInvocation;
    expect(invocation.operator!.lexeme, '?..');
    expect(invocation.toSource(), '?..foo()');
  }

  void test_cascade_withNullCheck_propertyAccess() {
    var unit = parseCompilationUnit('main() { a?..x27; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var cascade = statement.expression as CascadeExpression;
    var propertyAccess = cascade.cascadeSections[0] as PropertyAccess;
    expect(propertyAccess.operator.lexeme, '?..');
    expect(propertyAccess.toSource(), '?..x27');
  }

  void test_conditional() {
    parseCompilationUnit('D? foo(X? x) { X ? 7 : y; }');
  }

  void test_conditional_complex() {
    parseCompilationUnit('D? foo(X? x) { X ? x2 = x + bar(7) : y; }');
  }

  void test_conditional_error() {
    parseCompilationUnit('D? foo(X? x) { X ? ? x2 = x + bar(7) : y; }',
        errors: [
          expectedError(ParserErrorCode.MISSING_IDENTIFIER, 19, 1),
          expectedError(ParserErrorCode.EXPECTED_TOKEN, 40, 1),
          expectedError(ParserErrorCode.MISSING_IDENTIFIER, 40, 1),
        ]);
  }

  void test_conditional_simple() {
    parseCompilationUnit('D? foo(X? x) { X ? x2 = x : y; }');
  }

  void test_enableNonNullable_false() {
    parseCompilationUnit('main() { x is String? ? (x + y) : z; }',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 20, 1)],
        featureSet: preNonNullable);
  }

  void test_for() {
    parseCompilationUnit('main() { for(int x = 0; x < 7; ++x) { } }');
  }

  void test_for_conditional() {
    parseCompilationUnit('main() { for(x ? y = 7 : y = 8; y < 10; ++y) { } }');
  }

  void test_for_nullable() {
    parseCompilationUnit('main() { for(int? x = 0; x < 7; ++x) { } }');
  }

  void test_foreach() {
    parseCompilationUnit('main() { for(int x in [7]) { } }');
  }

  void test_foreach_nullable() {
    parseCompilationUnit('main() { for(int? x in [7, null]) { } }');
  }

  void test_functionTypedFormalParameter_nullable_disabled() {
    parseCompilationUnit('void f(void p()?) {}',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 15, 1)],
        featureSet: preNonNullable);
  }

  test_fuzz_38113() async {
    // https://github.com/dart-lang/sdk/issues/38113
    parseCompilationUnit(r'+t{{r?this}}', errors: [
      expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 0, 1),
      expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 1, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 6, 4),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 6, 4),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 10, 1),
    ]);
  }

  void test_gft_nullable() {
    parseCompilationUnit('main() { C? Function() x = 7; }');
  }

  void test_gft_nullable_1() {
    parseCompilationUnit('main() { C Function()? x = 7; }');
  }

  void test_gft_nullable_2() {
    parseCompilationUnit('main() { C? Function()? x = 7; }');
  }

  void test_gft_nullable_3() {
    parseCompilationUnit('main() { C? Function()? Function()? x = 7; }');
  }

  void test_gft_nullable_prefixed() {
    parseCompilationUnit('main() { C.a? Function()? x = 7; }');
  }

  void test_indexed() {
    CompilationUnit unit = parseCompilationUnit('main() { a[7]; }');
    var method = unit.declarations[0] as FunctionDeclaration;
    var body = method.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpression;
    expect(expression.leftBracket.lexeme, '[');
  }

  void test_indexed_nullAware() {
    CompilationUnit unit = parseCompilationUnit('main() { a?[7]; }');
    var method = unit.declarations[0] as FunctionDeclaration;
    var body = method.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpression;
    expect(expression.question, isNotNull);
    expect(expression.leftBracket.lexeme, '[');
    expect(expression.rightBracket.lexeme, ']');
    expect(expression.leftBracket.endGroup, expression.rightBracket);
  }

  void test_indexed_nullAware_optOut() {
    CompilationUnit unit = parseCompilationUnit('''
// @dart = 2.2
main() { a?[7]; }''',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 25, 1)]);
    var method = unit.declarations[0] as FunctionDeclaration;
    var body = method.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpressionImpl;
    expect(expression.target!.toSource(), 'a');
    expect(expression.question, isNotNull);
    expect(expression.leftBracket.lexeme, '[');
    expect(expression.rightBracket.lexeme, ']');
    expect(expression.leftBracket.endGroup, expression.rightBracket);
  }

  void test_indexExpression_nullable_disabled() {
    parseCompilationUnit('main(a) { a?[0]; }',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 11, 1)],
        featureSet: preNonNullable);
  }

  void test_is_nullable() {
    CompilationUnit unit =
        parseCompilationUnit('main() { x is String? ? (x + y) : z; }');
    var function = unit.declarations[0] as FunctionDeclaration;
    var body = function.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;

    var condition = expression.condition as IsExpression;
    expect((condition.type as NamedType).question, isNotNull);
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
  }

  void test_is_nullable_parenthesis() {
    CompilationUnit unit =
        parseCompilationUnit('main() { (x is String?) ? (x + y) : z; }');
    var function = unit.declarations[0] as FunctionDeclaration;
    var body = function.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;

    var condition = expression.condition as ParenthesizedExpression;
    var isExpression = condition.expression as IsExpression;
    expect((isExpression.type as NamedType).question, isNotNull);
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
  }

  void test_is_nullable_parenthesis_optOut() {
    parseCompilationUnit('''
// @dart = 2.2
main() { (x is String?) ? (x + y) : z; }
''', errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 36, 1)]);
  }

  void test_late_as_identifier() {
    parseCompilationUnit('''
class C {
  int late;
}

void f(C c) {
  print(c.late);
}

main() {
  f(new C());
}
''', featureSet: preNonNullable);
  }

  void test_late_as_identifier_optOut() {
    parseCompilationUnit('''
// @dart = 2.2
class C {
  int late;
}

void f(C c) {
  print(c.late);
}

main() {
  f(new C());
}
''');
  }

  void test_nullableTypeInInitializerList_01() {
    // http://dartbug.com/40834
    var unit = parseCompilationUnit(r'''
class Foo {
  String? x;
  int y;

  Foo(Object? o) : x = o as String?, y = 0;
}
''');
    var classDeclaration = unit.declarations.first as ClassDeclaration;
    var constructor =
        classDeclaration.getConstructor(null) as ConstructorDeclaration;

    // Object? o
    var parameter =
        constructor.parameters.parameters.single as SimpleFormalParameter;
    expect(parameter.identifier!.name, 'o');
    var type = parameter.type as NamedType;
    expect(type.question!.lexeme, '?');
    expect(type.name.name, 'Object');

    expect(constructor.initializers.length, 2);

    // o as String?
    {
      var initializer =
          constructor.initializers[0] as ConstructorFieldInitializer;
      expect(initializer.fieldName.name, 'x');
      var expression = initializer.expression as AsExpression;
      var identifier = expression.expression as SimpleIdentifier;
      expect(identifier.name, 'o');
      var expressionType = expression.type as NamedType;
      expect(expressionType.question!.lexeme, '?');
      expect(expressionType.name.name, 'String');
    }

    // y = 0
    {
      var initializer =
          constructor.initializers[1] as ConstructorFieldInitializer;
      expect(initializer.fieldName.name, 'y');
      var expression = initializer.expression as IntegerLiteral;
      expect(expression.value, 0);
    }
  }

  void test_nullableTypeInInitializerList_02() {
    var unit = parseCompilationUnit(r'''
class Foo {
  String? x;
  int y;

  Foo(Object? o) : y = o is String? ? o.length : null, x = null;
}
''');
    var classDeclaration = unit.declarations.first as ClassDeclaration;
    var constructor =
        classDeclaration.getConstructor(null) as ConstructorDeclaration;

    // Object? o
    var parameter =
        constructor.parameters.parameters.single as SimpleFormalParameter;
    expect(parameter.identifier!.name, 'o');
    var type = parameter.type as NamedType;
    expect(type.question!.lexeme, '?');
    expect(type.name.name, 'Object');

    expect(constructor.initializers.length, 2);

    // y = o is String? ? o.length : null
    {
      var initializer =
          constructor.initializers[0] as ConstructorFieldInitializer;
      expect(initializer.fieldName.name, 'y');
      var expression = initializer.expression as ConditionalExpression;
      var condition = expression.condition as IsExpression;
      var identifier = condition.expression as SimpleIdentifier;
      expect(identifier.name, 'o');
      var expressionType = condition.type as NamedType;
      expect(expressionType.question!.lexeme, '?');
      expect(expressionType.name.name, 'String');
      var thenExpression = expression.thenExpression as PrefixedIdentifier;
      expect(thenExpression.identifier.name, 'length');
      expect(thenExpression.prefix.name, 'o');
      var elseExpression = expression.elseExpression as NullLiteral;
      expect(elseExpression, isNotNull);
    }

    // x = null
    {
      var initializer =
          constructor.initializers[1] as ConstructorFieldInitializer;
      expect(initializer.fieldName.name, 'x');
      var expression = initializer.expression as NullLiteral;
      expect(expression, isNotNull);
    }
  }

  void test_nullableTypeInInitializerList_03() {
    // As test_nullableTypeInInitializerList_02 but without ? on String in is.
    var unit = parseCompilationUnit(r'''
class Foo {
  String? x;
  int y;

  Foo(Object? o) : y = o is String ? o.length : null, x = null;
}
''');
    var classDeclaration = unit.declarations.first as ClassDeclaration;
    var constructor =
        classDeclaration.getConstructor(null) as ConstructorDeclaration;

    // Object? o
    var parameter =
        constructor.parameters.parameters.single as SimpleFormalParameter;
    expect(parameter.identifier!.name, 'o');
    var type = parameter.type as NamedType;
    expect(type.question!.lexeme, '?');
    expect(type.name.name, 'Object');

    expect(constructor.initializers.length, 2);

    // y = o is String ? o.length : null
    {
      var initializer =
          constructor.initializers[0] as ConstructorFieldInitializer;
      expect(initializer.fieldName.name, 'y');
      var expression = initializer.expression as ConditionalExpression;
      var condition = expression.condition as IsExpression;
      var identifier = condition.expression as SimpleIdentifier;
      expect(identifier.name, 'o');
      var expressionType = condition.type as NamedType;
      expect(expressionType.question, isNull);
      expect(expressionType.name.name, 'String');
      var thenExpression = expression.thenExpression as PrefixedIdentifier;
      expect(thenExpression.identifier.name, 'length');
      expect(thenExpression.prefix.name, 'o');
      var elseExpression = expression.elseExpression as NullLiteral;
      expect(elseExpression, isNotNull);
    }

    // x = null
    {
      var initializer =
          constructor.initializers[1] as ConstructorFieldInitializer;
      expect(initializer.fieldName.name, 'x');
      var expression = initializer.expression as NullLiteral;
      expect(expression, isNotNull);
    }
  }

  void test_nullCheck() {
    var unit = parseCompilationUnit('f(int? y) { var x = y!; }');
    var function = unit.declarations[0] as FunctionDeclaration;
    var body = function.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as VariableDeclarationStatement;
    var expression =
        statement.variables.variables[0].initializer as PostfixExpression;
    var identifier = expression.operand as SimpleIdentifier;
    expect(identifier.name, 'y');
    expect(expression.operator.lexeme, '!');
  }

  void test_nullCheck_disabled() {
    var unit = parseCompilationUnit('f(int? y) { var x = y!; }',
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 5, 1),
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 21, 1),
        ],
        featureSet: preNonNullable);
    var function = unit.declarations[0] as FunctionDeclaration;
    var body = function.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as VariableDeclarationStatement;
    var identifier =
        statement.variables.variables[0].initializer as SimpleIdentifier;
    expect(identifier.name, 'y');
  }

  void test_nullCheckAfterGetterAccess() {
    parseCompilationUnit('f() { var x = g.x!.y + 7; }');
  }

  void test_nullCheckAfterMethodCall() {
    parseCompilationUnit('f() { var x = g.m()!.y + 7; }');
  }

  void test_nullCheckBeforeGetterAccess() {
    parseCompilationUnit('f() { var x = g!.x + 7; }');
  }

  void test_nullCheckBeforeIndex() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { foo.bar!.baz[arg]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpression;
    expect(expression.index.toSource(), 'arg');
    var propertyAccess = expression.target as PropertyAccess;
    expect(propertyAccess.propertyName.toSource(), 'baz');
    var target = propertyAccess.target as PostfixExpression;
    expect(target.operand.toSource(), 'foo.bar');
    expect(target.operator.lexeme, '!');
  }

  void test_nullCheckBeforeMethodCall() {
    parseCompilationUnit('f() { var x = g!.m() + 7; }');
  }

  void test_nullCheckFunctionResult() {
    parseCompilationUnit('f() { var x = g()! + 7; }');
  }

  void test_nullCheckIndexedValue() {
    parseCompilationUnit('f(int? y) { var x = y[0]! + 7; }');
  }

  void test_nullCheckIndexedValue2() {
    parseCompilationUnit('f(int? y) { var x = super.y[0]! + 7; }');
  }

  void test_nullCheckInExpression() {
    parseCompilationUnit('f(int? y) { var x = y! + 7; }');
  }

  void test_nullCheckInExpression_disabled() {
    parseCompilationUnit('f(int? y) { var x = y! + 7; }',
        errors: [
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 5, 1),
          expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 21, 1),
        ],
        featureSet: preNonNullable);
  }

  void test_nullCheckMethodResult() {
    parseCompilationUnit('f() { var x = g.m()! + 7; }');
  }

  void test_nullCheckMethodResult2() {
    parseCompilationUnit('f() { var x = g?.m()! + 7; }');
  }

  void test_nullCheckMethodResult3() {
    parseCompilationUnit('f() { var x = super.m()! + 7; }');
  }

  void test_nullCheckOnConstConstructor() {
    parseCompilationUnit('f() { var x = const Foo()!; }');
  }

  void test_nullCheckOnConstructor() {
    parseCompilationUnit('f() { var x = new Foo()!; }');
  }

  void test_nullCheckOnIndex() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { obj![arg]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpression;
    var target = expression.target as PostfixExpression;
    expect(target.operand.toSource(), 'obj');
    expect(target.operator.lexeme, '!');
  }

  void test_nullCheckOnIndex2() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { obj![arg]![arg2]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpression;
    expect(expression.index.toSource(), 'arg2');
    var target = expression.target as PostfixExpression;
    expect(target.operator.lexeme, '!');
    expression = target.operand as IndexExpression;
    expect(expression.index.toSource(), 'arg');
    target = expression.target as PostfixExpression;
    expect(target.operator.lexeme, '!');
    expect(target.operand.toSource(), 'obj');
  }

  void test_nullCheckOnIndex3() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { foo.bar![arg]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpression;
    expect(expression.index.toSource(), 'arg');
    var target = expression.target as PostfixExpression;
    expect(target.operand.toSource(), 'foo.bar');
    expect(target.operator.lexeme, '!');
  }

  void test_nullCheckOnIndex4() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { foo!.bar![arg]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpression;
    var fooBarTarget = expression.target as PostfixExpression;
    expect(fooBarTarget.toSource(), "foo!.bar!");
    var propertyAccess = fooBarTarget.operand as PropertyAccess;
    var targetFoo = propertyAccess.target as PostfixExpression;
    expect(targetFoo.operand.toSource(), "foo");
    expect(targetFoo.operator.lexeme, "!");
    expect(propertyAccess.propertyName.toSource(), "bar");
    expect(fooBarTarget.operator.lexeme, '!');
    expect(expression.index.toSource(), 'arg');
  }

  void test_nullCheckOnIndex5() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { foo.bar![arg]![arg2]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as IndexExpression;
    expect(expression.index.toSource(), 'arg2');
    var target = expression.target as PostfixExpression;
    expect(target.operator.lexeme, '!');
    expression = target.operand as IndexExpression;
    expect(expression.index.toSource(), 'arg');
    target = expression.target as PostfixExpression;
    expect(target.operator.lexeme, '!');
    expect(target.operand.toSource(), 'foo.bar');
  }

  void test_nullCheckOnIndex6() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { foo!.bar![arg]![arg2]; }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;

    // expression is "foo!.bar![arg]![arg2]"
    var expression = statement.expression as IndexExpression;
    expect(expression.index.toSource(), 'arg2');

    // target is "foo!.bar![arg]!"
    var target = expression.target as PostfixExpression;
    expect(target.operator.lexeme, '!');

    // expression is "foo!.bar![arg]"
    expression = target.operand as IndexExpression;
    expect(expression.index.toSource(), 'arg');

    // target is "foo!.bar!"
    target = expression.target as PostfixExpression;
    expect(target.operator.lexeme, '!');

    // propertyAccess is "foo!.bar"
    PropertyAccess propertyAccess = target.operand as PropertyAccess;
    expect(propertyAccess.propertyName.toSource(), "bar");

    // target is "foo!"
    target = propertyAccess.target as PostfixExpression;
    expect(target.operator.lexeme, '!');

    expect(target.operand.toSource(), "foo");
  }

  void test_nullCheckOnLiteral_disabled() {
    parseCompilationUnit('f() { var x = 0!; }',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 15, 1)],
        featureSet: preNonNullable);
  }

  void test_nullCheckOnLiteralDouble() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = 1.2!; }');
  }

  void test_nullCheckOnLiteralInt() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = 0!; }');
  }

  void test_nullCheckOnLiteralList() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = [1,2]!; }');
  }

  void test_nullCheckOnLiteralMap() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = {1:2}!; }');
  }

  void test_nullCheckOnLiteralSet() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = {1,2}!; }');
  }

  void test_nullCheckOnLiteralString() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = "seven"!; }');
  }

  void test_nullCheckOnNull() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = null!; }');
  }

  void test_nullCheckOnSend() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { obj!(arg); }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as FunctionExpressionInvocation;
    var target = expression.function as PostfixExpression;
    expect(target.operand.toSource(), 'obj');
    expect(target.operator.lexeme, '!');
  }

  void test_nullCheckOnSend2() {
    // https://github.com/dart-lang/sdk/issues/37708
    var unit = parseCompilationUnit('f() { obj!(arg)!(arg2); }');
    var funct = unit.declarations[0] as FunctionDeclaration;
    var body = funct.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var expression = statement.expression as FunctionExpressionInvocation;
    expect(expression.argumentList.toSource(), '(arg2)');
    var target = expression.function as PostfixExpression;
    expect(target.operator.lexeme, '!');
    expression = target.operand as FunctionExpressionInvocation;
    expect(expression.argumentList.toSource(), '(arg)');
    target = expression.function as PostfixExpression;
    expect(target.operator.lexeme, '!');
    expect(target.operand.toSource(), 'obj');
  }

  void test_nullCheckOnSymbol() {
    // Issues like this should be caught during later analysis
    parseCompilationUnit('f() { var x = #seven!; }');
  }

  void test_nullCheckOnValue() {
    parseCompilationUnit('f(Point p) { var x = p.y! + 7; }');
  }

  void test_nullCheckOnValue_disabled() {
    parseCompilationUnit('f(Point p) { var x = p.y! + 7; }',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 24, 1)],
        featureSet: preNonNullable);
  }

  void test_nullCheckParenthesizedExpression() {
    parseCompilationUnit('f(int? y) { var x = (y)! + 7; }');
  }

  void test_nullCheckPropertyAccess() {
    parseCompilationUnit('f() { var x = g.p! + 7; }');
  }

  void test_nullCheckPropertyAccess2() {
    parseCompilationUnit('f() { var x = g?.p! + 7; }');
  }

  void test_nullCheckPropertyAccess3() {
    parseCompilationUnit('f() { var x = super.p! + 7; }');
  }

  void test_postfix_null_assertion_and_unary_prefix_operator_precedence() {
    // -x! is parsed as -(x!).
    var unit = parseCompilationUnit('void main() { -x!; }');
    var function = unit.declarations[0] as FunctionDeclaration;
    var body = function.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var outerExpression = statement.expression as PrefixExpression;
    expect(outerExpression.operator.type, TokenType.MINUS);
    var innerExpression = outerExpression.operand as PostfixExpression;
    expect(innerExpression.operator.type, TokenType.BANG);
  }

  void test_postfix_null_assertion_of_postfix_expression() {
    // x++! is parsed as (x++)!.
    var unit = parseCompilationUnit('void main() { x++!; }');
    var function = unit.declarations[0] as FunctionDeclaration;
    var body = function.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var outerExpression = statement.expression as PostfixExpression;
    expect(outerExpression.operator.type, TokenType.BANG);
    var innerExpression = outerExpression.operand as PostfixExpression;
    expect(innerExpression.operator.type, TokenType.PLUS_PLUS);
  }

  void test_typeName_nullable_disabled() {
    parseCompilationUnit('int? x;',
        errors: [expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 3, 1)],
        featureSet: preNonNullable);
  }
}
