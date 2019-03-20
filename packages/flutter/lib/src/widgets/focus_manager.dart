// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'focus_scope.dart';
import 'focus_traversal.dart';
import 'framework.dart';

/// A leaf node in the focus tree that can receive focus.
///
/// The focus tree keeps track of which widget is the user's current focus. The
/// focused widget often listens for keyboard events.
///
/// To request focus, find the [FocusScopeNode] for the current [BuildContext]
/// and call the [FocusScopeNode.requestFocus] method:
///
/// ```dart
/// FocusScope.of(context).requestFocus(focusNode);
/// ```
///
/// If your widget requests focus, be sure to call
/// `FocusScope.of(context).reparentIfNeeded(focusNode);` in your `build`
/// method to reparent your [FocusNode] if your widget moves from one
/// location in the tree to another.
///
/// ## Lifetime
///
/// Focus nodes are long-lived objects. For example, if a stateful widget has a
/// focusable child widget, it should create a [FocusNode] in the
/// [State.initState] method, and [dispose] it in the [State.dispose] method,
/// providing the same [FocusNode] to the focusable child each time the
/// [State.build] method is run. In particular, creating a [FocusNode] each time
/// [State.build] is invoked will cause the focus to be lost each time the
/// widget is built.
///
/// See also:
///
///  * [FocusScopeNode], which is an interior node in the focus tree.
///  * [FocusScope.of], which provides the [FocusScopeNode] for a given
///    [BuildContext].
class FocusNode extends Diagnosticable with ChangeNotifier {
  FocusScopeNode _scopeParent;
  FocusManager _manager;
  bool _hasKeyboardToken = false;

  /// Whether this node has the overall focus.
  ///
  /// A [FocusNode] has the overall focus when the node is focused in its
  /// parent [FocusScopeNode] and [FocusScopeNode.isFirstFocus] is true for
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
  bool get hasFocus => _manager?._currentFocus == this;

  /// Removes the keyboard token from this focus node if it has one.
  ///
  /// This mechanism helps distinguish between an input control gaining focus by
  /// default and gaining focus as a result of an explicit user action.
  ///
  /// When a focus node requests the focus (either via
  /// [FocusScopeNode.requestFocus] or [FocusScopeNode.autofocus]), the focus
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

  /// Cancels any outstanding requests for focus.
  ///
  /// This method is safe to call regardless of whether this node has ever
  /// requested focus.
  void unfocus() {
    _scopeParent?._resignFocus(this);
    assert(_scopeParent == null);
    assert(_manager == null);
  }

  @override
  void dispose() {
    _manager?._willDisposeFocusNode(this);
    _scopeParent?._resignFocus(this);
    super.dispose();
  }

  @mustCallSuper
  void _notify() {
    notifyListeners();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('hasFocus', value: hasFocus, ifTrue: 'FOCUSED', defaultValue: false));
  }
}

/// An interior node in the focus tree.
///
/// The focus tree keeps track of which widget is the user's current focus. The
/// focused widget often listens for keyboard events.
///
/// The interior nodes in the focus tree cannot themselves be focused but
/// instead remember previous focus states. A scope is currently active in its
/// parent whenever [isFirstFocus] is true. If that scope is detached from its
/// parent, its previous sibling becomes the parent's first focus.
///
/// A [FocusNode] has the overall focus when the node is focused in its
/// parent [FocusScopeNode] and [FocusScopeNode.isFirstFocus] is true for
/// that scope and all its ancestor scopes.
///
/// If a [FocusScopeNode] is removed, then the next sibling node will be set as
/// the focused node by the [FocusManager].
///
/// See also:
///
///  * [FocusNode], which is a leaf node in the focus tree that can receive
///    focus.
///  * [FocusScope.of], which provides the [FocusScopeNode] for a given
///    [BuildContext].
///  * [FocusScope], which is a widget that associates a [FocusScopeNode] with
///    its location in the tree.
class FocusScopeNode extends Object with DiagnosticableTreeMixin {
  FocusManager _manager;
  FocusScopeNode _parent;

  FocusScopeNode _nextSibling;
  FocusScopeNode _previousSibling;

  FocusScopeNode _firstChild;
  FocusScopeNode _lastChild;

  FocusNode _focus;
  List<FocusScopeNode> _focusPath;

  /// Whether this scope is currently active in its parent scope.
  bool get isFirstFocus => _parent == null || _parent._firstChild == this;

