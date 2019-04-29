// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'focus_manager.dart';
import 'framework.dart';
import 'inherited_notifier.dart';

/// A widget that manages a [FocusNode] to allow keyboard focus to be given
/// to this widget and its descendants.
///
/// When the focus is gained or lost, [onFocusChanged] is called.
///
/// For keyboard events, [onKey] is called if [FocusNode.hasFocus] is true for
/// this widget's [focusNode], unless a focused descendant's [onKey] callback
/// returns false when called.
///
/// This widget does not provide any visual indication that the focus has
/// changed. Any desired visual changes should be made when [onFocusChanged] is
/// called.
///
/// To access the [FocusNode] of the nearest ancestor [Focus] widget and
/// establish a relationship that will rebuild the widget when the focus
/// changes, use the [Focus.of] and [FocusScope.of] static methods.
///
/// To access the focused state of the nearest [Focus] widget, use
/// [Focus.hasFocus] from a build method, which also establishes a relationship
/// between the calling widget and the [Focus] widget that will rebuild the
/// calling widget when the focus changes.
///
/// Managing a [FocusNode] means managing its lifecycle, listening for changes
/// in focus, and re-parenting it when needed to keep the focus hierarchy in
/// sync with the widget hierarchy. See [FocusNode] for more information about
/// the details of what node management entails if not using a [Focus] widget.
///
/// To collect a sub-tree of nodes into a group, use a [FocusScope].
///
/// {@tool snippet --template=stateful_widget_scaffold}
/// This example shows how to manage focus using the [Focus] and [FocusScope]
/// widgets. See [FocusNode] for a similar example that doesn't use [Focus] or
/// [FocusScope].
///
/// ```dart imports
/// import 'package:flutter/services.dart';
/// ```
///
/// ```dart
/// Color _color = Colors.white;
///
/// bool _handleKeyPress(FocusNode node, RawKeyEvent event) {
///   if (event is RawKeyDownEvent) {
///     print('Focus node ${node.debugLabel} got key event: ${event.logicalKey}');
///     if (event.logicalKey == LogicalKeyboardKey.keyR) {
///       print('Changing color to red.');
///       setState(() {
///         _color = Colors.red;
///       });
///       return true;
///     } else if (event.logicalKey == LogicalKeyboardKey.keyG) {
///       print('Changing color to green.');
///       setState(() {
///         _color = Colors.green;
///       });
///       return true;
///     } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
///       print('Changing color to blue.');
///       setState(() {
///         _color = Colors.blue;
///       });
///       return true;
///     }
///   }
///   return false;
/// }
///
/// @override
/// Widget build(BuildContext context) {
///   final TextTheme textTheme = Theme.of(context).textTheme;
///   return FocusScope(
///     debugLabel: 'Scope',
///     autofocus: true,
///     child: DefaultTextStyle(
///       style: textTheme.display1,
///       child: Focus(
///         onKey: _handleKeyPress,
///         debugLabel: 'Button',
///         child: Builder(
///           builder: (BuildContext context) {
///             final FocusNode focusNode = Focus.of(context);
///             final bool hasFocus = focusNode.hasFocus;
///             return GestureDetector(
///               onTap: () {
///                 if (hasFocus) {
///                   setState(() {
///                     focusNode.unfocus();
///                   });
///                 } else {
///                   setState(() {
///                     focusNode.requestFocus();
///                   });
///                 }
///               },
///               child: Center(
///                 child: Container(
///                   width: 400,
///                   height: 100,
///                   alignment: Alignment.center,
///                   color: hasFocus ? _color : Colors.white,
///                   child: Text(hasFocus ? "I'm in color! Press R,G,B!" : 'Press to focus'),
///                 ),
///               ),
///             );
///           },
///         ),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///   * [FocusNode], which represents a node in the focus hierarchy and
///     [FocusNode]'s API documentation includes a detailed explanation of its
///     role in the overall focus system.
///   * [FocusScope], a widget that manages a group of focusable widgets using a
///     [FocusScopeNode].
///   * [FocusScopeNode], a node that collects focus nodes into a group for
///     traversal.
///   * [FocusManager], a singleton that manages the primary focus and
///     distributes key events to focused nodes.
class Focus extends StatefulWidget {
  /// Creates a widget that manages a [FocusNode].
  ///
  /// The [child] argument is required and must not be null.
  ///
  /// The [autofocus] argument must not be null.
  const Focus({
    Key key,
    @required this.child,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.onKey,
    this.debugLabel,
  })  : assert(child != null),
        assert(autofocus != null),
        super(key: key);

