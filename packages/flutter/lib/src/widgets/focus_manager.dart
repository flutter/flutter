// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import 'binding.dart';
import 'framework.dart';

/// Signature of a callback used by [Focus.onKey] and [FocusScope.onKey]
/// to receive key events.
///
/// The [node] is the node that received the event.
typedef FocusOnKeyCallback = bool Function(FocusNode node, RawKeyEvent event);

/// An attachment point for a [FocusNode].
///
/// Once created, a [FocusNode] must be attached to the element tree by its
/// _host_ [StatefulWidget] via a [FocusAttachment] object.  This attachment is
/// created by calling [FocusNode.attach], usually from the host widget's
/// [State.initState] method. If the widget is updated to have a different focus
/// node, then the new node needs to be attached in [State.didUpdateWidget],
/// after calling [detach] on the previous [FocusAttachment].
///
/// Without these attachment points, it would be possible for the focus node to
/// simultaneously be attached to more than one part of the element tree during
/// the build stage.
class FocusAttachment {
  /// A private constructor, because [FocusAttachment]s are only to be created
  /// by [FocusNode.attach].
  FocusAttachment._(this.node);

  /// The focus node that this attachment manages an attachment for.
  final FocusNode node;

  /// Returns true if the node is attached to the element tree.
  ///
  /// It is possible to be attached to the element tree, but not be placed in
  /// the focus tree (i.e. to not have a parent yet in the focus tree).
  bool get isAttached => node._attachment == this;

  /// Detaches the [node] this attachment point is associated with from the
  /// focus tree, and disconnects it from this attachment point.
  ///
  /// Calling [FocusNode.dispose] will also automatically detach the node.
  void detach() {
    assert(node != null);
    if (isAttached) {
      node._parent?._removeChild(node);
      node._attachment = null;
    }
    assert(!isAttached);
  }

  /// Ensures that the given [parent] node is the parent of the [node] which is
  /// attached at this attachment point, changing it if necessary.
  ///
  /// If [isAttached] is false, then calling this method does nothing.
  ///
  /// Called whenever the associated widget is rebuilt in order to maintain the
  /// focus hierarchy.
  ///
  /// A [StatefulWidget] that hosts a [FocusNode] should call this method on the
  /// node it hosts during its [State.build] or [State.didChangeDependencies]
  /// methods in case the widget is moved from one location in the tree to
  /// another location that has a different [FocusScope] or context.
  void reparent(FocusNode parent) {
    assert(parent != null);
    assert(node != null);
    if (isAttached) {
      parent._reparent(node);
    }
  }
}

