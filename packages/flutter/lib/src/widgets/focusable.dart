// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'focusable_manager.dart';
import 'framework.dart';
import 'raw_keyboard_listener.dart';

/// Signature for key events that occurred on a [Focusable] widget.
///
/// This is the type of the [Focusable.onKey] callback.
typedef FocusableOnKeyCallback = bool Function(FocusableNode node, RawKeyEvent event);

/// Signature for the callback that reports when the [Focusable] sets or changes
/// the [FocusableNode] that it manages.
///
/// If the [newNode] is null, then the [oldNode] is being disposed, and you must
/// unregister any listeners with [FocusableNode.removeListener].  If [oldNode]
/// is null, then the node is being initialized.
///
/// It is used by the [Focusable.onFocusableNodeSet] and
/// [EditableText.onFocusableNodeSet] callbacks, among others.
typedef FocusableNodeSetCallback = void Function(FocusableNode newNode, FocusableNode oldNode);

/// A widget that manages a [FocusableNode] to allow input focus to be given
/// to this widget and its descendants.
///
/// It manages a [FocusableNode], managing its lifecycle, and listening for
/// changes in focus.
///
/// It provides [onFocusChange] as a way to be notified when the focus is given
/// to or removed from this widget.
///
/// The [onKey] argument allows specification of a key event handler that should
/// be invoked when this node or one of its children has focus.
///
/// This widget does not provide any visual indication that the focus has
/// changed. To provide that, add a [FocusHighlight] widget as a descendant of
/// this widget, or provide your own indication based on changes notified by
/// [onFocusChange].
///
/// See also:
///
///   * [FocusableScopeNode], to collect nodes into a group and specify focus
///     traversal order within the group, and manipulate the focus.
class Focusable extends StatefulWidget {
  /// Creates a widget that manages a [FocusableNode]
  ///
  /// The [child] argument is required and must not be null.
  ///
  /// The [autofocus] argument must not be null.
  const Focusable({
    Key key,
    @required this.child,
    this.autofocus = false,
    this.onFocusChange,
    this.onFocusableNodeSet,
    this.onKey,
    this.debugLabel,
  })  : assert(child != null),
        assert(autofocus != null),
        super(key: key);

  /// A debug label for this widget.
  final String debugLabel;

  /// The child widget of this [Focusable].
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Handler for keys pressed when this object or one of its children has
  /// focus.
  ///
  /// Key events are first given to the leaf nodes, and if they don't handle
  /// them, then to each node up the widget hierarchy. If they reach the root of
  /// the hierarchy, they are discarded.
  ///
  /// This is not the way to get text input in the manner of a text field: it
  /// leaves out support for input method editors, and doesn't support soft
  /// keyboards in general. For text input, consider [TextField] or
  /// [CupertinoTextField], or (if you need more control over the
  /// behavior/presentation) [EditableText], which do support these things.
  final FocusableOnKeyCallback onKey;

  /// Handler called when the focus of this focusable changes.
  ///
  /// Called with true if this focusable gains focus, and false if it loses
  /// focus.
  final ValueChanged<bool> onFocusChange;

  /// Called when the managed FocusableNode is created or changed.
  final FocusableNodeSetCallback onFocusableNodeSet;

  /// True if this widget will be selected as the initial focus when no other
  /// node in its scope is currently focused.
  ///
  /// There must only be one descendant node in a scope that has `autofocus`
  /// set, unless it is the descendant of another scope.
  final bool autofocus;

  /// Returns the [node] of the [Focusable] that most tightly encloses the given
  /// [BuildContext].
  ///
  /// The [context] argument must not be null.
  static FocusableNode of(BuildContext context) {
    assert(context != null);
    final _FocusableMarker marker = context.inheritFromWidgetOfExactType(_FocusableMarker);
//    assert(() {
//      if (marker == null) {
//        throw FlutterError('Unable to find a Focusable or FocusableScope widget in the context.\n'
//            'Focusable.of() was called with a context that does not contain a Focusable.\n'
//            'No Focusable or FocusableScope ancestor could be found starting from the context that was '
//            'passed to Focusable.of(). This can happen because you do not have a '
//            'WidgetsApp or MaterialApp widget (those widgets introduce a FocusableScope at the top level), '
//            'or it can happen if the context you use comes from a widget above those widgets.\n'
//            'The context used was:\n'
//            '  $context');
//      }
//      return true;
//    }());
    return marker?.node ?? context.owner.focusableManager.rootScope;
  }

  /// A convenience function to allow build functions to write:
  /// `Focusable.at(context)` to get whether or not the nearest Focusable above
  /// them in the widget hierarchy currently has the keyboard focus.
  static bool at(BuildContext context) {
    return Focusable.of(context).hasFocus;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
    properties.add(FlagProperty('autofocus', value: autofocus, ifTrue: 'AUTOFOCUS', defaultValue: false));
  }

  @override
  _FocusableState createState() => _FocusableState();
}

class _FocusableState extends State<Focusable> {
  FocusableNode node;
  bool _hasFocus;

  FocusableNode _createNode() {
    return FocusableNode(
      debugLabel: widget.debugLabel,
      autofocus: widget.autofocus,
      context: context,
    );
  }

  void _initNode() {
    final FocusableNode old = node;
    node ??= _createNode();
    if (old != node && widget.onFocusableNodeSet != null) {
      widget.onFocusableNodeSet(node, null);
    }
    _hasFocus = node.hasFocus;
    // Add listener even if the _internalNode existed before, since it should
    // not be listening already if we're re-using a previous one.
    node.addListener(_handleFocusChanged);
  }

  @override
  void initState() {
    super.initState();
    _initNode();
  }

