// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/to_source_visitor.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ToSourceVisitor2Test);
  });
}

@reflectiveTest
class ToSourceVisitor2Test {
  void test_visitAdjacentStrings() {
    _assertSource(
        "'a' 'b'",
        AstTestFactory.adjacentStrings(
            [AstTestFactory.string2("a"), AstTestFactory.string2("b")]));
  }

  void test_visitAnnotation_constant() {
    _assertSource(
        "@A", AstTestFactory.annotation(AstTestFactory.identifier3("A")));
  }

  void test_visitAnnotation_constructor() {
    _assertSource(
        "@A.c()",
        AstTestFactory.annotation2(AstTestFactory.identifier3("A"),
            AstTestFactory.identifier3("c"), AstTestFactory.argumentList()));
  }

  void test_visitAnnotation_constructor_generic() {
    _assertSource(
        "@A<T>.c()",
        AstTestFactory.annotation2(AstTestFactory.identifier3("A"),
            AstTestFactory.identifier3("c"), AstTestFactory.argumentList(),
            typeArguments: AstTestFactory.typeArgumentList2(
                [AstTestFactory.namedType4('T')])));
  }

  void test_visitArgumentList() {
    _assertSource(
        "(a, b)",
        AstTestFactory.argumentList([
          AstTestFactory.identifier3("a"),
          AstTestFactory.identifier3("b")
        ]));
  }

  void test_visitAsExpression() {
    _assertSource(
        "e as T",
        AstTestFactory.asExpression(
            AstTestFactory.identifier3("e"), AstTestFactory.namedType4("T")));
  }

  void test_visitAssertStatement() {
    _assertSource("assert (a);",
        AstTestFactory.assertStatement(AstTestFactory.identifier3("a")));
  }

  void test_visitAssertStatement_withMessage() {
    _assertSource(
        "assert (a, b);",
        AstTestFactory.assertStatement(
            AstTestFactory.identifier3("a"), AstTestFactory.identifier3('b')));
  }

  void test_visitAssignmentExpression() {
    _assertSource(
        "a = b",
        AstTestFactory.assignmentExpression(AstTestFactory.identifier3("a"),
            TokenType.EQ, AstTestFactory.identifier3("b")));
  }

  void test_visitAwaitExpression() {
    _assertSource("await e",
        AstTestFactory.awaitExpression(AstTestFactory.identifier3("e")));
  }

  void test_visitBinaryExpression() {
    _assertSource(
        "a + b",
        AstTestFactory.binaryExpression(AstTestFactory.identifier3("a"),
            TokenType.PLUS, AstTestFactory.identifier3("b")));
  }

  void test_visitBinaryExpression_precedence() {
    var a = AstTestFactory.identifier3('a');
    var b = AstTestFactory.identifier3('b');
    var c = AstTestFactory.identifier3('c');
    _assertSource(
        'a * (b + c)',
        AstTestFactory.binaryExpression(a, TokenType.STAR,
            AstTestFactory.binaryExpression(b, TokenType.PLUS, c)));
  }

  void test_visitBlock_empty() {
    _assertSource("{}", AstTestFactory.block());
  }

  void test_visitBlock_nonEmpty() {
    _assertSource(
        "{break; break;}",
        AstTestFactory.block([
          AstTestFactory.breakStatement(),
          AstTestFactory.breakStatement()
        ]));
  }

  void test_visitBlockFunctionBody_async() {
    _assertSource("async {}", AstTestFactory.asyncBlockFunctionBody());
  }

  void test_visitBlockFunctionBody_async_star() {
    _assertSource(
        "async* {}", AstTestFactory.asyncGeneratorBlockFunctionBody());
  }

  void test_visitBlockFunctionBody_simple() {
    _assertSource("{}", AstTestFactory.blockFunctionBody2());
  }

  void test_visitBlockFunctionBody_sync() {
    _assertSource("sync {}", AstTestFactory.syncBlockFunctionBody());
  }

  void test_visitBlockFunctionBody_sync_star() {
    _assertSource("sync* {}", AstTestFactory.syncGeneratorBlockFunctionBody());
  }

  void test_visitBooleanLiteral_false() {
    _assertSource("false", AstTestFactory.booleanLiteral(false));
  }

  void test_visitBooleanLiteral_true() {
    _assertSource("true", AstTestFactory.booleanLiteral(true));
  }

  void test_visitBreakStatement_label() {
    _assertSource("break l;", AstTestFactory.breakStatement2("l"));
  }

  void test_visitBreakStatement_noLabel() {
    _assertSource("break;", AstTestFactory.breakStatement());
  }

  void test_visitCascadeExpression_field() {
    _assertSource(
        "a..b..c",
        AstTestFactory.cascadeExpression(AstTestFactory.identifier3("a"), [
          AstTestFactory.cascadedPropertyAccess("b"),
          AstTestFactory.cascadedPropertyAccess("c")
        ]));
  }

  void test_visitCascadeExpression_index() {
    _assertSource(
        "a..[0]..[1]",
        AstTestFactory.cascadeExpression(AstTestFactory.identifier3("a"), [
          AstTestFactory.cascadedIndexExpression(AstTestFactory.integer(0)),
          AstTestFactory.cascadedIndexExpression(AstTestFactory.integer(1))
        ]));
  }

  void test_visitCascadeExpression_method() {
    _assertSource(
        "a..b()..c()",
        AstTestFactory.cascadeExpression(AstTestFactory.identifier3("a"), [
          AstTestFactory.cascadedMethodInvocation("b"),
          AstTestFactory.cascadedMethodInvocation("c")
        ]));
  }

  void test_visitCatchClause_catch_noStack() {
    _assertSource("catch (e) {}", AstTestFactory.catchClause("e"));
  }

  void test_visitCatchClause_catch_stack() {
    _assertSource("catch (e, s) {}", AstTestFactory.catchClause2("e", "s"));
  }

  void test_visitCatchClause_on() {
    _assertSource(
        "on E {}", AstTestFactory.catchClause3(AstTestFactory.namedType4("E")));
  }

  void test_visitCatchClause_on_catch() {
    _assertSource("on E catch (e) {}",
        AstTestFactory.catchClause4(AstTestFactory.namedType4("E"), "e"));
  }

  void test_visitClassDeclaration_abstract() {
    _assertSource(
        "abstract class C {}",
        AstTestFactory.classDeclaration(
            Keyword.ABSTRACT, "C", null, null, null, null));
  }

  void test_visitClassDeclaration_empty() {
    _assertSource("class C {}",
        AstTestFactory.classDeclaration(null, "C", null, null, null, null));
  }

  void test_visitClassDeclaration_extends() {
    _assertSource(
        "class C extends A {}",
        AstTestFactory.classDeclaration(
            null,
            "C",
            null,
            AstTestFactory.extendsClause(AstTestFactory.namedType4("A")),
            null,
            null));
  }

  void test_visitClassDeclaration_extends_implements() {
    _assertSource(
        "class C extends A implements B {}",
        AstTestFactory.classDeclaration(
            null,
            "C",
            null,
            AstTestFactory.extendsClause(AstTestFactory.namedType4("A")),
            null,
            AstTestFactory.implementsClause([AstTestFactory.namedType4("B")])));
  }

  void test_visitClassDeclaration_extends_with() {
    _assertSource(
        "class C extends A with M {}",
        AstTestFactory.classDeclaration(
            null,
            "C",
            null,
            AstTestFactory.extendsClause(AstTestFactory.namedType4("A")),
            AstTestFactory.withClause([AstTestFactory.namedType4("M")]),
            null));
  }

  void test_visitClassDeclaration_extends_with_implements() {
    _assertSource(
        "class C extends A with M implements B {}",
        AstTestFactory.classDeclaration(
            null,
            "C",
            null,
            AstTestFactory.extendsClause(AstTestFactory.namedType4("A")),
            AstTestFactory.withClause([AstTestFactory.namedType4("M")]),
            AstTestFactory.implementsClause([AstTestFactory.namedType4("B")])));
  }

  void test_visitClassDeclaration_implements() {
    _assertSource(
        "class C implements B {}",
        AstTestFactory.classDeclaration(null, "C", null, null, null,
            AstTestFactory.implementsClause([AstTestFactory.namedType4("B")])));
  }

  void test_visitClassDeclaration_multipleMember() {
    _assertSource(
        "class C {var a; var b;}",
        AstTestFactory.classDeclaration(null, "C", null, null, null, null, [
          AstTestFactory.fieldDeclaration2(
              false, Keyword.VAR, [AstTestFactory.variableDeclaration("a")]),
          AstTestFactory.fieldDeclaration2(
              false, Keyword.VAR, [AstTestFactory.variableDeclaration("b")])
        ]));
  }

  void test_visitClassDeclaration_parameters() {
    _assertSource(
        "class C<E> {}",
        AstTestFactory.classDeclaration(null, "C",
            AstTestFactory.typeParameterList(["E"]), null, null, null));
  }

  void test_visitClassDeclaration_parameters_extends() {
    _assertSource(
        "class C<E> extends A {}",
        AstTestFactory.classDeclaration(
            null,
            "C",
            AstTestFactory.typeParameterList(["E"]),
            AstTestFactory.extendsClause(AstTestFactory.namedType4("A")),
            null,
            null));
  }

  void test_visitClassDeclaration_parameters_extends_implements() {
    _assertSource(
        "class C<E> extends A implements B {}",
        AstTestFactory.classDeclaration(
            null,
            "C",
            AstTestFactory.typeParameterList(["E"]),
            AstTestFactory.extendsClause(AstTestFactory.namedType4("A")),
            null,
            AstTestFactory.implementsClause([AstTestFactory.namedType4("B")])));
  }

  void test_visitClassDeclaration_parameters_extends_with() {
    _assertSource(
        "class C<E> extends A with M {}",
        AstTestFactory.classDeclaration(
            null,
            "C",
            AstTestFactory.typeParameterList(["E"]),
            AstTestFactory.extendsClause(AstTestFactory.namedType4("A")),
            AstTestFactory.withClause([AstTestFactory.namedType4("M")]),
            null));
  }

  void test_visitClassDeclaration_parameters_extends_with_implements() {
    _assertSource(
        "class C<E> extends A with M implements B {}",
        AstTestFactory.classDeclaration(
            null,
            "C",
            AstTestFactory.typeParameterList(["E"]),
            AstTestFactory.extendsClause(AstTestFactory.namedType4("A")),
            AstTestFactory.withClause([AstTestFactory.namedType4("M")]),
            AstTestFactory.implementsClause([AstTestFactory.namedType4("B")])));
  }

  void test_visitClassDeclaration_parameters_implements() {
    _assertSource(
        "class C<E> implements B {}",
        AstTestFactory.classDeclaration(
            null,
            "C",
            AstTestFactory.typeParameterList(["E"]),
            null,
            null,
            AstTestFactory.implementsClause([AstTestFactory.namedType4("B")])));
  }

  void test_visitClassDeclaration_singleMember() {
    _assertSource(
        "class C {var a;}",
        AstTestFactory.classDeclaration(null, "C", null, null, null, null, [
          AstTestFactory.fieldDeclaration2(
              false, Keyword.VAR, [AstTestFactory.variableDeclaration("a")])
        ]));
  }

  void test_visitClassDeclaration_withMetadata() {
    ClassDeclaration declaration =
        AstTestFactory.classDeclaration(null, "C", null, null, null, null);
    declaration.metadata.add(
        AstTestFactory.annotation(AstTestFactory.identifier3("deprecated")));
    _assertSource("@deprecated class C {}", declaration);
  }

  void test_visitClassTypeAlias_abstract() {
    _assertSource(
        "abstract class C = S with M1;",
        AstTestFactory.classTypeAlias(
            "C",
            null,
            Keyword.ABSTRACT,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            null));
  }

  void test_visitClassTypeAlias_abstract_implements() {
    _assertSource(
        "abstract class C = S with M1 implements I;",
        AstTestFactory.classTypeAlias(
            "C",
            null,
            Keyword.ABSTRACT,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            AstTestFactory.implementsClause([AstTestFactory.namedType4("I")])));
  }

  void test_visitClassTypeAlias_generic() {
    _assertSource(
        "class C<E> = S<E> with M1<E>;",
        AstTestFactory.classTypeAlias(
            "C",
            AstTestFactory.typeParameterList(["E"]),
            null,
            AstTestFactory.namedType4("S", [AstTestFactory.namedType4("E")]),
            AstTestFactory.withClause([
              AstTestFactory.namedType4("M1", [AstTestFactory.namedType4("E")])
            ]),
            null));
  }

  void test_visitClassTypeAlias_implements() {
    _assertSource(
        "class C = S with M1 implements I;",
        AstTestFactory.classTypeAlias(
            "C",
            null,
            null,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            AstTestFactory.implementsClause([AstTestFactory.namedType4("I")])));
  }