  // Returns this FocusScopeNode's ancestors, starting with the node
  // below the FocusManager's rootScope.
  List<FocusScopeNode> _getFocusPath() {
    final List<FocusScopeNode> nodes = <FocusScopeNode>[this];
    FocusScopeNode node = _parent;
    while (node != null && node != _manager?.rootScope) {
      nodes.add(node);
      node = node._parent;
    }
    return nodes;
  }

  void _prepend(FocusScopeNode child) {
    assert(child != this);
    assert(child != _firstChild);
    assert(child != _lastChild);
    assert(child._parent == null);
    assert(child._manager == null);
    assert(child._nextSibling == null);
    assert(child._previousSibling == null);
    assert(() {
      FocusScopeNode node = this;
      while (node._parent != null) {
        node = node._parent;
      }
      assert(node != child); // indicates we are about to create a cycle
      return true;
    }());
    child._parent = this;
    child._nextSibling = _firstChild;
    if (_firstChild != null) {
      _firstChild._previousSibling = child;
    }
    _firstChild = child;
    _lastChild ??= child;
    child._updateManager(_manager);
  }

  void _updateManager(FocusManager manager) {
    void update(FocusScopeNode child) {
      if (child._manager == manager) {
        return;
      }
      child._manager = manager;
      // We don't proactively null out the manager for FocusNodes because the
      // manager holds the currently active focus node until the end of the
      // microtask, even if that node is detached from the focus tree.
      if (manager != null) {
        child._focus?._manager = manager;
      }
      child._visitChildren(update);
    }

    update(this);
  }

  void _visitChildren(void visitor(FocusScopeNode child)) {
    FocusScopeNode child = _firstChild;
    while (child != null) {
      visitor(child);
      child = child._nextSibling;
    }
  }

  bool _debugUltimatePreviousSiblingOf(FocusScopeNode child, {FocusScopeNode equals}) {
    while (child._previousSibling != null) {
      assert(child._previousSibling != child);
      child = child._previousSibling;
    }
    return child == equals;
  }

  bool _debugUltimateNextSiblingOf(FocusScopeNode child, {FocusScopeNode equals}) {
    while (child._nextSibling != null) {
      assert(child._nextSibling != child);
      child = child._nextSibling;
    }
    return child == equals;
  }

  void _remove(FocusScopeNode child) {
    assert(child._parent == this);
    assert(child._manager == _manager);
    assert(_debugUltimatePreviousSiblingOf(child, equals: _firstChild));
    assert(_debugUltimateNextSiblingOf(child, equals: _lastChild));
    if (child._previousSibling == null) {
      assert(_firstChild == child);
      _firstChild = child._nextSibling;
    } else {
      child._previousSibling._nextSibling = child._nextSibling;
    }
    if (child._nextSibling == null) {
      assert(_lastChild == child);
      _lastChild = child._previousSibling;
    } else {
      child._nextSibling._previousSibling = child._previousSibling;
    }
    child._previousSibling = null;
    child._nextSibling = null;
    child._parent = null;
    child._updateManager(null);
  }

  void _didChangeFocusChain() {
    if (isFirstFocus) {
      _manager?._markNeedsUpdate();
    }
  }

  /// Requests that the given node becomes the focus for this scope.
  ///
  /// If the given node is currently focused in another scope, the node will
  /// first be unfocused in that scope.
  ///
  /// The node will receive the overall focus if this [isFirstFocus] is true
  /// in this scope and all its ancestor scopes. The node is notified that it
  /// has received the overall focus in a microtask.
  void requestFocus(FocusNode node) {
    assert(node != null);
    if (_focus == node && listEquals<FocusScopeNode>(_focusPath, _manager?._getCurrentFocusPath())) {
      return;
    }
    _focus?.unfocus();
    node._hasKeyboardToken = true;
    _setFocus(node);
  }

  /// If this scope lacks a focus, request that the given node becomes the
  /// focus.
  ///
  /// Useful for widgets that wish to grab the focus if no other widget already
  /// has the focus.
  ///
  /// The node is notified that it has received the overall focus in a
  /// microtask.
  void autofocus(FocusNode node) {
    assert(node != null);
    if (_focus == null) {
      node._hasKeyboardToken = true;
      _setFocus(node);
    }
  }

  /// Adopts the given node if it is focused in another scope.
  ///
  /// A widget that requests that a node is focused should call this method
  /// during its [StatelessWidget.build] or [State.build] method in case the
  /// widget is moved from one location in the tree to another location that has
  /// a different focus scope.
  void reparentIfNeeded(FocusNode node) {
    assert(node != null);
    if (node._scopeParent == null || node._scopeParent == this) {
      return;
    }
    node.unfocus();
    assert(node._scopeParent == null);
    if (_focus == null) {
      _setFocus(node);
    }
  }

