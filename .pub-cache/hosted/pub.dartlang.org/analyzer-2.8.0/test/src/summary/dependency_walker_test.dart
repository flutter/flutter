// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary/link.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DependencyWalkerTest);
  });
}

@reflectiveTest
class DependencyWalkerTest {
  final nodes = <String, TestNode>{};

  void checkGraph(Map<String, List<String>> graph, String startingNodeName,
      List<List<String>> expectedEvaluations, List<bool> expectedSccFlags) {
    makeGraph(graph);
    var walker = walk(startingNodeName);
    expect(walker._evaluations, expectedEvaluations.map((x) => x.toSet()));
    expect(walker._sccFlags, expectedSccFlags);
  }

  TestNode getNode(String name) =>
      nodes.putIfAbsent(name, () => TestNode(name));

  void makeGraph(Map<String, List<String>> graph) {
    graph.forEach((name, deps) {
      var node = getNode(name);
      for (var dep in deps) {
        node._dependencies.add(getNode(dep));
      }
    });
  }

  void test_complex_graph() {
    checkGraph(
        {
          'a': ['b', 'c'],
          'b': ['c', 'd'],
          'c': [],
          'd': ['c', 'e'],
          'e': ['b', 'f'],
          'f': ['c', 'd']
        },
        'a',
        [
          ['c'],
          ['b', 'd', 'e', 'f'],
          ['a']
        ],
        [false, true, false]);
  }

  void test_diamond() {
    checkGraph(
        {
          'a': ['b', 'c'],
          'b': ['d'],
          'c': ['d'],
          'd': []
        },
        'a',
        [
          ['d'],
          ['b'],
          ['c'],
          ['a']
        ],
        [false, false, false, false]);
  }

  void test_singleNode() {
    checkGraph(
        {'a': []},
        'a',
        [
          ['a']
        ],
        [false]);
  }

  void test_singleNodeWithTrivialCycle() {
    checkGraph(
        {
          'a': ['a']
        },
        'a',
        [
          ['a']
        ],
        [true]);
  }

  void test_threeNodesWithCircularDependency() {
    checkGraph(
        {
          'a': ['b'],
          'b': ['c'],
          'c': ['a'],
        },
        'a',
        [
          ['a', 'b', 'c']
        ],
        [true]);
  }

  test_twoBacklinksEarlierFirst() {
    // Test a graph A->B->C->D, where D points back to B and then C.
    checkGraph(
        {
          'a': ['b'],
          'b': ['c'],
          'c': ['d'],
          'd': ['b', 'c']
        },
        'a',
        [
          ['b', 'c', 'd'],
          ['a']
        ],
        [true, false]);
  }

  test_twoBacklinksLaterFirst() {
    // Test a graph A->B->C->D, where D points back to C and then B.
    checkGraph(
        {
          'a': ['b'],
          'b': ['c'],
          'c': ['d'],
          'd': ['c', 'b']
        },
        'a',
        [
          ['b', 'c', 'd'],
          ['a']
        ],
        [true, false]);
  }

  void test_twoNodesWithCircularDependency() {
    checkGraph(
        {
          'a': ['b'],
          'b': ['a']
        },
        'a',
        [
          ['a', 'b']
        ],
        [true]);
  }

  void test_twoNodesWithSimpleDependency() {
    checkGraph(
        {
          'a': ['b'],
          'b': []
        },
        'a',
        [
          ['b'],
          ['a']
        ],
        [false, false]);
  }

  TestWalker walk(String startingNodeName) =>
      TestWalker()..walk(getNode(startingNodeName));
}

class TestNode extends Node<TestNode> {
  final String _name;

  @override
  bool isEvaluated = false;

  bool _computeDependenciesCalled = false;

  final _dependencies = <TestNode>[];

  TestNode(this._name);

  @override
  List<TestNode> computeDependencies() {
    expect(_computeDependenciesCalled, false);
    _computeDependenciesCalled = true;
    return _dependencies;
  }
}

class TestWalker extends DependencyWalker<TestNode> {
  final _evaluations = <Set<String>>[];
  final _sccFlags = <bool>[];

  @override
  void evaluate(TestNode v) {
    v.isEvaluated = true;
    _evaluations.add({v._name});
    _sccFlags.add(false);
  }

  @override
  void evaluateScc(List<TestNode> scc) {
    for (var v in scc) {
      v.isEvaluated = true;
    }
    var sccNames = scc.map((node) => node._name).toSet();
    // Make sure there were no duplicates
    expect(sccNames.length, scc.length);
    _evaluations.add(sccNames);
    _sccFlags.add(true);
  }
}
