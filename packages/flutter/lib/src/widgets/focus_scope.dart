// Copyright 2014 The Flutter Authors. All rights reserved.
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
/// When the focus is gained or lost, [onFocusChange] is called.
///
/// For keyboard events, [onKey] is called if [FocusNode.hasFocus] is true for
/// this widget's [focusNode], unless a focused descendant's [onKey] callback
/// returns true when called.
///
/// This widget does not provide any visual indication that the focus has
/// changed. Any desired visual changes should be made when [onFocusChange] is
/// called.
///
/// To access the [FocusNode] of the nearest ancestor [Focus] widget and
/// establish a relationship that will rebuild the widget when the focus
/// changes, use the [Focus.of] and [FocusScope.of] static methods.
///
/// To access the focused state of the nearest [Focus] widget, use
/// [FocusNode.hasFocus] from a build method, which also establishes a relationship
/// between the calling widget and the [Focus] widget that will rebuild the
/// calling widget when the focus changes.
///
/// Managing a [FocusNode] means managing its lifecycle, listening for changes
/// in focus, and re-parenting it when needed to keep the focus hierarchy in
/// sync with the widget hierarchy. This widget does all of those things for
/// you. See [FocusNode] for more information about the details of what node
/// management entails if you are not using a [Focus] widget and you need to do
/// it yourself.
///
/// To collect a sub-tree of nodes into an exclusive group that restricts focus
/// traversal to the group, use a [FocusScope]. To collect a sub-tree of nodes
/// into a group that has a specific order to its traversal but allows the
/// traversal to escape the group, use a [FocusTraversalGroup].
///
/// To move the focus, use methods on [FocusNode] by getting the [FocusNode]
/// through the [of] method. For instance, to move the focus to the next node in
/// the focus traversal order, call `Focus.of(context).nextFocus()`. To unfocus
/// a widget, call `Focus.of(context).unfocus()`.
///
/// {@tool dartpad --template=stateful_widget_scaffold}
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
/// KeyEventResult _handleKeyPress(FocusNode node, RawKeyEvent event) {
///   if (event is RawKeyDownEvent) {
///     print('Focus node ${node.debugLabel} got key event: ${event.logicalKey}');
///     if (event.logicalKey == LogicalKeyboardKey.keyR) {
///       print('Changing color to red.');
///       setState(() {
///         _color = Colors.red;
///       });
///       return KeyEventResult.handled;
///     } else if (event.logicalKey == LogicalKeyboardKey.keyG) {
///       print('Changing color to green.');
///       setState(() {
///         _color = Colors.green;
///       });
///       return KeyEventResult.handled;
///     } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
///       print('Changing color to blue.');
///       setState(() {
///         _color = Colors.blue;
///       });
///       return KeyEventResult.handled;
///     }
///   }
///   return KeyEventResult.ignored;
/// }
///
/// @override
/// Widget build(BuildContext context) {
///   final TextTheme textTheme = Theme.of(context).textTheme;
///   return FocusScope(
///     debugLabel: 'Scope',
///     autofocus: true,
///     child: DefaultTextStyle(
///       style: textTheme.headline4!,
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
///                   focusNode.unfocus();
///                 } else {
///                   focusNode.requestFocus();
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
/// {@tool dartpad --template=stateless_widget_material}
/// This example shows how to wrap another widget in a [Focus] widget to make it
/// focusable. It wraps a [Container], and changes the container's color when it
/// is set as the [FocusManager.primaryFocus].
///
/// If you also want to handle mouse hover and/or keyboard actions on a widget,
/// consider using a [FocusableActionDetector], which combines several different
/// widgets to provide those capabilities.
///
/// ```dart preamble
/// class FocusableText extends StatelessWidget {
///   const FocusableText(this.data, {
///     Key? key,
///     required this.autofocus,
///   }) : super(key: key);
///
///   /// The string to display as the text for this widget.
///   final String data;
///
///   /// Whether or not to focus this widget initially if nothing else is focused.
///   final bool autofocus;
///
///   @override
///   Widget build(BuildContext context) {
///     return Focus(
///       autofocus: autofocus,
///       child: Builder(builder: (BuildContext context) {
///         // The contents of this Builder are being made focusable. It is inside
///         // of a Builder because the builder provides the correct context
///         // variable for Focus.of() to be able to find the Focus widget that is
///         // the Builder's parent. Without the builder, the context variable used
///         // would be the one given the FocusableText build function, and that
///         // would start looking for a Focus widget ancestor of the FocusableText
///         // instead of finding the one inside of its build function.
///         return Container(
///           padding: EdgeInsets.all(8.0),
///           // Change the color based on whether or not this Container has focus.
///           color: Focus.of(context).hasPrimaryFocus ? Colors.black12 : null,
///           child: Text(data),
///         );
///       }),
///     );
///   }
/// }
/// ```
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: ListView.builder(
///       itemBuilder: (context, index) => FocusableText(
///         'Item $index',
///         autofocus: index == 0,
///       ),
///       itemCount: 50,
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@tool dartpad --template=stateful_widget_material}
/// This example shows how to focus a newly-created widget immediately after it
/// is created.
///
/// The focus node will not actually be given the focus until after the frame in
/// which it has requested focus is drawn, so it is OK to call
/// [FocusNode.requestFocus] on a node which is not yet in the focus tree.
///
/// ```dart
/// int focusedChild = 0;
/// List<Widget> children = <Widget>[];
/// List<FocusNode> childFocusNodes = <FocusNode>[];
///
/// @override
/// void initState() {
///   super.initState();
///   // Add the first child.
///   _addChild();
/// }
///
/// @override
/// void dispose() {
///   super.dispose();
///   childFocusNodes.forEach((FocusNode node) => node.dispose());
/// }
///
/// void _addChild() {
///   // Calling requestFocus here creates a deferred request for focus, since the
///   // node is not yet part of the focus tree.
///   childFocusNodes
///       .add(FocusNode(debugLabel: 'Child ${children.length}')..requestFocus());
///
///   children.add(Padding(
///     padding: const EdgeInsets.all(2.0),
///     child: ActionChip(
///       focusNode: childFocusNodes.last,
///       label: Text('CHILD ${children.length}'),
///       onPressed: () {},
///     ),
///   ));
/// }
///
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Center(
///       child: Wrap(
///         children: children,
///       ),
///     ),
///     floatingActionButton: FloatingActionButton(
///       onPressed: () {
///         setState(() {
///           focusedChild = children.length;
///           _addChild();
///         });
///       },
///       child: Icon(Icons.add),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [FocusNode], which represents a node in the focus hierarchy and
///    [FocusNode]'s API documentation includes a detailed explanation of its role
///    in the overall focus system.
///  * [FocusScope], a widget that manages a group of focusable widgets using a
///    [FocusScopeNode].
///  * [FocusScopeNode], a node that collects focus nodes into a group for
///    traversal.
///  * [FocusManager], a singleton that manages the primary focus and
///    distributes key events to focused nodes.
///  * [FocusTraversalPolicy], an object used to determine how to move the focus
///    to other nodes.
///  * [FocusTraversalGroup], a widget that groups together and imposes a
///    traversal policy on the [Focus] nodes below it in the widget hierarchy.
class Focus extends StatefulWidget {
  /// Creates a widget that manages a [FocusNode].
  ///
  /// The [child] argument is required and must not be null.
  ///
  /// The [autofocus] argument must not be null.
  const Focus({
    Key? key,
    required this.child,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.onKey,
    this.debugLabel,
    this.canRequestFocus,
    this.descendantsAreFocusable = true,
    this.skipTraversal,
    this.includeSemantics = true,
  })  : assert(child != null),
        assert(autofocus != null),
        assert(descendantsAreFocusable != null),
        assert(includeSemantics != null),
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
  final String? debugLabel;

  /// The child widget of this [Focus].
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
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
  final FocusOnKeyCallback? onKey;

  /// Handler called when the focus changes.
  ///
  /// Called with true if this widget's node gains focus, and false if it loses
  /// focus.
  final ValueChanged<bool>? onFocusChange;

  /// {@template flutter.widgets.Focus.autofocus}
  /// True if this widget will be selected as the initial focus when no other
  /// node in its scope is currently focused.
  ///
  /// Ideally, there is only one widget with autofocus set in each [FocusScope].
  /// If there is more than one widget with autofocus set, then the first one
  /// added to the tree will get focus.
  ///
  /// Must not be null. Defaults to false.
  /// {@endtemplate}
  final bool autofocus;

  /// {@template flutter.widgets.Focus.focusNode}
  /// An optional focus node to use as the focus node for this widget.
  ///
  /// If one is not supplied, then one will be automatically allocated, owned,
  /// and managed by this widget. The widget will be focusable even if a
  /// [focusNode] is not supplied. If supplied, the given `focusNode` will be
  /// _hosted_ by this widget, but not owned. See [FocusNode] for more
  /// information on what being hosted and/or owned implies.
  ///
  /// Supplying a focus node is sometimes useful if an ancestor to this widget
  /// wants to control when this widget has the focus. The owner will be
  /// responsible for calling [FocusNode.dispose] on the focus node when it is
  /// done with it, but this widget will attach/detach and reparent the node
  /// when needed.
  /// {@endtemplate}
  final FocusNode? focusNode;

  /// Sets the [FocusNode.skipTraversal] flag on the focus node so that it won't
  /// be visited by the [FocusTraversalPolicy].
  ///
  /// This is sometimes useful if a [Focus] widget should receive key events as
  /// part of the focus chain, but shouldn't be accessible via focus traversal.
  ///
  /// This is different from [FocusNode.canRequestFocus] because it only implies
  /// that the widget can't be reached via traversal, not that it can't be
  /// focused. It may still be focused explicitly.
  final bool? skipTraversal;

  /// {@template flutter.widgets.Focus.includeSemantics}
  /// Include semantics information in this widget.
  ///
  /// If true, this widget will include a [Semantics] node that indicates the
  /// [SemanticsProperties.focusable] and [SemanticsProperties.focused]
  /// properties.
  ///
  /// It is not typical to set this to false, as that can affect the semantics
  /// information available to accessibility systems.
  ///
  /// Must not be null, defaults to true.
  /// {@endtemplate}
  final bool includeSemantics;

  /// {@template flutter.widgets.Focus.canRequestFocus}
  /// If true, this widget may request the primary focus.
  ///
  /// Defaults to true.  Set to false if you want the [FocusNode] this widget
  /// manages to do nothing when [FocusNode.requestFocus] is called on it. Does
  /// not affect the children of this node, and [FocusNode.hasFocus] can still
  /// return true if this node is the ancestor of the primary focus.
  ///
  /// This is different than [Focus.skipTraversal] because [Focus.skipTraversal]
  /// still allows the widget to be focused, just not traversed to.
  ///
  /// Setting [FocusNode.canRequestFocus] to false implies that the widget will
  /// also be skipped for traversal purposes.
  ///
  /// See also:
  ///
  /// * [FocusTraversalGroup], a widget that sets the traversal policy for its
  ///   descendants.
  /// * [FocusTraversalPolicy], a class that can be extended to describe a
  ///   traversal policy.
  /// {@endtemplate}
  final bool? canRequestFocus;

  /// {@template flutter.widgets.Focus.descendantsAreFocusable}
  /// If false, will make this widget's descendants unfocusable.
  ///
  /// Defaults to true. Does not affect focusability of this node (just its
  /// descendants): for that, use [FocusNode.canRequestFocus].
  ///
  /// If any descendants are focused when this is set to false, they will be
  /// unfocused. When `descendantsAreFocusable` is set to true again, they will
  /// not be refocused, although they will be able to accept focus again.
  ///
  /// Does not affect the value of [FocusNode.canRequestFocus] on the
  /// descendants.
  ///
  /// See also:
  ///
  /// * [ExcludeFocus], a widget that uses this property to conditionally
  ///   exclude focus for a subtree.
  /// * [FocusTraversalGroup], a widget used to group together and configure the
  ///   focus traversal policy for a widget subtree that has a
  ///   `descendantsAreFocusable` parameter to conditionally block focus for a
  ///   subtree.
  /// {@endtemplate}
  final bool descendantsAreFocusable;

  /// Returns the [focusNode] of the [Focus] that most tightly encloses the
  /// given [BuildContext].
  ///
  /// If no [Focus] node is found before reaching the nearest [FocusScope]
  /// widget, or there is no [Focus] widget in scope, then this method will
  /// throw an exception.
  ///
  /// The `context` and `scopeOk` arguments must not be null.
  ///
  /// Calling this function creates a dependency that will rebuild the given
  /// context when the focus changes.
  ///
  /// See also:
  ///
  ///  * [maybeOf], which is similar to this function, but will return null
  ///    instead of throwing if it doesn't find a [Focus] node.
  static FocusNode of(BuildContext context, { bool scopeOk = false }) {
    assert(context != null);
    assert(scopeOk != null);
    final _FocusMarker? marker = context.dependOnInheritedWidgetOfExactType<_FocusMarker>();
    final FocusNode? node = marker?.notifier;
    assert(() {
      if (node == null) {
        throw FlutterError(
          'Focus.of() was called with a context that does not contain a Focus widget.\n'
          'No Focus widget ancestor could be found starting from the context that was passed to '
          'Focus.of(). This can happen because you are using a widget that looks for a Focus '
          'ancestor, and do not have a Focus widget descendant in the nearest FocusScope.\n'
          'The context used was:\n'
          '  $context'
        );
      }
      return true;
    }());
    assert(() {
      if (!scopeOk && node is FocusScopeNode) {
        throw FlutterError(
          'Focus.of() was called with a context that does not contain a Focus between the given '
          'context and the nearest FocusScope widget.\n'
          'No Focus ancestor could be found starting from the context that was passed to '
          'Focus.of() to the point where it found the nearest FocusScope widget. This can happen '
          'because you are using a widget that looks for a Focus ancestor, and do not have a '
          'Focus widget ancestor in the current FocusScope.\n'
          'The context used was:\n'
          '  $context'
        );
      }
      return true;
    }());
    return node!;
  }

  /// Returns the [focusNode] of the [Focus] that most tightly encloses the
  /// given [BuildContext].
  ///
  /// If no [Focus] node is found before reaching the nearest [FocusScope]
  /// widget, or there is no [Focus] widget in scope, then this method will
  /// return null.
  ///
  /// The `context` and `scopeOk` arguments must not be null.
  ///
  /// Calling this function creates a dependency that will rebuild the given
  /// context when the focus changes.
  ///
  /// See also:
  ///
  ///  * [of], which is similar to this function, but will throw an exception if
  ///    it doesn't find a [Focus] node instead of returning null.
  static FocusNode? maybeOf(BuildContext context, { bool scopeOk = false }) {
    assert(context != null);
    assert(scopeOk != null);
    final _FocusMarker? marker = context.dependOnInheritedWidgetOfExactType<_FocusMarker>();
    final FocusNode? node = marker?.notifier;
    if (node == null) {
      return null;
    }
    if (!scopeOk && node is FocusScopeNode) {
      return null;
    }
    return node;
  }

  /// Returns true if the nearest enclosing [Focus] widget's node is focused.
  ///
  /// A convenience method to allow build methods to write:
  /// `Focus.isAt(context)` to get whether or not the nearest [Focus] above them
  /// in the widget hierarchy currently has the input focus.
  ///
  /// Returns false if no [Focus] widget is found before reaching the nearest
  /// [FocusScope], or if the root of the focus tree is reached without finding
  /// a [Focus] widget.
  ///
  /// Calling this function creates a dependency that will rebuild the given
  /// context when the focus changes.
  static bool isAt(BuildContext context) => Focus.maybeOf(context)?.hasFocus ?? false;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
    properties.add(FlagProperty('autofocus', value: autofocus, ifTrue: 'AUTOFOCUS', defaultValue: false));
    properties.add(FlagProperty('canRequestFocus', value: canRequestFocus, ifFalse: 'NOT FOCUSABLE', defaultValue: false));
    properties.add(FlagProperty('descendantsAreFocusable', value: descendantsAreFocusable, ifFalse: 'DESCENDANTS UNFOCUSABLE', defaultValue: true));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode, defaultValue: null));
  }

  @override
  _FocusState createState() => _FocusState();
}

