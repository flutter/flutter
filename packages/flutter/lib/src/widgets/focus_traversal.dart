// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:flutter/painting.dart';

import 'actions.dart';
import 'basic.dart';
import 'editable_text.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'scroll_position.dart';
import 'scrollable.dart';

void _focusAndEnsureVisible(
  FocusNode node, {
  ScrollPositionAlignmentPolicy alignmentPolicy = ScrollPositionAlignmentPolicy.explicit,
}) {
  node.requestFocus();
  Scrollable.ensureVisible(node.context, alignment: 1.0, alignmentPolicy: alignmentPolicy);
}

class _FocusPolicyGroupInfo {
  _FocusPolicyGroupInfo(FocusTraversalGroup group, {List<FocusNode> members, FocusTraversalPolicy defaultPolicy})
      : groupNode = group?._focusNode,
        policy = group?.policy ?? defaultPolicy ?? ReadingOrderTraversalPolicy(),
        members = members ?? <FocusNode>[];
  final FocusNode groupNode;
  final FocusTraversalPolicy policy;
  final List<FocusNode> members;
}

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
/// [FocusTraversalGroup] widget.
///
/// The focus traversal policy is what determines which widget is "next",
/// "previous", or in a direction from the currently focused [FocusNode].
///
/// One of the pre-defined subclasses may be used, or define a custom policy to
/// create a unique focus order.
///
/// See also:
///
///  * [FocusNode], for a description of the focus system.
///  * [FocusTraversalGroup], a widget that groups together and imposes a
///    traversal policy on the [Focus] nodes below it in the widget hierarchy.
///  * [FocusNode], which is affected by the traversal policy.
///  * [WidgetOrderTraversalPolicy], a policy that relies on the widget
///    creation order to describe the order of traversal.
///  * [ReadingOrderTraversalPolicy], a policy that describes the order as the
///    natural "reading order" for the current [Directionality].
///  * [OrderedTraversalPolicy], a policy that describes the order
///    explicitly using [FocusTraversalOrder] widgets.
///  * [DirectionalFocusTraversalPolicyMixin] a mixin class that implements
///    focus traversal in a direction.
abstract class FocusTraversalPolicy extends Diagnosticable {
  /// A const constructor so subclasses can be const.
  const FocusTraversalPolicy();

  /// Returns the node that should receive focus if there is no current focus
  /// in the nearest [FocusScopeNode] that `currentNode` belongs to.
  ///
  /// This is used by [next]/[previous]/[inDirection] to determine which node to
  /// focus if they are called when no node is currently focused.
  ///
  /// The `currentNode` argument must not be null.
  ///
  /// The default implementation returns the [FocusScopeNode.focusedChild], if
  /// set, on the nearest scope of the `currentNode`, otherwise, returns the
  /// first node from [sortDescendants], or the given `currentNode` if there are
  /// no descendants.
  FocusNode findFirstFocus(FocusNode currentNode) {
    assert(currentNode != null);
    final FocusScopeNode scope = currentNode.nearestScope;
    FocusNode candidate = scope.focusedChild;
    if (candidate == null && scope.descendants.isNotEmpty) {
      final Iterable<FocusNode> sorted = _sortAllDescendants(scope);
      candidate = sorted.isNotEmpty ? sorted.first : null;
    }

    // If we still didn't find any candidate, use the current node as a
    // fallback.
    candidate ??= currentNode;
    return candidate;
  }

  /// Returns the first node in the given [direction] that should receive focus
  /// if there is no current focus in the scope to which the [currentNode]
  /// belongs.
  ///
  /// This is typically used by [inDirection] to determine which node to focus
  /// if it is called when no node is currently focused.
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

  /// This is called whenever the given [node] is re-parented into a new scope,
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
  bool next(FocusNode currentNode) => _moveFocus(currentNode, forward: true);

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
  bool previous(FocusNode currentNode) => _moveFocus(currentNode, forward: false);

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

  /// Sorts the given `descendants` into focus order.
  ///
  /// Subclasses can override this to implement a different sort for [next] and
  /// [previous] to use in their ordering. If the returned iterable omits a node
  /// that is a descendant of the given scope, then the user will be unable to
  /// use next/previous keyboard traversal to reach that node, and if that node
  /// is used as the originator of a call to next/previous (i.e. supplied as the
  /// argument to [next] or [previous]), then the next or previous node will not
  /// be able to be determined and the focus will not change.
  ///
  /// This is not used for directional focus ([inDirection]), only for
  /// determining the focus order for [next] and [previous].
  ///
  /// When implementing an override for this function, be sure to use
  /// [mergeSort] instead of Dart's default list sorting algorithm when sorting
  /// items, since the default algorithm is not stable (items deemed to be equal
  /// can appear in arbitrary order, and change positions between sorts), where
  /// [mergeSort] is stable.
  ///
  /// The default implementation returns the nodes in the order given.
  @protected
  Iterable<FocusNode> sortDescendants(Iterable<FocusNode> descendants) => descendants;

