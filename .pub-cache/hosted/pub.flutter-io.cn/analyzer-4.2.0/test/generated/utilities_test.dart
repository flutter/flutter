// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/feature_sets.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BooleanArrayTest);
    defineReflectiveTests(LineInfoTest);
    defineReflectiveTests(NodeReplacerTest);
    defineReflectiveTests(SourceRangeTest);
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

  void test_fromContent_n() {
    var lineInfo = LineInfo.fromContent('a\nbb\nccc');
    expect(lineInfo.lineStarts, <int>[0, 2, 5]);
  }

  void test_fromContent_r() {
    var lineInfo = LineInfo.fromContent('a\rbb\rccc');
    expect(lineInfo.lineStarts, <int>[0, 2, 5]);
  }

  void test_fromContent_rn() {
    var lineInfo = LineInfo.fromContent('a\r\nbb\r\nccc');
    expect(lineInfo.lineStarts, <int>[0, 3, 7]);
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

@reflectiveTest
class NodeReplacerTest {
  void test_adjacentStrings() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  'aaa' 'bbb';
}
''');
    var adjacentStrings = findNode.adjacentStrings('aaa');
    _assertReplaceInList(
      destination: adjacentStrings,
      child: adjacentStrings.strings[0],
      replacement: adjacentStrings.strings[1],
    );
  }

  void test_annotation() {
    var findNode = _parseStringToFindNode(r'''
@prefix.A<int>.named(args)
@prefix.B<double>.named(args)
void f() {}
''');
    _assertReplacementForChildren<Annotation>(
      destination: findNode.annotation('prefix.A'),
      source: findNode.annotation('prefix.B'),
      childAccessors: [
        (node) => node.arguments!,
        (node) => node.constructorName!,
        (node) => node.name,
        (node) => node.typeArguments!,
      ],
    );
  }

  void test_argumentList() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  g(0, 1);
}
''');
    var argumentList = findNode.argumentList('(0, 1)');
    _assertReplaceInList(
      destination: argumentList,
      child: argumentList.arguments[0],
      replacement: argumentList.arguments[1],
    );
  }

  void test_asExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  0 as int;
  1 as int;
}
''');
    _assertReplacementForChildren<AsExpression>(
      destination: findNode.as_('0 as'),
      source: findNode.as_('1 as'),
      childAccessors: [
        (node) => node.expression,
        (node) => node.type,
      ],
    );
  }

  void test_assertStatement() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  assert(true, 'first');
  assert(true, 'second');
}
''');
    _assertReplacementForChildren<AssertStatement>(
      destination: findNode.assertStatement('first'),
      source: findNode.assertStatement('second'),
      childAccessors: [
        (node) => node.condition,
        (node) => node.message!,
      ],
    );
  }

  void test_assignmentExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  a = 0;
  b = 1;
}
''');
    _assertReplacementForChildren<AssignmentExpression>(
      destination: findNode.assignment('a ='),
      source: findNode.assignment('b ='),
      childAccessors: [
        (node) => node.leftHandSide,
        (node) => node.rightHandSide,
      ],
    );
  }

  void test_awaitExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() async {
  await 0;
  await 1;
}
''');
    _assertReplacementForChildren<AwaitExpression>(
      destination: findNode.awaitExpression('0'),
      source: findNode.awaitExpression('1'),
      childAccessors: [
        (node) => node.expression,
      ],
    );
  }

  void test_binaryExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  0 + 1;
  1 + 2;
}
''');
    _assertReplacementForChildren<BinaryExpression>(
      destination: findNode.binary('0 + 1'),
      source: findNode.binary('1 + 2'),
      childAccessors: [
        (node) => node.leftOperand,
        (node) => node.rightOperand,
      ],
    );
  }

  void test_block() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  print(0);
  print(1);
}
''');
    var block = findNode.block('{');
    _assertReplaceInList(
      destination: block,
      child: block.statements[0],
      replacement: block.statements[1],
    );
  }

  void test_blockFunctionBody() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  print('fff');
}

