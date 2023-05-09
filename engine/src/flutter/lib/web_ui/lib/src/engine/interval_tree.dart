// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'noto_font.dart' show CodePointRange;

/// A tree which stores a set of intervals that can be queried for intersection.
class IntervalTree<T> {
  IntervalTree._(this.root);

  /// Creates an interval tree from a mapping of [T] values to a list of ranges.
  ///
  /// When the interval tree is queried, it will return a list of [T]s which
  /// have a range which contains the point.
  factory IntervalTree.createFromRanges(Map<T, List<CodePointRange>> rangesMap) {
    assert(rangesMap.isNotEmpty);
    // Get a list of all the ranges ordered by start index.
    final List<IntervalTreeNode<T>> intervals = <IntervalTreeNode<T>>[];
    rangesMap.forEach((T key, List<CodePointRange> rangeList) {
      for (final CodePointRange range in rangeList) {
        intervals.add(IntervalTreeNode<T>(key, range.start, range.end));
      }
    });
    assert(intervals.isNotEmpty);

    intervals
        .sort((IntervalTreeNode<T> a, IntervalTreeNode<T> b) => a.low - b.low);

    // Make a balanced binary search tree from the nodes sorted by low value.
    IntervalTreeNode<T>? makeBalancedTree(List<IntervalTreeNode<T>> nodes) {
      if (nodes.isEmpty) {
        return null;
      }
      if (nodes.length == 1) {
        return nodes.single;
      }
      final int mid = nodes.length ~/ 2;
      final IntervalTreeNode<T> root = nodes[mid];
      root.left = makeBalancedTree(nodes.sublist(0, mid));
      root.right = makeBalancedTree(nodes.sublist(mid + 1));
      return root;
    }

    // Given a node, computes the highest `high` point of all of the subnodes.
    //
    // As a side effect, this also computes the high point of all subnodes.
    void computeHigh(IntervalTreeNode<T> root) {
      if (root.left == null && root.right == null) {
        root.computedHigh = root.high;
      } else if (root.left == null) {
        computeHigh(root.right!);
        root.computedHigh = math.max(root.high, root.right!.computedHigh);
      } else if (root.right == null) {
        computeHigh(root.left!);
        root.computedHigh = math.max(root.high, root.left!.computedHigh);
      } else {
        computeHigh(root.right!);
        computeHigh(root.left!);
        root.computedHigh = math.max(
            root.high,
            math.max(
              root.left!.computedHigh,
              root.right!.computedHigh,
            ));
      }
    }

    final IntervalTreeNode<T> root = makeBalancedTree(intervals)!;
    computeHigh(root);

    return IntervalTree<T>._(root);
  }

  /// The root node of the interval tree.
  final IntervalTreeNode<T> root;

  /// Returns the list of objects which have been associated with intervals that
  /// intersect with [x].
  List<T> intersections(int x) {
    final List<T> results = <T>[];
    root.searchForPoint(x, results);
    return results;
  }

  /// Whether this tree contains at least one interval that includes [x].
  bool containsDeep(int x) {
    return root.containsDeep(x);
  }
}

class IntervalTreeNode<T> {
  IntervalTreeNode(this.value, this.low, this.high) : computedHigh = high;

  final T value;
  final int low;
  final int high;
  int computedHigh;

  IntervalTreeNode<T>? left;
  IntervalTreeNode<T>? right;

  Iterable<T> enumerateAllElements() {
    final Iterable<T> leftElements = left?.enumerateAllElements() ?? Iterable<T>.empty();
    final Iterable<T> rightElements = right?.enumerateAllElements() ?? Iterable<T>.empty();
    return leftElements.followedBy(<T>[value]).followedBy(rightElements);
  }

  /// Whether this node contains [x].
  ///
  /// Does not recursively check whether child nodes contain [x].
  bool containsShallow(int x) {
    return low <= x && x <= high;
  }

  /// Whether this sub-tree contains [x].
  ///
  /// Recursively checks whether child nodes contain [x].
  bool containsDeep(int x) {
    if (x > computedHigh) {
      // x is above the highest possible value stored in this subtree.
      // Don't bother checking intervals.
      return false;
    }
    if (containsShallow(x)) {
      return true;
    }
    if (left?.containsDeep(x) ?? false) {
      return true;
    }
    if (x < low) {
      // The right tree can't possible contain x. Don't bother checking.
      return false;
    }
    return right?.containsDeep(x) ?? false;
  }

  // Searches the tree rooted at this node for all T containing [x].
  void searchForPoint(int x, List<T> result) {
    if (x > computedHigh) {
      return;
    }
    left?.searchForPoint(x, result);
    if (containsShallow(x)) {
      result.add(value);
    }
    if (x < low) {
      return;
    }
    right?.searchForPoint(x, result);
  }
}