  /// A debug label for this widget.
  ///
  /// Not used for anything except to be printed in the diagnostic output from
  /// [toString] or [toStringDeep]. Also unused if a [focusNode] is provided,
  /// since that node can have its own [FocusNode.debugLabel].
  ///
  /// To get a string with the entire tree, call [debugDescribeFocusTree]. To
  /// print it to the console call [debugDumpFocusTree].
  ///
  /// Defaults to null.
  final String debugLabel;

  /// The child widget of this [Focus].
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Handler for keys pressed when this object or one of its children has
  /// focus.
  ///
  /// Key events are first given to the [FocusNode] that has primary focus, and
  /// if its [onKey] method return false, then they are given to each ancestor
  /// node up the focus hierarchy in turn. If an event reaches the root of the
  /// hierarchy, it is discarded.
  ///
  /// This is not the way to get text input in the manner of a text field: it
  /// leaves out support for input method editors, and doesn't support soft
  /// keyboards in general. For text input, consider [TextField],
  /// [EditableText], or [CupertinoTextField] instead, which do support these
  /// things.
  final FocusOnKeyCallback onKey;

  /// Handler called when the focus changes.
  ///
  /// Called with true if this node gains focus, and false if it loses
  /// focus.
  final ValueChanged<bool> onFocusChange;

  /// True if this widget will be selected as the initial focus when no other
  /// node in its scope is currently focused.
  ///
  /// Ideally, there is only one [Focus] with autofocus set in each
  /// [FocusScope]. If there is more than one [Focus] with autofocus set, then
  /// the first one added to the tree will get focus.
  final bool autofocus;

  /// An optional focus node to use as the focus node for this [Focus] widget.
  ///
  /// If one is not supplied, then one will be allocated and owned by this
  /// widget.
  ///
  /// Supplying a focus node is sometimes useful if an ancestor to this widget
  /// wants to control when this widget has the focus. The owner will be
  /// responsible for calling [FocusNode.dispose] on the focus node when it is
  /// done with it, but this [Focus] widget will attach/detach and reparent the
  /// node when needed.
  final FocusNode focusNode;

  /// Returns the [focusNode] of the [Focus] that most tightly encloses the given
  /// [BuildContext].
  ///
  /// If this node doesn't have a [Focus] widget ancestor, then the
  /// [FocusManager.rootScope] is returned.
  ///
  /// The [context] argument must not be null.
  static FocusNode of(BuildContext context) {
    assert(context != null);
    final _FocusMarker marker = context.inheritFromWidgetOfExactType(_FocusMarker);
    return marker?.notifier ?? context.owner.focusManager.rootScope;
  }

  /// Returns true if the nearest enclosing [Focus] widget's node is focused.
  ///
  /// A convenience method to allow build methods to write:
  /// `Focus.isAt(context)` to get whether or not the nearest [Focus] or
  /// [FocusScope] above them in the widget hierarchy currently has the keyboard
  /// focus.
  static bool isAt(BuildContext context) => Focus.of(context).hasFocus;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
    properties.add(FlagProperty('autofocus', value: autofocus, ifTrue: 'AUTOFOCUS', defaultValue: false));
    properties.add(DiagnosticsProperty<FocusScopeNode>('node', focusNode, defaultValue: null));
  }

  @override
  _FocusState createState() => _FocusState();
}

class _FocusState extends State<Focus> {
  FocusNode _internalNode;
  FocusNode get node => widget.focusNode ?? _internalNode;
  bool _hasFocus;
  bool _didAutofocus = false;
  FocusAttachment _focusAttachment;

  @override
  void initState() {
    super.initState();
    _initNode();
  }

  void _initNode() {
    if (widget.focusNode == null) {
      // Only create a new node if the widget doesn't have one.
      _internalNode ??= _createNode();
    }
    _focusAttachment = node.attach(context, onKey: widget.onKey);
    _hasFocus = node.hasFocus;
    // Add listener even if the _internalNode existed before, since it should
    // not be listening now if we're re-using a previous one, because it should
    // have already removed its listener.
    node.addListener(_handleFocusChanged);
  }

  FocusNode _createNode() {
    return FocusNode(
      debugLabel: widget.debugLabel,
    );
  }

