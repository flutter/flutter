// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'button_style.dart';
import 'colors.dart';
import 'constants.dart';
import 'ink_ripple.dart';
import 'ink_well.dart';
import 'material.dart';
import 'material_state.dart';
import 'theme_data.dart';

/// The base [StatefulWidget] class for buttons whose style is defined by a [ButtonStyle] object.
///
/// Concrete subclasses must override [defaultStyleOf] and [themeStyleOf].
///
/// See also:
///
///  * [TextButton], a simple ButtonStyleButton without a shadow.
///  * [ElevatedButton], a filled ButtonStyleButton whose material elevates when pressed.
///  * [OutlinedButton], similar to [TextButton], but with an outline.
abstract class ButtonStyleButton extends StatefulWidget {
  /// Create a [ButtonStyleButton].
  const ButtonStyleButton({
    Key key,
    @required this.onPressed,
    @required this.onLongPress,
    @required this.style,
    @required this.focusNode,
    @required this.autofocus,
    @required this.clipBehavior,
    @required this.child,
  }) : assert(autofocus != null),
       assert(clipBehavior != null),
       super(key: key);

  /// Called when the button is tapped or otherwise activated.
  ///
  /// If this callback and [onLongPress] are null, then the button will be disabled.
  ///
  /// See also:
  ///
  ///  * [enabled], which is true if the button is enabled.
  final VoidCallback onPressed;

  /// Called when the button is long-pressed.
  ///
  /// If this callback and [onPressed] are null, then the button will be disabled.
  ///
  /// See also:
  ///
  ///  * [enabled], which is true if the button is enabled.
  final VoidCallback onLongPress;

  /// Customizes this button's appearance.
  ///
  /// Non-null properties of this style override the corresponding
  /// properties in [themeStyleOf] and [defaultStyleOf]. [MaterialStateProperty]s
  /// that resolve to non-null values will similarly override the corresponding
  /// [MaterialStateProperty]s in [themeStyleOf] and [defaultStyleOf].
  ///
  /// Null by default.
  final ButtonStyle style;

  /// {@macro flutter.widgets.Clip}
  ///
  /// Defaults to [Clip.none], and must not be null.
  final Clip clipBehavior;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// Typically the button's label.
  final Widget child;

  /// Returns a non-null [ButtonStyle] that's based primarily on the [Theme]'s
  /// [ThemeData.textTheme] and [ThemeData.colorScheme].
  ///
  /// The returned style can be overriden by the [style] parameter and
  /// by the style returned by [themeStyleOf]. For example the default
  /// style of the [TextButton] subclass can be overidden with its
  /// [TextButton.style] constructor parameter, or with a
  /// [TextButtonTheme].
  ///
  /// Concrete button subclasses should return a ButtonStyle that
  /// has no null properties, and where all of the [MaterialStateProperty]
  /// properties resolve to non-null values.
  ///
  /// See also:
  ///
  ///  * [themeStyleOf], Returns the ButtonStyle of this button's component theme.
  @protected
  ButtonStyle defaultStyleOf(BuildContext context);

  /// Returns the ButtonStyle that belongs to the button's component theme.
  ///
  /// The returned style can be overriden by the [style] parameter.
  ///
  /// Concrete button subclasses should return the ButtonStyle for the
  /// nearest subclass-specific inherited theme, and if no such theme
  /// exists, then the same value from the overall [Theme].
  ///
  /// See also:
  ///
  ///  * [defaultStyleOf], Returns the default [ButtonStyle] for this button.
  @protected
  ButtonStyle themeStyleOf(BuildContext context);

  /// Whether the button is enabled or disabled.
  ///
  /// Buttons are disabled by default. To enable a button, set its [onPressed]
  /// or [onLongPress] properties to a non-null value.
  bool get enabled => onPressed != null || onLongPress != null;

  @override
  _ButtonStyleState createState() => _ButtonStyleState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
    properties.add(DiagnosticsProperty<ButtonStyle>('style', style, defaultValue: null));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode, defaultValue: null));
  }

  /// Returns null if [value] is null, otherwise `MaterialStateProperty.all<T>(value)`.
  ///
  /// A convenience method for subclasses.
  static MaterialStateProperty<T> allOrNull<T>(T value) => value == null ? null : MaterialStateProperty.all<T>(value);

  /// Returns an interpolated value based on the [textScaleFactor] parameter:
  ///
  ///  * 0 - 1 [geometry1x]
  ///  * 1 - 2 lerp([geometry1x], [geometry2x], [textScaleFactor] - 1)
  ///  * 2 - 3 lerp([geometry2x], [geometry3x], [textScaleFactor] - 2)
  ///  * otherwise [geometry3x]
  ///
  /// A convenience method for subclasses.
  static EdgeInsetsGeometry scaledPadding(
    EdgeInsetsGeometry geometry1x,
    EdgeInsetsGeometry geometry2x,
    EdgeInsetsGeometry geometry3x,
    double textScaleFactor,
  ) {
    assert(geometry1x != null);
    assert(geometry2x != null);
    assert(geometry3x != null);
    assert(textScaleFactor != null);

    if (textScaleFactor <= 1) {
      return geometry1x;
    } else if (textScaleFactor >= 3) {
      return geometry3x;
    } else if (textScaleFactor <= 2) {
      return EdgeInsetsGeometry.lerp(geometry1x, geometry2x, textScaleFactor - 1);
    }
    return EdgeInsetsGeometry.lerp(geometry2x, geometry3x, textScaleFactor - 2);
  }
}

