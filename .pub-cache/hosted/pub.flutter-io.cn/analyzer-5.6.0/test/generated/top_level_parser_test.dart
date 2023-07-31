// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/ast_type_matchers.dart';
import 'parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelParserTest);
  });
}

/// Tests which exercise the parser using a complete compilation unit or
/// compilation unit member.
@reflectiveTest
class TopLevelParserTest extends FastaParserTestCase {
  void test_function_literal_allowed_at_toplevel() {
    parseCompilationUnit("var x = () {};");
  }

  void
      test_function_literal_allowed_in_ArgumentList_in_ConstructorFieldInitializer() {
    parseCompilationUnit("class C { C() : a = f(() {}); }");
  }

  void
      test_function_literal_allowed_in_IndexExpression_in_ConstructorFieldInitializer() {
    parseCompilationUnit("class C { C() : a = x[() {}]; }");
  }

  void
      test_function_literal_allowed_in_ListLiteral_in_ConstructorFieldInitializer() {
    parseCompilationUnit("class C { C() : a = [() {}]; }");
  }

  void
      test_function_literal_allowed_in_MapLiteral_in_ConstructorFieldInitializer() {
    parseCompilationUnit("class C { C() : a = {'key': () {}}; }");
  }

  void
      test_function_literal_allowed_in_ParenthesizedExpression_in_ConstructorFieldInitializer() {
    parseCompilationUnit("class C { C() : a = (() {}); }");
  }

  void
      test_function_literal_allowed_in_StringInterpolation_in_ConstructorFieldInitializer() {
    parseCompilationUnit("class C { C() : a = \"\${(){}}\"; }");
  }

  void test_import_as_show() {
    parseCompilationUnit("import 'dart:math' as M show E;");
  }

  void test_import_show_hide() {
    parseCompilationUnit(
        "import 'import1_lib.dart' show hide, show hide ugly;");
  }

  void test_import_withDocComment() {
    var compilationUnit = parseCompilationUnit('/// Doc\nimport "foo.dart";');
    var importDirective = compilationUnit.directives[0];
    expectCommentText(importDirective.documentationComment, '/// Doc');
  }