void g() {
  print('ggg');
}
''');
    _assertReplacementForChildren<BlockFunctionBody>(
      destination: findNode.blockFunctionBody('fff'),
      source: findNode.blockFunctionBody('ggg'),
      childAccessors: [
        (node) => node.block,
        (node) => node.block,
      ],
    );
  }

  void test_breakStatement() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  while (true) {
    break first;
    break second;
  }
}
''');
    _assertReplacementForChildren<BreakStatement>(
      destination: findNode.breakStatement('first'),
      source: findNode.breakStatement('second'),
      childAccessors: [
        (node) => node.label!,
      ],
    );
  }

  void test_cascadeExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  0..foo..bar;
  1..foo;
}
''');
    var cascadeExpression = findNode.cascade('0');
    _assertReplaceInList(
      destination: cascadeExpression,
      child: cascadeExpression.cascadeSections[0],
      replacement: cascadeExpression.cascadeSections[1],
    );

    _assertReplacementForChildren<CascadeExpression>(
      destination: findNode.cascade('0'),
      source: findNode.cascade('1'),
      childAccessors: [
        (node) => node.target,
      ],
    );
  }

  void test_catchClause() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  try {} on E catch (e, st) {}
  try {} on E2 catch (e2, st2) {}
}
''');
    _assertReplacementForChildren<CatchClause>(
      destination: findNode.catchClause('(e,'),
      source: findNode.catchClause('(e2,'),
      childAccessors: [
        (node) => node.exceptionType!,
        (node) => node.exceptionParameter!,
        (node) => node.stackTraceParameter!,
        (node) => node.body,
      ],
    );
  }

  void test_classDeclaration() {
    var findNode = _parseStringToFindNode(r'''
/// Comment A.
@myA1
@myA2
class A<T> extends A0 with M implements I {
  void foo() {}
  void bar() {}
}

/// Comment B.
class B<U> extends B0 with N implements J {}
''');
    var A = findNode.classDeclaration('A<T>');
    _assertAnnotatedNode(A);
    _assertReplaceInList(
      destination: A,
      child: A.members[0],
      replacement: A.members[1],
    );
    _assertReplacementForChildren<ClassDeclaration>(
      destination: findNode.classDeclaration('A<T>'),
      source: findNode.classDeclaration('B<U>'),
      childAccessors: [
        (node) => node.documentationComment!,
        (node) => node.extendsClause!,
        (node) => node.implementsClause!,
        (node) => node.name,
        (node) => node.typeParameters!,
        (node) => node.withClause!,
      ],
    );
  }

  void test_classTypeAlias() {
    var findNode = _parseStringToFindNode(r'''
/// Comment A.
@myA1
@myA2
class A<T> = A0 with M implements I;

/// Comment B.
class B<U> = B0 with N implements J;
''');
    _assertAnnotatedNode(
      findNode.classTypeAlias('A<T>'),
    );
    _assertReplacementForChildren<ClassTypeAlias>(
      destination: findNode.classTypeAlias('A<T>'),
      source: findNode.classTypeAlias('B<U>'),
      childAccessors: [
        (node) => node.documentationComment!,
        (node) => node.superclass,
        (node) => node.implementsClause!,
        (node) => node.name,
        (node) => node.typeParameters!,
        (node) => node.withClause,
      ],
    );
  }

  void test_comment() {
    var findNode = _parseStringToFindNode(r'''
/// Has [foo] and [bar].
void f() {}
''');
    var comment = findNode.comment('Has');
    _assertReplaceInList(
      destination: comment,
      child: comment.references[0],
      replacement: comment.references[1],
    );
  }

  void test_commentReference() {
    var findNode = _parseStringToFindNode(r'''
/// Has [foo] and [bar].
void f() {}
''');
    _assertReplacementForChildren<CommentReference>(
      destination: findNode.commentReference('foo'),
      source: findNode.commentReference('bar'),
      childAccessors: [
        (node) => node.expression,
      ],
    );
  }

  void test_compilationUnit() {
    var findNode = _parseStringToFindNode(r'''
import 'a.dart';
import 'b.dart';
class A {}
class B {}
''');
    var unit = findNode.unit;
    _assertReplaceInList(
      destination: unit,
      child: unit.directives[0],
      replacement: unit.directives[1],
    );
    _assertReplaceInList(
      destination: unit,
      child: unit.declarations[0],
      replacement: unit.declarations[1],
    );
  }

  void test_conditionalExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  true ? 0 : 1;
  false ? 2 : 3;
}
''');
    _assertReplacementForChildren<ConditionalExpression>(
      destination: findNode.conditionalExpression('true'),
      source: findNode.conditionalExpression('false'),
      childAccessors: [
        (node) => node.condition,
        (node) => node.thenExpression,
        (node) => node.elseExpression,
      ],
    );
  }

  void test_constructorDeclaration() {
    var findNode = _parseStringToFindNode(r'''
class A {
  @myA1
  @myA2
  A.named(int a) : b = 0, c = 1;
}

class B {
  B.named(int b);
}
''');
    _assertReplacementForChildren<ConstructorDeclaration>(
      destination: findNode.constructor('A.named'),
      source: findNode.constructor('B.named'),
      childAccessors: [
        (node) => node.body,
        (node) => node.name!,
        (node) => node.parameters,
        (node) => node.returnType,
      ],
    );
    _assertAnnotatedNode(
      findNode.constructor('A.named'),
    );
  }

  void test_constructorDeclaration_redirectedConstructor() {
    var findNode = _parseStringToFindNode(r'''
class A {
  factory A() = R;
}

class B {
  factory B() = R;
}
''');
    _assertReplacementForChildren<ConstructorDeclaration>(
      destination: findNode.constructor('factory A'),
      source: findNode.constructor('factory B'),
      childAccessors: [
        (node) => node.redirectedConstructor!,
      ],
    );
  }

  void test_constructorFieldInitializer() {
    var findNode = _parseStringToFindNode(r'''
