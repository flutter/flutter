// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' show min;

/// Finds the strongly connected components of a directed graph using Tarjan's
/// algorithm.
///
/// The result will be a valid reverse topological order ordering of the
/// strongly connected components. Components further from a root will appear in
/// the result before the components which they are connected to.
///
/// Nodes within a strongly connected component have no ordering guarantees,
/// except that if the first value in [nodes] is a valid root, and is contained
/// in a cycle, it will be the last element of that cycle.
///
/// [nodes] must contain at least a root of every tree in the graph if there are
/// disjoint subgraphs but it may contain all nodes in the graph if the roots
/// are not known.
///
/// If [equals] is provided, it is used to compare nodes in the graph. If
/// [equals] is omitted, the node's own [Object.==] is used instead.
///
/// Similarly, if [hashCode] is provided, it is used to produce a hash value
/// for nodes to efficiently calculate the return value. If it is omitted, the
/// key's own [Object.hashCode] is used.
///
/// If you supply one of [equals] or [hashCode], you should generally also to
/// supply the other.
List<List<T>> stronglyConnectedComponents<T extends Object>(
  Iterable<T> nodes,
  Iterable<T> Function(T) edges, {
  bool Function(T, T)? equals,
  int Function(T)? hashCode,
}) {
  final result = <List<T>>[];
  final lowLinks = HashMap<T, int>(equals: equals, hashCode: hashCode);
  final indexes = HashMap<T, int>(equals: equals, hashCode: hashCode);
  final onStack = HashSet<T>(equals: equals, hashCode: hashCode);

  final nonNullEquals = equals ?? _defaultEquals;

  var index = 0;
  var lastVisited = Queue<T>();

  void strongConnect(T node) {
    indexes[node] = index;
    var lowLink = lowLinks[node] = index;
    index++;
    lastVisited.addLast(node);
    onStack.add(node);
    for (final next in edges(node)) {
      if (!indexes.containsKey(next)) {
        strongConnect(next);
        lowLink = lowLinks[node] = min(lowLink, lowLinks[next]!);
      } else if (onStack.contains(next)) {
        lowLink = lowLinks[node] = min(lowLink, indexes[next]!);
      }
    }
    if (lowLinks[node] == indexes[node]) {
      final component = <T>[];
      T next;
      do {
        next = lastVisited.removeLast();
        onStack.remove(next);
        component.add(next);
      } while (!nonNullEquals(next, node));
      result.add(component);
    }
  }

  for (final node in nodes) {
    if (!indexes.containsKey(node)) strongConnect(node);
  }
  return result;
}

bool _defaultEquals(Object a, Object b) => a == b;
