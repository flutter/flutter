// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parser_test_base.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CollectionLiteralParserTest);
  });
}

@reflectiveTest
class CollectionLiteralParserTest extends FastaParserTestCase {
  Expression parseCollectionLiteral(String source,
      {List<ErrorCode>? codes,
      List<ExpectedError>? errors,
      int? expectedEndOffset,
      bool inAsync = false}) {
    return parseExpression(
      source,
      codes: codes,
      errors: errors,
      expectedEndOffset: expectedEndOffset,
      inAsync: inAsync,
    );
  }

  void test_listLiteral_for() {
    var list = parseCollectionLiteral(
      '[1, await for (var x in list) 2]',
      inAsync: true,
    ) as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as ForElement;
    expect(second.awaitKeyword, isNotNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    var forLoopParts = second.forLoopParts as ForEachPartsWithDeclaration;
    DeclaredIdentifier forLoopVar = forLoopParts.loopVariable;
    expect(forLoopVar.name.lexeme, 'x');
    expect(forLoopParts.inKeyword, isNotNull);
    var iterable = forLoopParts.iterable as SimpleIdentifier;
    expect(iterable.name, 'list');
  }

  void test_listLiteral_forIf() {
    var list = parseCollectionLiteral(
      '[1, await for (var x in list) if (c) 2]',
      inAsync: true,
    ) as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as ForElement;
    expect(second.awaitKeyword, isNotNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    var forLoopParts = second.forLoopParts as ForEachPartsWithDeclaration;
    DeclaredIdentifier forLoopVar = forLoopParts.loopVariable;
    expect(forLoopVar.name.lexeme, 'x');
    expect(forLoopParts.inKeyword, isNotNull);
    var iterable = forLoopParts.iterable as SimpleIdentifier;
    expect(iterable.name, 'list');

    var body = second.body as IfElement;
    var condition = body.condition as SimpleIdentifier;
    expect(condition.name, 'c');
    var thenElement = body.thenElement as IntegerLiteral;
    expect(thenElement.value, 2);
  }

  void test_listLiteral_forSpread() {
    var list =
        parseCollectionLiteral('[1, for (int x = 0; x < 10; ++x) ...[2]]')
            as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as ForElement;
    expect(second.awaitKeyword, isNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    var forLoopParts = second.forLoopParts as ForPartsWithDeclarations;
    VariableDeclaration forLoopVar = forLoopParts.variables.variables[0];
    expect(forLoopVar.name.lexeme, 'x');
    var condition = forLoopParts.condition as BinaryExpression;
    var rightOperand = condition.rightOperand as IntegerLiteral;
    expect(rightOperand.value, 10);
    var updater = forLoopParts.updaters[0] as PrefixExpression;
    var updaterOperand = updater.operand as SimpleIdentifier;
    expect(updaterOperand.name, 'x');
  }

  void test_listLiteral_if() {
    var list = parseCollectionLiteral('[1, if (true) 2]') as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as IntegerLiteral;
    expect(thenElement.value, 2);
    expect(second.elseElement, isNull);
  }

  void test_listLiteral_ifElse() {
    var list = parseCollectionLiteral('[1, if (true) 2 else 5]') as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as IntegerLiteral;
    expect(thenElement.value, 2);
    var elseElement = second.elseElement as IntegerLiteral;
    expect(elseElement.value, 5);
  }

  void test_listLiteral_ifElseFor() {
    var list = parseCollectionLiteral('[1, if (true) 2 else for (a in b) 5]')
        as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as IntegerLiteral;
    expect(thenElement.value, 2);

    var elseElement = second.elseElement as ForElement;
    var forLoopParts = elseElement.forLoopParts as ForEachPartsWithIdentifier;
    expect(forLoopParts.identifier.name, 'a');

    var forValue = elseElement.body as IntegerLiteral;
    expect(forValue.value, 5);
  }

  void test_listLiteral_ifElseSpread() {
    var list = parseCollectionLiteral('[1, if (true) ...[2] else ...?[5]]')
        as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as SpreadElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    var elseElement = second.elseElement as SpreadElement;
    expect(elseElement.spreadOperator.lexeme, '...?');
  }

  void test_listLiteral_ifFor() {
    var list =
        parseCollectionLiteral('[1, if (true) for (a in b) 2]') as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);

    var thenElement = second.thenElement as ForElement;
    var forLoopParts = thenElement.forLoopParts as ForEachPartsWithIdentifier;
    expect(forLoopParts.identifier.name, 'a');

    var forValue = thenElement.body as IntegerLiteral;
    expect(forValue.value, 2);
    expect(second.elseElement, isNull);
  }

  void test_listLiteral_ifSpread() {
    var list = parseCollectionLiteral('[1, if (true) ...[2]]') as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = list.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as SpreadElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    expect(second.elseElement, isNull);
  }

  void test_listLiteral_spread() {
    var list = parseCollectionLiteral('[1, ...[2]]') as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var element = list.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...');
    var spreadExpression = element.expression as ListLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_listLiteral_spreadQ() {
    var list = parseCollectionLiteral('[1, ...?[2]]') as ListLiteral;
    expect(list.elements, hasLength(2));
    var first = list.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var element = list.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...?');
    var spreadExpression = element.expression as ListLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_for() {
    var map = parseCollectionLiteral('{1:7, await for (y in list) 2:3}',
        inAsync: true) as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 7);

    var second = map.elements[1] as ForElement;
    expect(second.awaitKeyword, isNotNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    var forLoopParts = second.forLoopParts as ForEachPartsWithIdentifier;
    SimpleIdentifier forLoopVar = forLoopParts.identifier;
    expect(forLoopVar.name, 'y');
    expect(forLoopParts.inKeyword, isNotNull);
    var iterable = forLoopParts.iterable as SimpleIdentifier;
    expect(iterable.name, 'list');
  }

  void test_mapLiteral_forIf() {
    var map = parseCollectionLiteral('{1:7, await for (y in list) if (c) 2:3}',
        inAsync: true) as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 7);

    var second = map.elements[1] as ForElement;
    expect(second.awaitKeyword, isNotNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    var forLoopParts = second.forLoopParts as ForEachPartsWithIdentifier;
    SimpleIdentifier forLoopVar = forLoopParts.identifier;
    expect(forLoopVar.name, 'y');
    expect(forLoopParts.inKeyword, isNotNull);
    var iterable = forLoopParts.iterable as SimpleIdentifier;
    expect(iterable.name, 'list');

    var body = second.body as IfElement;
    var condition = body.condition as SimpleIdentifier;
    expect(condition.name, 'c');
    var thenElement = body.thenElement as MapLiteralEntry;
    var thenValue = thenElement.value as IntegerLiteral;
    expect(thenValue.value, 3);
  }

  void test_mapLiteral_forSpread() {
    var map = parseCollectionLiteral('{1:7, for (x = 0; x < 10; ++x) ...{2:3}}')
        as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 7);

    var second = map.elements[1] as ForElement;
    expect(second.awaitKeyword, isNull);
    expect(second.forKeyword.isKeyword, isTrue);
    expect(second.leftParenthesis.lexeme, '(');
    expect(second.rightParenthesis.lexeme, ')');
    var forLoopParts = second.forLoopParts as ForPartsWithExpression;
    var forLoopInit = forLoopParts.initialization as AssignmentExpression;
    var forLoopVar = forLoopInit.leftHandSide as SimpleIdentifier;
    expect(forLoopVar.name, 'x');
    var condition = forLoopParts.condition as BinaryExpression;
    var rightOperand = condition.rightOperand as IntegerLiteral;
    expect(rightOperand.value, 10);
    var updater = forLoopParts.updaters[0] as PrefixExpression;
    var updaterOperand = updater.operand as SimpleIdentifier;
    expect(updaterOperand.name, 'x');
  }

  void test_mapLiteral_if() {
    var map = parseCollectionLiteral('{1:1, if (true) 2:4}') as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 1);

    var second = map.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as MapLiteralEntry;
    var thenElementValue = thenElement.value as IntegerLiteral;
    expect(thenElementValue.value, 4);
    expect(second.elseElement, isNull);
  }

  void test_mapLiteral_ifElse() {
    var map = parseCollectionLiteral('{1:1, if (true) 2:4 else 5:6}')
        as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 1);

    var second = map.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as MapLiteralEntry;
    var thenElementValue = thenElement.value as IntegerLiteral;
    expect(thenElementValue.value, 4);
    var elseElement = second.elseElement as MapLiteralEntry;
    var elseElementValue = elseElement.value as IntegerLiteral;
    expect(elseElementValue.value, 6);
  }

  void test_mapLiteral_ifElseFor() {
    var map =
        parseCollectionLiteral('{1:1, if (true) 2:4 else for (c in d) 5:6}')
            as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 1);

    var second = map.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as MapLiteralEntry;
    var thenElementValue = thenElement.value as IntegerLiteral;
    expect(thenElementValue.value, 4);

    var elseElement = second.elseElement as ForElement;
    var forLoopParts = elseElement.forLoopParts as ForEachPartsWithIdentifier;
    expect(forLoopParts.identifier.name, 'c');

    var body = elseElement.body as MapLiteralEntry;
    var bodyValue = body.value as IntegerLiteral;
    expect(bodyValue.value, 6);
  }