class A {
  A() : a = 0, b = 1;
}
''');
    _assertReplacementForChildren<ConstructorFieldInitializer>(
      destination: findNode.constructorFieldInitializer('a ='),
      source: findNode.constructorFieldInitializer('b ='),
      childAccessors: [
        (node) => node.fieldName,
        (node) => node.expression,
      ],
    );
  }

  void test_constructorName() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  new prefix.A.foo();
  new prefix.B.bar();
}
''');
    _assertReplacementForChildren<ConstructorName>(
      destination: findNode.constructorName('A.foo'),
      source: findNode.constructorName('B.bar'),
      childAccessors: [
        (node) => node.type,
        (node) => node.name!,
      ],
    );
  }

  void test_continueStatement() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  while (true) {
    continue first;
    continue second;
  }
}
''');
    _assertReplacementForChildren<ContinueStatement>(
      destination: findNode.continueStatement('first'),
      source: findNode.continueStatement('second'),
      childAccessors: [
        (node) => node.label!,
      ],
    );
  }

  void test_declaredIdentifier() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  for (int i in []) {}
  for (double j in []) {}
}
''');
    _assertReplacementForChildren<DeclaredIdentifier>(
      destination: findNode.declaredIdentifier('i in'),
      source: findNode.declaredIdentifier('j in'),
      childAccessors: [
        (node) => node.identifier,
        (node) => node.type!,
      ],
    );
  }

  void test_defaultFormalParameter() {
    var findNode = _parseStringToFindNode(r'''
void f({int a = 0, double b = 1}) {}
''');
    _assertReplacementForChildren<DefaultFormalParameter>(
      destination: findNode.defaultParameter('a ='),
      source: findNode.defaultParameter('b ='),
      childAccessors: [
        (node) => node.parameter,
        (node) => node.defaultValue!,
      ],
    );
  }

  void test_doStatement() {
    var findNode = _parseStringToFindNode(r'''
void f({int a = 0, double b = 1}) {}
''');
    _assertReplacementForChildren<DefaultFormalParameter>(
      destination: findNode.defaultParameter('a ='),
      source: findNode.defaultParameter('b ='),
      childAccessors: [
        (node) => node.parameter,
        (node) => node.defaultValue!,
      ],
    );
  }

  void test_enumConstantDeclaration() {
    var findNode = _parseStringToFindNode(r'''
enum E {
  @myA1
  @myA2
  aaa,
  bbb;
}
''');
    _assertAnnotatedNode(
      findNode.enumConstantDeclaration('aaa'),
    );
    _assertReplacementForChildren<EnumConstantDeclaration>(
      destination: findNode.enumConstantDeclaration('aaa'),
      source: findNode.enumConstantDeclaration('bbb'),
      childAccessors: [
        (node) => node.name,
      ],
    );
  }

  void test_enumDeclaration() {
    var findNode = _parseStringToFindNode(r'''
enum E1<T> with M1 implements I1 {one, two}
enum E2<U> with M2 implements I2 {one, two}
''');
    _assertReplacementForChildren<EnumDeclaration>(
      destination: findNode.enumDeclaration('enum E1'),
      source: findNode.enumDeclaration('enum E2'),
      childAccessors: [
        (node) => node.name,
        (node) => node.typeParameters!,
        (node) => node.withClause!,
        (node) => node.implementsClause!,
      ],
    );
  }

  void test_enumDeclaration_constants() {
    var findNode = _parseStringToFindNode(r'''
enum E1 {one}
enum E2 {two}
''');
    _assertReplaceInList(
      destination: findNode.enumDeclaration('enum E1'),
      child: findNode.enumConstantDeclaration('one'),
      replacement: findNode.enumConstantDeclaration('two'),
    );
  }

  void test_enumDeclaration_members() {
    var findNode = _parseStringToFindNode(r'''
enum E1 {one; void foo() {}}
enum E2 {two; void bar() {}}
''');
    _assertReplaceInList(
      destination: findNode.enumDeclaration('enum E1'),
      child: findNode.methodDeclaration('foo'),
      replacement: findNode.methodDeclaration('bar'),
    );
  }

  void test_exportDirective() {
    var findNode = _parseStringToFindNode(r'''
@myA1
@myA2
export 'a.dart' hide A show B;
export 'b.dart';
''');
    var export_a = findNode.export('a.dart');
    _assertAnnotatedNode(export_a);
    _assertReplaceInList(
      destination: export_a,
      child: export_a.combinators[0],
      replacement: export_a.combinators[1],
    );
    _assertReplacementForChildren<ExportDirective>(
      destination: findNode.export('a.dart'),
      source: findNode.export('b.dart'),
      childAccessors: [
        (node) => node.uri,
      ],
    );
  }

  void test_expressionFunctionBody() {
    var findNode = _parseStringToFindNode(r'''
void f() => 0;
void g() => 1;
''');
    _assertReplacementForChildren<ExpressionFunctionBody>(
      destination: findNode.expressionFunctionBody('0'),
      source: findNode.expressionFunctionBody('1'),
      childAccessors: [
        (node) => node.expression,
      ],
    );
  }

  void test_expressionStatement() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  0;
  1;
}
''');
    _assertReplacementForChildren<ExpressionStatement>(
      destination: findNode.expressionStatement('0'),
      source: findNode.expressionStatement('1'),
      childAccessors: [
        (node) => node.expression,
      ],
    );
  }

  void test_extendsClause() {
    var findNode = _parseStringToFindNode(r'''
class A extends A0 {}
class B extends B0 {}
''');
    _assertReplacementForChildren<ExtendsClause>(
      destination: findNode.extendsClause('A0'),
      source: findNode.extendsClause('B0'),
      childAccessors: [
        (node) => node.superclass,
      ],
    );
  }

  void test_fieldDeclaration() {
    var findNode = _parseStringToFindNode(r'''
class A {
  @myA1
  @myA2
  int foo = 0;
  int bar = 0;
}
class B extends B0 {}
''');
    _assertAnnotatedNode(
      findNode.fieldDeclaration('foo'),
    );
    _assertReplacementForChildren<FieldDeclaration>(
      destination: findNode.fieldDeclaration('foo'),
      source: findNode.fieldDeclaration('bar'),
      childAccessors: [
        (node) => node.fields,
      ],
    );
  }

  void test_fieldFormalParameter() {
    var findNode = _parseStringToFindNode(r'''
