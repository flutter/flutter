// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BooleanArrayTest);
    defineReflectiveTests(LineInfoTest);
    defineReflectiveTests(NodeReplacerTest);
    defineReflectiveTests(SourceRangeTest);
    defineReflectiveTests(StringUtilitiesTest);
  });
}

class AstCloneComparator extends AstComparator {
  final bool expectTokensCopied;

  AstCloneComparator(this.expectTokensCopied);

  @override
  bool isEqualNodes(AstNode? first, AstNode? second) {
    if (first != null && identical(first, second)) {
      fail('Failed to copy node: $first (${first.offset})');
    }
    return super.isEqualNodes(first, second);
  }

  @override
  bool isEqualTokens(Token? first, Token? second) {
    if (expectTokensCopied && first != null && identical(first, second)) {
      fail('Failed to copy token: ${first.lexeme} (${first.offset})');
    }
    var firstComment = first?.precedingComments;
    if (firstComment != null) {
      if (firstComment.parent != first) {
        fail(
            'Failed to link the comment "$firstComment" with the token "$first".');
      }
    }
    return super.isEqualTokens(first, second);
  }
}

@reflectiveTest
class BooleanArrayTest {
  void test_get_negative() {
    try {
      BooleanArray.get(0, -1);
      fail("Expected ");
    } on RangeError {
      // Expected
    }
  }

  void test_get_tooBig() {
    try {
      BooleanArray.get(0, 31);
      fail("Expected ");
    } on RangeError {
      // Expected
    }
  }

  void test_get_valid() {
    expect(BooleanArray.get(0, 0), false);
    expect(BooleanArray.get(1, 0), true);
    expect(BooleanArray.get(0, 30), false);
    expect(BooleanArray.get(1 << 30, 30), true);
  }

  void test_set_negative() {
    try {
      BooleanArray.set(0, -1, true);
      fail("Expected ");
    } on RangeError {
      // Expected
    }
  }

  void test_set_tooBig() {
    try {
      BooleanArray.set(0, 32, true);
      fail("Expected ");
    } on RangeError {
      // Expected
    }
  }

  void test_set_valueChanging() {
    expect(BooleanArray.set(0, 0, true), 1);
    expect(BooleanArray.set(1, 0, false), 0);
    expect(BooleanArray.set(0, 30, true), 1 << 30);
    expect(BooleanArray.set(1 << 30, 30, false), 0);
  }

  void test_set_valuePreserving() {
    expect(BooleanArray.set(0, 0, false), 0);
    expect(BooleanArray.set(1, 0, true), 1);
    expect(BooleanArray.set(0, 30, false), 0);
    expect(BooleanArray.set(1 << 30, 30, true), 1 << 30);
  }
}

class Getter_NodeReplacerTest_test_annotation
    implements NodeReplacerTest_Getter<Annotation, ArgumentList> {
  @override
  ArgumentList? get(Annotation node) => node.arguments;
}

class Getter_NodeReplacerTest_test_annotation_2
    implements NodeReplacerTest_Getter<Annotation, Identifier> {
  @override
  Identifier get(Annotation node) => node.name;
}

class Getter_NodeReplacerTest_test_annotation_3
    implements NodeReplacerTest_Getter<Annotation, SimpleIdentifier> {
  @override
  SimpleIdentifier? get(Annotation node) => node.constructorName;
}

class Getter_NodeReplacerTest_test_annotation_4
    implements NodeReplacerTest_Getter<Annotation, TypeArgumentList> {
  @override
  TypeArgumentList? get(Annotation node) => node.typeArguments;
}

class Getter_NodeReplacerTest_test_asExpression
    implements NodeReplacerTest_Getter<AsExpression, TypeAnnotation> {
  @override
  TypeAnnotation? get(AsExpression node) => node.type;
}