  // Sort all descendants, taking into account the FocusTraversalPolicyGroup
  // that they are each in, and filtering out non-traversable/focusable nodes.
  List<FocusNode> _sortAllDescendants(FocusScopeNode scope) {
    final FocusTraversalGroup scopeGroup = scope.context == null ? null : FocusTraversalGroup.of(scope.context, nullOk: true);
    final FocusTraversalPolicy defaultPolicy = scopeGroup?.policy ?? ReadingOrderTraversalPolicy();
    // Build the sorting data structure, separating descendants into groups.
    final Map<FocusNode, _FocusPolicyGroupInfo> groups = <FocusNode, _FocusPolicyGroupInfo>{};
    for (final FocusNode node in scope.descendants) {
      final FocusTraversalGroup group = FocusTraversalGroup.of(node.context, nullOk: true);
      final FocusNode groupNode = group?._focusNode;
      if (node == groupNode) {
        final FocusTraversalGroup parent = FocusTraversalGroup.of(node.parent.context, nullOk: true);
        final FocusNode parentNode = parent?._focusNode;
        groups[parentNode] ??= _FocusPolicyGroupInfo(parent, members: <FocusNode>[], defaultPolicy: defaultPolicy);
        assert(!groups[parentNode].members.contains(node));
        groups[parentNode].members.add(groupNode);
        continue;
      }
      // Skip non-focusable or traversable nodes.
      if (node.canRequestFocus && !node.skipTraversal) {
        groups[groupNode] ??= _FocusPolicyGroupInfo(group, members: <FocusNode>[], defaultPolicy: defaultPolicy);
        assert(!groups[groupNode].members.contains(node));
        groups[groupNode].members.add(node);
      }
    }

    // Sort the member lists using the individual policy sorts.
    final Set<FocusNode> groupKeys = groups.keys.toSet();
    for (final FocusNode key in groups.keys) {
      final List<FocusNode> sortedMembers = groups[key].policy.sortDescendants(groups[key].members).toList();
      groups[key].members.clear();
      groups[key].members.addAll(sortedMembers);
    }

    // Traverse the group tree, adding the children of members in the order they appear in the member lists.
    final List<FocusNode> sortedDescendants =  <FocusNode>[];
    void visitGroups(_FocusPolicyGroupInfo info) {
      for (final FocusNode node in info.members) {
        if (groupKeys.contains(node)) {
          // This is a policy group focus node. Replace it with the members of
          // the corresponding policy group.
          visitGroups(groups[node]);
        } else {
          sortedDescendants.add(node);
        }
      }
    }

    visitGroups(groups[scopeGroup?._focusNode]);
    assert(sortedDescendants.toSet().difference(scope.traversalDescendants.toSet()).isEmpty,
      'sorted descendants contains more nodes than it should: (${sortedDescendants.toSet().difference(scope.traversalDescendants.toSet())})');
    assert(scope.traversalDescendants.toSet().difference(sortedDescendants.toSet()).isEmpty,
      'sorted descendants are missing some nodes: (${scope.traversalDescendants.toSet().difference(sortedDescendants.toSet())})');
    return sortedDescendants;
  }