  void test_visitClassTypeAlias_minimal() {
    _assertSource(
        "class C = S with M1;",
        AstTestFactory.classTypeAlias(
            "C",
            null,
            null,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            null));
  }

  void test_visitClassTypeAlias_parameters_abstract() {
    _assertSource(
        "abstract class C<E> = S with M1;",
        AstTestFactory.classTypeAlias(
            "C",
            AstTestFactory.typeParameterList(["E"]),
            Keyword.ABSTRACT,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            null));
  }

  void test_visitClassTypeAlias_parameters_abstract_implements() {
    _assertSource(
        "abstract class C<E> = S with M1 implements I;",
        AstTestFactory.classTypeAlias(
            "C",
            AstTestFactory.typeParameterList(["E"]),
            Keyword.ABSTRACT,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            AstTestFactory.implementsClause([AstTestFactory.namedType4("I")])));
  }

  void test_visitClassTypeAlias_parameters_implements() {
    _assertSource(
        "class C<E> = S with M1 implements I;",
        AstTestFactory.classTypeAlias(
            "C",
            AstTestFactory.typeParameterList(["E"]),
            null,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            AstTestFactory.implementsClause([AstTestFactory.namedType4("I")])));
  }

  void test_visitClassTypeAlias_withMetadata() {
    ClassTypeAlias declaration = AstTestFactory.classTypeAlias(
        "C",
        null,
        null,
        AstTestFactory.namedType4("S"),
        AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
        null);
    declaration.metadata.add(
        AstTestFactory.annotation(AstTestFactory.identifier3("deprecated")));
    _assertSource("@deprecated class C = S with M1;", declaration);
  }

  void test_visitComment() {
    _assertSource(
        "",
        astFactory.blockComment(
            <Token>[TokenFactory.tokenFromString("/* comment */")]));
  }

  void test_visitCommentReference() {
    _assertSource(
        "", astFactory.commentReference(null, AstTestFactory.identifier3("a")));
  }

  void test_visitCompilationUnit_declaration() {
    _assertSource(
        "var a;",
        AstTestFactory.compilationUnit2([
          AstTestFactory.topLevelVariableDeclaration2(
              Keyword.VAR, [AstTestFactory.variableDeclaration("a")])
        ]));
  }

  void test_visitCompilationUnit_directive() {
    _assertSource(
        "library l;",
        AstTestFactory.compilationUnit3(
            [AstTestFactory.libraryDirective2("l")]));
  }

  void test_visitCompilationUnit_directive_declaration() {
    _assertSource(
        "library l; var a;",
        AstTestFactory.compilationUnit4([
          AstTestFactory.libraryDirective2("l")
        ], [
          AstTestFactory.topLevelVariableDeclaration2(
              Keyword.VAR, [AstTestFactory.variableDeclaration("a")])
        ]));
  }

  void test_visitCompilationUnit_empty() {
    _assertSource("", AstTestFactory.compilationUnit());
  }

  void test_visitCompilationUnit_script() {
    _assertSource(
        "!#/bin/dartvm", AstTestFactory.compilationUnit5("!#/bin/dartvm"));
  }

  void test_visitCompilationUnit_script_declaration() {
    _assertSource(
        "!#/bin/dartvm var a;",
        AstTestFactory.compilationUnit6("!#/bin/dartvm", [
          AstTestFactory.topLevelVariableDeclaration2(
              Keyword.VAR, [AstTestFactory.variableDeclaration("a")])
        ]));
  }

  void test_visitCompilationUnit_script_directive() {
    _assertSource(
        "!#/bin/dartvm library l;",
        AstTestFactory.compilationUnit7(
            "!#/bin/dartvm", [AstTestFactory.libraryDirective2("l")]));
  }

  void test_visitCompilationUnit_script_directives_declarations() {
    _assertSource(
        "!#/bin/dartvm library l; var a;",
        AstTestFactory.compilationUnit8("!#/bin/dartvm", [
          AstTestFactory.libraryDirective2("l")
        ], [
          AstTestFactory.topLevelVariableDeclaration2(
              Keyword.VAR, [AstTestFactory.variableDeclaration("a")])
        ]));
  }

  void test_visitConditionalExpression() {
    _assertSource(
        "a ? b : c",
        AstTestFactory.conditionalExpression(AstTestFactory.identifier3("a"),
            AstTestFactory.identifier3("b"), AstTestFactory.identifier3("c")));
  }