/// An object that can be used by a stateful widget to obtain the keyboard focus
/// and to handle keyboard events.
///
/// _Please see the [Focus] and [FocusScope] widgets, which are utility widgets
/// that manage their own [FocusNode]s and [FocusScopeNode]s, respectively. If
/// they aren't appropriate, [FocusNode]s can be managed directly._
///
/// [FocusNode]s are persistent objects that form a _focus tree_ that is a
/// representation of the widgets in the hierarchy that are interested in
/// focus.
///
/// [FocusNodes] are organized into _scopes_ (see [FocusScopeNode]), which form
/// sub-trees of nodes that can be traversed as a group. Within a scope, the
/// most recent nodes to have focus are remembered, and if a node is focused and
/// then removed, the original node receives focus again.
///
/// The focus node hierarchy can be traversed using the [parent], [children],
/// [ancestors] and [descendants] accessors.
///
/// [FocusNode]s are [ChangeNotifier]s, so a listener can be registered to
/// receive a notification when the focus changes. If the [Focus] and
/// [FocusScope] widgets are being used to manage the nodes, consider
/// establishing an [InheritedWidget] dependency on them by calling [Focus.of]
/// or [FocusScope.of] instead. [Focus.hasFocus] can also be used to establish a
/// similar dependency, especially if all that is needed is to determine whether
/// or not the widget is focused at build time.
///
/// To see the focus tree in the debug console, call [debugDumpFocusTree]. To
/// get the focus tree as a string, call [debugDescribeFocusTree].
///
/// {@template flutter.widgets.focusManager.hierarchyManagement}
/// ## Hierarchy Management
///
/// [FocusNode]s (and hence [FocusScopeNode]s) are persistent objects that form
/// part of a _focus tree_ that is a representation of the widgets in the
/// hierarchy that are interested in receiving keyboard events. They must be
/// managed like other persistent state, which is typically done by a
/// [StatefulWidget]. A stateful widget that manages a focus scope node must
/// call [dispose] from its [State.dispose] method.
///
/// Once created, a [FocusNode] must be attached to the focus tree via a
/// [FocusAttachment] object.  This attachment is created by calling [attach],
/// usually from a widget's [State.initState] method, and if the widget is
/// updated, again in [State.didUpdateWidget], after calling
/// [FocusAttachment.detach] on the previous [FocusAttachment].
///
/// Because [FocusNode]s form a sparse representation of the widget tree,
/// they must be updated whenever the widget tree is rebuilt. This is done by
/// calling [FocusAttachment.reparent], usually from the [State.build] or
/// [State.didChangeDependencies] methods of the widget that represents the
/// focused region, so that the [BuildContext] assigned to the [FocusScopeNode]
/// can be tracked (the context is used to obtain the [RenderObject], from which
/// the geometry of focused regions can be determined).
/// {@endtemplate}
///
/// {@template flutter.widgets.focus_manager.focus.lifecycle}
/// ## Lifecycle
///
/// There are several actors involved in the lifecycle of a
/// [FocusNode]/[FocusScopeNode]. They are created and disposed by their
/// _owner_, attached, detached, and reparented using a [FocusAttachment] by
/// their _host_ (which must be the [State] of a [StatefulWidget]), and they are
/// managed by the [FocusManager]. Different parts of the [FocusNode] API are
/// intended for these different actors.
///
/// Focus nodes are long-lived objects. For example, if a host [StatefulWidget]
/// should be able to receive focus, and is not using a [Focus] or [FocusScope]
/// widget, it would [attach] a [FocusNode] in its [State.initState] method, and
/// [detach] from it in the [State.dispose] method, providing the same
/// [FocusNode] to the [FocusAttachment.reparent] call each time its
/// [State.build] method is run. Creating a [FocusNode] each time [State.build]
/// is invoked will cause the focus to be lost each time the widget is built,
/// which is usually not desired behavior (call [unfocus] if losing focus is
/// desired).
///
/// If, as is common, the hosting [StatefulWidget] is also the owner of the
/// focus node, then it will also call [dispose] from its [State.dispose] (in
/// which case the [detach] may be skipped, since dispose will automatically
/// detach). If another object owns the focus node, then it must call [dispose]
/// when the node is done being used.
///
/// If the hosting widget is updated to have a different focus node, then the
/// updated node needs to be attached in [State.didUpdateWidget], after calling
/// [detach] on the previous [FocusAttachment].
/// {@endtemplate}
///
/// {@template flutter.widgets.focus_manager.focus.keyEvents}
/// ## Key Event Propagation
///
/// The [FocusManager] receives all key events and will pass them to the focused
/// nodes. It starts with the node with the primary focus, and will call the
/// [onKey] callback for that node. If the callback returns false, indicating
/// that it did not handle the event, the [FocusManager] will move to the parent
/// of that node and call its [onKey]. If that [onKey] returns true, then it
/// will stop propagating the event. If it reaches the root [FocusScopeNode],
/// [FocusManager.rootScope], the event is discarded.
/// {@endtemplate}
///
/// {@tool snippet --template=stateless_widget_material}
/// This example shows how a FocusNode should be managed if not using the
/// [Focus] or [FocusScope] widgets. See the [Focus] widget for a similar
/// example using [Focus] and [FocusScope] widgets.
///
/// ```dart imports
/// import 'package:flutter/services.dart';
/// ```
///
/// ```dart preamble
/// class ColorfulButton extends StatefulWidget {
///   ColorfulButton({Key key}) : super(key: key);
///
///   @override
///   _ColorfulButtonState createState() => _ColorfulButtonState();
/// }
///
/// class _ColorfulButtonState extends State<ColorfulButton> {
///   FocusNode _node;
///   FocusAttachment _nodeAttachment;
///   Color _color;
///
///   @override
///   void initState() {
///     super.initState();
///     _node = FocusNode(debugLabel: 'Button');
///     _nodeAttachment = _node.attach(context, onKey: _handleKeyPress);
///   }
///
///   bool _handleKeyPress(FocusNode node, RawKeyEvent event) {
///     if (event is RawKeyDownEvent) {
///       print('Focus node ${node.debugLabel} got key event: ${event.logicalKey}');
///       if (event.logicalKey == LogicalKeyboardKey.keyR) {
///         print('Changing color to red.');
///         setState(() {
///           _color = Colors.red;
///         });
///         return true;
///       } else if (event.logicalKey == LogicalKeyboardKey.keyG) {
///         print('Changing color to green.');
///         setState(() {
///           _color = Colors.green;
///         });
///         return true;
///       } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
///         print('Changing color to blue.');
///         setState(() {
///           _color = Colors.blue;
///         });
///         return true;
///       }
///     }
///     return false;
///   }
///
///   @override
///   void dispose() {
///     // The attachment will automatically be detached in dispose().
///     _node.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     _nodeAttachment.reparent(Focus.of(context));
///     return RaisedButton(
///       color: _node.hasFocus ? _color : null,
///       onPressed: () {
///         if (_node.hasFocus) {
///           setState(() {
///             _node.unfocus();
///           });
///         } else {
///           setState(() {
///             _node.requestFocus();
///           });
///         }
///       },
///       child: Text(_node.hasFocus ? "I'm in color! Press R,G,B!" : 'Press to focus'),
///     );
///   }
/// }
/// ```
///
/// ```dart
/// Widget build(BuildContext context) {
///   final TextTheme textTheme = Theme.of(context).textTheme;
///   return DefaultTextStyle(
///     style: textTheme.display1,
///     child: ColorfulButton(),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///   * [Focus], a widget that manages a [FocusNode] and provides access to
///     focus information and actions to its descendant widgets.
///   * [FocusScope], a widget that manages a [FocusScopeNode] and provides
///     access to scope information and actions to its descendant widgets.
///   * [FocusAttachment], a widget that connects a [FocusScopeNode] to the
///     element tree.
///   * [FocusManager], a singleton that manages the focus and distributes key
///     events to focused nodes.
class FocusNode with DiagnosticableTreeMixin, ChangeNotifier {
  /// Creates a focus node.
  ///
  /// The [debugLabel] is ignored on release builds.
  FocusNode({
    String debugLabel,
    FocusOnKeyCallback onKey,
  }) : _onKey = onKey {
    // Set it this way so that it does nothing on release builds.
    this.debugLabel = debugLabel;
  }