class A {
  A(
    @myA1
    @myA2
    int this.foo<T>(int a),
    int this.bar<U>(int b),
  );
}
''');
    var foo = findNode.fieldFormalParameter('foo');
    _assertFormalParameterMetadata(foo);
    _assertReplacementForChildren<FieldFormalParameter>(
      destination: findNode.fieldFormalParameter('foo'),
      source: findNode.fieldFormalParameter('bar'),
      childAccessors: [
        (node) => node.identifier,
        (node) => node.parameters!,
        (node) => node.type!,
        (node) => node.typeParameters!,
      ],
    );
  }

  void test_forEachPartsWithDeclaration() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  for (int a in []) {}
  for (int b in []) {}
}
''');
    _assertReplacementForChildren<ForEachPartsWithDeclaration>(
      destination: findNode.forEachPartsWithDeclaration('a in'),
      source: findNode.forEachPartsWithDeclaration('b in'),
      childAccessors: [
        (node) => node.loopVariable,
        (node) => node.iterable,
      ],
    );
  }

  void test_forEachPartsWithIdentifier() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  for (a in []) {}
  for (b in []) {}
}
''');
    _assertReplacementForChildren<ForEachPartsWithIdentifier>(
      destination: findNode.forEachPartsWithIdentifier('a in'),
      source: findNode.forEachPartsWithIdentifier('b in'),
      childAccessors: [
        (node) => node.identifier,
        (node) => node.iterable,
      ],
    );
  }

  void test_forEachStatement_withIdentifier() {
    var findNode = _parseStringToFindNode(r'''
void f(int a) {
  for (a in []) {}
  for (b in []) {}
}
''');
    _assertReplacementForChildren<ForStatement>(
      destination: findNode.forStatement('a in'),
      source: findNode.forStatement('b in'),
      childAccessors: [
        (node) => node.body,
        (node) => node.forLoopParts,
      ],
    );
  }

  void test_formalParameterList() {
    var findNode = _parseStringToFindNode(r'''
void f(int a, int b) {}
''');
    _assertReplaceInList(
      destination: findNode.formalParameterList('int a'),
      child: findNode.simpleFormalParameter('int a'),
      replacement: findNode.simpleFormalParameter('int b'),
    );
  }

  void test_forPartsWithDeclarations() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  for (int i = 0; i < 8; i++, i += 2) {}
  for (int j = 0; j < 8; j++) {}
}
''');
    var for_i = findNode.forPartsWithDeclarations('i = 0');
    _assertReplaceInList(
      destination: for_i,
      child: for_i.updaters[0],
      replacement: for_i.updaters[1],
    );
    _assertReplacementForChildren<ForPartsWithDeclarations>(
      destination: for_i,
      source: findNode.forPartsWithDeclarations('j = 0'),
      childAccessors: [
        (node) => node.variables,
        (node) => node.condition!,
      ],
    );
  }

  void test_forPartsWithExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  for (i = 0; i < 8; i++, i += 2) {}
  for (j = 0; j < 8; j++) {}
}
''');
    var for_i = findNode.forPartsWithExpression('i = 0');
    _assertReplaceInList(
      destination: for_i,
      child: for_i.updaters[0],
      replacement: for_i.updaters[1],
    );
    _assertReplacementForChildren<ForPartsWithExpression>(
      destination: for_i,
      source: findNode.forPartsWithExpression('j = 0'),
      childAccessors: [
        (node) => node.initialization!,
        (node) => node.condition!,
      ],
    );
  }

  void test_functionDeclaration() {
    var findNode = _parseStringToFindNode(r'''
@myA1
@myA2
int f() => 0;
double g() => 0;
''');
    _assertAnnotatedNode(
      findNode.functionDeclaration('f()'),
    );
    _assertReplacementForChildren<FunctionDeclaration>(
      destination: findNode.functionDeclaration('f()'),
      source: findNode.functionDeclaration('g()'),
      childAccessors: [
        (node) => node.functionExpression,
        (node) => node.name,
        (node) => node.returnType!,
      ],
    );
  }

  void test_functionDeclarationStatement() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  void g() {}
  void h() {}
}
''');
    _assertReplacementForChildren<FunctionDeclarationStatement>(
      destination: findNode.functionDeclarationStatement('g()'),
      source: findNode.functionDeclarationStatement('h()'),
      childAccessors: [
        (node) => node.functionDeclaration,
      ],
    );
  }

  void test_functionExpression() {
    var findNode = _parseStringToFindNode(r'''
void f<T>(int a) {
  0;
}
void g<U>(double b) {
  1;
}
''');
    _assertReplacementForChildren<FunctionExpression>(
      destination: findNode.functionExpression('<T>'),
      source: findNode.functionExpression('<U>'),
      childAccessors: [
        (node) => node.body,
        (node) => node.parameters!,
        (node) => node.typeParameters!,
      ],
    );
  }

  void test_functionExpressionInvocation() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  (g)<int>(0);
  (h)<double>(1);
}
''');
    _assertReplacementForChildren<FunctionExpressionInvocation>(
      destination: findNode.functionExpressionInvocation('<int>'),
      source: findNode.functionExpressionInvocation('<double>'),
      childAccessors: [
        (node) => node.function,
        (node) => node.typeArguments!,
        (node) => node.argumentList,
      ],
    );
  }

  void test_functionTypeAlias() {
    var findNode = _parseStringToFindNode(r'''
@myA1
@myA2
typedef int F<T>(int a);
typedef double G<U>(double b);
''');
    _assertAnnotatedNode(
      findNode.functionTypeAlias('int F'),
    );
    _assertReplacementForChildren<FunctionTypeAlias>(
      destination: findNode.functionTypeAlias('int F'),
      source: findNode.functionTypeAlias('double G'),
      childAccessors: [
        (node) => node.name,
        (node) => node.parameters,
        (node) => node.returnType!,
        (node) => node.typeParameters!,
      ],
    );
  }

  void test_functionTypedFormalParameter() {
    var findNode = _parseStringToFindNode(r'''