  // Moves the focus to the next node in the FocusScopeNode provided by the
  // nearest scope to the currentNode argument, either in a forward or
  // reverse direction, depending on the value of the forward argument.
  //
  // This function is called by the next and previous members to move to the
  // next or previous node, respectively.
  //
  // Uses findFirstFocus to find the first node if there is no
  // FocusScopeNode.focusedChild set. If there is a focused child for the
  // scope, then it calls sortDescendants to get a sorted list of descendants,
  // and then finds the node after the current first focus of the scope if
  // forward is true, and the node before it if forward is false.
  //
  // Returns true if a node requested focus.
  @protected
  bool _moveFocus(FocusNode currentNode, {@required bool forward}) {
    assert(forward != null);
    if (currentNode == null) {
      return false;
    }
    final FocusScopeNode nearestScope = currentNode.nearestScope;
    invalidateScopeData(nearestScope);
    final FocusNode focusedChild = nearestScope.focusedChild;
    if (focusedChild == null) {
      final FocusNode firstFocus = findFirstFocus(currentNode);
      if (firstFocus != null) {
        _focusAndEnsureVisible(
          firstFocus,
          alignmentPolicy: forward ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );
        return true;
      }
    }
    final List<FocusNode> sortedNodes = _sortAllDescendants(nearestScope);
    if (forward && focusedChild == sortedNodes.last) {
      _focusAndEnsureVisible(sortedNodes.first, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
      return true;
    }
    if (!forward && focusedChild == sortedNodes.first) {
      _focusAndEnsureVisible(sortedNodes.last, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart);
      return true;
    }

    final Iterable<FocusNode> maybeFlipped = forward ? sortedNodes : sortedNodes.reversed;
    FocusNode previousNode;
    for (final FocusNode node in maybeFlipped) {
      if (previousNode == focusedChild) {
        _focusAndEnsureVisible(
          node,
          alignmentPolicy: forward ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );
        return true;
      }
      previousNode = node;
    }
    return false;
  }
}

/// A policy data object for use by the [DirectionalFocusTraversalPolicyMixin]
/// so it can keep track of the traversal history.
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
/// follow the same path on the way up as it did on the way down, since changing
/// the axis of motion resets the history.
///
/// See also:
///
///  * [FocusNode], for a description of the focus system.
///  * [FocusTraversalGroup], a widget that groups together and imposes a
///    traversal policy on the [Focus] nodes below it in the widget hierarchy.
///  * [WidgetOrderTraversalPolicy], a policy that relies on the widget
///    creation order to describe the order of traversal.
///  * [ReadingOrderTraversalPolicy], a policy that describes the order as the
///    natural "reading order" for the current [Directionality].
///  * [OrderedTraversalPolicy], a policy that describes the order
///    explicitly using [FocusTraversalOrder] widgets.
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
    mergeSort<FocusNode>(sorted, compare: (FocusNode a, FocusNode b) {
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

    if (sorted.isNotEmpty) {
      return sorted.first;
    }

    return null;
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
    mergeSort<FocusNode>(sorted, compare: (FocusNode a, FocusNode b) => a.rect.center.dx.compareTo(b.rect.center.dx));
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
    mergeSort<FocusNode>(sorted, compare: (FocusNode a, FocusNode b) => a.rect.center.dy.compareTo(b.rect.center.dy));
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

      // Returns true if successfully popped the history.
      bool popOrInvalidate(TraversalDirection direction) {
        final FocusNode lastNode = policyData.history.removeLast().node;
        if (Scrollable.of(lastNode.context) != Scrollable.of(primaryFocus.context)) {
          invalidateScopeData(nearestScope);
          return false;
        }
        ScrollPositionAlignmentPolicy alignmentPolicy;
        switch (direction) {
          case TraversalDirection.up:
          case TraversalDirection.left:
            alignmentPolicy = ScrollPositionAlignmentPolicy.keepVisibleAtStart;
            break;
          case TraversalDirection.right:
          case TraversalDirection.down:
            alignmentPolicy = ScrollPositionAlignmentPolicy.keepVisibleAtEnd;
            break;
        }
        _focusAndEnsureVisible(
          lastNode,
          alignmentPolicy: alignmentPolicy,
        );
        return true;
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
              if (popOrInvalidate(direction)) {
                return true;
              }
              break;
          }
          break;
        case TraversalDirection.left:
        case TraversalDirection.right:
          switch (policyData.history.first.direction) {
            case TraversalDirection.left:
            case TraversalDirection.right:
              if (popOrInvalidate(direction)) {
                return true;
              }
              break;
            case TraversalDirection.up:
            case TraversalDirection.down:
              // Reset the policy data if we change directions.
              invalidateScopeData(nearestScope);
              break;
          }
      }
    }
    if (policyData != null && policyData.history.isEmpty) {
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
      final FocusNode firstFocus = findFirstFocusInDirection(currentNode, direction) ?? currentNode;
      switch (direction) {
        case TraversalDirection.up:
        case TraversalDirection.left:
          _focusAndEnsureVisible(
            firstFocus,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          );
          break;
        case TraversalDirection.right:
        case TraversalDirection.down:
          _focusAndEnsureVisible(
            firstFocus,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
          break;
      }
      return true;
    }
    if (_popPolicyDataIfNeeded(direction, nearestScope, focusedChild)) {
      return true;
    }
    FocusNode found;
    final ScrollableState focusedScrollable = Scrollable.of(focusedChild.context);
    switch (direction) {
      case TraversalDirection.down:
      case TraversalDirection.up:
        Iterable<FocusNode> eligibleNodes = _sortAndFilterVertically(
          direction,
          focusedChild.rect,
          nearestScope.traversalDescendants,
        );
        if (focusedScrollable != null && !focusedScrollable.position.atEdge) {
          final Iterable<FocusNode> filteredEligibleNodes = eligibleNodes.where((FocusNode node) => Scrollable.of(node.context) == focusedScrollable);
          if (filteredEligibleNodes.isNotEmpty) {
            eligibleNodes = filteredEligibleNodes;
          }
        }
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
        mergeSort<FocusNode>(sorted, compare: (FocusNode a, FocusNode b) {
          return (a.rect.center.dx - focusedChild.rect.center.dx).abs().compareTo((b.rect.center.dx - focusedChild.rect.center.dx).abs());
        });
        found = sorted.first;
        break;
      case TraversalDirection.right:
      case TraversalDirection.left:
        Iterable<FocusNode> eligibleNodes = _sortAndFilterHorizontally(direction, focusedChild.rect, nearestScope);
        if (focusedScrollable != null && !focusedScrollable.position.atEdge) {
          final Iterable<FocusNode> filteredEligibleNodes = eligibleNodes.where((FocusNode node) => Scrollable.of(node.context) == focusedScrollable);
          if (filteredEligibleNodes.isNotEmpty) {
            eligibleNodes = filteredEligibleNodes;
          }
        }
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
        mergeSort<FocusNode>(sorted, compare: (FocusNode a, FocusNode b) {
          return (a.rect.center.dy - focusedChild.rect.center.dy).abs().compareTo((b.rect.center.dy - focusedChild.rect.center.dy).abs());
        });
        found = sorted.first;
        break;
    }
    if (found != null) {
      _pushPolicyData(direction, nearestScope, focusedChild);
      switch (direction) {
        case TraversalDirection.up:
        case TraversalDirection.left:
          _focusAndEnsureVisible(
            found,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          );
          break;
        case TraversalDirection.down:
        case TraversalDirection.right:
          _focusAndEnsureVisible(
            found,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
          break;
      }
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
///  * [FocusNode], for a description of the focus system.
///  * [FocusTraversalGroup], a widget that groups together and imposes a
///    traversal policy on the [Focus] nodes below it in the widget hierarchy.
///  * [ReadingOrderTraversalPolicy], a policy that describes the order as the
///    natural "reading order" for the current [Directionality].
///  * [DirectionalFocusTraversalPolicyMixin] a mixin class that implements
///    focus traversal in a direction.
///  * [OrderedTraversalPolicy], a policy that describes the order
///    explicitly using [FocusTraversalOrder] widgets.
class WidgetOrderTraversalPolicy extends FocusTraversalPolicy with DirectionalFocusTraversalPolicyMixin {}

// This class exists mainly for efficiency reasons: the rect is copied out of
// the node, because it will be accessed many times in the reading order
// algorithm, and the FocusNode.rect accessor does coordinate transformation. If
// not for this optimization, it could just be removed, and the node used
// directly.
class _ReadingOrderSortData {
  _ReadingOrderSortData(this.node)
      : assert(node != null),
        rect = node.rect,
        directionality = Directionality.of(node.context);

  final TextDirection directionality;
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
///  * [FocusNode], for a description of the focus system.
///  * [FocusTraversalGroup], a widget that groups together and imposes a
///    traversal policy on the [Focus] nodes below it in the widget hierarchy.
///  * [WidgetOrderTraversalPolicy], a policy that relies on the widget
///    creation order to describe the order of traversal.
///  * [DirectionalFocusTraversalPolicyMixin] a mixin class that implements
///    focus traversal in a direction.
///  * [OrderedTraversalPolicy], a policy that describes the order
///    explicitly using [FocusTraversalOrder] widgets.
class ReadingOrderTraversalPolicy extends FocusTraversalPolicy with DirectionalFocusTraversalPolicyMixin {
  // Sorts the list of nodes based on their geometry into the desired reading
  // order based on the directionality of the context for each node.
  @override
  Iterable<FocusNode> sortDescendants(Iterable<FocusNode> descendants) {
    if (descendants.length <= 1) {
      return descendants;
    }

    Iterable<_ReadingOrderSortData> inBand(_ReadingOrderSortData current, Iterable<_ReadingOrderSortData> candidates) {
      final Rect wide = Rect.fromLTRB(double.negativeInfinity, current.rect.top, double.infinity, current.rect.bottom);
      return candidates.where((_ReadingOrderSortData item) {
        return !item.rect.intersect(wide).isEmpty;
      });
    }

    _ReadingOrderSortData pickFirst(List<_ReadingOrderSortData> candidates) {
      int compareBeginningSide(_ReadingOrderSortData a, _ReadingOrderSortData b) {
        if (a.directionality == b.directionality) {
          if (a.directionality == TextDirection.ltr) {
            return a.rect.left.compareTo(b.rect.left);
          } else {
            return -a.rect.right.compareTo(b.rect.right);
          }
        }
        // If the directionalities are different, sort ltr to the left, and
        // rtl to the right.
        switch(a.directionality) {
          case TextDirection.ltr:
            return -1;
          case TextDirection.rtl:
            return 1;
        }
        assert(false, 'Directionality ${a.directionality} not handled.');
        return 0;
      }

      int compareTopSide(_ReadingOrderSortData a, _ReadingOrderSortData b) {
        return a.rect.top.compareTo(b.rect.top);
      }

      // Get the topmost
      mergeSort<_ReadingOrderSortData>(candidates, compare: compareTopSide);
      final _ReadingOrderSortData topmost = candidates.first;
      // If there are any others in the band of the topmost, then pick the
      // leftmost one.
      final List<_ReadingOrderSortData> inBandOfTop = inBand(topmost, candidates).toList();
      mergeSort<_ReadingOrderSortData>(inBandOfTop, compare: compareBeginningSide);
      if (inBandOfTop.isNotEmpty) {
        return inBandOfTop.first;
      }
      return topmost;
    }

    final List<_ReadingOrderSortData> data = <_ReadingOrderSortData>[
      for (final FocusNode node in descendants) _ReadingOrderSortData(node),
    ];

    // Pick the initial widget as the one that is leftmost in the band of the
    // topmost, or the topmost, if there are no others in its band.
    final List<_ReadingOrderSortData> sortedList = <_ReadingOrderSortData>[];
    final List<_ReadingOrderSortData> unplaced = data.toList();
    _ReadingOrderSortData current = pickFirst(unplaced);
    sortedList.add(current);
    unplaced.remove(current);

    while (unplaced.isNotEmpty) {
      final _ReadingOrderSortData next = pickFirst(unplaced);
      current = next;
      sortedList.add(current);
      unplaced.remove(current);
    }
    return sortedList.map((_ReadingOrderSortData item) => item.node);
  }
}

/// Base class for all sort orders for [OrderedTraversalPolicy] traversal.
///
/// {@template flutter.widgets.focusorder.comparable}
/// Only orders of the same type are comparable. If a set of widgets in the same
/// [FocusScope] contains orders that are not comparable with each other, it
/// will assert, since the ordering between such keys is undefined. To avoid
/// collisions, use a [FocusTraversalGroup] to group similarly ordered widgets
/// together.
/// {@endtemplate}
///
/// See also:
///
///  * [FocusTraversalGroup], a widget that groups together and imposes a
///    traversal policy on the [Focus] nodes below it in the widget hierarchy.
///  * [FocusTraversalOrder], a widget that assigns an order to a widget subtree
///    for the [OrderedFocusTraversalPolicy] to use.
///  * [NumericFocusOrder], for a focus order that describes its order with a
///    `double`.
///  * [LexicalFocusOrder], a focus order that assigns a string-based lexical
///    traversal order to a [FocusTraversalOrder] widget.
abstract class FocusOrder extends Diagnosticable implements Comparable<FocusOrder> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const FocusOrder();

  @override
  @nonVirtual
  int compareTo(FocusOrder other) {
    assert(
        runtimeType == other.runtimeType,
        "The sorting algorithm must not compare incomparable keys, since they don't "
        'know how to order themselves relative to each other. Comparing $this with $other');
    return doCompare(other);
  }

  /// The subclass implementation called by [compareTo].
  ///
  /// The argument is guaranteed to be of the same [runtimeType] as this object.
  ///
  /// The method should return a negative number if this object comes earlier in
  /// the sort order than the argument; and a positive number if it comes later
  /// in the sort order. Returning zero causes the system to use default sort
  /// order.
  @protected
  int doCompare(covariant FocusOrder other);
}

/// Can be given to a [FocusTraversalOrder] widget to assign a numerical order
/// to a widget subtree that is using a [OrderedTraversalPolicy] to define the
/// order in which widgets should be traversed with the keyboard.
///
/// {@macro flutter.widgets.focusorder.comparable}
///
/// See also:
///
///  * [FocusTraversalOrder], a widget that assigns an order to a widget subtree
///    for the [OrderedFocusTraversalPolicy] to use.
class NumericFocusOrder extends FocusOrder {
  /// Const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const NumericFocusOrder(this.order) : assert(order != null);

  /// The numerical order to assign to the widget subtree using
  /// [FocusTraversalOrder].
  ///
  /// Determines the placement of this widget in a sequence of widgets that defines
  /// the order in which this node is traversed by the focus policy.
  ///
  /// Lower values will be traversed first.
  final double order;

  @override
  int doCompare(NumericFocusOrder other) => order.compareTo(other.order);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('order', order));
  }
}

/// Can be given to a [FocusTraversalOrder] widget to use a String to assign a
/// lexical order to a widget subtree that is using a
/// [OrderedTraversalPolicy] to define the order in which widgets should be
/// traversed with the keyboard.
///
/// This sorts strings using Dart's default string comparison, which is not
/// locale specific.
///
/// {@macro flutter.widgets.focusorder.comparable}
///
/// See also:
///
///  * [FocusTraversalOrder], a widget that assigns an order to a widget subtree
///    for the [OrderedFocusTraversalPolicy] to use.
class LexicalFocusOrder extends FocusOrder {
  /// Const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const LexicalFocusOrder(this.order) : assert(order != null);

  /// The String that defines the lexical order to assign to the widget subtree
  /// using [FocusTraversalOrder].
  ///
  /// Determines the placement of this widget in a sequence of widgets that defines
  /// the order in which this node is traversed by the focus policy.
  ///
  /// Lower lexical values will be traversed first (e.g. 'a' comes before 'z').
  final String order;

  @override
  int doCompare(LexicalFocusOrder other) => order.compareTo(other.order);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('order', order));
  }
}

