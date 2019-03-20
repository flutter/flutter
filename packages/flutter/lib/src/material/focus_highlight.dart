// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// A widget that shows a highlight decoration around its child when a
/// [Focusable] above it in the widget hierarchy is focused.
///
/// It allows specification of a [focusedDecoration] to be shown when it
/// has focus, and [unfocusedDecoration] when it is not.
///
/// By default, it uses the values derived from [Theme.focusHighlightTheme].
class FocusHighlight extends StatefulWidget {
  /// Creates a widget that manages a [FocusableNode]
  ///
  /// The [child] argument is required and must not be null.
  ///
  /// The [autofocus], and [showDecorations] arguments must not be null.
  const FocusHighlight({
    Key key,
    @required this.child,
    this.focusedDecoration,
    this.unfocusedDecoration,
    this.duration,
    this.curve,
  })  : assert(child != null),
        super(key: key);

  /// The child widget of this [FocusHighlight].
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Defines the decoration to be drawn around the [child] when this widget
  /// receives the focus.
  ///
  /// This defaults to the [FocusHighlightThemeData.focusedDecoration] provided by
  /// the ambient [Theme] in the context.
  final Decoration focusedDecoration;

  /// Defines the decoration to be drawn around the [child] when this widget
  /// does not have the focus.
  ///
  /// This defaults to the [FocusHighlightThemeData.unfocusedDecoration] provided by
  /// the ambient [Theme] in the context.
  final Decoration unfocusedDecoration;

  /// The duration over which to animate the parameters of the focus highlight
  /// [decoration].
  final Duration duration;

  /// The curve to apply when animating the parameters of the focus highlight
  /// [decoration].
  final Curve curve;

  @override
  _FocusHighlightState createState() => _FocusHighlightState();
}

class _FocusHighlightState extends State<FocusHighlight> {
  bool _hasFocus;
  FocusableNode _node;

  @override
  void didUpdateWidget(FocusHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    final FocusableNode newNode = Focusable.of(context);
    if (newNode != _node) {
      _node.removeListener(_handleFocusChanged);
      _node = newNode;
      _node.addListener(_handleFocusChanged);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _node = Focusable.of(context);
    _node.addListener(_handleFocusChanged);
    _hasFocus = _node.hasFocus;
  }

  @override
  void dispose() {
    _node?.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_hasFocus != _node.hasFocus) {
      setState(() {
        _hasFocus = _node.hasFocus;
      });
    }
  }

  Decoration _getDecoration(BuildContext context) {
    if (_hasFocus) {
      return widget.focusedDecoration ?? Theme.of(context).focusHighlightTheme.focusedDecoration;
    } else {
      return widget.unfocusedDecoration ?? Theme.of(context).focusHighlightTheme.unfocusedDecoration;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      padding: EdgeInsets.zero,
      decoration: _getDecoration(context),
      duration: widget.duration ?? Theme.of(context).focusHighlightTheme.focusAnimationDuration,
      curve: widget.curve ?? Theme.of(context).focusHighlightTheme.focusAnimationCurve,
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Decoration>('decoration', widget.focusedDecoration, defaultValue: null));
    properties.add(DiagnosticsProperty<Decoration>('unfocusedDecoration', widget.unfocusedDecoration, defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('duration', widget.duration, defaultValue: null));
    properties.add(DiagnosticsProperty<Curve>('curve', widget.curve, defaultValue: null));
  }
}

/// Defines the appearance of [FocusHighlight]s.
///
/// This class is used to define the value of [ThemeData.focusHighlightTheme]. The
/// [FocusHighlight] widget uses the current focusable theme to initialize
/// [FocusHighlight] properties (like [FocusHighlight.focusedDecoration]) when
/// they are not supplied.
class FocusHighlightThemeData extends Diagnosticable {
  /// Creates a const FocusableThemeData object.
  ///
  /// All of the arguments are optional, and will use fallback values if not
  /// specified.
  const FocusHighlightThemeData({
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

  /// Linearly interpolate between two [FocusHighlightThemeData]s.
  ///
  /// If a theme is null, then the non-null border is returned.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static FocusHighlightThemeData lerp(FocusHighlightThemeData a, FocusHighlightThemeData b, double t) {
    return FocusHighlightThemeData(
      focusedDecoration: Decoration.lerp(a.focusedDecoration, b.focusedDecoration, t),
      unfocusedDecoration: Decoration.lerp(a.unfocusedDecoration, b.unfocusedDecoration, t),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const FocusHighlightThemeData defaultTheme = FocusHighlightThemeData();
    properties.add(DiagnosticsProperty<Decoration>('focusedDecoration', focusedDecoration, defaultValue: defaultTheme.focusedDecoration));
    properties.add(DiagnosticsProperty<Decoration>('unfocusedDecoration', unfocusedDecoration, defaultValue: defaultTheme.unfocusedDecoration));
  }
}