  void _setFocus(FocusNode node) {
    assert(node != null);
    assert(node._scopeParent == null);
    assert(_focus == null);
    _focus = node;
    _focus._scopeParent = this;
    _focus._manager = _manager;
    _focus._hasKeyboardToken = true;
    _focusPath = _getFocusPath();
    _didChangeFocusChain();
  }

  void _resignFocus(FocusNode node) {
    assert(node != null);
    if (_focus != node) {
      return;
    }
    _focus._scopeParent = null;
    _focus._manager = null;
    _focus = null;
    _didChangeFocusChain();
  }

  /// Makes the given child the first focus of this scope.
  ///
  /// If the child has another parent scope, the child is first removed from
  /// that scope. After this method returns [isFirstFocus] will be true for
  /// the child.
  void setFirstFocus(FocusScopeNode child) {
    assert(child != null);
    if (_firstChild == child) {
      return;
    }
    child.detach();
    _prepend(child);
    assert(child._parent == this);
    _didChangeFocusChain();
  }

  /// Adopts the given scope if it is the first focus of another scope.
  ///
  /// A widget that sets a scope as the first focus of another scope should
  /// call this method during its `build` method in case the widget is moved
  /// from one location in the tree to another location that has a different
  /// focus scope.
  ///
  /// If the given scope is not the first focus of its old parent, the scope
  /// is simply detached from its old parent.
  void reparentScopeIfNeeded(FocusScopeNode child) {
    assert(child != null);
    if (child._parent == null || child._parent == this) {
      return;
    }
    if (child.isFirstFocus) {
      setFirstFocus(child);
    } else {
      child.detach();
    }
  }

  /// Remove this scope from its parent child list.
  ///
  /// This method is safe to call even if this scope does not have a parent.
  ///
  /// A widget that sets a scope as the first focus of another scope should
  /// call this method during [State.dispose] to avoid leaving dangling
  /// children in their parent scope.
  void detach() {
    _didChangeFocusChain();
    _parent?._remove(this);
    assert(_parent == null);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusNode>('focus', _focus, defaultValue: null));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    if (_firstChild != null) {
      FocusScopeNode child = _firstChild;
      int count = 1;
      while (true) {
        children.add(child.toDiagnosticsNode(name: 'child $count'));
        if (child == _lastChild) {
          break;
        }
        child = child._nextSibling;
        count += 1;
      }
    }
    return children;
  }
}

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
class FocusableNode extends FocusNode with DiagnosticableTreeMixin {
  /// Creates a Focusable node
  ///
  /// All parameters must not be null.
  FocusableNode({
    this.autofocus = false,
    @required this.context,
  })  : assert(autofocus != null);

  /// Indicates that this node is a scope node, which keeps track of which of its
  /// descendants last had the focus.
  bool get isScope => false;

  /// True if this node will be selected as the initial focus when no other node
  /// in its scope is currently focused.
  ///
  /// There must only be one node in a scope that has [autofocus] set.
  final bool autofocus;

  /// The global key for the [InheritedWidget] associated with this node.
  ///
  /// This is not the [Focusable] itself, but is a child of the [Focusable], and
  /// it has the same dimensions.
  BuildContext context;

  /// Returns the parent node for this object.
  FocusableNode get parent => _parent;
  FocusableNode _parent;

  final List<FocusableNode> _children = <FocusableNode>[];

  /// Resets this node back to a base configuration.
  ///
  /// This is only used by tests to clear the root node. Do not call in other
  /// contexts, as it doesn't properly detach children.
  @visibleForTesting
  @mustCallSuper
  void clear() {
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
    node._unfocus();

    node._parent = null;

    _children.remove(node);
  }