// Used to help sort the focus nodes in an OrderedFocusTraversalPolicy.
class _OrderedFocusInfo {
  const _OrderedFocusInfo({@required this.node, @required this.order})
      : assert(node != null),
        assert(order != null);

  final FocusNode node;
  final FocusOrder order;
}

/// A [FocusTraversalPolicy] that orders nodes by an explicit order that resides
/// in the nearest [FocusTraversalOrder] widget ancestor.
///
/// {@macro flutter.widgets.focusorder.comparable}
///
/// {@tool sample --template=stateless_widget_scaffold_center}
/// This sample shows how to assign a traversal order to a widget. In the
/// example, the focus order goes from bottom right (the "One" button) to top
/// left (the "Six" button).
///
/// ```dart preamble
/// class DemoButton extends StatelessWidget {
///   const DemoButton({this.name, this.autofocus = false, this.order});
///
///   final String name;
///   final bool autofocus;
///   final double order;
///
///   void _handleOnPressed() {
///     print('Button $name pressed.');
///     debugDumpFocusTree();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return FocusTraversalOrder(
///       order: NumericFocusOrder(order),
///       child: FlatButton(
///         autofocus: autofocus,
///         focusColor: Colors.red,
///         onPressed: () => _handleOnPressed(),
///         child: Text(name),
///       ),
///     );
///   }
/// }
/// ```
///
/// ```dart
/// Widget build(BuildContext context) {
///   return FocusTraversalGroup(
///     policy: OrderedTraversalPolicy(),
///     child: Column(
///       mainAxisAlignment: MainAxisAlignment.center,
///       children: <Widget>[
///         Row(
///           mainAxisAlignment: MainAxisAlignment.center,
///           children: const <Widget>[
///             DemoButton(name: 'Six', order: 6),
///           ],
///         ),
///         Row(
///           mainAxisAlignment: MainAxisAlignment.center,
///           children: const <Widget>[
///             DemoButton(name: 'Five', order: 5),
///             DemoButton(name: 'Four', order: 4),
///           ],
///         ),
///         Row(
///           mainAxisAlignment: MainAxisAlignment.center,
///           children: const <Widget>[
///             DemoButton(name: 'Three', order: 3),
///             DemoButton(name: 'Two', order: 2),
///             DemoButton(name: 'One', order: 1, autofocus: true),
///           ],
///         ),
///       ],
///     ),
///   );
/// }
/// {@end-tool}
///
/// See also:
///
///  * [WidgetOrderFocusTraversalPolicy], a policy that relies on the widget
///    creation order to describe the order of traversal.
///  * [ReadingOrderTraversalPolicy], a policy that describes the order as the
///    natural "reading order" for the current [Directionality].
///  * [NumericFocusOrder], a focus order that assigns a numeric traversal order
///    to a [FocusTraversalOrder] widget.
///  * [LexicalFocusOrder], a focus order that assigns a string-based lexical
///    traversal order to a [FocusTraversalOrder] widget.
///  * [FocusOrder], an abstract base class for all types of focus traversal
///    orderings.
class OrderedTraversalPolicy extends FocusTraversalPolicy with DirectionalFocusTraversalPolicyMixin {
  /// Constructs a traversal policy that orders widgets for keyboard traversal
  /// based on an explicit order.
  ///
  /// If [secondary] is null, it will default to [ReadingOrderTraversalPolicy].
  OrderedTraversalPolicy({this.secondary}) {
    secondary ??= ReadingOrderTraversalPolicy();
  }

