// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import 'binding.dart';
import 'focus_scope.dart';
import 'focus_traversal.dart';
import 'framework.dart';

// Used for debugging focus code. Set to true to see highly verbose debug output
// when focus changes occur.
const bool _kDebugFocus = false;

bool _focusDebug(String message, [Iterable<String> details]) {
  if (_kDebugFocus) {
    debugPrint('FOCUS: $message');
    if (details != null && details.isNotEmpty) {
      for (String detail in details) {
        debugPrint('    $detail');
      }
    }
  }
  return true;
}

/// Signature of a callback used by [Focus.onKey] and [FocusScope.onKey]
/// to receive key events.
///
/// The [node] is the node that received the event.
typedef FocusOnKeyCallback = bool Function(FocusNode node, RawKeyEvent event);

/// An attachment point for a [FocusNode].
///
/// Once created, a [FocusNode] must be attached to the widget tree by its
/// _host_ [StatefulWidget] via a [FocusAttachment] object. [FocusAttachment]s
/// are owned by the [StatefulWidget] that hosts a [FocusNode] or
/// [FocusScopeNode]. There can be multiple [FocusAttachment]s for each
/// [FocusNode], but the node will only ever be attached to one of them at a
/// time.
///
/// This attachment is created by calling [FocusNode.attach], usually from the
/// host widget's [State.initState] method. If the widget is updated to have a
/// different focus node, then the new node needs to be attached in
/// [State.didUpdateWidget], after calling [detach] on the previous
/// [FocusAttachment]. Once detached, the attachment is defunct and will no
/// longer make changes to the [FocusNode] through [reparent].
///
/// Without these attachment points, it would be possible for a focus node to
/// simultaneously be attached to more than one part of the widget tree during
/// the build stage.
class FocusAttachment {
  /// A private constructor, because [FocusAttachment]s are only to be created
  /// by [FocusNode.attach].
  FocusAttachment._(this._node) : assert(_node != null);

  // The focus node that this attachment manages an attachment for. The node may
  // not yet have a parent, or may have been detached from this attachment, so
  // don't count on this node being in a usable state.
  final FocusNode _node;

  /// Returns true if the associated node is attached to this attachment.
  ///
  /// It is possible to be attached to the widget tree, but not be placed in
  /// the focus tree (i.e. to not have a parent yet in the focus tree).
  bool get isAttached => _node._attachment == this;

  /// Detaches the [FocusNode] this attachment point is associated with from the
  /// focus tree, and disconnects it from this attachment point.
  ///
  /// Calling [FocusNode.dispose] will also automatically detach the node.
  void detach() {
    assert(_node != null);
    assert(_focusDebug('Detaching node:', <String>[_node.toString(), 'With enclosing scope ${_node.enclosingScope}']));
    if (isAttached) {
      if (_node.hasPrimaryFocus) {
        _node.unfocus();
      }
      _node._parent?._removeChild(_node);
      _node._attachment = null;
    }
    assert(!isAttached);
  }