  void test_visitConstructorDeclaration_const() {
    _assertSource(
        "const C() {}",
        AstTestFactory.constructorDeclaration2(
            Keyword.CONST,
            null,
            AstTestFactory.identifier3("C"),
            null,
            AstTestFactory.formalParameterList(),
            [],
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitConstructorDeclaration_external() {
    _assertSource(
        "external C();",
        AstTestFactory.constructorDeclaration(AstTestFactory.identifier3("C"),
            null, AstTestFactory.formalParameterList(), []));
  }

  void test_visitConstructorDeclaration_minimal() {
    _assertSource(
        "C() {}",
        AstTestFactory.constructorDeclaration2(
            null,
            null,
            AstTestFactory.identifier3("C"),
            null,
            AstTestFactory.formalParameterList(),
            [],
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitConstructorDeclaration_multipleInitializers() {
    _assertSource(
        "C() : a = b, c = d {}",
        AstTestFactory.constructorDeclaration2(
            null,
            null,
            AstTestFactory.identifier3("C"),
            null,
            AstTestFactory.formalParameterList(),
            [
              AstTestFactory.constructorFieldInitializer(
                  false, "a", AstTestFactory.identifier3("b")),
              AstTestFactory.constructorFieldInitializer(
                  false, "c", AstTestFactory.identifier3("d"))
            ],
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitConstructorDeclaration_multipleParameters() {
    _assertSource(
        "C(var a, var b) {}",
        AstTestFactory.constructorDeclaration2(
            null,
            null,
            AstTestFactory.identifier3("C"),
            null,
            AstTestFactory.formalParameterList([
              AstTestFactory.simpleFormalParameter(Keyword.VAR, "a"),
              AstTestFactory.simpleFormalParameter(Keyword.VAR, "b")
            ]),
            [],
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitConstructorDeclaration_named() {
    _assertSource(
        "C.m() {}",
        AstTestFactory.constructorDeclaration2(
            null,
            null,
            AstTestFactory.identifier3("C"),
            "m",
            AstTestFactory.formalParameterList(),
            [],
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitConstructorDeclaration_singleInitializer() {
    _assertSource(
        "C() : a = b {}",
        AstTestFactory.constructorDeclaration2(
            null,
            null,
            AstTestFactory.identifier3("C"),
            null,
            AstTestFactory.formalParameterList(),
            [
              AstTestFactory.constructorFieldInitializer(
                  false, "a", AstTestFactory.identifier3("b"))
            ],
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitConstructorDeclaration_withMetadata() {
    ConstructorDeclaration declaration = AstTestFactory.constructorDeclaration2(
        null,
        null,
        AstTestFactory.identifier3("C"),
        null,
        AstTestFactory.formalParameterList(),
        [],
        AstTestFactory.blockFunctionBody2());
    declaration.metadata.add(
        AstTestFactory.annotation(AstTestFactory.identifier3("deprecated")));
    _assertSource("@deprecated C() {}", declaration);
  }

  void test_visitConstructorFieldInitializer_withoutThis() {
    _assertSource(
        "a = b",
        AstTestFactory.constructorFieldInitializer(
            false, "a", AstTestFactory.identifier3("b")));
  }

  void test_visitConstructorFieldInitializer_withThis() {
    _assertSource(
        "this.a = b",
        AstTestFactory.constructorFieldInitializer(
            true, "a", AstTestFactory.identifier3("b")));
  }

  void test_visitConstructorName_named_prefix() {
    _assertSource(
        "p.C.n",
        AstTestFactory.constructorName(
            AstTestFactory.namedType4("p.C.n"), null));
  }

  void test_visitConstructorName_unnamed_noPrefix() {
    _assertSource("C",
        AstTestFactory.constructorName(AstTestFactory.namedType4("C"), null));
  }

  void test_visitConstructorName_unnamed_prefix() {
    _assertSource(
        "p.C",
        AstTestFactory.constructorName(
            AstTestFactory.namedType3(AstTestFactory.identifier5("p", "C")),
            null));
  }

  void test_visitContinueStatement_label() {
    _assertSource("continue l;", AstTestFactory.continueStatement("l"));
  }

  void test_visitContinueStatement_noLabel() {
    _assertSource("continue;", AstTestFactory.continueStatement());
  }

  void test_visitDefaultFormalParameter_annotation() {
    DefaultFormalParameter parameter = AstTestFactory.positionalFormalParameter(
        AstTestFactory.simpleFormalParameter3("p"), AstTestFactory.integer(0));
    parameter.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("A")));
    _assertSource('@A p = 0', parameter);
  }

  void test_visitDefaultFormalParameter_named_noValue() {
    _assertSource(
        "p",
        AstTestFactory.namedFormalParameter(
            AstTestFactory.simpleFormalParameter3("p"), null));
  }

  void test_visitDefaultFormalParameter_named_value() {
    _assertSource(
        "p: 0",
        AstTestFactory.namedFormalParameter(
            AstTestFactory.simpleFormalParameter3("p"),
            AstTestFactory.integer(0)));
  }

  void test_visitDefaultFormalParameter_positional_noValue() {
    _assertSource(
        "p",
        AstTestFactory.positionalFormalParameter(
            AstTestFactory.simpleFormalParameter3("p"), null));
  }

  void test_visitDefaultFormalParameter_positional_value() {
    _assertSource(
        "p = 0",
        AstTestFactory.positionalFormalParameter(
            AstTestFactory.simpleFormalParameter3("p"),
            AstTestFactory.integer(0)));
  }

  void test_visitDoStatement() {
    _assertSource(
        "do {} while (c);",
        AstTestFactory.doStatement(
            AstTestFactory.block(), AstTestFactory.identifier3("c")));
  }

  void test_visitDoubleLiteral() {
    _assertSource("4.2", AstTestFactory.doubleLiteral(4.2));
  }

  void test_visitEmptyFunctionBody() {
    _assertSource(";", AstTestFactory.emptyFunctionBody());
  }

  void test_visitEmptyStatement() {
    _assertSource(";", AstTestFactory.emptyStatement());
  }

  void test_visitEnumDeclaration_multiple() {
    _assertSource("enum E {ONE, TWO}",
        AstTestFactory.enumDeclaration2("E", ["ONE", "TWO"]));
  }

  void test_visitEnumDeclaration_single() {
    _assertSource(
        "enum E {ONE}", AstTestFactory.enumDeclaration2("E", ["ONE"]));
  }

  void test_visitExportDirective_combinator() {
    _assertSource(
        "export 'a.dart' show A;",
        AstTestFactory.exportDirective2("a.dart", [
          AstTestFactory.showCombinator([AstTestFactory.identifier3("A")])
        ]));
  }

  void test_visitExportDirective_combinators() {
    _assertSource(
        "export 'a.dart' show A hide B;",
        AstTestFactory.exportDirective2("a.dart", [
          AstTestFactory.showCombinator([AstTestFactory.identifier3("A")]),
          AstTestFactory.hideCombinator([AstTestFactory.identifier3("B")])
        ]));
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
    _assertSource(
        "export 'a.dart';", AstTestFactory.exportDirective2("a.dart"));
  }

  void test_visitExportDirective_withMetadata() {
    ExportDirective directive = AstTestFactory.exportDirective2("a.dart");
    directive.metadata.add(
        AstTestFactory.annotation(AstTestFactory.identifier3("deprecated")));
    _assertSource("@deprecated export 'a.dart';", directive);
  }

  void test_visitExpressionFunctionBody_async() {
    _assertSource(
        "async => a;",
        AstTestFactory.asyncExpressionFunctionBody(
            AstTestFactory.identifier3("a")));
  }

  void test_visitExpressionFunctionBody_async_star() {
    _assertSource(
        "async* => a;",
        AstTestFactory.asyncGeneratorExpressionFunctionBody(
            AstTestFactory.identifier3("a")));
  }

  void test_visitExpressionFunctionBody_simple() {
    _assertSource("=> a;",
        AstTestFactory.expressionFunctionBody(AstTestFactory.identifier3("a")));
  }

  void test_visitExpressionStatement() {
    _assertSource("a;",
        AstTestFactory.expressionStatement(AstTestFactory.identifier3("a")));
  }

  void test_visitExtendsClause() {
    _assertSource("extends C",
        AstTestFactory.extendsClause(AstTestFactory.namedType4("C")));
  }

  void test_visitExtensionDeclaration_empty() {
    _assertSource(
        'extension E on C {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            isExtensionTypeDeclaration: false));
  }

  void test_visitExtensionDeclaration_multipleMember() {
    _assertSource(
        'extension E on C {var a; var b;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(false, Keyword.VAR,
                  [AstTestFactory.variableDeclaration('a')]),
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('b')])
            ],
            isExtensionTypeDeclaration: false));
  }

  void test_visitExtensionDeclaration_parameters() {
    _assertSource(
        'extension E<T> on C {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            typeParameters: AstTestFactory.typeParameterList(['T']),
            extendedType: AstTestFactory.namedType4('C'),
            isExtensionTypeDeclaration: false));
  }

  void test_visitExtensionDeclaration_singleMember() {
    _assertSource(
        'extension E on C {var a;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('a')])
            ],
            isExtensionTypeDeclaration: false));
  }

  void test_visitExtensionDeclarationHideClause_empty() {
    _assertSource(
        'extension type E on C hide B {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            hideClause:
                AstTestFactory.hideClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationHideClause_multipleMember() {
    _assertSource(
        'extension type E on C hide B {var a; var b;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(false, Keyword.VAR,
                  [AstTestFactory.variableDeclaration('a')]),
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('b')])
            ],
            hideClause:
                AstTestFactory.hideClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationHideClause_parameters() {
    _assertSource(
        'extension type E<T> on C hide B {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            typeParameters: AstTestFactory.typeParameterList(['T']),
            extendedType: AstTestFactory.namedType4('C'),
            hideClause:
                AstTestFactory.hideClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationHideClause_singleMember() {
    _assertSource(
        'extension type E on C hide B {var a;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('a')])
            ],
            hideClause:
                AstTestFactory.hideClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_ambiguousElement() {
    _assertSource(
        'extension type E on C show foo {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause: AstTestFactory.showClause(
                [AstTestFactory.showHideElement("foo")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_empty() {
    _assertSource(
        'extension type E on C show B {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause:
                AstTestFactory.showClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_getterElement() {
    _assertSource(
        'extension type E on C show get foo {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause: AstTestFactory.showClause(
                [AstTestFactory.showHideElementGetter("foo")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_multipleMember() {
    _assertSource(
        'extension type E on C show B {var a; var b;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(false, Keyword.VAR,
                  [AstTestFactory.variableDeclaration('a')]),
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('b')])
            ],
            showClause:
                AstTestFactory.showClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_operatorElement() {
    _assertSource(
        'extension type E on C show operator * {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause: AstTestFactory.showClause(
                [AstTestFactory.showHideElementOperator("*")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_parameters() {
    _assertSource(
        'extension type E<T> on C show B {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            typeParameters: AstTestFactory.typeParameterList(['T']),
            extendedType: AstTestFactory.namedType4('C'),
            showClause:
                AstTestFactory.showClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_qualifiedTypeElement() {
    _assertSource(
        'extension type E on C show prefix.B {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause: AstTestFactory.showClause([
              AstTestFactory.namedType3(
                  AstTestFactory.identifier5('prefix', 'B'))
            ]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_setterElement() {
    _assertSource(
        'extension type E on C show set foo {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause: AstTestFactory.showClause(
                [AstTestFactory.showHideElementSetter("foo")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_singleMember() {
    _assertSource(
        'extension type E on C show B {var a;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('a')])
            ],
            showClause:
                AstTestFactory.showClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_typeWithArgumentsElement() {
    _assertSource(
        'extension type E on C show B<int, String> {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause: AstTestFactory.showClause([
              AstTestFactory.namedType3(AstTestFactory.identifier3('B'), [
                AstTestFactory.namedType4('int'),
                AstTestFactory.namedType4('String')
              ])
            ]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowHideClause_empty() {
    _assertSource(
        'extension type E on C show B hide foo {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause:
                AstTestFactory.showClause([AstTestFactory.namedType4("B")]),
            hideClause: AstTestFactory.hideClause(
                [AstTestFactory.showHideElement("foo")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionOverride_prefixedName_noTypeArgs() {
    _assertSource(
        'p.E(o)',
        AstTestFactory.extensionOverride(
            extensionName: AstTestFactory.identifier5('p', 'E'),
            argumentList: AstTestFactory.argumentList(
                [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionOverride_prefixedName_typeArgs() {
    _assertSource(
        'p.E<A>(o)',
        AstTestFactory.extensionOverride(
            extensionName: AstTestFactory.identifier5('p', 'E'),
            typeArguments: AstTestFactory.typeArgumentList(
                [AstTestFactory.namedType4('A')]),
            argumentList: AstTestFactory.argumentList(
                [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionOverride_simpleName_noTypeArgs() {
    _assertSource(
        'E(o)',
        AstTestFactory.extensionOverride(
            extensionName: AstTestFactory.identifier3('E'),
            argumentList: AstTestFactory.argumentList(
                [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionOverride_simpleName_typeArgs() {
    _assertSource(
        'E<A>(o)',
        AstTestFactory.extensionOverride(
            extensionName: AstTestFactory.identifier3('E'),
            typeArguments: AstTestFactory.typeArgumentList(
                [AstTestFactory.namedType4('A')]),
            argumentList: AstTestFactory.argumentList(
                [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionTypeDeclaration_empty() {
    _assertSource(
        'extension type E on C {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionTypeDeclaration_multipleMember() {
    _assertSource(
        'extension type E on C {var a; var b;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(false, Keyword.VAR,
                  [AstTestFactory.variableDeclaration('a')]),
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('b')])
            ],
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionTypeDeclaration_parameters() {
    _assertSource(
        'extension type E<T> on C {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            typeParameters: AstTestFactory.typeParameterList(['T']),
            extendedType: AstTestFactory.namedType4('C'),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionTypeDeclaration_singleMember() {
    _assertSource(
        'extension type E on C {var a;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('a')])
            ],
            isExtensionTypeDeclaration: true));
  }

  void test_visitFieldDeclaration_abstract() {
    _assertSource(
        "abstract var a;",
        AstTestFactory.fieldDeclaration(
            false, Keyword.VAR, null, [AstTestFactory.variableDeclaration("a")],
            isAbstract: true));
  }

  void test_visitFieldDeclaration_external() {
    _assertSource(
        "external var a;",
        AstTestFactory.fieldDeclaration(
            false, Keyword.VAR, null, [AstTestFactory.variableDeclaration("a")],
            isExternal: true));
  }

  void test_visitFieldDeclaration_instance() {
    _assertSource(
        "var a;",
        AstTestFactory.fieldDeclaration2(
            false, Keyword.VAR, [AstTestFactory.variableDeclaration("a")]));
  }

  void test_visitFieldDeclaration_static() {
    _assertSource(
        "static var a;",
        AstTestFactory.fieldDeclaration2(
            true, Keyword.VAR, [AstTestFactory.variableDeclaration("a")]));
  }

  void test_visitFieldDeclaration_withMetadata() {
    FieldDeclaration declaration = AstTestFactory.fieldDeclaration2(
        false, Keyword.VAR, [AstTestFactory.variableDeclaration("a")]);
    declaration.metadata.add(
        AstTestFactory.annotation(AstTestFactory.identifier3("deprecated")));
    _assertSource("@deprecated var a;", declaration);
  }

  void test_visitFieldFormalParameter_annotation() {
    FieldFormalParameter parameter = AstTestFactory.fieldFormalParameter2('f');
    parameter.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("A")));
    _assertSource('@A this.f', parameter);
  }

  void test_visitFieldFormalParameter_functionTyped() {
    _assertSource(
        "A this.a(b)",
        AstTestFactory.fieldFormalParameter(
            null,
            AstTestFactory.namedType4("A"),
            "a",
            AstTestFactory.formalParameterList(
                [AstTestFactory.simpleFormalParameter3("b")])));
  }

  void test_visitFieldFormalParameter_functionTyped_typeParameters() {
    _assertSource(
        "A this.a<E, F>(b)",
        astFactory.fieldFormalParameter2(
            type: AstTestFactory.namedType4('A'),
            thisKeyword: TokenFactory.tokenFromKeyword(Keyword.THIS),
            period: TokenFactory.tokenFromType(TokenType.PERIOD),
            identifier: AstTestFactory.identifier3('a'),
            typeParameters: AstTestFactory.typeParameterList(['E', 'F']),
            parameters: AstTestFactory.formalParameterList(
                [AstTestFactory.simpleFormalParameter3("b")])));
  }

  void test_visitFieldFormalParameter_keyword() {
    _assertSource("var this.a",
        AstTestFactory.fieldFormalParameter(Keyword.VAR, null, "a"));
  }

  void test_visitFieldFormalParameter_keywordAndType() {
    _assertSource(
        "final A this.a",
        AstTestFactory.fieldFormalParameter(
            Keyword.FINAL, AstTestFactory.namedType4("A"), "a"));
  }

  void test_visitFieldFormalParameter_type() {
    _assertSource(
        "A this.a",
        AstTestFactory.fieldFormalParameter(
            null, AstTestFactory.namedType4("A"), "a"));
  }

  void test_visitFieldFormalParameter_type_covariant() {
    var expected = AstTestFactory.fieldFormalParameter(
        null, AstTestFactory.namedType4("A"), "a");
    expected.covariantKeyword =
        TokenFactory.tokenFromKeyword(Keyword.COVARIANT);
    _assertSource("covariant A this.a", expected);
  }

  void test_visitForEachPartsWithDeclaration() {
    _assertSource(
        'var e in l',
        astFactory.forEachPartsWithDeclaration(
            loopVariable: AstTestFactory.declaredIdentifier3('e'),
            inKeyword: Tokens.in_(),
            iterable: AstTestFactory.identifier3('l')));
  }

  void test_visitForEachPartsWithIdentifier() {
    _assertSource(
        'e in l',
        astFactory.forEachPartsWithIdentifier(
            identifier: AstTestFactory.identifier3('e'),
            inKeyword: Tokens.in_(),
            iterable: AstTestFactory.identifier3('l')));
  }

  void test_visitForEachStatement_declared() {
    _assertSource(
        "for (var a in b) {}",
        AstTestFactory.forStatement(
            AstTestFactory.forEachPartsWithDeclaration(
                AstTestFactory.declaredIdentifier3("a"),
                AstTestFactory.identifier3("b")),
            AstTestFactory.block()));
  }

  void test_visitForEachStatement_variable() {
    _assertSource(
        "for (a in b) {}",
        astFactory.forStatement(
            forKeyword: TokenFactory.tokenFromKeyword(Keyword.FOR),
            leftParenthesis: TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
            forLoopParts: astFactory.forEachPartsWithIdentifier(
                identifier: AstTestFactory.identifier3("a"),
                inKeyword: TokenFactory.tokenFromKeyword(Keyword.IN),
                iterable: AstTestFactory.identifier3("b")),
            rightParenthesis: TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
            body: AstTestFactory.block()));
  }

  void test_visitForEachStatement_variable_await() {
    _assertSource(
        "await for (a in b) {}",
        astFactory.forStatement(
            awaitKeyword: TokenFactory.tokenFromString("await"),
            forKeyword: TokenFactory.tokenFromKeyword(Keyword.FOR),
            leftParenthesis: TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
            forLoopParts: astFactory.forEachPartsWithIdentifier(
                identifier: AstTestFactory.identifier3("a"),
                inKeyword: TokenFactory.tokenFromKeyword(Keyword.IN),
                iterable: AstTestFactory.identifier3("b")),
            rightParenthesis: TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
            body: AstTestFactory.block()));
  }

  void test_visitForElement() {
    _assertSource(
      'for (e in l) 0',
      astFactory.forElement(
          forKeyword: Tokens.for_(),
          leftParenthesis: Tokens.openParenthesis(),
          forLoopParts: astFactory.forEachPartsWithIdentifier(
              identifier: AstTestFactory.identifier3('e'),
              inKeyword: Tokens.in_(),
              iterable: AstTestFactory.identifier3('l')),
          rightParenthesis: Tokens.closeParenthesis(),
          body: AstTestFactory.integer(0)),
    );
  }

  void test_visitFormalParameterList_empty() {
    _assertSource("()", AstTestFactory.formalParameterList());
  }

  void test_visitFormalParameterList_n() {
    _assertSource(
        "({a: 0})",
        AstTestFactory.formalParameterList([
          AstTestFactory.namedFormalParameter(
              AstTestFactory.simpleFormalParameter3("a"),
              AstTestFactory.integer(0))
        ]));
  }

  void test_visitFormalParameterList_namedRequired() {
    _assertSource(
        "({required a, required A b})",
        AstTestFactory.formalParameterList([
          AstTestFactory.namedFormalParameter(
              AstTestFactory.simpleFormalParameter3("a")
                ..requiredKeyword =
                    TokenFactory.tokenFromKeyword(Keyword.REQUIRED),
              null),
          AstTestFactory.namedFormalParameter(
              AstTestFactory.simpleFormalParameter2(
                  null, AstTestFactory.namedType4('A'), "b")
                ..requiredKeyword =
                    TokenFactory.tokenFromKeyword(Keyword.REQUIRED),
              null),
        ]));
  }

  void test_visitFormalParameterList_nn() {
    _assertSource(
        "({a: 0, b: 1})",
        AstTestFactory.formalParameterList([
          AstTestFactory.namedFormalParameter(
              AstTestFactory.simpleFormalParameter3("a"),
              AstTestFactory.integer(0)),
          AstTestFactory.namedFormalParameter(
              AstTestFactory.simpleFormalParameter3("b"),
              AstTestFactory.integer(1))
        ]));
  }

  void test_visitFormalParameterList_p() {
    _assertSource(
        "([a = 0])",
        AstTestFactory.formalParameterList([
          AstTestFactory.positionalFormalParameter(
              AstTestFactory.simpleFormalParameter3("a"),
              AstTestFactory.integer(0))
        ]));
  }

  void test_visitFormalParameterList_pp() {
    _assertSource(
        "([a = 0, b = 1])",
        AstTestFactory.formalParameterList([
          AstTestFactory.positionalFormalParameter(
              AstTestFactory.simpleFormalParameter3("a"),
              AstTestFactory.integer(0)),
          AstTestFactory.positionalFormalParameter(
              AstTestFactory.simpleFormalParameter3("b"),
              AstTestFactory.integer(1))
        ]));
  }

  void test_visitFormalParameterList_r() {
    _assertSource(
        "(a)",
        AstTestFactory.formalParameterList(
            [AstTestFactory.simpleFormalParameter3("a")]));
  }

  void test_visitFormalParameterList_rn() {
    _assertSource(
        "(a, {b: 1})",
        AstTestFactory.formalParameterList([
          AstTestFactory.simpleFormalParameter3("a"),
          AstTestFactory.namedFormalParameter(
              AstTestFactory.simpleFormalParameter3("b"),
              AstTestFactory.integer(1))
        ]));
  }

  void test_visitFormalParameterList_rnn() {
    _assertSource(
        "(a, {b: 1, c: 2})",
        AstTestFactory.formalParameterList([
          AstTestFactory.simpleFormalParameter3("a"),
          AstTestFactory.namedFormalParameter(
              AstTestFactory.simpleFormalParameter3("b"),
              AstTestFactory.integer(1)),
          AstTestFactory.namedFormalParameter(
              AstTestFactory.simpleFormalParameter3("c"),
              AstTestFactory.integer(2))
        ]));
  }

  void test_visitFormalParameterList_rp() {
    _assertSource(
        "(a, [b = 1])",
        AstTestFactory.formalParameterList([
          AstTestFactory.simpleFormalParameter3("a"),
          AstTestFactory.positionalFormalParameter(
              AstTestFactory.simpleFormalParameter3("b"),
              AstTestFactory.integer(1))
        ]));
  }

  void test_visitFormalParameterList_rpp() {
    _assertSource(
        "(a, [b = 1, c = 2])",
        AstTestFactory.formalParameterList([
          AstTestFactory.simpleFormalParameter3("a"),
          AstTestFactory.positionalFormalParameter(
              AstTestFactory.simpleFormalParameter3("b"),
              AstTestFactory.integer(1)),
          AstTestFactory.positionalFormalParameter(
              AstTestFactory.simpleFormalParameter3("c"),
              AstTestFactory.integer(2))
        ]));
  }

  void test_visitFormalParameterList_rr() {
    _assertSource(
        "(a, b)",
        AstTestFactory.formalParameterList([
          AstTestFactory.simpleFormalParameter3("a"),
          AstTestFactory.simpleFormalParameter3("b")
        ]));
  }

  void test_visitFormalParameterList_rrn() {
    _assertSource(
        "(a, b, {c: 3})",
        AstTestFactory.formalParameterList([
          AstTestFactory.simpleFormalParameter3("a"),
          AstTestFactory.simpleFormalParameter3("b"),
          AstTestFactory.namedFormalParameter(
              AstTestFactory.simpleFormalParameter3("c"),
              AstTestFactory.integer(3))
        ]));
  }

  void test_visitFormalParameterList_rrnn() {
    _assertSource(
        "(a, b, {c: 3, d: 4})",
        AstTestFactory.formalParameterList([
          AstTestFactory.simpleFormalParameter3("a"),
          AstTestFactory.simpleFormalParameter3("b"),
          AstTestFactory.namedFormalParameter(
              AstTestFactory.simpleFormalParameter3("c"),
              AstTestFactory.integer(3)),
          AstTestFactory.namedFormalParameter(
              AstTestFactory.simpleFormalParameter3("d"),
              AstTestFactory.integer(4))
        ]));
  }

  void test_visitFormalParameterList_rrp() {
    _assertSource(
        "(a, b, [c = 3])",
        AstTestFactory.formalParameterList([
          AstTestFactory.simpleFormalParameter3("a"),
          AstTestFactory.simpleFormalParameter3("b"),
          AstTestFactory.positionalFormalParameter(
              AstTestFactory.simpleFormalParameter3("c"),
              AstTestFactory.integer(3))
        ]));
  }

  void test_visitFormalParameterList_rrpp() {
    _assertSource(
        "(a, b, [c = 3, d = 4])",
        AstTestFactory.formalParameterList([
          AstTestFactory.simpleFormalParameter3("a"),
          AstTestFactory.simpleFormalParameter3("b"),
          AstTestFactory.positionalFormalParameter(
              AstTestFactory.simpleFormalParameter3("c"),
              AstTestFactory.integer(3)),
          AstTestFactory.positionalFormalParameter(
              AstTestFactory.simpleFormalParameter3("d"),
              AstTestFactory.integer(4))
        ]));
  }

  void test_visitForPartsWithDeclarations() {
    _assertSource(
        'var v; b; u',
        astFactory.forPartsWithDeclarations(
            variables: AstTestFactory.variableDeclarationList2(
                Keyword.VAR, [AstTestFactory.variableDeclaration('v')]),
            leftSeparator: Tokens.semicolon(),
            condition: AstTestFactory.identifier3('b'),
            rightSeparator: Tokens.semicolon(),
            updaters: [AstTestFactory.identifier3('u')]));
  }

  void test_visitForPartsWithExpression() {
    _assertSource(
        'v; b; u',
        astFactory.forPartsWithExpression(
            initialization: AstTestFactory.identifier3('v'),
            leftSeparator: Tokens.semicolon(),
            condition: AstTestFactory.identifier3('b'),
            rightSeparator: Tokens.semicolon(),
            updaters: [AstTestFactory.identifier3('u')]));
  }

  void test_visitForStatement() {
    _assertSource(
      'for (e in l) s;',
      astFactory.forStatement(
          forKeyword: Tokens.for_(),
          leftParenthesis: Tokens.openParenthesis(),
          forLoopParts: astFactory.forEachPartsWithIdentifier(
              identifier: AstTestFactory.identifier3('e'),
              inKeyword: Tokens.in_(),
              iterable: AstTestFactory.identifier3('l')),
          rightParenthesis: Tokens.closeParenthesis(),
          body: AstTestFactory.expressionStatement(
              AstTestFactory.identifier3('s'))),
    );
  }

  void test_visitForStatement_c() {
    _assertSource(
        "for (; c;) {}",
        AstTestFactory.forStatement(
            AstTestFactory.forPartsWithExpression(
                null, AstTestFactory.identifier3("c"), null),
            AstTestFactory.block()));
  }

  void test_visitForStatement_cu() {
    _assertSource(
        "for (; c; u) {}",
        AstTestFactory.forStatement(
            AstTestFactory.forPartsWithExpression(
                null,
                AstTestFactory.identifier3("c"),
                [AstTestFactory.identifier3("u")]),
            AstTestFactory.block()));
  }

  void test_visitForStatement_e() {
    _assertSource(
        "for (e;;) {}",
        AstTestFactory.forStatement(
            AstTestFactory.forPartsWithExpression(
                AstTestFactory.identifier3("e"), null, null),
            AstTestFactory.block()));
  }

  void test_visitForStatement_ec() {
    _assertSource(
        "for (e; c;) {}",
        AstTestFactory.forStatement(
            AstTestFactory.forPartsWithExpression(
                AstTestFactory.identifier3("e"),
                AstTestFactory.identifier3("c"),
                null),
            AstTestFactory.block()));
  }

  void test_visitForStatement_ecu() {
    _assertSource(
        "for (e; c; u) {}",
        AstTestFactory.forStatement(
            AstTestFactory.forPartsWithExpression(
                AstTestFactory.identifier3("e"),
                AstTestFactory.identifier3("c"),
                [AstTestFactory.identifier3("u")]),
            AstTestFactory.block()));
  }

  void test_visitForStatement_eu() {
    _assertSource(
        "for (e;; u) {}",
        AstTestFactory.forStatement(
            AstTestFactory.forPartsWithExpression(
                AstTestFactory.identifier3("e"),
                null,
                [AstTestFactory.identifier3("u")]),
            AstTestFactory.block()));
  }

  void test_visitForStatement_i() {
    _assertSource(
        "for (var i;;) {}",
        AstTestFactory.forStatement(
            AstTestFactory.forPartsWithDeclarations(
                AstTestFactory.variableDeclarationList2(
                    Keyword.VAR, [AstTestFactory.variableDeclaration("i")]),
                null,
                null),
            AstTestFactory.block()));
  }

  void test_visitForStatement_ic() {
    _assertSource(
        "for (var i; c;) {}",
        AstTestFactory.forStatement(
            AstTestFactory.forPartsWithDeclarations(
                AstTestFactory.variableDeclarationList2(
                    Keyword.VAR, [AstTestFactory.variableDeclaration("i")]),
                AstTestFactory.identifier3("c"),
                null),
            AstTestFactory.block()));
  }

  void test_visitForStatement_icu() {
    _assertSource(
        "for (var i; c; u) {}",
        AstTestFactory.forStatement(
            AstTestFactory.forPartsWithDeclarations(
                AstTestFactory.variableDeclarationList2(
                    Keyword.VAR, [AstTestFactory.variableDeclaration("i")]),
                AstTestFactory.identifier3("c"),
                [AstTestFactory.identifier3("u")]),
            AstTestFactory.block()));
  }

  void test_visitForStatement_iu() {
    _assertSource(
        "for (var i;; u) {}",
        AstTestFactory.forStatement(
            AstTestFactory.forPartsWithDeclarations(
                AstTestFactory.variableDeclarationList2(
                    Keyword.VAR, [AstTestFactory.variableDeclaration("i")]),
                null,
                [AstTestFactory.identifier3("u")]),
            AstTestFactory.block()));
  }

  void test_visitForStatement_u() {
    _assertSource(
        "for (;; u) {}",
        AstTestFactory.forStatement(
            AstTestFactory.forPartsWithExpression(
                null, null, [AstTestFactory.identifier3("u")]),
            AstTestFactory.block()));
  }

  void test_visitFunctionDeclaration_external() {
    var functionDeclaration = AstTestFactory.functionDeclaration(
        null,
        null,
        "f",
        AstTestFactory.functionExpression2(AstTestFactory.formalParameterList(),
            AstTestFactory.emptyFunctionBody()));
    functionDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    _assertSource("external f();", functionDeclaration);
  }

  void test_visitFunctionDeclaration_getter() {
    _assertSource(
        "get f() {}",
        AstTestFactory.functionDeclaration(
            null, Keyword.GET, "f", AstTestFactory.functionExpression()));
  }

  void test_visitFunctionDeclaration_local_blockBody() {
    FunctionDeclaration f = AstTestFactory.functionDeclaration(
        null, null, "f", AstTestFactory.functionExpression());
    FunctionDeclarationStatement fStatement =
        astFactory.functionDeclarationStatement(f);
    _assertSource(
        "main() {f() {} 42;}",
        AstTestFactory.functionDeclaration(
            null,
            null,
            "main",
            AstTestFactory.functionExpression2(
                AstTestFactory.formalParameterList(),
                AstTestFactory.blockFunctionBody2([
                  fStatement,
                  AstTestFactory.expressionStatement(AstTestFactory.integer(42))
                ]))));
  }

  void test_visitFunctionDeclaration_local_expressionBody() {
    FunctionDeclaration f = AstTestFactory.functionDeclaration(
        null,
        null,
        "f",
        AstTestFactory.functionExpression2(AstTestFactory.formalParameterList(),
            AstTestFactory.expressionFunctionBody(AstTestFactory.integer(1))));
    FunctionDeclarationStatement fStatement =
        astFactory.functionDeclarationStatement(f);
    _assertSource(
        "main() {f() => 1; 2;}",
        AstTestFactory.functionDeclaration(
            null,
            null,
            "main",
            AstTestFactory.functionExpression2(
                AstTestFactory.formalParameterList(),
                AstTestFactory.blockFunctionBody2([
                  fStatement,
                  AstTestFactory.expressionStatement(AstTestFactory.integer(2))
                ]))));
  }

  void test_visitFunctionDeclaration_normal() {
    _assertSource(
        "f() {}",
        AstTestFactory.functionDeclaration(
            null, null, "f", AstTestFactory.functionExpression()));
  }

  void test_visitFunctionDeclaration_setter() {
    _assertSource(
        "set f() {}",
        AstTestFactory.functionDeclaration(
            null, Keyword.SET, "f", AstTestFactory.functionExpression()));
  }

  void test_visitFunctionDeclaration_typeParameters() {
    _assertSource(
        "f<E>() {}",
        AstTestFactory.functionDeclaration(
            null,
            null,
            "f",
            AstTestFactory.functionExpression3(
                AstTestFactory.typeParameterList2(['E']),
                AstTestFactory.formalParameterList(),
                AstTestFactory.blockFunctionBody2())));
  }

  void test_visitFunctionDeclaration_withMetadata() {
    FunctionDeclaration declaration = AstTestFactory.functionDeclaration(
        null, null, "f", AstTestFactory.functionExpression());
    declaration.metadata.add(
        AstTestFactory.annotation(AstTestFactory.identifier3("deprecated")));
    _assertSource("@deprecated f() {}", declaration);
  }

  void test_visitFunctionDeclarationStatement() {
    _assertSource(
        "f() {}",
        AstTestFactory.functionDeclarationStatement(
            null, null, "f", AstTestFactory.functionExpression()));
  }

  void test_visitFunctionExpression() {
    _assertSource("() {}", AstTestFactory.functionExpression());
  }

  void test_visitFunctionExpression_typeParameters() {
    _assertSource(
        "<E>() {}",
        AstTestFactory.functionExpression3(
            AstTestFactory.typeParameterList2(['E']),
            AstTestFactory.formalParameterList(),
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitFunctionExpressionInvocation_minimal() {
    _assertSource(
        "f()",
        AstTestFactory.functionExpressionInvocation(
            AstTestFactory.identifier3("f")));
  }

  void test_visitFunctionExpressionInvocation_typeArguments() {
    _assertSource(
        "f<A>()",
        AstTestFactory.functionExpressionInvocation2(
            AstTestFactory.identifier3("f"),
            AstTestFactory.typeArgumentList([AstTestFactory.namedType4('A')])));
  }

  void test_visitFunctionTypeAlias_generic() {
    _assertSource(
        "typedef A F<B>();",
        AstTestFactory.typeAlias(
            AstTestFactory.namedType4("A"),
            "F",
            AstTestFactory.typeParameterList(["B"]),
            AstTestFactory.formalParameterList()));
  }

  void test_visitFunctionTypeAlias_nonGeneric() {
    _assertSource(
        "typedef A F();",
        AstTestFactory.typeAlias(AstTestFactory.namedType4("A"), "F", null,
            AstTestFactory.formalParameterList()));
  }

  void test_visitFunctionTypeAlias_withMetadata() {
    FunctionTypeAlias declaration = AstTestFactory.typeAlias(
        AstTestFactory.namedType4("A"),
        "F",
        null,
        AstTestFactory.formalParameterList());
    declaration.metadata.add(
        AstTestFactory.annotation(AstTestFactory.identifier3("deprecated")));
    _assertSource("@deprecated typedef A F();", declaration);
  }

  void test_visitFunctionTypedFormalParameter_annotation() {
    FunctionTypedFormalParameter parameter =
        AstTestFactory.functionTypedFormalParameter(null, "f");
    parameter.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("A")));
    _assertSource('@A f()', parameter);
  }

  void test_visitFunctionTypedFormalParameter_noType() {
    _assertSource(
        "f()", AstTestFactory.functionTypedFormalParameter(null, "f"));
  }

  void test_visitFunctionTypedFormalParameter_nullable() {
    _assertSource(
        "T f()?",
        astFactory.functionTypedFormalParameter2(
            returnType: AstTestFactory.namedType4("T"),
            identifier: AstTestFactory.identifier3('f'),
            parameters: AstTestFactory.formalParameterList([]),
            question: TokenFactory.tokenFromType(TokenType.QUESTION)));
  }

  void test_visitFunctionTypedFormalParameter_type() {
    _assertSource(
        "T f()",
        AstTestFactory.functionTypedFormalParameter(
            AstTestFactory.namedType4("T"), "f"));
  }

  void test_visitFunctionTypedFormalParameter_type_covariant() {
    var expected = AstTestFactory.functionTypedFormalParameter(
        AstTestFactory.namedType4("T"), "f");
    expected.covariantKeyword =
        TokenFactory.tokenFromKeyword(Keyword.COVARIANT);
    _assertSource("covariant T f()", expected);
  }

  void test_visitFunctionTypedFormalParameter_typeParameters() {
    _assertSource(
        "T f<E>()",
        astFactory.functionTypedFormalParameter2(
            returnType: AstTestFactory.namedType4("T"),
            identifier: AstTestFactory.identifier3('f'),
            typeParameters: AstTestFactory.typeParameterList(['E']),
            parameters: AstTestFactory.formalParameterList([])));
  }

  void test_visitGenericFunctionType() {
    _assertSource(
        "int Function<T>(T)",
        AstTestFactory.genericFunctionType(
            AstTestFactory.namedType4("int"),
            AstTestFactory.typeParameterList2(['T']),
            AstTestFactory.formalParameterList([
              AstTestFactory.simpleFormalParameter4(
                  AstTestFactory.namedType4("T"), null)
            ])));
  }

  void test_visitGenericFunctionType_withQuestion() {
    _assertSource(
        "int Function<T>(T)?",
        AstTestFactory.genericFunctionType(
            AstTestFactory.namedType4("int"),
            AstTestFactory.typeParameterList2(['T']),
            AstTestFactory.formalParameterList([
              AstTestFactory.simpleFormalParameter4(
                  AstTestFactory.namedType4("T"), null)
            ]),
            question: true));
  }

  void test_visitGenericTypeAlias() {
    _assertSource(
        "typedef X<S> = S Function<T>(T);",
        AstTestFactory.genericTypeAlias(
            'X',
            AstTestFactory.typeParameterList2(['S']),
            AstTestFactory.genericFunctionType(
                AstTestFactory.namedType4("S"),
                AstTestFactory.typeParameterList2(['T']),
                AstTestFactory.formalParameterList([
                  AstTestFactory.simpleFormalParameter4(
                      AstTestFactory.namedType4("T"), null)
                ]))));
  }

  void test_visitIfElement_else() {
    _assertSource(
        'if (b) 1 else 0',
        astFactory.ifElement(
            ifKeyword: Tokens.if_(),
            leftParenthesis: Tokens.openParenthesis(),
            condition: AstTestFactory.identifier3('b'),
            rightParenthesis: Tokens.closeParenthesis(),
            thenElement: AstTestFactory.integer(1),
            elseKeyword: Tokens.else_(),
            elseElement: AstTestFactory.integer(0)));
  }

  void test_visitIfElement_then() {
    _assertSource(
        'if (b) 1',
        astFactory.ifElement(
            ifKeyword: Tokens.if_(),
            leftParenthesis: Tokens.openParenthesis(),
            condition: AstTestFactory.identifier3('b'),
            rightParenthesis: Tokens.closeParenthesis(),
            thenElement: AstTestFactory.integer(1)));
  }

  void test_visitIfStatement_withElse() {
    _assertSource(
        "if (c) {} else {}",
        AstTestFactory.ifStatement2(AstTestFactory.identifier3("c"),
            AstTestFactory.block(), AstTestFactory.block()));
  }

  void test_visitIfStatement_withoutElse() {
    _assertSource(
        "if (c) {}",
        AstTestFactory.ifStatement(
            AstTestFactory.identifier3("c"), AstTestFactory.block()));
  }

  void test_visitImplementsClause_multiple() {
    _assertSource(
        "implements A, B",
        AstTestFactory.implementsClause(
            [AstTestFactory.namedType4("A"), AstTestFactory.namedType4("B")]));
  }

  void test_visitImplementsClause_single() {
    _assertSource("implements A",
        AstTestFactory.implementsClause([AstTestFactory.namedType4("A")]));
  }

  void test_visitImportDirective_combinator() {
    _assertSource(
        "import 'a.dart' show A;",
        AstTestFactory.importDirective3("a.dart", null, [
          AstTestFactory.showCombinator([AstTestFactory.identifier3("A")])
        ]));
  }

  void test_visitImportDirective_combinators() {
    _assertSource(
        "import 'a.dart' show A hide B;",
        AstTestFactory.importDirective3("a.dart", null, [
          AstTestFactory.showCombinator([AstTestFactory.identifier3("A")]),
          AstTestFactory.hideCombinator([AstTestFactory.identifier3("B")])
        ]));
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
    _assertSource("import 'a.dart' deferred as p;",
        AstTestFactory.importDirective2("a.dart", true, "p"));
  }

  void test_visitImportDirective_minimal() {
    _assertSource(
        "import 'a.dart';", AstTestFactory.importDirective3("a.dart", null));
  }

  void test_visitImportDirective_prefix() {
    _assertSource("import 'a.dart' as p;",
        AstTestFactory.importDirective3("a.dart", "p"));
  }

  void test_visitImportDirective_prefix_combinator() {
    _assertSource(
        "import 'a.dart' as p show A;",
        AstTestFactory.importDirective3("a.dart", "p", [
          AstTestFactory.showCombinator([AstTestFactory.identifier3("A")])
        ]));
  }

  void test_visitImportDirective_prefix_combinators() {
    _assertSource(
        "import 'a.dart' as p show A hide B;",
        AstTestFactory.importDirective3("a.dart", "p", [
          AstTestFactory.showCombinator([AstTestFactory.identifier3("A")]),
          AstTestFactory.hideCombinator([AstTestFactory.identifier3("B")])
        ]));
  }

  void test_visitImportDirective_withMetadata() {
    ImportDirective directive = AstTestFactory.importDirective3("a.dart", null);
    directive.metadata.add(
        AstTestFactory.annotation(AstTestFactory.identifier3("deprecated")));
    _assertSource("@deprecated import 'a.dart';", directive);
  }

  void test_visitImportHideCombinator_multiple() {
    _assertSource(
        "hide a, b",
        AstTestFactory.hideCombinator([
          AstTestFactory.identifier3("a"),
          AstTestFactory.identifier3("b")
        ]));
  }

  void test_visitImportHideCombinator_single() {
    _assertSource("hide a",
        AstTestFactory.hideCombinator([AstTestFactory.identifier3("a")]));
  }

  void test_visitImportShowCombinator_multiple() {
    _assertSource(
        "show a, b",
        AstTestFactory.showCombinator([
          AstTestFactory.identifier3("a"),
          AstTestFactory.identifier3("b")
        ]));
  }

  void test_visitImportShowCombinator_single() {
    _assertSource("show a",
        AstTestFactory.showCombinator([AstTestFactory.identifier3("a")]));
  }

  void test_visitIndexExpression() {
    _assertSource(
      "a[i]",
      AstTestFactory.indexExpression(
        target: AstTestFactory.identifier3("a"),
        index: AstTestFactory.identifier3("i"),
      ),
    );
  }

  void test_visitInstanceCreationExpression_const() {
    _assertSource(
        "const C()",
        AstTestFactory.instanceCreationExpression2(
            Keyword.CONST, AstTestFactory.namedType4("C")));
  }

  void test_visitInstanceCreationExpression_named() {
    _assertSource(
        "new C.c()",
        AstTestFactory.instanceCreationExpression3(
            Keyword.NEW, AstTestFactory.namedType4("C"), "c"));
  }

  void test_visitInstanceCreationExpression_unnamed() {
    _assertSource(
        "new C()",
        AstTestFactory.instanceCreationExpression2(
            Keyword.NEW, AstTestFactory.namedType4("C")));
  }

  void test_visitIntegerLiteral() {
    _assertSource("42", AstTestFactory.integer(42));
  }

  void test_visitInterpolationExpression_expression() {
    _assertSource(
        "\${a}",
        AstTestFactory.interpolationExpression(
            AstTestFactory.identifier3("a")));
  }

  void test_visitInterpolationExpression_identifier() {
    _assertSource("\$a", AstTestFactory.interpolationExpression2("a"));
  }

  void test_visitInterpolationString() {
    _assertSource("'x", AstTestFactory.interpolationString("'x", "x"));
  }

  void test_visitIsExpression_negated() {
    _assertSource(
        "a is! C",
        AstTestFactory.isExpression(AstTestFactory.identifier3("a"), true,
            AstTestFactory.namedType4("C")));
  }

  void test_visitIsExpression_normal() {
    _assertSource(
        "a is C",
        AstTestFactory.isExpression(AstTestFactory.identifier3("a"), false,
            AstTestFactory.namedType4("C")));
  }

  void test_visitLabel() {
    _assertSource("a:", AstTestFactory.label2("a"));
  }

  void test_visitLabeledStatement_multiple() {
    _assertSource(
        "a: b: return;",
        AstTestFactory.labeledStatement(
            [AstTestFactory.label2("a"), AstTestFactory.label2("b")],
            AstTestFactory.returnStatement()));
  }

  void test_visitLabeledStatement_single() {
    _assertSource(
        "a: return;",
        AstTestFactory.labeledStatement(
            [AstTestFactory.label2("a")], AstTestFactory.returnStatement()));
  }

  void test_visitLibraryDirective() {
    _assertSource("library l;", AstTestFactory.libraryDirective2("l"));
  }

  void test_visitLibraryDirective_withMetadata() {
    LibraryDirective directive = AstTestFactory.libraryDirective2("l");
    directive.metadata.add(
        AstTestFactory.annotation(AstTestFactory.identifier3("deprecated")));
    _assertSource("@deprecated library l;", directive);
  }

  void test_visitLibraryIdentifier_multiple() {
    _assertSource(
        "a.b.c",
        AstTestFactory.libraryIdentifier([
          AstTestFactory.identifier3("a"),
          AstTestFactory.identifier3("b"),
          AstTestFactory.identifier3("c")
        ]));
  }

  void test_visitLibraryIdentifier_single() {
    _assertSource("a",
        AstTestFactory.libraryIdentifier([AstTestFactory.identifier3("a")]));
  }

  void test_visitListLiteral_complex() {
    _assertSource(
        '<int>[0, for (e in l) 0, if (b) 1, ...[0]]',
        astFactory.listLiteral(
            null,
            AstTestFactory.typeArgumentList([AstTestFactory.namedType4('int')]),
            Tokens.openSquareBracket(),
            [
              AstTestFactory.integer(0),
              astFactory.forElement(
                  forKeyword: Tokens.for_(),
                  leftParenthesis: Tokens.openParenthesis(),
                  forLoopParts: astFactory.forEachPartsWithIdentifier(
                      identifier: AstTestFactory.identifier3('e'),
                      inKeyword: Tokens.in_(),
                      iterable: AstTestFactory.identifier3('l')),
                  rightParenthesis: Tokens.closeParenthesis(),
                  body: AstTestFactory.integer(0)),
              astFactory.ifElement(
                  ifKeyword: Tokens.if_(),
                  leftParenthesis: Tokens.openParenthesis(),
                  condition: AstTestFactory.identifier3('b'),
                  rightParenthesis: Tokens.closeParenthesis(),
                  thenElement: AstTestFactory.integer(1)),
              astFactory.spreadElement(
                  spreadOperator: TokenFactory.tokenFromType(
                      TokenType.PERIOD_PERIOD_PERIOD),
                  expression: astFactory.listLiteral(
                      null,
                      null,
                      Tokens.openSquareBracket(),
                      [AstTestFactory.integer(0)],
                      Tokens.closeSquareBracket()))
            ],
            Tokens.closeSquareBracket()));
  }

  void test_visitListLiteral_const() {
    _assertSource("const []", AstTestFactory.listLiteral2(Keyword.CONST, null));
  }

  void test_visitListLiteral_empty() {
    _assertSource("[]", AstTestFactory.listLiteral());
  }

  void test_visitListLiteral_nonEmpty() {
    _assertSource(
        "[a, b, c]",
        AstTestFactory.listLiteral([
          AstTestFactory.identifier3("a"),
          AstTestFactory.identifier3("b"),
          AstTestFactory.identifier3("c")
        ]));
  }

  void test_visitListLiteral_withConst_withoutTypeArgs() {
    _assertSource(
        'const [0]',
        astFactory.listLiteral(
            TokenFactory.tokenFromKeyword(Keyword.CONST),
            null,
            Tokens.openSquareBracket(),
            [AstTestFactory.integer(0)],
            Tokens.closeSquareBracket()));
  }

  void test_visitListLiteral_withConst_withTypeArgs() {
    _assertSource(
        'const <int>[0]',
        astFactory.listLiteral(
            TokenFactory.tokenFromKeyword(Keyword.CONST),
            AstTestFactory.typeArgumentList([AstTestFactory.namedType4('int')]),
            Tokens.openSquareBracket(),
            [AstTestFactory.integer(0)],
            Tokens.closeSquareBracket()));
  }

  void test_visitListLiteral_withoutConst_withoutTypeArgs() {
    _assertSource(
        '[0]',
        astFactory.listLiteral(null, null, Tokens.openSquareBracket(),
            [AstTestFactory.integer(0)], Tokens.closeSquareBracket()));
  }

  void test_visitListLiteral_withoutConst_withTypeArgs() {
    _assertSource(
        '<int>[0]',
        astFactory.listLiteral(
            null,
            AstTestFactory.typeArgumentList([AstTestFactory.namedType4('int')]),
            Tokens.openSquareBracket(),
            [AstTestFactory.integer(0)],
            Tokens.closeSquareBracket()));
  }

  void test_visitMapLiteral_const() {
    _assertSource(
        "const {}", AstTestFactory.setOrMapLiteral(Keyword.CONST, null));
  }

  void test_visitMapLiteral_empty() {
    _assertSource("{}", AstTestFactory.setOrMapLiteral(null, null));
  }

  void test_visitMapLiteral_nonEmpty() {
    _assertSource(
        "{'a' : a, 'b' : b, 'c' : c}",
        AstTestFactory.setOrMapLiteral(null, null, [
          AstTestFactory.mapLiteralEntry("a", AstTestFactory.identifier3("a")),
          AstTestFactory.mapLiteralEntry("b", AstTestFactory.identifier3("b")),
          AstTestFactory.mapLiteralEntry("c", AstTestFactory.identifier3("c"))
        ]));
  }

  void test_visitMapLiteralEntry() {
    _assertSource("'a' : b",
        AstTestFactory.mapLiteralEntry("a", AstTestFactory.identifier3("b")));
  }

  void test_visitMethodDeclaration_external() {
    _assertSource(
        "external m();",
        AstTestFactory.methodDeclaration(
            null,
            null,
            null,
            null,
            AstTestFactory.identifier3("m"),
            AstTestFactory.formalParameterList()));
  }

  void test_visitMethodDeclaration_external_returnType() {
    _assertSource(
        "external T m();",
        AstTestFactory.methodDeclaration(
            null,
            AstTestFactory.namedType4("T"),
            null,
            null,
            AstTestFactory.identifier3("m"),
            AstTestFactory.formalParameterList()));
  }

  void test_visitMethodDeclaration_getter() {
    _assertSource(
        "get m {}",
        AstTestFactory.methodDeclaration2(
            null,
            null,
            Keyword.GET,
            null,
            AstTestFactory.identifier3("m"),
            null,
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_getter_returnType() {
    _assertSource(
        "T get m {}",
        AstTestFactory.methodDeclaration2(
            null,
            AstTestFactory.namedType4("T"),
            Keyword.GET,
            null,
            AstTestFactory.identifier3("m"),
            null,
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_getter_seturnType() {
    _assertSource(
        "T set m(var v) {}",
        AstTestFactory.methodDeclaration2(
            null,
            AstTestFactory.namedType4("T"),
            Keyword.SET,
            null,
            AstTestFactory.identifier3("m"),
            AstTestFactory.formalParameterList(
                [AstTestFactory.simpleFormalParameter(Keyword.VAR, "v")]),
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_minimal() {
    _assertSource(
        "m() {}",
        AstTestFactory.methodDeclaration2(
            null,
            null,
            null,
            null,
            AstTestFactory.identifier3("m"),
            AstTestFactory.formalParameterList(),
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_multipleParameters() {
    _assertSource(
        "m(var a, var b) {}",
        AstTestFactory.methodDeclaration2(
            null,
            null,
            null,
            null,
            AstTestFactory.identifier3("m"),
            AstTestFactory.formalParameterList([
              AstTestFactory.simpleFormalParameter(Keyword.VAR, "a"),
              AstTestFactory.simpleFormalParameter(Keyword.VAR, "b")
            ]),
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_operator() {
    _assertSource(
        "operator +() {}",
        AstTestFactory.methodDeclaration2(
            null,
            null,
            null,
            Keyword.OPERATOR,
            AstTestFactory.identifier3("+"),
            AstTestFactory.formalParameterList(),
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_operator_returnType() {
    _assertSource(
        "T operator +() {}",
        AstTestFactory.methodDeclaration2(
            null,
            AstTestFactory.namedType4("T"),
            null,
            Keyword.OPERATOR,
            AstTestFactory.identifier3("+"),
            AstTestFactory.formalParameterList(),
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_returnType() {
    _assertSource(
        "T m() {}",
        AstTestFactory.methodDeclaration2(
            null,
            AstTestFactory.namedType4("T"),
            null,
            null,
            AstTestFactory.identifier3("m"),
            AstTestFactory.formalParameterList(),
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_setter() {
    _assertSource(
        "set m(var v) {}",
        AstTestFactory.methodDeclaration2(
            null,
            null,
            Keyword.SET,
            null,
            AstTestFactory.identifier3("m"),
            AstTestFactory.formalParameterList(
                [AstTestFactory.simpleFormalParameter(Keyword.VAR, "v")]),
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_static() {
    _assertSource(
        "static m() {}",
        AstTestFactory.methodDeclaration2(
            Keyword.STATIC,
            null,
            null,
            null,
            AstTestFactory.identifier3("m"),
            AstTestFactory.formalParameterList(),
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_static_returnType() {
    _assertSource(
        "static T m() {}",
        AstTestFactory.methodDeclaration2(
            Keyword.STATIC,
            AstTestFactory.namedType4("T"),
            null,
            null,
            AstTestFactory.identifier3("m"),
            AstTestFactory.formalParameterList(),
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_typeParameters() {
    _assertSource(
        "m<E>() {}",
        AstTestFactory.methodDeclaration3(
            null,
            null,
            null,
            null,
            AstTestFactory.identifier3("m"),
            AstTestFactory.typeParameterList(['E']),
            AstTestFactory.formalParameterList(),
            AstTestFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_withMetadata() {
    MethodDeclaration declaration = AstTestFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstTestFactory.identifier3("m"),
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody2());
    declaration.metadata.add(
        AstTestFactory.annotation(AstTestFactory.identifier3("deprecated")));
    _assertSource("@deprecated m() {}", declaration);
  }

  void test_visitMethodInvocation_conditional() {
    _assertSource(
        "t?.m()",
        AstTestFactory.methodInvocation(AstTestFactory.identifier3("t"), "m",
            [], TokenType.QUESTION_PERIOD));
  }

  void test_visitMethodInvocation_noTarget() {
    _assertSource("m()", AstTestFactory.methodInvocation2("m"));
  }

  void test_visitMethodInvocation_target() {
    _assertSource("t.m()",
        AstTestFactory.methodInvocation(AstTestFactory.identifier3("t"), "m"));
  }

  void test_visitMethodInvocation_typeArguments() {
    _assertSource(
        "m<A>()",
        AstTestFactory.methodInvocation3(null, "m",
            AstTestFactory.typeArgumentList([AstTestFactory.namedType4('A')])));
  }

  void test_visitNamedExpression() {
    _assertSource("a: b",
        AstTestFactory.namedExpression2("a", AstTestFactory.identifier3("b")));
  }

  void test_visitNamedFormalParameter() {
    _assertSource(
        "var a: 0",
        AstTestFactory.namedFormalParameter(
            AstTestFactory.simpleFormalParameter(Keyword.VAR, "a"),
            AstTestFactory.integer(0)));
  }

  void test_visitNativeClause() {
    _assertSource("native 'code'", AstTestFactory.nativeClause("code"));
  }

  void test_visitNativeFunctionBody() {
    _assertSource("native 'str';", AstTestFactory.nativeFunctionBody("str"));
  }

  void test_visitNullLiteral() {
    _assertSource("null", AstTestFactory.nullLiteral());
  }

  void test_visitParenthesizedExpression() {
    _assertSource(
        "(a)",
        AstTestFactory.parenthesizedExpression(
            AstTestFactory.identifier3("a")));
  }

  void test_visitPartDirective() {
    _assertSource("part 'a.dart';", AstTestFactory.partDirective2("a.dart"));
  }

  void test_visitPartDirective_withMetadata() {
    PartDirective directive = AstTestFactory.partDirective2("a.dart");
    directive.metadata.add(
        AstTestFactory.annotation(AstTestFactory.identifier3("deprecated")));
    _assertSource("@deprecated part 'a.dart';", directive);
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
    PartOfDirective directive = AstTestFactory.partOfDirective(
        AstTestFactory.libraryIdentifier2(["l"]));
    directive.metadata.add(
        AstTestFactory.annotation(AstTestFactory.identifier3("deprecated")));
    _assertSource("@deprecated part of l;", directive);
  }

  void test_visitPositionalFormalParameter() {
    _assertSource(
        "var a = 0",
        AstTestFactory.positionalFormalParameter(
            AstTestFactory.simpleFormalParameter(Keyword.VAR, "a"),
            AstTestFactory.integer(0)));
  }

  void test_visitPostfixExpression() {
    _assertSource(
        "a++",
        AstTestFactory.postfixExpression(
            AstTestFactory.identifier3("a"), TokenType.PLUS_PLUS));
  }

  void test_visitPrefixedIdentifier() {
    _assertSource("a.b", AstTestFactory.identifier5("a", "b"));
  }

  void test_visitPrefixExpression() {
    _assertSource(
        "-a",
        AstTestFactory.prefixExpression(
            TokenType.MINUS, AstTestFactory.identifier3("a")));
  }

  void test_visitPrefixExpression_precedence() {
    var a = AstTestFactory.identifier3('a');
    var b = AstTestFactory.identifier3('b');
    _assertSource(
        '!(a == b)',
        AstTestFactory.prefixExpression(TokenType.BANG,
            AstTestFactory.binaryExpression(a, TokenType.EQ_EQ, b)));
  }

  void test_visitPropertyAccess() {
    _assertSource("a.b",
        AstTestFactory.propertyAccess2(AstTestFactory.identifier3("a"), "b"));
  }

  void test_visitPropertyAccess_conditional() {
    _assertSource(
        "a?.b",
        AstTestFactory.propertyAccess2(
            AstTestFactory.identifier3("a"), "b", TokenType.QUESTION_PERIOD));
  }

  void test_visitRedirectingConstructorInvocation_named() {
    _assertSource(
        "this.c()", AstTestFactory.redirectingConstructorInvocation2("c"));
  }

  void test_visitRedirectingConstructorInvocation_unnamed() {
    _assertSource("this()", AstTestFactory.redirectingConstructorInvocation());
  }

  void test_visitRethrowExpression() {
    _assertSource("rethrow", AstTestFactory.rethrowExpression());
  }

  void test_visitReturnStatement_expression() {
    _assertSource("return a;",
        AstTestFactory.returnStatement2(AstTestFactory.identifier3("a")));
  }

  void test_visitReturnStatement_noExpression() {
    _assertSource("return;", AstTestFactory.returnStatement());
  }

  void test_visitScriptTag() {
    String scriptTag = "!#/bin/dart.exe";
    _assertSource(scriptTag, AstTestFactory.scriptTag(scriptTag));
  }

  void test_visitSetOrMapLiteral_map_complex() {
    _assertSource(
      "<String, String>{'a' : 'b', for (c in d) 'e' : 'f', if (g) 'h' : 'i', ...{'j' : 'k'}}",
      astFactory.setOrMapLiteral(
        leftBracket: Tokens.openCurlyBracket(),
        typeArguments: AstTestFactory.typeArgumentList([
          AstTestFactory.namedType4('String'),
          AstTestFactory.namedType4('String')
        ]),
        elements: [
          AstTestFactory.mapLiteralEntry3('a', 'b'),
          astFactory.forElement(
              forKeyword: Tokens.for_(),
              leftParenthesis: Tokens.openParenthesis(),
              forLoopParts: astFactory.forEachPartsWithIdentifier(
                identifier: AstTestFactory.identifier3('c'),
                inKeyword: Tokens.in_(),
                iterable: AstTestFactory.identifier3('d'),
              ),
              rightParenthesis: Tokens.closeParenthesis(),
              body: AstTestFactory.mapLiteralEntry3('e', 'f')),
          astFactory.ifElement(
            ifKeyword: Tokens.if_(),
            leftParenthesis: Tokens.openParenthesis(),
            condition: AstTestFactory.identifier3('g'),
            rightParenthesis: Tokens.closeParenthesis(),
            thenElement: AstTestFactory.mapLiteralEntry3('h', 'i'),
          ),
          astFactory.spreadElement(
            spreadOperator:
                TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD_PERIOD),
            expression: astFactory.setOrMapLiteral(
              leftBracket: Tokens.openCurlyBracket(),
              elements: [AstTestFactory.mapLiteralEntry3('j', 'k')],
              rightBracket: Tokens.closeCurlyBracket(),
            ),
          )
        ],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_map_withConst_withoutTypeArgs() {
    _assertSource(
      "const {'a' : 'b'}",
      astFactory.setOrMapLiteral(
        leftBracket: Tokens.openCurlyBracket(),
        constKeyword: TokenFactory.tokenFromKeyword(Keyword.CONST),
        elements: [AstTestFactory.mapLiteralEntry3('a', 'b')],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_map_withConst_withTypeArgs() {
    _assertSource(
      "const <String, String>{'a' : 'b'}",
      astFactory.setOrMapLiteral(
        constKeyword: TokenFactory.tokenFromKeyword(Keyword.CONST),
        typeArguments: AstTestFactory.typeArgumentList([
          AstTestFactory.namedType4('String'),
          AstTestFactory.namedType4('String')
        ]),
        leftBracket: Tokens.openCurlyBracket(),
        elements: [AstTestFactory.mapLiteralEntry3('a', 'b')],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_map_withoutConst_withoutTypeArgs() {
    _assertSource(
      "{'a' : 'b'}",
      astFactory.setOrMapLiteral(
        leftBracket: Tokens.openCurlyBracket(),
        elements: [AstTestFactory.mapLiteralEntry3('a', 'b')],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_map_withoutConst_withTypeArgs() {
    _assertSource(
      "<String, String>{'a' : 'b'}",
      astFactory.setOrMapLiteral(
        typeArguments: AstTestFactory.typeArgumentList([
          AstTestFactory.namedType4('String'),
          AstTestFactory.namedType4('String')
        ]),
        leftBracket: Tokens.openCurlyBracket(),
        elements: [AstTestFactory.mapLiteralEntry3('a', 'b')],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_set_complex() {
    _assertSource(
      '<int>{0, for (e in l) 0, if (b) 1, ...[0]}',
      astFactory.setOrMapLiteral(
        typeArguments:
            AstTestFactory.typeArgumentList([AstTestFactory.namedType4('int')]),
        leftBracket: Tokens.openCurlyBracket(),
        elements: [
          AstTestFactory.integer(0),
          astFactory.forElement(
              forKeyword: Tokens.for_(),
              leftParenthesis: Tokens.openParenthesis(),
              forLoopParts: astFactory.forEachPartsWithIdentifier(
                identifier: AstTestFactory.identifier3('e'),
                inKeyword: Tokens.in_(),
                iterable: AstTestFactory.identifier3('l'),
              ),
              rightParenthesis: Tokens.closeParenthesis(),
              body: AstTestFactory.integer(0)),
          astFactory.ifElement(
            ifKeyword: Tokens.if_(),
            leftParenthesis: Tokens.openParenthesis(),
            condition: AstTestFactory.identifier3('b'),
            rightParenthesis: Tokens.closeParenthesis(),
            thenElement: AstTestFactory.integer(1),
          ),
          astFactory.spreadElement(
            spreadOperator:
                TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD_PERIOD),
            expression: astFactory.listLiteral(
              null,
              null,
              Tokens.openSquareBracket(),
              [AstTestFactory.integer(0)],
              Tokens.closeSquareBracket(),
            ),
          )
        ],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_set_withConst_withoutTypeArgs() {
    _assertSource(
      'const {0}',
      astFactory.setOrMapLiteral(
        constKeyword: TokenFactory.tokenFromKeyword(Keyword.CONST),
        leftBracket: Tokens.openCurlyBracket(),
        elements: [AstTestFactory.integer(0)],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_set_withConst_withTypeArgs() {
    _assertSource(
      'const <int>{0}',
      astFactory.setOrMapLiteral(
        constKeyword: TokenFactory.tokenFromKeyword(Keyword.CONST),
        typeArguments:
            AstTestFactory.typeArgumentList([AstTestFactory.namedType4('int')]),
        leftBracket: Tokens.openCurlyBracket(),
        elements: [AstTestFactory.integer(0)],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_set_withoutConst_withoutTypeArgs() {
    _assertSource(
      '{0}',
      astFactory.setOrMapLiteral(
        leftBracket: Tokens.openCurlyBracket(),
        elements: [AstTestFactory.integer(0)],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_set_withoutConst_withTypeArgs() {
    _assertSource(
      '<int>{0}',
      astFactory.setOrMapLiteral(
        typeArguments:
            AstTestFactory.typeArgumentList([AstTestFactory.namedType4('int')]),
        leftBracket: Tokens.openCurlyBracket(),
        elements: [AstTestFactory.integer(0)],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSimpleFormalParameter_annotation() {
    SimpleFormalParameter parameter =
        AstTestFactory.simpleFormalParameter3('x');
    parameter.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("A")));
    _assertSource('@A x', parameter);
  }

  void test_visitSimpleFormalParameter_keyword() {
    _assertSource(
        "var a", AstTestFactory.simpleFormalParameter(Keyword.VAR, "a"));
  }

  void test_visitSimpleFormalParameter_keyword_type() {
    _assertSource(
        "final A a",
        AstTestFactory.simpleFormalParameter2(
            Keyword.FINAL, AstTestFactory.namedType4("A"), "a"));
  }

  void test_visitSimpleFormalParameter_type() {
    _assertSource(
        "A a",
        AstTestFactory.simpleFormalParameter4(
            AstTestFactory.namedType4("A"), "a"));
  }

  void test_visitSimpleFormalParameter_type_covariant() {
    var expected = AstTestFactory.simpleFormalParameter4(
        AstTestFactory.namedType4("A"), "a");
    expected.covariantKeyword =
        TokenFactory.tokenFromKeyword(Keyword.COVARIANT);
    _assertSource("covariant A a", expected);
  }

  void test_visitSimpleIdentifier() {
    _assertSource("a", AstTestFactory.identifier3("a"));
  }

  void test_visitSimpleStringLiteral() {
    _assertSource("'a'", AstTestFactory.string2("a"));
  }

  void test_visitSpreadElement_nonNullable() {
    _assertSource(
        '...[0]',
        astFactory.spreadElement(
            spreadOperator:
                TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD_PERIOD),
            expression: astFactory.listLiteral(
                null,
                null,
                Tokens.openSquareBracket(),
                [AstTestFactory.integer(0)],
                Tokens.closeSquareBracket())));
  }

  @failingTest
  void test_visitSpreadElement_nullable() {
    // TODO(brianwilkerson) Replace the token type below when there is one for
    //  '...?'.
    _assertSource(
        '...?[0]',
        astFactory.spreadElement(
            spreadOperator:
                TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD_PERIOD),
            expression: astFactory.listLiteral(
                null,
                null,
                Tokens.openSquareBracket(),
                [AstTestFactory.integer(0)],
                Tokens.closeSquareBracket())));
  }

  void test_visitStringInterpolation() {
    _assertSource(
        "'a\${e}b'",
        AstTestFactory.string([
          AstTestFactory.interpolationString("'a", "a"),
          AstTestFactory.interpolationExpression(
              AstTestFactory.identifier3("e")),
          AstTestFactory.interpolationString("b'", "b")
        ]));
  }

  void test_visitSuperConstructorInvocation() {
    _assertSource("super()", AstTestFactory.superConstructorInvocation());
  }

  void test_visitSuperConstructorInvocation_named() {
    _assertSource("super.c()", AstTestFactory.superConstructorInvocation2("c"));
  }

  void test_visitSuperExpression() {
    _assertSource("super", AstTestFactory.superExpression());
  }

  void test_visitSuperFormalParameter_annotation() {
    SuperFormalParameter parameter = AstTestFactory.superFormalParameter2('f');
    parameter.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("A")));
    _assertSource('@A super.f', parameter);
  }

  void test_visitSuperFormalParameter_functionTyped() {
    _assertSource(
        "A super.a(b)",
        AstTestFactory.superFormalParameter(
            null,
            AstTestFactory.namedType4("A"),
            "a",
            AstTestFactory.formalParameterList(
                [AstTestFactory.simpleFormalParameter3("b")])));
  }

  void test_visitSuperFormalParameter_functionTyped_typeParameters() {
    _assertSource(
        "A super.a<E, F>(b)",
        astFactory.superFormalParameter(
            type: AstTestFactory.namedType4('A'),
            superKeyword: TokenFactory.tokenFromKeyword(Keyword.SUPER),
            period: TokenFactory.tokenFromType(TokenType.PERIOD),
            identifier: AstTestFactory.identifier3('a'),
            typeParameters: AstTestFactory.typeParameterList(['E', 'F']),
            parameters: AstTestFactory.formalParameterList(
                [AstTestFactory.simpleFormalParameter3("b")])));
  }

  void test_visitSuperFormalParameter_keyword() {
    _assertSource("var super.a",
        AstTestFactory.superFormalParameter(Keyword.VAR, null, "a"));
  }

  void test_visitSuperFormalParameter_keywordAndType() {
    _assertSource(
        "final A super.a",
        AstTestFactory.superFormalParameter(
            Keyword.FINAL, AstTestFactory.namedType4("A"), "a"));
  }

  void test_visitSuperFormalParameter_type() {
    _assertSource(
        "A super.a",
        AstTestFactory.superFormalParameter(
            null, AstTestFactory.namedType4("A"), "a"));
  }

  void test_visitSuperFormalParameter_type_covariant() {
    var expected = AstTestFactory.superFormalParameter(
        null, AstTestFactory.namedType4("A"), "a");
    expected.covariantKeyword =
        TokenFactory.tokenFromKeyword(Keyword.COVARIANT);
    _assertSource("covariant A super.a", expected);
  }

  void test_visitSwitchCase_multipleLabels() {
    _assertSource(
        "l1: l2: case a: {}",
        AstTestFactory.switchCase2(
            [AstTestFactory.label2("l1"), AstTestFactory.label2("l2")],
            AstTestFactory.identifier3("a"),
            [AstTestFactory.block()]));
  }

  void test_visitSwitchCase_multipleStatements() {
    _assertSource(
        "case a: {} {}",
        AstTestFactory.switchCase(AstTestFactory.identifier3("a"),
            [AstTestFactory.block(), AstTestFactory.block()]));
  }

  void test_visitSwitchCase_noLabels() {
    _assertSource(
        "case a: {}",
        AstTestFactory.switchCase(
            AstTestFactory.identifier3("a"), [AstTestFactory.block()]));
  }

  void test_visitSwitchCase_singleLabel() {
    _assertSource(
        "l1: case a: {}",
        AstTestFactory.switchCase2([AstTestFactory.label2("l1")],
            AstTestFactory.identifier3("a"), [AstTestFactory.block()]));
  }

  void test_visitSwitchDefault_multipleLabels() {
    _assertSource(
        "l1: l2: default: {}",
        AstTestFactory.switchDefault(
            [AstTestFactory.label2("l1"), AstTestFactory.label2("l2")],
            [AstTestFactory.block()]));
  }

  void test_visitSwitchDefault_multipleStatements() {
    _assertSource(
        "default: {} {}",
        AstTestFactory.switchDefault2(
            [AstTestFactory.block(), AstTestFactory.block()]));
  }

  void test_visitSwitchDefault_noLabels() {
    _assertSource(
        "default: {}", AstTestFactory.switchDefault2([AstTestFactory.block()]));
  }

  void test_visitSwitchDefault_singleLabel() {
    _assertSource(
        "l1: default: {}",
        AstTestFactory.switchDefault(
            [AstTestFactory.label2("l1")], [AstTestFactory.block()]));
  }

  void test_visitSwitchStatement() {
    _assertSource(
        "switch (a) {case 'b': {} default: {}}",
        AstTestFactory.switchStatement(AstTestFactory.identifier3("a"), [
          AstTestFactory.switchCase(
              AstTestFactory.string2("b"), [AstTestFactory.block()]),
          AstTestFactory.switchDefault2([AstTestFactory.block()])
        ]));
  }

  void test_visitSymbolLiteral_multiple() {
    _assertSource("#a.b.c", AstTestFactory.symbolLiteral(["a", "b", "c"]));
  }

  void test_visitSymbolLiteral_single() {
    _assertSource("#a", AstTestFactory.symbolLiteral(["a"]));
  }

  void test_visitThisExpression() {
    _assertSource("this", AstTestFactory.thisExpression());
  }

  void test_visitThrowStatement() {
    _assertSource("throw e",
        AstTestFactory.throwExpression2(AstTestFactory.identifier3("e")));
  }

  void test_visitTopLevelVariableDeclaration_external() {
    _assertSource(
        "external var a;",
        AstTestFactory.topLevelVariableDeclaration2(
            Keyword.VAR, [AstTestFactory.variableDeclaration("a")],
            isExternal: true));
  }

  void test_visitTopLevelVariableDeclaration_multiple() {
    _assertSource(
        "var a;",
        AstTestFactory.topLevelVariableDeclaration2(
            Keyword.VAR, [AstTestFactory.variableDeclaration("a")]));
  }

  void test_visitTopLevelVariableDeclaration_single() {
    _assertSource(
        "var a, b;",
        AstTestFactory.topLevelVariableDeclaration2(Keyword.VAR, [
          AstTestFactory.variableDeclaration("a"),
          AstTestFactory.variableDeclaration("b")
        ]));
  }

  void test_visitTryStatement_catch() {
    _assertSource(
        "try {} on E {}",
        AstTestFactory.tryStatement2(AstTestFactory.block(),
            [AstTestFactory.catchClause3(AstTestFactory.namedType4("E"))]));
  }

  void test_visitTryStatement_catches() {
    _assertSource(
        "try {} on E {} on F {}",
        AstTestFactory.tryStatement2(AstTestFactory.block(), [
          AstTestFactory.catchClause3(AstTestFactory.namedType4("E")),
          AstTestFactory.catchClause3(AstTestFactory.namedType4("F"))
        ]));
  }

  void test_visitTryStatement_catchFinally() {
    _assertSource(
        "try {} on E {} finally {}",
        AstTestFactory.tryStatement3(
            AstTestFactory.block(),
            [AstTestFactory.catchClause3(AstTestFactory.namedType4("E"))],
            AstTestFactory.block()));
  }

  void test_visitTryStatement_finally() {
    _assertSource(
        "try {} finally {}",
        AstTestFactory.tryStatement(
            AstTestFactory.block(), AstTestFactory.block()));
  }

  void test_visitTypeArgumentList_multiple() {
    _assertSource(
        "<E, F>",
        AstTestFactory.typeArgumentList2(
            [AstTestFactory.namedType4("E"), AstTestFactory.namedType4("F")]));
  }

  void test_visitTypeArgumentList_single() {
    _assertSource("<E>",
        AstTestFactory.typeArgumentList2([AstTestFactory.namedType4("E")]));
  }

  void test_visitTypeName_multipleArgs() {
    _assertSource(
        "C<D, E>",
        AstTestFactory.namedType4("C",
            [AstTestFactory.namedType4("D"), AstTestFactory.namedType4("E")]));
  }

  void test_visitTypeName_nestedArg() {
    _assertSource(
        "C<D<E>>",
        AstTestFactory.namedType4("C", [
          AstTestFactory.namedType4("D", [AstTestFactory.namedType4("E")])
        ]));
  }

  void test_visitTypeName_noArgs() {
    _assertSource("C", AstTestFactory.namedType4("C"));
  }

  void test_visitTypeName_noArgs_withQuestion() {
    _assertSource("C?", AstTestFactory.namedType4("C", null, true));
  }

  void test_visitTypeName_singleArg() {
    _assertSource("C<D>",
        AstTestFactory.namedType4("C", [AstTestFactory.namedType4("D")]));
  }

  void test_visitTypeName_singleArg_withQuestion() {
    _assertSource("C<D>?",
        AstTestFactory.namedType4("C", [AstTestFactory.namedType4("D")], true));
  }

  void test_visitTypeParameter_variance_contravariant() {
    _assertSource("in E", AstTestFactory.typeParameter3("E", "in"));
  }

  void test_visitTypeParameter_variance_covariant() {
    _assertSource("out E", AstTestFactory.typeParameter3("E", "out"));
  }

  void test_visitTypeParameter_variance_invariant() {
    _assertSource("inout E", AstTestFactory.typeParameter3("E", "inout"));
  }

  void test_visitTypeParameter_withExtends() {
    _assertSource("E extends C",
        AstTestFactory.typeParameter2("E", AstTestFactory.namedType4("C")));
  }

  void test_visitTypeParameter_withMetadata() {
    TypeParameter parameter = AstTestFactory.typeParameter("E");
    parameter.metadata.add(
        AstTestFactory.annotation(AstTestFactory.identifier3("deprecated")));
    _assertSource("@deprecated E", parameter);
  }

  void test_visitTypeParameter_withoutExtends() {
    _assertSource("E", AstTestFactory.typeParameter("E"));
  }

  void test_visitTypeParameterList_multiple() {
    _assertSource("<E, F>", AstTestFactory.typeParameterList2(["E", "F"]));
  }

  void test_visitTypeParameterList_single() {
    _assertSource("<E>", AstTestFactory.typeParameterList2(["E"]));
  }

  void test_visitVariableDeclaration_initialized() {
    _assertSource(
        "a = b",
        AstTestFactory.variableDeclaration2(
            "a", AstTestFactory.identifier3("b")));
  }

  void test_visitVariableDeclaration_uninitialized() {
    _assertSource("a", AstTestFactory.variableDeclaration("a"));
  }

  void test_visitVariableDeclaration_withMetadata() {
    VariableDeclaration declaration = AstTestFactory.variableDeclaration("a");
    declaration.metadata.add(
        AstTestFactory.annotation(AstTestFactory.identifier3("deprecated")));
    _assertSource("@deprecated a", declaration);
  }

  void test_visitVariableDeclarationList_const_type() {
    _assertSource(
        "const C a, b",
        AstTestFactory.variableDeclarationList(
            Keyword.CONST, AstTestFactory.namedType4("C"), [
          AstTestFactory.variableDeclaration("a"),
          AstTestFactory.variableDeclaration("b")
        ]));
  }

  void test_visitVariableDeclarationList_final_noType() {
    _assertSource(
        "final a, b",
        AstTestFactory.variableDeclarationList2(Keyword.FINAL, [
          AstTestFactory.variableDeclaration("a"),
          AstTestFactory.variableDeclaration("b")
        ]));
  }

  void test_visitVariableDeclarationList_final_withMetadata() {
    VariableDeclarationList declarationList =
        AstTestFactory.variableDeclarationList2(Keyword.FINAL, [
      AstTestFactory.variableDeclaration("a"),
      AstTestFactory.variableDeclaration("b")
    ]);
    declarationList.metadata.add(
        AstTestFactory.annotation(AstTestFactory.identifier3("deprecated")));
    _assertSource("@deprecated final a, b", declarationList);
  }

  void test_visitVariableDeclarationList_type() {
    _assertSource(
        "C a, b",
        AstTestFactory.variableDeclarationList(
            null, AstTestFactory.namedType4("C"), [
          AstTestFactory.variableDeclaration("a"),
          AstTestFactory.variableDeclaration("b")
        ]));
  }

  void test_visitVariableDeclarationList_var() {
    _assertSource(
        "var a, b",
        AstTestFactory.variableDeclarationList2(Keyword.VAR, [
          AstTestFactory.variableDeclaration("a"),
          AstTestFactory.variableDeclaration("b")
        ]));
  }

  void test_visitVariableDeclarationStatement() {
    _assertSource(
        "C c;",
        AstTestFactory.variableDeclarationStatement(
            null,
            AstTestFactory.namedType4("C"),
            [AstTestFactory.variableDeclaration("c")]));
  }

  void test_visitWhileStatement() {
    _assertSource(
        "while (c) {}",
        AstTestFactory.whileStatement(
            AstTestFactory.identifier3("c"), AstTestFactory.block()));
  }

  void test_visitWithClause_multiple() {
    _assertSource(
        "with A, B, C",
        AstTestFactory.withClause([
          AstTestFactory.namedType4("A"),
          AstTestFactory.namedType4("B"),
          AstTestFactory.namedType4("C")
        ]));
  }

  void test_visitWithClause_single() {
    _assertSource(
        "with A", AstTestFactory.withClause([AstTestFactory.namedType4("A")]));
  }

  void test_visitYieldStatement() {
    _assertSource("yield e;",
        AstTestFactory.yieldStatement(AstTestFactory.identifier3("e")));
  }

  void test_visitYieldStatement_each() {
    _assertSource("yield* e;",
        AstTestFactory.yieldEachStatement(AstTestFactory.identifier3("e")));
  }

  /// Assert that a `ToSourceVisitor2` will produce the [expectedSource] when
  /// visiting the given [node].
  void _assertSource(String expectedSource, AstNode node) {
    StringBuffer buffer = StringBuffer();
    node.accept(ToSourceVisitor(buffer));
    expect(buffer.toString(), expectedSource);
  }
}