  /// Moves the given node to be a child of this node.
  ///
  /// Called whenever the associated widget is rebuilt in order to maintain the
  /// focus hierarchy.
  ///
  /// A widget that requests that a node is focused should call this method
  /// during its `build` method in case the widget is moved from one location
  /// in the tree to another location that has a different focus scope.
  @mustCallSuper
  void reparent(FocusableNode child) {
    assert(child != null);
    assert(_manager == null || child != _manager.rootFocusable, "Can't reparent the root focusable node");
    assert(!ancestors.contains(child), 'The supplied child is already an ancestor of this node. Inheritance loops are not allowed.');
    if (child._parent == this) {
      assert(_children.contains(child), "Found a node that says it's a child, but doesn't appear in the child list.");
      return;
    }
    child.detach();
    _children.add(child);
    child._parent = this;
    child._manager = _manager;
    // If this child is an autofocus child, then set that as the focused child
    // in its scope.
    child.enclosingScope._focusedChild ??= child.autofocus ? child : null;
    if (child.autofocus) {
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

  @override
  void dispose() {
    detach();
    super.dispose();
  }

  /// Requests that this node and every parent of this node gets focus.
  ///
  /// If this node is a scope, and there is a current [focusedChild], then focus
  /// that node instead.  If that node is also a scope, will look for its
  /// [focusedChild], and so forth, until a non-scope, or a scope with a null
  /// [focusedChild] is found.
  ///
  /// Set [isImplicit] to true if you are requesting focus from within a focus
  /// policy in order to keep the policy data for future access.
  void requestFocus({bool isImplicit = false}) {
    assert(isImplicit != null);
    assert(_manager != null, "Tried to request focus for a node that isn't part of the focus tree.");
    // Set the focus to the focused child of this scope, if it is one. Otherwise
    // start with setting the focus to this node itself.
    if (!isImplicit) {
      final FocusableScopeNode scope = enclosingScope;
      if (scope != null) {
        scope.policyData = null;
      }
    }
    _manager._markNeedsUpdate(newFocus: this);
  }

  @override
  bool get hasFocus {
    if (_manager == null) {
      return false;
    }
    if (hasPrimaryFocus) {
      return true;
    }
    if (_manager._currentFocus is! FocusableNode) {
      return false;
    }
    FocusableNode focus = _manager._currentFocus;
    if (focus == this) {
      return true;
    }
    // See if this node appears in the focus path.
    while (focus != this && focus != null) {
      focus = focus._parent;
    }
    return focus == this;
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
  /// this node, if it's a scope, or null if none is found.
  FocusableScopeNode get nearestScope => isScope ? this : enclosingScope;

  /// Returns the nearest enclosing scope node above this node, or null if none
  /// is found. If this node is a scope, does not include it.
  FocusableScopeNode get enclosingScope => ancestors.firstWhere((FocusableNode node) => node.isScope, orElse: () => null);

  // Sets this node as the focused child for the enclosing scope, and that scope
  // as focused child for the scope above it, until it reaches the root node.
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

  @override
  void _notify() {
    if (hasPrimaryFocus) {
      _setAsFocusedChild();
    }
    super._notify();
  }

  void _unfocus() {
    final FocusableScopeNode scope = enclosingScope;
    if (scope == null) {
      return;
    }
    if (scope._focusedChild == this) {
      scope._focusedChild = null;
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
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    return '${describeIdentity(this)} key:$context ${hasFocus ? '(FOCUSED)' : ''}';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BuildContext>('key', context, defaultValue: null));
    properties.add(FlagProperty('hasFocus', value: hasFocus, ifTrue: 'FOCUSED', defaultValue: false));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    int count = 0;
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
    @required BuildContext context,
  })  : assert(autofocus != null),
        super(context: context, autofocus: autofocus);

  @override
  bool get isScope => true;

  @override
  void reparent(FocusableNode child) {
    final FocusableScopeNode previousEnclosingScope = child.enclosingScope;
    super.reparent(child);
    // If the child moved scopes, then the policy data is invalid.
    if (previousEnclosingScope != child.enclosingScope) {
      policyData = null;
    }
  }

  /// Returns the child of this node which should receive focus if this scope
  /// node receives focus.
  ///
  /// If [hasFocus] is true, then this points to the child of this node which is
  /// currently focused.
  ///
  /// Returns null if there is no currently focused child.
  FocusableNode get focusedChild {
    assert(_focusedChild == null || _focusedChild.enclosingScope == this,
      'Focused child does not have the same idea of its enclosing scope as the scope does.');
    return _focusedChild;
  }

  FocusableNode _focusedChild;

  /// Requests that this node and every parent of this node gets focus.
  ///
  /// If this node is a scope, and there is a current [focusedChild], then focus
  /// that node instead.  If that node is also a scope, will look for its
  /// [focusedChild], and so forth, until a non-scope, or a scope with a null
  /// [focusedChild] is found.
  ///
  /// Set [isImplicit] to true if you are requesting focus from within a focus
  /// policy in order to keep the policy data for future access.
  @override
  void requestFocus({bool isImplicit = false}) {
    assert(isImplicit != null);
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
    if (!isImplicit) {
      final FocusableScopeNode scope = primaryFocus.enclosingScope;
      if (scope != null) {
        scope.policyData = null;
      }
    }
    _manager._markNeedsUpdate(newFocus: primaryFocus);
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
    assert(rootScope._firstChild == null);
    assert(rootScope._lastChild == null);

    rootFocusable._manager = this;
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
    _nextFocusable = null;
    _haveScheduledUpdate = false;

    rootScope._manager = this;
    rootScope._firstChild = null;
    rootScope._lastChild = null;
    rootScope._nextSibling = null;
    rootScope._previousSibling = null;
    rootScope._parent = null;
    assert(rootScope._firstChild == null);
    assert(rootScope._lastChild == null);

    rootFocusable.clear();
    rootFocusable._manager = this;
  }

  /// The root [FocusScopeNode] in the focus tree.
  ///
  /// This field is rarely used directly. Instead, to find the
  /// [FocusScopeNode] for a given [BuildContext], use [FocusScope.of].
  final FocusScopeNode rootScope = FocusScopeNode();

  /// The root [FocusableNode] in the focus tree.
  ///
  /// This field is rarely used directly. Instead, to find the nearest
  /// [FocusableNode] for a given [BuildContext], use [Focusable.of].
  ///
  /// To find the nearest [FocusableNode] that corresponds to a
  /// [Focusable], use [Focusable.of].
  final FocusableNode rootFocusable = FocusableScopeNode(context: null);

  // The entire focus path, except for the rootFocusable, which is implicitly
  // at the beginning of the list.  The last element should correspond with
  // _currentFocus;
  FocusNode _currentFocus;
  FocusableNode _nextFocusable;
  FocusableNode _nextAutofocus;

  void _willDisposeFocusNode(FocusNode node) {
    assert(node != null);
    if (_currentFocus == node) {
      _currentFocus = null;
    }
  }

  bool _haveScheduledUpdate = false;
  void _markNeedsUpdate({FocusableNode newFocus}) {
    // If newFocus isn't specified, then don't mess with _nextFocusable, just
    // schedule the update.
    _nextFocusable = newFocus ?? _nextFocusable;
    if (_haveScheduledUpdate) {
      return;
    }
    _haveScheduledUpdate = true;
    scheduleMicrotask(_applyFocusChange);
  }

  FocusNode _findNextFocus() {
    FocusScopeNode scope = rootScope;
    while (scope._firstChild != null) {
      scope = scope._firstChild;
    }
    return scope._focus;
  }

  void _requestAutofocus(FocusableNode node) {
    _nextAutofocus = node;
    _markNeedsUpdate();
  }

  void _applyFocusChange() {
    _haveScheduledUpdate = false;
    final FocusNode previousFocus = _currentFocus;
    if (_nextAutofocus != null) {
      // If a child with autofocus was re-parented, and we don't have any focus
      // or pending focus set, then use that as the focus.
      if (_nextFocusable == null && _currentFocus == null) {
        _nextFocusable = _nextAutofocus;
      }
      _nextAutofocus = null;
    }
    if (_nextFocusable != null) {
      // The new focus is a FocusableNode
      if (_currentFocus == _nextFocusable) {
        return;
      }
      _currentFocus = _nextFocusable;
      if (previousFocus is! FocusableNode) {
        for (FocusableNode node in _nextFocusable.ancestors) {
          node._notify();
        }
      } else if (previousFocus is FocusableNode) {
        final Set<FocusableNode> previousPath = previousFocus.ancestors.toSet();
        final Set<FocusableNode> nextPath = _nextFocusable.ancestors.toSet();
        // Notify nodes that are newly focused.
        for (FocusableNode node in nextPath.difference(previousPath)) {
          node._notify();
        }
        // Notify nodes that are no longer focused
        for (FocusableNode node in previousPath.difference(nextPath)) {
          node._notify();
        }
      }
      _nextFocusable = null;
    } else {
      // The new focus is a FocusNode.
      final FocusNode nextFocus = _findNextFocus();
      if (_currentFocus == nextFocus) {
        return;
      }
      final FocusNode previousFocus = _currentFocus;
      if (previousFocus is FocusableNode) {
        // Notify the previous focus that it lost focus if it was a
        // FocusableNode.
        for (FocusableNode node in _nextFocusable.ancestors) {
          node._notify();
        }
      }
      _currentFocus = nextFocus;
    }
    previousFocus?._notify();
    _currentFocus?._notify();
  }

  List<FocusScopeNode> _getCurrentFocusPath() => _currentFocus?._scopeParent?._getFocusPath();

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      rootScope.toDiagnosticsNode(name: 'rootScope'),
      rootFocusable.toDiagnosticsNode(name: 'rootFocusable'),
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