  void test_mapLiteral_ifElseSpread() {
    var map = parseCollectionLiteral('{1:7, if (true) ...{2:4} else ...?{5:6}}')
        as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 7);

    var second = map.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as SpreadElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    var elseElement = second.elseElement as SpreadElement;
    expect(elseElement.spreadOperator.lexeme, '...?');
    var elseElementExpression = elseElement.expression as SetOrMapLiteral;
    expect(elseElementExpression.elements, hasLength(1));
    var entry = elseElementExpression.elements[0] as MapLiteralEntry;
    var entryValue = entry.value as IntegerLiteral;
    expect(entryValue.value, 6);
  }

  void test_mapLiteral_ifFor() {
    var map = parseCollectionLiteral('{1:1, if (true) for (a in b) 2:4}')
        as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 1);

    var second = map.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);

    var thenElement = second.thenElement as ForElement;
    var forLoopParts = thenElement.forLoopParts as ForEachPartsWithIdentifier;
    expect(forLoopParts.identifier.name, 'a');

    var body = thenElement.body as MapLiteralEntry;
    var thenElementValue = body.value as IntegerLiteral;
    expect(thenElementValue.value, 4);
    expect(second.elseElement, isNull);
  }

  void test_mapLiteral_ifSpread() {
    var map =
        parseCollectionLiteral('{1:1, if (true) ...{2:4}}') as SetOrMapLiteral;
    expect(map.elements, hasLength(2));
    var first = map.elements[0] as MapLiteralEntry;
    var firstValue = first.value as IntegerLiteral;
    expect(firstValue.value, 1);

    var second = map.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as SpreadElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    expect(second.elseElement, isNull);
  }

  void test_mapLiteral_spread() {
    var map = parseCollectionLiteral('{1: 2, ...{3: 4}}') as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(2));

    var element = map.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_spread2_typed() {
    var map = parseCollectionLiteral('<int, int>{1: 2, ...{3: 4}}')
        as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments!.arguments, hasLength(2));
    expect(map.elements, hasLength(2));

    var element = map.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_spread_typed() {
    var map =
        parseCollectionLiteral('<int, int>{...{3: 4}}') as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments!.arguments, hasLength(2));
    expect(map.elements, hasLength(1));

    var element = map.elements[0] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_spreadQ() {
    var map = parseCollectionLiteral('{1: 2, ...?{3: 4}}') as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(2));

    var element = map.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...?');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_spreadQ2_typed() {
    var map = parseCollectionLiteral('<int, int>{1: 2, ...?{3: 4}}')
        as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments!.arguments, hasLength(2));
    expect(map.elements, hasLength(2));

    var element = map.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...?');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_mapLiteral_spreadQ_typed() {
    var map =
        parseCollectionLiteral('<int, int>{...?{3: 4}}') as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments!.arguments, hasLength(2));
    expect(map.elements, hasLength(1));

    var element = map.elements[0] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...?');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setLiteral_if() {
    var setLiteral =
        parseCollectionLiteral('{1, if (true) 2}') as SetOrMapLiteral;
    expect(setLiteral.elements, hasLength(2));
    var first = setLiteral.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = setLiteral.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as IntegerLiteral;
    expect(thenElement.value, 2);
    expect(second.elseElement, isNull);
  }

  void test_setLiteral_ifElse() {
    var setLiteral =
        parseCollectionLiteral('{1, if (true) 2 else 5}') as SetOrMapLiteral;
    expect(setLiteral.elements, hasLength(2));
    var first = setLiteral.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = setLiteral.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as IntegerLiteral;
    expect(thenElement.value, 2);
    var elseElement = second.elseElement as IntegerLiteral;
    expect(elseElement.value, 5);
  }

  void test_setLiteral_ifElseSpread() {
    var setLiteral =
        parseCollectionLiteral('{1, if (true) ...{2} else ...?[5]}')
            as SetOrMapLiteral;
    expect(setLiteral.elements, hasLength(2));
    var first = setLiteral.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = setLiteral.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as SpreadElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    var theExpression = thenElement.expression as SetOrMapLiteral;
    expect(theExpression.elements, hasLength(1));
    var elseElement = second.elseElement as SpreadElement;
    expect(elseElement.spreadOperator.lexeme, '...?');
    var elseExpression = elseElement.expression as ListLiteral;
    expect(elseExpression.elements, hasLength(1));
  }

  void test_setLiteral_ifSpread() {
    var setLiteral =
        parseCollectionLiteral('{1, if (true) ...[2]}') as SetOrMapLiteral;
    expect(setLiteral.elements, hasLength(2));
    var first = setLiteral.elements[0] as IntegerLiteral;
    expect(first.value, 1);

    var second = setLiteral.elements[1] as IfElement;
    var condition = second.condition as BooleanLiteral;
    expect(condition.value, isTrue);
    var thenElement = second.thenElement as SpreadElement;
    expect(thenElement.spreadOperator.lexeme, '...');
    expect(second.elseElement, isNull);
  }

  void test_setLiteral_spread2() {
    var set = parseCollectionLiteral('{3, ...[4]}') as SetOrMapLiteral;
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNull);
    expect(set.elements, hasLength(2));
    var value = set.elements[0] as IntegerLiteral;
    expect(value.value, 3);

    var element = set.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...');
    var spreadExpression = element.expression as ListLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setLiteral_spread2Q() {
    var set = parseCollectionLiteral('{3, ...?[4]}') as SetOrMapLiteral;
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNull);
    expect(set.elements, hasLength(2));
    var value = set.elements[0] as IntegerLiteral;
    expect(value.value, 3);

    var element = set.elements[1] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...?');
    var spreadExpression = element.expression as ListLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setLiteral_spread_typed() {
    var set = parseCollectionLiteral('<int>{...[3]}') as SetOrMapLiteral;
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNotNull);
    expect(set.elements, hasLength(1));

    var element = set.elements[0] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...');
    var spreadExpression = element.expression as ListLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setLiteral_spreadQ_typed() {
    var set = parseCollectionLiteral('<int>{...?[3]}') as SetOrMapLiteral;
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNotNull);
    expect(set.elements, hasLength(1));

    var element = set.elements[0] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...?');
    var spreadExpression = element.expression as ListLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setOrMapLiteral_spread() {
    var map = parseCollectionLiteral('{...{3: 4}}') as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(1));

    var element = map.elements[0] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }

  void test_setOrMapLiteral_spreadQ() {
    var map = parseCollectionLiteral('{...?{3: 4}}') as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(1));

    var element = map.elements[0] as SpreadElement;
    expect(element.spreadOperator.lexeme, '...?');
    var spreadExpression = element.expression as SetOrMapLiteral;
    expect(spreadExpression.elements, hasLength(1));
  }
}