  @override
  void dispose() {
    // Regardless of the node owner, we need to remove it from the tree and stop
    // listening to it.
    node.removeListener(_handleFocusChanged);
    _focusAttachment.detach();
    // Don't manage the lifetime of external nodes given to the widget, just the
    // internal node.
    _internalNode?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _focusAttachment?.reparent();
    if (!_didAutofocus && widget.autofocus) {
      FocusScope.of(context).autofocus(node);
      _didAutofocus = true;
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    _didAutofocus = false;
  }

  @override
  void didUpdateWidget(Focus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.debugLabel != widget.debugLabel && _internalNode != null) {
      _internalNode.debugLabel = widget.debugLabel;
    }
    if ((oldWidget.focusNode == widget.focusNode && oldWidget.onKey == widget.onKey)
        || oldWidget.focusNode == null && widget.focusNode == null) {
      // Either there aren't changes, or the _internalNode is already attached
      // and being listened to.
      return;
    }
    _focusAttachment.detach();
    if (oldWidget.focusNode == null && widget.focusNode != null) {
      // We're no longer using the node we were managing. We don't stop managing
      // it until dispose, so just detach it: we might re-use it eventually, and
      // calling dispose on it here will confuse other widgets that haven't yet
      // been notified of a widget change and might still be listening.
      _internalNode?.removeListener(_handleFocusChanged);
      _focusAttachment = widget.focusNode?.attach(context, onKey: widget.onKey);
      widget.focusNode?.addListener(_handleFocusChanged);
    } else if (oldWidget.focusNode != null && widget.focusNode == null) {
      oldWidget.focusNode?.removeListener(_handleFocusChanged);
      // We stopped using the external node, and now we need to manage one.
      _initNode();
    } else {
      // We just switched which node the widget had, so just change what we
      // listen to/attach.
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
      _focusAttachment = widget.focusNode.attach(context, onKey: widget.onKey);
    }
    _hasFocus = node.hasFocus;
  }

  void _handleFocusChanged() {
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
  Widget build(BuildContext context) {
    _focusAttachment.reparent();
    return _FocusMarker(
      node: node,
      child: widget.child,
    );
  }
}

/// A [FocusScope] is similar to a [Focus], but also serves as a scope for other
/// [Focus]s and [FocusScope]s, grouping them together.
///
/// Like [Focus], [FocusScope] provides an [onFocusChange] as a way to be
/// notified when the focus is given to or removed from this widget.
///
/// The [onKey] argument allows specification of a key event handler that is
/// invoked when this node or one of its children has focus. Keys are handed to
/// the primary focused widget first, and then they propagate through the
/// ancestors of that node, stopping if one of them returns true from [onKey],
/// indicating that it has handled the event.
///
/// A [FocusScope] manages a [FocusScopeNode]. Managing a [FocusScopeNode] means
/// managing its lifecycle, listening for changes in focus, and re-parenting it
/// when the widget hierarchy changes. See [FocusNode] and [FocusScopeNode] for
/// more information about the details of what node management entails if not
/// using a [FocusScope] widget.
///
/// See also:
///
///   * [FocusScopeNode], which represents a scope node in the focus hierarchy.
///   * [FocusNode], which represents a node in the focus hierarchy and has an
///     explanation of the focus system.
///   * [Focus], a widget that manages a [FocusNode] and allows easy access to
///     managing focus without having to manage the node.
///   * [FocusManager], a singleton that manages the focus and distributes key
///     events to focused nodes.
class FocusScope extends Focus {
  /// Creates a widget that manages a [FocusScopeNode].
  ///
  /// The [child] argument is required and must not be null.
  ///
  /// The [autofocus], and [showDecorations] arguments must not be null.
  const FocusScope({
    Key key,
    FocusNode node,
    @required Widget child,
    bool autofocus = false,
    ValueChanged<bool> onFocusChange,
    FocusOnKeyCallback onKey,
    String debugLabel,
  })  : assert(child != null),
        assert(autofocus != null),
        super(
          key: key,
          child: child,
          focusNode: node,
          autofocus: autofocus,
          onFocusChange: onFocusChange,
          onKey: onKey,
          debugLabel: debugLabel,
        );

  /// Returns the [FocusScopeNode] of the [FocusScope] that most tightly
  /// encloses the given [context].
  ///
  /// If this node doesn't have a [Focus] widget ancestor, then the
  /// [FocusManager.rootScope] is returned.
  ///
  /// The [context] argument must not be null.
  static FocusScopeNode of(BuildContext context) {
    assert(context != null);
    final _FocusMarker marker = context.inheritFromWidgetOfExactType(_FocusMarker);
    return marker?.notifier?.nearestScope ?? context.owner.focusManager.rootScope;
  }

  @override
  _FocusScopeState createState() => _FocusScopeState();
}

class _FocusScopeState extends _FocusState {
  @override
  FocusScopeNode _createNode() {
    return FocusScopeNode(
      debugLabel: widget.debugLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    _focusAttachment.reparent();
    return Semantics(
      explicitChildNodes: true,
      child: _FocusMarker(
        node: node,
        child: widget.child,
      ),
    );
  }
}

// The InheritedWidget marker for Focus and FocusScope.
class _FocusMarker extends InheritedNotifier<FocusNode> {
  const _FocusMarker({
    Key key,
    @required FocusNode node,
    @required Widget child,
  })  : assert(node != null),
        assert(child != null),
        super(key: key, notifier: node, child: child);
}
