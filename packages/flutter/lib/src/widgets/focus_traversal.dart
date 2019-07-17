// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'basic.dart';
import 'binding.dart';
import 'focus_manager.dart';
import 'framework.dart';

/// A direction along either the horizontal or vertical axes.
///
/// This is used by the [DirectionalFocusTraversalPolicyMixin] to indicate which
/// direction to traverse in.
enum TraversalDirection {
  /// Indicates a direction above the currently focused widget.
  up,

  /// Indicates a direction to the right of the currently focused widget.
  ///
  /// This direction is unaffected by the [Directionality] of the current
  /// context.
  right,

  /// Indicates a direction below the currently focused widget.
  down,

  /// Indicates a direction to the left of the currently focused widget.
  ///
  /// This direction is unaffected by the [Directionality] of the current
  /// context.
  left,

  // TODO(gspencer): Add diagonal traversal directions used by TV remotes and
  // game controllers when we support them.
}

/// An object used to specify a focus traversal policy used for configuring a
/// [DefaultFocusTraversal] widget.
///
/// The focus traversal policy is what determines which widget is "next",
/// "previous", or in a direction from the currently focused [FocusNode].
///
/// One of the pre-defined subclasses may be used, or define a custom policy to
/// create a unique focus order.
///
/// See also:
///
///   * [FocusNode], for a description of the focus system.
///   * [DefaultFocusTraversal], a widget that imposes a traversal policy on the
///     [Focus] nodes below it in the widget hierarchy.
///   * [FocusNode], which is affected by the traversal policy.
///   * [WidgetOrderFocusTraversalPolicy], a policy that relies on the widget
///     creation order to describe the order of traversal.
///   * [ReadingOrderTraversalPolicy], a policy that describes the order as the
///     natural "reading order" for the current [Directionality].
///   * [DirectionalFocusTraversalPolicyMixin] a mixin class that implements
///     focus traversal in a direction.
abstract class FocusTraversalPolicy {
  /// Returns the node that should receive focus if there is no current focus
  /// in the [FocusScopeNode] that [currentNode] belongs to.
  ///
  /// This is used by [next]/[previous]/[inDirection] to determine which node to
  /// focus if they are called, but no node is currently focused.
  ///
  /// It is also used by the [FocusManager] to know which node to focus
  /// initially if no nodes are focused.
  ///
  /// If the [direction] is null, then it should find the appropriate first node
  /// for next/previous, and if direction is non-null, should find the
  /// appropriate first node in that direction.
  ///
  /// The [currentNode] argument must not be null.
  FocusNode findFirstFocus(FocusNode currentNode);

  /// Returns the node in the given [direction] that should receive focus if
  /// there is no current focus in the scope to which the [currentNode] belongs.
  ///
  /// This is typically used by [inDirection] to determine which node to focus
  /// if it is called, but no node is currently focused.
  ///
  /// All arguments must not be null.
  FocusNode findFirstFocusInDirection(FocusNode currentNode, TraversalDirection direction);

  /// Clears the data associated with the given [FocusScopeNode] for this object.
  ///
  /// This is used to indicate that the focus policy has changed its mode, and
  /// so any cached policy data should be invalidated. For example, changing the
  /// direction in which focus is moving, or changing from directional to
  /// next/previous navigation modes.
  ///
  /// The default implementation does nothing.
  @mustCallSuper
  @protected
  void invalidateScopeData(FocusScopeNode node) {}

  /// This is called whenever the given [node] is reparented into a new scope,
  /// so that the policy has a chance to update or invalidate any cached data
  /// that it maintains per scope about the node.
  ///
  /// The [oldScope] is the previous scope that this node belonged to, if any.
  ///
  /// The default implementation does nothing.
  @mustCallSuper
  void changedScope({FocusNode node, FocusScopeNode oldScope}) {}

  /// Focuses the next widget in the focus scope that contains the given
  /// [currentNode].
  ///
  /// This should determine what the next node to receive focus should be by
  /// inspecting the node tree, and then calling [FocusNode.requestFocus] on
  /// the node that has been selected.
  ///
  /// Returns true if it successfully found a node and requested focus.
  ///
  /// The [currentNode] argument must not be null.
  bool next(FocusNode currentNode);

