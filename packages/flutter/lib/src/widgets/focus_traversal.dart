// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'basic.dart';
import 'focusable_manager.dart';
import 'framework.dart';

/// Object for specifying a focus traversal policy used for configuring a
/// [DefaultFocusTraversal] widget.
///
/// See also:
///
///   * [DefaultFocusTraversal], a widget that imposes a traversal policy on the
///     [Focusable] nodes below it in the widget hierarchy.
///   * [FocusableNode], which uses the policy, and whose order is affected by
///     the policy.
///   * [WidgetOrderFocusTraversalPolicy], a policy that relies on the widget
///     creation order to describe the order of traversal.
///   * [ReadingOrderTraversalPolicy], a policy that implements an order that is
///     the natural "reading order" for the current [Directionality].
///   * [DirectionalFocusTraversalPolicyMixin] a mixin class that implements
///     focus traversal in an axis direction.
abstract class FocusTraversalPolicy {
  /// Creates a FocusTraversalPolicy.
  const FocusTraversalPolicy();

  /// Returns the node which should receive focus if there is no current focus
  /// in the scope to which the [currentNode] belongs.
  ///
  /// This is used by [next]/[previous] to determine which node to focus if they
  /// are called, but no node is currently focused.
  ///
  /// Typically, it should take into account the [FocusableNode.isAutoFocus]
  /// setting, but can ignore it if that is the desired behavior. Nothing else
  /// looks at the [autofocus] setting.
  ///
  /// The default implementation returns the autofocus node in the scope
  /// containing the node, or the node itself if nothing is set to autofocus.
  ///
  /// If more than one node in the scope of [currentNode] has autofocus set,
  /// will assert.
  FocusableNode findFirstFocus(FocusableNode currentNode) {
    // Make sure there's only one autofocus child for the scope this node
    // belongs to.
    debugCheckUniqueAutofocusNode(currentNode);
    final FocusableScopeNode scope = currentNode.nearestScope;
    assert(scope.focusedChild == null, 'There already is a focused node in $scope');
    final FocusableNode autofocus = scope.descendants.firstWhere(
          (FocusableNode node) => node.nearestScope == scope && node.autofocus,
      orElse: () => null,
    );
    return autofocus ?? currentNode;
  }

  /// A debug method to find the autofocus nodes in the nodes in the same scope
  /// as the given [node], and if there exists more than one, assert.
  ///
  /// Does not descend into scope nodes, because they could have their own
  /// separate autofocus node.
  @protected
  void debugCheckUniqueAutofocusNode(FocusableNode node) {
    assert(() {
      final FocusableNode nearestScope = node.nearestScope;
      final List<FocusableNode> autofocusNodes = nearestScope.descendants.where((FocusableNode descendant) {
        return descendant.nearestScope == nearestScope && descendant.autofocus;
      });
      return autofocusNodes.length <= 1;
    }(), 'More than one autofocus node was found in the descendants of scope ${node.nearestScope}, which is not allowed.');
  }

  /// Focuses the next widget in the focus scope that contains the given
  /// [currentNode].
  ///
  /// This should determine what the next node to receive focus should be by
  /// inspecting the node tree, and then call [FocusableNode.requestFocus] on
  /// it.
  ///
  /// Returns true if it successfully found a node and requested focus.
  bool next(FocusableNode currentNode);

  /// Focuses the previous widget in the focus scope that contains the given
  /// [currentNode].
  ///
  /// This should determine what the previous node to receive focus should be by
  /// inspecting the node tree, and then call [FocusableNode.requestFocus] on
  /// it.
  ///
  /// Returns true if it successfully found a node and requested focus.
  bool previous(FocusableNode currentNode);

  /// Focuses the next widget in the given [direction] in the focus scope that
  /// contains the given [currentNode].
  ///
  /// This should determine what the next node to receive focus in the given
  /// [direction] should be by inspecting the node tree, and then call
  /// [FocusableNode.requestFocus] on it.
  ///
  /// Returns true if it successfully found a node and requested focus.
  ///
  /// If the previous direction was the opposite of the current direction, then
  /// the default implementation will request focus on the previously focused
  /// node, because hysteresis in the navigation order is undesirable.
  ///
  /// If this function returns true when called by the subclass, then the
  /// subclass should immediately return true and not request focus from any
  /// other node.
  bool inDirection(FocusableNode currentNode, TraversalDirection direction);
}

/// A policy data object for use by the [DirectionalFocusTraversalPolicyMixin]
class _DirectionalPolicyDataEntry {
  const _DirectionalPolicyDataEntry({@required this.previousDirection, @required this.previousNode})
      : assert(previousDirection != null),
        assert(previousNode != null);

