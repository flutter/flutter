// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'focus_traversal.dart';
import 'framework.dart';

typedef FocusableNodeVisitor = bool Function(FocusableNode node);

/// A node used by [Focusable] to represent and change the input focus.
///
/// A [FocusableNode] is created and managed by the [Focusable] widget, forming
/// a tree of nodes that represent things that can be given the input focus in
/// the UI.
///
/// [FocusableNode]s are persistent objects which are reparented and reorganized
/// when the widget tree is rebuilt.
///
/// The can be organized into "scopes", which form groups of nodes which are to
/// be traversed together. Within a scope, the last item to have focus is
/// remembered, and if another scope is focused and then the first is returned
/// to, that node will gain focus again.
class FocusableNode with DiagnosticableTreeMixin, ChangeNotifier {
  /// Creates a Focusable node
  ///
  /// All parameters must not be null.
  FocusableNode({
    bool autofocus = false,
    this.debugLabel,
    this.context,
  })  : assert(autofocus != null),
        _autofocus = autofocus;

  /// A debug label that used for diagnostic output.
  String debugLabel;

  FocusableManager _manager;
  bool _hasKeyboardToken = false;

  /// True if this node will be selected as the initial focus when no other node
  /// in its scope is currently focused.
  ///
  /// There must only be one node in a scope that has [autofocus] set.
  bool get autofocus => _autofocus;
  set autofocus(bool value) {
    if (_autofocus == value) {
      return;
    }
    _autofocus = value;
    if (_autofocus) {
      _debugCheckUniqueAutofocusNode(this);
      _manager._requestAutofocus(this);
    }
  }
  bool _autofocus;

  /// Cancels any outstanding requests for focus.
  ///
  /// This method is safe to call regardless of whether this node has ever
  /// requested focus.
  void unfocus() {
    final FocusableScopeNode scope = enclosingScope;
    if (scope == null) {
      return;
    }
    if (scope._focusedChild == this) {
      scope._focusedChild = null;
    }
    _manager?._willUnfocusNode(this);
  }

  /// Removes the keyboard token from this focus node if it has one.
  ///
  /// This mechanism helps distinguish between an input control gaining focus by
  /// default and gaining focus as a result of an explicit user action.
  ///
  /// When a focus node requests the focus (either via
  /// [FocusableScopeNode.requestFocus] or [FocusableScopeNode.autofocus]), the focus
  /// node receives a keyboard token if it does not already have one. Later,
  /// when the focus node becomes focused, the widget that manages the
  /// [TextInputConnection] should show the keyboard (i.e., call
  /// [TextInputConnection.show]) only if it successfully consumes the keyboard
  /// token from the focus node.
  ///
  /// Returns whether this function successfully consumes a keyboard token.
  bool consumeKeyboardToken() {
    if (!_hasKeyboardToken) {
      return false;
    }
    _hasKeyboardToken = false;
    return true;
  }

  /// The context from the [InheritedWidget] associated with this node.
  ///
  /// This is not the [Focusable] or [FocusScope] itself, but is a child of a
  /// [Focusable] or [FocusScope], and it has the same dimensions.
  BuildContext context;

  /// Returns the parent node for this object.
  FocusableNode get parent => _parent;
  FocusableNode _parent;

  // Set to true if this focusable node changed, and needs to have its listeners
  // notified the next time the manager processes focus changes.
  void _markAsDirty() {
    _manager?._dirtyNodes?.add(this);
    _manager?._markNeedsUpdate();
  }

  final List<FocusableNode> _children = <FocusableNode>[];

  /// Resets this node back to a base configuration.
  ///
  /// This is only used by tests to clear the root node. Do not call in other
  /// contexts, as it doesn't properly detach children.
  @visibleForTesting
  @mustCallSuper
  void clear() {
    if (_manager != null) {
      _manager._dirtyNodes.remove(this);
    }
    _manager = null;
    _parent = null;
    _children.clear();
  }

  /// Removes the given FocusableNode and its children as a child of this node.
  @mustCallSuper
  void removeChild(FocusableNode node) {
    assert(_children.contains(node), "Tried to remove a node that wasn't a child.");
    // If this was the focused child for this scope, then unfocus it in that
    // scope.
    node.unfocus();

    node._parent = null;
    _children.remove(node);
  }

  // Updates the manager for all descendants to the given manager.
  void _updateManager(FocusableManager manager) {
    for (FocusableNode node in descendants) {
      node._manager = manager;
    }
    _manager = manager;
  }