/// The base [State] class for buttons whose style is defined by a [ButtonStyle] object.
///
/// See also:
///
///  * [ButtonStyleButton], the [StatefulWidget] subclass for which this class is the [State].
///  * [TextButton], a simple button without a shadow.
///  * [ElevatedButton], a filled button whose material elevates when pressed.
///  * [OutlinedButton], similar to [TextButton], but with an outline.
class _ButtonStyleState extends State<ButtonStyleButton> {
  final Set<MaterialState> _states = <MaterialState>{};

  bool get _hovered => _states.contains(MaterialState.hovered);
  bool get _focused => _states.contains(MaterialState.focused);
  bool get _pressed => _states.contains(MaterialState.pressed);
  bool get _disabled => _states.contains(MaterialState.disabled);

  void _updateState(MaterialState state, bool value) {
    value ? _states.add(state) : _states.remove(state);
  }

  void _handleHighlightChanged(bool value) {
    if (_pressed != value) {
      setState(() {
        _updateState(MaterialState.pressed, value);
      });
    }
  }

  void _handleHoveredChanged(bool value) {
    if (_hovered != value) {
      setState(() {
        _updateState(MaterialState.hovered, value);
      });
    }
  }

  void _handleFocusedChanged(bool value) {
    if (_focused != value) {
      setState(() {
        _updateState(MaterialState.focused, value);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _updateState(MaterialState.disabled, !widget.enabled);
  }

  @override
  void didUpdateWidget(ButtonStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateState(MaterialState.disabled, !widget.enabled);
    // If the button is disabled while a press gesture is currently ongoing,
    // InkWell makes a call to handleHighlightChanged. This causes an exception
    // because it calls setState in the middle of a build. To preempt this, we
    // manually update pressed to false when this situation occurs.
    if (_disabled && _pressed) {
      _handleHighlightChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle widgetStyle = widget.style;
    final ButtonStyle themeStyle = widget.themeStyleOf(context);
    final ButtonStyle defaultStyle = widget.defaultStyleOf(context);
    assert(defaultStyle != null);

    T effectiveValue<T>(T Function(ButtonStyle style) getProperty) {
      final T widgetValue  = getProperty(widgetStyle);
      final T themeValue   = getProperty(themeStyle);
      final T defaultValue = getProperty(defaultStyle);
      return widgetValue ?? themeValue ?? defaultValue;
    }

    T resolve<T>(MaterialStateProperty<T> Function(ButtonStyle style) getProperty) {
      return effectiveValue(
        (ButtonStyle style) => getProperty(style)?.resolve(_states),
      );
    }

    final TextStyle resolvedTextStyle = resolve<TextStyle>((ButtonStyle style) => style?.textStyle);
    final Color resolvedBackgroundColor = resolve<Color>((ButtonStyle style) => style?.backgroundColor);
    final Color resolvedForegroundColor = resolve<Color>((ButtonStyle style) => style?.foregroundColor);
    final Color resolvedShadowColor = resolve<Color>((ButtonStyle style) => style?.shadowColor);
    final double resolvedElevation = resolve<double>((ButtonStyle style) => style?.elevation);
    final EdgeInsetsGeometry resolvedPadding = resolve<EdgeInsetsGeometry>((ButtonStyle style) => style?.padding);
    final Size resolvedMinimumSize = resolve<Size>((ButtonStyle style) => style?.minimumSize);
    final BorderSide resolvedSide = resolve<BorderSide>((ButtonStyle style) => style?.side);
    final OutlinedBorder resolvedShape = resolve<OutlinedBorder>((ButtonStyle style) => style?.shape);

    final MaterialStateMouseCursor resolvedMouseCursor = _MouseCursor(
      (Set<MaterialState> states) => effectiveValue((ButtonStyle style) => style?.mouseCursor?.resolve(states)),
    );

    final MaterialStateProperty<Color> overlayColor = MaterialStateProperty.resolveWith<Color>(
      (Set<MaterialState> states) => effectiveValue((ButtonStyle style) => style?.overlayColor?.resolve(states)),
    );

    final VisualDensity resolvedVisualDensity = effectiveValue((ButtonStyle style) => style?.visualDensity);
    final MaterialTapTargetSize resolvedTapTargetSize = effectiveValue((ButtonStyle style) => style?.tapTargetSize);
    final Duration resolvedAnimationDuration = effectiveValue((ButtonStyle style) => style?.animationDuration);
    final bool resolvedEnableFeedback = effectiveValue((ButtonStyle style) => style?.enableFeedback);
    final Offset densityAdjustment = resolvedVisualDensity.baseSizeAdjustment;
    final BoxConstraints effectiveConstraints = resolvedVisualDensity.effectiveConstraints(
      BoxConstraints(
        minWidth: resolvedMinimumSize.width,
        minHeight: resolvedMinimumSize.height,
      ),
    );
    final EdgeInsetsGeometry padding = resolvedPadding.add(
      EdgeInsets.only(
        left: densityAdjustment.dx,
        top: densityAdjustment.dy,
        right: densityAdjustment.dx,
        bottom: densityAdjustment.dy,
      ),
    ).clamp(EdgeInsets.zero, EdgeInsetsGeometry.infinity);

    final Widget result = ConstrainedBox(
      constraints: effectiveConstraints,
      child: Material(
        elevation: resolvedElevation,
        textStyle: resolvedTextStyle?.copyWith(color: resolvedForegroundColor),
        shape: resolvedShape.copyWith(side: resolvedSide),
        color: resolvedBackgroundColor,
        shadowColor: resolvedShadowColor,
        type: resolvedBackgroundColor == null ? MaterialType.transparency : MaterialType.button,
        animationDuration: resolvedAnimationDuration,
        clipBehavior: widget.clipBehavior,
        child: InkWell(
          onTap: widget.onPressed,
          onLongPress: widget.onLongPress,
          onHighlightChanged: _handleHighlightChanged,
          onHover: _handleHoveredChanged,
          mouseCursor: resolvedMouseCursor,
          enableFeedback: resolvedEnableFeedback,
          focusNode: widget.focusNode,
          canRequestFocus: widget.enabled,
          onFocusChange: _handleFocusedChanged,
          autofocus: widget.autofocus,
          splashFactory: InkRipple.splashFactory,
          overlayColor: overlayColor,
          highlightColor: Colors.transparent,
          customBorder: resolvedShape,
          child: IconTheme.merge(
            data: IconThemeData(color: resolvedForegroundColor),
            child: Padding(
              padding: padding,
              child: Center(
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );

    Size minSize;
    switch (resolvedTapTargetSize) {
      case MaterialTapTargetSize.padded:
        minSize = Size(
          kMinInteractiveDimension + densityAdjustment.dx,
          kMinInteractiveDimension + densityAdjustment.dy,
        );
        assert(minSize.width >= 0.0);
        assert(minSize.height >= 0.0);
        break;
      case MaterialTapTargetSize.shrinkWrap:
        minSize = Size.zero;
        break;
    }

    return Semantics(
      container: true,
      button: true,
      enabled: widget.enabled,
      child: _InputPadding(
        minSize: minSize,
        child: result,
      ),
    );
  }
}

class _MouseCursor extends MaterialStateMouseCursor {
  const _MouseCursor(this.resolveCallback);

  final MaterialPropertyResolver<MouseCursor> resolveCallback;

  @override
  MouseCursor resolve(Set<MaterialState> states) => resolveCallback(states);

  @override
  String get debugDescription => 'ButtonStyleButton_MouseCursor';
}

/// A widget to pad the area around a [MaterialButton]'s inner [Material].
///
/// Redirect taps that occur in the padded area around the child to the center
/// of the child. This increases the size of the button and the button's
/// "tap target", but not its material or its ink splashes.
class _InputPadding extends SingleChildRenderObjectWidget {
  const _InputPadding({
    Key key,
    Widget child,
    this.minSize,
  }) : super(key: key, child: child);

  final Size minSize;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderInputPadding(minSize);
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderInputPadding renderObject) {
    renderObject.minSize = minSize;
  }
}

class _RenderInputPadding extends RenderShiftedBox {
  _RenderInputPadding(this._minSize, [RenderBox child]) : super(child);

  Size get minSize => _minSize;
  Size _minSize;
  set minSize(Size value) {
    if (_minSize == value)
      return;
    _minSize = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null)
      return math.max(child.getMinIntrinsicWidth(height), minSize.width);
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null)
      return math.max(child.getMinIntrinsicHeight(width), minSize.height);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null)
      return math.max(child.getMaxIntrinsicWidth(height), minSize.width);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null)
      return math.max(child.getMaxIntrinsicHeight(width), minSize.height);
    return 0.0;
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    if (child != null) {
      child.layout(constraints, parentUsesSize: true);
      final double height = math.max(child.size.width, minSize.width);
      final double width = math.max(child.size.height, minSize.height);
      size = constraints.constrain(Size(height, width));
      final BoxParentData childParentData = child.parentData as BoxParentData;
      childParentData.offset = Alignment.center.alongOffset(size - child.size as Offset);
    } else {
      size = Size.zero;
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, { Offset position }) {
    if (super.hitTest(result, position: position)) {
      return true;
    }
    final Offset center = child.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (BoxHitTestResult result, Offset position) {
        assert(position == center);
        return child.hitTest(result, position: center);
      },
    );
  }
}
