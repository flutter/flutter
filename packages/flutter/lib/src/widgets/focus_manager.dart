// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'focus_traversal.dart';
import 'framework.dart';

typedef FocusableNodeVisitor = bool Function(FocusNode node);

/// A node used by [Focusable] to represent and change the input focus.
///
/// A [FocusNode] is created and managed by the [Focusable] widget, forming
/// a tree of nodes that represent things that can be given the input focus in
/// the UI.
///
/// [FocusNode]s are persistent objects which are reparented and reorganized
/// when the widget tree is rebuilt.
///
/// The can be organized into "scopes", which form groups of nodes which are to
/// be traversed together. Within a scope, the last item to have focus is
/// remembered, and if another scope is focused and then the first is returned
/// to, that node will gain focus again.
class FocusNode with DiagnosticableTreeMixin, ChangeNotifier {
  /// Creates a Focusable node
  ///
  /// All parameters must not be null.
  FocusNode({
    bool isAutoFocus = false,
    this.debugLabel,
    this.context,
  })  : assert(isAutoFocus != null),
        _isAutoFocus = isAutoFocus;

  /// A debug label that used for diagnostic output.
  String debugLabel;

  FocusManager _manager;
  bool _hasKeyboardToken = false;

  /// True if this node will be selected as the initial focus when no other node
  /// in its scope is currently focused.
  ///
  /// There must only be one node in a scope that has [isAutoFocus] set.
  bool get isAutoFocus => _isAutoFocus;
  set isAutoFocus(bool value) {
    if (_isAutoFocus == value) {
      return;
    }
    _isAutoFocus = value;
    if (_isAutoFocus) {
      _debugCheckUniqueAutofocusNode(this);
      enclosingScope?._autofocusChild = this;
      _manager?._requestAutofocus(this);
    }
  }

  bool _isAutoFocus;

  /// Cancels any outstanding requests for focus.
  ///
  /// This method is safe to call regardless of whether this node has ever
  /// requested focus.
  void unfocus() {
    final FocusScopeNode scope = enclosingScope;
    if (scope == null) {
      return;
    }
    final bool hadFocus = scope._focusedChild == this;
    if (hadFocus) {
      scope._focusedChild = null;
    }
    if (scope._autofocusChild == this) {
      scope._autofocusChild = null;
    }
    _manager?._willUnfocusNode(this);
  }

  /// Removes the keyboard token from this focus node if it has one.
  ///
  /// This mechanism helps distinguish between an input control gaining focus by
  /// default and gaining focus as a result of an explicit user action.
  ///
  /// When a focus node requests the focus (either via
  /// [FocusScopeNode.requestFocus] or [FocusScopeNode.isAutoFocus]), the focus
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
  FocusNode get parent => _parent;
  FocusNode _parent;

  // Set to true if this focusable node changed, and needs to have its listeners
  // notified the next time the manager processes focus changes.
  void _markAsDirty() {
    _manager?._dirtyNodes?.add(this);
    _manager?._markNeedsUpdate();
  }

  final List<FocusNode> _children = <FocusNode>[];

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
  void removeChild(FocusNode node) {
    assert(_children.contains(node), "Tried to remove a node that wasn't a child.");
    // If this was the focused child for this scope, then unfocus it in that
    // scope.
    node.unfocus();

    node._parent = null;
    _children.remove(node);
  }