  /// The context that was supplied to [reparent].
  ///
  /// This is typically the context in the build method for the widget that is
  /// being focused, as it is used to determine the bounds of the widget.
  BuildContext get context => _context;
  BuildContext _context;

  /// Called if this focus node receives a key event while focused (i.e. when
  /// [hasFocus] returns true).
  ///
  /// {@macro flutter.widgets.focus_manager.focus.keyEvents}
  FocusOnKeyCallback get onKey => _onKey;
  FocusOnKeyCallback _onKey;

  FocusManager _manager;
  bool _hasKeyboardToken = false;

  /// Returns the parent node for this object.
  ///
  /// All nodes except for the root [FocusScopeNode] ([FocusManager.rootScope])
  /// will be given a parent when they are added to the focus tree, which is
  /// done using [reparent].
  FocusNode get parent => _parent;
  FocusNode _parent;

  /// An iterator over the children of this node.
  Iterable<FocusNode> get children => _children;
  final List<FocusNode> _children = <FocusNode>[];

  /// A debug label that is used for diagnostic output.
  ///
  /// Will always return null in release builds.
  String get debugLabel => _debugLabel;
  String _debugLabel;
  set debugLabel(String value) {
    assert(() {
      // Only set the value in debug builds.
      _debugLabel = value;
      return true;
    }());
  }

  FocusAttachment _attachment;