  /// Focuses the previous widget in the focus scope that contains the given
  /// [currentNode].
  ///
  /// This should determine what the previous node to receive focus should be by
  /// inspecting the node tree, and then calling [FocusNode.requestFocus] on
  /// the node that has been selected.
  ///
  /// Returns true if it successfully found a node and requested focus.
  ///
  /// The [currentNode] argument must not be null.
  bool previous(FocusNode currentNode);

  /// Focuses the next widget in the given [direction] in the focus scope that
  /// contains the given [currentNode].
  ///
  /// This should determine what the next node to receive focus in the given
  /// [direction] should be by inspecting the node tree, and then calling
  /// [FocusNode.requestFocus] on the node that has been selected.
  ///
  /// Returns true if it successfully found a node and requested focus.
  ///
  /// All arguments must not be null.
  bool inDirection(FocusNode currentNode, TraversalDirection direction);
}

/// A policy data object for use by the [DirectionalFocusTraversalPolicyMixin]
class _DirectionalPolicyDataEntry {
  const _DirectionalPolicyDataEntry({@required this.direction, @required this.node})
      : assert(direction != null),
        assert(node != null);

  final TraversalDirection direction;
  final FocusNode node;
}

class _DirectionalPolicyData {
  const _DirectionalPolicyData({@required this.history}) : assert(history != null);

  /// A queue of entries that describe the path taken to the current node.
  final List<_DirectionalPolicyDataEntry> history;
}