class _FocusState extends State<Focus> {
  FocusNode? _internalNode;
  FocusNode get focusNode => widget.focusNode ?? _internalNode!;
  bool? _hasPrimaryFocus;
  bool? _canRequestFocus;
  bool? _descendantsAreFocusable;
  bool _didAutofocus = false;
  FocusAttachment? _focusAttachment;

  @override
  void initState() {
    super.initState();
    _initNode();
  }

  void _initNode() {
    if (widget.focusNode == null) {
      // Only create a new node if the widget doesn't have one.
      // This calls a function instead of just allocating in place because
      // _createNode is overridden in _FocusScopeState.
      _internalNode ??= _createNode();
    }
    focusNode.descendantsAreFocusable = widget.descendantsAreFocusable;
    if (widget.skipTraversal != null) {
      focusNode.skipTraversal = widget.skipTraversal!;
    }
    if (widget.canRequestFocus != null) {
      focusNode.canRequestFocus = widget.canRequestFocus!;
    }
    _canRequestFocus = focusNode.canRequestFocus;
    _descendantsAreFocusable = focusNode.descendantsAreFocusable;
    _hasPrimaryFocus = focusNode.hasPrimaryFocus;
    _focusAttachment = focusNode.attach(context, onKey: widget.onKey);

    // Add listener even if the _internalNode existed before, since it should
    // not be listening now if we're re-using a previous one because it should
    // have already removed its listener.
    focusNode.addListener(_handleFocusChanged);
  }