  /// This is the policy that is used when a node doesn't have an order
  /// assigned, or when multiple nodes have orders which are identical.
  ///
  /// If not set, this defaults to [ReadingOrderTraversalPolicy].
  ///
  /// This policy determines the secondary sorting order of nodes which evaluate
  /// as having an identical order (including those with no order specified).
  ///
  /// Nodes with no order specified will be sorted after nodes with an explicit
  /// order.
  FocusTraversalPolicy secondary;

  @override
  Iterable<FocusNode> sortDescendants(Iterable<FocusNode> descendants) {
    final Iterable<FocusNode> sortedDescendants = secondary.sortDescendants(descendants);
    final List<FocusNode> unordered = <FocusNode>[];
    final List<_OrderedFocusInfo> ordered = <_OrderedFocusInfo>[];
    for (final FocusNode node in sortedDescendants) {
      final FocusOrder order = FocusTraversalOrder.of(node.context, nullOk: true);
      if (order != null) {
        ordered.add(_OrderedFocusInfo(node: node, order: order));
      } else {
        unordered.add(node);
      }
    }
    mergeSort<_OrderedFocusInfo>(ordered, compare:(_OrderedFocusInfo a, _OrderedFocusInfo b) {
      return a.order.compareTo(b.order);
    });
    return ordered.map<FocusNode>((_OrderedFocusInfo info) => info.node).followedBy(unordered);
  }
}