/// A mixin class that provides an implementation for finding a node in a
/// particular direction.
///
/// This can be mixed in to other [FocusTraversalPolicy] implementations that
/// only want to implement new next/previous policies.
///
/// Since hysteresis in the navigation order is undesirable, this implementation
/// maintains a stack of previous locations that have been visited on the
/// [policyData] for the affected [FocusScopeNode]. If the previous direction
/// was the opposite of the current direction, then the this policy will request
/// focus on the previously focused node. Change to another direction other than
/// the current one or its opposite will clear the stack.
///
/// For instance, if the focus moves down, down, down, and then up, up, up, it
/// will follow the same path through the widgets in both directions. However,
/// if it moves down, down, down, left, right, and then up, up, up, it may not
/// follow the same path on the way up as it did on the way down.
///
/// See also:
///
///   * [FocusNode], for a description of the focus system.
///   * [DefaultFocusTraversal], a widget that imposes a traversal policy on the
///     [Focus] nodes below it in the widget hierarchy.
///   * [WidgetOrderFocusTraversalPolicy], a policy that relies on the widget
///     creation order to describe the order of traversal.
///   * [ReadingOrderTraversalPolicy], a policy that describes the order as the
///     natural "reading order" for the current [Directionality].
mixin DirectionalFocusTraversalPolicyMixin on FocusTraversalPolicy {
  final Map<FocusScopeNode, _DirectionalPolicyData> _policyData = <FocusScopeNode, _DirectionalPolicyData>{};

  @override
  void invalidateScopeData(FocusScopeNode node) {
    super.invalidateScopeData(node);
    _policyData.remove(node);
  }

  @override
  void changedScope({FocusNode node, FocusScopeNode oldScope}) {
    super.changedScope(node: node, oldScope: oldScope);
    if (oldScope != null) {
      _policyData[oldScope]?.history?.removeWhere((_DirectionalPolicyDataEntry entry) {
        return entry.node == node;
      });
    }
  }

  @override
  FocusNode findFirstFocusInDirection(FocusNode currentNode, TraversalDirection direction) {
    assert(direction != null);
    assert(currentNode != null);
    switch (direction) {
      case TraversalDirection.up:
        // Find the bottom-most node so we can go up from there.
        return _sortAndFindInitial(currentNode, vertical: true, first: false);
      case TraversalDirection.down:
        // Find the top-most node so we can go down from there.
        return _sortAndFindInitial(currentNode, vertical: true, first: true);
      case TraversalDirection.left:
        // Find the right-most node so we can go left from there.
        return _sortAndFindInitial(currentNode, vertical: false, first: false);
      case TraversalDirection.right:
        // Find the left-most node so we can go right from there.
        return _sortAndFindInitial(currentNode, vertical: false, first: true);
    }
    return null;
  }

  FocusNode _sortAndFindInitial(FocusNode currentNode, { bool vertical, bool first }) {
    final Iterable<FocusNode> nodes = currentNode.nearestScope.traversalDescendants;
    final List<FocusNode> sorted = nodes.toList();
    sorted.sort((FocusNode a, FocusNode b) {
      if (vertical) {
        if (first) {
          return a.rect.top.compareTo(b.rect.top);
        } else {
          return b.rect.bottom.compareTo(a.rect.bottom);
        }
      } else {
        if (first) {
          return a.rect.left.compareTo(b.rect.left);
        } else {
          return b.rect.right.compareTo(a.rect.right);
        }
      }
    });
    return sorted.first;
  }

  // Sorts nodes from left to right horizontally, and removes nodes that are
  // either to the right of the left side of the target node if we're going
  // left, or to the left of the right side of the target node if we're going
  // right.
  //
  // This doesn't need to take into account directionality because it is
  // typically intending to actually go left or right, not in a reading
  // direction.
  Iterable<FocusNode> _sortAndFilterHorizontally(
    TraversalDirection direction,
    Rect target,
    FocusNode nearestScope,
  ) {
    assert(direction == TraversalDirection.left || direction == TraversalDirection.right);
    final Iterable<FocusNode> nodes = nearestScope.traversalDescendants;
    assert(!nodes.contains(nearestScope));
    final List<FocusNode> sorted = nodes.toList();
    sorted.sort((FocusNode a, FocusNode b) => a.rect.center.dx.compareTo(b.rect.center.dx));
    Iterable<FocusNode> result;
    switch (direction) {
      case TraversalDirection.left:
        result = sorted.where((FocusNode node) => node.rect != target && node.rect.center.dx <= target.left);
        break;
      case TraversalDirection.right:
        result = sorted.where((FocusNode node) => node.rect != target && node.rect.center.dx >= target.right);
        break;
      case TraversalDirection.up:
      case TraversalDirection.down:
        break;
    }
    return result;
  }

  // Sorts nodes from top to bottom vertically, and removes nodes that are
  // either below the top of the target node if we're going up, or above the
  // bottom of the target node if we're going down.
  Iterable<FocusNode> _sortAndFilterVertically(
    TraversalDirection direction,
    Rect target,
    Iterable<FocusNode> nodes,
  ) {
    final List<FocusNode> sorted = nodes.toList();
    sorted.sort((FocusNode a, FocusNode b) => a.rect.center.dy.compareTo(b.rect.center.dy));
    switch (direction) {
      case TraversalDirection.up:
        return sorted.where((FocusNode node) => node.rect != target && node.rect.center.dy <= target.top);
      case TraversalDirection.down:
        return sorted.where((FocusNode node) => node.rect != target && node.rect.center.dy >= target.bottom);
      case TraversalDirection.left:
      case TraversalDirection.right:
        break;
    }
    assert(direction == TraversalDirection.up || direction == TraversalDirection.down);
    return null;
  }

  // Updates the policy data to keep the previously visited node so that we can
  // avoid hysteresis when we change directions in navigation.
  //
  // Returns true if focus was requested on a previous node.
  bool _popPolicyDataIfNeeded(TraversalDirection direction, FocusScopeNode nearestScope, FocusNode focusedChild) {
    final _DirectionalPolicyData policyData = _policyData[nearestScope];
    if (policyData != null && policyData.history.isNotEmpty && policyData.history.first.direction != direction) {
      if (policyData.history.last.node.parent == null) {
        // If a node has been removed from the tree, then we should stop
        // referencing it and reset the scope data so that we don't try and
        // request focus on it. This can happen in slivers where the rendered node
        // has been unmounted. This has the side effect that hysteresis might not
        // be avoided when items that go off screen get unmounted.
        invalidateScopeData(nearestScope);
        return false;
      }
      switch (direction) {
        case TraversalDirection.down:
        case TraversalDirection.up:
          switch (policyData.history.first.direction) {
            case TraversalDirection.left:
            case TraversalDirection.right:
              // Reset the policy data if we change directions.
              invalidateScopeData(nearestScope);
              break;
            case TraversalDirection.up:
            case TraversalDirection.down:
              policyData.history.removeLast().node.requestFocus();
              return true;
          }
          break;
        case TraversalDirection.left:
        case TraversalDirection.right:
          switch (policyData.history.first.direction) {
            case TraversalDirection.left:
            case TraversalDirection.right:
              policyData.history.removeLast().node.requestFocus();
              return true;
            case TraversalDirection.up:
            case TraversalDirection.down:
              // Reset the policy data if we change directions.
              invalidateScopeData(nearestScope);
              break;
          }
      }
    }
    if (policyData != null && policyData.history.isEmpty) {
      // Reset the policy data if we change directions.
      invalidateScopeData(nearestScope);
    }
    return false;
  }

  void _pushPolicyData(TraversalDirection direction, FocusScopeNode nearestScope, FocusNode focusedChild) {
    final _DirectionalPolicyData policyData = _policyData[nearestScope];
    if (policyData != null && policyData is! _DirectionalPolicyData) {
      return;
    }
    final _DirectionalPolicyDataEntry newEntry = _DirectionalPolicyDataEntry(node: focusedChild, direction: direction);
    if (policyData != null) {
      policyData.history.add(newEntry);
    } else {
      _policyData[nearestScope] = _DirectionalPolicyData(history: <_DirectionalPolicyDataEntry>[newEntry]);
    }
  }

  /// Focuses the next widget in the given [direction] in the [FocusScope] that
  /// contains the [currentNode].
  ///
  /// This determines what the next node to receive focus in the given
  /// [direction] will be by inspecting the node tree, and then calling
  /// [FocusNode.requestFocus] on it.
  ///
  /// Returns true if it successfully found a node and requested focus.
  ///
  /// Maintains a stack of previous locations that have been visited on the
  /// [policyData] for the affected [FocusScopeNode]. If the previous direction
  /// was the opposite of the current direction, then the this policy will
  /// request focus on the previously focused node. Change to another direction
  /// other than the current one or its opposite will clear the stack.
  ///
  /// If this function returns true when called by a subclass, then the subclass
  /// should return true and not request focus from any node.
  @mustCallSuper
  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    final FocusScopeNode nearestScope = currentNode.nearestScope;
    final FocusNode focusedChild = nearestScope.focusedChild;
    if (focusedChild == null) {
      final FocusNode firstFocus = findFirstFocusInDirection(currentNode, direction);
      (firstFocus ?? currentNode).requestFocus();
      return true;
    }
    if (_popPolicyDataIfNeeded(direction, nearestScope, focusedChild)) {
      return true;
    }
    FocusNode found;
    switch (direction) {
      case TraversalDirection.down:
      case TraversalDirection.up:
        final Iterable<FocusNode> eligibleNodes = _sortAndFilterVertically(
          direction,
          focusedChild.rect,
          nearestScope.traversalDescendants,
        );
        if (eligibleNodes.isEmpty) {
          break;
        }
        List<FocusNode> sorted = eligibleNodes.toList();
        if (direction == TraversalDirection.up) {
          sorted = sorted.reversed.toList();
        }
        // Find any nodes that intersect the band of the focused child.
        final Rect band = Rect.fromLTRB(focusedChild.rect.left, -double.infinity, focusedChild.rect.right, double.infinity);
        final Iterable<FocusNode> inBand = sorted.where((FocusNode node) => !node.rect.intersect(band).isEmpty);
        if (inBand.isNotEmpty) {
          // The inBand list is already sorted by horizontal distance, so pick the closest one.
          found = inBand.first;
          break;
        }
        // Only out-of-band targets remain, so pick the one that is closest the to the center line horizontally.
        sorted.sort((FocusNode a, FocusNode b) {
          return (a.rect.center.dx - focusedChild.rect.center.dx).abs().compareTo((b.rect.center.dx - focusedChild.rect.center.dx).abs());
        });
        found = sorted.first;
        break;
      case TraversalDirection.right:
      case TraversalDirection.left:
        final Iterable<FocusNode> eligibleNodes = _sortAndFilterHorizontally(direction, focusedChild.rect, nearestScope);
        if (eligibleNodes.isEmpty) {
          break;
        }
        List<FocusNode> sorted = eligibleNodes.toList();
        if (direction == TraversalDirection.left) {
          sorted = sorted.reversed.toList();
        }
        // Find any nodes that intersect the band of the focused child.
        final Rect band = Rect.fromLTRB(-double.infinity, focusedChild.rect.top, double.infinity, focusedChild.rect.bottom);
        final Iterable<FocusNode> inBand = sorted.where((FocusNode node) => !node.rect.intersect(band).isEmpty);
        if (inBand.isNotEmpty) {
          // The inBand list is already sorted by vertical distance, so pick the closest one.
          found = inBand.first;
          break;
        }
        // Only out-of-band targets remain, so pick the one that is closest the to the center line vertically.
        sorted.sort((FocusNode a, FocusNode b) {
          return (a.rect.center.dy - focusedChild.rect.center.dy).abs().compareTo((b.rect.center.dy - focusedChild.rect.center.dy).abs());
        });
        found = sorted.first;
        break;
    }
    if (found != null) {
      _pushPolicyData(direction, nearestScope, focusedChild);
      found.requestFocus();
      return true;
    }
    return false;
  }
}