  /// An [Iterable] over the hierarchy of children below this one, in
  /// depth-first order.
  Iterable<FocusNode> get descendants sync* {
    for (FocusNode child in _children) {
      yield* child.descendants;
      yield child;
    }
  }

  /// An [Iterable] over the ancestors of this node.
  ///
  /// Iterates the ancestors of this node starting at the parent and iterating
  /// over successively more remote ancestors of this node, ending at the root
  /// [FocusScope] ([FocusManager.rootScope]).
  Iterable<FocusNode> get ancestors sync* {
    FocusNode parent = _parent;
    while (parent != null) {
      yield parent;
      parent = parent._parent;
    }
  }

  /// Whether this node has focus.
  ///
  /// A [FocusNode] has the primary focus when the node is focused in its
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
    return _manager._currentFocus.ancestors.contains(this);
  }

  /// Returns true if this node currently has the application-wide focus.
  ///
  /// This is different from [hasFocus] in that [hasFocus] is true if the node
  /// is anywhere in the focus chain, but here the node has to be at the end of
  /// the chain to return true.
  ///
  /// A node that returns true for [hasPrimaryFocus] will be the first node to
  /// receive key events.
  bool get hasPrimaryFocus => _manager?._currentFocus == this;

  /// Returns the nearest enclosing scope node above this node, including
  /// this node, if it's a scope.
  ///
  /// Returns null if no scope is found.
  ///
  /// Use [enclosingScope] to look for scopes above this node.
  FocusScopeNode get nearestScope => enclosingScope;

  /// Returns the nearest enclosing scope node above this node, or null if none
  /// is found.
  ///
  /// If this node is itself a scope, this will only return ancestors of this
  /// scope.
  ///
  /// Use [nearestScope] to start at this node instead of above it.
  FocusScopeNode get enclosingScope {
    return ancestors.firstWhere((FocusNode node) => node is FocusScopeNode, orElse: () => null);
  }

  /// Returns the size of the associated [Focus] in logical units.
  Size get size {
    assert(context != null,
      "Tried to get the size of a focus node that didn't have its context set yet.\n"
      'The context needs to be set before trying to evaluate traversal policies. This '
      'is typically done by the reparent method, called from a build method.');
    return context.findRenderObject().semanticBounds.size;
  }

  /// Returns the global offset to the upper left corner of the [Focus] in
  /// logical units.
  Offset get offset {
    assert(context != null,
      "Tried to get the offset of a focus node that didn't have its context set yet.\n"
      'The context needs to be set before trying to evaluate traversal policies. This '
      'is typically done by the reparent method, called from a build method.');
    final RenderObject object = context.findRenderObject();
    return MatrixUtils.transformPoint(object.getTransformTo(null), object.semanticBounds.topLeft);
  }

  /// Returns the global rectangle surrounding the node in logical units.
  Rect get rect {
    assert(context != null,
      "Tried to get the bounds of a focus node that didn't have its context set yet.\n"
      'The context needs to be set before trying to evaluate traversal policies. This '
      'is typically done by the reparent method, called from a build method.');
    final RenderObject object = context.findRenderObject();
    final Offset globalOffset = MatrixUtils.transformPoint(object.getTransformTo(null), object.semanticBounds.topLeft);
    return globalOffset & object.semanticBounds.size;
  }

  /// Removes focus from a node that has the primary focus, and cancels any
  /// outstanding requests to focus it.
  ///
  /// Calling [requestFocus] sends a request to the [FocusManager] to make that
  /// node the primary focus, which schedules a microtask to resolve the latest
  /// request into an update of the focus state on the tree. Calling [unfocus]
  /// cancels a request that has been requested, but not yet acted upon.
  ///
  /// This method is safe to call regardless of whether this node has ever
  /// requested focus.
  ///
  /// Has no effect on nodes that return true from [hasFocus], but false from
  /// [hasPrimaryFocus].
  void unfocus() {
    final FocusScopeNode scope = enclosingScope;
    if (scope == null) {
      // This node isn't part of a tree.
      return;
    }
    scope._focusedChildren.remove(this);
    _manager?._willUnfocusNode(this);
  }

  /// Removes the keyboard token from this focus node if it has one.
  ///
  /// This mechanism helps distinguish between an input control gaining focus by
  /// default and gaining focus as a result of an explicit user action.
  ///
  /// When a focus node requests the focus (either via
  /// [FocusScopeNode.requestFocus] or [FocusScopeNode.autofocus]), the focus
  /// node receives a keyboard token if it does not already have one. Later,
  /// when the focus node becomes focused, the widget that manages the
  /// [TextInputConnection] should show the keyboard (i.e. call
  /// [TextInputConnection.show]) only if it successfully consumes the keyboard
  /// token from the focus node.
  ///
  /// Returns true if this method successfully consumes the keyboard token.
  bool consumeKeyboardToken() {
    if (!_hasKeyboardToken) {
      return false;
    }
    _hasKeyboardToken = false;
    return true;
  }

  // Marks the node as dirty, meaning that it needs to notify listeners of a
  // focus change the next time focus is resolved by the manager.
  void _markAsDirty({FocusNode newFocus}) {
    if (_manager != null) {
      // If we have a manager, then let it handle the focus change.
      _manager._dirtyNodes?.add(this);
      _manager._markNeedsUpdate(newFocus: newFocus);
    } else {
      // If we don't have a manager, then change the focus locally.
      newFocus?._setAsFocusedChild();
      newFocus?._notify();
      if (newFocus != this) {
        _notify();
      }
    }
  }

  // Resets this node back to a base configuration. This is only used by tests
  // to clear the root node. Do not call in other contexts, as it doesn't
  // properly detach children.
  @mustCallSuper
  void _clear() {
    _manager?._dirtyNodes?.remove(this);
    _manager = null;
    _parent = null;
    _children.clear();
  }

  // Removes the given FocusNode and its children as a child of this node.
  @mustCallSuper
  void _removeChild(FocusNode node) {
    assert(_children.contains(node), "Tried to remove a node that wasn't a child.");
    assert(node._parent == this);
    assert(node._manager == _manager);

    // If the child was (or requested to be) the primary focus, then unfocus it
    // and cancel any outstanding request to be focused.
    node.unfocus();

    node._parent = null;
    _children.remove(node);
    assert(_manager == null || !_manager.rootScope.descendants.contains(node));
  }

  void _updateManager(FocusManager manager) {
    _manager = manager;
    for (FocusNode descendant in descendants) {
      descendant._manager = manager;
    }
  }

  // Used by FocusAttachment.reparent to perform the actual parenting operation.
  @mustCallSuper
  void _reparent(FocusNode child) {
    assert(child != null);
    assert(child != this, 'Tried to make a child into a parent of itself.');
    if (child._parent == this) {
      assert(_children.contains(child), "Found a node that says it's a child, but doesn't appear in the child list.");
      // The child is already a child of this parent.
      return;
    }
    assert(_manager == null || child != _manager.rootScope, "Reparenting the root node isn't allowed.");
    assert(!ancestors.contains(child), 'The supplied child is already an ancestor of this node. Loops are not allowed.');
    FocusNode oldPrimaryFocus;
    if (child._manager != null) {
      // We want to find out what the primary focus is, since the new child
      // might be an ancestor of the primary focus, and it should move with the
      // child.
      oldPrimaryFocus = child.hasFocus ? child._manager._currentFocus : null;
      assert(oldPrimaryFocus == null || oldPrimaryFocus == child || oldPrimaryFocus.ancestors.contains(child),
        "child has focus, but primary focus isn't a descendant of it for some reason.");
    }
    // The child currently has focus, so we have to do some extra work to keep
    // that focus, and to notify any scopes that used to be ancestors, and no
    // longer have focus after we move it.
    final Set<FocusNode> oldFocusPath = oldPrimaryFocus?.ancestors?.toSet() ?? <FocusNode>{};
    child._parent?._removeChild(child);
    _children.add(child);
    child._parent = this;
    child._updateManager(_manager);
    if (oldPrimaryFocus != null) {
      final Set<FocusNode> newFocusPath = _manager?._currentFocus?.ancestors?.toSet() ?? <FocusNode>{};
      // Nodes that will no longer be focused need to be marked dirty.
      for (FocusNode node in oldFocusPath.difference(newFocusPath)) {
        node._markAsDirty();
      }
      // If the node used to have focus, make sure it keeps it's old primary
      // focus when it moves.
      oldPrimaryFocus.requestFocus();
    }
  }

  /// Called by the _host_ [StatefulWidget] to attach a [FocusNode] to the focus tree.
  ///
  /// In order to attach a [FocusNode] to the focus tree, call [attach] when the
  /// node is ready to be added to the focus tree, typically from the
  /// [StatefulWidget]'s [State.initState] method.
  ///
  /// If the focus node in the host widget is swapped out, the new node will
  /// need to be attached. [FocusAttachment.detach] should be called on the old
  /// node, and then [attach] called on the new node. This typically happens in
  /// the [State.didUpdateWidget] method.
  @mustCallSuper
  FocusAttachment attach(BuildContext context, {FocusOnKeyCallback onKey}) {
    _context = context;
    _onKey = onKey;
    _attachment = FocusAttachment._(this);
    return _attachment;
  }

  @override
  void dispose() {
    _manager?._willDisposeFocusNode(this);
    _attachment?.detach();
    super.dispose();
  }

  @mustCallSuper
  void _notify() {
    if (_parent == null) {
      // no longer part of the tree, so don't notify.
      return;
    }
    if (hasPrimaryFocus) {
      _setAsFocusedChild();
    }
    notifyListeners();
  }

  /// Requests the primary focus for a [node], which will also give
  /// focus to its [ancestors].
  ///
  /// If called without a node, request focus for this node.
  ///
  /// If the given [node] is a [FocusScopeNode] and that focus scope node has a
  /// non-null [focusedChild], then request the focus for the focused child.
  /// This process is recursive and continues until it encounters either a focus
  /// scope node with a null focused child or an ordinary (non-scope)
  /// [FocusNode] is found.
  ///
  /// The node is notified that it has received the primary focus in a
  /// microtask, so notification may lag the request by up to one frame.
  void requestFocus([FocusNode node]) {
    if (node != null) {
      if (node._parent == null) {
        _reparent(node);
      }
      assert(node.ancestors.contains(this),
        'Focus was requested for a node that is not a descendant of the scope from which it was requested.');
      node._doRequestFocus(false);
      return;
    }
    _doRequestFocus(false);
  }

  void _doRequestFocus(bool isFromPolicy) {
    assert(isFromPolicy != null);
    _hasKeyboardToken = true;
    _setAsFocusedChild();
    _markAsDirty(newFocus: this);
  }

  // Sets this node as the focused child for the enclosing scope, and that scope
  // as the focused child for the scope above it, etc., until it reaches the
  // root node.
  void _setAsFocusedChild() {
    FocusNode scopeFocus = this;
    for (FocusScopeNode ancestor in ancestors.whereType<FocusScopeNode>()) {
      assert(scopeFocus != ancestor, 'Somehow made a loop by setting focusedChild to its scope.');
      // Remove it anywhere in the focused child history.
      ancestor._focusedChildren.remove(scopeFocus);
      // Add it to the end of the list, which is also the top of the queue: The
      // end of the list represents the currently focused child.
      ancestor._focusedChildren.add(scopeFocus);
      scopeFocus = ancestor;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BuildContext>('context', context, defaultValue: null));
    properties.add(FlagProperty('hasFocus', value: hasFocus, ifTrue: 'FOCUSED', defaultValue: false));
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    int count = 1;
    return _children.map<DiagnosticsNode>(
        (FocusNode child) => child.toDiagnosticsNode(name: 'Child ${count++}')
    ).toList();
  }
}

