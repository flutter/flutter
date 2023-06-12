// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

/// Computes the strongly connected components of [graph].
///
/// This implementation is based on [Dijkstra's path-based strong component
/// algorithm]
/// (https://en.wikipedia.org/wiki/Path-based_strong_component_algorithm#Description).
List<List<T>> computeStrongComponents<T>(Graph<T> graph) {
  List<List<T>> result = <List<T>>[];
  int count = 0;
  Map<T, int> preorderNumbers = <T, int>{};
  List<T> unassigned = <T>[];
  List<T> candidates = <T>[];
  Set<T> assigned = <T>{};

  void recursivelySearch(T vertex) {
    // Step 1: Set the preorder number of [vertex] to [count], and increment
    // [count].
    preorderNumbers[vertex] = count++;

    // Step 2: Push [vertex] onto [unassigned] and also onto [candidates].
    unassigned.add(vertex);
    candidates.add(vertex);

    // Step 3: For each edge from [vertex] to a neighboring vertex [neighbor]:
    for (T neighbor in graph.neighborsOf(vertex)) {
      var neighborPreorderNumber = preorderNumbers[neighbor];
      if (neighborPreorderNumber == null) {
        // If the preorder number of [neighbor] has not yet been assigned,
        // recursively search [neighbor];
        recursivelySearch(neighbor);
      } else if (!assigned.contains(neighbor)) {
        // Otherwise, if [neighbor] has not yet been assigned to a strongly
        // connected component:
        //
        // * Repeatedly pop vertices from [candidates] until the top element of
        //   [candidates] has a preorder number less than or equal to the
        //   preorder number of [neighbor].
        while (preorderNumbers[candidates.last]! > neighborPreorderNumber) {
          candidates.removeLast();
        }
      }
    }
    // Step 4: If [vertex] is the top element of [candidates]:
    if (candidates.last == vertex) {
      // Pop vertices from [unassigned] until [vertex] has been popped, and
      // assign the popped vertices to a new component.
      List<T> component = <T>[];
      while (true) {
        T top = unassigned.removeLast();
        component.add(top);
        assigned.add(top);
        if (top == vertex) break;
      }
      result.add(component);

      // Pop [vertex] from [candidates].
      candidates.removeLast();
    }
  }

  for (T vertex in graph.vertices) {
    if (preorderNumbers[vertex] == null) {
      recursivelySearch(vertex);
    }
  }

  return result;
}

abstract class Graph<T> {
  Iterable<T> get vertices;

  Iterable<T> neighborsOf(T vertex);
}