/// A [FocusTraversalPolicy] that traverses the focus order in widget hierarchy
/// order.
///
/// This policy is used when the order desired is the order in which widgets are
/// created in the widget hierarchy.
///
/// See also:
///
///   * [FocusNode], for a description of the focus system.
///   * [DefaultFocusTraversal], a widget that imposes a traversal policy on the
///     [Focus] nodes below it in the widget hierarchy.
///   * [ReadingOrderTraversalPolicy], a policy that describes the order as the
///     natural "reading order" for the current [Directionality].
///   * [DirectionalFocusTraversalPolicyMixin] a mixin class that implements
///     focus traversal in a direction.
class WidgetOrderFocusTraversalPolicy extends FocusTraversalPolicy with DirectionalFocusTraversalPolicyMixin {
  /// Creates a const [WidgetOrderFocusTraversalPolicy].
  WidgetOrderFocusTraversalPolicy();

  @override
  FocusNode findFirstFocus(FocusNode currentNode) {
    assert(currentNode != null);
    final FocusScopeNode scope = currentNode.nearestScope;
    // Start with the candidate focus as the focused child of this scope, if
    // there is one. Otherwise start with this node itself. Keep going down
    // through scopes until an ultimately focusable item is found, a scope
    // doesn't have a focusedChild, or a non-scope is encountered.
    FocusNode candidate = scope.focusedChild;
    if (candidate == null) {
      if (scope.traversalChildren.isNotEmpty) {
        candidate = scope.traversalChildren.first;
      } else {
        candidate = currentNode;
      }
    }
    while (candidate is FocusScopeNode && candidate.focusedChild != null) {
      final FocusScopeNode candidateScope = candidate;
      candidate = candidateScope.focusedChild;
    }
    return candidate;
  }