/// An inherited widget that describes the order in which its child subtree
/// should be traversed.
///
/// {@macro flutter.widgets.focusorder.comparable}
///
/// The order for a widget is determined by the [FocusOrder] returned by
/// [FocusTraversalOrder.of] for a particular context.
class FocusTraversalOrder extends InheritedWidget {
  /// A const constructor so that subclasses can be const.
  const FocusTraversalOrder({Key key, this.order, Widget child}) : super(key: key, child: child);

  /// The order for the widget descendants of this [FocusTraversalOrder].
  final FocusOrder order;

  /// Finds the nearest TraversalOrder widget.
  ///
  /// It does not create a rebuild dependency because changing the traversal
  /// order doesn't change the widget tree, so nothing needs to be rebuilt as a
  /// result of an order change.
  static FocusOrder of(BuildContext context, {bool nullOk = false}) {
    assert(context != null);
    assert(nullOk != null);
    final FocusTraversalOrder marker = context.findAncestorWidgetOfExactType<FocusTraversalOrder>();
    final FocusOrder order = marker?.order;
    if (order == null) {
      if (!nullOk) {
        throw FlutterError('FocusTraversalOrder.of() was called with a context that does not contain '
            'a TraversalOrder widget. No TraversalOrder widget ancestor could be found starting '
            'from the context that was passed to FocusTraversalOrder.of().\n'
            'The context used was:\n'
            '  $context');
      }
      return null;
    }
    return order;
  }

  // Since the order of traversal doesn't affect display of anything, we don't
  // need to force a rebuild of anything that depends upon it.
  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusOrder>('order', order));
  }
}

/// A widget that describes the inherited focus policy for focus traversal for
/// its descendants, grouping them into a separate traversal group.
///
/// A traversal group is treated as one entity when sorted by the traversal
/// algorithm, so it can be used to segregate different parts of the widget tree
/// that need to be sorted using different algorithms and/or sort orders when
/// using an [OrderedTraversalPolicy].
///
/// By default, traverses in reading order using [ReadingOrderTraversalPolicy].
///
/// See also:
///
///  * [FocusNode], for a description of the focus system.
///  * [WidgetOrderTraversalPolicy], a policy that relies on the widget
///    creation order to describe the order of traversal.
///  * [ReadingOrderTraversalPolicy], a policy that describes the order as the
///    natural "reading order" for the current [Directionality].
///  * [DirectionalFocusTraversalPolicyMixin] a mixin class that implements
///    focus traversal in a direction.
class FocusTraversalGroup extends StatelessWidget {
  /// Creates a [FocusTraversalGroup] object.
  ///
  /// The [child] argument must not be null.
  FocusTraversalGroup({
    Key key,
    FocusTraversalPolicy policy,
    @required this.child,
    String debugLabel,
  })  : _focusNode = FocusNode(
          canRequestFocus: false,
          skipTraversal: true,
          debugLabel: debugLabel ?? 'FocusTraversalPolicyGroup',
        ),
        policy = policy ?? ReadingOrderTraversalPolicy(),
        super(key: key);