void f(
  @myA1
  @myA2
  int a<T>(int a1),
  double b<U>(double b2),
) {}
''');
    var a = findNode.functionTypedFormalParameter('a<T>');
    _assertFormalParameterMetadata(a);
    _assertReplacementForChildren<FunctionTypedFormalParameter>(
      destination: findNode.functionTypedFormalParameter('a<T>'),
      source: findNode.functionTypedFormalParameter('b<U>'),
      childAccessors: [
        (node) => node.returnType!,
        (node) => node.identifier,
        (node) => node.typeParameters!,
        (node) => node.parameters,
      ],
    );
  }

  void test_hideCombinator() {
    var findNode = _parseStringToFindNode(r'''
import '' hide A, B;
''');
    var node = findNode.hideCombinator('hide');
    _assertReplaceInList(
      destination: node,
      child: node.hiddenNames[0],
      replacement: node.hiddenNames[1],
    );
  }

  void test_ifStatement() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  if (true) {
    0;
  } else {
    1;
  }
  if (false) {
    2;
  } else {
    3;
  }
}
''');
    _assertReplacementForChildren<IfStatement>(
      destination: findNode.ifStatement('true'),
      source: findNode.ifStatement('false'),
      childAccessors: [
        (node) => node.condition,
        (node) => node.thenStatement,
        (node) => node.elseStatement!,
      ],
    );
  }

  void test_implementsClause() {
    var findNode = _parseStringToFindNode(r'''
class A implements I, J {}
''');
    var node = findNode.implementsClause('implements');
    _assertReplaceInList(
      destination: node,
      child: node.interfaces[0],
      replacement: node.interfaces[1],
    );
  }

  void test_importDirective() {
    var findNode = _parseStringToFindNode(r'''
@myA1
@myA2
import 'a.dart' hide A show B;
import 'b.dart';
''');
    var import_a = findNode.import('a.dart');
    _assertAnnotatedNode(import_a);
    _assertReplaceInList(
      destination: import_a,
      child: import_a.combinators[0],
      replacement: import_a.combinators[1],
    );
    _assertReplacementForChildren<ImportDirective>(
      destination: findNode.import('a.dart'),
      source: findNode.import('b.dart'),
      childAccessors: [
        (node) => node.uri,
      ],
    );
  }

  void test_indexExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  a[0];
  b[1];
}
''');
    _assertReplacementForChildren<IndexExpression>(
      destination: findNode.index('[0]'),
      source: findNode.index('[1]'),
      childAccessors: [
        (node) => node.target!,
        (node) => node.index,
      ],
    );
  }

  void test_instanceCreationExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  new A(0);
  new B(1);
}
''');
    _assertReplacementForChildren<InstanceCreationExpression>(
      destination: findNode.instanceCreation('A('),
      source: findNode.instanceCreation('B('),
      childAccessors: [
        (node) => node.constructorName,
        (node) => node.argumentList,
      ],
    );
  }

  void test_interpolationExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  '$foo $bar';
}
''');
    _assertReplacementForChildren<InterpolationExpression>(
      destination: findNode.interpolationExpression('foo'),
      source: findNode.interpolationExpression('bar'),
      childAccessors: [
        (node) => node.expression,
      ],
    );
  }

  void test_isExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  0 is int;
  1 is double;
}
''');
    _assertReplacementForChildren<IsExpression>(
      destination: findNode.isExpression('0 is'),
      source: findNode.isExpression('1 is'),
      childAccessors: [
        (node) => node.expression,
        (node) => node.type,
      ],
    );
  }

  void test_label() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  foo: while (true) {}
  bar: while (true) {}
}
''');
    _assertReplacementForChildren<Label>(
      destination: findNode.label('foo:'),
      source: findNode.label('bar'),
      childAccessors: [
        (node) => node.label,
      ],
    );
  }

  void test_labeledStatement() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  foo: bar: 0;
  baz: 1;
}
''');
    var foo = findNode.labeledStatement('foo');
    _assertReplaceInList(
      destination: foo,
      child: foo.labels[0],
      replacement: foo.labels[1],
    );
    _assertReplacementForChildren<LabeledStatement>(
      destination: foo,
      source: findNode.labeledStatement('baz'),
      childAccessors: [
        (node) => node.statement,
      ],
    );
  }

  void test_libraryDirective() {
    var findNode = _parseStringToFindNode(r'''
@myA1
@myA2
library foo;
''');
    var node = findNode.libraryDirective;
    _assertAnnotatedNode(node);
    _assertReplacementForChildren<LibraryDirective>(
      destination: node,
      source: node,
      childAccessors: [
        (node) => node.name,
      ],
    );
  }

  void test_libraryIdentifier() {
    var findNode = _parseStringToFindNode(r'''
library foo.bar;
''');
    var node = findNode.libraryIdentifier('foo');
    _assertReplaceInList(
      destination: node,
      child: node.components[0],
      replacement: node.components[1],
    );
  }

  void test_listLiteral() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  <int>[0, 1];
  <double>[];
}
''');
    var node = findNode.listLiteral('[0');
    _assertReplaceInList(
      destination: node,
      child: node.elements[0],
      replacement: node.elements[1],
    );
    _assertReplacementForChildren<ListLiteral>(
      destination: findNode.listLiteral('<int>'),
      source: findNode.listLiteral('<double>'),
      childAccessors: [
        (node) => node.typeArguments!,
      ],
    );
  }

  void test_mapLiteralEntry() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  <int, int>{0: 1, 2: 3};
}
''');
    _assertReplacementForChildren<MapLiteralEntry>(
      destination: findNode.mapLiteralEntry('0: 1'),
      source: findNode.mapLiteralEntry('2: 3'),
      childAccessors: [
        (node) => node.key,
        (node) => node.value,
      ],
    );
  }

  void test_methodDeclaration() {
    var findNode = _parseStringToFindNode(r'''
class A {
  @myA1
  @myA2
  int foo<T>(int a) {}
  double bar<U>(double b) {}
}
''');
    var foo = findNode.methodDeclaration('foo');
    _assertAnnotatedNode(foo);
    _assertReplacementForChildren<MethodDeclaration>(
      destination: foo,
      source: findNode.methodDeclaration('bar'),
      childAccessors: [
        (node) => node.returnType!,
        (node) => node.name,
        (node) => node.typeParameters!,
        (node) => node.parameters!,
        (node) => node.body,
      ],
    );
  }

  void test_methodInvocation() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  a.foo<int>(0);
  b.bar<double>(1);
}
''');
    _assertReplacementForChildren<MethodInvocation>(
      destination: findNode.methodInvocation('foo'),
      source: findNode.methodInvocation('bar'),
      childAccessors: [
        (node) => node.target!,
        (node) => node.typeArguments!,
        (node) => node.argumentList,
      ],
    );
  }

  void test_namedExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  g(foo: 0, bar: 1);
}
''');
    _assertReplacementForChildren<NamedExpression>(
      destination: findNode.namedExpression('foo'),
      source: findNode.namedExpression('bar'),
      childAccessors: [
        (node) => node.name,
        (node) => node.expression,
      ],
    );
  }

  void test_nativeClause() {
    var findNode = _parseStringToFindNode(r'''
class A native 'foo' {}
class B native 'bar' {}
''');
    _assertReplacementForChildren<NativeClause>(
      destination: findNode.nativeClause('foo'),
      source: findNode.nativeClause('bar'),
      childAccessors: [
        (node) => node.name!,
      ],
    );
  }

  void test_nativeFunctionBody() {
    var findNode = _parseStringToFindNode(r'''
void f() native 'foo';
void g() native 'bar';
''');
    _assertReplacementForChildren<NativeFunctionBody>(
      destination: findNode.nativeFunctionBody('foo'),
      source: findNode.nativeFunctionBody('bar'),
      childAccessors: [
        (node) => node.stringLiteral!,
      ],
    );
  }

  void test_parenthesizedExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  (0);
  (1);
}
''');
    _assertReplacementForChildren<ParenthesizedExpression>(
      destination: findNode.parenthesized('0'),
      source: findNode.parenthesized('1'),
      childAccessors: [
        (node) => node.expression,
      ],
    );
  }

  void test_partDirective() {
    var findNode = _parseStringToFindNode(r'''