class Getter_NodeReplacerTest_test_asExpression_2
    implements NodeReplacerTest_Getter<AsExpression, Expression> {
  @override
  Expression get(AsExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_assertStatement
    implements NodeReplacerTest_Getter<AssertStatement, Expression> {
  @override
  Expression get(AssertStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_assertStatement_2
    implements NodeReplacerTest_Getter<AssertStatement, Expression> {
  @override
  Expression? get(AssertStatement node) => node.message;
}

class Getter_NodeReplacerTest_test_assignmentExpression
    implements NodeReplacerTest_Getter<AssignmentExpression, Expression> {
  @override
  Expression get(AssignmentExpression node) => node.rightHandSide;
}

class Getter_NodeReplacerTest_test_assignmentExpression_2
    implements NodeReplacerTest_Getter<AssignmentExpression, Expression> {
  @override
  Expression get(AssignmentExpression node) => node.leftHandSide;
}

class Getter_NodeReplacerTest_test_awaitExpression
    implements NodeReplacerTest_Getter<AwaitExpression, Expression> {
  @override
  Expression get(AwaitExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_binaryExpression
    implements NodeReplacerTest_Getter<BinaryExpression, Expression> {
  @override
  Expression get(BinaryExpression node) => node.leftOperand;
}

class Getter_NodeReplacerTest_test_binaryExpression_2
    implements NodeReplacerTest_Getter<BinaryExpression, Expression> {
  @override
  Expression get(BinaryExpression node) => node.rightOperand;
}

class Getter_NodeReplacerTest_test_blockFunctionBody
    implements NodeReplacerTest_Getter<BlockFunctionBody, Block> {
  @override
  Block get(BlockFunctionBody node) => node.block;
}

class Getter_NodeReplacerTest_test_breakStatement
    implements NodeReplacerTest_Getter<BreakStatement, SimpleIdentifier> {
  @override
  SimpleIdentifier? get(BreakStatement node) => node.label;
}

class Getter_NodeReplacerTest_test_cascadeExpression
    implements NodeReplacerTest_Getter<CascadeExpression, Expression> {
  @override
  Expression get(CascadeExpression node) => node.target;
}

class Getter_NodeReplacerTest_test_classDeclaration
    implements NodeReplacerTest_Getter<ClassDeclaration, ImplementsClause> {
  @override
  ImplementsClause? get(ClassDeclaration node) => node.implementsClause;
}

class Getter_NodeReplacerTest_test_classDeclaration_2
    implements NodeReplacerTest_Getter<ClassDeclaration, WithClause> {
  @override
  WithClause? get(ClassDeclaration node) => node.withClause;
}

class Getter_NodeReplacerTest_test_classDeclaration_3
    implements NodeReplacerTest_Getter<ClassDeclaration, NativeClause> {
  @override
  NativeClause? get(ClassDeclaration node) => node.nativeClause;
}

class Getter_NodeReplacerTest_test_classDeclaration_4
    implements NodeReplacerTest_Getter<ClassDeclaration, ExtendsClause> {
  @override
  ExtendsClause? get(ClassDeclaration node) => node.extendsClause;
}

class Getter_NodeReplacerTest_test_classDeclaration_5
    implements NodeReplacerTest_Getter<ClassDeclaration, TypeParameterList> {
  @override
  TypeParameterList? get(ClassDeclaration node) => node.typeParameters;
}

class Getter_NodeReplacerTest_test_classDeclaration_6
    implements NodeReplacerTest_Getter<ClassDeclaration, SimpleIdentifier> {
  @override
  SimpleIdentifier get(ClassDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_classTypeAlias
    implements NodeReplacerTest_Getter<ClassTypeAlias, NamedType> {
  @override
  NamedType get(ClassTypeAlias node) => node.superclass2;
}

class Getter_NodeReplacerTest_test_classTypeAlias_2
    implements NodeReplacerTest_Getter<ClassTypeAlias, ImplementsClause> {
  @override
  ImplementsClause? get(ClassTypeAlias node) => node.implementsClause;
}

class Getter_NodeReplacerTest_test_classTypeAlias_3
    implements NodeReplacerTest_Getter<ClassTypeAlias, WithClause> {
  @override
  WithClause get(ClassTypeAlias node) => node.withClause;
}

class Getter_NodeReplacerTest_test_classTypeAlias_4
    implements NodeReplacerTest_Getter<ClassTypeAlias, SimpleIdentifier> {
  @override
  SimpleIdentifier get(ClassTypeAlias node) => node.name;
}

class Getter_NodeReplacerTest_test_classTypeAlias_5
    implements NodeReplacerTest_Getter<ClassTypeAlias, TypeParameterList> {
  @override
  TypeParameterList? get(ClassTypeAlias node) => node.typeParameters;
}

class Getter_NodeReplacerTest_test_commentReference
    implements
        NodeReplacerTest_Getter<CommentReference, CommentReferableExpression> {
  @override
  CommentReferableExpression get(CommentReference node) => node.expression;
}

class Getter_NodeReplacerTest_test_compilationUnit
    implements NodeReplacerTest_Getter<CompilationUnit, ScriptTag> {
  @override
  ScriptTag? get(CompilationUnit node) => node.scriptTag;
}

class Getter_NodeReplacerTest_test_conditionalExpression
    implements NodeReplacerTest_Getter<ConditionalExpression, Expression> {
  @override
  Expression get(ConditionalExpression node) => node.elseExpression;
}

class Getter_NodeReplacerTest_test_conditionalExpression_2
    implements NodeReplacerTest_Getter<ConditionalExpression, Expression> {
  @override
  Expression get(ConditionalExpression node) => node.thenExpression;
}

class Getter_NodeReplacerTest_test_conditionalExpression_3
    implements NodeReplacerTest_Getter<ConditionalExpression, Expression> {
  @override
  Expression get(ConditionalExpression node) => node.condition;
}

class Getter_NodeReplacerTest_test_constructorDeclaration
    implements
        NodeReplacerTest_Getter<ConstructorDeclaration, ConstructorName> {
  @override
  ConstructorName? get(ConstructorDeclaration node) =>
      node.redirectedConstructor;
}

class Getter_NodeReplacerTest_test_constructorDeclaration_2
    implements
        NodeReplacerTest_Getter<ConstructorDeclaration, SimpleIdentifier> {
  @override
  SimpleIdentifier? get(ConstructorDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_constructorDeclaration_3
    implements NodeReplacerTest_Getter<ConstructorDeclaration, Identifier> {
  @override
  Identifier get(ConstructorDeclaration node) => node.returnType;
}

class Getter_NodeReplacerTest_test_constructorDeclaration_4
    implements
        NodeReplacerTest_Getter<ConstructorDeclaration, FormalParameterList> {
  @override
  FormalParameterList get(ConstructorDeclaration node) => node.parameters;
}

class Getter_NodeReplacerTest_test_constructorDeclaration_5
    implements NodeReplacerTest_Getter<ConstructorDeclaration, FunctionBody> {
  @override
  FunctionBody? get(ConstructorDeclaration node) => node.body;
}

class Getter_NodeReplacerTest_test_constructorFieldInitializer
    implements
        NodeReplacerTest_Getter<ConstructorFieldInitializer, SimpleIdentifier> {
  @override
  SimpleIdentifier get(ConstructorFieldInitializer node) => node.fieldName;
}

class Getter_NodeReplacerTest_test_constructorFieldInitializer_2
    implements
        NodeReplacerTest_Getter<ConstructorFieldInitializer, Expression> {
  @override
  Expression get(ConstructorFieldInitializer node) => node.expression;
}

class Getter_NodeReplacerTest_test_constructorName
    implements NodeReplacerTest_Getter<ConstructorName, NamedType> {
  @override
  NamedType get(ConstructorName node) => node.type2;
}

class Getter_NodeReplacerTest_test_constructorName_2
    implements NodeReplacerTest_Getter<ConstructorName, SimpleIdentifier> {
  @override
  SimpleIdentifier? get(ConstructorName node) => node.name;
}

class Getter_NodeReplacerTest_test_continueStatement
    implements NodeReplacerTest_Getter<ContinueStatement, SimpleIdentifier> {
  @override
  SimpleIdentifier? get(ContinueStatement node) => node.label;
}

class Getter_NodeReplacerTest_test_declaredIdentifier
    implements NodeReplacerTest_Getter<DeclaredIdentifier, TypeAnnotation> {
  @override
  TypeAnnotation? get(DeclaredIdentifier node) => node.type;
}

class Getter_NodeReplacerTest_test_declaredIdentifier_2
    implements NodeReplacerTest_Getter<DeclaredIdentifier, SimpleIdentifier> {
  @override
  SimpleIdentifier get(DeclaredIdentifier node) => node.identifier;
}

class Getter_NodeReplacerTest_test_defaultFormalParameter
    implements
        NodeReplacerTest_Getter<DefaultFormalParameter, NormalFormalParameter> {
  @override
  NormalFormalParameter get(DefaultFormalParameter node) => node.parameter;
}

class Getter_NodeReplacerTest_test_defaultFormalParameter_2
    implements NodeReplacerTest_Getter<DefaultFormalParameter, Expression> {
  @override
  Expression? get(DefaultFormalParameter node) => node.defaultValue;
}

class Getter_NodeReplacerTest_test_doStatement
    implements NodeReplacerTest_Getter<DoStatement, Expression> {
  @override
  Expression get(DoStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_doStatement_2
    implements NodeReplacerTest_Getter<DoStatement, Statement> {
  @override
  Statement get(DoStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_enumConstantDeclaration
    implements
        NodeReplacerTest_Getter<EnumConstantDeclaration, SimpleIdentifier> {
  @override
  SimpleIdentifier get(EnumConstantDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_enumDeclaration
    implements NodeReplacerTest_Getter<EnumDeclaration, SimpleIdentifier> {
  @override
  SimpleIdentifier get(EnumDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_expressionFunctionBody
    implements NodeReplacerTest_Getter<ExpressionFunctionBody, Expression> {
  @override
  Expression get(ExpressionFunctionBody node) => node.expression;
}

class Getter_NodeReplacerTest_test_expressionStatement
    implements NodeReplacerTest_Getter<ExpressionStatement, Expression> {
  @override
  Expression get(ExpressionStatement node) => node.expression;
}

class Getter_NodeReplacerTest_test_extendsClause
    implements NodeReplacerTest_Getter<ExtendsClause, NamedType> {
  @override
  NamedType get(ExtendsClause node) => node.superclass2;
}

class Getter_NodeReplacerTest_test_fieldDeclaration
    implements
        NodeReplacerTest_Getter<FieldDeclaration, VariableDeclarationList> {
  @override
  VariableDeclarationList get(FieldDeclaration node) => node.fields;
}

class Getter_NodeReplacerTest_test_fieldFormalParameter
    implements
        NodeReplacerTest_Getter<FieldFormalParameter, FormalParameterList> {
  @override
  FormalParameterList? get(FieldFormalParameter node) => node.parameters;
}

class Getter_NodeReplacerTest_test_fieldFormalParameter_2
    implements NodeReplacerTest_Getter<FieldFormalParameter, TypeAnnotation> {
  @override
  TypeAnnotation? get(FieldFormalParameter node) => node.type;
}

class Getter_NodeReplacerTest_test_forEachStatement_withIdentifier
    implements NodeReplacerTest_Getter<ForStatement, Statement> {
  @override
  Statement get(ForStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_forEachStatement_withIdentifier_2
    implements NodeReplacerTest_Getter<ForStatement, SimpleIdentifier> {
  @override
  SimpleIdentifier get(ForStatement node) =>
      (node.forLoopParts as ForEachPartsWithIdentifier).identifier;
}

class Getter_NodeReplacerTest_test_forEachStatement_withIdentifier_3
    implements NodeReplacerTest_Getter<ForStatement, Expression> {
  @override
  Expression get(ForStatement node) =>
      (node.forLoopParts as ForEachParts).iterable;
}

class Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable
    implements NodeReplacerTest_Getter<ForStatement, Expression> {
  @override
  Expression get(ForStatement node) =>
      (node.forLoopParts as ForEachParts).iterable;
}

class Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable_2
    implements NodeReplacerTest_Getter<ForStatement, DeclaredIdentifier> {
  @override
  DeclaredIdentifier get(ForStatement node) =>
      (node.forLoopParts as ForEachPartsWithDeclaration).loopVariable;
}

class Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable_3
    implements NodeReplacerTest_Getter<ForStatement, Statement> {
  @override
  Statement get(ForStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_forStatement_withInitialization
    implements NodeReplacerTest_Getter<ForStatement, Statement> {
  @override
  Statement get(ForStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_forStatement_withInitialization_2
    implements NodeReplacerTest_Getter<ForStatement, Expression> {
  @override
  Expression? get(ForStatement node) =>
      (node.forLoopParts as ForParts).condition;
}

class Getter_NodeReplacerTest_test_forStatement_withInitialization_3
    implements NodeReplacerTest_Getter<ForStatement, Expression> {
  @override
  Expression? get(ForStatement node) =>
      (node.forLoopParts as ForPartsWithExpression).initialization;
}

class Getter_NodeReplacerTest_test_forStatement_withVariables
    implements NodeReplacerTest_Getter<ForStatement, Statement> {
  @override
  Statement get(ForStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_forStatement_withVariables_2
    implements NodeReplacerTest_Getter<ForStatement, VariableDeclarationList> {
  @override
  VariableDeclarationList get(ForStatement node) =>
      (node.forLoopParts as ForPartsWithDeclarations).variables;
}

class Getter_NodeReplacerTest_test_forStatement_withVariables_3
    implements NodeReplacerTest_Getter<ForStatement, Expression> {
  @override
  Expression? get(ForStatement node) =>
      (node.forLoopParts as ForParts).condition;
}

class Getter_NodeReplacerTest_test_functionDeclaration
    implements NodeReplacerTest_Getter<FunctionDeclaration, TypeAnnotation> {
  @override
  TypeAnnotation? get(FunctionDeclaration node) => node.returnType;
}

class Getter_NodeReplacerTest_test_functionDeclaration_2
    implements
        NodeReplacerTest_Getter<FunctionDeclaration, FunctionExpression> {
  @override
  FunctionExpression get(FunctionDeclaration node) => node.functionExpression;
}

class Getter_NodeReplacerTest_test_functionDeclaration_3
    implements NodeReplacerTest_Getter<FunctionDeclaration, SimpleIdentifier> {
  @override
  SimpleIdentifier get(FunctionDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_functionDeclarationStatement
    implements
        NodeReplacerTest_Getter<FunctionDeclarationStatement,
            FunctionDeclaration> {
  @override
  FunctionDeclaration get(FunctionDeclarationStatement node) =>
      node.functionDeclaration;
}

class Getter_NodeReplacerTest_test_functionExpression
    implements
        NodeReplacerTest_Getter<FunctionExpression, FormalParameterList> {
  @override
  FormalParameterList? get(FunctionExpression node) => node.parameters;
}

class Getter_NodeReplacerTest_test_functionExpression_2
    implements NodeReplacerTest_Getter<FunctionExpression, FunctionBody> {
  @override
  FunctionBody? get(FunctionExpression node) => node.body;
}

class Getter_NodeReplacerTest_test_functionExpressionInvocation
    implements
        NodeReplacerTest_Getter<FunctionExpressionInvocation, Expression> {
  @override
  Expression get(FunctionExpressionInvocation node) => node.function;
}

class Getter_NodeReplacerTest_test_functionExpressionInvocation_2
    implements
        NodeReplacerTest_Getter<FunctionExpressionInvocation, ArgumentList> {
  @override
  ArgumentList get(FunctionExpressionInvocation node) => node.argumentList;
}

class Getter_NodeReplacerTest_test_functionTypeAlias
    implements NodeReplacerTest_Getter<FunctionTypeAlias, TypeParameterList> {
  @override
  TypeParameterList? get(FunctionTypeAlias node) => node.typeParameters;
}

class Getter_NodeReplacerTest_test_functionTypeAlias_2
    implements NodeReplacerTest_Getter<FunctionTypeAlias, FormalParameterList> {
  @override
  FormalParameterList get(FunctionTypeAlias node) => node.parameters;
}

class Getter_NodeReplacerTest_test_functionTypeAlias_3
    implements NodeReplacerTest_Getter<FunctionTypeAlias, TypeAnnotation> {
  @override
  TypeAnnotation? get(FunctionTypeAlias node) => node.returnType;
}

class Getter_NodeReplacerTest_test_functionTypeAlias_4
    implements NodeReplacerTest_Getter<FunctionTypeAlias, SimpleIdentifier> {
  @override
  SimpleIdentifier get(FunctionTypeAlias node) => node.name;
}

class Getter_NodeReplacerTest_test_functionTypedFormalParameter
    implements
        NodeReplacerTest_Getter<FunctionTypedFormalParameter, TypeAnnotation> {
  @override
  TypeAnnotation? get(FunctionTypedFormalParameter node) => node.returnType;
}

class Getter_NodeReplacerTest_test_functionTypedFormalParameter_2
    implements
        NodeReplacerTest_Getter<FunctionTypedFormalParameter,
            FormalParameterList> {
  @override
  FormalParameterList get(FunctionTypedFormalParameter node) => node.parameters;
}

class Getter_NodeReplacerTest_test_ifStatement
    implements NodeReplacerTest_Getter<IfStatement, Expression> {
  @override
  Expression get(IfStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_ifStatement_2
    implements NodeReplacerTest_Getter<IfStatement, Statement> {
  @override
  Statement? get(IfStatement node) => node.elseStatement;
}

class Getter_NodeReplacerTest_test_ifStatement_3
    implements NodeReplacerTest_Getter<IfStatement, Statement> {
  @override
  Statement get(IfStatement node) => node.thenStatement;
}

class Getter_NodeReplacerTest_test_importDirective
    implements NodeReplacerTest_Getter<ImportDirective, SimpleIdentifier> {
  @override
  SimpleIdentifier? get(ImportDirective node) => node.prefix;
}

class Getter_NodeReplacerTest_test_indexExpression
    implements NodeReplacerTest_Getter<IndexExpression, Expression> {
  @override
  Expression? get(IndexExpression node) => node.target;
}

class Getter_NodeReplacerTest_test_indexExpression_2
    implements NodeReplacerTest_Getter<IndexExpression, Expression> {
  @override
  Expression get(IndexExpression node) => node.index;
}

class Getter_NodeReplacerTest_test_instanceCreationExpression
    implements
        NodeReplacerTest_Getter<InstanceCreationExpression, ArgumentList> {
  @override
  ArgumentList get(InstanceCreationExpression node) => node.argumentList;
}

class Getter_NodeReplacerTest_test_instanceCreationExpression_2
    implements
        NodeReplacerTest_Getter<InstanceCreationExpression, ConstructorName> {
  @override
  ConstructorName get(InstanceCreationExpression node) => node.constructorName;
}

class Getter_NodeReplacerTest_test_interpolationExpression
    implements NodeReplacerTest_Getter<InterpolationExpression, Expression> {
  @override
  Expression get(InterpolationExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_isExpression
    implements NodeReplacerTest_Getter<IsExpression, Expression> {
  @override
  Expression get(IsExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_isExpression_2
    implements NodeReplacerTest_Getter<IsExpression, TypeAnnotation> {
  @override
  TypeAnnotation? get(IsExpression node) => node.type;
}

class Getter_NodeReplacerTest_test_label
    implements NodeReplacerTest_Getter<Label, SimpleIdentifier> {
  @override
  SimpleIdentifier get(Label node) => node.label;
}

class Getter_NodeReplacerTest_test_labeledStatement
    implements NodeReplacerTest_Getter<LabeledStatement, Statement> {
  @override
  Statement get(LabeledStatement node) => node.statement;
}

class Getter_NodeReplacerTest_test_libraryDirective
    implements NodeReplacerTest_Getter<LibraryDirective, LibraryIdentifier> {
  @override
  LibraryIdentifier get(LibraryDirective node) => node.name;
}

class Getter_NodeReplacerTest_test_mapLiteralEntry
    implements NodeReplacerTest_Getter<MapLiteralEntry, Expression> {
  @override
  Expression get(MapLiteralEntry node) => node.value;
}

class Getter_NodeReplacerTest_test_mapLiteralEntry_2
    implements NodeReplacerTest_Getter<MapLiteralEntry, Expression> {
  @override
  Expression get(MapLiteralEntry node) => node.key;
}

class Getter_NodeReplacerTest_test_methodDeclaration
    implements NodeReplacerTest_Getter<MethodDeclaration, TypeAnnotation> {
  @override
  TypeAnnotation? get(MethodDeclaration node) => node.returnType;
}

class Getter_NodeReplacerTest_test_methodDeclaration_2
    implements NodeReplacerTest_Getter<MethodDeclaration, FunctionBody> {
  @override
  FunctionBody get(MethodDeclaration node) => node.body;
}

class Getter_NodeReplacerTest_test_methodDeclaration_3
    implements NodeReplacerTest_Getter<MethodDeclaration, SimpleIdentifier> {
  @override
  SimpleIdentifier get(MethodDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_methodDeclaration_4
    implements NodeReplacerTest_Getter<MethodDeclaration, FormalParameterList> {
  @override
  FormalParameterList? get(MethodDeclaration node) => node.parameters;
}

class Getter_NodeReplacerTest_test_methodInvocation
    implements NodeReplacerTest_Getter<MethodInvocation, ArgumentList> {
  @override
  ArgumentList get(MethodInvocation node) => node.argumentList;
}

class Getter_NodeReplacerTest_test_methodInvocation_2
    implements NodeReplacerTest_Getter<MethodInvocation, Expression> {
  @override
  Expression? get(MethodInvocation node) => node.target;
}

class Getter_NodeReplacerTest_test_methodInvocation_3
    implements NodeReplacerTest_Getter<MethodInvocation, SimpleIdentifier> {
  @override
  SimpleIdentifier get(MethodInvocation node) => node.methodName;
}

class Getter_NodeReplacerTest_test_namedExpression
    implements NodeReplacerTest_Getter<NamedExpression, Label> {
  @override
  Label get(NamedExpression node) => node.name;
}

class Getter_NodeReplacerTest_test_namedExpression_2
    implements NodeReplacerTest_Getter<NamedExpression, Expression> {
  @override
  Expression get(NamedExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_nativeClause
    implements NodeReplacerTest_Getter<NativeClause, StringLiteral> {
  @override
  StringLiteral? get(NativeClause node) => node.name;
}

class Getter_NodeReplacerTest_test_nativeFunctionBody
    implements NodeReplacerTest_Getter<NativeFunctionBody, StringLiteral> {
  @override
  StringLiteral? get(NativeFunctionBody node) => node.stringLiteral;
}

class Getter_NodeReplacerTest_test_parenthesizedExpression
    implements NodeReplacerTest_Getter<ParenthesizedExpression, Expression> {
  @override
  Expression get(ParenthesizedExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_partOfDirective
    implements NodeReplacerTest_Getter<PartOfDirective, LibraryIdentifier> {
  @override
  LibraryIdentifier? get(PartOfDirective node) => node.libraryName;
}

class Getter_NodeReplacerTest_test_postfixExpression
    implements NodeReplacerTest_Getter<PostfixExpression, Expression> {
  @override
  Expression get(PostfixExpression node) => node.operand;
}

class Getter_NodeReplacerTest_test_prefixedIdentifier
    implements NodeReplacerTest_Getter<PrefixedIdentifier, SimpleIdentifier> {
  @override
  SimpleIdentifier get(PrefixedIdentifier node) => node.identifier;
}

class Getter_NodeReplacerTest_test_prefixedIdentifier_2
    implements NodeReplacerTest_Getter<PrefixedIdentifier, SimpleIdentifier> {
  @override
  SimpleIdentifier get(PrefixedIdentifier node) => node.prefix;
}

class Getter_NodeReplacerTest_test_prefixExpression
    implements NodeReplacerTest_Getter<PrefixExpression, Expression> {
  @override
  Expression get(PrefixExpression node) => node.operand;
}

class Getter_NodeReplacerTest_test_propertyAccess
    implements NodeReplacerTest_Getter<PropertyAccess, Expression> {
  @override
  Expression? get(PropertyAccess node) => node.target;
}

class Getter_NodeReplacerTest_test_propertyAccess_2
    implements NodeReplacerTest_Getter<PropertyAccess, SimpleIdentifier> {
  @override
  SimpleIdentifier get(PropertyAccess node) => node.propertyName;
}

class Getter_NodeReplacerTest_test_redirectingConstructorInvocation
    implements
        NodeReplacerTest_Getter<RedirectingConstructorInvocation,
            SimpleIdentifier> {
  @override
  SimpleIdentifier? get(RedirectingConstructorInvocation node) =>
      node.constructorName;
}

class Getter_NodeReplacerTest_test_redirectingConstructorInvocation_2
    implements
        NodeReplacerTest_Getter<RedirectingConstructorInvocation,
            ArgumentList> {
  @override
  ArgumentList get(RedirectingConstructorInvocation node) => node.argumentList;
}

class Getter_NodeReplacerTest_test_returnStatement
    implements NodeReplacerTest_Getter<ReturnStatement, Expression> {
  @override
  Expression? get(ReturnStatement node) => node.expression;
}

class Getter_NodeReplacerTest_test_simpleFormalParameter
    implements NodeReplacerTest_Getter<SimpleFormalParameter, TypeAnnotation> {
  @override
  TypeAnnotation? get(SimpleFormalParameter node) => node.type;
}

class Getter_NodeReplacerTest_test_superConstructorInvocation
    implements
        NodeReplacerTest_Getter<SuperConstructorInvocation, SimpleIdentifier> {
  @override
  SimpleIdentifier? get(SuperConstructorInvocation node) =>
      node.constructorName;
}

class Getter_NodeReplacerTest_test_superConstructorInvocation_2
    implements
        NodeReplacerTest_Getter<SuperConstructorInvocation, ArgumentList> {
  @override
  ArgumentList get(SuperConstructorInvocation node) => node.argumentList;
}

class Getter_NodeReplacerTest_test_switchCase
    implements NodeReplacerTest_Getter<SwitchCase, Expression> {
  @override
  Expression get(SwitchCase node) => node.expression;
}

class Getter_NodeReplacerTest_test_switchStatement
    implements NodeReplacerTest_Getter<SwitchStatement, Expression> {
  @override
  Expression get(SwitchStatement node) => node.expression;
}

class Getter_NodeReplacerTest_test_throwExpression
    implements NodeReplacerTest_Getter<ThrowExpression, Expression> {
  @override
  Expression get(ThrowExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_topLevelVariableDeclaration
    implements
        NodeReplacerTest_Getter<TopLevelVariableDeclaration,
            VariableDeclarationList> {
  @override
  VariableDeclarationList get(TopLevelVariableDeclaration node) =>
      node.variables;
}

class Getter_NodeReplacerTest_test_tryStatement
    implements NodeReplacerTest_Getter<TryStatement, Block> {
  @override
  Block? get(TryStatement node) => node.finallyBlock;
}

class Getter_NodeReplacerTest_test_tryStatement_2
    implements NodeReplacerTest_Getter<TryStatement, Block> {
  @override
  Block get(TryStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_typeName
    implements NodeReplacerTest_Getter<NamedType, TypeArgumentList> {
  @override
  TypeArgumentList? get(NamedType node) => node.typeArguments;
}

class Getter_NodeReplacerTest_test_typeName_2
    implements NodeReplacerTest_Getter<NamedType, Identifier> {
  @override
  Identifier get(NamedType node) => node.name;
}

class Getter_NodeReplacerTest_test_typeParameter
    implements NodeReplacerTest_Getter<TypeParameter, TypeAnnotation> {
  @override
  TypeAnnotation? get(TypeParameter node) => node.bound;
}

class Getter_NodeReplacerTest_test_typeParameter_2
    implements NodeReplacerTest_Getter<TypeParameter, SimpleIdentifier> {
  @override
  SimpleIdentifier get(TypeParameter node) => node.name;
}

class Getter_NodeReplacerTest_test_variableDeclaration
    implements NodeReplacerTest_Getter<VariableDeclaration, SimpleIdentifier> {
  @override
  SimpleIdentifier get(VariableDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_variableDeclaration_2
    implements NodeReplacerTest_Getter<VariableDeclaration, Expression> {
  @override
  Expression? get(VariableDeclaration node) => node.initializer;
}

class Getter_NodeReplacerTest_test_variableDeclarationList
    implements
        NodeReplacerTest_Getter<VariableDeclarationList, TypeAnnotation> {
  @override
  TypeAnnotation? get(VariableDeclarationList node) => node.type;
}

class Getter_NodeReplacerTest_test_variableDeclarationStatement
    implements
        NodeReplacerTest_Getter<VariableDeclarationStatement,
            VariableDeclarationList> {
  @override
  VariableDeclarationList get(VariableDeclarationStatement node) =>
      node.variables;
}

class Getter_NodeReplacerTest_test_whileStatement
    implements NodeReplacerTest_Getter<WhileStatement, Expression> {
  @override
  Expression get(WhileStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_whileStatement_2
    implements NodeReplacerTest_Getter<WhileStatement, Statement> {
  @override
  Statement get(WhileStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_yieldStatement
    implements NodeReplacerTest_Getter<YieldStatement, Expression> {
  @override
  Expression get(YieldStatement node) => node.expression;
}

class Getter_NodeReplacerTest_testAnnotatedNode
    implements NodeReplacerTest_Getter<AnnotatedNode, Comment> {
  @override
  Comment? get(AnnotatedNode node) => node.documentationComment;
}

class Getter_NodeReplacerTest_testNormalFormalParameter
    implements
        NodeReplacerTest_Getter<NormalFormalParameter, SimpleIdentifier> {
  @override
  SimpleIdentifier? get(NormalFormalParameter node) => node.identifier;
}

class Getter_NodeReplacerTest_testNormalFormalParameter_2
    implements NodeReplacerTest_Getter<NormalFormalParameter, Comment> {
  @override
  Comment? get(NormalFormalParameter node) => node.documentationComment;
}

class Getter_NodeReplacerTest_testTypedLiteral
    implements NodeReplacerTest_Getter<TypedLiteral, TypeArgumentList> {
  @override
  TypeArgumentList? get(TypedLiteral node) => node.typeArguments;
}

class Getter_NodeReplacerTest_testUriBasedDirective
    implements NodeReplacerTest_Getter<UriBasedDirective, StringLiteral> {
  @override
  StringLiteral get(UriBasedDirective node) => node.uri;
}

@reflectiveTest
class LineInfoTest {
  void test_creation() {
    expect(LineInfo(<int>[0]), isNotNull);
  }

  void test_creation_empty() {
    expect(() {
      LineInfo(<int>[]);
    }, throwsArgumentError);
  }

  void test_getLocation_firstLine() {
    LineInfo info = LineInfo(<int>[0, 12, 34]);
    var location = info.getLocation(4);
    expect(location.lineNumber, 1);
    expect(location.columnNumber, 5);
  }

  void test_getLocation_lastLine() {
    LineInfo info = LineInfo(<int>[0, 12, 34]);
    var location = info.getLocation(36);
    expect(location.lineNumber, 3);
    expect(location.columnNumber, 3);
  }

  void test_getLocation_middleLine() {
    LineInfo info = LineInfo(<int>[0, 12, 34]);
    var location = info.getLocation(12);
    expect(location.lineNumber, 2);
    expect(location.columnNumber, 1);
  }

  void test_getOffsetOfLine() {
    LineInfo info = LineInfo(<int>[0, 12, 34]);
    expect(0, info.getOffsetOfLine(0));
    expect(12, info.getOffsetOfLine(1));
    expect(34, info.getOffsetOfLine(2));
  }

  void test_getOffsetOfLineAfter() {
    LineInfo info = LineInfo(<int>[0, 12, 34]);

    expect(info.getOffsetOfLineAfter(0), 12);
    expect(info.getOffsetOfLineAfter(11), 12);

    expect(info.getOffsetOfLineAfter(12), 34);
    expect(info.getOffsetOfLineAfter(33), 34);
  }
}

class ListGetter_NodeReplacerTest_test_adjacentStrings
    extends NodeReplacerTest_ListGetter<AdjacentStrings, StringLiteral> {
  ListGetter_NodeReplacerTest_test_adjacentStrings(int arg0) : super(arg0);

  @override
  NodeList<StringLiteral> getList(AdjacentStrings node) => node.strings;
}

class ListGetter_NodeReplacerTest_test_adjacentStrings_2
    extends NodeReplacerTest_ListGetter<AdjacentStrings, StringLiteral> {
  ListGetter_NodeReplacerTest_test_adjacentStrings_2(int arg0) : super(arg0);

  @override
  NodeList<StringLiteral> getList(AdjacentStrings node) => node.strings;
}

class ListGetter_NodeReplacerTest_test_argumentList
    extends NodeReplacerTest_ListGetter<ArgumentList, Expression> {
  ListGetter_NodeReplacerTest_test_argumentList(int arg0) : super(arg0);

  @override
  NodeList<Expression> getList(ArgumentList node) => node.arguments;
}

class ListGetter_NodeReplacerTest_test_block
    extends NodeReplacerTest_ListGetter<Block, Statement> {
  ListGetter_NodeReplacerTest_test_block(int arg0) : super(arg0);

  @override
  NodeList<Statement> getList(Block node) => node.statements;
}

class ListGetter_NodeReplacerTest_test_cascadeExpression
    extends NodeReplacerTest_ListGetter<CascadeExpression, Expression> {
  ListGetter_NodeReplacerTest_test_cascadeExpression(int arg0) : super(arg0);

  @override
  NodeList<Expression> getList(CascadeExpression node) => node.cascadeSections;
}

class ListGetter_NodeReplacerTest_test_classDeclaration
    extends NodeReplacerTest_ListGetter<ClassDeclaration, ClassMember> {
  ListGetter_NodeReplacerTest_test_classDeclaration(int arg0) : super(arg0);

  @override
  NodeList<ClassMember> getList(ClassDeclaration node) => node.members;
}

class ListGetter_NodeReplacerTest_test_comment
    extends NodeReplacerTest_ListGetter<Comment, CommentReference> {
  ListGetter_NodeReplacerTest_test_comment(int arg0) : super(arg0);

  @override
  NodeList<CommentReference> getList(Comment node) => node.references;
}

class ListGetter_NodeReplacerTest_test_compilationUnit
    extends NodeReplacerTest_ListGetter<CompilationUnit, Directive> {
  ListGetter_NodeReplacerTest_test_compilationUnit(int arg0) : super(arg0);

  @override
  NodeList<Directive> getList(CompilationUnit node) => node.directives;
}

class ListGetter_NodeReplacerTest_test_compilationUnit_2
    extends NodeReplacerTest_ListGetter<CompilationUnit,
        CompilationUnitMember> {
  ListGetter_NodeReplacerTest_test_compilationUnit_2(int arg0) : super(arg0);

  @override
  NodeList<CompilationUnitMember> getList(CompilationUnit node) =>
      node.declarations;
}

class ListGetter_NodeReplacerTest_test_constructorDeclaration
    extends NodeReplacerTest_ListGetter<ConstructorDeclaration,
        ConstructorInitializer> {
  ListGetter_NodeReplacerTest_test_constructorDeclaration(int arg0)
      : super(arg0);

  @override
  NodeList<ConstructorInitializer> getList(ConstructorDeclaration node) =>
      node.initializers;
}

class ListGetter_NodeReplacerTest_test_formalParameterList
    extends NodeReplacerTest_ListGetter<FormalParameterList, FormalParameter> {
  ListGetter_NodeReplacerTest_test_formalParameterList(int arg0) : super(arg0);

  @override
  NodeList<FormalParameter> getList(FormalParameterList node) =>
      node.parameters;
}

class ListGetter_NodeReplacerTest_test_forStatement_withInitialization
    extends NodeReplacerTest_ListGetter<ForStatement, Expression> {
  ListGetter_NodeReplacerTest_test_forStatement_withInitialization(int arg0)
      : super(arg0);

  @override
  NodeList<Expression> getList(ForStatement node) =>
      (node.forLoopParts as ForParts).updaters;
}

class ListGetter_NodeReplacerTest_test_forStatement_withVariables
    extends NodeReplacerTest_ListGetter<ForStatement, Expression> {
  ListGetter_NodeReplacerTest_test_forStatement_withVariables(int arg0)
      : super(arg0);

  @override
  NodeList<Expression> getList(ForStatement node) =>
      (node.forLoopParts as ForParts).updaters;
}

class ListGetter_NodeReplacerTest_test_hideCombinator
    extends NodeReplacerTest_ListGetter<HideCombinator, SimpleIdentifier> {
  ListGetter_NodeReplacerTest_test_hideCombinator(int arg0) : super(arg0);

  @override
  NodeList<SimpleIdentifier> getList(HideCombinator node) => node.hiddenNames;
}

class ListGetter_NodeReplacerTest_test_implementsClause
    extends NodeReplacerTest_ListGetter<ImplementsClause, NamedType> {
  ListGetter_NodeReplacerTest_test_implementsClause(int arg0) : super(arg0);

  @override
  NodeList<NamedType> getList(ImplementsClause node) => node.interfaces2;
}

class ListGetter_NodeReplacerTest_test_labeledStatement
    extends NodeReplacerTest_ListGetter<LabeledStatement, Label> {
  ListGetter_NodeReplacerTest_test_labeledStatement(int arg0) : super(arg0);

  @override
  NodeList<Label> getList(LabeledStatement node) => node.labels;
}

class ListGetter_NodeReplacerTest_test_libraryIdentifier
    extends NodeReplacerTest_ListGetter<LibraryIdentifier, SimpleIdentifier> {
  ListGetter_NodeReplacerTest_test_libraryIdentifier(int arg0) : super(arg0);

  @override
  NodeList<SimpleIdentifier> getList(LibraryIdentifier node) => node.components;
}

class ListGetter_NodeReplacerTest_test_listLiteral
    extends NodeReplacerTest_ListGetter<ListLiteral, CollectionElement> {
  ListGetter_NodeReplacerTest_test_listLiteral(int arg0) : super(arg0);

  @override
  NodeList<CollectionElement> getList(ListLiteral node) => node.elements;
}

class ListGetter_NodeReplacerTest_test_mapLiteral
    extends NodeReplacerTest_ListGetter<SetOrMapLiteral, CollectionElement> {
  ListGetter_NodeReplacerTest_test_mapLiteral(int arg0) : super(arg0);

  @override
  NodeList<CollectionElement> getList(SetOrMapLiteral node) => node.elements;
}

class ListGetter_NodeReplacerTest_test_showCombinator
    extends NodeReplacerTest_ListGetter<ShowCombinator, SimpleIdentifier> {
  ListGetter_NodeReplacerTest_test_showCombinator(int arg0) : super(arg0);

  @override
  NodeList<SimpleIdentifier> getList(ShowCombinator node) => node.shownNames;
}

class ListGetter_NodeReplacerTest_test_stringInterpolation
    extends NodeReplacerTest_ListGetter<StringInterpolation,
        InterpolationElement> {
  ListGetter_NodeReplacerTest_test_stringInterpolation(int arg0) : super(arg0);

  @override
  NodeList<InterpolationElement> getList(StringInterpolation node) =>
      node.elements;
}

class ListGetter_NodeReplacerTest_test_switchStatement
    extends NodeReplacerTest_ListGetter<SwitchStatement, SwitchMember> {
  ListGetter_NodeReplacerTest_test_switchStatement(int arg0) : super(arg0);

  @override
  NodeList<SwitchMember> getList(SwitchStatement node) => node.members;
}

class ListGetter_NodeReplacerTest_test_tryStatement
    extends NodeReplacerTest_ListGetter<TryStatement, CatchClause> {
  ListGetter_NodeReplacerTest_test_tryStatement(int arg0) : super(arg0);

  @override
  NodeList<CatchClause> getList(TryStatement node) => node.catchClauses;
}

class ListGetter_NodeReplacerTest_test_typeArgumentList
    extends NodeReplacerTest_ListGetter<TypeArgumentList, TypeAnnotation> {
  ListGetter_NodeReplacerTest_test_typeArgumentList(int arg0) : super(arg0);

  @override
  NodeList<TypeAnnotation> getList(TypeArgumentList node) => node.arguments;
}

class ListGetter_NodeReplacerTest_test_typeParameterList
    extends NodeReplacerTest_ListGetter<TypeParameterList, TypeParameter> {
  ListGetter_NodeReplacerTest_test_typeParameterList(int arg0) : super(arg0);

  @override
  NodeList<TypeParameter> getList(TypeParameterList node) =>
      node.typeParameters;
}

class ListGetter_NodeReplacerTest_test_variableDeclarationList
    extends NodeReplacerTest_ListGetter<VariableDeclarationList,
        VariableDeclaration> {
  ListGetter_NodeReplacerTest_test_variableDeclarationList(int arg0)
      : super(arg0);

  @override
  NodeList<VariableDeclaration> getList(VariableDeclarationList node) =>
      node.variables;
}

class ListGetter_NodeReplacerTest_test_withClause
    extends NodeReplacerTest_ListGetter<WithClause, NamedType> {
  ListGetter_NodeReplacerTest_test_withClause(int arg0) : super(arg0);

  @override
  NodeList<NamedType> getList(WithClause node) => node.mixinTypes2;
}

class ListGetter_NodeReplacerTest_testAnnotatedNode
    extends NodeReplacerTest_ListGetter<AnnotatedNode, Annotation> {
  ListGetter_NodeReplacerTest_testAnnotatedNode(int arg0) : super(arg0);

  @override
  NodeList<Annotation> getList(AnnotatedNode node) => node.metadata;
}

class ListGetter_NodeReplacerTest_testNamespaceDirective
    extends NodeReplacerTest_ListGetter<NamespaceDirective, Combinator> {
  ListGetter_NodeReplacerTest_testNamespaceDirective(int arg0) : super(arg0);

  @override
  NodeList<Combinator> getList(NamespaceDirective node) => node.combinators;
}

class ListGetter_NodeReplacerTest_testNormalFormalParameter
    extends NodeReplacerTest_ListGetter<NormalFormalParameter, Annotation> {
  ListGetter_NodeReplacerTest_testNormalFormalParameter(int arg0) : super(arg0);

  @override
  NodeList<Annotation> getList(NormalFormalParameter node) => node.metadata;
}

class ListGetter_NodeReplacerTest_testSwitchMember
    extends NodeReplacerTest_ListGetter<SwitchMember, Label> {
  ListGetter_NodeReplacerTest_testSwitchMember(int arg0) : super(arg0);

  @override
  NodeList<Label> getList(SwitchMember node) => node.labels;
}

class ListGetter_NodeReplacerTest_testSwitchMember_2
    extends NodeReplacerTest_ListGetter<SwitchMember, Statement> {
  ListGetter_NodeReplacerTest_testSwitchMember_2(int arg0) : super(arg0);

  @override
  NodeList<Statement> getList(SwitchMember node) => node.statements;
}

@reflectiveTest
class NodeReplacerTest {
  /// An empty list of tokens.
  static const List<Token> EMPTY_TOKEN_LIST = <Token>[];

  void test_adjacentStrings() {
    AdjacentStrings node = AstTestFactory.adjacentStrings(
        [AstTestFactory.string2("a"), AstTestFactory.string2("b")]);
    _assertReplace(node, ListGetter_NodeReplacerTest_test_adjacentStrings_2(0));
    _assertReplace(node, ListGetter_NodeReplacerTest_test_adjacentStrings(1));
  }

  void test_annotation() {
    Annotation node = AstTestFactory.annotation2(
        AstTestFactory.identifier3("C"),
        AstTestFactory.identifier3("c"),
        AstTestFactory.argumentList([AstTestFactory.integer(0)]));
    _assertReplace(node, Getter_NodeReplacerTest_test_annotation());
    _assertReplace(node, Getter_NodeReplacerTest_test_annotation_3());
    _assertReplace(node, Getter_NodeReplacerTest_test_annotation_2());
  }

  void test_annotation_generic() {
    Annotation node = AstTestFactory.annotation2(
        AstTestFactory.identifier3("C"),
        AstTestFactory.identifier3("c"),
        AstTestFactory.argumentList([AstTestFactory.integer(0)]),
        typeArguments:
            AstTestFactory.typeArgumentList2([AstTestFactory.namedType4('T')]));
    _assertReplace(node, Getter_NodeReplacerTest_test_annotation());
    _assertReplace(node, Getter_NodeReplacerTest_test_annotation_3());
    _assertReplace(node, Getter_NodeReplacerTest_test_annotation_2());
  }

  void test_argumentList() {
    ArgumentList node =
        AstTestFactory.argumentList([AstTestFactory.integer(0)]);
    _assertReplace(node, ListGetter_NodeReplacerTest_test_argumentList(0));
  }

  void test_asExpression() {
    AsExpression node = AstTestFactory.asExpression(
        AstTestFactory.integer(0),
        AstTestFactory.namedType3(
            AstTestFactory.identifier3("a"), [AstTestFactory.namedType4("C")]));
    _assertReplace(node, Getter_NodeReplacerTest_test_asExpression_2());
    _assertReplace(node, Getter_NodeReplacerTest_test_asExpression());
  }

  void test_assertStatement() {
    AssertStatement node = AstTestFactory.assertStatement(
        AstTestFactory.booleanLiteral(true), AstTestFactory.string2('foo'));
    _assertReplace(node, Getter_NodeReplacerTest_test_assertStatement());
    _assertReplace(node, Getter_NodeReplacerTest_test_assertStatement_2());
  }

  void test_assignmentExpression() {
    AssignmentExpression node = AstTestFactory.assignmentExpression(
        AstTestFactory.identifier3("l"),
        TokenType.EQ,
        AstTestFactory.identifier3("r"));
    _assertReplace(node, Getter_NodeReplacerTest_test_assignmentExpression_2());
    _assertReplace(node, Getter_NodeReplacerTest_test_assignmentExpression());
  }

  void test_awaitExpression() {
    var node = AstTestFactory.awaitExpression(AstTestFactory.identifier3("A"));
    _assertReplace(node, Getter_NodeReplacerTest_test_awaitExpression());
  }

  void test_binaryExpression() {
    BinaryExpression node = AstTestFactory.binaryExpression(
        AstTestFactory.identifier3("l"),
        TokenType.PLUS,
        AstTestFactory.identifier3("r"));
    _assertReplace(node, Getter_NodeReplacerTest_test_binaryExpression());
    _assertReplace(node, Getter_NodeReplacerTest_test_binaryExpression_2());
  }

  void test_block() {
    Block node = AstTestFactory.block([AstTestFactory.emptyStatement()]);
    _assertReplace(node, ListGetter_NodeReplacerTest_test_block(0));
  }

  void test_blockFunctionBody() {
    BlockFunctionBody node =
        AstTestFactory.blockFunctionBody(AstTestFactory.block());
    _assertReplace(node, Getter_NodeReplacerTest_test_blockFunctionBody());
  }

  void test_breakStatement() {
    BreakStatement node = AstTestFactory.breakStatement2("l");
    _assertReplace(node, Getter_NodeReplacerTest_test_breakStatement());
  }

  void test_cascadeExpression() {
    CascadeExpression node = AstTestFactory.cascadeExpression(
        AstTestFactory.integer(0),
        [AstTestFactory.propertyAccess(null, AstTestFactory.identifier3("b"))]);
    _assertReplace(node, Getter_NodeReplacerTest_test_cascadeExpression());
    _assertReplace(node, ListGetter_NodeReplacerTest_test_cascadeExpression(0));
  }

  void test_catchClause() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  try {} on E catch (e, st) {}
  try {} on E2 catch (e2, st2) {}
}
''');
    _assertReplace2<CatchClause>(
      destination: findNode.catchClause('(e,'),
      source: findNode.catchClause('(e2,'),
      getters: [
        (node) => node.exceptionType!,
        (node) => node.exceptionParameter!,
        (node) => node.stackTraceParameter!,
        (node) => node.body,
      ],
    );
  }

  void test_classDeclaration() {
    var node = AstTestFactory.classDeclaration(
        null,
        "A",
        AstTestFactory.typeParameterList(["E"]),
        AstTestFactory.extendsClause(AstTestFactory.namedType4("B")),
        AstTestFactory.withClause([AstTestFactory.namedType4("C")]),
        AstTestFactory.implementsClause([AstTestFactory.namedType4("D")]), [
      AstTestFactory.fieldDeclaration2(
          false, null, [AstTestFactory.variableDeclaration("f")])
    ]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    node.nativeClause = AstTestFactory.nativeClause("");
    _assertReplace(node, Getter_NodeReplacerTest_test_classDeclaration_6());
    _assertReplace(node, Getter_NodeReplacerTest_test_classDeclaration_5());
    _assertReplace(node, Getter_NodeReplacerTest_test_classDeclaration_4());
    _assertReplace(node, Getter_NodeReplacerTest_test_classDeclaration_2());
    _assertReplace(node, Getter_NodeReplacerTest_test_classDeclaration());
    _assertReplace(node, Getter_NodeReplacerTest_test_classDeclaration_3());
    _assertReplace(node, ListGetter_NodeReplacerTest_test_classDeclaration(0));
    _testAnnotatedNode(node);
  }

  void test_classTypeAlias() {
    var node = AstTestFactory.classTypeAlias(
        "A",
        AstTestFactory.typeParameterList(["E"]),
        null,
        AstTestFactory.namedType4("B"),
        AstTestFactory.withClause([AstTestFactory.namedType4("C")]),
        AstTestFactory.implementsClause([AstTestFactory.namedType4("D")]));
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, Getter_NodeReplacerTest_test_classTypeAlias_4());
    _assertReplace(node, Getter_NodeReplacerTest_test_classTypeAlias_5());
    _assertReplace(node, Getter_NodeReplacerTest_test_classTypeAlias());
    _assertReplace(node, Getter_NodeReplacerTest_test_classTypeAlias_3());
    _assertReplace(node, Getter_NodeReplacerTest_test_classTypeAlias_2());
    _testAnnotatedNode(node);
  }

  void test_comment() {
    Comment node = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.references.add(
        astFactory.commentReference(null, AstTestFactory.identifier3("x")));
    _assertReplace(node, ListGetter_NodeReplacerTest_test_comment(0));
  }

  void test_commentReference() {
    CommentReference node =
        astFactory.commentReference(null, AstTestFactory.identifier3("x"));
    _assertReplace(node, Getter_NodeReplacerTest_test_commentReference());
  }

  void test_compilationUnit() {
    CompilationUnit node = AstTestFactory.compilationUnit8("", [
      AstTestFactory.libraryDirective2("lib")
    ], [
      AstTestFactory.topLevelVariableDeclaration2(
          null, [AstTestFactory.variableDeclaration("X")])
    ]);
    _assertReplace(node, Getter_NodeReplacerTest_test_compilationUnit());
    _assertReplace(node, ListGetter_NodeReplacerTest_test_compilationUnit(0));
    _assertReplace(node, ListGetter_NodeReplacerTest_test_compilationUnit_2(0));
  }

  void test_conditionalExpression() {
    ConditionalExpression node = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(true),
        AstTestFactory.integer(0),
        AstTestFactory.integer(1));
    _assertReplace(
        node, Getter_NodeReplacerTest_test_conditionalExpression_3());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_conditionalExpression_2());
    _assertReplace(node, Getter_NodeReplacerTest_test_conditionalExpression());
  }

  void test_constructorDeclaration() {
    var node = AstTestFactory.constructorDeclaration2(
        null,
        null,
        AstTestFactory.identifier3("C"),
        "d",
        AstTestFactory.formalParameterList(),
        [
          AstTestFactory.constructorFieldInitializer(
              false, "x", AstTestFactory.integer(0))
        ],
        AstTestFactory.emptyFunctionBody());
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    node.redirectedConstructor =
        AstTestFactory.constructorName(AstTestFactory.namedType4("B"), "a");
    _assertReplace(
        node, Getter_NodeReplacerTest_test_constructorDeclaration_3());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_constructorDeclaration_2());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_constructorDeclaration_4());
    _assertReplace(node, Getter_NodeReplacerTest_test_constructorDeclaration());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_constructorDeclaration_5());
    _assertReplace(
        node, ListGetter_NodeReplacerTest_test_constructorDeclaration(0));
    _testAnnotatedNode(node);
  }

  void test_constructorFieldInitializer() {
    ConstructorFieldInitializer node =
        AstTestFactory.constructorFieldInitializer(
            false, "f", AstTestFactory.integer(0));
    _assertReplace(
        node, Getter_NodeReplacerTest_test_constructorFieldInitializer());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_constructorFieldInitializer_2());
  }

  void test_constructorName() {
    ConstructorName node =
        AstTestFactory.constructorName(AstTestFactory.namedType4("C"), "n");
    _assertReplace(node, Getter_NodeReplacerTest_test_constructorName());
    _assertReplace(node, Getter_NodeReplacerTest_test_constructorName_2());
  }

  void test_continueStatement() {
    ContinueStatement node = AstTestFactory.continueStatement("l");
    _assertReplace(node, Getter_NodeReplacerTest_test_continueStatement());
  }

  void test_declaredIdentifier() {
    var node =
        AstTestFactory.declaredIdentifier4(AstTestFactory.namedType4("C"), "i");
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, Getter_NodeReplacerTest_test_declaredIdentifier());
    _assertReplace(node, Getter_NodeReplacerTest_test_declaredIdentifier_2());
    _testAnnotatedNode(node);
  }

  void test_defaultFormalParameter() {
    DefaultFormalParameter node = AstTestFactory.positionalFormalParameter(
        AstTestFactory.simpleFormalParameter3("p"), AstTestFactory.integer(0));
    _assertReplace(node, Getter_NodeReplacerTest_test_defaultFormalParameter());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_defaultFormalParameter_2());
  }

  void test_doStatement() {
    DoStatement node = AstTestFactory.doStatement(
        AstTestFactory.block(), AstTestFactory.booleanLiteral(true));
    _assertReplace(node, Getter_NodeReplacerTest_test_doStatement_2());
    _assertReplace(node, Getter_NodeReplacerTest_test_doStatement());
  }

  void test_enumConstantDeclaration() {
    EnumConstantDeclaration node = astFactory.enumConstantDeclaration(
        astFactory.endOfLineComment(EMPTY_TOKEN_LIST),
        [AstTestFactory.annotation(AstTestFactory.identifier3("a"))],
        AstTestFactory.identifier3("C"));
    _assertReplace(
        node, Getter_NodeReplacerTest_test_enumConstantDeclaration());
    _testAnnotatedNode(node);
  }

  void test_enumDeclaration() {
    var node = AstTestFactory.enumDeclaration2("E", ["ONE", "TWO"]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, Getter_NodeReplacerTest_test_enumDeclaration());
    _testAnnotatedNode(node);
  }

  void test_exportDirective() {
    var node = AstTestFactory.exportDirective2("", [
      AstTestFactory.hideCombinator2(["C"])
    ]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _testNamespaceDirective(node);
  }

  void test_expressionFunctionBody() {
    ExpressionFunctionBody node =
        AstTestFactory.expressionFunctionBody(AstTestFactory.integer(0));
    _assertReplace(node, Getter_NodeReplacerTest_test_expressionFunctionBody());
  }

  void test_expressionStatement() {
    ExpressionStatement node =
        AstTestFactory.expressionStatement(AstTestFactory.integer(0));
    _assertReplace(node, Getter_NodeReplacerTest_test_expressionStatement());
  }

  void test_extendsClause() {
    ExtendsClause node =
        AstTestFactory.extendsClause(AstTestFactory.namedType4("S"));
    _assertReplace(node, Getter_NodeReplacerTest_test_extendsClause());
  }

  void test_fieldDeclaration() {
    var node = AstTestFactory.fieldDeclaration(
        false,
        null,
        AstTestFactory.namedType4("C"),
        [AstTestFactory.variableDeclaration("c")]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, Getter_NodeReplacerTest_test_fieldDeclaration());
    _testAnnotatedNode(node);
  }

  void test_fieldFormalParameter() {
    var node = AstTestFactory.fieldFormalParameter(
        null,
        AstTestFactory.namedType4("C"),
        "f",
        AstTestFactory.formalParameterList());
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [
      AstTestFactory.annotation(AstTestFactory.identifier3("a"))
    ];
    _assertReplace(node, Getter_NodeReplacerTest_test_fieldFormalParameter_2());
    _assertReplace(node, Getter_NodeReplacerTest_test_fieldFormalParameter());
    _testNormalFormalParameter(node);
  }

  void test_forEachStatement_withIdentifier() {
    ForStatement node = AstTestFactory.forStatement(
        AstTestFactory.forEachPartsWithIdentifier(
            AstTestFactory.identifier3("i"), AstTestFactory.identifier3("l")),
        AstTestFactory.block());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_forEachStatement_withIdentifier_2());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_forEachStatement_withIdentifier_3());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_forEachStatement_withIdentifier());
  }

  void test_forEachStatement_withLoopVariable() {
    ForStatement node = AstTestFactory.forStatement(
        AstTestFactory.forEachPartsWithDeclaration(
            AstTestFactory.declaredIdentifier3("e"),
            AstTestFactory.identifier3("l")),
        AstTestFactory.block());
    _assertReplace(node,
        Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable_2());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable());
    _assertReplace(node,
        Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable_3());
  }

  void test_formalParameterList() {
    FormalParameterList node = AstTestFactory.formalParameterList(
        [AstTestFactory.simpleFormalParameter3("p")]);
    _assertReplace(
        node, ListGetter_NodeReplacerTest_test_formalParameterList(0));
  }

  void test_forStatement_withInitialization() {
    ForStatement node = AstTestFactory.forStatement(
        AstTestFactory.forPartsWithExpression(AstTestFactory.identifier3("a"),
            AstTestFactory.booleanLiteral(true), [AstTestFactory.integer(0)]),
        AstTestFactory.block());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_forStatement_withInitialization_3());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_forStatement_withInitialization_2());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_forStatement_withInitialization());
    _assertReplace(node,
        ListGetter_NodeReplacerTest_test_forStatement_withInitialization(0));
  }

  void test_forStatement_withVariables() {
    ForStatement node = AstTestFactory.forStatement(
        AstTestFactory.forPartsWithDeclarations(
            AstTestFactory.variableDeclarationList2(
                null, [AstTestFactory.variableDeclaration("i")]),
            AstTestFactory.booleanLiteral(true),
            [AstTestFactory.integer(0)]),
        AstTestFactory.block());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_forStatement_withVariables_2());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_forStatement_withVariables_3());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_forStatement_withVariables());
    _assertReplace(
        node, ListGetter_NodeReplacerTest_test_forStatement_withVariables(0));
  }

  void test_functionDeclaration() {
    var node = AstTestFactory.functionDeclaration(
        AstTestFactory.namedType4("R"),
        null,
        "f",
        AstTestFactory.functionExpression2(AstTestFactory.formalParameterList(),
            AstTestFactory.blockFunctionBody(AstTestFactory.block())));
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, Getter_NodeReplacerTest_test_functionDeclaration());
    _assertReplace(node, Getter_NodeReplacerTest_test_functionDeclaration_3());
    _assertReplace(node, Getter_NodeReplacerTest_test_functionDeclaration_2());
    _testAnnotatedNode(node);
  }

  void test_functionDeclarationStatement() {
    FunctionDeclarationStatement node =
        AstTestFactory.functionDeclarationStatement(
            AstTestFactory.namedType4("R"),
            null,
            "f",
            AstTestFactory.functionExpression2(
                AstTestFactory.formalParameterList(),
                AstTestFactory.blockFunctionBody(AstTestFactory.block())));
    _assertReplace(
        node, Getter_NodeReplacerTest_test_functionDeclarationStatement());
  }

  void test_functionExpression() {
    FunctionExpression node = AstTestFactory.functionExpression2(
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody(AstTestFactory.block()));
    _assertReplace(node, Getter_NodeReplacerTest_test_functionExpression());
    _assertReplace(node, Getter_NodeReplacerTest_test_functionExpression_2());
  }

  void test_functionExpressionInvocation() {
    FunctionExpressionInvocation node =
        AstTestFactory.functionExpressionInvocation(
            AstTestFactory.identifier3("f"), [AstTestFactory.integer(0)]);
    _assertReplace(
        node, Getter_NodeReplacerTest_test_functionExpressionInvocation());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_functionExpressionInvocation_2());
  }

  void test_functionTypeAlias() {
    var node = AstTestFactory.typeAlias(
        AstTestFactory.namedType4("R"),
        "F",
        AstTestFactory.typeParameterList(["E"]),
        AstTestFactory.formalParameterList());
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, Getter_NodeReplacerTest_test_functionTypeAlias_3());
    _assertReplace(node, Getter_NodeReplacerTest_test_functionTypeAlias_4());
    _assertReplace(node, Getter_NodeReplacerTest_test_functionTypeAlias());
    _assertReplace(node, Getter_NodeReplacerTest_test_functionTypeAlias_2());
    _testAnnotatedNode(node);
  }

  void test_functionTypedFormalParameter() {
    var node = AstTestFactory.functionTypedFormalParameter(
        AstTestFactory.namedType4("R"),
        "f",
        [AstTestFactory.simpleFormalParameter3("p")]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [
      AstTestFactory.annotation(AstTestFactory.identifier3("a"))
    ];
    _assertReplace(
        node, Getter_NodeReplacerTest_test_functionTypedFormalParameter());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_functionTypedFormalParameter_2());
    _testNormalFormalParameter(node);
  }

  void test_hideCombinator() {
    HideCombinator node = AstTestFactory.hideCombinator2(["A", "B"]);
    _assertReplace(node, ListGetter_NodeReplacerTest_test_hideCombinator(0));
  }

  void test_ifStatement() {
    IfStatement node = AstTestFactory.ifStatement2(
        AstTestFactory.booleanLiteral(true),
        AstTestFactory.block(),
        AstTestFactory.block());
    _assertReplace(node, Getter_NodeReplacerTest_test_ifStatement());
    _assertReplace(node, Getter_NodeReplacerTest_test_ifStatement_3());
    _assertReplace(node, Getter_NodeReplacerTest_test_ifStatement_2());
  }

  void test_implementsClause() {
    ImplementsClause node = AstTestFactory.implementsClause(
        [AstTestFactory.namedType4("I"), AstTestFactory.namedType4("J")]);
    _assertReplace(node, ListGetter_NodeReplacerTest_test_implementsClause(0));
  }

  void test_importDirective() {
    var node = AstTestFactory.importDirective3("", "p", [
      AstTestFactory.showCombinator2(["A"]),
      AstTestFactory.hideCombinator2(["B"])
    ]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, Getter_NodeReplacerTest_test_importDirective());
    _testNamespaceDirective(node);
  }

  void test_indexExpression() {
    IndexExpression node = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.identifier3("i"),
    );
    _assertReplace(node, Getter_NodeReplacerTest_test_indexExpression());
    _assertReplace(node, Getter_NodeReplacerTest_test_indexExpression_2());
  }

  void test_instanceCreationExpression() {
    InstanceCreationExpression node =
        AstTestFactory.instanceCreationExpression3(null,
            AstTestFactory.namedType4("C"), "c", [AstTestFactory.integer(2)]);
    _assertReplace(
        node, Getter_NodeReplacerTest_test_instanceCreationExpression_2());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_instanceCreationExpression());
  }

  void test_interpolationExpression() {
    InterpolationExpression node = AstTestFactory.interpolationExpression2("x");
    _assertReplace(
        node, Getter_NodeReplacerTest_test_interpolationExpression());
  }

  void test_isExpression() {
    IsExpression node = AstTestFactory.isExpression(
        AstTestFactory.identifier3("v"), false, AstTestFactory.namedType4("T"));
    _assertReplace(node, Getter_NodeReplacerTest_test_isExpression());
    _assertReplace(node, Getter_NodeReplacerTest_test_isExpression_2());
  }

  void test_label() {
    Label node = AstTestFactory.label2("l");
    _assertReplace(node, Getter_NodeReplacerTest_test_label());
  }

  void test_labeledStatement() {
    LabeledStatement node = AstTestFactory.labeledStatement(
        [AstTestFactory.label2("l")], AstTestFactory.block());
    _assertReplace(node, ListGetter_NodeReplacerTest_test_labeledStatement(0));
    _assertReplace(node, Getter_NodeReplacerTest_test_labeledStatement());
  }

  void test_libraryDirective() {
    var node = AstTestFactory.libraryDirective2("lib");
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, Getter_NodeReplacerTest_test_libraryDirective());
    _testAnnotatedNode(node);
  }

  void test_libraryIdentifier() {
    LibraryIdentifier node = AstTestFactory.libraryIdentifier2(["lib"]);
    _assertReplace(node, ListGetter_NodeReplacerTest_test_libraryIdentifier(0));
  }

  void test_listLiteral() {
    ListLiteral node = AstTestFactory.listLiteral2(
        null,
        AstTestFactory.typeArgumentList([AstTestFactory.namedType4("E")]),
        [AstTestFactory.identifier3("e")]);
    _assertReplace(node, ListGetter_NodeReplacerTest_test_listLiteral(0));
    _testTypedLiteral(node);
  }

  void test_mapLiteral() {
    SetOrMapLiteral node = AstTestFactory.setOrMapLiteral(
        null,
        AstTestFactory.typeArgumentList([AstTestFactory.namedType4("E")]),
        [AstTestFactory.mapLiteralEntry("k", AstTestFactory.identifier3("v"))]);
    _assertReplace(node, ListGetter_NodeReplacerTest_test_mapLiteral(0));
    _testTypedLiteral(node);
  }

  void test_mapLiteralEntry() {
    MapLiteralEntry node =
        AstTestFactory.mapLiteralEntry("k", AstTestFactory.identifier3("v"));
    _assertReplace(node, Getter_NodeReplacerTest_test_mapLiteralEntry_2());
    _assertReplace(node, Getter_NodeReplacerTest_test_mapLiteralEntry());
  }

  void test_methodDeclaration() {
    var node = AstTestFactory.methodDeclaration2(
        null,
        AstTestFactory.namedType4("A"),
        null,
        null,
        AstTestFactory.identifier3("m"),
        AstTestFactory.formalParameterList(),
        AstTestFactory.blockFunctionBody(AstTestFactory.block()));
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, Getter_NodeReplacerTest_test_methodDeclaration());
    _assertReplace(node, Getter_NodeReplacerTest_test_methodDeclaration_3());
    _assertReplace(node, Getter_NodeReplacerTest_test_methodDeclaration_4());
    _assertReplace(node, Getter_NodeReplacerTest_test_methodDeclaration_2());
    _testAnnotatedNode(node);
  }

  void test_methodInvocation() {
    MethodInvocation node = AstTestFactory.methodInvocation(
        AstTestFactory.identifier3("t"), "m", [AstTestFactory.integer(0)]);
    _assertReplace(node, Getter_NodeReplacerTest_test_methodInvocation_2());
    _assertReplace(node, Getter_NodeReplacerTest_test_methodInvocation_3());
    _assertReplace(node, Getter_NodeReplacerTest_test_methodInvocation());
  }

  void test_namedExpression() {
    NamedExpression node =
        AstTestFactory.namedExpression2("l", AstTestFactory.identifier3("v"));
    _assertReplace(node, Getter_NodeReplacerTest_test_namedExpression());
    _assertReplace(node, Getter_NodeReplacerTest_test_namedExpression_2());
  }

  void test_nativeClause() {
    NativeClause node = AstTestFactory.nativeClause("");
    _assertReplace(node, Getter_NodeReplacerTest_test_nativeClause());
  }

  void test_nativeFunctionBody() {
    NativeFunctionBody node = AstTestFactory.nativeFunctionBody("m");
    _assertReplace(node, Getter_NodeReplacerTest_test_nativeFunctionBody());
  }

  void test_parenthesizedExpression() {
    ParenthesizedExpression node =
        AstTestFactory.parenthesizedExpression(AstTestFactory.integer(0));
    _assertReplace(
        node, Getter_NodeReplacerTest_test_parenthesizedExpression());
  }

  void test_partDirective() {
    var node = AstTestFactory.partDirective2("");
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _testUriBasedDirective(node);
  }

  void test_partOfDirective() {
    var node = AstTestFactory.partOfDirective(
        AstTestFactory.libraryIdentifier2(["lib"]));
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, Getter_NodeReplacerTest_test_partOfDirective());
    _testAnnotatedNode(node);
  }

  void test_postfixExpression() {
    PostfixExpression node = AstTestFactory.postfixExpression(
        AstTestFactory.identifier3("x"), TokenType.MINUS_MINUS);
    _assertReplace(node, Getter_NodeReplacerTest_test_postfixExpression());
  }

  void test_prefixedIdentifier() {
    PrefixedIdentifier node = AstTestFactory.identifier5("a", "b");
    _assertReplace(node, Getter_NodeReplacerTest_test_prefixedIdentifier_2());
    _assertReplace(node, Getter_NodeReplacerTest_test_prefixedIdentifier());
  }

  void test_prefixExpression() {
    PrefixExpression node = AstTestFactory.prefixExpression(
        TokenType.PLUS_PLUS, AstTestFactory.identifier3("y"));
    _assertReplace(node, Getter_NodeReplacerTest_test_prefixExpression());
  }

  void test_propertyAccess() {
    PropertyAccess node =
        AstTestFactory.propertyAccess2(AstTestFactory.identifier3("x"), "y");
    _assertReplace(node, Getter_NodeReplacerTest_test_propertyAccess());
    _assertReplace(node, Getter_NodeReplacerTest_test_propertyAccess_2());
  }

  void test_redirectingConstructorInvocation() {
    RedirectingConstructorInvocation node =
        AstTestFactory.redirectingConstructorInvocation2(
            "c", [AstTestFactory.integer(0)]);
    _assertReplace(
        node, Getter_NodeReplacerTest_test_redirectingConstructorInvocation());
    _assertReplace(node,
        Getter_NodeReplacerTest_test_redirectingConstructorInvocation_2());
  }

  void test_returnStatement() {
    ReturnStatement node =
        AstTestFactory.returnStatement2(AstTestFactory.integer(0));
    _assertReplace(node, Getter_NodeReplacerTest_test_returnStatement());
  }

  void test_showCombinator() {
    ShowCombinator node = AstTestFactory.showCombinator2(["X", "Y"]);
    _assertReplace(node, ListGetter_NodeReplacerTest_test_showCombinator(0));
  }

  void test_simpleFormalParameter() {
    var node = AstTestFactory.simpleFormalParameter4(
        AstTestFactory.namedType4("T"), "p");
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [
      AstTestFactory.annotation(AstTestFactory.identifier3("a"))
    ];
    _assertReplace(node, Getter_NodeReplacerTest_test_simpleFormalParameter());
    _testNormalFormalParameter(node);
  }

  void test_stringInterpolation() {
    var unit = parseString(content: 'var v = "first \$x last";').unit;
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    var variable = declaration.variables.variables[0];
    var node = variable.initializer as StringInterpolation;
    _assertReplace(
        node, ListGetter_NodeReplacerTest_test_stringInterpolation(0));
  }

  void test_superConstructorInvocation() {
    SuperConstructorInvocation node =
        AstTestFactory.superConstructorInvocation2(
            "s", [AstTestFactory.integer(1)]);
    _assertReplace(
        node, Getter_NodeReplacerTest_test_superConstructorInvocation());
    _assertReplace(
        node, Getter_NodeReplacerTest_test_superConstructorInvocation_2());
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/47741')
  void test_superFormalParameter() {
    var findNode = _parseStringToFindNode(r'''
class A {
  A(int foo<T>(int a));
}

class B extends A {
  B.sub1(double super.bar1<T1>(int a1),);
  B.sub2(double super.bar2<T2>(int a2),);
}
''');
    _assertReplace2<SuperFormalParameter>(
      destination: findNode.superFormalParameter('bar1'),
      source: findNode.superFormalParameter('bar2'),
      getters: [
        (node) => node.type!,
        (node) => node.identifier,
        (node) => node.typeParameters!,
        (node) => node.parameters!,
      ],
    );
  }

  void test_switchCase() {
    SwitchCase node = AstTestFactory.switchCase2([AstTestFactory.label2("l")],
        AstTestFactory.integer(0), [AstTestFactory.block()]);
    _assertReplace(node, Getter_NodeReplacerTest_test_switchCase());
    _testSwitchMember(node);
  }

  void test_switchDefault() {
    SwitchDefault node = AstTestFactory.switchDefault(
        [AstTestFactory.label2("l")], [AstTestFactory.block()]);
    _testSwitchMember(node);
  }

  void test_switchStatement() {
    SwitchStatement node =
        AstTestFactory.switchStatement(AstTestFactory.identifier3("x"), [
      AstTestFactory.switchCase2([AstTestFactory.label2("l")],
          AstTestFactory.integer(0), [AstTestFactory.block()]),
      AstTestFactory.switchDefault(
          [AstTestFactory.label2("l")], [AstTestFactory.block()])
    ]);
    _assertReplace(node, Getter_NodeReplacerTest_test_switchStatement());
    _assertReplace(node, ListGetter_NodeReplacerTest_test_switchStatement(0));
  }

  void test_throwExpression() {
    ThrowExpression node =
        AstTestFactory.throwExpression2(AstTestFactory.identifier3("e"));
    _assertReplace(node, Getter_NodeReplacerTest_test_throwExpression());
  }

  void test_topLevelVariableDeclaration() {
    var node = AstTestFactory.topLevelVariableDeclaration(
        null,
        AstTestFactory.namedType4("T"),
        [AstTestFactory.variableDeclaration("t")]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(
        node, Getter_NodeReplacerTest_test_topLevelVariableDeclaration());
    _testAnnotatedNode(node);
  }

  void test_tryStatement() {
    TryStatement node = AstTestFactory.tryStatement3(
        AstTestFactory.block(),
        [
          AstTestFactory.catchClause("e", [AstTestFactory.block()])
        ],
        AstTestFactory.block());
    _assertReplace(node, Getter_NodeReplacerTest_test_tryStatement_2());
    _assertReplace(node, Getter_NodeReplacerTest_test_tryStatement());
    _assertReplace(node, ListGetter_NodeReplacerTest_test_tryStatement(0));
  }

  void test_typeArgumentList() {
    TypeArgumentList node =
        AstTestFactory.typeArgumentList2([AstTestFactory.namedType4("A")]);
    _assertReplace(node, ListGetter_NodeReplacerTest_test_typeArgumentList(0));
  }

  void test_typeName() {
    NamedType node = AstTestFactory.namedType4(
        "T", [AstTestFactory.namedType4("E"), AstTestFactory.namedType4("F")]);
    _assertReplace(node, Getter_NodeReplacerTest_test_typeName_2());
    _assertReplace(node, Getter_NodeReplacerTest_test_typeName());
  }

  void test_typeParameter() {
    TypeParameter node =
        AstTestFactory.typeParameter2("E", AstTestFactory.namedType4("B"));
    _assertReplace(node, Getter_NodeReplacerTest_test_typeParameter_2());
    _assertReplace(node, Getter_NodeReplacerTest_test_typeParameter());
  }

  void test_typeParameterList() {
    TypeParameterList node = AstTestFactory.typeParameterList2(["A", "B"]);
    _assertReplace(node, ListGetter_NodeReplacerTest_test_typeParameterList(0));
  }

  void test_variableDeclaration() {
    var node =
        AstTestFactory.variableDeclaration2("a", AstTestFactory.nullLiteral());
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(node, Getter_NodeReplacerTest_test_variableDeclaration());
    _assertReplace(node, Getter_NodeReplacerTest_test_variableDeclaration_2());
    _testAnnotatedNode(node);
  }

  void test_variableDeclarationList() {
    var node = AstTestFactory.variableDeclarationList(
        null,
        AstTestFactory.namedType4("T"),
        [AstTestFactory.variableDeclaration("a")]);
    node.documentationComment = astFactory.endOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata
        .add(AstTestFactory.annotation(AstTestFactory.identifier3("a")));
    _assertReplace(
        node, Getter_NodeReplacerTest_test_variableDeclarationList());
    _assertReplace(
        node, ListGetter_NodeReplacerTest_test_variableDeclarationList(0));
    _testAnnotatedNode(node);
  }

  void test_variableDeclarationStatement() {
    VariableDeclarationStatement node =
        AstTestFactory.variableDeclarationStatement(
            null,
            AstTestFactory.namedType4("T"),
            [AstTestFactory.variableDeclaration("a")]);
    _assertReplace(
        node, Getter_NodeReplacerTest_test_variableDeclarationStatement());
  }

  void test_whileStatement() {
    WhileStatement node = AstTestFactory.whileStatement(
        AstTestFactory.booleanLiteral(true), AstTestFactory.block());
    _assertReplace(node, Getter_NodeReplacerTest_test_whileStatement());
    _assertReplace(node, Getter_NodeReplacerTest_test_whileStatement_2());
  }

  void test_withClause() {
    WithClause node =
        AstTestFactory.withClause([AstTestFactory.namedType4("M")]);
    _assertReplace(node, ListGetter_NodeReplacerTest_test_withClause(0));
  }

  void test_yieldStatement() {
    var node = AstTestFactory.yieldStatement(AstTestFactory.identifier3("A"));
    _assertReplace(node, Getter_NodeReplacerTest_test_yieldStatement());
  }

  void _assertReplace(AstNode parent, NodeReplacerTest_Getter getter) {
    var child = getter.get(parent);
    if (child != null) {
      NodeReplacer.replace(child, child);
      expect(getter.get(parent), child);
      expect(child.parent, child.parent);
    }
  }

  void _assertReplace2<T extends AstNode>({
    required T destination,
    required T source,
    required List<AstNode Function(T node)> getters,
  }) {
    for (var getter in getters) {
      var child = getter(destination);
      expect(child.parent, destination);

      var replacement = getter(source);
      NodeReplacer.replace(child, replacement);
      expect(getter(destination), replacement);
      expect(replacement.parent, destination);
    }
  }

  FindNode _parseStringToFindNode(String content) {
    var parseResult = parseString(
      content: content,
      featureSet: FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: ExperimentStatus.currentVersion,
        flags: [
          Feature.super_parameters.enableString,
        ],
      ),
    );
    return FindNode(parseResult.content, parseResult.unit);
  }

  void _testAnnotatedNode(AnnotatedNode node) {
    _assertReplace(node, Getter_NodeReplacerTest_testAnnotatedNode());
    _assertReplace(node, ListGetter_NodeReplacerTest_testAnnotatedNode(0));
  }

  void _testNamespaceDirective(NamespaceDirective node) {
    _assertReplace(node, ListGetter_NodeReplacerTest_testNamespaceDirective(0));
    _testUriBasedDirective(node);
  }

  void _testNormalFormalParameter(NormalFormalParameter node) {
    _assertReplace(node, Getter_NodeReplacerTest_testNormalFormalParameter_2());
    _assertReplace(node, Getter_NodeReplacerTest_testNormalFormalParameter());
    _assertReplace(
        node, ListGetter_NodeReplacerTest_testNormalFormalParameter(0));
  }

  void _testSwitchMember(SwitchMember node) {
    _assertReplace(node, ListGetter_NodeReplacerTest_testSwitchMember(0));
    _assertReplace(node, ListGetter_NodeReplacerTest_testSwitchMember_2(0));
  }

  void _testTypedLiteral(TypedLiteral node) {
    _assertReplace(node, Getter_NodeReplacerTest_testTypedLiteral());
  }

  void _testUriBasedDirective(UriBasedDirective node) {
    _assertReplace(node, Getter_NodeReplacerTest_testUriBasedDirective());
    _testAnnotatedNode(node);
  }
}

abstract class NodeReplacerTest_Getter<P, C extends AstNode> {
  C? get(P parent);
}

abstract class NodeReplacerTest_ListGetter<P extends AstNode, C extends AstNode>
    implements NodeReplacerTest_Getter<P, C> {
  final int _index;

  NodeReplacerTest_ListGetter(this._index);

  @override
  C? get(P parent) {
    NodeList<C> list = getList(parent);
    if (list.isEmpty) {
      return null;
    }
    return list[_index];
  }

  NodeList<C> getList(P parent);
}

@reflectiveTest
class SourceRangeTest {
  void test_access() {
    SourceRange r = SourceRange(10, 1);
    expect(r.offset, 10);
    expect(r.length, 1);
    expect(r.end, 10 + 1);
    // to check
    r.hashCode;
  }

  void test_contains() {
    SourceRange r = SourceRange(5, 10);
    expect(r.contains(5), isTrue);
    expect(r.contains(10), isTrue);
    expect(r.contains(15), isTrue);
    expect(r.contains(0), isFalse);
    expect(r.contains(16), isFalse);
  }

  void test_containsExclusive() {
    SourceRange r = SourceRange(5, 10);
    expect(r.containsExclusive(5), isFalse);
    expect(r.containsExclusive(10), isTrue);
    expect(r.containsExclusive(14), isTrue);
    expect(r.containsExclusive(0), isFalse);
    expect(r.containsExclusive(15), isFalse);
  }

  void test_coveredBy() {
    SourceRange r = SourceRange(5, 10);
    // ends before
    expect(r.coveredBy(SourceRange(20, 10)), isFalse);
    // starts after
    expect(r.coveredBy(SourceRange(0, 3)), isFalse);
    // only intersects
    expect(r.coveredBy(SourceRange(0, 10)), isFalse);
    expect(r.coveredBy(SourceRange(10, 10)), isFalse);
    // covered
    expect(r.coveredBy(SourceRange(0, 20)), isTrue);
    expect(r.coveredBy(SourceRange(5, 10)), isTrue);
  }

  void test_covers() {
    SourceRange r = SourceRange(5, 10);
    // ends before
    expect(r.covers(SourceRange(0, 3)), isFalse);
    // starts after
    expect(r.covers(SourceRange(20, 3)), isFalse);
    // only intersects
    expect(r.covers(SourceRange(0, 10)), isFalse);
    expect(r.covers(SourceRange(10, 10)), isFalse);
    // covers
    expect(r.covers(SourceRange(5, 10)), isTrue);
    expect(r.covers(SourceRange(6, 9)), isTrue);
    expect(r.covers(SourceRange(6, 8)), isTrue);
  }

  void test_endsIn() {
    SourceRange r = SourceRange(5, 10);
    // ends before
    expect(r.endsIn(SourceRange(20, 10)), isFalse);
    // starts after
    expect(r.endsIn(SourceRange(0, 3)), isFalse);
    // ends
    expect(r.endsIn(SourceRange(10, 20)), isTrue);
    expect(r.endsIn(SourceRange(0, 20)), isTrue);
  }

  void test_equals() {
    SourceRange r = SourceRange(10, 1);
    // ignore: unrelated_type_equality_checks
    expect(r == this, isFalse);
    expect(r == SourceRange(20, 2), isFalse);
    expect(r == SourceRange(10, 1), isTrue);
    expect(r == r, isTrue);
  }

  void test_getExpanded() {
    SourceRange r = SourceRange(5, 3);
    expect(r.getExpanded(0), r);
    expect(r.getExpanded(2), SourceRange(3, 7));
    expect(r.getExpanded(-1), SourceRange(6, 1));
  }

  void test_getMoveEnd() {
    SourceRange r = SourceRange(5, 3);
    expect(r.getMoveEnd(0), r);
    expect(r.getMoveEnd(3), SourceRange(5, 6));
    expect(r.getMoveEnd(-1), SourceRange(5, 2));
  }

  void test_getTranslated() {
    SourceRange r = SourceRange(5, 3);
    expect(r.getTranslated(0), r);
    expect(r.getTranslated(2), SourceRange(7, 3));
    expect(r.getTranslated(-1), SourceRange(4, 3));
  }

  void test_getUnion() {
    expect(
        SourceRange(10, 10).getUnion(SourceRange(15, 10)), SourceRange(10, 15));
    expect(
        SourceRange(15, 10).getUnion(SourceRange(10, 10)), SourceRange(10, 15));
    // "other" is covered/covers
    expect(
        SourceRange(10, 10).getUnion(SourceRange(15, 2)), SourceRange(10, 10));
    expect(
        SourceRange(15, 2).getUnion(SourceRange(10, 10)), SourceRange(10, 10));
  }

  void test_intersects() {
    SourceRange r = SourceRange(5, 3);
    // null
    expect(r.intersects(null), isFalse);
    // ends before
    expect(r.intersects(SourceRange(0, 5)), isFalse);
    // begins after
    expect(r.intersects(SourceRange(8, 5)), isFalse);
    // begins on same offset
    expect(r.intersects(SourceRange(5, 1)), isTrue);
    // begins inside, ends inside
    expect(r.intersects(SourceRange(6, 1)), isTrue);
    // begins inside, ends after
    expect(r.intersects(SourceRange(6, 10)), isTrue);
    // begins before, ends after
    expect(r.intersects(SourceRange(0, 10)), isTrue);
  }

  void test_startsIn() {
    SourceRange r = SourceRange(5, 10);
    // ends before
    expect(r.startsIn(SourceRange(20, 10)), isFalse);
    // starts after
    expect(r.startsIn(SourceRange(0, 3)), isFalse);
    // starts
    expect(r.startsIn(SourceRange(5, 1)), isTrue);
    expect(r.startsIn(SourceRange(0, 20)), isTrue);
  }

  void test_toString() {
    SourceRange r = SourceRange(10, 1);
    expect(r.toString(), "[offset=10, length=1]");
  }
}

@reflectiveTest
class StringUtilitiesTest {
  void test_computeLineStarts_n() {
    List<int> starts = StringUtilities.computeLineStarts('a\nbb\nccc');
    expect(starts, <int>[0, 2, 5]);
  }

  void test_computeLineStarts_r() {
    List<int> starts = StringUtilities.computeLineStarts('a\rbb\rccc');
    expect(starts, <int>[0, 2, 5]);
  }

  void test_computeLineStarts_rn() {
    List<int> starts = StringUtilities.computeLineStarts('a\r\nbb\r\nccc');
    expect(starts, <int>[0, 3, 7]);
  }

  void test_EMPTY() {
    expect(StringUtilities.EMPTY, "");
    expect(StringUtilities.EMPTY.isEmpty, isTrue);
  }

  void test_EMPTY_ARRAY() {
    expect(StringUtilities.EMPTY_ARRAY.length, 0);
  }

  void test_endsWith3() {
    expect(StringUtilities.endsWith3("abc", 0x61, 0x62, 0x63), isTrue);
    expect(StringUtilities.endsWith3("abcdefghi", 0x67, 0x68, 0x69), isTrue);
    expect(StringUtilities.endsWith3("abcdefghi", 0x64, 0x65, 0x61), isFalse);
    // missing
  }

  void test_endsWithChar() {
    expect(StringUtilities.endsWithChar("a", 0x61), isTrue);
    expect(StringUtilities.endsWithChar("b", 0x61), isFalse);
    expect(StringUtilities.endsWithChar("", 0x61), isFalse);
  }

  void test_indexOf1() {
    expect(StringUtilities.indexOf1("a", 0, 0x61), 0);
    expect(StringUtilities.indexOf1("abcdef", 0, 0x61), 0);
    expect(StringUtilities.indexOf1("abcdef", 0, 0x63), 2);
    expect(StringUtilities.indexOf1("abcdef", 0, 0x66), 5);
    expect(StringUtilities.indexOf1("abcdef", 0, 0x7A), -1);
    expect(StringUtilities.indexOf1("abcdef", 1, 0x61), -1);
    // before start
  }

  void test_indexOf2() {
    expect(StringUtilities.indexOf2("ab", 0, 0x61, 0x62), 0);
    expect(StringUtilities.indexOf2("abcdef", 0, 0x61, 0x62), 0);
    expect(StringUtilities.indexOf2("abcdef", 0, 0x63, 0x64), 2);
    expect(StringUtilities.indexOf2("abcdef", 0, 0x65, 0x66), 4);
    expect(StringUtilities.indexOf2("abcdef", 0, 0x64, 0x61), -1);
    expect(StringUtilities.indexOf2("abcdef", 1, 0x61, 0x62), -1);
    // before start
  }

  void test_indexOf4() {
    expect(StringUtilities.indexOf4("abcd", 0, 0x61, 0x62, 0x63, 0x64), 0);
    expect(StringUtilities.indexOf4("abcdefghi", 0, 0x61, 0x62, 0x63, 0x64), 0);
    expect(StringUtilities.indexOf4("abcdefghi", 0, 0x63, 0x64, 0x65, 0x66), 2);
    expect(StringUtilities.indexOf4("abcdefghi", 0, 0x66, 0x67, 0x68, 0x69), 5);
    expect(
        StringUtilities.indexOf4("abcdefghi", 0, 0x64, 0x65, 0x61, 0x64), -1);
    expect(
        StringUtilities.indexOf4("abcdefghi", 1, 0x61, 0x62, 0x63, 0x64), -1);
    // before start
  }

  void test_indexOf5() {
    expect(
        StringUtilities.indexOf5("abcde", 0, 0x61, 0x62, 0x63, 0x64, 0x65), 0);
    expect(
        StringUtilities.indexOf5("abcdefghi", 0, 0x61, 0x62, 0x63, 0x64, 0x65),
        0);
    expect(
        StringUtilities.indexOf5("abcdefghi", 0, 0x63, 0x64, 0x65, 0x66, 0x67),
        2);
    expect(
        StringUtilities.indexOf5("abcdefghi", 0, 0x65, 0x66, 0x67, 0x68, 0x69),
        4);
    expect(
        StringUtilities.indexOf5("abcdefghi", 0, 0x64, 0x65, 0x66, 0x69, 0x6E),
        -1);
    expect(
        StringUtilities.indexOf5("abcdefghi", 1, 0x61, 0x62, 0x63, 0x64, 0x65),
        -1);
    // before start
  }

  void test_isEmpty() {
    expect(StringUtilities.isEmpty(""), isTrue);
    expect(StringUtilities.isEmpty(" "), isFalse);
    expect(StringUtilities.isEmpty("a"), isFalse);
    expect(StringUtilities.isEmpty(StringUtilities.EMPTY), isTrue);
  }

  void test_isTagName() {
    expect(StringUtilities.isTagName(null), isFalse);
    expect(StringUtilities.isTagName(""), isFalse);
    expect(StringUtilities.isTagName("-"), isFalse);
    expect(StringUtilities.isTagName("0"), isFalse);
    expect(StringUtilities.isTagName("0a"), isFalse);
    expect(StringUtilities.isTagName("a b"), isFalse);
    expect(StringUtilities.isTagName("a0"), isTrue);
    expect(StringUtilities.isTagName("a"), isTrue);
    expect(StringUtilities.isTagName("ab"), isTrue);
    expect(StringUtilities.isTagName("a-b"), isTrue);
  }

  void test_printListOfQuotedNames_empty() {
    expect(() {
      StringUtilities.printListOfQuotedNames([]);
    }, throwsArgumentError);
  }

  void test_printListOfQuotedNames_five() {
    expect(
        StringUtilities.printListOfQuotedNames(
            <String>["a", "b", "c", "d", "e"]),
        "'a', 'b', 'c', 'd' and 'e'");
  }

  void test_printListOfQuotedNames_null() {
    expect(() {
      StringUtilities.printListOfQuotedNames(null);
    }, throwsArgumentError);
  }

  void test_printListOfQuotedNames_one() {
    expect(() {
      StringUtilities.printListOfQuotedNames(<String>["a"]);
    }, throwsArgumentError);
  }

  void test_printListOfQuotedNames_three() {
    expect(StringUtilities.printListOfQuotedNames(<String>["a", "b", "c"]),
        "'a', 'b' and 'c'");
  }

  void test_printListOfQuotedNames_two() {
    expect(StringUtilities.printListOfQuotedNames(<String>["a", "b"]),
        "'a' and 'b'");
  }

  void test_startsWith2() {
    expect(StringUtilities.startsWith2("ab", 0, 0x61, 0x62), isTrue);
    expect(StringUtilities.startsWith2("abcdefghi", 0, 0x61, 0x62), isTrue);
    expect(StringUtilities.startsWith2("abcdefghi", 2, 0x63, 0x64), isTrue);
    expect(StringUtilities.startsWith2("abcdefghi", 5, 0x66, 0x67), isTrue);
    expect(StringUtilities.startsWith2("abcdefghi", 0, 0x64, 0x64), isFalse);
    // missing
  }

  void test_startsWith3() {
    expect(StringUtilities.startsWith3("abc", 0, 0x61, 0x62, 0x63), isTrue);
    expect(
        StringUtilities.startsWith3("abcdefghi", 0, 0x61, 0x62, 0x63), isTrue);
    expect(
        StringUtilities.startsWith3("abcdefghi", 2, 0x63, 0x64, 0x65), isTrue);
    expect(
        StringUtilities.startsWith3("abcdefghi", 6, 0x67, 0x68, 0x69), isTrue);
    expect(
        StringUtilities.startsWith3("abcdefghi", 0, 0x64, 0x65, 0x61), isFalse);
    // missing
  }

  void test_startsWith4() {
    expect(
        StringUtilities.startsWith4("abcd", 0, 0x61, 0x62, 0x63, 0x64), isTrue);
    expect(StringUtilities.startsWith4("abcdefghi", 0, 0x61, 0x62, 0x63, 0x64),
        isTrue);
    expect(StringUtilities.startsWith4("abcdefghi", 2, 0x63, 0x64, 0x65, 0x66),
        isTrue);
    expect(StringUtilities.startsWith4("abcdefghi", 5, 0x66, 0x67, 0x68, 0x69),
        isTrue);
    expect(StringUtilities.startsWith4("abcdefghi", 0, 0x64, 0x65, 0x61, 0x64),
        isFalse);
    // missing
  }

  void test_startsWith5() {
    expect(
        StringUtilities.startsWith5("abcde", 0, 0x61, 0x62, 0x63, 0x64, 0x65),
        isTrue);
    expect(
        StringUtilities.startsWith5(
            "abcdefghi", 0, 0x61, 0x62, 0x63, 0x64, 0x65),
        isTrue);
    expect(
        StringUtilities.startsWith5(
            "abcdefghi", 2, 0x63, 0x64, 0x65, 0x66, 0x67),
        isTrue);
    expect(
        StringUtilities.startsWith5(
            "abcdefghi", 4, 0x65, 0x66, 0x67, 0x68, 0x69),
        isTrue);
    expect(
        StringUtilities.startsWith5(
            "abcdefghi", 0, 0x61, 0x62, 0x63, 0x62, 0x61),
        isFalse);
    // missing
  }

  void test_startsWith6() {
    expect(
        StringUtilities.startsWith6(
            "abcdef", 0, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66),
        isTrue);
    expect(
        StringUtilities.startsWith6(
            "abcdefghi", 0, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66),
        isTrue);
    expect(
        StringUtilities.startsWith6(
            "abcdefghi", 2, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68),
        isTrue);
    expect(
        StringUtilities.startsWith6(
            "abcdefghi", 3, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69),
        isTrue);
    expect(
        StringUtilities.startsWith6(
            "abcdefghi", 0, 0x61, 0x62, 0x63, 0x64, 0x65, 0x67),
        isFalse);
    // missing
  }

  void test_substringBefore() {
    expect(StringUtilities.substringBefore(null, ""), null);
    expect(StringUtilities.substringBefore(null, "a"), null);
    expect(StringUtilities.substringBefore("", "a"), "");
    expect(StringUtilities.substringBefore("abc", "a"), "");
    expect(StringUtilities.substringBefore("abcba", "b"), "a");
    expect(StringUtilities.substringBefore("abc", "c"), "ab");
    expect(StringUtilities.substringBefore("abc", "d"), "abc");
    expect(StringUtilities.substringBefore("abc", ""), "");
    expect(StringUtilities.substringBefore("abc", null), "abc");
  }

  void test_substringBeforeChar() {
    expect(StringUtilities.substringBeforeChar("", 0x61), "");
    expect(StringUtilities.substringBeforeChar("abc", 0x61), "");
    expect(StringUtilities.substringBeforeChar("abcba", 0x62), "a");
    expect(StringUtilities.substringBeforeChar("abc", 0x63), "ab");
    expect(StringUtilities.substringBeforeChar("abc", 0x64), "abc");
  }
}