  final TraversalDirection previousDirection;
  final FocusableNode previousNode;
}

class _DirectionalPolicyData {
  const _DirectionalPolicyData({@required this.history}) : assert(history != null);

  /// A queue of entries that describe the path taken to the current node.
  final List<_DirectionalPolicyDataEntry> history;
}

/// A direction along either the horizontal or vertical axes.
/// 
/// This is used by the [DirectionalFocusTraversalPolicyMixin] to indicate which
/// direction to traverse in.
enum TraversalDirection {
  /// Indicates a direction above the currently focused widget.
  ///
  /// Zero is at the bottom and positive values are above it: ⇈
  up,

  /// Indicates a direction to the right of the currently focused widget.
  ///
  /// This direction is unaffected by the [Directionality] of the current
  /// context.
  ///
  /// Zero is on the left and positive values are to the right of it: ⇉
  right,

  /// Indicates a direction below the currently focused widget.
  ///
  /// Zero is at the top and positive values are below it: ⇊
  down,

  /// Indicates a direction to the left of the currently focused widget.
  ///
  /// This direction is unaffected by the [Directionality] of the current
  /// context.
  ///
  /// Zero is to the right and positive values are to the left of it: ⇇
  left,

  // TODO(gspencer): Add diagonal traversal directions.
}