  // Moves the focus to the next or previous node, depending on whether forward
  // is true or not.
  bool _move(FocusNode currentNode, {@required bool forward}) {
    if (currentNode == null) {
      return false;
    }
    final FocusScopeNode nearestScope = currentNode.nearestScope;
    invalidateScopeData(nearestScope);
    final FocusNode focusedChild = nearestScope.focusedChild;
    if (focusedChild == null) {
      final FocusNode firstFocus = findFirstFocus(currentNode);
      if (firstFocus != null) {
        firstFocus.requestFocus();
        return true;
      }
    }
    FocusNode previousNode;
    FocusNode firstNode;
    FocusNode lastNode;
    bool visit(FocusNode node) {
      for (FocusNode visited in node.traversalChildren) {
        firstNode ??= visited;
        if (!visit(visited)) {
          return false;
        }
        if (forward) {
          if (previousNode == focusedChild) {
            visited.requestFocus();
            return false; // short circuit the traversal.
          }
        } else {
          if (previousNode != null && visited == focusedChild) {
            previousNode.requestFocus();
            return false; // short circuit the traversal.
          }
        }
        previousNode = visited;
        lastNode = visited;
      }
      return true; // continue traversal
    }

    if (visit(nearestScope)) {
      if (forward) {
        if (firstNode != null) {
          firstNode.requestFocus();
          return true;
        }
      } else {
        if (lastNode != null) {
          lastNode.requestFocus();
          return true;
        }
      }
      return false;
    }
    return true;
  }