  /// Moves the given node to be a child of this node.
  ///
  /// Called whenever the associated widget is rebuilt in order to maintain the
  /// focus hierarchy.
  ///
  /// A widget that manages focus should call this method on the node it owns
  /// during its `build` method in case the widget is moved from one location
  /// in the tree to another location that has a different focus scope.
  @mustCallSuper
  void reparent(FocusableNode child) {
    assert(child != null);
    assert(_manager == null || child != _manager.rootScope, "Can't reparent the root node");
    assert(!ancestors.contains(child), 'The supplied child is already an ancestor of this node. Inheritance loops are not allowed.');
    if (child._parent == this) {
      assert(_children.contains(child), "Found a node that says it's a child, but doesn't appear in the child list.");
      return;
    }
    FocusableNode oldPrimaryFocus;
    if (child._manager != null) {
      oldPrimaryFocus = child.hasFocus ? child._manager._currentFocus : null;
      assert(oldPrimaryFocus == null || oldPrimaryFocus == child || oldPrimaryFocus.ancestors.contains(child), "child has focus, but primary focus isn't a descendant of it for some reason");
    }
    Set<FocusableNode> oldFocusPath = <FocusableNode>{};
    if (oldPrimaryFocus != null) {
      // The child currently has focus, so we have to do some extra work to keep
      // that focus, and to notify any scopes that used to be ancestors, and no
      // longer have focus after we move it.
      oldFocusPath = oldPrimaryFocus.ancestors.toSet();
    }
    child.detach();
    _children.add(child);
    child._parent = this;
    child._updateManager(_manager);
    // If this child is an autofocus node, then set that as the focused child
    // in its scope.
    child.enclosingScope._focusedChild ??= child.autofocus ? child : null;
    if (oldPrimaryFocus != null) {
      final Set<FocusableNode> newFocusPath = _manager?._currentFocus?.ancestors?.toSet() ?? <FocusableNode>{};
      // Nodes that will no longer be focused need to be marked dirty.
      for (FocusableNode node in oldFocusPath.difference(newFocusPath)) {
        node._markAsDirty();
      }
      // If the node used to have focus, make sure it keeps it's old primary
      // focus when it moves.
      oldPrimaryFocus.requestFocus();
    } else if (child.autofocus) {
      _debugCheckUniqueAutofocusNode(child);
      _manager._requestAutofocus(child);
    }
  }

  /// A debug method to find the autofocus nodes in the nodes in the same scope
  /// as the given [node], and if there exists more than one, assert.
  ///
  /// Does not descend into scope nodes, because they could have their own
  /// separate autofocus node.
  void _debugCheckUniqueAutofocusNode(FocusableNode node) {
    assert(() {
      final FocusableNode enclosingScope = node.enclosingScope;
      final List<FocusableNode> autofocusNodes = enclosingScope.descendants.where((FocusableNode descendant) {
        return descendant.enclosingScope == enclosingScope && descendant.autofocus;
      }).toList();
      return autofocusNodes.length <= 1;
    }(), 'More than one autofocus node was found in the descendants of scope ${node.enclosingScope}, which is not allowed.');
  }

  /// An iterator over the children of this node.
  Iterable<FocusableNode> get children => _children;

  /// An iterator over the hierarchy of children below this one, in depth first
  /// order.
  Iterable<FocusableNode> get descendants sync* {
    for (FocusableNode child in _children) {
      yield* child.descendants;
      yield child;
    }
  }

  /// An iterator over the ancestors of this node.
  Iterable<FocusableNode> get ancestors sync* {
    FocusableNode parent = _parent;
    while (parent != null) {
      yield parent;
      parent = parent._parent;
    }
  }

  /// Allows a function to be run on each child of this node.
  ///
  /// If the callback returns false, it terminates the traversal. Returns true
  /// if all child nodes were visited, and false if terminated early.
  bool visitChildren(FocusableNodeVisitor callback) {
    for (FocusableNode child in _children) {
      if (!callback(child)) {
        return false;
      }
    }
    return true;
  }

  /// Detach from the parent.
  @mustCallSuper
  void detach() => parent?.removeChild(this);