/// A mixin class that provides an implementation for finding a node in a
/// particular direction.
///
/// This can be mixed in to other [FocusTraversalPolicy] implementations that
/// only want to implement new next/previous policies.
///
/// See also:
///
///   * [TraversalDirection], the enum that describes the various directions
///     that traversal can move in.
///   * [Focusable], a widget that manages a [FocusableNode].
///   * [DefaultFocusTraversal], a widget that imposes a traversal policy on the
///     [Focusable] nodes below it in the widget hierarchy.
///   * [FocusableNode], which is affected by the traversal policy.
///   * [FocusableScopeNode], which represents a group of focusable nodes.
///   * [FocusableScope], a widget that manages a [FocusaleScopeNode].
mixin DirectionalFocusTraversalPolicyMixin on FocusTraversalPolicy {
  // Sorts nodes from left to right horizontally, and removes nodes that are
  // either to the right of the left side of the target node if we're going
  // left, or to the left of the right side of the target node if we're going
  // right.
  //
  // This doesn't need to take into account directionality because it is
  // typically the result of an actual left or right arrow press.
  Iterable<FocusableNode> _sortAndFilterHorizontally(
      TraversalDirection direction,
      Rect target,
      FocusableNode nearestScope,
      ) {
    assert(direction == TraversalDirection.left || direction == TraversalDirection.right);
    final Iterable<FocusableNode> nodes = nearestScope.descendants;
    assert(!nodes.contains(nearestScope));
    final List<FocusableNode> sorted = nodes.toList();
    sorted.sort((FocusableNode a, FocusableNode b) => a.rect.center.dx.compareTo(b.rect.center.dx));
    Iterable<FocusableNode> result;
    switch (direction) {
      case TraversalDirection.left:
        result = sorted.where((FocusableNode node) => node.rect != target && node.rect.center.dx <= target.left);
        break;
      case TraversalDirection.right:
        result = sorted.where((FocusableNode node) => node.rect != target && node.rect.center.dx >= target.right);
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
  Iterable<FocusableNode> _sortAndFilterVertically(
      TraversalDirection direction,
      Rect target,
      Iterable<FocusableNode> nodes,
      ) {
    final List<FocusableNode> sorted = nodes.toList();
    sorted.sort((FocusableNode a, FocusableNode b) => a.rect.center.dy.compareTo(b.rect.center.dy));
    switch (direction) {
      case TraversalDirection.up:
        return sorted.where((FocusableNode node) => node.rect != target && node.rect.center.dy <= target.top);
      case TraversalDirection.down:
        return sorted.where((FocusableNode node) => node.rect != target && node.rect.center.dy >= target.bottom);
      case TraversalDirection.left:
      case TraversalDirection.right:
        break;
    }
    assert(direction == TraversalDirection.up || direction == TraversalDirection.down);
    return null;
  }

  /// Updates the policy data to keep the previously visited node so that we can
  /// avoid hysteresis when we change directions in navigation.
  ///
  /// Returns true if focus was requested on a previous node.
  bool _popPolicyDataIfNeeded(TraversalDirection direction, FocusableScopeNode nearestScope, FocusableNode focusedChild) {
    _DirectionalPolicyData policyData;
    print('Looking for policy data: ${nearestScope.policyData}');
    if (nearestScope.policyData != null && nearestScope.policyData is _DirectionalPolicyData) {
      policyData = nearestScope.policyData;
    } else {
      print('Found none.');
      return false;
    }
    print('Found Policy Data: $policyData');
    if (policyData != null && policyData.history.isNotEmpty && policyData.history.first.previousDirection != direction) {
      switch (direction) {
        case TraversalDirection.down:
        case TraversalDirection.up:
          switch (policyData.history.first.previousDirection) {
            case TraversalDirection.left:
            case TraversalDirection.right:
            // Reset the policy data if we change directions.
              nearestScope.policyData = null;
              break;
            case TraversalDirection.up:
            case TraversalDirection.down:
              policyData.history.removeLast().previousNode.requestFocusFromPolicy();
              return true;
          }
          break;
        case TraversalDirection.left:
        case TraversalDirection.right:
          switch (policyData.history.first.previousDirection) {
            case TraversalDirection.left:
            case TraversalDirection.right:
              policyData.history.removeLast().previousNode.requestFocusFromPolicy();
              return true;
            case TraversalDirection.up:
            case TraversalDirection.down:
            // Reset the policy data if we change directions.
              nearestScope.policyData = null;
              break;
          }
      }
    }
    if (policyData != null && policyData.history.isEmpty) {
      nearestScope.policyData = null;
    }
    return false;
  }

  void _pushPolicyData(TraversalDirection direction, FocusableScopeNode nearestScope, FocusableNode focusedChild) {
    final _DirectionalPolicyData policyData = nearestScope.policyData;
    if (policyData != null && policyData is! _DirectionalPolicyData) {
      return;
    }
    final _DirectionalPolicyDataEntry newEntry = _DirectionalPolicyDataEntry(previousNode: focusedChild, previousDirection: direction);
    if (policyData != null) {
      policyData.history.add(newEntry);
    } else {
      nearestScope.policyData = _DirectionalPolicyData(history: <_DirectionalPolicyDataEntry>[newEntry]);
    }
  }

  /// Focuses the next widget in the given [direction] in the focus scope that
  /// contains the given [currentNode].
  ///
  /// This should determine what the next node to receive focus in the given
  /// [direction] should be by inspecting the node tree, and then call
  /// [FocusableNode.requestFocus] on it.
  ///
  /// Returns true if it successfully found a node and requested focus.
  ///
  /// If the previous direction was the opposite of the current direction, then
  /// the default implementation will request focus on the previously focused
  /// node, because hysteresis in the navigation order is undesirable.
  ///
  /// If this function returns true when called by a subclass, then the subclass
  /// should return true and not request focus from any other node.
  @mustCallSuper
  @override
  bool inDirection(FocusableNode currentNode, TraversalDirection direction) {
    final FocusableScopeNode nearestScope = currentNode.nearestScope;
    final FocusableNode focusedChild = nearestScope.focusedChild;
    if (focusedChild == null) {
      currentNode.requestFocusFromPolicy();
      return true;
    }
    if (_popPolicyDataIfNeeded(direction, nearestScope, focusedChild)) {
      return true;
    }
    FocusableNode found;
    switch (direction) {
      case TraversalDirection.down:
      case TraversalDirection.up:
        final Iterable<FocusableNode> eligibleNodes = _sortAndFilterVertically(
          direction,
          focusedChild.rect,
          nearestScope.descendants,
        );
        if (eligibleNodes.isEmpty) {
          break;
        }
        List<FocusableNode> sorted = eligibleNodes.toList();
        if (direction == TraversalDirection.up) {
          sorted = sorted.reversed.toList();
        }
        // Find any nodes that intersect the band of the focused child.
        final Rect band = Rect.fromLTRB(focusedChild.rect.left, -double.infinity, focusedChild.rect.right, double.infinity);
        final Iterable<FocusableNode> inBand = sorted.where((FocusableNode node) => !node.rect.intersect(band).isEmpty);
        if (inBand.isNotEmpty) {
          // The inBand list is already sorted by horizontal distance, so pick the closest one.
          found = inBand.first;
          break;
        }
        // Only out-of-band targets remain, so pick the one that is closest the to the center line horizontally.
        sorted.sort((FocusableNode a, FocusableNode b) {
          return (a.rect.center.dx - focusedChild.rect.center.dx).abs().compareTo((b.rect.center.dx - focusedChild.rect.center.dx).abs());
        });
        found = sorted.first;
        break;
      case TraversalDirection.right:
      case TraversalDirection.left:
        final Iterable<FocusableNode> eligibleNodes = _sortAndFilterHorizontally(direction, focusedChild.rect, nearestScope);
        if (eligibleNodes.isEmpty) {
          break;
        }
        List<FocusableNode> sorted = eligibleNodes.toList();
        if (direction == TraversalDirection.left) {
          sorted = sorted.reversed.toList();
        }
        // Find any nodes that intersect the band of the focused child.
        final Rect band = Rect.fromLTRB(-double.infinity, focusedChild.rect.top, double.infinity, focusedChild.rect.bottom);
        final Iterable<FocusableNode> inBand = sorted.where((FocusableNode node) => !node.rect.intersect(band).isEmpty);
        if (inBand.isNotEmpty) {
          // The inBand list is already sorted by horizontal distance, so pick the closest one.
          found = inBand.first;
          break;
        }
        // Only out-of-band targets remain, so pick the one that is closest the to the center line vertically.
        sorted.sort((FocusableNode a, FocusableNode b) {
          return (a.rect.center.dy - focusedChild.rect.center.dy).abs().compareTo((b.rect.center.dy - focusedChild.rect.center.dy).abs());
        });
        found = sorted.first;
        break;
    }
    if (found != null) {
      _pushPolicyData(direction, nearestScope, focusedChild);
      found.requestFocusFromPolicy();
      return true;
    }
    return false;
  }
}

/// A [FocusTraversalPolicy] that traverses the focus order in widget hierarchy
/// order.
///
/// This policy is used when the order desired is the order in which widgets are
/// created in the widget hierarchy. This is most often the case for things like
/// lists, columns, and rows.
///
/// See also:
///
///   * [Focusable], a widget that manages a [FocusableNode].
///   * [DefaultFocusTraversal], a widget that imposes a traversal policy on the
///     [Focusable] nodes below it in the widget hierarchy.
///   * [FocusableNode], which is affected by the traversal policy.
///   * [FocusableScopeNode], which represents a group of focusable nodes.
///   * [FocusableScope], a widget that manages a [FocusaleScopeNode].
class WidgetOrderFocusTraversalPolicy extends FocusTraversalPolicy with DirectionalFocusTraversalPolicyMixin {
  /// Creates a const [WidgetOrderFocusTraversalPolicy].
  const WidgetOrderFocusTraversalPolicy();

  // Moves the focus to the next or previous node, depending on whether forward
  // is true or not.
  bool _move(FocusableNode node, {@required bool forward}) {
    if (node == null) {
      return false;
    }
    final FocusableScopeNode nearestScope = node.nearestScope;
    nearestScope.policyData = null;
    final FocusableNode focusedChild = nearestScope.focusedChild;
    if (focusedChild == null) {
      findFirstFocus(node).requestFocusFromPolicy();
      return true;
    }
    FocusableNode previousNode;
    FocusableNode firstNode;
    FocusableNode lastNode;
    bool visit(FocusableNode visited) {
      firstNode ??= visited;
      visited.visitChildren(visit);
      if (forward) {
        if (previousNode == focusedChild) {
          visited.requestFocusFromPolicy();
          return false; // short circuit the traversal.
        }
      } else {
        if (previousNode != null && visited == focusedChild) {
          previousNode.requestFocusFromPolicy();
          return false; // short circuit the traversal.
        }
      }
      previousNode = visited;
      lastNode = visited;
      return true; // continue traversal
    }

    if (nearestScope.visitChildren(visit)) {
      if (forward) {
        if (firstNode != null) {
          firstNode.requestFocusFromPolicy();
          return true;
        }
      } else {
        if (lastNode != null) {
          lastNode.requestFocusFromPolicy();
          return true;
        }
      }
      return false;
    }
    return true;
  }

  @override
  bool next(FocusableNode currentNode) => _move(currentNode, forward: true);

  @override
  bool previous(FocusableNode currentNode) => _move(currentNode, forward: false);
}

class _SortData {
  _SortData(this.node) : rect = node.rect;

  final Rect rect;
  final FocusableNode node;
}

/// Traverses the focus order in "reading order".
///
/// By default, reading order traversal goes in the reading direction (based on
/// the ambient [Directionality] in the context), and then down, using this
/// algorithm:
///
/// 1. Find the node rectangle that has the highest `top` on the screen.
/// 2. Find any other nodes which intersect the infinite horizontal band defined
///    by the highest rectangle's top and bottom edges.
/// 3. Pick the closest to the beginning of the reading order from among the
///    nodes discovered above.
///
/// See also:
///
///   * [Focusable], a widget that manages a [FocusableNode].
///   * [DefaultFocusTraversal], a widget that imposes a traversal policy on the
///     [Focusable] nodes below it in the widget hierarchy.
///   * [FocusableNode], which is affected by the traversal policy.
///   * [FocusableScopeNode], which represents a group of focusable nodes.
///   * [FocusableScope], a widget that manages a [FocusaleScopeNode].
class ReadingOrderTraversalPolicy extends FocusTraversalPolicy with DirectionalFocusTraversalPolicyMixin {
  /// Creates a const ReadingOrderTraversalPolicy.
  const ReadingOrderTraversalPolicy();

  // Sorts the list of nodes based on their geometry into the desired reading
  // order based on the directionality of the context for each node.
  Iterable<FocusableNode> _sortByGeometry(FocusableNode scope) {
    final Iterable<FocusableNode> nodes = scope.descendants;
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
    for (FocusableNode node in nodes) {
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
  bool _move(FocusableNode currentNode, {@required bool forward}) {
    final FocusableScopeNode nearestScope = currentNode.nearestScope;
    nearestScope.policyData = null;
    final FocusableNode focusedChild = nearestScope.focusedChild;
    if (focusedChild == null) {
      currentNode.requestFocusFromPolicy();
      return true;
    }
    final List<FocusableNode> sortedNodes = _sortByGeometry(nearestScope).toList();
    if (forward && focusedChild == sortedNodes.last) {
      sortedNodes.first.requestFocusFromPolicy();
      return true;
    }
    if (!forward && focusedChild == sortedNodes.first) {
      sortedNodes.last.requestFocusFromPolicy();
      return true;
    }

    final Iterable<FocusableNode> maybeFlipped = forward ? sortedNodes : sortedNodes.reversed;
    FocusableNode previousNode;
    for (FocusableNode node in maybeFlipped) {
      if (previousNode == focusedChild) {
        node.requestFocusFromPolicy();
        return true;
      }
      previousNode = node;
    }
    return false;
  }

  @override
  bool next(FocusableNode currentNode) => _move(currentNode, forward: true);

  @override
  bool previous(FocusableNode currentNode) => _move(currentNode, forward: false);
}

/// A widget that describes an inherited focus policy for focus traversal.
///
/// By default, traverses in widget order using the
/// [ReadingOrderTraversalPolicy].
///
/// See also:
///
///  * [FocusTraversalPolicy] for the API used to impose traversal order policy.
///  * [WidgetOrderFocusTraversalPolicy] for a traversal policy that traverses
///    nodes in the order they are added to the widget tree.
///  * [ReadingOrderTraversalPolicy] for a traversal policy that traverses nodes
///    in the reading order defined in the widget tree, and then top to bottom.
///  * [DirectionalFocusTraversalPolicyMixin] for a mixin that implements
///  * [Focusable], a widget that manages a [FocusableNode].
///  * [DefaultFocusTraversal], a widget that imposes a traversal policy on the
///    [Focusable] nodes below it in the widget hierarchy.
///  * [FocusableNode], which is affected by the traversal policy.
///  * [FocusableScopeNode], which represents a group of focusable nodes.
///  * [FocusableScope], a widget that manages a [FocusaleScopeNode].
class DefaultFocusTraversal extends InheritedWidget {
  /// Creates a FocusTraversal object.
  ///
  /// The [policy] and [child] arguments must not be null.
  const DefaultFocusTraversal({
    Key key,
    this.policy = const ReadingOrderTraversalPolicy(),
    @required Widget child,
  })  : assert(policy != null),
        super(key: key, child: child);

  /// The policy used to move the focus from one focus node to another.
  ///
  /// By default, traverses in widget order using
  /// [WidgetOrderFocusTraversalPolicy].
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

  /// Returns the [DefaultFocusTraversal] that most tightly encloses the given
  /// [BuildContext].
  ///
  /// The [context] argument must not be null.
  static FocusTraversalPolicy of(BuildContext context) {
    assert(context != null);
    final DefaultFocusTraversal inherited = context.inheritFromWidgetOfExactType(DefaultFocusTraversal);
    assert(() {
      if (inherited == null) {
        throw FlutterError('Unable to find a DefaultFocusTraversal widget in the context.\n'
            'DefaultFocusTraversal.of() was called with a context that does not contain a '
            'DefaultFocusTraversal.\n'
            'No DefaultFocusTraversal ancestor could be found starting from the context that was '
            'passed to DefaultFocusTraversal.of(). This can happen because you do not have a '
            'WidgetsApp or MaterialApp widget (those widgets introduce a DefaultFocusTraversal), '
            'or it can happen if the context you use comes from a widget above those widgets.\n'
            'The context used was:\n'
            '  $context');
      }
      return true;
    }());
    return inherited?.policy;
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
}