/// A subclass of [FocusNode] that acts as a scope for its descendants,
/// maintaining information about which descendant is currently or was last
/// focused.
///
/// _Please see the [FocusScope] and [Focus] widgets, which are utility widgets
/// that manage their own [FocusScopeNode]s and [FocusNode]s, respectively. If
/// they aren't appropriate, [FocusScopeNode]s can be managed directly._
///
/// [FocusScopeNode] organizes [FocusNodes] into _scopes_. Scopes form sub-trees
/// of nodes that can be traversed as a group. Within a scope, the most recent
/// nodes to have focus are remembered, and if a node is focused and then
/// removed, the original node receives focus again.
///
/// From a [FocusScopeNode], calling [setFirstFocus], sets the given focus scope
/// as the [focusedChild] of this node, adopting if it isn't already part of the
/// focus tree.
///
/// {@macro flutter.widgets.focusManager.hierarchyManagement}
/// {@macro flutter.widgets.focusManager.lifecycle}
/// {@macro flutter.widgets.focus_manager.focus.keyEvents}
///
/// See also:
///
///   * [Focus], a widget that manages a [FocusNode] and provides access to
///     focus information and actions to its descendant widgets.
///   * [FocusScope], a widget that manages a [FocusScopeNode] and provides
///     access to scope information and actions to its descendant widgets.
///   * [FocusAttachment], a widget that connects a [FocusScopeNode] to the
///     focus tree.
///   * [FocusManager], a singleton that manages the focus and distributes key
///     events to focused nodes.
class FocusScopeNode extends FocusNode {
  /// Creates a FocusScope node.
  ///
  /// All parameters are optional.
  FocusScopeNode({
    String debugLabel,
    FocusOnKeyCallback onKey,
  }) : super(debugLabel: debugLabel, onKey: onKey);