  /// Ensures that the [FocusNode] attached at this attachment point has the
  /// proper parent node, changing it if necessary.
  ///
  /// If given, ensures that the given [parent] node is the parent of the node
  /// that is attached at this attachment point, changing it if necessary.
  /// However, it is usually not necessary to supply an explicit parent, since
  /// [reparent] will use [Focus.of] to determine the correct parent node for
  /// the context given in [FocusNode.attach].
  ///
  /// If [isAttached] is false, then calling this method does nothing.
  ///
  /// Should be called whenever the associated widget is rebuilt in order to
  /// maintain the focus hierarchy.
  ///
  /// A [StatefulWidget] that hosts a [FocusNode] should call this method on the
  /// node it hosts during its [State.build] or [State.didChangeDependencies]
  /// methods in case the widget is moved from one location in the tree to
  /// another location that has a different [FocusScope] or context.
  ///
  /// The optional [parent] argument must be supplied when not using [Focus] and
  /// [FocusScope] widgets to build the focus tree, or if there is a need to
  /// supply the parent explicitly (which are both uncommon).
  void reparent({FocusNode parent}) {
    assert(_node != null);
    if (isAttached) {
      assert(_node.context != null);
      parent ??= Focus.of(_node.context, nullOk: true);
      parent ??= FocusScope.of(_node.context);
      assert(parent != null);
      parent._reparent(_node);
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
/// representation of the widgets in the hierarchy that are interested in focus.
/// A focus node might need to be created if it is passed in from an ancestor of
/// a [Focus] widget to control the focus of the children from the ancestor, or
/// a widget might need to host one if the widget subsystem is not being used,
/// or if the [Focus] and [FocusScope] widgets provide insufficient control.
///
/// [FocusNodes] are organized into _scopes_ (see [FocusScopeNode]), which form
/// sub-trees of nodes that can be traversed as a group. Within a scope, the
/// most recent nodes to have focus are remembered, and if a node is focused and
/// then removed, the previous node receives focus again.
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
/// {@template flutter.widgets.focus_manager.focus.lifecycle}
/// ## Lifecycle
///
/// There are several actors involved in the lifecycle of a
/// [FocusNode]/[FocusScopeNode]. They are created and disposed by their
/// _owner_, attached, detached, and reparented using a [FocusAttachment] by
/// their _host_ (which must be owned by the [State] of a [StatefulWidget]), and
/// they are managed by the [FocusManager]. Different parts of the [FocusNode]
/// API are intended for these different actors.
///
/// [FocusNode]s (and hence [FocusScopeNode]s) are persistent objects that form
/// part of a _focus tree_ that is a sparse representation of the widgets in the
/// hierarchy that are interested in receiving keyboard events. They must be
/// managed like other persistent state, which is typically done by a
/// [StatefulWidget] that owns the node. A stateful widget that owns a focus
/// scope node must call [dispose] from its [State.dispose] method.
///
/// Once created, a [FocusNode] must be attached to the widget tree via a
/// [FocusAttachment] object. This attachment is created by calling [attach],
/// usually from the [State.initState] method. If the hosting widget is updated
/// to have a different focus node, then the updated node needs to be attached
/// in [State.didUpdateWidget], after calling [detach] on the previous
/// [FocusAttachment].
///
/// Because [FocusNode]s form a sparse representation of the widget tree,
/// they must be updated whenever the widget tree is rebuilt. This is done by
/// calling [FocusAttachment.reparent], usually from the [State.build] or
/// [State.didChangeDependencies] methods of the widget that represents the
/// focused region, so that the [BuildContext] assigned to the [FocusScopeNode]
/// can be tracked (the context is used to obtain the [RenderObject], from which
/// the geometry of focused regions can be determined).
///
/// Creating a [FocusNode] each time [State.build] is invoked will cause the
/// focus to be lost each time the widget is built, which is usually not desired
/// behavior (call [unfocus] if losing focus is desired).
///
/// If, as is common, the hosting [StatefulWidget] is also the owner of the
/// focus node, then it will also call [dispose] from its [State.dispose] (in
/// which case the [detach] may be skipped, since dispose will automatically
/// detach). If another object owns the focus node, then it must call [dispose]
/// when the node is done being used.
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
/// ## Focus Traversal
///
/// The term _traversal_, sometimes called _tab traversal_, refers to moving the
/// focus from one widget to the next in a particular order (also sometimes
/// referred to as the _tab order_, since the TAB key is often bound to the
/// action to move to the next widget).
///
/// To give focus to the logical _next_ or _previous_ widget in the UI, call the
/// [nextFocus] or [previousFocus] methods. To give the focus to a widget in a
/// particular direction, call the [focusInDirection] method.
///
/// The policy for what the _next_ or _previous_ widget is, or the widget in a
/// particular direction, is determined by the [FocusTraversalPolicy] in force.
///
/// The ambient policy is determined by looking up the widget hierarchy for a
/// [DefaultFocusTraversal] widget, and obtaining the focus traversal policy
/// from it. Different focus nodes can inherit difference policies, so part of
/// the app can go in widget order, and part can go in reading order, depending
/// upon the use case.
///
/// Predefined policies include [WidgetOrderFocusTraversalPolicy],
/// [ReadingOrderTraversalPolicy], and [DirectionalFocusTraversalPolicyMixin],
/// but custom policies can be built based upon these policies.
///
/// {@tool snippet --template=stateless_widget_scaffold}
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
///   bool _focused = false;
///   FocusAttachment _nodeAttachment;
///   Color _color = Colors.white;
///
///   @override
///   void initState() {
///     super.initState();
///     _node = FocusNode(debugLabel: 'Button');
///     _node.addListener(_handleFocusChange);
///     _nodeAttachment = _node.attach(context, onKey: _handleKeyPress);
///   }
///
///   void _handleFocusChange() {
///     if (_node.hasFocus != _focused) {
///       setState(() {
///         _focused = _node.hasFocus;
///       });
///     }
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
///     _node.removeListener(_handleFocusChange);
///     // The attachment will automatically be detached in dispose().
///     _node.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     _nodeAttachment.reparent();
///     return GestureDetector(
///       onTap: () {
///         if (_focused) {
///             _node.unfocus();
///         } else {
///            _node.requestFocus();
///         }
///       },
///       child: Center(
///         child: Container(
///           width: 400,
///           height: 100,
///           color: _focused ? _color : Colors.white,
///           alignment: Alignment.center,
///           child: Text(
///               _focused ? "I'm in color! Press R,G,B!" : 'Press to focus'),
///         ),
///       ),
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
///     widget tree.
///   * [FocusManager], a singleton that manages the focus and distributes key
///     events to focused nodes.
///   * [FocusTraversalPolicy], a class used to determine how to move the focus
///     to other nodes.
///   * [DefaultFocusTraversal], a widget used to configure the default focus
///     traversal policy for a widget subtree.
class FocusNode with DiagnosticableTreeMixin, ChangeNotifier {
  /// Creates a focus node.
  ///
  /// The [debugLabel] is ignored on release builds.
  FocusNode({
    String debugLabel,
    FocusOnKeyCallback onKey,
    bool skipTraversal = false,
    bool canRequestFocus = true,
  })  : assert(skipTraversal != null),
        assert(canRequestFocus != null),
        _skipTraversal = skipTraversal,
        _canRequestFocus = canRequestFocus,
        _onKey = onKey {
    // Set it via the setter so that it does nothing on release builds.
    this.debugLabel = debugLabel;
  }

  /// If true, tells the focus traversal policy to skip over this node for
  /// purposes of the traversal algorithm.
  ///
  /// This may be used to place nodes in the focus tree that may be focused, but
  /// not traversed, allowing them to receive key events as part of the focus
  /// chain, but not be traversed to via focus traversal.
  ///
  /// This is different from [canRequestFocus] because it only implies that the
  /// node can't be reached via traversal, not that it can't be focused. It may
  /// still be focused explicitly.
  bool get skipTraversal => _skipTraversal;
  bool _skipTraversal;
  set skipTraversal(bool value) {
    if (value != _skipTraversal) {
      _skipTraversal = value;
      _manager?._dirtyNodes?.add(this);
      _manager?._markNeedsUpdate();
    }
  }

  /// If true, this focus node may request the primary focus.
  ///
  /// Defaults to true.  Set to false if you want this node to do nothing when
  /// [requestFocus] is called on it. Does not affect the children of this node,
  /// and [hasFocus] can still return true if this node is the ancestor of a
  /// node with primary focus.
  ///
  /// This is different than [skipTraversal] because [skipTraversal] still
  /// allows the node to be focused, just not traversed to via the
  /// [FocusTraversalPolicy]
  ///
  /// Setting [canRequestFocus] to false implies that the node will also be
  /// skipped for traversal purposes.
  ///
  /// See also:
  ///
  ///   - [DefaultFocusTraversal], a widget that sets the traversal policy for
  ///     its descendants.
  ///   - [FocusTraversalPolicy], a class that can be extended to describe a
  ///     traversal policy.
  bool get canRequestFocus => _canRequestFocus;
  bool _canRequestFocus;
  set canRequestFocus(bool value) {
    if (value != _canRequestFocus) {
      _canRequestFocus = value;
      if (!_canRequestFocus) {
        unfocus();
      }
      _manager?._dirtyNodes?.add(this);
      _manager?._markNeedsUpdate();
    }
  }

  /// The context that was supplied to [attach].
  ///
  /// This is typically the context for the widget that is being focused, as it
  /// is used to determine the bounds of the widget.
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
  /// done using [FocusAttachment.reparent].
  FocusNode get parent => _parent;
  FocusNode _parent;

  /// An iterator over the children of this node.
  Iterable<FocusNode> get children => _children;
  final List<FocusNode> _children = <FocusNode>[];

  /// An iterator over the children that are allowed to be traversed by the
  /// [FocusTraversalPolicy].
  Iterable<FocusNode> get traversalChildren {
    return children.where(
      (FocusNode node) => !node.skipTraversal && node.canRequestFocus,
    );
  }

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

  /// Returns all descendants which do not have the [skipTraversal] flag set.
  Iterable<FocusNode> get traversalDescendants => descendants.where((FocusNode node) => !node.skipTraversal && node.canRequestFocus);

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

  /// Whether this node has input focus.
  ///
  /// A [FocusNode] has focus when it is an ancestor of a node that returns true
  /// from [hasPrimaryFocus], or it has the primary focus itself.
  ///
  /// The [hasFocus] accessor is different from [hasPrimaryFocus] in that
  /// [hasFocus] is true if the node is anywhere in the focus chain, but for
  /// [hasPrimaryFocus] the node must to be at the end of the chain to return
  /// true.
  ///
  /// A node that returns true for [hasFocus] will receive key events if none of
  /// its focused descendants returned true from their [onKey] handler.
  ///
  /// This object is a [ChangeNotifier], and notifies its [Listenable] listeners
  /// (registered via [addListener]) whenever this value changes.
  ///
  /// See also:
  ///
  ///   * [Focus.isAt], which is a static method that will return the focus
  ///     state of the nearest ancestor [Focus] widget's focus node.
  bool get hasFocus {
    if (_manager?.primaryFocus == null) {
      return false;
    }
    if (hasPrimaryFocus) {
      return true;
    }
    return _manager.primaryFocus.ancestors.contains(this);
  }

  /// Returns true if this node currently has the application-wide input focus.
  ///
  /// A [FocusNode] has the primary focus when the node is focused in its
  /// nearest ancestor [FocusScopeNode] and [hasFocus] is true for all its
  /// ancestor nodes, but none of its descendants.
  ///
  /// This is different from [hasFocus] in that [hasFocus] is true if the node
  /// is anywhere in the focus chain, but here the node has to be at the end of
  /// the chain to return true.
  ///
  /// A node that returns true for [hasPrimaryFocus] will be the first node to
  /// receive key events through its [onKey] handler.
  ///
  /// This object notifies its listeners whenever this value changes.
  bool get hasPrimaryFocus => _manager?.primaryFocus == this;

  /// Returns the [FocusHighlightMode] that is currently in effect for this node.
  FocusHighlightMode get highlightMode => WidgetsBinding.instance.focusManager.highlightMode;

  /// Returns the nearest enclosing scope node above this node, including
  /// this node, if it's a scope.
  ///
  /// Returns null if no scope is found.
  ///
  /// Use [enclosingScope] to look for scopes above this node.
  FocusScopeNode get nearestScope => enclosingScope;

  /// Returns the nearest enclosing scope node above this node, or null if the
  /// node has not yet be added to the focus tree.
  ///
  /// If this node is itself a scope, this will only return ancestors of this
  /// scope.
  ///
  /// Use [nearestScope] to start at this node instead of above it.
  FocusScopeNode get enclosingScope {
    return ancestors.firstWhere((FocusNode node) => node is FocusScopeNode, orElse: () => null);
  }

  /// Returns the size of the attached widget's [RenderObject], in logical
  /// units.
  Size get size {
    assert(
        context != null,
        "Tried to get the size of a focus node that didn't have its context set yet.\n"
        'The context needs to be set before trying to evaluate traversal policies. This '
        'is typically done with the attach method.');
    return context.findRenderObject().semanticBounds.size;
  }

  /// Returns the global offset to the upper left corner of the attached
  /// widget's [RenderObject], in logical units.
  Offset get offset {
    assert(
        context != null,
        "Tried to get the offset of a focus node that didn't have its context set yet.\n"
        'The context needs to be set before trying to evaluate traversal policies. This '
        'is typically done with the attach method.');
    final RenderObject object = context.findRenderObject();
    return MatrixUtils.transformPoint(object.getTransformTo(null), object.semanticBounds.topLeft);
  }

  /// Returns the global rectangle of the attached widget's [RenderObject], in
  /// logical units.
  Rect get rect {
    assert(
        context != null,
        "Tried to get the bounds of a focus node that didn't have its context set yet.\n"
        'The context needs to be set before trying to evaluate traversal policies. This '
        'is typically done with the attach method.');
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
    if (hasPrimaryFocus) {
      final FocusScopeNode scope = enclosingScope;
      assert(scope != null, 'Node has primary focus, but no enclosingScope.');
      scope._focusedChildren.remove(this);
      _manager?._willUnfocusNode(this);
      return;
    }
    if (hasFocus) {
      // If we are in the focus chain, but not the primary focus, then unfocus
      // the primary instead.
      _manager.primaryFocus.unfocus();
    }
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

  // Removes the given FocusNode and its children as a child of this node.
  @mustCallSuper
  void _removeChild(FocusNode node) {
    assert(node != null);
    assert(_children.contains(node), "Tried to remove a node that wasn't a child.");
    assert(node._parent == this);
    assert(node._manager == _manager);

    node.enclosingScope?._focusedChildren?.remove(node);

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
    final FocusScopeNode oldScope = child.enclosingScope;
    final bool hadFocus = child.hasFocus;
    child._parent?._removeChild(child);
    _children.add(child);
    child._parent = this;
    child._updateManager(_manager);
    if (hadFocus) {
      // Update the focus chain for the current focus without changing it.
      _manager?.primaryFocus?._setAsFocusedChild();
    }
    if (oldScope != null && child.context != null && child.enclosingScope != oldScope) {
      DefaultFocusTraversal.of(child.context, nullOk: true)?.changedScope(node: child, oldScope: oldScope);
    }
  }

  /// Called by the _host_ [StatefulWidget] to attach a [FocusNode] to the
  /// widget tree.
  ///
  /// In order to attach a [FocusNode] to the widget tree, call [attach],
  /// typically from the [StatefulWidget]'s [State.initState] method.
  ///
  /// If the focus node in the host widget is swapped out, the new node will
  /// need to be attached. [FocusAttachment.detach] should be called on the old
  /// node, and then [attach] called on the new node. This typically happens in
  /// the [State.didUpdateWidget] method.
  @mustCallSuper
  FocusAttachment attach(BuildContext context, {FocusOnKeyCallback onKey}) {
    _context = context;
    _onKey = onKey ?? _onKey;
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

  /// Requests the primary focus for this node, or for a supplied [node], which
  /// will also give focus to its [ancestors].
  ///
  /// If called without a node, request focus for this node.
  ///
  /// If the given [node] is not yet a part of the focus tree, then this method
  /// will add the [node] as a child of this node before requesting focus.
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
      assert(node.ancestors.contains(this), 'Focus was requested for a node that is not a descendant of the scope from which it was requested.');
      node._doRequestFocus();
      return;
    }
    _doRequestFocus();
  }

  // Note that this is overridden in FocusScopeNode.
  void _doRequestFocus() {
    if (!canRequestFocus) {
      return;
    }
    _setAsFocusedChild();
    if (hasPrimaryFocus) {
      return;
    }
    _hasKeyboardToken = true;
    _markAsDirty(newFocus: this);
  }

  /// Sets this node as the [FocusScopeNode.focusedChild] of the enclosing
  /// scope.
  ///
  /// Sets this node as the focused child for the enclosing scope, and that
  /// scope as the focused child for the scope above it, etc., until it reaches
  /// the root node. It doesn't change the primary focus, it just changes what
  /// node would be focused if the enclosing scope receives focus, and keeps
  /// track of previously focused children in that scope, so that if the focused
  /// child in that scope is removed, the previous focus returns.
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

  /// Request to move the focus to the next focus node, by calling the
  /// [FocusTraversalPolicy.next] method.
  ///
  /// Returns true if it successfully found a node and requested focus.
  bool nextFocus() => DefaultFocusTraversal.of(context).next(this);

  /// Request to move the focus to the previous focus node, by calling the
  /// [FocusTraversalPolicy.previous] method.
  ///
  /// Returns true if it successfully found a node and requested focus.
  bool previousFocus() => DefaultFocusTraversal.of(context).previous(this);

  /// Request to move the focus to the nearest focus node in the given
  /// direction, by calling the [FocusTraversalPolicy.inDirection] method.
  ///
  /// Returns true if it successfully found a node and requested focus.
  bool focusInDirection(TraversalDirection direction) => DefaultFocusTraversal.of(context).inDirection(this, direction);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BuildContext>('context', context, defaultValue: null));
    properties.add(FlagProperty('canRequestFocus', value: canRequestFocus, ifFalse: 'NOT FOCUSABLE', defaultValue: true));
    properties.add(FlagProperty('hasFocus', value: hasFocus, ifTrue: 'FOCUSED', defaultValue: false));
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    int count = 1;
    return _children.map<DiagnosticsNode>((FocusNode child) {
      return child.toDiagnosticsNode(name: 'Child ${count++}');
    }).toList();
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
/// {@macro flutter.widgets.focus_manager.focus.lifecycle}
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
    assert(_focusedChildren.isEmpty || _focusedChildren.last.enclosingScope == this, 'Focused child does not have the same idea of its enclosing scope as the scope does.');
    return _focusedChildren.isNotEmpty ? _focusedChildren.last : null;
  }

  // A stack of the children that have been set as the focusedChild, most recent
  // last (which is the top of the stack).
  final List<FocusNode> _focusedChildren = <FocusNode>[];

  /// Make the given [scope] the active child scope for this scope.
  ///
  /// If the given [scope] is not yet a part of the focus tree, then add it to
  /// the tree as a child of this scope. If it is already part of the focus
  /// tree, the given scope must be a descendant of this scope.
  void setFirstFocus(FocusScopeNode scope) {
    assert(scope != null);
    assert(scope != this, 'Unexpected self-reference in setFirstFocus.');
    if (scope._parent == null) {
      _reparent(scope);
    }
    assert(scope.ancestors.contains(this), '$FocusScopeNode $scope must be a child of $this to set it as first focus.');
    if (hasFocus) {
      scope._doRequestFocus();
    } else {
      scope._setAsFocusedChild();
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
      assert(node.ancestors.contains(this), 'Autofocus was requested for a node that is not a descendant of the scope from which it was requested.');
      node._doRequestFocus();
    }
  }

  @override
  void _doRequestFocus() {
    if (!canRequestFocus) {
      return;
    }

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
      _setAsFocusedChild();
      _markAsDirty(newFocus: primaryFocus);
    } else {
      // We found a FocusScope at the leaf, so ask it to focus itself instead of
      // this scope. That will cause this scope to return true from hasFocus,
      // but false from hasPrimaryFocus.
      primaryFocus.requestFocus();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusNode>('focusedChild', focusedChild, defaultValue: null));
  }
}