  @mustCallSuper
  void _notify() {
    if (hasPrimaryFocus) {
      _setAsFocusedChild();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _manager?._willDisposeFocusNode(this);
    detach();
    super.dispose();
  }

  /// Requests that this node is focused from a [FocusTraversalPolicy].
  ///
  /// The only difference between this and [requestFocus] is that the policy data
  /// is not cleared.
  void requestFocusFromPolicy() {
    _doRequestFocus(true);
  }

  /// Requests that this node and every parent of this node gets focus.
  ///
  /// If this node is a scope, and there is a current [focusedChild], then focus
  /// that node instead.  If that node is also a scope, will look for its
  /// [focusedChild], and so forth, until a non-scope, or a scope with a null
  /// [focusedChild] is found.
  ///
  /// Call [requestFocusFromPolicy] instead if you are requesting focus from
  /// within a focus policy in order to keep the policy data for future use.
  ///
  /// Calling this will clear the [policyData] for the enclosing scope.
  void requestFocus([FocusableNode node]) {
    if (node != null) {
      // If an argument was given, then it expects to be a child of this node,
      // and have the focus given to it.  Reparent the node and then request
      // focus on it.
      reparent(node);
      node.requestFocus();
      return;
    }
    _doRequestFocus(false);
  }

  void _doRequestFocus(bool isFromPolicy) {
    assert(isFromPolicy != null);
    assert(_manager != null, "Tried to request focus for a node that isn't part of the focus tree.");
    if (!isFromPolicy) {
      enclosingScope?.policyData = null;
    }
    _manager._markNeedsUpdate(newFocus: this);
  }

  /// Whether this node has focus.
  ///
  /// A [FocusableNode] has the overall focus when the node is focused in its
  /// parent [FocusableScopeNode] and [FocusableScopeNode.hasFocus] is true for
  /// that scope and all its ancestor scopes.
  ///
  /// To request focus, find the [FocusableScopeNode] for the current [BuildContext]
  /// and call the [FocusableScopeNode.requestFocus] method:
  ///
  /// ```dart
  /// FocusScope.of(context).requestFocus(focusNode);
  /// ```
  ///
  /// This object notifies its listeners whenever this value changes.
  bool get hasFocus {
    if (_manager?._currentFocus == null) {
      return false;
    }
    if (hasPrimaryFocus) {
      return true;
    }
    if (_manager._currentFocus == this) {
      return true;
    }
    return _manager._currentFocus.ancestors.contains(this);
  }

  /// Returns true if this node currently has the application-wide focus.
  ///
  /// This is different from [hasFocus] in that [hasFocus] is true if the node
  /// is anywhere in the focus chain, but here the node has to be at the end of
  /// the chain to return true.
  bool get hasPrimaryFocus {
    assert(_manager != null);
    return this == _manager._currentFocus;
  }

  /// Returns the nearest enclosing scope node above this node, including
  /// this node, if it's a scope. Returns null if no scope is found.
  FocusableScopeNode get nearestScope => enclosingScope;

  /// Returns the nearest enclosing scope node above this node, or null if none
  /// is found. If this node is itself a scope, this will only return ancestors
  /// of this scope.
  FocusableScopeNode get enclosingScope {
    return ancestors.firstWhere((FocusableNode node) => node is FocusableScopeNode, orElse: () => null);
  }

  // Sets this node as the focused child for the enclosing scope, and that scope
  // as focused child for the scope above it, etc., until it reaches the root
  // node.
  void _setAsFocusedChild() {
    FocusableNode scopeFocus = this;
    for (FocusableNode ancestor in ancestors) {
      if (ancestor is FocusableScopeNode) {
        assert(scopeFocus != ancestor, "Somehow made a loop by setting focusedChild to it's scope.");
        ancestor._focusedChild = scopeFocus;
        scopeFocus = ancestor;
      }
    }
  }

  /// Request that the widget move the focus to the next focusable node, by
  /// calling the [FocusTraversalPolicy.next] function.
  bool nextFocus() => DefaultFocusTraversal.of(context).next(this);

  /// Request that the widget move the focus to the previous focusable node, by
  /// calling the [FocusTraversalPolicy.previous] function.
  bool previousFocus() => DefaultFocusTraversal.of(context).previous(this);

  /// Request that the widget move the focus to the previous focusable node, by
  /// calling the [FocusTraversalPolicy.inDirection] function.
  bool focusInDirection(AxisDirection direction) => DefaultFocusTraversal.of(context).inDirection(this, direction);

  /// Returns the size of the associated [Focusable] in logical units.
  Size get size => context.size;

  /// Returns the global offset to the upper left corner of the [Focusable] in
  /// logical units.
  Offset get offset {
    final RenderObject object = context.findRenderObject();
    return MatrixUtils.transformPoint(object.getTransformTo(null), Offset.zero);
  }

  /// Returns the global rectangle surrounding the node in logical units.
  Rect get rect => offset & size;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BuildContext>('context', context, defaultValue: null));
    properties.add(FlagProperty('hasFocus', value: hasFocus, ifTrue: 'FOCUSED', defaultValue: false));
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    int count = 1;
    for (FocusableNode child in _children) {
      children.add(child.toDiagnosticsNode(name: 'child $count'));
      ++count;
    }
    return children;
  }
}