  @override
  void dispose() {
    node?.removeListener(_handleFocusChanged);
    if (widget.onFocusableNodeSet != null) {
      widget.onFocusableNodeSet(null, node);
    }
    node?.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) {
      return;
    }
    if (_hasFocus != node.hasFocus) {
      setState(() {
        _hasFocus = node.hasFocus;
      });
      if (widget.onFocusChange != null) {
        widget.onFocusChange(node.hasFocus);
      }
    }
  }

  @override
  void didUpdateWidget(Focusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (node == null) {
      return;
    }
    if (oldWidget.autofocus != widget.autofocus) {
      node.autofocus = widget.autofocus;
    }
    if (oldWidget.debugLabel != widget.debugLabel) {
      node.debugLabel = widget.debugLabel;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final FocusableNode newParent = Focusable.of(context);
    node.context = context;
    newParent.reparentIfNecessary(node);
  }

  @override
  Widget build(BuildContext context) {
    Focusable.of(context).reparentIfNecessary(node);
    return RawKeyboardListener(
      focusableNode: node,
      onKey: (RawKeyEvent event) {
        if (widget.onKey != null) {
          widget.onKey(node, event);
        }
      },
      child: _FocusableMarker(
        node: node,
        child: widget.child,
      ),
    );
  }
}

/// A [FocusableScope] is a [Focusable] that serves as a scope for other
/// [Focusable]s.
///
/// It manages a [FocusableScopeNode], managing its lifecycle, and listening for
/// changes in focus. Scope nodes provide a scope for their children, using the
/// focus traversal policy defined by the [DefaultFocusTraversal] widget above
/// them to traverse their children.
///
/// Scope nodes remember the last focusable node that was focused within their
/// descendants, and can move that focus to the next/previous node, or a node in
/// a particular direction when the [FocusableNode.nextFocus],
/// [FocusableNode.previousFocus], or [FocusableNode.focusInDirection] are
/// called on a [FocusableNode] or [FocusableScopeNode] that is a child of this
/// scope, or the node owned by the scope node managed by this widget.
///
/// The selection process of the node to move to is determined by the node
/// traversal policy specified by the nearest enclosing
/// [DefaultFocusTraversal] widget.
///
/// It provides [onFocusChange] as a way to be notified when the focus is given
/// to or removed from this widget, and allows specification of a
/// [focusedDecoration] to be shown when its [child] has focus.
///
/// The [onKey] argument allows specification of a key even handler that should
/// be invoked when this node or one of its children has focus.
///
/// To manipulate the focus, use methods on [FocusableScopeNode]. For instance,
/// to move the focus to the next node, call
/// `Focusable.of(context).nextFocus()`.
class FocusableScope extends Focusable {
  /// Creates a widget that manages a [FocusableScopeNode]
  ///
  /// The [child] argument is required and must not be null.
  ///
  /// The [autofocus], and [showDecorations] arguments must not be null.
  const FocusableScope({
    Key key,
    FocusableNodeSetCallback onFocusableNodeSet,
    @required Widget child,
    bool autofocus = false,
    ValueChanged<bool> onFocusChange,
    FocusableOnKeyCallback onKey,
    String debugLabel,
  })  : assert(child != null),
        assert(autofocus != null),
        super(
          key: key,
          child: child,
          autofocus: autofocus,
          onFocusChange: onFocusChange,
          onFocusableNodeSet: onFocusableNodeSet,
          onKey: onKey,
          debugLabel: debugLabel,
        );

  /// Returns the node of the [FocusableScope] that most tightly encloses the given
  /// [BuildContext].
  ///
  /// The [context] argument must not be null.
  static FocusableScopeNode of(BuildContext context) {
    assert(context != null);
    final _FocusableMarker marker = context.inheritFromWidgetOfExactType(_FocusableMarker);
//    assert(() {
//      if (marker == null) {
//        throw FlutterError('Unable to find a FocusableScope widget in the context.\n'
//            'FocusableScope.of() was called with a context that does not contain a FocusableScope.\n'
//            'No FocusableScope ancestor could be found starting from the context that was '
//            'passed to FocusableScope.of(). This can happen because you do not have a '
//            'WidgetsApp or MaterialApp widget (those widgets introduce a FocusableScope at the top level), '
//            'or it can happen if the context you use comes from a widget above those widgets.\n'
//            'The context used was:\n'
//            '  $context');
//      }
//      return true;
//    }());
    return marker?.node?.nearestScope ?? context.owner.focusableManager.rootScope;
  }

  /// Returns the ancestor nodes of the [FocusableScope] in the given
  /// [BuildContext].
  ///
  /// The [context] argument must not be null.
  static List<FocusableScopeNode> ancestorsOf(BuildContext context) {
    assert(context != null);
    final FocusableScopeNode parent = FocusableScope.of(context);
    return parent?.ancestors?.cast<FocusableScopeNode>()?.toList() ?? <FocusableScopeNode>[];
  }

  @override
  _FocusableScopeState createState() => _FocusableScopeState();
}

class _FocusableScopeState extends _FocusableState {
  @override
  FocusableScopeNode _createNode() {
    return FocusableScopeNode(
      debugLabel: widget.debugLabel,
      autofocus: widget.autofocus,
      context: context,
    );
  }
}

// The InheritedWidget marker for Focusable and FocusScope.
class _FocusableMarker extends InheritedWidget {
  const _FocusableMarker({
    Key key,
    @required this.node,
    Widget child,
  })  : assert(node != null),
        super(key: key, child: child);

  final FocusableNode node;

  @override
  bool updateShouldNotify(_FocusableMarker oldWidget) {
    return node != oldWidget.node;
  }
}