  @override
  FocusScopeNode get nearestScope => this;

  /// Returns true if this scope is the focused child of its parent scope.
  bool get isFirstFocus => enclosingScope.focusedChild == this;

  /// Returns the child of this node that should receive focus if this scope
  /// node receives focus.
  ///
  /// If [hasFocus] is true, then this points to the child of this node that is
  /// currently focused.
  ///
  /// Returns null if there is no currently focused child.
  FocusNode get focusedChild {
    assert(_focusedChildren.isEmpty || _focusedChildren.last.enclosingScope == this,
    'Focused child does not have the same idea of its enclosing scope as the scope does.');
    return _focusedChildren.isNotEmpty ? _focusedChildren.last : null;
  }

  final List<FocusNode> _focusedChildren = <FocusNode>[];

  @override
  void _reparent(FocusNode child) {
    final bool hadChildren = _children.isNotEmpty;
    super._reparent(child);
    final FocusScopeNode currentEnclosingScope = child.enclosingScope;
    // If we just added our first child to this scope, and this scope had the
    // focus, then focus the child.
    if (!hadChildren && currentEnclosingScope.focusedChild == null && currentEnclosingScope.hasFocus) {
      child.requestFocus();
    }
  }

  /// Make the given [scope] the active child scope for this scope.
  ///
  /// If the given [scope] is not yet a part of the focus tree, then add it to
  /// the tree as a child of this scope.
  ///
  /// The given scope must be a descendant of this scope.
  void setFirstFocus(FocusScopeNode scope) {
    assert(scope != null);
    if (scope._parent == null) {
      _reparent(scope);
    }
    assert(scope.ancestors.contains(this));
    // Move down the tree, checking each focusedChild until we get to a node
    // that either isn't a scope node, or has no focused child, and then request
    // focus on that node.
    FocusNode descendantFocus = scope.focusedChild;
    while (descendantFocus is FocusScopeNode && descendantFocus != null) {
      final FocusScopeNode descendantScope = descendantFocus;
      descendantFocus = descendantScope.focusedChild;
    }
    if (descendantFocus != null) {
      descendantFocus?._doRequestFocus(false);
    } else {
      scope._doRequestFocus(false);
    }
  }