  // Updates the manager for all descendants to the given manager.
  void _updateManager(FocusManager manager) {
    for (FocusNode node in descendants) {
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
  void reparentIfNeeded(FocusNode child) {
    assert(child != null);
    assert(_manager == null || child != _manager.rootScope, "Can't reparent the root node");
    assert(!ancestors.contains(child), 'The supplied child is already an ancestor of this node. Inheritance loops are not allowed.');
    if (child._parent == this) {
      assert(_children.contains(child), "Found a node that says it's a child, but doesn't appear in the child list.");
      return;
    }
    FocusNode oldPrimaryFocus;
    if (child._manager != null) {
      oldPrimaryFocus = child.hasFocus ? child._manager._currentFocus : null;
      assert(oldPrimaryFocus == null || oldPrimaryFocus == child || oldPrimaryFocus.ancestors.contains(child), "child has focus, but primary focus isn't a descendant of it for some reason");
    }
    Set<FocusNode> oldFocusPath = <FocusNode>{};
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
    final FocusScopeNode scope = child.enclosingScope;
    scope._focusedChild ??= child.isAutoFocus ? child : null;
    if (child.isAutoFocus) {
      scope._autofocusChild = child;
    }
    if (oldPrimaryFocus != null) {
      final Set<FocusNode> newFocusPath = _manager?._currentFocus?.ancestors?.toSet() ?? <FocusNode>{};
      // Nodes that will no longer be focused need to be marked dirty.
      for (FocusNode node in oldFocusPath.difference(newFocusPath)) {
        node._markAsDirty();
      }
      // If the node used to have focus, make sure it keeps it's old primary
      // focus when it moves.
      oldPrimaryFocus.requestFocus();
    } else if (child.isAutoFocus) {
      _debugCheckUniqueAutofocusNode(child);
      _manager._requestAutofocus(child);
    }
  }

  /// A debug method to find the autofocus nodes in the nodes in the same scope
  /// as the given [node], and if there exists more than one, assert.
  ///
  /// Does not descend into scope nodes, because they could have their own
  /// separate autofocus node.
  void _debugCheckUniqueAutofocusNode(FocusNode node) {
    assert(() {
      final FocusNode enclosingScope = node.enclosingScope;
      final List<FocusNode> autofocusNodes = enclosingScope?.descendants?.where((FocusNode descendant) {
        return descendant.enclosingScope == enclosingScope && descendant.isAutoFocus;
      })?.toList() ?? const <FocusNode>[];
      return autofocusNodes.length <= 1;
    }(), 'More than one autofocus node was found in the descendants of scope ${node.enclosingScope}, which is not allowed.');
  }

  /// An iterator over the children of this node.
  Iterable<FocusNode> get children => _children;

  /// An iterator over the hierarchy of children below this one, in depth first
  /// order.
  Iterable<FocusNode> get descendants sync* {
    for (FocusNode child in _children) {
      yield* child.descendants;
      yield child;
    }
  }

  /// An iterator over the ancestors of this node.
  Iterable<FocusNode> get ancestors sync* {
    FocusNode parent = _parent;
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
    for (FocusNode child in _children) {
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
  void requestFocus([FocusNode node]) {
    if (node != null) {
      // If an argument was given, then it expects to be a child of this node,
      // and have the focus given to it.  Reparent the node and then request
      // focus on it.
      reparentIfNeeded(node);
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
  /// A [FocusNode] has the overall focus when the node is focused in its
  /// parent [FocusScopeNode] and [FocusScopeNode.hasFocus] is true for
  /// that scope and all its ancestor scopes.
  ///
  /// To request focus, find the [FocusScopeNode] for the current [BuildContext]
  /// and call the [FocusScopeNode.requestFocus] method:
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
  FocusScopeNode get nearestScope => enclosingScope;

  /// Returns the nearest enclosing scope node above this node, or null if none
  /// is found. If this node is itself a scope, this will only return ancestors
  /// of this scope.
  FocusScopeNode get enclosingScope {
    return ancestors.firstWhere((FocusNode node) => node is FocusScopeNode, orElse: () => null);
  }

  // Sets this node as the focused child for the enclosing scope, and that scope
  // as focused child for the scope above it, etc., until it reaches the root
  // node.
  void _setAsFocusedChild() {
    FocusNode scopeFocus = this;
    for (FocusNode ancestor in ancestors) {
      if (ancestor is FocusScopeNode) {
        assert(scopeFocus != ancestor, "Somehow made a loop by setting focusedChild to it's scope.");
        ancestor._focusedChild = scopeFocus;
        scopeFocus = ancestor;
      }
    }
  }

  /// Request that the widget move the focus to the next focusable node, by
  /// calling the [FocusTraversalPolicy.next] function.
  bool nextFocus() => context != null ? DefaultFocusTraversal.of(context).next(this) : false;

  /// Request that the widget move the focus to the previous focusable node, by
  /// calling the [FocusTraversalPolicy.previous] function.
  bool previousFocus() => context != null ? DefaultFocusTraversal.of(context).previous(this) : false;

  /// Request that the widget move the focus to the previous focusable node, by
  /// calling the [FocusTraversalPolicy.inDirection] function.
  bool focusInDirection(AxisDirection direction) => context != null ? DefaultFocusTraversal.of(context).inDirection(this, direction) : false;

  /// Returns the size of the associated [Focusable] in logical units.
  Size get size => context?.findRenderObject()?.semanticBounds?.size ?? Size.zero;

  /// Returns the global offset to the upper left corner of the [Focusable] in
  /// logical units.
  Offset get offset {
    final RenderObject object = context?.findRenderObject();
    if (object == null) {
      return Offset.zero;
    }
    return MatrixUtils.transformPoint(object.getTransformTo(null), object.semanticBounds.topLeft);
  }

  /// Returns the global rectangle surrounding the node in logical units.
  Rect get rect {
    final RenderObject object = context?.findRenderObject();
    if (object == null) {
      return Rect.zero;
    }
    final Offset globalOffset = MatrixUtils.transformPoint(object.getTransformTo(null), object.semanticBounds.topLeft);
    return globalOffset & object.semanticBounds.size;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BuildContext>('context', context, defaultValue: null));
    properties.add(FlagProperty('isAutoFocus', value: isAutoFocus, ifTrue: 'AUTOFOCUS', defaultValue: false));
    properties.add(FlagProperty('hasFocus', value: hasFocus, ifTrue: 'FOCUSED', defaultValue: false));
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    int count = 1;
    for (FocusNode child in _children) {
      children.add(child.toDiagnosticsNode(name: 'child $count'));
      ++count;
    }
    return children;
  }
}

/// A [FocusNode] subclass that acts as a scope for its descendants,
/// maintaining state about which descendant was last or is currently focused.
class FocusScopeNode extends FocusNode {
  /// Creates a FocusableScope node
  ///
  /// All parameters must not be null.
  FocusScopeNode({
    bool isAutoFocus = false,
    BuildContext context,
    String debugLabel,
  })  : assert(isAutoFocus != null),
        super(context: context, isAutoFocus: isAutoFocus, debugLabel: debugLabel);

  @override
  FocusScopeNode get nearestScope => this;

  @override
  void reparentIfNeeded(FocusNode child) {
    final FocusScopeNode previousEnclosingScope = child.enclosingScope;
    super.reparentIfNeeded(child);
    final FocusScopeNode currentEnclosingScope = child.enclosingScope;
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
  void setFirstFocus(FocusScopeNode node) {
    reparentIfNeeded(node);
    _focusedChild = node;
  }

  /// If this scope lacks a focus, reparent the node as a child of this one, and
  /// request that the given node becomes the focus.
  ///
  /// Useful for widgets that wish to grab the focus if no other widget already
  /// has the focus.
  ///
  /// The node is notified that it has received the overall focus in a
  /// microtask.
  void autofocus(FocusNode node) {
    if (_focusedChild == null) {
      reparentIfNeeded(node);
      node.requestFocus();
    }
  }

  /// Returns the child of this node which should receive focus if this scope
  /// node receives focus.
  ///
  /// If [hasFocus] is true, then this points to the child of this node which is
  /// currently focused.
  ///
  /// Returns null if there is no currently focused child.
  FocusNode get focusedChild {
    assert(_focusedChild == null || _focusedChild.enclosingScope == this, 'Focused child does not have the same idea of its enclosing scope as the scope does.');
    return _focusedChild;
  }

  FocusNode _focusedChild;

  FocusNode _autofocusChild;

  @override
  void _doRequestFocus(bool isFromPolicy) {
    assert(isFromPolicy != null);
    assert(_manager != null, "Tried to request focus for a node that isn't part of the focus tree.");
    // Set the focus to the focused child of this scope, if it is one. Otherwise
    // start with setting the focus to this node itself.
    FocusNode primaryFocus = focusedChild ?? this;
    // Keep going down through scopes until the ultimately focusable item is
    // found, a scope doesn't have a focusedChild, or a non-scope is
    // encountered.
    while (primaryFocus is FocusScopeNode && primaryFocus.focusedChild != null) {
      final FocusScopeNode scope = primaryFocus;
      primaryFocus = scope.focusedChild;
    }
    if (primaryFocus is FocusScopeNode) {
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
    properties.add(DiagnosticsProperty<FocusNode>('focusedChild', focusedChild, defaultValue: null));
  }
}

/// Manages the focus tree.
///
/// The focus tree keeps track of which [FocusNode] is the user's current
/// keyboard focus. The widget that owns the [FocusNode] often listens for
/// keyboard events.
///
/// The focus manager is responsible for holding the [FocusScopeNode] that is
/// the root of the focus tree and tracking which [FocusNode] has the overall
/// focus.
///
/// The [FocusManager] is held by the [WidgetsBinding] as
/// [WidgetsBinding.focusManager]. The [FocusManager] is rarely accessed
/// directly. Instead, to find the [FocusScopeNode] for a given [BuildContext],
/// use [FocusScope.of].
///
/// The [FocusManager] knows nothing about [FocusNode]s other than the one that
/// is currently focused. If a [FocusScopeNode] is removed, then the
/// [FocusManager] will attempt to focus the next [FocusScopeNode] in the focus
/// tree that it maintains, but if the current focus in that [FocusScopeNode] is
/// null, it will stop there, and no [FocusNode] will have focus.
///
/// See also:
///
///  * [FocusNode], which is a leaf node in the focus tree that can receive
///    focus.
///  * [FocusScopeNode], which is an interior node in the focus tree.
///  * [FocusScope.of], which provides the [FocusScopeNode] for a given
///    [BuildContext].
class FocusManager with DiagnosticableTreeMixin {
  /// Creates an object that manages the focus tree.
  ///
  /// This constructor is rarely called directly. To access the [FocusManager],
  /// consider using [WidgetsBinding.focusManager] instead.
  FocusManager() {
    rootScope._manager = this;
  }

  /// Resets the FocusManager to a base state.
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

    for (FocusNode descendant in rootScope.descendants.toList()) {
      descendant.detach();
    }

    rootScope.clear();
    rootScope._manager = this;
  }

  /// The root [FocusNode] in the focus tree.
  ///
  /// This field is rarely used directly. Instead, to find the nearest
  /// [FocusNode] for a given [BuildContext], use [Focusable.of].
  ///
  /// To find the nearest [FocusNode] that corresponds to a
  /// [Focusable], use [Focusable.of].
  final FocusScopeNode rootScope = FocusScopeNode(debugLabel: 'Root Focus Scope');

  // The entire focus path, except for the rootFocusable, which is implicitly
  // at the beginning of the list.  The last element should correspond with
  // _currentFocus;
  FocusNode _currentFocus;
  FocusNode _nextFocus;
  FocusNode _nextAutofocus;
  final Set<FocusNode> _dirtyNodes = <FocusNode>{};

  void _willDisposeFocusNode(FocusNode node) {
    assert(node != null);
    _willUnfocusNode(node);
  }

  void _willUnfocusNode(FocusNode node) {
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
  void _markNeedsUpdate({FocusNode newFocus}) {
    // If newFocus isn't specified, then don't mess with _nextFocus, just
    // schedule the update.
    _nextFocus = newFocus ?? _nextFocus;
    if (_haveScheduledUpdate) {
      return;
    }
    _haveScheduledUpdate = true;
    scheduleMicrotask(_applyFocusChange);
  }

  void _requestAutofocus(FocusNode node) {
    _nextAutofocus = node;
    _markNeedsUpdate();
  }

  void _applyFocusChange() {
    _haveScheduledUpdate = false;
    final FocusNode previousFocus = _currentFocus;
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
      final Set<FocusNode> previousPath = previousFocus?.ancestors?.toSet() ?? <FocusNode>{};
      final Set<FocusNode> nextPath = _nextFocus.ancestors.toSet();
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
    for (FocusNode node in _dirtyNodes) {
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