  FocusNode _createNode() {
    return FocusNode(
      debugLabel: widget.debugLabel,
      canRequestFocus: widget.canRequestFocus ?? true,
      descendantsAreFocusable: widget.descendantsAreFocusable,
      skipTraversal: widget.skipTraversal ?? false,
    );
  }

  @override
  void dispose() {
    // Regardless of the node owner, we need to remove it from the tree and stop
    // listening to it.
    focusNode.removeListener(_handleFocusChanged);
    _focusAttachment!.detach();

    // Don't manage the lifetime of external nodes given to the widget, just the
    // internal node.
    _internalNode?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _focusAttachment?.reparent();
    _handleAutofocus();
  }

  void _handleAutofocus() {
    if (!_didAutofocus && widget.autofocus) {
      FocusScope.of(context).autofocus(focusNode);
      _didAutofocus = true;
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    // The focus node's location in the tree is no longer valid here. But
    // we can't unfocus or remove the node from the tree because if the widget
    // is moved to a different part of the tree (via global key) it should
    // retain its focus state. That's why we temporarily park it on the root
    // focus node (via reparent) until it either gets moved to a different part
    // of the tree (via didChangeDependencies) or until it is disposed.
    _focusAttachment?.reparent();
    _didAutofocus = false;
  }

  @override
  void didUpdateWidget(Focus oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(() {
      // Only update the debug label in debug builds, and only if we own the
      // node.
      if (oldWidget.debugLabel != widget.debugLabel && _internalNode != null) {
        _internalNode!.debugLabel = widget.debugLabel;
      }
      return true;
    }());

    if (oldWidget.focusNode == widget.focusNode) {
      if (widget.onKey != focusNode.onKey) {
        focusNode.onKey = widget.onKey;
      }
      if (widget.skipTraversal != null) {
        focusNode.skipTraversal = widget.skipTraversal!;
      }
      if (widget.canRequestFocus != null) {
        focusNode.canRequestFocus = widget.canRequestFocus!;
      }
      focusNode.descendantsAreFocusable = widget.descendantsAreFocusable;
    } else {
      _focusAttachment!.detach();
      focusNode.removeListener(_handleFocusChanged);
      _initNode();
    }

    if (oldWidget.autofocus != widget.autofocus) {
      _handleAutofocus();
    }
  }

  void _handleFocusChanged() {
    final bool hasPrimaryFocus = focusNode.hasPrimaryFocus;
    final bool canRequestFocus = focusNode.canRequestFocus;
    final bool descendantsAreFocusable = focusNode.descendantsAreFocusable;
    if (widget.onFocusChange != null) {
      widget.onFocusChange!(focusNode.hasFocus);
    }
    if (_hasPrimaryFocus != hasPrimaryFocus) {
      setState(() {
        _hasPrimaryFocus = hasPrimaryFocus;
      });
    }
    if (_canRequestFocus != canRequestFocus) {
      setState(() {
        _canRequestFocus = canRequestFocus;
      });
    }
    if (_descendantsAreFocusable != descendantsAreFocusable) {
      setState(() {
        _descendantsAreFocusable = descendantsAreFocusable;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _focusAttachment!.reparent();
    Widget child = widget.child;
    if (widget.includeSemantics) {
      child = Semantics(
        focusable: _canRequestFocus,
        focused: _hasPrimaryFocus,
        child: widget.child,
      );
    }
    return _FocusMarker(
      node: focusNode,
      child: child,
    );
  }
}

/// A [FocusScope] is similar to a [Focus], but also serves as a scope for its
/// descendants, restricting focus traversal to the scoped controls.
///
/// For example a new [FocusScope] is created automatically when a route is
/// pushed, keeping the focus traversal from moving to a control in a previous
/// route.
///
/// If you just want to group widgets together in a group so that they are
/// traversed in a particular order, but the focus can still leave the group,
/// use a [FocusTraversalGroup].
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
/// Managing a [FocusScopeNode] means managing its lifecycle, listening for
/// changes in focus, and re-parenting it when needed to keep the focus
/// hierarchy in sync with the widget hierarchy. This widget does all of those
/// things for you. See [FocusScopeNode] for more information about the details
/// of what node management entails if you are not using a [FocusScope] widget
/// and you need to do it yourself.
///
/// [FocusScopeNode]s remember the last [FocusNode] that was focused within
/// their descendants, and can move that focus to the next/previous node, or a
/// node in a particular direction when the [FocusNode.nextFocus],
/// [FocusNode.previousFocus], or [FocusNode.focusInDirection] are called on a
/// [FocusNode] or [FocusScopeNode].
///
/// To move the focus, use methods on [FocusNode] by getting the [FocusNode]
/// through the [of] method. For instance, to move the focus to the next node in
/// the focus traversal order, call `Focus.of(context).nextFocus()`. To unfocus
/// a widget, call `Focus.of(context).unfocus()`.
///
/// {@tool dartpad --template=stateful_widget_material}
/// This example demonstrates using a [FocusScope] to restrict focus to a particular
/// portion of the app. In this case, restricting focus to the visible part of a
/// Stack.
///
/// ```dart preamble
/// /// A demonstration pane.
/// ///
/// /// This is just a separate widget to simplify the example.
/// class Pane extends StatelessWidget {
///   const Pane({
///     Key? key,
///     required this.focusNode,
///     this.onPressed,
///     required this.backgroundColor,
///     required this.icon,
///     this.child,
///   }) : super(key: key);
///
///   final FocusNode focusNode;
///   final VoidCallback? onPressed;
///   final Color backgroundColor;
///   final Widget icon;
///   final Widget? child;
///
///   @override
///   Widget build(BuildContext context) {
///     return Material(
///       color: backgroundColor,
///       child: Stack(
///         fit: StackFit.expand,
///         children: <Widget>[
///           Center(
///             child: child,
///           ),
///           Align(
///             alignment: Alignment.topLeft,
///             child: IconButton(
///               autofocus: true,
///               focusNode: focusNode,
///               onPressed: onPressed,
///               icon: icon,
///             ),
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
///
/// ```dart
///   bool backdropIsVisible = false;
///   FocusNode backdropNode = FocusNode(debugLabel: 'Close Backdrop Button');
///   FocusNode foregroundNode = FocusNode(debugLabel: 'Option Button');
///
///   @override
///   void dispose() {
///     super.dispose();
///     backdropNode.dispose();
///     foregroundNode.dispose();
///   }
///
///   Widget _buildStack(BuildContext context, BoxConstraints constraints) {
///     Size stackSize = constraints.biggest;
///     return Stack(
///       fit: StackFit.expand,
///       // The backdrop is behind the front widget in the Stack, but the widgets
///       // would still be active and traversable without the FocusScope.
///       children: <Widget>[
///         // TRY THIS: Try removing this FocusScope entirely to see how it affects
///         // the behavior. Without this FocusScope, the "ANOTHER BUTTON TO FOCUS"
///         // button, and the IconButton in the backdrop Pane would be focusable
///         // even when the backdrop wasn't visible.
///         FocusScope(
///           // TRY THIS: Try commenting out this line. Notice that the focus
///           // starts on the backdrop and is stuck there? It seems like the app is
///           // non-responsive, but it actually isn't. This line makes sure that
///           // this focus scope and its children can't be focused when they're not
///           // visible. It might help to make the background color of the
///           // foreground pane semi-transparent to see it clearly.
///           canRequestFocus: backdropIsVisible,
///           child: Pane(
///             icon: Icon(Icons.close),
///             focusNode: backdropNode,
///             backgroundColor: Colors.lightBlue,
///             onPressed: () => setState(() => backdropIsVisible = false),
///             child: Column(
///               mainAxisAlignment: MainAxisAlignment.center,
///               children: <Widget>[
///                 // This button would be not visible, but still focusable from
///                 // the foreground pane without the FocusScope.
///                 ElevatedButton(
///                   onPressed: () => print('You pressed the other button!'),
///                   child: Text('ANOTHER BUTTON TO FOCUS'),
///                 ),
///                 DefaultTextStyle(
///                     style: Theme.of(context).textTheme.headline2!,
///                     child: Text('BACKDROP')),
///               ],
///             ),
///           ),
///         ),
///         AnimatedPositioned(
///           curve: Curves.easeInOut,
///           duration: const Duration(milliseconds: 300),
///           top: backdropIsVisible ? stackSize.height * 0.9 : 0.0,
///           width: stackSize.width,
///           height: stackSize.height,
///           onEnd: () {
///             if (backdropIsVisible) {
///               backdropNode.requestFocus();
///             } else {
///               foregroundNode.requestFocus();
///             }
///           },
///           child: Pane(
///             icon: Icon(Icons.menu),
///             focusNode: foregroundNode,
///             // TRY THIS: Try changing this to Colors.green.withOpacity(0.8) to see for
///             // yourself that the hidden components do/don't get focus.
///             backgroundColor: Colors.green,
///             onPressed: backdropIsVisible
///                 ? null
///                 : () => setState(() => backdropIsVisible = true),
///             child: DefaultTextStyle(
///                 style: Theme.of(context).textTheme.headline2!,
///                 child: Text('FOREGROUND')),
///           ),
///         ),
///       ],
///     );
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     // Use a LayoutBuilder so that we can base the size of the stack on the size
///     // of its parent.
///     return LayoutBuilder(builder: _buildStack);
///   }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [FocusScopeNode], which represents a scope node in the focus hierarchy.
///  * [FocusNode], which represents a node in the focus hierarchy and has an
///    explanation of the focus system.
///  * [Focus], a widget that manages a [FocusNode] and allows easy access to
///    managing focus without having to manage the node.
///  * [FocusManager], a singleton that manages the focus and distributes key
///    events to focused nodes.
///  * [FocusTraversalPolicy], an object used to determine how to move the focus
///    to other nodes.
///  * [FocusTraversalGroup], a widget used to configure the focus traversal
///    policy for a widget subtree.
class FocusScope extends Focus {
  /// Creates a widget that manages a [FocusScopeNode].
  ///
  /// The [child] argument is required and must not be null.
  ///
  /// The [autofocus] argument must not be null.
  const FocusScope({
    Key? key,
    FocusScopeNode? node,
    required Widget child,
    bool autofocus = false,
    ValueChanged<bool>? onFocusChange,
    bool? canRequestFocus,
    bool? skipTraversal,
    FocusOnKeyCallback? onKey,
    String? debugLabel,
  })  : assert(child != null),
        assert(autofocus != null),
        super(
          key: key,
          child: child,
          focusNode: node,
          autofocus: autofocus,
          onFocusChange: onFocusChange,
          canRequestFocus: canRequestFocus,
          skipTraversal: skipTraversal,
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
    final _FocusMarker? marker = context.dependOnInheritedWidgetOfExactType<_FocusMarker>();
    return marker?.notifier?.nearestScope ?? context.owner!.focusManager.rootScope;
  }

  @override
  _FocusScopeState createState() => _FocusScopeState();
}

class _FocusScopeState extends _FocusState {
  @override
  FocusScopeNode _createNode() {
    return FocusScopeNode(
      debugLabel: widget.debugLabel,
      canRequestFocus: widget.canRequestFocus ?? true,
      skipTraversal: widget.skipTraversal ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    _focusAttachment!.reparent();
    return Semantics(
      explicitChildNodes: true,
      child: _FocusMarker(
        node: focusNode,
        child: widget.child,
      ),
    );
  }
}

// The InheritedWidget marker for Focus and FocusScope.
class _FocusMarker extends InheritedNotifier<FocusNode> {
  const _FocusMarker({
    Key? key,
    required FocusNode node,
    required Widget child,
  })  : assert(node != null),
        assert(child != null),
        super(key: key, notifier: node, child: child);
}

/// A widget that controls whether or not the descendants of this widget are
/// focusable.
///
/// Does not affect the value of [Focus.canRequestFocus] on the descendants.
///
/// See also:
///
///  * [Focus], a widget for adding and managing a [FocusNode] in the widget tree.
///  * [FocusTraversalGroup], a widget that groups widgets for focus traversal,
///    and can also be used in the same way as this widget by setting its
///    `descendantsAreFocusable` attribute.
class ExcludeFocus extends StatelessWidget {
  /// Const constructor for [ExcludeFocus] widget.
  ///
  /// The [excluding] argument must not be null.
  ///
  /// The [child] argument is required, and must not be null.
  const ExcludeFocus({
    Key? key,
    this.excluding = true,
    required this.child,
  })  : assert(excluding != null),
        assert(child != null),
        super(key: key);

  /// If true, will make this widget's descendants unfocusable.
  ///
  /// Defaults to true.
  ///
  /// If any descendants are focused when this is set to true, they will be
  /// unfocused. When `excluding` is set to false again, they will not be
  /// refocused, although they will be able to accept focus again.
  ///
  /// Does not affect the value of [FocusNode.canRequestFocus] on the
  /// descendants.
  ///
  /// See also:
  ///
  /// * [Focus.descendantsAreFocusable], the attribute of a [Focus] widget that
  ///   controls this same property for focus widgets.
  /// * [FocusTraversalGroup], a widget used to group together and configure the
  ///   focus traversal policy for a widget subtree that has a
  ///   `descendantsAreFocusable` parameter to conditionally block focus for a
  ///   subtree.
  final bool excluding;

  /// The child widget of this [ExcludeFocus].
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      descendantsAreFocusable: !excluding,
      child: child,
    );
  }
}
