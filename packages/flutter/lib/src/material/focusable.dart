// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

typedef FocusableOnKeyCallback = bool Function(FocusableNode node, RawKeyEvent event);

/// A widget that manages a [FocusableNode] and allows specification of the
/// focus order.
///
/// The node can be either a scope node or a leaf node. Scope nodes provide a
/// scope for their children, using the focus traversal policy defined by the
/// [DefaultFocusTraversal] widget above them to traverse their children.
///
/// It provides [onFocusChange] as a way to be notified when the focus is given
/// to or removed from this widget, and allows specification of a [focusedDecoration]
/// to be shown when its [child] has focus.
///
/// The [onKey] argument allows specification of a key even handler that should
/// be invoked when this node or one of its children has focus.
class Focusable extends StatefulWidget {
  /// Creates a widget that manages a [FocusableNode]
  ///
  /// The [child] arguments is required and must not be null.
  ///
  /// The [isScope], [autofocus], and [showDecorations] arguments must not be
  /// null.
  const Focusable({
    Key key,
    @required this.child,
    this.isScope = false,
    this.autofocus = false,
    this.showDecorations = true,
    this.focusedDecoration,
    this.unfocusedDecoration,
    this.duration,
    this.curve,
    this.onFocusChange,
    this.onKey,
    this.debugLabel,
  })  : assert(child != null),
        assert(isScope != null),
        assert(autofocus != null),
        assert(showDecorations != null),
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
  /// This is not the way to get text input similar to a text field: it leaves
  /// out support for input method editors, and doesn't support soft keyboards
  /// in general. For text input, consider [TextField] or [CupertinoTextField],
  /// which do support these things.
  final FocusableOnKeyCallback onKey;

  /// Handler called when the focus of this focusable changes.
  ///
  /// Called with true if this focusable gains focus, and false if it loses
  /// focus.
  final ValueChanged<bool> onFocusChange;

  /// True if this [Focusable] serves as a scope for other [Focusable]s.
  ///
  /// This means that it remembers the last focusable that was focused within
  /// its descendants, and can move that focus to the next/previous node, or a
  /// node in a particular direction when the [FocusableNode.nextFocus],
  /// [FocusableNode.previousFocus], or [FocusableNode.focusInDirection] are
  /// called on a Focusable node that is a child of this scope, or the node
  /// owned by this scope node.
  ///
  /// The selection process of the node to move to is determined by the node
  /// traversal policy specified by the nearest enclosing
  /// [DefaultFocusTraversal] widget.
  final bool isScope;

  /// True if this widget will be selected as the initial focus when no other
  /// node in its scope is currently focused.
  ///
  /// There must only be one descendant node in a scope that has `autofocus`
  /// set, unless it is the descendant of another scope.
  final bool autofocus;

  /// True when displaying focus decorations.
  ///
  /// Set to false if you wish to handle the visual focus indicators yourself.
  ///
  /// If you just want a different decoration around the focusable widget, set
  /// [focusedDecoration] and/or [unfocusedDecoration], or modify the
  /// [FocusableThemeData] in the ambient [Theme].
  ///
  /// Defaults to true.
  final bool showDecorations;

  /// Defines the decoration to be drawn around the [child] when this widget
  /// receives the focus.
  ///
  /// This defaults to the [FocusableThemeData.focusedDecoration] provided by
  /// the ambient [Theme] in the context.
  final Decoration focusedDecoration;

  /// Defines the decoration to be drawn around the [child] when this widget
  /// does not have the focus.
  ///
  /// This defaults to the [FocusableThemeData.unfocusedDecoration] provided by
  /// the ambient [Theme] in the context.
  final Decoration unfocusedDecoration;

  /// The duration over which to animate the parameters of the focus highlight
  /// [decoration].
  final Duration duration;

  /// The curve to apply when animating the parameters of the focus highlight
  /// [decoration].
  final Curve curve;

  /// Returns the [node] of the [Focusable] that most tightly encloses the given
  /// [BuildContext].
  ///
  /// The [context] argument must not be null.
  static FocusableNode of(BuildContext context) {
    assert(context != null);
    final _FocusableMarker marker = context.inheritFromWidgetOfExactType(_FocusableMarker);
    return marker?.node ?? context.owner.focusManager.rootFocusable;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('debugName', debugLabel, defaultValue: null));
    properties.add(DiagnosticsProperty<Decoration>('decoration', focusedDecoration));
  }

  @override
  _FocusableState createState() => _FocusableState();
}

class _FocusableState extends State<Focusable> {
  FocusableNode node;
  bool _hasFocus;