/// An enum to describe which kind of focus highlight behavior to use when
/// displaying focus information.
enum FocusHighlightMode {
  /// Touch interfaces will not show the focus highlight except for controls
  /// which bring up the soft keyboard.
  ///
  /// If a device that uses a traditional mouse and keyboard has a touch screen
  /// attached, it can also enter `touch` mode if the user is using the touch
  /// screen.
  touch,

  /// Traditional interfaces (keyboard and mouse) will show the currently
  /// focused control via a focus highlight of some sort.
  ///
  /// If a touch device (like a mobile phone) has a keyboard and/or mouse
  /// attached, it also can enter `traditional` mode if the user is using these
  /// input devices.
  traditional,
}

/// An enum to describe how the current value of [FocusManager.highlightMode] is
/// determined. The strategy is set on [FocusManager.highlightStrategy].
enum FocusHighlightStrategy {
  /// Automatic switches between the various highlight modes based on the last
  /// kind of input that was received. This is the default.
  automatic,

  /// [FocusManager.highlightMode] always returns [FocusHighlightMode.touch].
  alwaysTouch,

  /// [FocusManager.highlightMode] always returns [FocusHighlightMode.traditional].
  alwaysTraditional,
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
///  * [FocusNode], which is a node in the focus tree that can receive focus.
///  * [FocusScopeNode], which is a node in the focus tree used to collect
///    subtrees into groups.
///  * [Focus.of], which provides the nearest ancestor [FocusNode] for a given
///    [BuildContext].
///  * [FocusScope.of], which provides the nearest ancestor [FocusScopeNode] for
///    a given [BuildContext].
class FocusManager with DiagnosticableTreeMixin {
  /// Creates an object that manages the focus tree.
  ///
  /// This constructor is rarely called directly. To access the [FocusManager],
  /// consider using [WidgetsBinding.focusManager] instead.
  FocusManager() {
    rootScope._manager = this;
    RawKeyboard.instance.addListener(_handleRawKeyEvent);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
  }