  /// If this scope lacks a focus, request that the given node become the focus.
  ///
  /// If the given node is not yet part of the focus tree, then add it as a
  /// child of this node.
  ///
  /// Useful for widgets that wish to grab the focus if no other widget already
  /// has the focus.
  ///
  /// The node is notified that it has received the primary focus in a
  /// microtask, so notification may lag the request by up to one frame.
  void autofocus(FocusNode node) {
    if (focusedChild == null) {
      if (node._parent == null) {
        _reparent(node);
      }
      assert(node.ancestors.contains(this),
        'Autofocus was requested for a node that is not a descendant of the scope from which it was requested.');
      node.requestFocus();
    }
  }

  @override
  void _doRequestFocus(bool isFromPolicy) {
    assert(isFromPolicy != null);
    // Start with the primary focus as the focused child of this scope, if there
    // is one. Otherwise start with this node itself.
    FocusNode primaryFocus = focusedChild ?? this;
    // Keep going down through scopes until the ultimately focusable item is
    // found, a scope doesn't have a focusedChild, or a non-scope is
    // encountered.
    while (primaryFocus is FocusScopeNode && primaryFocus.focusedChild != null) {
      final FocusScopeNode scope = primaryFocus;
      primaryFocus = scope.focusedChild;
    }
    if (primaryFocus is FocusScopeNode) {
      // We didn't find a FocusNode at the leaf, so we're focusing the scope.
      _markAsDirty(newFocus: primaryFocus);
    } else {
      primaryFocus.requestFocus();
    }
  }