  /// The child widget of this [FocusTraversalGroup].
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  // The internal focus node used to collect the children of this node into a
  // group, and to provide a context for the traversal algorithm to sort the
  // group with.
  final FocusNode _focusNode;

  /// The policy used to move the focus from one focus node to another when
  /// traversing them using a keyboard.
  ///
  /// If not specified, traverses in reading order using
  /// [ReadingOrderTraversalPolicy].
  ///
  /// See also:
  ///
  ///  * [FocusTraversalPolicy] for the API used to impose traversal order
  ///    policy.
  ///  * [WidgetOrderTraversalPolicy] for a traversal policy that traverses
  ///    nodes in the order they are added to the widget tree.
  ///  * [ReadingOrderTraversalPolicy] for a traversal policy that traverses
  ///    nodes in the reading order defined in the widget tree, and then top to
  ///    bottom.
  final FocusTraversalPolicy policy;

  /// Returns the focus policy group widget used by the [FocusTraversalPolicy]
  /// that most tightly encloses the given [BuildContext].
  ///
  /// The [context] argument must not be null.
  ///
  /// It does not create a rebuild dependency because changing the traversal
  /// order doesn't change the widget tree, so nothing needs to be rebuilt as a
  /// result of an order change.
  static FocusTraversalGroup of(BuildContext context, {bool nullOk = false}) {
    final FocusTraversalGroup inherited = context?.findAncestorWidgetOfExactType<FocusTraversalGroup>();
    assert(() {
      if (nullOk) {
        return true;
      }
      if (context == null) {
        throw FlutterError('The context given to FocusTraversalPolicyGroup.of was null, so '
            'consequently no FocusTraversalPolicyGroup ancestor can be found.');
      }
      if (inherited == null) {
        throw FlutterError('Unable to find a FocusTraversalPolicyGroup widget in the context.\n'
            'FocusTraversalPolicyGroup.of() was called with a context that does not contain a '
            'FocusTraversalPolicyGroup.\n'
            'No FocusTraversalPolicyGroup ancestor could be found starting from the context that was '
            'passed to FocusTraversalPolicyGroup.of(). This can happen because there is not a '
            'WidgetsApp or MaterialApp widget (those widgets introduce a FocusTraversalPolicyGroup), '
            'or it can happen if the context comes from a widget above those widgets.\n'
            'The context used was:\n'
            '  $context');
      }
      return true;
    }());
    return inherited;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      // The focus node shouldn't actually participate in focus operations: it's
      // just used as an ancestor node in the focus tree to provide a context by
      // which to sort the tree.
      canRequestFocus: false,
      skipTraversal: true,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusTraversalPolicy>('policy', policy));
  }
}

/// A deprecated widget that describes the inherited focus policy for focus
/// traversal for its descendants.
///
/// _This widget has been deprecated: use [FocusTraversalGroup] instead._
@Deprecated(
  'Use FocusTraversalGroup as a replacement for DefaultFocusTraversal. Be aware that FocusTraversalGroup does add an (unfocusable) Focus widget to the hierarchy that DefaultFocusTraversal does not. Use FocusTraversalGroup.of(context).policy as a replacement for DefaultFocusTraversal.of(context). '
  'This feature was deprecated after v1.14.3.'
)
class DefaultFocusTraversal extends InheritedWidget {
  /// Creates a [DefaultFocusTraversal] object.
  ///
  /// The [child] argument must not be null.
  const DefaultFocusTraversal({
    Key key,
    this.policy,
    @required Widget child,
  }) : super(key: key, child: child);

  /// The policy used to move the focus from one focus node to another when
  /// traversing them using a keyboard.
  ///
  /// _This widget has been deprecated: use [FocusTraversalGroup] instead._
  ///
  /// If not specified, traverses in reading order using
  /// [ReadingOrderTraversalPolicy].
  ///
  /// See also:
  ///
  ///  * [FocusTraversalPolicy] for the API used to impose traversal order
  ///    policy.
  ///  * [WidgetOrderTraversalPolicy] for a traversal policy that traverses
  ///    nodes in the order they are added to the widget tree.
  ///  * [ReadingOrderTraversalPolicy] for a traversal policy that traverses
  ///    nodes in the reading order defined in the widget tree, and then top to
  ///    bottom.
  final FocusTraversalPolicy policy;