  @override
  bool next(FocusNode currentNode) => _move(currentNode, forward: true);

  @override
  bool previous(FocusNode currentNode) => _move(currentNode, forward: false);
}

class _SortData {
  _SortData(this.node) : rect = node.rect;

  final Rect rect;
  final FocusNode node;
}

/// Traverses the focus order in "reading order".
///
/// By default, reading order traversal goes in the reading direction, and then
/// down, using this algorithm:
///
/// 1. Find the node rectangle that has the highest `top` on the screen.
/// 2. Find any other nodes that intersect the infinite horizontal band defined
///    by the highest rectangle's top and bottom edges.
/// 3. Pick the closest to the beginning of the reading order from among the
///    nodes discovered above.
///
/// It uses the ambient directionality in the context for the enclosing scope to
/// determine which direction is "reading order".
///
/// See also:
///
///   * [FocusNode], for a description of the focus system.
///   * [DefaultFocusTraversal], a widget that imposes a traversal policy on the
///     [Focus] nodes below it in the widget hierarchy.
///   * [WidgetOrderFocusTraversalPolicy], a policy that relies on the widget
///     creation order to describe the order of traversal.
///   * [DirectionalFocusTraversalPolicyMixin] a mixin class that implements
///     focus traversal in a direction.
class ReadingOrderTraversalPolicy extends FocusTraversalPolicy with DirectionalFocusTraversalPolicyMixin {
  @override
  FocusNode findFirstFocus(FocusNode currentNode) {
    assert(currentNode != null);
    final FocusScopeNode scope = currentNode.nearestScope;
    FocusNode candidate = scope.focusedChild;
    if (candidate == null && scope.traversalChildren.isNotEmpty) {
      candidate = _sortByGeometry(scope).first;
    }

    // If we still didn't find any candidate, use the current node as a
    // fallback.
    candidate ??= currentNode;
    candidate ??= WidgetsBinding.instance.focusManager.rootScope;
    return candidate;
  }

  // Sorts the list of nodes based on their geometry into the desired reading
  // order based on the directionality of the context for each node.
  Iterable<FocusNode> _sortByGeometry(FocusScopeNode scope) {
    final Iterable<FocusNode> nodes = scope.traversalDescendants;
    if (nodes.length <= 1) {
      return nodes;
    }

    Iterable<_SortData> inBand(_SortData current, Iterable<_SortData> candidates) {
      final Rect wide = Rect.fromLTRB(double.negativeInfinity, current.rect.top, double.infinity, current.rect.bottom);
      return candidates.where((_SortData item) {
        return !item.rect.intersect(wide).isEmpty;
      });
    }

    final TextDirection textDirection = scope.context == null ? TextDirection.ltr : Directionality.of(scope.context);
    _SortData pickFirst(List<_SortData> candidates) {
      int compareBeginningSide(_SortData a, _SortData b) {
        return textDirection == TextDirection.ltr ? a.rect.left.compareTo(b.rect.left) : -a.rect.right.compareTo(b.rect.right);
      }

      int compareTopSide(_SortData a, _SortData b) {
        return a.rect.top.compareTo(b.rect.top);
      }

      // Get the topmost
      candidates.sort(compareTopSide);
      final _SortData topmost = candidates.first;
      // If there are any others in the band of the topmost, then pick the
      // leftmost one.
      final List<_SortData> inBandOfTop = inBand(topmost, candidates).toList();
      inBandOfTop.sort(compareBeginningSide);
      if (inBandOfTop.isNotEmpty) {
        return inBandOfTop.first;
      }
      return topmost;
    }

    final List<_SortData> data = <_SortData>[];
    for (FocusNode node in nodes) {
      data.add(_SortData(node));
    }

    // Pick the initial widget as the one that is leftmost in the band of the
    // topmost, or the topmost, if there are no others in its band.
    final List<_SortData> sortedList = <_SortData>[];
    final List<_SortData> unplaced = data.toList();
    _SortData current = pickFirst(unplaced);
    sortedList.add(current);
    unplaced.remove(current);

    while (unplaced.isNotEmpty) {
      final _SortData next = pickFirst(unplaced);
      current = next;
      sortedList.add(current);
      unplaced.remove(current);
    }
    return sortedList.map((_SortData item) => item.node);
  }