@myA1
@myA2
part 'a.dart';
part 'b.dart';
''');
    var part_a = findNode.part('a.dart');
    _assertAnnotatedNode(part_a);
    _assertReplacementForChildren<PartDirective>(
      destination: findNode.part('a.dart'),
      source: findNode.part('b.dart'),
      childAccessors: [
        (node) => node.uri,
      ],
    );
  }

  void test_partOfDirective() {
    var findNode = _parseStringToFindNode(r'''
@myA1
@myA2
part of 'a.dart';
''');
    var partOf_a = findNode.partOf('a.dart');
    _assertAnnotatedNode(partOf_a);
    _assertReplacementForChildren<PartOfDirective>(
      destination: findNode.partOf('a.dart'),
      source: findNode.partOf('a.dart'),
      childAccessors: [
        (node) => node.uri!,
      ],
    );
  }

  void test_postfixExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  a++;
  b++;
}
''');
    _assertReplacementForChildren<PostfixExpression>(
      destination: findNode.postfix('a++'),
      source: findNode.postfix('b++'),
      childAccessors: [
        (node) => node.operand,
      ],
    );
  }

  void test_prefixedIdentifier() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  a.foo;
  b.bar;
}
''');
    _assertReplacementForChildren<PrefixedIdentifier>(
      destination: findNode.prefixed('a.foo'),
      source: findNode.prefixed('b.bar'),
      childAccessors: [
        (node) => node.prefix,
        (node) => node.identifier,
      ],
    );
  }

  void test_prefixExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  ++a;
  ++b;
}
''');
    _assertReplacementForChildren<PrefixExpression>(
      destination: findNode.prefix('++a'),
      source: findNode.prefix('++b'),
      childAccessors: [
        (node) => node.operand,
      ],
    );
  }

  void test_propertyAccess() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  (a).foo;
  (b).bar;
}
''');
    _assertReplacementForChildren<PropertyAccess>(
      destination: findNode.propertyAccess('(a)'),
      source: findNode.propertyAccess('(b)'),
      childAccessors: [
        (node) => node.target!,
        (node) => node.propertyName,
      ],
    );
  }

  void test_redirectingConstructorInvocation() {
    var findNode = _parseStringToFindNode(r'''
class A {
  A.named();
  A.foo() : this.named(0);
  A.bar() : this.named(1);
}
''');
    _assertReplacementForChildren<RedirectingConstructorInvocation>(
      destination: findNode.redirectingConstructorInvocation('(0)'),
      source: findNode.redirectingConstructorInvocation('(1)'),
      childAccessors: [
        (node) => node.constructorName!,
        (node) => node.argumentList,
      ],
    );
  }

  void test_returnStatement() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  return 0;
  return 1;
}
''');
    _assertReplacementForChildren<ReturnStatement>(
      destination: findNode.returnStatement('0;'),
      source: findNode.returnStatement('1;'),
      childAccessors: [
        (node) => node.expression!,
      ],
    );
  }

  void test_setOrMapLiteral() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  <int, int>{0: 1, 2: 3};
  <double, double>{};
}
''');
    var node = findNode.setOrMapLiteral('<int');
    _assertReplaceInList(
      destination: node,
      child: node.elements[0],
      replacement: node.elements[1],
    );
    _assertReplacementForChildren<SetOrMapLiteral>(
      destination: findNode.setOrMapLiteral('<int'),
      source: findNode.setOrMapLiteral('<double'),
      childAccessors: [
        (node) => node.typeArguments!,
      ],
    );
  }

  void test_showCombinator() {
    var findNode = _parseStringToFindNode(r'''