  bool _lastInteractionWasTouch = true;

  /// Sets the strategy by which [highlightMode] is determined.
  ///
  /// If set to [FocusHighlightStrategy.automatic], then the highlight mode will
  /// change depending upon the interaction mode used last. For instance, if the
  /// last interaction was a touch interaction, then [highlightMode] will return
  /// [FocusHighlightMode.touch], and focus highlights will only appear on
  /// widgets that bring up a soft keyboard. If the last interaction was a
  /// non-touch interaction (hardware keyboard press, mouse click, etc.), then
  /// [highlightMode] will return [FocusHighlightMode.traditional], and focus
  /// highlights will appear on all widgets.
  ///
  /// If set to [FocusHighlightStrategy.alwaysTouch] or
  /// [FocusHighlightStrategy.alwaysTraditional], then [highlightMode] will
  /// always return [FocusHighlightMode.touch] or
  /// [FocusHighlightMode.traditional], respectively, regardless of the last UI
  /// interaction type.
  ///
  /// The initial value of [highlightMode] depends upon the value of
  /// [defaultTargetPlatform] and
  /// [RendererBinding.instance.mouseTracker.mouseIsConnected], making a guess
  /// about which interaction is most appropriate for the initial interaction
  /// mode.
  ///
  /// Defaults to [FocusHighlightStrategy.automatic].
  FocusHighlightStrategy get highlightStrategy => _highlightStrategy;
  FocusHighlightStrategy _highlightStrategy = FocusHighlightStrategy.automatic;
  set highlightStrategy(FocusHighlightStrategy highlightStrategy) {
    _highlightStrategy = highlightStrategy;
    _updateHighlightMode();
  }

