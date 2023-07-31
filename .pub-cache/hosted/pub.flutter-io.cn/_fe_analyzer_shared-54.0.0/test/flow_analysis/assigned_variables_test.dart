// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:test/test.dart';

main() {
  test('readCapturedAnywhere records reads in closures', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    var v3 = _Variable('v3');
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.declare(v3);
    assignedVariables.read(v1);
    assignedVariables.beginNode();
    assignedVariables.read(v2);
    assignedVariables.endNode(_Node(),
        isClosureOrLateVariableInitializer: true);
    assignedVariables.read(v3);
    assignedVariables.finish();
    expect(assignedVariables.readCapturedAnywhere,
        {assignedVariables.keyForVariable(v2)});
  });

  test('readCapturedAnywhere does not record variables local to a closure', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    assignedVariables.declare(v1);
    assignedVariables.beginNode();
    assignedVariables.declare(v2);
    assignedVariables.read(v1);
    assignedVariables.read(v2);
    assignedVariables.endNode(_Node(),
        isClosureOrLateVariableInitializer: true);
    assignedVariables.finish();
    expect(assignedVariables.readCapturedAnywhere,
        {assignedVariables.keyForVariable(v1)});
  });

  test('capturedAnywhere records assignments in closures', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    var v3 = _Variable('v3');
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.declare(v3);
    assignedVariables.write(v1);
    assignedVariables.beginNode();
    assignedVariables.write(v2);
    assignedVariables.endNode(_Node(),
        isClosureOrLateVariableInitializer: true);
    assignedVariables.write(v3);
    assignedVariables.finish();
    expect(assignedVariables.capturedAnywhere,
        {assignedVariables.keyForVariable(v2)});
  });

  test('capturedAnywhere does not record variables local to a closure', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    assignedVariables.declare(v1);
    assignedVariables.beginNode();
    assignedVariables.declare(v2);
    assignedVariables.write(v1);
    assignedVariables.write(v2);
    assignedVariables.endNode(_Node(),
        isClosureOrLateVariableInitializer: true);
    assignedVariables.finish();
    expect(assignedVariables.capturedAnywhere,
        {assignedVariables.keyForVariable(v1)});
  });

  test('readAnywhere records all reads', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    var v3 = _Variable('v3');
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.declare(v3);
    assignedVariables.read(v1);
    assignedVariables.beginNode();
    assignedVariables.read(v2);
    assignedVariables.endNode(_Node(),
        isClosureOrLateVariableInitializer: true);
    assignedVariables.read(v3);
    assignedVariables.finish();
    expect(assignedVariables.readAnywhere, {
      assignedVariables.keyForVariable(v1),
      assignedVariables.keyForVariable(v2),
      assignedVariables.keyForVariable(v3)
    });
  });

  test('writtenAnywhere records all assignments', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    var v3 = _Variable('v3');
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.declare(v3);
    assignedVariables.write(v1);
    assignedVariables.beginNode();
    assignedVariables.write(v2);
    assignedVariables.endNode(_Node(),
        isClosureOrLateVariableInitializer: true);
    assignedVariables.write(v3);
    assignedVariables.finish();
    expect(assignedVariables.writtenAnywhere, {
      assignedVariables.keyForVariable(v1),
      assignedVariables.keyForVariable(v2),
      assignedVariables.keyForVariable(v3)
    });
  });

  test('readInNode ignores reads outside the node', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.read(v1);
    assignedVariables.beginNode();
    var node = _Node();
    assignedVariables.endNode(node);
    assignedVariables.read(v2);
    assignedVariables.finish();
    expect(assignedVariables.readInNode(node), isEmpty);
  });

  test('readInNode records reads inside the node', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.declare(v1);
    assignedVariables.beginNode();
    assignedVariables.read(v1);
    var node = _Node();
    assignedVariables.endNode(node);
    assignedVariables.finish();
    expect(assignedVariables.readInNode(node),
        {assignedVariables.keyForVariable(v1)});
  });

  test('readInNode records reads in a nested node', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.declare(v1);
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.read(v1);
    assignedVariables.endNode(_Node());
    var node = _Node();
    assignedVariables.endNode(node);
    assignedVariables.finish();
    expect(assignedVariables.readInNode(node),
        {assignedVariables.keyForVariable(v1)});
  });

  test('readInNode records reads in a closure', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.declare(v1);
    assignedVariables.beginNode();
    assignedVariables.read(v1);
    var node = _Node();
    assignedVariables.endNode(node, isClosureOrLateVariableInitializer: true);
    assignedVariables.finish();
    expect(assignedVariables.readInNode(node),
        {assignedVariables.keyForVariable(v1)});
  });

  test('writtenInNode ignores assignments outside the node', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.write(v1);
    assignedVariables.beginNode();
    var node = _Node();
    assignedVariables.endNode(node);
    assignedVariables.write(v2);
    assignedVariables.finish();
    expect(assignedVariables.writtenInNode(node), isEmpty);
  });

  test('writtenInNode records assignments inside the node', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.declare(v1);
    assignedVariables.beginNode();
    assignedVariables.write(v1);
    var node = _Node();
    assignedVariables.endNode(node);
    assignedVariables.finish();
    expect(assignedVariables.writtenInNode(node),
        {assignedVariables.keyForVariable(v1)});
  });

  test('writtenInNode records assignments in a nested node', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.declare(v1);
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.write(v1);
    assignedVariables.endNode(_Node());
    var node = _Node();
    assignedVariables.endNode(node);
    assignedVariables.finish();
    expect(assignedVariables.writtenInNode(node),
        {assignedVariables.keyForVariable(v1)});
  });

  test('writtenInNode records assignments in a closure', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.declare(v1);
    assignedVariables.beginNode();
    assignedVariables.write(v1);
    var node = _Node();
    assignedVariables.endNode(node, isClosureOrLateVariableInitializer: true);
    assignedVariables.finish();
    expect(assignedVariables.writtenInNode(node),
        {assignedVariables.keyForVariable(v1)});
  });

  test('readCapturedInNode ignores reads in non-nested closures', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.beginNode();
    assignedVariables.read(v1);
    assignedVariables.endNode(_Node(),
        isClosureOrLateVariableInitializer: true);
    assignedVariables.beginNode();
    var node = _Node();
    assignedVariables.endNode(node);
    assignedVariables.beginNode();
    assignedVariables.read(v2);
    assignedVariables.endNode(_Node(),
        isClosureOrLateVariableInitializer: true);
    assignedVariables.finish();
    expect(assignedVariables.readCapturedInNode(node), isEmpty);
  });

  test('readCapturedInNode records assignments in nested closures', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.declare(v1);
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.read(v1);
    assignedVariables.endNode(_Node(),
        isClosureOrLateVariableInitializer: true);
    var innerNode = _Node();
    assignedVariables.endNode(innerNode);
    var outerNode = _Node();
    assignedVariables.endNode(outerNode);
    assignedVariables.finish();
    expect(assignedVariables.readCapturedInNode(innerNode),
        {assignedVariables.keyForVariable(v1)});
    expect(assignedVariables.readCapturedInNode(outerNode),
        {assignedVariables.keyForVariable(v1)});
  });

  test('capturedInNode ignores assignments in non-nested closures', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.beginNode();
    assignedVariables.write(v1);
    assignedVariables.endNode(_Node(),
        isClosureOrLateVariableInitializer: true);
    assignedVariables.beginNode();
    var node = _Node();
    assignedVariables.endNode(node);
    assignedVariables.beginNode();
    assignedVariables.write(v2);
    assignedVariables.endNode(_Node(),
        isClosureOrLateVariableInitializer: true);
    assignedVariables.finish();
    expect(assignedVariables.capturedInNode(node), isEmpty);
  });

  test('capturedInNode records assignments in nested closures', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.declare(v1);
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.write(v1);
    assignedVariables.endNode(_Node(),
        isClosureOrLateVariableInitializer: true);
    var innerNode = _Node();
    assignedVariables.endNode(innerNode);
    var outerNode = _Node();
    assignedVariables.endNode(outerNode);
    assignedVariables.finish();
    expect(assignedVariables.capturedInNode(innerNode),
        {assignedVariables.keyForVariable(v1)});
    expect(assignedVariables.capturedInNode(outerNode),
        {assignedVariables.keyForVariable(v1)});
  });

  group('Variables do not percolate beyond the scope they were declared in',
      () {
    test('Non-closure scope', () {
      var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
      var v1 = _Variable('v1');
      var v2 = _Variable('v2');
      assignedVariables.beginNode();
      assignedVariables.beginNode();
      assignedVariables.declare(v1);
      assignedVariables.declare(v2);
      assignedVariables.read(v1);
      assignedVariables.write(v1);
      assignedVariables.beginNode();
      assignedVariables.read(v2);
      assignedVariables.write(v2);
      assignedVariables.endNode(_Node(),
          isClosureOrLateVariableInitializer: true);
      var innerNode = _Node();
      assignedVariables.endNode(innerNode,
          isClosureOrLateVariableInitializer: false);
      var outerNode = _Node();
      assignedVariables.endNode(outerNode);
      assignedVariables.finish();
      expect(assignedVariables.readInNode(innerNode), isEmpty);
      expect(assignedVariables.writtenInNode(innerNode), isEmpty);
      expect(assignedVariables.readCapturedInNode(innerNode), isEmpty);
      expect(assignedVariables.capturedInNode(innerNode), isEmpty);
      expect(assignedVariables.readInNode(outerNode), isEmpty);
      expect(assignedVariables.writtenInNode(outerNode), isEmpty);
      expect(assignedVariables.readCapturedInNode(outerNode), isEmpty);
      expect(assignedVariables.capturedInNode(outerNode), isEmpty);
    });

    test('Closure scope', () {
      var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
      var v1 = _Variable('v1');
      var v2 = _Variable('v2');
      assignedVariables.beginNode();
      assignedVariables.beginNode();
      assignedVariables.declare(v1);
      assignedVariables.declare(v2);
      assignedVariables.read(v1);
      assignedVariables.write(v1);
      assignedVariables.beginNode();
      assignedVariables.read(v2);
      assignedVariables.write(v2);
      assignedVariables.endNode(_Node(),
          isClosureOrLateVariableInitializer: true);
      var innerNode = _Node();
      assignedVariables.endNode(innerNode,
          isClosureOrLateVariableInitializer: true);
      var outerNode = _Node();
      assignedVariables.endNode(outerNode);
      assignedVariables.finish();
      expect(assignedVariables.readInNode(innerNode), isEmpty);
      expect(assignedVariables.writtenInNode(innerNode), isEmpty);
      expect(assignedVariables.readCapturedInNode(innerNode), isEmpty);
      expect(assignedVariables.capturedInNode(innerNode), isEmpty);
      expect(assignedVariables.readInNode(outerNode), isEmpty);
      expect(assignedVariables.writtenInNode(outerNode), isEmpty);
      expect(assignedVariables.readCapturedInNode(outerNode), isEmpty);
      expect(assignedVariables.capturedInNode(outerNode), isEmpty);
    });
  });

  test('discardNode percolates declarations to enclosing node', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    var node = _Node();
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.discardNode();
    assignedVariables.endNode(node);
    assignedVariables.finish();
    expect(
        assignedVariables.declaredInNode(node),
        unorderedEquals([
          assignedVariables.keyForVariable(v1),
          assignedVariables.keyForVariable(v2)
        ]));
  });

  test('discardNode percolates reads to enclosing node', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    var node = _Node();
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.read(v1);
    assignedVariables.read(v2);
    assignedVariables.discardNode();
    assignedVariables.endNode(node);
    assignedVariables.finish();
    expect(
        assignedVariables.readInNode(node),
        unorderedEquals([
          assignedVariables.keyForVariable(v1),
          assignedVariables.keyForVariable(v2)
        ]));
  });

  test('discardNode percolates writes to enclosing node', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    var node = _Node();
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.write(v1);
    assignedVariables.write(v2);
    assignedVariables.discardNode();
    assignedVariables.endNode(node);
    assignedVariables.finish();
    expect(
        assignedVariables.writtenInNode(node),
        unorderedEquals([
          assignedVariables.keyForVariable(v1),
          assignedVariables.keyForVariable(v2)
        ]));
  });

  test('discardNode percolates read captures to enclosing node', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    var node = _Node();
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.read(v1);
    assignedVariables.read(v2);
    assignedVariables.endNode(_Node(),
        isClosureOrLateVariableInitializer: true);
    assignedVariables.discardNode();
    assignedVariables.endNode(node);
    assignedVariables.finish();
    expect(
        assignedVariables.readCapturedInNode(node),
        unorderedEquals([
          assignedVariables.keyForVariable(v1),
          assignedVariables.keyForVariable(v2)
        ]));
  });

  test('discardNode percolates write captures to enclosing node', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    var node = _Node();
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.write(v1);
    assignedVariables.write(v2);
    assignedVariables.endNode(_Node(),
        isClosureOrLateVariableInitializer: true);
    assignedVariables.discardNode();
    assignedVariables.endNode(node);
    assignedVariables.finish();
    expect(
        assignedVariables.capturedInNode(node),
        unorderedEquals([
          assignedVariables.keyForVariable(v1),
          assignedVariables.keyForVariable(v2)
        ]));
  });

  test('deferNode allows deferring of node info', () {
    var assignedVariables = AssignedVariablesForTesting<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    var v3 = _Variable('v3');
    var v4 = _Variable('v4');
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.declare(v4);
    assignedVariables.beginNode();
    assignedVariables.write(v1);
    assignedVariables.declare(v3);
    assignedVariables.beginNode();
    assignedVariables.write(v2);
    assignedVariables.endNode(_Node(),
        isClosureOrLateVariableInitializer: true);
    var info = assignedVariables.deferNode();
    assignedVariables.beginNode();
    assignedVariables.write(v4);
    assignedVariables.endNode(_Node());
    var node = _Node();
    assignedVariables.storeInfo(node, info);
    assignedVariables.finish();
    expect(assignedVariables.declaredInNode(node),
        [assignedVariables.keyForVariable(v3)]);
    expect(
        assignedVariables.writtenInNode(node),
        unorderedEquals([
          assignedVariables.keyForVariable(v1),
          assignedVariables.keyForVariable(v2)
        ]));
    expect(assignedVariables.capturedInNode(node),
        [assignedVariables.keyForVariable(v2)]);
  });
}

class _Node {}

class _Variable {
  final String name;

  _Variable(this.name);

  @override
  String toString() => name;
}