  @override
  void _clear() {
    super._clear();
    _focusedChildren.clear();
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
    RawKeyboard.instance.addListener(_handleRawKeyEvent);
  }

  /// The root [FocusNode] in the focus tree.
  ///
  /// This field is rarely used directly. Typically, to find the nearest
  /// [FocusNode] for a given [BuildContext], [Focus.of] or [FocusScope.of] is
  /// used.
  final FocusScopeNode rootScope = FocusScopeNode(debugLabel: 'Root Focus Scope');

  void _handleRawKeyEvent(RawKeyEvent event) {
    // Walk the current focus from the leaf to the root, calling each one on the
    // way up, and if one responds that they handled it, stop.
    if (_currentFocus == null) {
      return;
    }
    Iterable<FocusNode> allNodes(FocusNode node) sync* {
      yield node;
      for (FocusNode ancestor in node.ancestors) {
        yield ancestor;
      }
    }

    for (FocusNode node in allNodes(_currentFocus)) {
      if (node.onKey != null && node.onKey(node, event)) {
        break;
      }
    }
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
      descendant.dispose();
    }
    _currentFocus = null;
    _nextFocus = null;
    _haveScheduledUpdate = false;
    rootScope._clear();
    rootScope._manager = this;
  }

  // The entire focus path, except for the rootFocus, which is implicitly
  // at the beginning of the list.  The last element should correspond with
  // _currentFocus;
  FocusNode _currentFocus;
  FocusNode _nextFocus;
  final Set<FocusNode> _dirtyNodes = <FocusNode>{};

  void _willDisposeFocusNode(FocusNode node) {
    assert(node != null);
    _willUnfocusNode(node);
    _dirtyNodes.remove(node);
  }

  void _willUnfocusNode(FocusNode node) {
    assert(node != null);
    if (_currentFocus == node) {
      _currentFocus = null;
      _dirtyNodes.add(node);
      _markNeedsUpdate();
    }
    if (_nextFocus == node) {
      _nextFocus = null;
      _dirtyNodes.add(node);
      _markNeedsUpdate();
    }
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

  void _applyFocusChange() {
    _haveScheduledUpdate = false;
    final FocusNode previousFocus = _currentFocus;
    if (_currentFocus == null && _nextFocus == null) {
      _nextFocus = rootScope;
    }
    if (_nextFocus != null && _nextFocus != _currentFocus) {
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
      rootScope.toDiagnosticsNode(name: 'rootScope'),
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties.add(FlagProperty('haveScheduledUpdate', value: _haveScheduledUpdate, ifTrue: 'UPDATE SCHEDULED'));
    properties.add(DiagnosticsProperty<FocusNode>('currentFocus', _currentFocus, defaultValue: null));
  }
}

/// Returns a text representation of the current focus tree, along with the
/// current attributes on each node.
///
/// Will return an empty string in release builds.
String debugDescribeFocusTree() {
  assert(WidgetsBinding.instance != null);
  String result;
  assert(() {
    result = WidgetsBinding.instance.focusManager.toStringDeep();
    return true;
  }());
  return result ?? '';
}

/// Prints a text representation of the current focus tree, along with the
/// current attributes on each node.
///
/// Will do nothing in release builds.
void debugDumpFocusTree() {
  assert(() {
    debugPrint(debugDescribeFocusTree());
    return true;
  }());
}