/// A [FocusableNode] subclass that acts as a scope for its descendants,
/// maintaining state about which descendant was last or is currently focused.
class FocusableScopeNode extends FocusableNode {
  /// Creates a FocusableScope node
  ///
  /// All parameters must not be null.
  FocusableScopeNode({
    bool autofocus = false,
    BuildContext context,
    String debugLabel,
  })  : assert(autofocus != null),
        super(context: context, autofocus: autofocus, debugLabel: debugLabel);

  @override
  FocusableScopeNode get nearestScope => this;

  @override
  void reparent(FocusableNode child) {
    final FocusableScopeNode previousEnclosingScope = child.enclosingScope;
    super.reparent(child);
    final FocusableScopeNode currentEnclosingScope = child.enclosingScope;
    // If the child moved scopes, then the policy data is invalid.
    if (previousEnclosingScope != currentEnclosingScope) {
      policyData = null;
    }
  }

  /// Deprecated way to find out if this scope has focus.
  ///
  /// Use [hasFocus] instead.
  bool get isFirstFocus => hasFocus;

  /// Add the given node as a child of this focus scope, and make it be the
  /// [focusedChild].
  void setFirstFocus(FocusableScopeNode node) {
    reparent(node);
    _focusedChild = node;
  }

  /// Returns the child of this node which should receive focus if this scope
  /// node receives focus.
  ///
  /// If [hasFocus] is true, then this points to the child of this node which is
  /// currently focused.
  ///
  /// Returns null if there is no currently focused child.
  FocusableNode get focusedChild {
    assert(_focusedChild == null || _focusedChild.enclosingScope == this, 'Focused child does not have the same idea of its enclosing scope as the scope does.');
    return _focusedChild;
  }

  FocusableNode _focusedChild;

  @override
  void _doRequestFocus(bool isFromPolicy) {
    assert(isFromPolicy != null);
    assert(_manager != null, "Tried to request focus for a node that isn't part of the focus tree.");
    // Set the focus to the focused child of this scope, if it is one. Otherwise
    // start with setting the focus to this node itself.
    FocusableNode primaryFocus = focusedChild ?? this;
    // Keep going down through scopes until the ultimately focusable item is
    // found, a scope doesn't have a focusedChild, or a non-scope is
    // encountered.
    while (primaryFocus is FocusableScopeNode && primaryFocus.focusedChild != null) {
      final FocusableScopeNode scope = primaryFocus;
      primaryFocus = scope.focusedChild;
    }
    if (primaryFocus is FocusableScopeNode) {
      if (!isFromPolicy) {
        primaryFocus.policyData = null;
      }
      _manager._markNeedsUpdate(newFocus: primaryFocus);
    } else {
      if (isFromPolicy) {
        primaryFocus.requestFocusFromPolicy();
      } else {
        primaryFocus.requestFocus();
      }
    }
  }

  /// Holds the [PolicyData] used by the scope's [FocusTraversalPolicy].
  ///
  /// This is set on scope nodes by the traversal policy to keep data that it
  /// may need later.  For instance, the last focused node in a direction is
  /// kept here so that directional navigation can avoid hysteresis when
  /// returning in the direction it just came from.
  ///
  /// This data will be cleared if the node moves to another scope.
  Object policyData;

  @visibleForTesting
  @override
  void clear() {
    super.clear();
    _focusedChild = null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusableNode>('focusedChild', focusedChild, defaultValue: null));
  }
}

/// Manages the focus tree.
///
/// The focus tree keeps track of which [FocusableNode] is the user's current
/// keyboard focus. The widget that owns the [FocusableNode] often listens for
/// keyboard events.
///
/// The focus manager is responsible for holding the [FocusableScopeNode] that is
/// the root of the focus tree and tracking which [FocusableNode] has the overall
/// focus.
///
/// The [FocusableManager] is held by the [WidgetsBinding] as
/// [WidgetsBinding.focusManager]. The [FocusableManager] is rarely accessed
/// directly. Instead, to find the [FocusableScopeNode] for a given [BuildContext],
/// use [FocusScope.of].
///
/// The [FocusableManager] knows nothing about [FocusableNode]s other than the one that
/// is currently focused. If a [FocusableScopeNode] is removed, then the
/// [FocusableManager] will attempt to focus the next [FocusableScopeNode] in the focus
/// tree that it maintains, but if the current focus in that [FocusableScopeNode] is
/// null, it will stop there, and no [FocusableNode] will have focus.
///
/// See also:
///
///  * [FocusableNode], which is a leaf node in the focus tree that can receive
///    focus.
///  * [FocusableScopeNode], which is an interior node in the focus tree.
///  * [FocusScope.of], which provides the [FocusableScopeNode] for a given
///    [BuildContext].
class FocusableManager with DiagnosticableTreeMixin {
  /// Creates an object that manages the focus tree.
  ///
  /// This constructor is rarely called directly. To access the [FocusableManager],
  /// consider using [WidgetsBinding.focusManager] instead.
  FocusableManager() {
    rootScope._manager = this;
  }