  /// Indicates the current interaction mode for focus highlights.
  ///
  /// The value returned depends upon the [highlightStrategy] used, and possibly
  /// (depending on the value of [highlightStrategy]) the most recent
  /// interaction mode that they user used.
  ///
  /// If [highlightMode] returns [FocusHighlightMode.touch], then widgets should
  /// not draw their focus highlight unless they perform text entry.
  ///
  /// If [highlightMode] returns [FocusHighlightMode.traditional], then widgets should
  /// draw their focus highlight whenever they are focused.
  FocusHighlightMode get highlightMode => _highlightMode;
  FocusHighlightMode _highlightMode = FocusHighlightMode.touch;

  // Update function to be called whenever the state relating to highlightMode
  // changes.
  void _updateHighlightMode() {
    // Assume that if we're on one of these mobile platforms, or if there's no
    // mouse connected, that the initial interaction will be touch-based, and
    // that it's traditional mouse and keyboard on all others.
    //
    // This only affects the initial value: the ongoing value is updated as soon
    // as any input events are received.
    _lastInteractionWasTouch ??= Platform.isAndroid || Platform.isIOS || !WidgetsBinding.instance.mouseTracker.mouseIsConnected;
    FocusHighlightMode newMode;
    switch (highlightStrategy) {
      case FocusHighlightStrategy.automatic:
        if (_lastInteractionWasTouch) {
          newMode = FocusHighlightMode.touch;
        } else {
          newMode = FocusHighlightMode.traditional;
        }
        break;
      case FocusHighlightStrategy.alwaysTouch:
        newMode = FocusHighlightMode.touch;
        break;
      case FocusHighlightStrategy.alwaysTraditional:
        newMode = FocusHighlightMode.traditional;
        break;
    }
    if (newMode != _highlightMode) {
      _highlightMode = newMode;
      _notifyHighlightModeListeners();
    }
  }