  // Moves the focus forward or backward in reading order, depending on the
  // value of the forward argument.
  bool _move(FocusNode currentNode, {@required bool forward}) {
    final FocusScopeNode nearestScope = currentNode.nearestScope;
    invalidateScopeData(nearestScope);
    final FocusNode focusedChild = nearestScope.focusedChild;
    if (focusedChild == null) {
      final FocusNode firstFocus = findFirstFocus(currentNode);
      if (firstFocus != null) {
        firstFocus.requestFocus();
        return true;
      }
    }
    final List<FocusNode> sortedNodes = _sortByGeometry(nearestScope).toList();
    if (forward && focusedChild == sortedNodes.last) {
      sortedNodes.first.requestFocus();
      return true;
    }
    if (!forward && focusedChild == sortedNodes.first) {
      sortedNodes.last.requestFocus();
      return true;
    }

    final Iterable<FocusNode> maybeFlipped = forward ? sortedNodes : sortedNodes.reversed;
    FocusNode previousNode;
    for (FocusNode node in maybeFlipped) {
      if (previousNode == focusedChild) {
        node.requestFocus();
        return true;
      }
      previousNode = node;
    }
    return false;
  }

  @override
  bool next(FocusNode currentNode) => _move(currentNode, forward: true);

  @override
  bool previous(FocusNode currentNode) => _move(currentNode, forward: false);
}

/// A widget that describes the inherited focus policy for focus traversal.
///
/// By default, traverses in widget order using
/// [ReadingOrderFocusTraversalPolicy].
///
/// See also:
///
///   * [FocusNode], for a description of the focus system.
///   * [WidgetOrderFocusTraversalPolicy], a policy that relies on the widget
///     creation order to describe the order of traversal.
///   * [ReadingOrderTraversalPolicy], a policy that describes the order as the
///     natural "reading order" for the current [Directionality].
///   * [DirectionalFocusTraversalPolicyMixin] a mixin class that implements
///     focus traversal in a direction.
class DefaultFocusTraversal extends InheritedWidget {
  /// Creates a [DefaultFocusTraversal] object.
  ///
  /// The [child] argument must not be null.
  const DefaultFocusTraversal({
    Key key,
    this.policy,
    @required Widget child,
  }) : super(key: key, child: child);

  /// The policy used to move the focus from one focus node to another.
  ///
  /// If not specified, traverses in reading order using
  /// [ReadingOrderTraversalPolicy].
  ///
  /// See also:
  ///
  ///  * [FocusTraversalPolicy] for the API used to impose traversal order
  ///    policy.
  ///  * [WidgetOrderFocusTraversalPolicy] for a traversal policy that traverses
  ///    nodes in the order they are added to the widget tree.
  ///  * [ReadingOrderTraversalPolicy] for a traversal policy that traverses
  ///    nodes in the reading order defined in the widget tree, and then top to
  ///    bottom.
  final FocusTraversalPolicy policy;

  /// Returns the [FocusTraversalPolicy] that most tightly encloses the given
  /// [BuildContext].
  ///
  /// The [context] argument must not be null.
  static FocusTraversalPolicy of(BuildContext context, { bool nullOk = false }) {
    assert(context != null);
    final DefaultFocusTraversal inherited = context.inheritFromWidgetOfExactType(DefaultFocusTraversal);
    assert(() {
      if (nullOk) {
        return true;
      }
      if (inherited == null) {
        throw FlutterError('Unable to find a DefaultFocusTraversal widget in the context.\n'
            'DefaultFocusTraversal.of() was called with a context that does not contain a '
            'DefaultFocusTraversal.\n'
            'No DefaultFocusTraversal ancestor could be found starting from the context that was '
            'passed to DefaultFocusTraversal.of(). This can happen because there is not a '
            'WidgetsApp or MaterialApp widget (those widgets introduce a DefaultFocusTraversal), '
            'or it can happen if the context comes from a widget above those widgets.\n'
            'The context used was:\n'
            '  $context');
      }
      return true;
    }());
    return inherited?.policy ?? ReadingOrderTraversalPolicy();
  }

  @override
  bool updateShouldNotify(DefaultFocusTraversal oldWidget) => policy != oldWidget.policy;
}
