// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:graphs/graphs.dart';
import 'package:test/test.dart';

import 'utils/graph.dart';
import 'utils/utils.dart';

void main() {
  group('strongly connected components', () {
    /// Run [stronglyConnectedComponents] on [g].
    List<List<String>> components(
      Map<String, List<String>?> g, {
      Iterable<String>? startNodes,
    }) {
      final graph = Graph(g);
      return stronglyConnectedComponents(
          startNodes ?? graph.allNodes, graph.edges);
    }

    test('empty result for empty graph', () {
      var result = components({});
      expect(result, isEmpty);
    });

    test('single item for single node', () {
      var result = components({'a': []});
      expect(result, [
        ['a']
      ]);
    });

    test('handles non-cycles', () {
      var result = components({
        'a': ['b'],
        'b': ['c'],
        'c': []
      });
      expect(result, [
        ['c'],
        ['b'],
        ['a']
      ]);
    });

    test('handles entire graph as cycle', () {
      var result = components({
        'a': ['b'],
        'b': ['c'],
        'c': ['a']
      });
      expect(result, [allOf(contains('a'), contains('b'), contains('c'))]);
    });

    test('includes the first passed root last in a cycle', () {
      // In cases where this is used to find a topological ordering the first
      // value in nodes should always come last.
      var graph = {
        'a': ['b'],
        'b': ['a']
      };
      var resultFromA = components(graph, startNodes: ['a']);
      var resultFromB = components(graph, startNodes: ['b']);
      expect(resultFromA.single.last, 'a');
      expect(resultFromB.single.last, 'b');
    });

    test('handles cycles in the middle', () {
      var result = components({
        'a': ['b', 'c'],
        'b': ['c', 'd'],
        'c': ['b', 'd'],
        'd': [],
      });
      expect(result, [
        ['d'],
        allOf(contains('b'), contains('c')),
        ['a'],
      ]);
    });

    test('handles self cycles', () {
      var result = components({
        'a': ['b'],
        'b': ['b'],
      });
      expect(result, [
        ['b'],
        ['a'],
      ]);
    });

    test('valid topological ordering for disjoint subgraphs', () {
      var result = components({
        'a': ['b', 'c'],
        'b': ['b1', 'b2'],
        'c': ['c1', 'c2'],
        'b1': [],
        'b2': [],
        'c1': [],
        'c2': []
      });

      expect(
          result,
          containsAllInOrder([
            ['c1'],
            ['c'],
            ['a']
          ]));
      expect(
          result,
          containsAllInOrder([
            ['c2'],
            ['c'],
            ['a']
          ]));
      expect(
          result,
          containsAllInOrder([
            ['b1'],
            ['b'],
            ['a']
          ]));
      expect(
          result,
          containsAllInOrder([
            ['b2'],
            ['b'],
            ['a']
          ]));
    });

    test('handles getting null for edges', () {
      var result = components({
        'a': ['b'],
        'b': null,
      });
      expect(result, [
        ['b'],
        ['a']
      ]);
    });
  });

  group('custom hashCode and equals', () {
    /// Run [stronglyConnectedComponents] on [g].
    List<List<String>> components(
      Map<String, List<String>?> g, {
      Iterable<String>? startNodes,
    }) {
      final graph = BadGraph(g);

      startNodes ??= graph.allNodes.map((n) => n.value);

      return stronglyConnectedComponents<X>(
              startNodes.map((n) => X(n)), graph.edges,
              equals: xEquals, hashCode: xHashCode)
          .map((list) => list.map((x) => x.value).toList())
          .toList();
    }

    test('empty result for empty graph', () {
      var result = components({});
      expect(result, isEmpty);
    });

    test('single item for single node', () {
      var result = components({'a': []});
      expect(result, [
        ['a']
      ]);
    });

    test('handles non-cycles', () {
      var result = components({
        'a': ['b'],
        'b': ['c'],
        'c': []
      });
      expect(result, [
        ['c'],
        ['b'],
        ['a']
      ]);
    });

    test('handles entire graph as cycle', () {
      var result = components({
        'a': ['b'],
        'b': ['c'],
        'c': ['a']
      });
      expect(result, [allOf(contains('a'), contains('b'), contains('c'))]);
    });

    test('includes the first passed root last in a cycle', () {
      // In cases where this is used to find a topological ordering the first
      // value in nodes should always come last.
      var graph = {
        'a': ['b'],
        'b': ['a']
      };
      var resultFromA = components(graph, startNodes: ['a']);
      var resultFromB = components(graph, startNodes: ['b']);
      expect(resultFromA.single.last, 'a');
      expect(resultFromB.single.last, 'b');
    });

    test('handles cycles in the middle', () {
      var result = components({
        'a': ['b', 'c'],
        'b': ['c', 'd'],
        'c': ['b', 'd'],
        'd': [],
      });
      expect(result, [
        ['d'],
        allOf(contains('b'), contains('c')),
        ['a'],
      ]);
    });

    test('handles self cycles', () {
      var result = components({
        'a': ['b'],
        'b': ['b'],
      });
      expect(result, [
        ['b'],
        ['a'],
      ]);
    });

    test('valid topological ordering for disjoint subgraphs', () {
      var result = components({
        'a': ['b', 'c'],
        'b': ['b1', 'b2'],
        'c': ['c1', 'c2'],
        'b1': [],
        'b2': [],
        'c1': [],
        'c2': []
      });

      expect(
          result,
          containsAllInOrder([
            ['c1'],
            ['c'],
            ['a']
          ]));
      expect(
          result,
          containsAllInOrder([
            ['c2'],
            ['c'],
            ['a']
          ]));
      expect(
          result,
          containsAllInOrder([
            ['b1'],
            ['b'],
            ['a']
          ]));
      expect(
          result,
          containsAllInOrder([
            ['b2'],
            ['b'],
            ['a']
          ]));
    });

    test('handles getting null for edges', () {
      var result = components({
        'a': ['b'],
        'b': null,
      });
      expect(result, [
        ['b'],
        ['a']
      ]);
    });
  });
}