  // The list of listeners for [highlightMode] state changes.
  final HashedObserverList<ValueChanged<FocusHighlightMode>> _listeners = HashedObserverList<ValueChanged<FocusHighlightMode>>();

  /// Register a closure to be called when the [FocusManager] notifies its listeners
  /// that the value of [highlightMode] has changed.
  void addHighlightModeListener(ValueChanged<FocusHighlightMode> listener) => _listeners.add(listener);

  /// Remove a previously registered closure from the list of closures that the
  /// [FocusManager] notifies.
  void removeHighlightModeListener(ValueChanged<FocusHighlightMode> listener) => _listeners?.remove(listener);

  void _notifyHighlightModeListeners() {
    if (_listeners.isEmpty) {
      return;
    }
    final List<ValueChanged<FocusHighlightMode>> localListeners = List<ValueChanged<FocusHighlightMode>>.from(_listeners);
    for (ValueChanged<FocusHighlightMode> listener in localListeners) {
      try {
        if (_listeners.contains(listener)) {
          listener(_highlightMode);
        }
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widgets library',
          context: ErrorDescription('while dispatching notifications for $runtimeType'),
          informationCollector: () sync* {
            yield DiagnosticsProperty<FocusManager>(
              'The $runtimeType sending notification was',
              this,
              style: DiagnosticsTreeStyle.errorProperty,
            );
          },
        ));
      }
    }
  }

  /// The root [FocusScopeNode] in the focus tree.
  ///
  /// This field is rarely used directly. To find the nearest [FocusScopeNode]
  /// for a given [FocusNode], call [FocusNode.nearestScope].
  final FocusScopeNode rootScope = FocusScopeNode(debugLabel: 'Root Focus Scope');

  void _handlePointerEvent(PointerEvent event) {
    bool currentInteractionIsTouch;
    switch (event.kind) {
      case PointerDeviceKind.touch:
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
        currentInteractionIsTouch = true;
        break;
      case PointerDeviceKind.mouse:
      case PointerDeviceKind.unknown:
        currentInteractionIsTouch = false;
        break;
    }
    if (_lastInteractionWasTouch != currentInteractionIsTouch) {
      _lastInteractionWasTouch = currentInteractionIsTouch;
      _updateHighlightMode();
    }
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    // Update highlightMode first, since things responding to the keys might
    // look at the highlight mode, and it should be accurate.
    if (_lastInteractionWasTouch) {
      _lastInteractionWasTouch = false;
      _updateHighlightMode();
    }

    // Walk the current focus from the leaf to the root, calling each one's
    // onKey on the way up, and if one responds that they handled it, stop.
    if (_primaryFocus == null) {
      return;
    }
    Iterable<FocusNode> allNodes(FocusNode node) sync* {
      yield node;
      for (FocusNode ancestor in node.ancestors) {
        yield ancestor;
      }
    }

    for (FocusNode node in allNodes(_primaryFocus)) {
      if (node.onKey != null && node.onKey(node, event)) {
        break;
      }
    }
  }

  /// The node that currently has the primary focus.
  FocusNode get primaryFocus => _primaryFocus;
  FocusNode _primaryFocus;

  // The node that has requested to have the primary focus, but hasn't been
  // given it yet.
  FocusNode _nextFocus;
  // The set of nodes that need to notify their listeners of changes at the next
  // update.
  final Set<FocusNode> _dirtyNodes = <FocusNode>{};

  // Called to indicate that the given node is being disposed.
  void _willDisposeFocusNode(FocusNode node) {
    assert(node != null);
    assert(_focusDebug('Disposing of node:', <String>[node.toString(), 'with enclosing scope ${node.enclosingScope}']));
    _willUnfocusNode(node);
    _dirtyNodes.remove(node);
  }

  // Called to indicate that the given node is being unfocused, and that any
  // pending request to be focused should be canceled.
  void _willUnfocusNode(FocusNode node) {
    assert(node != null);
    assert(_focusDebug('Unfocusing node $node'));
    if (_primaryFocus == node) {
      _primaryFocus = null;
      _dirtyNodes.add(node);
      _markNeedsUpdate();
    }
    if (_nextFocus == node) {
      _nextFocus = null;
      _dirtyNodes.add(node);
      _markNeedsUpdate();
    }
    assert(_focusDebug('Unfocused node $node:', <String>['primary focus is $_primaryFocus', 'next focus will be $_nextFocus']));
  }

  // True indicates that there is an update pending.
  bool _haveScheduledUpdate = false;

  // Request that an update be scheduled, optionally requesting focus for the
  // given newFocus node.
  void _markNeedsUpdate({FocusNode newFocus}) {
    // If newFocus isn't specified, then don't mess with _nextFocus, just
    // schedule the update.
    _nextFocus = newFocus ?? _nextFocus;
    assert(_focusDebug('Scheduling update, next focus will be $_nextFocus'));
    if (_haveScheduledUpdate) {
      return;
    }
    _haveScheduledUpdate = true;
    scheduleMicrotask(_applyFocusChange);
  }

  void _applyFocusChange() {
    _haveScheduledUpdate = false;
    assert(_focusDebug('Refreshing focus state. Next focus will be $_nextFocus'));
    final FocusNode previousFocus = _primaryFocus;
    if (_primaryFocus == null && _nextFocus == null) {
      // If we don't have any current focus, and nobody has asked to focus yet,
      // then pick a first one using widget order as a default.
      _nextFocus = rootScope;
    }
    if (_nextFocus != null && _nextFocus != _primaryFocus) {
      _primaryFocus = _nextFocus;
      final Set<FocusNode> previousPath = previousFocus?.ancestors?.toSet() ?? <FocusNode>{};
      final Set<FocusNode> nextPath = _nextFocus.ancestors.toSet();
      // Notify nodes that are newly focused.
      _dirtyNodes.addAll(nextPath.difference(previousPath));
      // Notify nodes that are no longer focused
      _dirtyNodes.addAll(previousPath.difference(nextPath));
      _nextFocus = null;
    }
    if (previousFocus != _primaryFocus) {
      assert(_focusDebug('Updating focus from $previousFocus to $_primaryFocus'));
      if (previousFocus != null) {
        _dirtyNodes.add(previousFocus);
      }
      if (_primaryFocus != null) {
        _dirtyNodes.add(_primaryFocus);
      }
    }
    assert(_focusDebug('Notifying ${_dirtyNodes.length} dirty nodes:', _dirtyNodes.toList().map<String>((FocusNode node) => node.toString())));
    for (FocusNode node in _dirtyNodes) {
      node._notify();
    }
    _dirtyNodes.clear();
    assert(() {
      if (_kDebugFocus) {
        debugDumpFocusTree();
      }
      return true;
    }());
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
    properties.add(DiagnosticsProperty<FocusNode>('primaryFocus', primaryFocus, defaultValue: null));
    final Element element = primaryFocus?.context;
    if (element != null) {
      properties.add(DiagnosticsProperty<String>('primaryFocusCreator', element.debugGetCreatorChain(20)));
    }
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