  void test_parse_missing_type_in_list_at_eof() {
    createParser('Future<List<>>');

    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 12, 2),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 13, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 14, 0),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 14, 0),
    ]);

    expect(member, isTopLevelVariableDeclaration);
    var declaration = member as TopLevelVariableDeclaration;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);

    // Ensure type parsed as "Future<List<[empty name]>>".
    expect(declaration.variables.type, isNotNull);
    expect(declaration.variables.type!.question, isNull);
    expect(declaration.variables.type, TypeMatcher<NamedType>());
    var type = declaration.variables.type as NamedType;
    expect(type.name.name, "Future");
    expect(type.typeArguments!.arguments.length, 1);
    expect(type.typeArguments!.arguments.single, TypeMatcher<NamedType>());
    var subType = type.typeArguments!.arguments.single as NamedType;
    expect(subType.name.name, "List");
    expect(subType.typeArguments!.arguments.length, 1);
    expect(subType.typeArguments!.arguments.single, TypeMatcher<NamedType>());
    var subSubType = subType.typeArguments!.arguments.single as NamedType;
    expect(subSubType.name.name, "");
    expect(subSubType.typeArguments, isNull);
  }

  void test_parseClassDeclaration_abstract() {
    createParser('abstract class A {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    var declaration = member as ClassDeclaration;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNotNull);
    expect(declaration.extendsClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_empty() {
    createParser('class A {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    var declaration = member as ClassDeclaration;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_extends() {
    createParser('class A extends B {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    var declaration = member as ClassDeclaration;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNotNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_extendsAndImplements() {
    createParser('class A extends B implements C {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    var declaration = member as ClassDeclaration;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNotNull);
    expect(declaration.implementsClause, isNotNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_extendsAndWith() {
    createParser('class A extends B with C {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    var declaration = member as ClassDeclaration;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.typeParameters, isNull);
    expect(declaration.extendsClause, isNotNull);
    expect(declaration.withClause, isNotNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseClassDeclaration_extendsAndWithAndImplements() {
    createParser('class A extends B with C implements D {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    var declaration = member as ClassDeclaration;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.typeParameters, isNull);
    expect(declaration.extendsClause, isNotNull);
    expect(declaration.withClause, isNotNull);
    expect(declaration.implementsClause, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseClassDeclaration_implements() {
    createParser('class A implements C {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    var declaration = member as ClassDeclaration;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNull);
    expect(declaration.implementsClause, isNotNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_metadata() {
    createParser('@A @B(2) @C.foo(3) @d.E.bar(4, 5) class X {}');
    var declaration = parseFullCompilationUnitMember() as ClassDeclaration;
    expect(declaration.metadata, hasLength(4));

    {
      var annotation = declaration.metadata[0];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isSimpleIdentifier);
      expect(annotation.name.name, 'A');
      expect(annotation.period, isNull);
      expect(annotation.constructorName, isNull);
      expect(annotation.arguments, isNull);
    }

    {
      var annotation = declaration.metadata[1];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isSimpleIdentifier);
      expect(annotation.name.name, 'B');
      expect(annotation.period, isNull);
      expect(annotation.constructorName, isNull);
      expect(annotation.arguments, isNotNull);
      expect(annotation.arguments!.arguments, hasLength(1));
    }

    {
      var annotation = declaration.metadata[2];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isPrefixedIdentifier);
      expect(annotation.name.name, 'C.foo');
      expect(annotation.period, isNull);
      expect(annotation.constructorName, isNull);
      expect(annotation.arguments, isNotNull);
      expect(annotation.arguments!.arguments, hasLength(1));
    }

    {
      var annotation = declaration.metadata[3];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isPrefixedIdentifier);
      expect(annotation.name.name, 'd.E');
      expect(annotation.period, isNotNull);
      expect(annotation.constructorName, isNotNull);
      expect(annotation.constructorName!.name, 'bar');
      expect(annotation.arguments, isNotNull);
      expect(annotation.arguments!.arguments, hasLength(2));
    }
  }

  void test_parseClassDeclaration_native() {
    createParser('class A native "nativeValue" {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    if (!allowNativeClause) {
      assertErrorsWithCodes([
        ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION,
      ]);
    } else {
      assertNoErrors();
    }
    expect(member, isClassDeclaration);
    var declaration = member as ClassDeclaration;
    var nativeClause = declaration.nativeClause!;
    expect(nativeClause, isNotNull);
    expect(nativeClause.nativeKeyword, isNotNull);
    expect(nativeClause.name!.stringValue, "nativeValue");
    expect(nativeClause.beginToken, same(nativeClause.nativeKeyword));
    expect(nativeClause.endToken, same(nativeClause.name!.endToken));
  }

  void test_parseClassDeclaration_native_allowed() {
    allowNativeClause = true;
    test_parseClassDeclaration_native();
  }

  void test_parseClassDeclaration_native_allowedWithFields() {
    allowNativeClause = true;
    createParser(r'''
class A native 'something' {
  final int x;
  A() {}
}
''');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
  }

  void test_parseClassDeclaration_native_missing_literal() {
    createParser('class A native {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    if (allowNativeClause) {
      assertNoErrors();
    } else {
      assertErrorsWithCodes([
        ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION,
      ]);
    }
    expect(member, TypeMatcher<ClassDeclaration>());
    var declaration = member as ClassDeclaration;
    expect(declaration.nativeClause, isNotNull);
    expect(declaration.nativeClause!.nativeKeyword, isNotNull);
    expect(declaration.nativeClause!.name, isNull);
    expect(declaration.endToken.type, TokenType.CLOSE_CURLY_BRACKET);
  }

  void test_parseClassDeclaration_native_missing_literal_allowed() {
    allowNativeClause = true;
    test_parseClassDeclaration_native_missing_literal();
  }

  void test_parseClassDeclaration_native_missing_literal_not_allowed() {
    allowNativeClause = false;
    test_parseClassDeclaration_native_missing_literal();
  }

  void test_parseClassDeclaration_native_not_allowed() {
    allowNativeClause = false;
    test_parseClassDeclaration_native();
  }

  void test_parseClassDeclaration_nonEmpty() {
    createParser('class A {var f;}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    var declaration = member as ClassDeclaration;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(1));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_typeAlias_implementsC() {
    createParser('class A = Object with B implements C;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassTypeAlias);
    var typeAlias = member as ClassTypeAlias;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNotNull);
    expect(typeAlias.implementsClause!.implementsKeyword, isNotNull);
    expect(typeAlias.implementsClause!.interfaces.length, 1);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseClassDeclaration_typeAlias_withB() {
    createParser('class A = Object with B;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassTypeAlias);
    var typeAlias = member as ClassTypeAlias;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.withClause.withKeyword, isNotNull);
    expect(typeAlias.withClause.mixinTypes.length, 1);
    expect(typeAlias.implementsClause, isNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseClassDeclaration_typeParameters() {
    createParser('class A<B> {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    var declaration = member as ClassDeclaration;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNotNull);
    expect(declaration.typeParameters!.typeParameters, hasLength(1));
  }

  void test_parseClassDeclaration_typeParameters_extends_void() {
    parseCompilationUnit('class C<T extends void>{}',
        errors: [expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 18, 4)]);
  }

  void test_parseClassDeclaration_withDocumentationComment() {
    createParser('/// Doc\nclass C {}');
    var classDeclaration = parseFullCompilationUnitMember() as ClassDeclaration;
    expectCommentText(classDeclaration.documentationComment, '/// Doc');
  }

  void test_parseClassTypeAlias_withDocumentationComment() {
    createParser('/// Doc\nclass C = D with E;');
    var classTypeAlias = parseFullCompilationUnitMember() as ClassTypeAlias;
    expectCommentText(classTypeAlias.documentationComment, '/// Doc');
  }

  void test_parseCompilationUnit_abstractAsPrefix_parameterized() {
    var errorCodes = <ErrorCode>[];
    // This used to be deferred to later in the pipeline, but is now being
    // reported by the parser.
    errorCodes.add(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE);
    CompilationUnit unit = parseCompilationUnit(
        'abstract<dynamic> _abstract = new abstract.A();',
        codes: errorCodes);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_builtIn_asFunctionName() {
    for (Keyword keyword in Keyword.values) {
      if (keyword.isBuiltIn || keyword.isPseudo) {
        String lexeme = keyword.lexeme;
        if (lexeme == 'Function') continue;
        parseCompilationUnit('$lexeme(x) => 0;');
        parseCompilationUnit('class C {$lexeme(x) => 0;}');
      }
    }
  }

  void test_parseCompilationUnit_builtIn_asFunctionName_withTypeParameter() {
    for (Keyword keyword in Keyword.values) {
      if (keyword.isBuiltIn || keyword.isPseudo) {
        String lexeme = keyword.lexeme;
        if (lexeme == 'Function') continue;
        // The fasta type resolution phase will report an error
        // on type arguments on `dynamic` (e.g. `dynamic<int>`).
        parseCompilationUnit('$lexeme<T>(x) => 0;');
        parseCompilationUnit('class C {$lexeme<T>(x) => 0;}');
      }
    }
  }

  void test_parseCompilationUnit_builtIn_asGetter() {
    for (Keyword keyword in Keyword.values) {
      if (keyword.isBuiltIn || keyword.isPseudo) {
        String lexeme = keyword.lexeme;
        parseCompilationUnit('get $lexeme => 0;');
        parseCompilationUnit('class C {get $lexeme => 0;}');
      }
    }
  }

  void test_parseCompilationUnit_directives_multiple() {
    createParser("library l;\npart 'a.dart';");
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(2));
    expect(unit.declarations, hasLength(0));
  }

  void test_parseCompilationUnit_directives_single() {
    createParser('library l;');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(0));
  }

  void test_parseCompilationUnit_empty() {
    createParser('');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(0));
    expect(unit.beginToken, isNotNull);
    expect(unit.endToken, isNotNull);
    expect(unit.endToken.type, TokenType.EOF);
  }

  void test_parseCompilationUnit_exportAsPrefix() {
    createParser('export.A _export = new export.A();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_exportAsPrefix_parameterized() {
    createParser('export<dynamic> _export = new export.A();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    // This used to be deferred to later in the pipeline, but is now being
    // reported by the parser.
    assertErrorsWithCodes([CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE]);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_operatorAsPrefix_parameterized() {
    createParser('operator<dynamic> _operator = new operator.A();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    // This used to be deferred to later in the pipeline, but is now being
    // reported by the parser.
    assertErrorsWithCodes([CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE]);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_pseudo_asNamedType() {
    for (Keyword keyword in Keyword.values) {
      if (keyword.isPseudo) {
        String lexeme = keyword.lexeme;
        parseCompilationUnit('$lexeme f;');
        parseCompilationUnit('class C {$lexeme f;}');
        parseCompilationUnit('f($lexeme g) {}');
        parseCompilationUnit('f() {$lexeme g;}');
      }
    }
  }

  void test_parseCompilationUnit_pseudo_prefixed() {
    for (Keyword keyword in Keyword.values) {
      if (keyword.isPseudo) {
        String lexeme = keyword.lexeme;
        parseCompilationUnit('M.$lexeme f;');
        parseCompilationUnit('class C {M.$lexeme f;}');
      }
    }
  }

  void test_parseCompilationUnit_script() {
    createParser('#! /bin/dart');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNotNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(0));
  }

  void test_parseCompilationUnit_skipFunctionBody_withInterpolation() {
    ParserTestCase.parseFunctionBodies = false;
    createParser('f() { "\${n}"; }');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_topLevelDeclaration() {
    createParser('class A {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
    expect(unit.beginToken, isNotNull);
    expect(unit.beginToken.keyword, Keyword.CLASS);
    expect(unit.endToken, isNotNull);
    expect(unit.endToken.type, TokenType.EOF);
  }

  void test_parseCompilationUnit_typedefAsPrefix() {
    createParser('typedef.A _typedef = new typedef.A();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnitMember_abstractAsPrefix() {
    createParser('abstract.A _abstract = new abstract.A();');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isTopLevelVariableDeclaration);
    var declaration = member as TopLevelVariableDeclaration;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseCompilationUnitMember_class() {
    createParser('class A {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassDeclaration);
    var declaration = member as ClassDeclaration;
    expect(declaration.name.lexeme, "A");
    expect(declaration.members, hasLength(0));
  }

  void test_parseCompilationUnitMember_classTypeAlias() {
    createParser('abstract class A = B with C;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassTypeAlias);
    var declaration = member as ClassTypeAlias;
    expect(declaration.name.lexeme, "A");
    expect(declaration.abstractKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_constVariable() {
    createParser('const int x = 0;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isTopLevelVariableDeclaration);
    var declaration = member as TopLevelVariableDeclaration;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
    expect(declaration.variables.keyword!.lexeme, 'const');
  }

  void test_parseCompilationUnitMember_expressionFunctionBody_tokens() {
    createParser('f() => 0;');
    var f = parseFullCompilationUnitMember() as FunctionDeclaration;
    var body = f.functionExpression.body as ExpressionFunctionBody;
    expect(body.functionDefinition.lexeme, '=>');
    expect(body.semicolon!.lexeme, ';');
  }

  void test_parseCompilationUnitMember_finalVariable() {
    createParser('final x = 0;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isTopLevelVariableDeclaration);
    var declaration = member as TopLevelVariableDeclaration;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
    expect(declaration.variables.keyword!.lexeme, 'final');
  }

  void test_parseCompilationUnitMember_function_external_noType() {
    createParser('external f();');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_external_type() {
    createParser('external int f();');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_generic_noReturnType() {
    createParser('f<E>() {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.returnType, isNull);
    expect(declaration.functionExpression.typeParameters, isNotNull);
  }

  void
      test_parseCompilationUnitMember_function_generic_noReturnType_annotated() {
    createParser('f<@a E>() {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.returnType, isNull);
    expect(declaration.functionExpression.typeParameters, isNotNull);
  }

  void test_parseCompilationUnitMember_function_generic_returnType() {
    createParser('E f<E>() {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.returnType, isNotNull);
    expect(declaration.functionExpression.typeParameters, isNotNull);
  }

  void test_parseCompilationUnitMember_function_generic_void() {
    createParser('void f<T>(T t) {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_gftReturnType() {
    createParser('''
void Function<A>(core.List<core.int> x) f() => null;
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    assertNoErrors();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnitMember_function_noReturnType() {
    createParser('''
Function<A>(core.List<core.int> x) f() => null;
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    assertNoErrors();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnitMember_function_noType() {
    createParser('f() {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_type() {
    createParser('int f() {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_void() {
    createParser('void f() {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.returnType, isNotNull);
  }

  void test_parseCompilationUnitMember_getter_external_noType() {
    createParser('external get p;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_getter_external_type() {
    createParser('external int get p;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_getter_noType() {
    createParser('get p => 0;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_getter_type() {
    createParser('int get p => 0;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_setter_external_noType() {
    createParser('external set p(v);');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_setter_external_type() {
    createParser('external void set p(int v);');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_setter_noType() {
    createParser('set p(v) {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_setter_type() {
    createParser('void set p(int v) {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isFunctionDeclaration);
    var declaration = member as FunctionDeclaration;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
    expect(declaration.returnType, isNotNull);
  }

  void test_parseCompilationUnitMember_typeAlias_abstract() {
    createParser('abstract class C = S with M;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassTypeAlias);
    var typeAlias = member as ClassTypeAlias;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name.lexeme, "C");
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.equals, isNotNull);
    expect(typeAlias.abstractKeyword, isNotNull);
    expect(typeAlias.superclass.name.name, "S");
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseCompilationUnitMember_typeAlias_generic() {
    createParser('class C<E> = S<E> with M<E> implements I<E>;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassTypeAlias);
    var typeAlias = member as ClassTypeAlias;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name.lexeme, "C");
    expect(typeAlias.typeParameters!.typeParameters, hasLength(1));
    expect(typeAlias.equals, isNotNull);
    expect(typeAlias.abstractKeyword, isNull);
    expect(typeAlias.superclass.name.name, "S");
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseCompilationUnitMember_typeAlias_implements() {
    createParser('class C = S with M implements I;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassTypeAlias);
    var typeAlias = member as ClassTypeAlias;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name.lexeme, "C");
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.equals, isNotNull);
    expect(typeAlias.abstractKeyword, isNull);
    expect(typeAlias.superclass.name.name, "S");
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseCompilationUnitMember_typeAlias_noImplements() {
    createParser('class C = S with M;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isClassTypeAlias);
    var typeAlias = member as ClassTypeAlias;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name.lexeme, "C");
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.equals, isNotNull);
    expect(typeAlias.abstractKeyword, isNull);
    expect(typeAlias.superclass.name.name, "S");
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseCompilationUnitMember_typedef() {
    createParser('typedef F();');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, TypeMatcher<FunctionTypeAlias>());
    var typeAlias = member as FunctionTypeAlias;
    expect(typeAlias.name.lexeme, "F");
    expect(typeAlias.parameters.parameters, hasLength(0));
  }

  void test_parseCompilationUnitMember_typedef_withDocComment() {
    createParser('/// Doc\ntypedef F();');
    var typeAlias = parseFullCompilationUnitMember() as FunctionTypeAlias;
    expectCommentText(typeAlias.documentationComment, '/// Doc');
  }

  void test_parseCompilationUnitMember_typedVariable() {
    createParser('int x = 0;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isTopLevelVariableDeclaration);
    var declaration = member as TopLevelVariableDeclaration;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
    expect(declaration.variables.type, isNotNull);
    expect(declaration.variables.keyword, isNull);
  }

  void test_parseCompilationUnitMember_variable() {
    createParser('var x = 0;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isTopLevelVariableDeclaration);
    var declaration = member as TopLevelVariableDeclaration;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
    expect(declaration.variables.keyword!.lexeme, 'var');
  }

  void test_parseCompilationUnitMember_variable_gftType_gftReturnType() {
    createParser('''
Function(int) Function(String) v;
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    assertNoErrors();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
    TopLevelVariableDeclaration declaration =
        unit.declarations[0] as TopLevelVariableDeclaration;
    expect(declaration.variables.type, isGenericFunctionType);
  }

  void test_parseCompilationUnitMember_variable_gftType_noReturnType() {
    createParser('''
Function(int, String) v;
''');
    CompilationUnit unit = parser.parseCompilationUnit2();
    assertNoErrors();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnitMember_variable_withDocumentationComment() {
    createParser('/// Doc\nvar x = 0;');
    var declaration =
        parseFullCompilationUnitMember() as TopLevelVariableDeclaration;
    expectCommentText(declaration.documentationComment, '/// Doc');
  }

  void test_parseCompilationUnitMember_variableGet() {
    createParser('String get = null;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isTopLevelVariableDeclaration);
    var declaration = member as TopLevelVariableDeclaration;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseCompilationUnitMember_variableSet() {
    createParser('String set = null;');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
    expect(member, isTopLevelVariableDeclaration);
    var declaration = member as TopLevelVariableDeclaration;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseDirective_export() {
    createParser("export 'lib/lib.dart';");
    Directive directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive, TypeMatcher<ExportDirective>());
    var exportDirective = directive as ExportDirective;
    expect(exportDirective.exportKeyword, isNotNull);
    expect(exportDirective.uri, isNotNull);
    expect(exportDirective.combinators, hasLength(0));
    expect(exportDirective.semicolon, isNotNull);
  }

  void test_parseDirective_export_withDocComment() {
    createParser("/// Doc\nexport 'foo.dart';");
    var directive = parseFullDirective() as ExportDirective;
    expectCommentText(directive.documentationComment, '/// Doc');
  }

  void test_parseDirective_import() {
    createParser("import 'lib/lib.dart';");
    Directive directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive, TypeMatcher<ImportDirective>());
    var importDirective = directive as ImportDirective;
    expect(importDirective.importKeyword, isNotNull);
    expect(importDirective.uri, isNotNull);
    expect(importDirective.asKeyword, isNull);
    expect(importDirective.prefix, isNull);
    expect(importDirective.combinators, hasLength(0));
    expect(importDirective.semicolon, isNotNull);
  }

  void test_parseDirective_library() {
    createParser("library l;");
    Directive directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive, TypeMatcher<LibraryDirective>());
    var libraryDirective = directive as LibraryDirective;
    expect(libraryDirective.libraryKeyword, isNotNull);
    expect(libraryDirective.name2, isNotNull);
    expect(libraryDirective.semicolon, isNotNull);
  }

  void test_parseDirective_library_1_component() {
    createParser("library a;");
    var lib = parseFullDirective() as LibraryDirective;
    expect(lib.name2!.components, hasLength(1));
    expect(lib.name2!.components[0].name, 'a');
  }

  void test_parseDirective_library_2_components() {
    createParser("library a.b;");
    var lib = parseFullDirective() as LibraryDirective;
    expect(lib.name2!.components, hasLength(2));
    expect(lib.name2!.components[0].name, 'a');
    expect(lib.name2!.components[1].name, 'b');
  }

  void test_parseDirective_library_3_components() {
    createParser("library a.b.c;");
    var lib = parseFullDirective() as LibraryDirective;
    expect(lib.name2!.components, hasLength(3));
    expect(lib.name2!.components[0].name, 'a');
    expect(lib.name2!.components[1].name, 'b');
    expect(lib.name2!.components[2].name, 'c');
  }

  void test_parseDirective_library_annotation() {
    createParser("@A library l;");
    Directive directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive, TypeMatcher<LibraryDirective>());
    var libraryDirective = directive as LibraryDirective;
    expect(libraryDirective.libraryKeyword, isNotNull);
    expect(libraryDirective.name2, isNotNull);
    expect(libraryDirective.semicolon, isNotNull);
    expect(libraryDirective.metadata, hasLength(1));
    expect(libraryDirective.metadata[0].name.name, 'A');
  }

  void test_parseDirective_library_annotation2() {
    createParser("@A library l;");
    CompilationUnit unit = parser.parseCompilationUnit2();
    Directive directive = unit.directives[0];
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive, TypeMatcher<LibraryDirective>());
    var libraryDirective = directive as LibraryDirective;
    expect(libraryDirective.libraryKeyword, isNotNull);
    expect(libraryDirective.name2, isNotNull);
    expect(libraryDirective.semicolon, isNotNull);
    expect(libraryDirective.metadata, hasLength(1));
    expect(libraryDirective.metadata[0].name.name, 'A');
  }

  void test_parseDirective_library_unnamed() {
    createParser("library;");
    var lib = parseFullDirective() as LibraryDirective;
    expect(lib.name2, isNull);
  }

  void test_parseDirective_library_withDocumentationComment() {
    createParser('/// Doc\nlibrary l;');
    var directive = parseFullDirective() as LibraryDirective;
    expectCommentText(directive.documentationComment, '/// Doc');
  }

  void test_parseDirective_part() {
    createParser("part 'lib/lib.dart';");
    Directive directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive, TypeMatcher<PartDirective>());
    var partDirective = directive as PartDirective;
    expect(partDirective.partKeyword, isNotNull);
    expect(partDirective.uri, isNotNull);
    expect(partDirective.semicolon, isNotNull);
  }

  void test_parseDirective_part_of_1_component() {
    createParser("part of a;");
    var partOf = parseFullDirective() as PartOfDirective;
    expect(partOf.libraryName!.components, hasLength(1));
    expect(partOf.libraryName!.components[0].name, 'a');
  }

  void test_parseDirective_part_of_2_components() {
    createParser("part of a.b;");
    var partOf = parseFullDirective() as PartOfDirective;
    expect(partOf.libraryName!.components, hasLength(2));
    expect(partOf.libraryName!.components[0].name, 'a');
    expect(partOf.libraryName!.components[1].name, 'b');
  }

  void test_parseDirective_part_of_3_components() {
    createParser("part of a.b.c;");
    var partOf = parseFullDirective() as PartOfDirective;
    expect(partOf.libraryName!.components, hasLength(3));
    expect(partOf.libraryName!.components[0].name, 'a');
    expect(partOf.libraryName!.components[1].name, 'b');
    expect(partOf.libraryName!.components[2].name, 'c');
  }

  void test_parseDirective_part_of_withDocumentationComment() {
    createParser('/// Doc\npart of a;');
    var partOf = parseFullDirective() as PartOfDirective;
    expectCommentText(partOf.documentationComment, '/// Doc');
  }

  void test_parseDirective_part_withDocumentationComment() {
    createParser("/// Doc\npart 'lib.dart';");
    var directive = parseFullDirective() as PartDirective;
    expectCommentText(directive.documentationComment, '/// Doc');
  }

  void test_parseDirective_partOf() {
    createParser("part of l;");
    Directive directive = parseFullDirective();
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive, TypeMatcher<PartOfDirective>());
    var partOfDirective = directive as PartOfDirective;
    expect(partOfDirective.partKeyword, isNotNull);
    expect(partOfDirective.ofKeyword, isNotNull);
    expect(partOfDirective.libraryName, isNotNull);
    expect(partOfDirective.semicolon, isNotNull);
  }

  void test_parseDirectives_annotations() {
    CompilationUnit unit =
        parseDirectives("@A library l; @B import 'foo.dart';");
    expect(unit.directives, hasLength(2));
    expect(unit.directives[0].metadata[0].name.name, 'A');
    expect(unit.directives[1].metadata[0].name.name, 'B');
  }

  void test_parseDirectives_complete() {
    CompilationUnit unit =
        parseDirectives("#! /bin/dart\nlibrary l;\nclass A {}");
    expect(unit.scriptTag, isNotNull);
    expect(unit.directives, hasLength(1));
  }

  void test_parseDirectives_empty() {
    CompilationUnit unit = parseDirectives("");
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
  }

  void test_parseDirectives_mixed() {
    CompilationUnit unit =
        parseDirectives("library l; class A {} part 'foo.dart';");
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(1));
  }

  void test_parseDirectives_multiple() {
    CompilationUnit unit = parseDirectives("library l;\npart 'a.dart';");
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(2));
  }

  void test_parseDirectives_script() {
    CompilationUnit unit = parseDirectives("#! /bin/dart");
    expect(unit.scriptTag, isNotNull);
    expect(unit.directives, hasLength(0));
  }

  void test_parseDirectives_single() {
    CompilationUnit unit = parseDirectives("library l;");
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(1));
  }

  void test_parseDirectives_topLevelDeclaration() {
    CompilationUnit unit = parseDirectives("class A {}");
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
  }

  void test_parseEnumDeclaration_one() {
    createParser("enum E {ONE}");
    var declaration = parseFullCompilationUnitMember() as EnumDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.documentationComment, isNull);
    expect(declaration.enumKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.constants, hasLength(1));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseEnumDeclaration_trailingComma() {
    createParser("enum E {ONE,}");
    var declaration = parseFullCompilationUnitMember() as EnumDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.documentationComment, isNull);
    expect(declaration.enumKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.constants, hasLength(1));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseEnumDeclaration_two() {
    createParser("enum E {ONE, TWO}");
    var declaration = parseFullCompilationUnitMember() as EnumDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.documentationComment, isNull);
    expect(declaration.enumKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.constants, hasLength(2));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseEnumDeclaration_withDocComment_onEnum() {
    createParser('/// Doc\nenum E {ONE}');
    var declaration = parseFullCompilationUnitMember() as EnumDeclaration;
    expectCommentText(declaration.documentationComment, '/// Doc');
  }

  void test_parseEnumDeclaration_withDocComment_onValue() {
    createParser('''
enum E {
  /// Doc
  ONE
}''');
    var declaration = parseFullCompilationUnitMember() as EnumDeclaration;
    var value = declaration.constants[0];
    expectCommentText(value.documentationComment, '/// Doc');
  }

  void test_parseEnumDeclaration_withDocComment_onValue_annotated() {
    createParser('''
enum E {
  /// Doc
  @annotation
  ONE
}
''');
    var declaration = parseFullCompilationUnitMember() as EnumDeclaration;
    var value = declaration.constants[0];
    expectCommentText(value.documentationComment, '/// Doc');
    expect(value.metadata, hasLength(1));
  }

  void test_parseExportDirective_configuration_multiple() {
    createParser("export 'lib/lib.dart' if (a) 'b.dart' if (c) 'd.dart';");
    var directive = parseFullDirective() as ExportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.exportKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.configurations, hasLength(2));
    expectDottedName(directive.configurations[0].name, ['a']);
    expectDottedName(directive.configurations[1].name, ['c']);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_configuration_single() {
    createParser("export 'lib/lib.dart' if (a.b == 'c.dart') '';");
    var directive = parseFullDirective() as ExportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.exportKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.configurations, hasLength(1));
    expectDottedName(directive.configurations[0].name, ['a', 'b']);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_hide() {
    createParser("export 'lib/lib.dart' hide A, B;");
    var directive = parseFullDirective() as ExportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.exportKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_hide_show() {
    createParser("export 'lib/lib.dart' hide A show B;");
    var directive = parseFullDirective() as ExportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.exportKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_noCombinator() {
    createParser("export 'lib/lib.dart';");
    var directive = parseFullDirective() as ExportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.exportKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_show() {
    createParser("export 'lib/lib.dart' show A, B;");
    var directive = parseFullDirective() as ExportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.exportKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_show_hide() {
    createParser("export 'lib/lib.dart' show B hide A;");
    var directive = parseFullDirective() as ExportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.exportKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseFunctionDeclaration_function() {
    createParser('/// Doc\nT f() {}');
    var declaration = parseFullCompilationUnitMember() as FunctionDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expectCommentText(declaration.documentationComment, '/// Doc');
    expect((declaration.returnType as NamedType).name.name, 'T');
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNull);
    expect(expression.parameters, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseFunctionDeclaration_functionWithTypeParameters() {
    createParser('/// Doc\nT f<E>() {}');
    var declaration = parseFullCompilationUnitMember() as FunctionDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expectCommentText(declaration.documentationComment, '/// Doc');
    expect((declaration.returnType as NamedType).name.name, 'T');
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNotNull);
    expect(expression.parameters, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseFunctionDeclaration_getter() {
    createParser('/// Doc\nT get p => 0;');
    var declaration = parseFullCompilationUnitMember() as FunctionDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expectCommentText(declaration.documentationComment, '/// Doc');
    expect((declaration.returnType as NamedType).name.name, 'T');
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNull);
    expect(expression.parameters, isNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseFunctionDeclaration_metadata() {
    createParser(
        'T f(@A a, @B(2) Foo b, {@C.foo(3) c : 0, @d.E.bar(4, 5) x:0}) {}');
    var declaration = parseFullCompilationUnitMember() as FunctionDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.documentationComment, isNull);
    expect((declaration.returnType as NamedType).name.name, 'T');
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNull);
    NodeList<FormalParameter> parameters = expression.parameters!.parameters;
    expect(parameters, hasLength(4));
    expect(declaration.propertyKeyword, isNull);

    {
      var annotation = parameters[0].metadata[0];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isSimpleIdentifier);
      expect(annotation.name.name, 'A');
      expect(annotation.period, isNull);
      expect(annotation.constructorName, isNull);
      expect(annotation.arguments, isNull);
    }

    {
      var annotation = parameters[1].metadata[0];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isSimpleIdentifier);
      expect(annotation.name.name, 'B');
      expect(annotation.period, isNull);
      expect(annotation.constructorName, isNull);
      expect(annotation.arguments, isNotNull);
      expect(annotation.arguments!.arguments, hasLength(1));
    }

    {
      var annotation = parameters[2].metadata[0];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isPrefixedIdentifier);
      expect(annotation.name.name, 'C.foo');
      expect(annotation.period, isNull);
      expect(annotation.constructorName, isNull);
      expect(annotation.arguments, isNotNull);
      expect(annotation.arguments!.arguments, hasLength(1));
    }

    {
      var annotation = parameters[3].metadata[0];
      expect(annotation.atSign, isNotNull);
      expect(annotation.name, isPrefixedIdentifier);
      expect(annotation.name.name, 'd.E');
      expect(annotation.period, isNotNull);
      expect(annotation.constructorName, isNotNull);
      expect(annotation.constructorName!.name, 'bar');
      expect(annotation.arguments, isNotNull);
      expect(annotation.arguments!.arguments, hasLength(2));
    }
  }

  void test_parseFunctionDeclaration_setter() {
    createParser('/// Doc\nT set p(v) {}');
    var declaration = parseFullCompilationUnitMember() as FunctionDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expectCommentText(declaration.documentationComment, '/// Doc');
    expect((declaration.returnType as NamedType).name.name, 'T');
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNull);
    expect(expression.parameters, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseGenericTypeAlias_noTypeParameters() {
    createParser('typedef F = int Function(int);');
    var alias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.lexeme, 'F');
    expect(alias.typeParameters, isNull);
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters() {
    createParser('typedef F<T> = T Function(T);');
    var alias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.lexeme, 'F');
    expect(alias.typeParameters!.typeParameters, hasLength(1));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters2() {
    // The scanner creates a single token for `>=`
    // then the parser must split it into two separate tokens.
    createParser('typedef F<T>= T Function(T);');
    var alias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.lexeme, 'F');
    expect(alias.typeParameters!.typeParameters, hasLength(1));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters3() {
    createParser('typedef F<A,B,C> = Function(A a, B b, C c);');
    var alias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.lexeme, 'F');
    expect(alias.typeParameters!.typeParameters, hasLength(3));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters3_gtEq() {
    // The scanner creates a single token for `>=`
    // then the parser must split it into two separate tokens.
    createParser('typedef F<A,B,C>=Function(A a, B b, C c);');
    var alias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.lexeme, 'F');
    expect(alias.typeParameters!.typeParameters, hasLength(3));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters_extends() {
    createParser('typedef F<A,B,C extends D<E>> = Function(A a, B b, C c);');
    var alias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.lexeme, 'F');
    expect(alias.typeParameters!.typeParameters, hasLength(3));
    TypeParameter typeParam = alias.typeParameters!.typeParameters[2];
    var type = typeParam.bound as NamedType;
    expect(type.typeArguments!.arguments, hasLength(1));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters_extends3() {
    createParser(
        'typedef F<A,B,C extends D<E,G,H>> = Function(A a, B b, C c);');
    var alias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.lexeme, 'F');
    expect(alias.typeParameters!.typeParameters, hasLength(3));
    TypeParameter typeParam = alias.typeParameters!.typeParameters[2];
    var type = typeParam.bound as NamedType;
    expect(type.typeArguments!.arguments, hasLength(3));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters_extends3_gtGtEq() {
    // The scanner creates a single token for `>>=`
    // then the parser must split it into three separate tokens.
    createParser('typedef F<A,B,C extends D<E,G,H>>=Function(A a, B b, C c);');
    var alias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.lexeme, 'F');
    expect(alias.typeParameters!.typeParameters, hasLength(3));
    TypeParameter typeParam = alias.typeParameters!.typeParameters[2];
    var type = typeParam.bound as NamedType;
    expect(type.typeArguments!.arguments, hasLength(3));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_typeParameters_extends_gtGtEq() {
    // The scanner creates a single token for `>>=`
    // then the parser must split it into three separate tokens.
    createParser('typedef F<A,B,C extends D<E>>=Function(A a, B b, C c);');
    var alias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(alias, isNotNull);
    assertNoErrors();
    expect(alias.name, isNotNull);
    expect(alias.name.lexeme, 'F');
    expect(alias.typeParameters!.typeParameters, hasLength(3));
    TypeParameter typeParam = alias.typeParameters!.typeParameters[2];
    var type = typeParam.bound as NamedType;
    expect(type.typeArguments!.arguments, hasLength(1));
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_TypeParametersInProgress1() {
    createParser('typedef F< = int Function(int);');
    GenericTypeAlias alias =
        parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(alias, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 11, 1),
    ]);
    expect(alias.name, isNotNull);
    expect(alias.name.lexeme, 'F');
    expect(alias.typeParameters, isNotNull);
    expect(alias.typeParameters!.typeParameters.length, 1);
    expect(alias.typeParameters!.typeParameters.single.name.lexeme, '');
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_TypeParametersInProgress2() {
    createParser('typedef F<>= int Function(int);');
    GenericTypeAlias alias =
        parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(alias, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 10, 2),
    ]);
    expect(alias.name, isNotNull);
    expect(alias.name.lexeme, 'F');
    expect(alias.typeParameters, isNotNull);
    expect(alias.typeParameters!.typeParameters.length, 1);
    expect(alias.typeParameters!.typeParameters.single.name.lexeme, '');
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseGenericTypeAlias_TypeParametersInProgress3() {
    createParser('typedef F<> = int Function(int);');
    GenericTypeAlias alias =
        parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(alias, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 10, 1),
    ]);
    expect(alias.name, isNotNull);
    expect(alias.name.lexeme, 'F');
    expect(alias.typeParameters, isNotNull);
    expect(alias.typeParameters!.typeParameters.length, 1);
    expect(alias.typeParameters!.typeParameters.single.name.lexeme, '');
    expect(alias.equals, isNotNull);
    expect(alias.functionType, isNotNull);
    expect(alias.semicolon, isNotNull);
  }

  void test_parseImportDirective_configuration_multiple() {
    createParser("import 'lib/lib.dart' if (a) 'b.dart' if (c) 'd.dart';");
    var directive = parseFullDirective() as ImportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.importKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.configurations, hasLength(2));
    expectDottedName(directive.configurations[0].name, ['a']);
    expectDottedName(directive.configurations[1].name, ['c']);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_configuration_single() {
    createParser("import 'lib/lib.dart' if (a.b == 'c.dart') '';");
    var directive = parseFullDirective() as ImportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.importKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.configurations, hasLength(1));
    expectDottedName(directive.configurations[0].name, ['a', 'b']);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_deferred() {
    createParser("import 'lib/lib.dart' deferred as a;");
    var directive = parseFullDirective() as ImportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.importKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNotNull);
    expect(directive.asKeyword, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_hide() {
    createParser("import 'lib/lib.dart' hide A, B;");
    var directive = parseFullDirective() as ImportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.importKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_noCombinator() {
    createParser("import 'lib/lib.dart';");
    var directive = parseFullDirective() as ImportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.importKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_prefix() {
    createParser("import 'lib/lib.dart' as a;");
    var directive = parseFullDirective() as ImportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.importKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_prefix_hide_show() {
    createParser("import 'lib/lib.dart' as a hide A show B;");
    var directive = parseFullDirective() as ImportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.importKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_prefix_show_hide() {
    createParser("import 'lib/lib.dart' as a show B hide A;");
    var directive = parseFullDirective() as ImportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.importKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_show() {
    createParser("import 'lib/lib.dart' show A, B;");
    var directive = parseFullDirective() as ImportDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.importKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseLibraryDirective() {
    createParser('library l;');
    var directive = parseFullDirective() as LibraryDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.libraryKeyword, isNotNull);
    expect(directive.name2, isNotNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parseMixinDeclaration_empty() {
    createParser('mixin A {}');
    var declaration = parseFullCompilationUnitMember() as MixinDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.metadata, isEmpty);
    expect(declaration.documentationComment, isNull);
    expect(declaration.onClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.lexeme, 'A');
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_implements() {
    createParser('mixin A implements B {}');
    var declaration = parseFullCompilationUnitMember() as MixinDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.metadata, isEmpty);
    expect(declaration.documentationComment, isNull);
    expect(declaration.onClause, isNull);
    var implementsClause = declaration.implementsClause!;
    expect(implementsClause.implementsKeyword, isNotNull);
    NodeList<NamedType> interfaces = implementsClause.interfaces;
    expect(interfaces, hasLength(1));
    expect(interfaces[0].name.name, 'B');
    expect(interfaces[0].typeArguments, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.lexeme, 'A');
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_implements2() {
    createParser('mixin A implements B<T>, C {}');
    var declaration = parseFullCompilationUnitMember() as MixinDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.metadata, isEmpty);
    expect(declaration.documentationComment, isNull);
    expect(declaration.onClause, isNull);
    var implementsClause = declaration.implementsClause!;
    expect(implementsClause.implementsKeyword, isNotNull);
    NodeList<NamedType> interfaces = implementsClause.interfaces;
    expect(interfaces, hasLength(2));
    expect(interfaces[0].name.name, 'B');
    expect(interfaces[0].typeArguments!.arguments, hasLength(1));
    expect(interfaces[1].name.name, 'C');
    expect(interfaces[1].typeArguments, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.lexeme, 'A');
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_metadata() {
    createParser('@Z mixin A {}');
    var declaration = parseFullCompilationUnitMember() as MixinDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    NodeList<Annotation> metadata = declaration.metadata;
    expect(metadata, hasLength(1));
    expect(metadata[0].name.name, 'Z');
    expect(declaration.documentationComment, isNull);
    expect(declaration.onClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.lexeme, 'A');
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_on() {
    createParser('mixin A on B {}');
    var declaration = parseFullCompilationUnitMember() as MixinDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.metadata, isEmpty);
    expect(declaration.documentationComment, isNull);
    var onClause = declaration.onClause!;
    expect(onClause.onKeyword, isNotNull);
    NodeList<NamedType> constraints = onClause.superclassConstraints;
    expect(constraints, hasLength(1));
    expect(constraints[0].name.name, 'B');
    expect(constraints[0].typeArguments, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.lexeme, 'A');
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_on2() {
    createParser('mixin A on B, C<T> {}');
    var declaration = parseFullCompilationUnitMember() as MixinDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.metadata, isEmpty);
    expect(declaration.documentationComment, isNull);
    var onClause = declaration.onClause!;
    expect(onClause.onKeyword, isNotNull);
    NodeList<NamedType> constraints = onClause.superclassConstraints;
    expect(constraints, hasLength(2));
    expect(constraints[0].name.name, 'B');
    expect(constraints[0].typeArguments, isNull);
    expect(constraints[1].name.name, 'C');
    expect(constraints[1].typeArguments!.arguments, hasLength(1));
    expect(declaration.implementsClause, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.lexeme, 'A');
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_onAndImplements() {
    createParser('mixin A on B implements C {}');
    var declaration = parseFullCompilationUnitMember() as MixinDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.metadata, isEmpty);
    expect(declaration.documentationComment, isNull);
    var onClause = declaration.onClause!;
    expect(onClause.onKeyword, isNotNull);
    NodeList<NamedType> constraints = onClause.superclassConstraints;
    expect(constraints, hasLength(1));
    expect(constraints[0].name.name, 'B');
    expect(constraints[0].typeArguments, isNull);
    var implementsClause = declaration.implementsClause!;
    expect(implementsClause.implementsKeyword, isNotNull);
    NodeList<NamedType> interfaces = implementsClause.interfaces;
    expect(interfaces, hasLength(1));
    expect(interfaces[0].name.name, 'C');
    expect(interfaces[0].typeArguments, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.lexeme, 'A');
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_simple() {
    createParser('''
mixin A {
  int f;
  int get g => f;
  set s(int v) {f = v;}
  int add(int v) => f = f + v;
}''');
    var declaration = parseFullCompilationUnitMember() as MixinDeclaration;
    expect(declaration, isNotNull);
    assertNoErrors();
    expect(declaration.metadata, isEmpty);
    expect(declaration.documentationComment, isNull);
    expect(declaration.onClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.mixinKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name.lexeme, 'A');
    expect(declaration.members, hasLength(4));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseMixinDeclaration_withDocumentationComment() {
    createParser('/// Doc\nmixin M {}');
    var declaration = parseFullCompilationUnitMember() as MixinDeclaration;
    expectCommentText(declaration.documentationComment, '/// Doc');
  }

  void test_parsePartDirective() {
    createParser("part 'lib/lib.dart';");
    var directive = parseFullDirective() as PartDirective;
    expect(directive, isNotNull);
    assertNoErrors();
    expect(directive.partKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parsePartOfDirective_name() {
    enableUriInPartOf = true;
    createParser("part of l;");
    var directive = parseFullDirective() as PartOfDirective;
    expect(directive.partKeyword, isNotNull);
    expect(directive.ofKeyword, isNotNull);
    expect(directive.libraryName, isNotNull);
    expect(directive.uri, isNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parsePartOfDirective_uri() {
    enableUriInPartOf = true;
    createParser("part of 'lib.dart';");
    var directive = parseFullDirective() as PartOfDirective;
    expect(directive.partKeyword, isNotNull);
    expect(directive.ofKeyword, isNotNull);
    expect(directive.libraryName, isNull);
    expect(directive.uri, isNotNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parseTopLevelVariable_external() {
    var unit = parseCompilationUnit('external int i;');
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    expect(declaration.externalKeyword, isNotNull);
  }

  void test_parseTopLevelVariable_external_late() {
    var unit = parseCompilationUnit('external late int? i;', errors: [
      expectedError(ParserErrorCode.EXTERNAL_LATE_FIELD, 0, 8),
    ]);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    expect(declaration.externalKeyword, isNotNull);
  }

  void test_parseTopLevelVariable_external_late_final() {
    var unit = parseCompilationUnit('external late final int? i;', errors: [
      expectedError(ParserErrorCode.EXTERNAL_LATE_FIELD, 0, 8),
    ]);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    expect(declaration.externalKeyword, isNotNull);
  }

  void test_parseTopLevelVariable_final_late() {
    var unit = parseCompilationUnit('final late a;',
        errors: [expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 6, 4)]);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    var declarationList = declaration.variables;
    expect(declarationList.keyword!.lexeme, 'final');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseTopLevelVariable_late() {
    var unit = parseCompilationUnit('late a;', errors: [
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 5, 1)
    ]);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    var declarationList = declaration.variables;
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseTopLevelVariable_late_final() {
    var unit = parseCompilationUnit('late final a;');
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    var declarationList = declaration.variables;
    expect(declarationList.keyword!.lexeme, 'final');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseTopLevelVariable_late_init() {
    var unit = parseCompilationUnit('late a = 0;', errors: [
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 5, 1)
    ]);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    var declarationList = declaration.variables;
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseTopLevelVariable_late_type() {
    var unit = parseCompilationUnit('late A a;');
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    var declarationList = declaration.variables;
    expect(declarationList.lateKeyword, isNotNull);
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseTopLevelVariable_non_external() {
    var unit = parseCompilationUnit('int i;');
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    expect(declaration.externalKeyword, isNull);
  }

  void test_parseTypeAlias_function_noParameters() {
    createParser('typedef bool F();');
    var typeAlias = parseFullCompilationUnitMember() as FunctionTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_noReturnType() {
    createParser('typedef F();');
    var typeAlias = parseFullCompilationUnitMember() as FunctionTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_parameterizedReturnType() {
    createParser('typedef A<B> F();');
    var typeAlias = parseFullCompilationUnitMember() as FunctionTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_parameters() {
    createParser('typedef bool F(Object value);');
    var typeAlias = parseFullCompilationUnitMember() as FunctionTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_typeParameters() {
    createParser('typedef bool F<E>();');
    var typeAlias = parseFullCompilationUnitMember() as FunctionTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
  }

  void test_parseTypeAlias_function_voidReturnType() {
    createParser('typedef void F();');
    var typeAlias = parseFullCompilationUnitMember() as FunctionTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_noParameters() {
    createParser('typedef F = bool Function();');
    var typeAlias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.semicolon, isNotNull);
    var functionType = typeAlias.functionType as GenericFunctionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_noReturnType() {
    createParser('typedef F = Function();');
    var typeAlias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.semicolon, isNotNull);
    var functionType = typeAlias.functionType as GenericFunctionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_parameterizedReturnType() {
    createParser('typedef F = A<B> Function();');
    var typeAlias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.semicolon, isNotNull);
    var functionType = typeAlias.functionType as GenericFunctionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_parameters() {
    createParser('typedef F = bool Function(Object value);');
    var typeAlias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.semicolon, isNotNull);
    var functionType = typeAlias.functionType as GenericFunctionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_typeParameters() {
    createParser('typedef F = bool Function<E>();');
    var typeAlias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.semicolon, isNotNull);
    var functionType = typeAlias.functionType as GenericFunctionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNotNull);
  }

  void test_parseTypeAlias_genericFunction_typeParameters_noParameters() {
    createParser('typedef F<T> = bool Function();');
    var typeAlias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    var functionType = typeAlias.functionType as GenericFunctionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_typeParameters_noReturnType() {
    createParser('typedef F<T> = Function();');
    var typeAlias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    var functionType = typeAlias.functionType as GenericFunctionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNull);
    expect(functionType.typeParameters, isNull);
  }

  void
      test_parseTypeAlias_genericFunction_typeParameters_parameterizedReturnType() {
    createParser('typedef F<T> = A<B> Function();');
    var typeAlias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    var functionType = typeAlias.functionType as GenericFunctionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_typeParameters_parameters() {
    createParser('typedef F<T> = bool Function(Object value);');
    var typeAlias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    var functionType = typeAlias.functionType as GenericFunctionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_typeParameters_typeParameters() {
    createParser('typedef F<T> = bool Function<E>();');
    var typeAlias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    var functionType = typeAlias.functionType as GenericFunctionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNotNull);
  }

  void test_parseTypeAlias_genericFunction_typeParameters_voidReturnType() {
    createParser('typedef F<T> = void Function();');
    var typeAlias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    var functionType = typeAlias.functionType as GenericFunctionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_voidReturnType() {
    createParser('typedef F = void Function();');
    var typeAlias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expect(typeAlias, isNotNull);
    assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.semicolon, isNotNull);
    var functionType = typeAlias.functionType as GenericFunctionType;
    expect(functionType, isNotNull);
    expect(functionType.parameters, isNotNull);
    expect(functionType.returnType, isNotNull);
    expect(functionType.typeParameters, isNull);
  }

  void test_parseTypeAlias_genericFunction_withDocComment() {
    createParser('/// Doc\ntypedef F = bool Function();');
    var typeAlias = parseFullCompilationUnitMember() as GenericTypeAlias;
    expectCommentText(typeAlias.documentationComment, '/// Doc');
  }

  void test_parseTypeVariable_withDocumentationComment() {
    createParser('''
class A<
    /// Doc
    B> {}
''');
    var classDeclaration = parseFullCompilationUnitMember() as ClassDeclaration;
    var typeVariable = classDeclaration.typeParameters!.typeParameters[0];
    expectCommentText(typeVariable.documentationComment, '/// Doc');
  }
}