import '' show A, B;
''');
    var node = findNode.showCombinator('show');
    _assertReplaceInList(
      destination: node,
      child: node.shownNames[0],
      replacement: node.shownNames[1],
    );
  }

  void test_simpleFormalParameter() {
    var findNode = _parseStringToFindNode(r'''
void f(
  @myA1
  @myA2
  int a,
  int b
) {}
''');
    var a = findNode.simpleFormalParameter('int a');
    _assertFormalParameterMetadata(a);
    _assertReplacementForChildren<SimpleFormalParameter>(
      destination: a,
      source: findNode.simpleFormalParameter('int b'),
      childAccessors: [
        (node) => node.type!,
        (node) => node.identifier!,
      ],
    );
  }

  void test_stringInterpolation() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  'my $foo other $bar';
}
''');
    var node = findNode.stringInterpolation('foo');
    _assertReplaceInList(
      destination: node,
      child: node.elements[0],
      replacement: node.elements[1],
    );
  }

  void test_superConstructorInvocation() {
    var findNode = _parseStringToFindNode(r'''
class A {
  A.foo() : super.first(0);
  A.bar() : super.second(0);
}
''');
    _assertReplacementForChildren<SuperConstructorInvocation>(
      destination: findNode.superConstructorInvocation('first'),
      source: findNode.superConstructorInvocation('second'),
      childAccessors: [
        (node) => node.constructorName!,
        (node) => node.argumentList,
      ],
    );
  }

  void test_superFormalParameter() {
    var findNode = _parseStringToFindNode(r'''
class A {
  A(num a);
}

class B extends A {
  B.sub1(int super.a1);
  B.sub2(double super.a2);
}
''');
    _assertReplacementForChildren<SuperFormalParameter>(
      destination: findNode.superFormalParameter('a1'),
      source: findNode.superFormalParameter('a2'),
      childAccessors: [
        (node) => node.type!,
        (node) => node.identifier,
      ],
    );
  }

  void test_superFormalParameter_functionTyped() {
    var findNode = _parseStringToFindNode(r'''
class A {
  A(int foo<T>(int a));
}

class B extends A {
  B.sub1(double super.bar1<T1>(int a1),);
  B.sub2(double super.bar2<T2>(int a2),);
}
''');
    _assertReplacementForChildren<SuperFormalParameter>(
      destination: findNode.superFormalParameter('bar1'),
      source: findNode.superFormalParameter('bar2'),
      childAccessors: [
        (node) => node.type!,
        (node) => node.identifier,
        (node) => node.typeParameters!,
        (node) => node.parameters!,
      ],
    );
  }

  void test_switchCase() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  switch (x) {
    foo: bar:
    case 0: 0; 1;
    case 1: break;
  }
}
''');
    _assertSwitchMember(
      findNode.switchCase('case 0'),
    );
    _assertReplacementForChildren<SwitchCase>(
      destination: findNode.switchCase('case 0'),
      source: findNode.switchCase('case 1'),
      childAccessors: [
        (node) => node.expression,
      ],
    );
  }

  void test_switchDefault() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  switch (x) {
    foo: bar:
    default: 0; 1;
  }
}
''');
    _assertSwitchMember(
      findNode.switchDefault('default: 0'),
    );
  }

  void test_switchStatement() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  switch (0) {
    case 0: break;
    case 1: break;
  }
  switch (1) {}
}
''');
    _assertReplaceInList(
      destination: findNode.switchStatement('(0)'),
      child: findNode.switchCase('case 0'),
      replacement: findNode.switchCase('case 1'),
    );
    _assertReplacementForChildren<SwitchStatement>(
      destination: findNode.switchStatement('(0)'),
      source: findNode.switchStatement('(1)'),
      childAccessors: [
        (node) => node.expression,
      ],
    );
  }

  void test_throwExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  throw 0;
  throw 1;
}
''');
    _assertReplacementForChildren<ThrowExpression>(
      destination: findNode.throw_('throw 0'),
      source: findNode.throw_('throw 1'),
      childAccessors: [
        (node) => node.expression,
      ],
    );
  }

  void test_topLevelVariableDeclaration() {
    var findNode = _parseStringToFindNode(r'''
@myA1
@myA2
var a = 0;
var b = 1;
''');
    _assertAnnotatedNode(
      findNode.topLevelVariableDeclaration('a = 0'),
    );
    _assertReplacementForChildren<TopLevelVariableDeclaration>(
      destination: findNode.topLevelVariableDeclaration('a = 0'),
      source: findNode.topLevelVariableDeclaration('b = 1'),
      childAccessors: [
        (node) => node.variables,
      ],
    );
  }

  void test_tryStatement() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  try { // 0
    0;
  } on E1 {
  } on E2 {
  } finally {
    1;
  }
  try { // 1
    2;
  } finally {
    3;
  }
}
''');
    _assertReplaceInList(
      destination: findNode.tryStatement('// 0'),
      child: findNode.catchClause('E1'),
      replacement: findNode.catchClause('E2'),
    );
    _assertReplacementForChildren<TryStatement>(
      destination: findNode.tryStatement('// 0'),
      source: findNode.tryStatement('// 1'),
      childAccessors: [
        (node) => node.body,
        (node) => node.finallyBlock!,
      ],
    );
  }

  void test_typeArgumentList() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  g<int, double>();
}
''');
    _assertReplaceInList(
      destination: findNode.typeArgumentList('<int'),
      child: findNode.namedType('int'),
      replacement: findNode.namedType('double'),
    );
  }

  void test_typeName() {
    var findNode = _parseStringToFindNode(r'''
void f(List<int> a, Set<double> b) {}
''');
    _assertReplacementForChildren<NamedType>(
      destination: findNode.namedType('List<int>'),
      source: findNode.namedType('Set<double>'),
      childAccessors: [
        (node) => node.name,
        (node) => node.typeArguments!,
      ],
    );
  }

  void test_typeParameter() {
    var findNode = _parseStringToFindNode(r'''
class A<T extends int, U extends double> {}
''');
    _assertReplacementForChildren<TypeParameter>(
      destination: findNode.typeParameter('T extends'),
      source: findNode.typeParameter('U extends'),
      childAccessors: [
        (node) => node.name,
        (node) => node.bound!,
      ],
    );
  }

  void test_typeParameterList() {
    var findNode = _parseStringToFindNode(r'''
class A<T, U> {}
''');
    var node = findNode.typeParameterList('<T, U>');
    _assertReplaceInList(
      destination: node,
      child: node.typeParameters[0],
      replacement: node.typeParameters[1],
    );
  }

  void test_variableDeclaration() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  var a = 0;
  var b = 1;
}
''');
    _assertReplacementForChildren<VariableDeclaration>(
      destination: findNode.variableDeclaration('a = 0'),
      source: findNode.variableDeclaration('b = 1'),
      childAccessors: [
        (node) => node.name,
        (node) => node.initializer!,
      ],
    );
  }

  void test_variableDeclarationList() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  int a = 0, b = 1;
  double c = 2;
}
''');
    _assertReplaceInList(
      destination: findNode.variableDeclarationList('int a'),
      child: findNode.variableDeclaration('a = 0'),
      replacement: findNode.variableDeclaration('b = 1'),
    );
    _assertReplacementForChildren<VariableDeclarationList>(
      destination: findNode.variableDeclarationList('int a'),
      source: findNode.variableDeclarationList('double c'),
      childAccessors: [
        (node) => node.type!,
      ],
    );
  }

  void test_variableDeclarationStatement() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  int a = 0;
  double b = 1;
}
''');
    _assertReplacementForChildren<VariableDeclarationStatement>(
      destination: findNode.variableDeclarationStatement('int a'),
      source: findNode.variableDeclarationStatement('double b'),
      childAccessors: [
        (node) => node.variables,
      ],
    );
  }

  void test_whileStatement() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  while (true) {
    0;
  }
  while (false) {
    1;
  }
}
''');
    _assertReplacementForChildren<WhileStatement>(
      destination: findNode.whileStatement('(true)'),
      source: findNode.whileStatement('(false)'),
      childAccessors: [
        (node) => node.condition,
        (node) => node.body,
      ],
    );
  }

  void test_withClause() {
    var findNode = _parseStringToFindNode(r'''
class A with M, N {}
''');
    var node = findNode.withClause('with');
    _assertReplaceInList(
      destination: node,
      child: node.mixinTypes[0],
      replacement: node.mixinTypes[1],
    );
  }

  void test_yieldStatement() {
    var findNode = _parseStringToFindNode(r'''
void f() sync* {
  yield 0;
  yield 1;
}
''');
    _assertReplacementForChildren<YieldStatement>(
      destination: findNode.yieldStatement('yield 0;'),
      source: findNode.yieldStatement('yield 1'),
      childAccessors: [
        (node) => node.expression,
      ],
    );
  }

  /// Asserts that the first annotation can be replaced with the second.
  /// Expects that [node] has at least 2 annotations.
  void _assertAnnotatedNode(AnnotatedNode node) {
    _assertReplaceInList(
      destination: node,
      child: node.metadata[0],
      replacement: node.metadata[1],
    );
  }

  /// Asserts that the first annotation can be replaced with the second.
  /// Expects that [node] has at least 2 annotations.
  void _assertFormalParameterMetadata(FormalParameter node) {
    _assertReplaceInList(
      destination: node,
      child: node.metadata[0],
      replacement: node.metadata[1],
    );
  }

  /// Asserts that a [child] node, with parent that is [destination], can
  /// by replaced with the [replacement], and then its parent is [destination].
  void _assertReplaceInList({
    required AstNode destination,
    required AstNode child,
    required AstNode replacement,
  }) {
    expect(child.parent, destination);

    NodeReplacer.replace(child, replacement);
    expect(replacement.parent, destination);
  }

  /// Asserts for each child returned by a function from [childAccessors]
  /// for [destination] that its parent is actually [destination], and then
  /// replaces it with a node returned this function for [source]. At the end,
  /// checks that the function, invoked for [destination] now returns the
  /// replacement node, and its parent is now [destination].
  void _assertReplacementForChildren<T extends AstNode>({
    required T destination,
    required T source,
    required List<AstNode Function(T node)> childAccessors,
  }) {
    for (var childAccessor in childAccessors) {
      var child = childAccessor(destination);
      expect(child.parent, destination);

      var replacement = childAccessor(source);
      NodeReplacer.replace(child, replacement);
      expect(childAccessor(destination), replacement);
      expect(replacement.parent, destination);
    }
  }

  void _assertSwitchMember(SwitchMember node) {
    _assertReplaceInList(
      destination: node,
      child: node.labels[0],
      replacement: node.labels[1],
    );
    _assertReplaceInList(
      destination: node,
      child: node.statements[0],
      replacement: node.statements[1],
    );
  }

  FindNode _parseStringToFindNode(String content) {
    var parseResult = parseString(
      content: content,
      featureSet: FeatureSets.latestWithExperiments,
    );
    return FindNode(parseResult.content, parseResult.unit);
  }
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