  @override
  void initState() {
    super.initState();
    node = FocusableNode(
      isScope: widget.isScope,
      autofocus: widget.autofocus,
      key: GlobalKey(debugLabel: widget.debugLabel),
    );
    _hasFocus = node.hasFocus;
    node.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    node.dispose();
    super.dispose();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final FocusableNode newParent = Focusable.of(context);
    newParent.reparent(node);
  }

  Decoration _getDecoration(BuildContext context) {
    if (!widget.showDecorations) {
      return null;
    }
    if (_hasFocus) {
      return widget.focusedDecoration ?? Theme.of(context).focusableTheme.focusedDecoration;
    } else {
      return widget.unfocusedDecoration ?? Theme.of(context).focusableTheme.unfocusedDecoration;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: node,
      onKey: (RawKeyEvent event) {
        if (widget.onKey != null) {
          widget.onKey(node, event);
        }
      },
      child: AnimatedContainer(
        decoration: _getDecoration(context),
        child: _FocusableMarker(
          key: node.key,
          node: node,
          child: widget.child,
        ),
        duration: widget.duration ?? Theme.of(context).focusableTheme.focusAnimationDuration,
        curve: widget.curve ?? Theme.of(context).focusableTheme.focusAnimationCurve,
      ),
    );
  }
}

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

/// Defines the appearance of [Focusable]s.
///
/// This class is used to define the value of [ThemeData.focusableTheme]. The
/// [Focusable] widget uses the current focusable theme to initialize
/// some null [Focusable] properties (like [Focusable.focusedDecoration]).
class FocusableThemeData extends Diagnosticable {
  /// Creates a const FocusableThemeData object.
  ///
  /// All of the arguments are optional, and will use fallback values if not
  /// specified.
  const FocusableThemeData({
    Decoration focusedDecoration,
    Decoration unfocusedDecoration,
    Curve focusAnimationCurve,
    Duration focusAnimationDuration,
  })  : focusedDecoration = focusedDecoration ?? _defaultFocusedDecoration,
        unfocusedDecoration = unfocusedDecoration ?? _defaultUnfocusedDecoration,
        focusAnimationCurve = focusAnimationCurve ?? Curves.easeInOut,
        focusAnimationDuration = focusAnimationDuration ?? const Duration(milliseconds: 100);

  static const Color _defaultFocusedColor = Color(0xff000080);
  static const Color _defaultUnfocusedColor = Color(0x00000000);
  static const double _defaultBorderWidth = 1.0;
  static const BorderSide _defaultFocusedBorder = BorderSide(color: _defaultFocusedColor, width: _defaultBorderWidth);
  static const BorderSide _defaultUnfocusedBorder = BorderSide(color: _defaultUnfocusedColor, width: _defaultBorderWidth);
  static const BoxDecoration _defaultFocusedDecoration = BoxDecoration(
    border: Border(
      top: _defaultFocusedBorder,
      right: _defaultFocusedBorder,
      bottom: _defaultFocusedBorder,
      left: _defaultFocusedBorder,
    ),
  );
  static const BoxDecoration _defaultUnfocusedDecoration = BoxDecoration(
    border: Border(
      top: _defaultUnfocusedBorder,
      right: _defaultUnfocusedBorder,
      bottom: _defaultUnfocusedBorder,
      left: _defaultUnfocusedBorder,
    ),
  );

  /// Specifies the decoration that should be applied to [Focusable]s when they
  /// have the focus.
  ///
  /// By default, this is a blue box with a border that is one logical pixel wide.
  final Decoration focusedDecoration;

  /// Specifies the decoration that should be applied to [Focusable]s when they
  /// do not have focus.
  ///
  /// By default, this is a box with a fully transparent border that is one
  /// logical pixel wide.
  final Decoration unfocusedDecoration;

  /// Specifies the default duration for the transition between focused and
  /// unfocused (and vice versa) decorations in a Focusable.
  final Duration focusAnimationDuration;

  /// Specifies the default curve to use for the transition between focused and
  /// unfocused (and vice versa) decorations in a focusable.
  final Curve focusAnimationCurve;

  /// Linearly interpolate between two [FocusableThemeData]s.
  ///
  /// If a theme is null, then the non-null border is returned.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static FocusableThemeData lerp(FocusableThemeData a, FocusableThemeData b, double t) {
    return FocusableThemeData(
      focusedDecoration: Decoration.lerp(a.focusedDecoration, b.focusedDecoration, t),
      unfocusedDecoration: Decoration.lerp(a.unfocusedDecoration, b.unfocusedDecoration, t),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const FocusableThemeData defaultTheme = FocusableThemeData();
    properties.add(DiagnosticsProperty<Decoration>('focusedDecoration', focusedDecoration, defaultValue: defaultTheme.focusedDecoration));
    properties.add(DiagnosticsProperty<Decoration>('unfocusedDecoration', unfocusedDecoration, defaultValue: defaultTheme.unfocusedDecoration));
  }
}
