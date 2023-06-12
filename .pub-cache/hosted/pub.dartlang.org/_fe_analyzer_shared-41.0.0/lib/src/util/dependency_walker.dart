// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An instance of [DependencyWalker] contains the core algorithms for
/// walking a dependency graph and evaluating nodes in a safe order.
abstract class DependencyWalker<NodeType extends Node<NodeType>> {
  /// Called by [walk] to evaluate a single non-cyclical node, after
  /// all that node's dependencies have been evaluated.
  void evaluate(NodeType v);

  /// Called by [walk] to evaluate a strongly connected component
  /// containing one or more nodes.  All dependencies of the strongly
  /// connected component have been evaluated.
  void evaluateScc(List<NodeType> scc);

  /// Walk the dependency graph starting at [startingPoint], finding
  /// strongly connected components and evaluating them in a safe order
  /// by calling [evaluate] and [evaluateScc].
  ///
  /// This is an implementation of Tarjan's strongly connected
  /// components algorithm
  /// (https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm).
  void walk(NodeType startingPoint) {
    // TODO(paulberry): consider rewriting in a non-recursive way so
    // that long dependency chains don't cause stack overflow.

    // TODO(paulberry): in the event that an exception occurs during
    // the walk, restore the state of the [Node] data structures so
    // that further evaluation will be safe.

    if (startingPoint.isEvaluated) return;

    // The index which will be assigned to the next node that is
    // freshly visited.
    int index = 1;

    // Stack of nodes which have been seen so far and whose strongly
    // connected component is still being determined.  Nodes are only
    // popped off the stack when they are evaluated, so sometimes the
    // stack contains nodes that were visited after the current node.
    List<NodeType> stack = <NodeType>[];

    void strongConnect(NodeType node) {
      bool hasTrivialCycle = false;

      // Assign the current node an index and add it to the stack.  We
      // haven't seen any of its dependencies yet, so set its lowLink
      // to its index, indicating that so far it is the only node in
      // its strongly connected component.
      node._index = node._lowLink = index++;
      stack.add(node);

      // Consider the node's dependencies one at a time.
      for (NodeType dependency in Node.getDependencies(node)) {
        // If the dependency has already been evaluated, it can't be
        // part of this node's strongly connected component, so we can
        // skip it.
        if (dependency.isEvaluated) {
          continue;
        }
        if (identical(node, dependency)) {
          // If a node includes itself as a dependency, there is no need to
          // explore the dependency further.
          hasTrivialCycle = true;
        } else if (dependency._index == 0) {
          // The dependency hasn't been seen yet, so recurse on it.
          strongConnect(dependency);
          // If the dependency's lowLink refers to a node that was
          // visited before the current node, that means that the
          // current node, the dependency, and the node referred to by
          // the dependency's lowLink are all part of the same
          // strongly connected component, so we need to update the
          // current node's lowLink accordingly.
          if (dependency._lowLink < node._lowLink) {
            node._lowLink = dependency._lowLink;
          }
        } else {
          // The dependency has already been seen, so it is part of
          // the current node's strongly connected component.  If it
          // was visited earlier than the current node's lowLink, then
          // it is a new addition to the current node's strongly
          // connected component, so we need to update the current
          // node's lowLink accordingly.
          if (dependency._index < node._lowLink) {
            node._lowLink = dependency._index;
          }
        }
      }

      // If the current node's lowLink is the same as its index, then
      // we have finished visiting a strongly connected component, so
      // pop the stack and evaluate it before moving on.
      if (node._lowLink == node._index) {
        // The strongly connected component has only one node.  If there is a
        // cycle, it's a trivial one.
        if (identical(stack.last, node)) {
          stack.removeLast();
          if (hasTrivialCycle) {
            evaluateScc(<NodeType>[node]);
          } else {
            evaluate(node);
          }
        } else {
          // There are multiple nodes in the strongly connected
          // component.
          List<NodeType> scc = <NodeType>[];
          while (true) {
            NodeType otherNode = stack.removeLast();
            scc.add(otherNode);
            if (identical(otherNode, node)) {
              break;
            }
          }
          evaluateScc(scc);
        }
      }
    }

    // Kick off the algorithm starting with the starting point.
    strongConnect(startingPoint);
  }
}

/// Instances of [Node] represent nodes in a dependency graph.  The
/// type parameter, [NodeType], is the derived type (this affords some
/// extra type safety by making it difficult to accidentally construct
/// bridges between unrelated dependency graphs).
abstract class Node<NodeType> {
  /// Index used by Tarjan's strongly connected components algorithm.
  /// Zero means the node has not been visited yet; a nonzero value
  /// counts the order in which the node was visited.
  int _index = 0;

  /// Low link used by Tarjan's strongly connected components
  /// algorithm.  This represents the smallest [_index] of all the nodes
  /// in the strongly connected component to which this node belongs.
  int _lowLink = 0;

  List<NodeType>? _dependencies;

  /// Indicates whether this node has been evaluated yet.
  bool get isEvaluated;

  /// Compute the dependencies of this node.
  List<NodeType> computeDependencies();

  /// Gets the dependencies of the given node, computing them if necessary.
  static List<NodeType> getDependencies<NodeType>(Node<NodeType> node) {
    return node._dependencies ??= node.computeDependencies();
  }
}