  /// Returns the [FocusTraversalPolicy] that most tightly encloses the given
  /// [BuildContext].
  ///
  /// _This method has been deprecated: use
  /// `FocusTraversalGroup.of(context).policy` instead._
  ///
  /// It does not create a rebuild dependency because changing the traversal
  /// order doesn't change the widget tree, so nothing needs to be rebuilt as a
  /// result of an order change.
  ///
  /// The [context] argument must not be null.
  static FocusTraversalPolicy of(BuildContext context, {bool nullOk = false}) {
    final DefaultFocusTraversal inherited = context?.findAncestorWidgetOfExactType<DefaultFocusTraversal>();
    assert(() {
      if (nullOk) {
        return true;
      }
      if (context == null) {
        throw FlutterError('The context given to DefaultFocusTraversal.of was null, so '
            'consequently no FocusTraversalPolicyGroup ancestor can be found.');
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
  bool updateShouldNotify(DefaultFocusTraversal oldWidget) => false;
}

// A base class for all of the default actions that request focus for a node.
class _RequestFocusActionBase extends Action {
  _RequestFocusActionBase(LocalKey name) : super(name);

  FocusNode _previousFocus;

  @override
  void invoke(FocusNode node, Intent intent) {
    _previousFocus = primaryFocus;
    node.requestFocus();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusNode>('previous', _previousFocus));
  }
}

/// An [Action] that requests the focus on the node it is invoked on.
///
/// This action can be used to request focus for a particular node, by calling
/// [Action.invoke] like so:
///
/// ```dart
/// Actions.invoke(context, const Intent(RequestFocusAction.key), focusNode: _focusNode);
/// ```
///
/// Where the `_focusNode` is the node for which the focus will be requested.
///
/// The difference between requesting focus in this way versus calling
/// [_focusNode.requestFocus] directly is that it will use the [Action]
/// registered in the nearest [Actions] widget associated with [key] to make the
/// request, rather than just requesting focus directly. This allows the action
/// to have additional side effects, like logging, or undo and redo
/// functionality.
///
/// However, this [RequestFocusAction] is the default action associated with the
/// [key] in the [WidgetsApp], and it simply requests focus and has no side
/// effects.
class RequestFocusAction extends _RequestFocusActionBase {
  /// Creates a [RequestFocusAction] with a fixed [key].
  RequestFocusAction() : super(key);

  /// The [LocalKey] that uniquely identifies this action to an [Intent].
  static const LocalKey key = ValueKey<Type>(RequestFocusAction);

  @override
  void invoke(FocusNode node, Intent intent) => _focusAndEnsureVisible(node);
}

/// An [Action] that moves the focus to the next focusable node in the focus
/// order.
///
/// This action is the default action registered for the [key], and by default
/// is bound to the [LogicalKeyboardKey.tab] key in the [WidgetsApp].
class NextFocusAction extends _RequestFocusActionBase {
  /// Creates a [NextFocusAction] with a fixed [key];
  NextFocusAction() : super(key);

  /// The [LocalKey] that uniquely identifies this action to an [Intent].
  static const LocalKey key = ValueKey<Type>(NextFocusAction);

  @override
  void invoke(FocusNode node, Intent intent) => node.nextFocus();
}

/// An [Action] that moves the focus to the previous focusable node in the focus
/// order.
///
/// This action is the default action registered for the [key], and by default
/// is bound to a combination of the [LogicalKeyboardKey.tab] key and the
/// [LogicalKeyboardKey.shift] key in the [WidgetsApp].
class PreviousFocusAction extends _RequestFocusActionBase {
  /// Creates a [PreviousFocusAction] with a fixed [key];
  PreviousFocusAction() : super(key);

  /// The [LocalKey] that uniquely identifies this action to an [Intent].
  static const LocalKey key = ValueKey<Type>(PreviousFocusAction);

  @override
  void invoke(FocusNode node, Intent intent) => node.previousFocus();
}

/// An [Intent] that represents moving to the next focusable node in the given
/// [direction].
///
/// This is the [Intent] bound by default to the [LogicalKeyboardKey.arrowUp],
/// [LogicalKeyboardKey.arrowDown], [LogicalKeyboardKey.arrowLeft], and
/// [LogicalKeyboardKey.arrowRight] keys in the [WidgetsApp], with the
/// appropriate associated directions.
class DirectionalFocusIntent extends Intent {
  /// Creates a [DirectionalFocusIntent] with a fixed [key], and the given
  /// [direction].
  const DirectionalFocusIntent(this.direction, {this.ignoreTextFields = true})
      : assert(ignoreTextFields != null),
        super(DirectionalFocusAction.key);

  /// The direction in which to look for the next focusable node when the
  /// associated [DirectionalFocusAction] is invoked.
  final TraversalDirection direction;

  /// If true, then directional focus actions that occur within a text field
  /// will not happen when the focus node which received the key is a text
  /// field.
  ///
  /// Defaults to true.
  final bool ignoreTextFields;
}

/// An [Action] that moves the focus to the focusable node in the direction
/// configured by the associated [DirectionalFocusIntent.direction].
///
/// This is the [Action] associated with the [key] and bound by default to the
/// [LogicalKeyboardKey.arrowUp], [LogicalKeyboardKey.arrowDown],
/// [LogicalKeyboardKey.arrowLeft], and [LogicalKeyboardKey.arrowRight] keys in
/// the [WidgetsApp], with the appropriate associated directions.
class DirectionalFocusAction extends _RequestFocusActionBase {
  /// Creates a [DirectionalFocusAction] with a fixed [key];
  DirectionalFocusAction() : super(key);

  /// The [LocalKey] that uniquely identifies this action to [DirectionalFocusIntent].
  static const LocalKey key = ValueKey<Type>(DirectionalFocusAction);

  @override
  void invoke(FocusNode node, DirectionalFocusIntent intent) {
    if (!intent.ignoreTextFields || node.context.widget is! EditableText) {
      node.focusInDirection(intent.direction);
    }
  }
}