  /// Resets the [FocusableManager] to a base state.
  ///
  /// This is used by test routines to reset the state between tests.
  ///
  /// Do not call this except from a test, since it doesn't gracefully remove
  /// child nodes.
  @visibleForTesting
  void reset() {
    _currentFocus = null;
    _nextFocus = null;
    _haveScheduledUpdate = false;

    for (FocusableNode descendant in rootScope.descendants.toList()) {
      descendant.detach();
    }

    rootScope.clear();
    rootScope._manager = this;
  }

  /// The root [FocusableNode] in the focus tree.
  ///
  /// This field is rarely used directly. Instead, to find the nearest
  /// [FocusableNode] for a given [BuildContext], use [Focusable.of].
  ///
  /// To find the nearest [FocusableNode] that corresponds to a
  /// [Focusable], use [Focusable.of].
  final FocusableScopeNode rootScope = FocusableScopeNode(debugLabel: 'Root Focus Scope');

  // The entire focus path, except for the rootFocusable, which is implicitly
  // at the beginning of the list.  The last element should correspond with
  // _currentFocus;
  FocusableNode _currentFocus;
  FocusableNode _nextFocus;
  FocusableNode _nextAutofocus;
  final Set<FocusableNode> _dirtyNodes = <FocusableNode>{};

  void _willDisposeFocusNode(FocusableNode node) {
    assert(node != null);
    _willUnfocusNode(node);
  }

  void _willUnfocusNode(FocusableNode node) {
    assert(node != null);
    if (_currentFocus == node) {
      _currentFocus = null;
    }
    if (_nextAutofocus == node) {
      _nextAutofocus = null;
    }
    if (_nextFocus == node) {
      _nextFocus = null;
    }
    _dirtyNodes.remove(node);
  }

  bool _haveScheduledUpdate = false;
  void _markNeedsUpdate({FocusableNode newFocus}) {
    // If newFocus isn't specified, then don't mess with _nextFocus, just
    // schedule the update.
    _nextFocus = newFocus ?? _nextFocus;
    if (_haveScheduledUpdate) {
      return;
    }
    _haveScheduledUpdate = true;
    scheduleMicrotask(_applyFocusChange);
  }

  void _requestAutofocus(FocusableNode node) {
    _nextAutofocus = node;
    _markNeedsUpdate();
  }

  void _applyFocusChange() {
    _haveScheduledUpdate = false;
    final FocusableNode previousFocus = _currentFocus;
    if (_nextAutofocus != null) {
      // If a child with autofocus was re-parented, and we don't have any focus
      // or pending focus set, then use that as the focus.
      if (_nextFocus == null && _currentFocus == null) {
        _nextFocus = _nextAutofocus;
      }
      _nextAutofocus = null;
    }
    if (_nextFocus != null && _nextFocus != _currentFocus) {
      // Even if the _currentFocus hasn't changed, it may have changed where it
      // was in the tree, so we have to make sure we update and notify.
      _currentFocus = _nextFocus;
      final Set<FocusableNode> previousPath = previousFocus?.ancestors?.toSet() ?? <FocusableNode>{};
      final Set<FocusableNode> nextPath = _nextFocus.ancestors.toSet();
      // Notify nodes that are newly focused.
      _dirtyNodes.addAll(nextPath.difference(previousPath));
      // Notify nodes that are no longer focused
      _dirtyNodes.addAll(previousPath.difference(nextPath));
      _nextFocus = null;
    }
    if (previousFocus != null) {
      _dirtyNodes.add(previousFocus);
    }
    if (_currentFocus != null) {
      _dirtyNodes.add(_currentFocus);
    }
    for (FocusableNode node in _dirtyNodes) {
      node._notify();
    }
    _dirtyNodes.clear();
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      rootScope.toDiagnosticsNode(name: 'rootFocusScope'),
    ];
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    final String status = _haveScheduledUpdate ? ' UPDATE SCHEDULED' : '';
    const String indent = '  ';
    return '${describeIdentity(this)}$status\n'
        '${indent}currentFocus: $_currentFocus\n'
        '${rootScope.toStringDeep(prefixLineOne: indent, prefixOtherLines: indent)}';
  }
}
