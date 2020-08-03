// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'constants.dart';
import 'debug.dart';
import 'theme.dart';
import 'theme_data.dart';
import 'toggle_buttons_theme.dart';

/// A horizontal set of toggle buttons.
///
/// The list of [children] are laid out in a row. The state of each button
/// is controlled by [isSelected], which is a list of bools that determine
/// if a button is in an unselected or selected state. They are both
/// correlated by their index in the list. The length of [isSelected] has to
/// match the length of the [children] list.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=kVEguaQWGAY}
///
/// ## Customizing toggle buttons
/// Each toggle's behavior can be configured by the [onPressed] callback, which
/// can update the [isSelected] list however it wants to.
///
/// {@animation 700 150 https://flutter.github.io/assets-for-api-docs/assets/material/toggle_buttons_simple.mp4}
///
/// Here is an implementation that allows for multiple buttons to be
/// simultaneously selected, while requiring none of the buttons to be
/// selected.
/// ```dart
/// ToggleButtons(
///   children: <Widget>[
///     Icon(Icons.ac_unit),
///     Icon(Icons.call),
///     Icon(Icons.cake),
///   ],
///   onPressed: (int index) {
///     setState(() {
///       isSelected[index] = !isSelected[index];
///     });
///   },
///   isSelected: isSelected,
/// ),
/// ```
///
/// {@animation 700 150 https://flutter.github.io/assets-for-api-docs/assets/material/toggle_buttons_required_mutually_exclusive.mp4}
///
/// Here is an implementation that requires mutually exclusive selection
/// while requiring at least one selection. Note that this assumes that
/// [isSelected] was properly initialized with one selection.
/// ```dart
/// ToggleButtons(
///   children: <Widget>[
///     Icon(Icons.ac_unit),
///     Icon(Icons.call),
///     Icon(Icons.cake),
///   ],
///   onPressed: (int index) {
///     setState(() {
///       for (int buttonIndex = 0; buttonIndex < isSelected.length; buttonIndex++) {
///         if (buttonIndex == index) {
///           isSelected[buttonIndex] = true;
///         } else {
///           isSelected[buttonIndex] = false;
///         }
///       }
///     });
///   },
///   isSelected: isSelected,
/// ),
/// ```
///
/// {@animation 700 150 https://flutter.github.io/assets-for-api-docs/assets/material/toggle_buttons_mutually_exclusive.mp4}
///
/// Here is an implementation that requires mutually exclusive selection,
/// but allows for none of the buttons to be selected.
/// ```dart
/// ToggleButtons(
///   children: <Widget>[
///     Icon(Icons.ac_unit),
///     Icon(Icons.call),
///     Icon(Icons.cake),
///   ],
///   onPressed: (int index) {
///     setState(() {
///       for (int buttonIndex = 0; buttonIndex < isSelected.length; buttonIndex++) {
///         if (buttonIndex == index) {
///           isSelected[buttonIndex] = !isSelected[buttonIndex];
///         } else {
///           isSelected[buttonIndex] = false;
///         }
///       }
///     });
///   },
///   isSelected: isSelected,
/// ),
/// ```
///
/// {@animation 700 150 https://flutter.github.io/assets-for-api-docs/assets/material/toggle_buttons_required.mp4}
///
/// Here is an implementation that allows for multiple buttons to be
/// simultaneously selected, while requiring at least one selection. Note
/// that this assumes that [isSelected] was properly initialized with one
/// selection.
/// ```dart
/// ToggleButtons(
///   children: <Widget>[
///     Icon(Icons.ac_unit),
///     Icon(Icons.call),
///     Icon(Icons.cake),
///   ],
///   onPressed: (int index) {
///     int count = 0;
///     isSelected.forEach((bool val) {
///       if (val) count++;
///     });
///
///     if (isSelected[index] && count < 2)
///       return;
///
///     setState(() {
///       isSelected[index] = !isSelected[index];
///     });
///   },
///   isSelected: isSelected,
/// ),
/// ```
///
/// ## ToggleButton Borders
/// The toggle buttons, by default, have a solid, 1 logical pixel border
/// surrounding itself and separating each button. The toggle button borders'
/// color, width, and corner radii are configurable.
///
/// The [selectedBorderColor] determines the border's color when the button is
/// selected, while [disabledBorderColor] determines the border's color when
/// the button is disabled. [borderColor] is used when the button is enabled.
///
/// To remove the border, set [borderWidth] to null. Setting [borderWidth] to
/// 0.0 results in a hairline border. For more information on hairline borders,
/// see [BorderSide.width].
///
/// See also:
///
///  * <https://material.io/design/components/buttons.html#toggle-button>
class ToggleButtons extends StatelessWidget {
  /// Creates a horizontal set of toggle buttons.
  ///
  /// It displays its widgets provided in a [List] of [children] horizontally.
  /// The state of each button is controlled by [isSelected], which is a list
  /// of bools that determine if a button is in an active, disabled, or
  /// selected state. They are both correlated by their index in the list.
  /// The length of [isSelected] has to match the length of the [children]
  /// list.
  ///
  /// Both [children] and [isSelected] properties arguments are required.
  ///
  /// [isSelected] values must be non-null. [focusNodes] must be null or a
  /// list of non-null nodes. [renderBorder] must not be null.
  const ToggleButtons({
    Key key,
    @required this.children,
    @required this.isSelected,
    this.onPressed,
    this.mouseCursor,
    this.textStyle,
    this.constraints,
    this.color,
    this.selectedColor,
    this.disabledColor,
    this.fillColor,
    this.focusColor,
    this.highlightColor,
    this.hoverColor,
    this.splashColor,
    this.focusNodes,
    this.renderBorder = true,
    this.borderColor,
    this.selectedBorderColor,
    this.disabledBorderColor,
    this.borderRadius,
    this.borderWidth,
  }) :
    assert(children != null),
    assert(isSelected != null),
    assert(children.length == isSelected.length),
    super(key: key);

  static const double _defaultBorderWidth = 1.0;

  /// The toggle button widgets.
  ///
  /// These are typically [Icon] or [Text] widgets. The boolean selection
  /// state of each widget is defined by the corresponding [isSelected]
  /// list item.
  ///
  /// The length of children has to match the length of [isSelected]. If
  /// [focusNodes] is not null, the length of children has to also match
  /// the length of [focusNodes].
  final List<Widget> children;

  /// The corresponding selection state of each toggle button.
  ///
  /// Each value in this list represents the selection state of the [children]
  /// widget at the same index.
  ///
  /// The length of [isSelected] has to match the length of [children].
  final List<bool> isSelected;

  /// The callback that is called when a button is tapped.
  ///
  /// The index parameter of the callback is the index of the button that is
  /// tapped or otherwise activated.
  ///
  /// When the callback is null, all toggle buttons will be disabled.
  final void Function(int index) onPressed;

  /// {@macro flutter.material.button.mouseCursor}
  final MouseCursor mouseCursor;

  /// The [TextStyle] to apply to any text in these toggle buttons.
  ///
  /// [TextStyle.color] will be ignored and substituted by [color],
  /// [selectedColor] or [disabledColor] depending on whether the buttons
  /// are active, selected, or disabled.
  final TextStyle textStyle;

  /// Defines the button's size.
  ///
  /// Typically used to constrain the button's minimum size.
  ///
  /// If this property is null, then
  /// BoxConstraints(minWidth: 48.0, minHeight: 48.0) is be used.
  final BoxConstraints constraints;

  /// The color for descendant [Text] and [Icon] widgets if the button is
  /// enabled and not selected.
  ///
  /// If [onPressed] is not null, this color will be used for values in
  /// [isSelected] that are false.
  ///
  /// If this property is null, then ToggleButtonTheme.of(context).color
  /// is used. If [ToggleButtonsThemeData.color] is also null, then
  /// Theme.of(context).colorScheme.onSurface is used.
  final Color color;

  /// The color for descendant [Text] and [Icon] widgets if the button is
  /// selected.
  ///
  /// If [onPressed] is not null, this color will be used for values in
  /// [isSelected] that are true.
  ///
  /// If this property is null, then
  /// ToggleButtonTheme.of(context).selectedColor is used. If
  /// [ToggleButtonsThemeData.selectedColor] is also null, then
  /// Theme.of(context).colorScheme.primary is used.
  final Color selectedColor;

  /// The color for descendant [Text] and [Icon] widgets if the button is
  /// disabled.
  ///
  /// If [onPressed] is null, this color will be used.
  ///
  /// If this property is null, then
  /// ToggleButtonTheme.of(context).disabledColor is used. If
  /// [ToggleButtonsThemeData.disabledColor] is also null, then
  /// Theme.of(context).colorScheme.onSurface.withOpacity(0.38) is used.
  final Color disabledColor;

  /// The fill color for selected toggle buttons.
  ///
  /// If this property is null, then
  /// ToggleButtonTheme.of(context).fillColor is used. If
  /// [ToggleButtonsThemeData.fillColor] is also null, then
  /// the fill color is null.
  final Color fillColor;

  /// The color to use for filling the button when the button has input focus.
  ///
  /// If this property is null, then
  /// ToggleButtonTheme.of(context).focusColor is used. If
  /// [ToggleButtonsThemeData.focusColor] is also null, then
  /// Theme.of(context).focusColor is used.
  final Color focusColor;

  /// The highlight color for the button's [InkWell].
  ///
  /// If this property is null, then
  /// ToggleButtonTheme.of(context).highlightColor is used. If
  /// [ToggleButtonsThemeData.highlightColor] is also null, then
  /// Theme.of(context).highlightColor is used.
  final Color highlightColor;

  /// The splash color for the button's [InkWell].
  ///
  /// If this property is null, then
  /// ToggleButtonTheme.of(context).splashColor is used. If
  /// [ToggleButtonsThemeData.splashColor] is also null, then
  /// Theme.of(context).splashColor is used.
  final Color splashColor;

  /// The color to use for filling the button when the button has a pointer
  /// hovering over it.
  ///
  /// If this property is null, then
  /// ToggleButtonTheme.of(context).hoverColor is used. If
  /// [ToggleButtonsThemeData.hoverColor] is also null, then
  /// Theme.of(context).hoverColor is used.
  final Color hoverColor;

  /// The list of [FocusNode]s, corresponding to each toggle button.
  ///
  /// Focus is used to determine which widget should be affected by keyboard
  /// events. The focus tree keeps track of which widget is currently focused
  /// on by the user.
  ///
  /// If not null, the length of focusNodes has to match the length of
  /// [children].
  ///
  /// See [FocusNode] for more information about how focus nodes are used.
  final List<FocusNode> focusNodes;

  /// Whether or not to render a border around each toggle button.
  ///
  /// When true, a border with [borderWidth], [borderRadius] and the
  /// appropriate border color will render. Otherwise, no border will be
  /// rendered.
  final bool renderBorder;

  /// The border color to display when the toggle button is enabled and not
  /// selected.
  ///
  /// If this property is null, then
  /// ToggleButtonTheme.of(context).borderColor is used. If
  /// [ToggleButtonsThemeData.borderColor] is also null, then
  /// Theme.of(context).colorScheme.onSurface is used.
  final Color borderColor;

  /// The border color to display when the toggle button is selected.
  ///
  /// If this property is null, then
  /// ToggleButtonTheme.of(context).selectedBorderColor is used. If
  /// [ToggleButtonsThemeData.selectedBorderColor] is also null, then
  /// Theme.of(context).colorScheme.primary is used.
  final Color selectedBorderColor;

  /// The border color to display when the toggle button is disabled.
  ///
  /// If this property is null, then
  /// ToggleButtonTheme.of(context).disabledBorderColor is used. If
  /// [ToggleButtonsThemeData.disabledBorderColor] is also null, then
  /// Theme.of(context).disabledBorderColor is used.
  final Color disabledBorderColor;

  /// The width of the border surrounding each toggle button.
  ///
  /// This applies to both the greater surrounding border, as well as the
  /// borders rendered between toggle buttons.
  ///
  /// To render a hairline border (one physical pixel), set borderWidth to 0.0.
  /// See [BorderSide.width] for more details on hairline borders.
  ///
  /// To omit the border entirely, set [renderBorder] to false.
  ///
  /// If this property is null, then
  /// ToggleButtonTheme.of(context).borderWidth is used. If
  /// [ToggleButtonsThemeData.borderWidth] is also null, then
  /// a width of 1.0 is used.
  final double borderWidth;

  /// The radii of the border's corners.
  ///
  /// If this property is null, then
  /// ToggleButtonTheme.of(context).borderRadius is used. If
  /// [ToggleButtonsThemeData.borderRadius] is also null, then
  /// the buttons default to non-rounded borders.
  final BorderRadius borderRadius;

  bool _isFirstIndex(int index, int length, TextDirection textDirection) {
    return index == 0 && textDirection == TextDirection.ltr
        || index == length - 1 && textDirection == TextDirection.rtl;
  }

  bool _isLastIndex(int index, int length, TextDirection textDirection) {
    return index == length - 1 && textDirection == TextDirection.ltr
        || index == 0 && textDirection == TextDirection.rtl;
  }

  BorderRadius _getEdgeBorderRadius(
    int index,
    int length,
    TextDirection textDirection,
    ToggleButtonsThemeData toggleButtonsTheme,
  ) {
    final BorderRadius resultingBorderRadius = borderRadius
      ?? toggleButtonsTheme.borderRadius
      ?? BorderRadius.zero;

    if (_isFirstIndex(index, length, textDirection)) {
      return BorderRadius.only(
        topLeft: resultingBorderRadius.topLeft,
        bottomLeft: resultingBorderRadius.bottomLeft,
      );
    } else if (_isLastIndex(index, length, textDirection)) {
      return BorderRadius.only(
        topRight: resultingBorderRadius.topRight,
        bottomRight: resultingBorderRadius.bottomRight,
      );
    }
    return BorderRadius.zero;
  }

  BorderRadius _getClipBorderRadius(
    int index,
    int length,
    TextDirection textDirection,
    ToggleButtonsThemeData toggleButtonsTheme,
  ) {
    final BorderRadius resultingBorderRadius = borderRadius
      ?? toggleButtonsTheme.borderRadius
      ?? BorderRadius.zero;
    final double resultingBorderWidth = borderWidth
      ?? toggleButtonsTheme.borderWidth
      ?? _defaultBorderWidth;

    if (_isFirstIndex(index, length, textDirection)) {
      return BorderRadius.only(
        topLeft: resultingBorderRadius.topLeft - Radius.circular(resultingBorderWidth / 2.0),
        bottomLeft: resultingBorderRadius.bottomLeft - Radius.circular(resultingBorderWidth / 2.0),
      );
    } else if (_isLastIndex(index, length, textDirection)) {
      return BorderRadius.only(
        topRight: resultingBorderRadius.topRight - Radius.circular(resultingBorderWidth / 2.0),
        bottomRight: resultingBorderRadius.bottomRight - Radius.circular(resultingBorderWidth / 2.0),
      );
    }
    return BorderRadius.zero;
  }

  BorderSide _getLeadingBorderSide(
    int index,
    ThemeData theme,
    ToggleButtonsThemeData toggleButtonsTheme,
  ) {
    if (!renderBorder)
      return BorderSide.none;

    final double resultingBorderWidth = borderWidth
      ?? toggleButtonsTheme.borderWidth
      ?? _defaultBorderWidth;
    if (onPressed != null && (isSelected[index] || (index != 0 && isSelected[index - 1]))) {
      return BorderSide(
        color: selectedBorderColor
          ?? toggleButtonsTheme.selectedBorderColor
          ?? theme.colorScheme.onSurface.withOpacity(0.12),
        width: resultingBorderWidth,
      );
    } else if (onPressed != null && !isSelected[index]) {
      return BorderSide(
        color: borderColor
          ?? toggleButtonsTheme.borderColor
          ?? theme.colorScheme.onSurface.withOpacity(0.12),
        width: resultingBorderWidth,
      );
    } else {
      return BorderSide(
        color: disabledBorderColor
          ?? toggleButtonsTheme.disabledBorderColor
          ?? theme.colorScheme.onSurface.withOpacity(0.12),
        width: resultingBorderWidth,
      );
    }
  }

  BorderSide _getHorizontalBorderSide(
    int index,
    ThemeData theme,
    ToggleButtonsThemeData toggleButtonsTheme,
  ) {
    if (!renderBorder)
      return BorderSide.none;

    final double resultingBorderWidth = borderWidth
      ?? toggleButtonsTheme.borderWidth
      ?? _defaultBorderWidth;
    if (onPressed != null && isSelected[index]) {
      return BorderSide(
        color: selectedBorderColor
          ?? toggleButtonsTheme.selectedBorderColor
          ?? theme.colorScheme.onSurface.withOpacity(0.12),
        width: resultingBorderWidth,
      );
    } else if (onPressed != null && !isSelected[index]) {
      return BorderSide(
        color: borderColor
          ?? toggleButtonsTheme.borderColor
          ?? theme.colorScheme.onSurface.withOpacity(0.12),
        width: resultingBorderWidth,
      );
    } else {
      return BorderSide(
        color: disabledBorderColor
          ?? toggleButtonsTheme.disabledBorderColor
          ?? theme.colorScheme.onSurface.withOpacity(0.12),
        width: resultingBorderWidth,
      );
    }
  }

  BorderSide _getTrailingBorderSide(
    int index,
    ThemeData theme,
    ToggleButtonsThemeData toggleButtonsTheme,
  ) {
    if (!renderBorder)
      return BorderSide.none;

    if (index != children.length - 1)
      return null;

    final double resultingBorderWidth = borderWidth
      ?? toggleButtonsTheme.borderWidth
      ?? _defaultBorderWidth;
    if (onPressed != null && (isSelected[index])) {
      return BorderSide(
        color: selectedBorderColor
          ?? toggleButtonsTheme.selectedBorderColor
          ?? theme.colorScheme.onSurface.withOpacity(0.12),
        width: resultingBorderWidth,
      );
    } else if (onPressed != null && !isSelected[index]) {
      return BorderSide(
        color: borderColor
          ?? toggleButtonsTheme.borderColor
          ?? theme.colorScheme.onSurface.withOpacity(0.12),
        width: resultingBorderWidth,
      );
    } else {
      return BorderSide(
        color: disabledBorderColor
          ?? toggleButtonsTheme.disabledBorderColor
          ?? theme.colorScheme.onSurface.withOpacity(0.12),
        width: resultingBorderWidth,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(
      !isSelected.any((bool val) => val == null),
      'All elements of isSelected must be non-null.\n'
      'The current list of isSelected values is as follows:\n'
      '$isSelected'
    );
    assert(
      focusNodes == null || !focusNodes.any((FocusNode val) => val == null),
      'All elements of focusNodes must be non-null.\n'
      'The current list of focus node values is as follows:\n'
      '$focusNodes'
    );
    assert(
      () {
        if (focusNodes != null)
          return focusNodes.length == children.length;
        return true;
      }(),
      'focusNodes.length must match children.length.\n'
      'There are ${focusNodes.length} focus nodes, while '
      'there are ${children.length} children.'
    );
    final ThemeData theme = Theme.of(context);
    final ToggleButtonsThemeData toggleButtonsTheme = ToggleButtonsTheme.of(context);
    final TextDirection textDirection = Directionality.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(children.length, (int index) {
          final BorderRadius edgeBorderRadius = _getEdgeBorderRadius(index, children.length, textDirection, toggleButtonsTheme);
          final BorderRadius clipBorderRadius = _getClipBorderRadius(index, children.length, textDirection, toggleButtonsTheme);

          final BorderSide leadingBorderSide = _getLeadingBorderSide(index, theme, toggleButtonsTheme);
          final BorderSide horizontalBorderSide = _getHorizontalBorderSide(index, theme, toggleButtonsTheme);
          final BorderSide trailingBorderSide = _getTrailingBorderSide(index, theme, toggleButtonsTheme);

          return _ToggleButton(
            selected: isSelected[index],
            textStyle: textStyle,
            constraints: constraints,
            color: color,
            selectedColor: selectedColor,
            disabledColor: disabledColor,
            fillColor: fillColor ?? toggleButtonsTheme.fillColor,
            focusColor: focusColor ?? toggleButtonsTheme.focusColor,
            highlightColor: highlightColor ?? toggleButtonsTheme.highlightColor,
            hoverColor: hoverColor ?? toggleButtonsTheme.hoverColor,
            splashColor: splashColor ?? toggleButtonsTheme.splashColor,
            focusNode: focusNodes != null ? focusNodes[index] : null,
            onPressed: onPressed != null
              ? () { onPressed(index); }
              : null,
            mouseCursor: mouseCursor,
            leadingBorderSide: leadingBorderSide,
            horizontalBorderSide: horizontalBorderSide,
            trailingBorderSide: trailingBorderSide,
            borderRadius: edgeBorderRadius,
            clipRadius: clipBorderRadius,
            isFirstButton: index == 0,
            isLastButton: index == children.length - 1,
            child: children[index],
          );
        }),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('disabled',
      value: onPressed == null,
      ifTrue: 'Buttons are disabled',
      ifFalse: 'Buttons are enabled',
    ));
    textStyle?.debugFillProperties(properties, prefix: 'textStyle.');
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(ColorProperty('selectedColor', selectedColor, defaultValue: null));
    properties.add(ColorProperty('disabledColor', disabledColor, defaultValue: null));
    properties.add(ColorProperty('fillColor', fillColor, defaultValue: null));
    properties.add(ColorProperty('focusColor', focusColor, defaultValue: null));
    properties.add(ColorProperty('highlightColor', highlightColor, defaultValue: null));
    properties.add(ColorProperty('hoverColor', hoverColor, defaultValue: null));
    properties.add(ColorProperty('splashColor', splashColor, defaultValue: null));
    properties.add(ColorProperty('borderColor', borderColor, defaultValue: null));
    properties.add(ColorProperty('selectedBorderColor', selectedBorderColor, defaultValue: null));
    properties.add(ColorProperty('disabledBorderColor', disabledBorderColor, defaultValue: null));
    properties.add(DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius, defaultValue: null));
    properties.add(DoubleProperty('borderWidth', borderWidth, defaultValue: null));
  }
}

/// An individual toggle button, otherwise known as a segmented button.
///
/// This button is used by [ToggleButtons] to implement a set of segmented controls.
class _ToggleButton extends StatelessWidget {
  /// Creates a toggle button based on [RawMaterialButton].
  ///
  /// This class adds some logic to distinguish between enabled, active, and
  /// disabled states, to determine the appropriate colors to use.
  ///
  /// It takes in a [shape] property to modify the borders of the button,
  /// which is used by [ToggleButtons] to customize borders based on the
  /// order in which this button appears in the list.
  const _ToggleButton({
    Key key,
    this.selected = false,
    this.textStyle,
    this.constraints,
    this.color,
    this.selectedColor,
    this.disabledColor,
    this.fillColor,
    this.focusColor,
    this.highlightColor,
    this.hoverColor,
    this.splashColor,
    this.focusNode,
    this.onPressed,
    this.mouseCursor,
    this.leadingBorderSide,
    this.horizontalBorderSide,
    this.trailingBorderSide,
    this.borderRadius,
    this.clipRadius,
    this.isFirstButton,
    this.isLastButton,
    this.child,
  }) : super(key: key);

  /// Determines if the button is displayed as active/selected or enabled.
  final bool selected;

  /// The [TextStyle] to apply to any text that appears in this button.
  final TextStyle textStyle;

  /// Defines the button's size.
  ///
  /// Typically used to constrain the button's minimum size.
  final BoxConstraints constraints;

  /// The color for [Text] and [Icon] widgets if the button is enabled.
  ///
  /// If [selected] is false and [onPressed] is not null, this color will be used.
  final Color color;

  /// The color for [Text] and [Icon] widgets if the button is selected.
  ///
  /// If [selected] is true and [onPressed] is not null, this color will be used.
  final Color selectedColor;

  /// The color for [Text] and [Icon] widgets if the button is disabled.
  ///
  /// If [onPressed] is null, this color will be used.
  final Color disabledColor;

  /// The color of the button's [Material].
  final Color fillColor;

  /// The color for the button's [Material] when it has the input focus.
  final Color focusColor;

  /// The color for the button's [Material] when a pointer is hovering over it.
  final Color hoverColor;

  /// The highlight color for the button's [InkWell].
  final Color highlightColor;

  /// The splash color for the button's [InkWell].
  final Color splashColor;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode focusNode;

  /// Called when the button is tapped or otherwise activated.
  ///
  /// If this is null, the button will be disabled, see [enabled].
  final VoidCallback onPressed;

  /// {@macro flutter.material.button.mouseCursor}
  final MouseCursor mouseCursor;

  /// The width and color of the button's leading side border.
  final BorderSide leadingBorderSide;

  /// The width and color of the button's top and bottom side borders.
  final BorderSide horizontalBorderSide;

  /// The width and color of the button's trailing side border.
  final BorderSide trailingBorderSide;

  /// The border radii of each corner of the button.
  final BorderRadius borderRadius;

  /// The corner radii used to clip the button's contents.
  ///
  /// This is used to have the button's contents be properly clipped taking
  /// the [borderRadius] and the border's width into account.
  final BorderRadius clipRadius;

  /// Whether or not this toggle button is the first button in the list.
  final bool isFirstButton;

  /// Whether or not this toggle button is the last button in the list.
  final bool isLastButton;

  /// The button's label, which is usually an [Icon] or a [Text] widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    Color currentColor;
    Color currentFillColor;
    Color currentFocusColor;
    Color currentHoverColor;
    Color currentSplashColor;
    final ThemeData theme = Theme.of(context);
    final ToggleButtonsThemeData toggleButtonsTheme = ToggleButtonsTheme.of(context);

    if (onPressed != null && selected) {
      currentColor = selectedColor
        ?? toggleButtonsTheme.selectedColor
        ?? theme.colorScheme.primary;
      currentFillColor = fillColor
        ?? theme.colorScheme.primary.withOpacity(0.12);
      currentFocusColor = focusColor
        ?? toggleButtonsTheme.focusColor
        ?? theme.colorScheme.primary.withOpacity(0.12);
      currentHoverColor = hoverColor
        ?? toggleButtonsTheme.hoverColor
        ?? theme.colorScheme.primary.withOpacity(0.04);
      currentSplashColor = splashColor
        ?? toggleButtonsTheme.splashColor
        ?? theme.colorScheme.primary.withOpacity(0.16);
    } else if (onPressed != null && !selected) {
      currentColor = color
        ?? toggleButtonsTheme.color
        ?? theme.colorScheme.onSurface.withOpacity(0.87);
      currentFillColor = theme.colorScheme.surface.withOpacity(0.0);
      currentFocusColor = focusColor
        ?? toggleButtonsTheme.focusColor
        ?? theme.colorScheme.onSurface.withOpacity(0.12);
      currentHoverColor = hoverColor
        ?? toggleButtonsTheme.hoverColor
        ?? theme.colorScheme.onSurface.withOpacity(0.04);
      currentSplashColor = splashColor
        ?? toggleButtonsTheme.splashColor
        ?? theme.colorScheme.onSurface.withOpacity(0.16);
    } else {
      currentColor = disabledColor
        ?? toggleButtonsTheme.disabledColor
        ?? theme.colorScheme.onSurface.withOpacity(0.38);
      currentFillColor = theme.colorScheme.surface.withOpacity(0.0);
    }

    final TextStyle currentTextStyle = textStyle ?? toggleButtonsTheme.textStyle ?? theme.textTheme.bodyText2;
    final BoxConstraints currentConstraints = constraints ?? toggleButtonsTheme.constraints ?? const BoxConstraints(minWidth: kMinInteractiveDimension, minHeight: kMinInteractiveDimension);

    final Widget result = ClipRRect(
      borderRadius: clipRadius,
      child: RawMaterialButton(
        textStyle: currentTextStyle.copyWith(
          color: currentColor,
        ),
        constraints: currentConstraints,
        elevation: 0.0,
        highlightElevation: 0.0,
        fillColor: currentFillColor,
        focusColor: currentFocusColor,
        highlightColor: highlightColor
          ?? theme.colorScheme.surface.withOpacity(0.0),
        hoverColor: currentHoverColor,
        splashColor: currentSplashColor,
        focusNode: focusNode,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: onPressed,
        mouseCursor: mouseCursor,
        child: child,
      ),
    );

    return _SelectToggleButton(
      key: key,
      leadingBorderSide: leadingBorderSide,
      horizontalBorderSide: horizontalBorderSide,
      trailingBorderSide: trailingBorderSide,
      borderRadius: borderRadius,
      isFirstButton: isFirstButton,
      isLastButton: isLastButton,
      child: result,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('selected',
      value: selected,
      ifTrue: 'Button is selected',
      ifFalse: 'Button is unselected',
    ));
  }
}

class _SelectToggleButton extends SingleChildRenderObjectWidget {
  const _SelectToggleButton({
    Key key,
    Widget child,
    this.leadingBorderSide,
    this.horizontalBorderSide,
    this.trailingBorderSide,
    this.borderRadius,
    this.isFirstButton,
    this.isLastButton,
  }) : super(
    key: key,
    child: child,
  );

  // The width and color of the button's leading side border.
  final BorderSide leadingBorderSide;

  // The width and color of the button's top and bottom side borders.
  final BorderSide horizontalBorderSide;

  // The width and color of the button's trailing side border.
  final BorderSide trailingBorderSide;

  // The border radii of each corner of the button.
  final BorderRadius borderRadius;

  // Whether or not this toggle button is the first button in the list.
  final bool isFirstButton;

  // Whether or not this toggle button is the last button in the list.
  final bool isLastButton;

  @override
  _SelectToggleButtonRenderObject createRenderObject(BuildContext context) => _SelectToggleButtonRenderObject(
    leadingBorderSide,
    horizontalBorderSide,
    trailingBorderSide,
    borderRadius,
    isFirstButton,
    isLastButton,
    Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, _SelectToggleButtonRenderObject renderObject) {
    renderObject
      ..leadingBorderSide = leadingBorderSide
      ..horizontalBorderSide = horizontalBorderSide
      ..trailingBorderSide = trailingBorderSide
      ..borderRadius = borderRadius
      ..isFirstButton = isFirstButton
      ..isLastButton = isLastButton
      ..textDirection = Directionality.of(context);
  }
}

class _SelectToggleButtonRenderObject extends RenderShiftedBox {
  _SelectToggleButtonRenderObject(
    this._leadingBorderSide,
    this._horizontalBorderSide,
    this._trailingBorderSide,
    this._borderRadius,
    this._isFirstButton,
    this._isLastButton,
    this._textDirection, [
    RenderBox child,
  ]) : super(child);

  // The width and color of the button's leading side border.
  BorderSide get leadingBorderSide => _leadingBorderSide;
  BorderSide _leadingBorderSide;
  set leadingBorderSide(BorderSide value) {
    if (_leadingBorderSide == value)
      return;
    _leadingBorderSide = value;
    markNeedsLayout();
  }

  // The width and color of the button's top and bottom side borders.
  BorderSide get horizontalBorderSide => _horizontalBorderSide;
  BorderSide _horizontalBorderSide;
  set horizontalBorderSide(BorderSide value) {
    if (_horizontalBorderSide == value)
      return;
    _horizontalBorderSide = value;
    markNeedsLayout();
  }

  // The width and color of the button's trailing side border.
  BorderSide get trailingBorderSide => _trailingBorderSide;
  BorderSide _trailingBorderSide;
  set trailingBorderSide(BorderSide value) {
    if (_trailingBorderSide == value)
      return;
    _trailingBorderSide = value;
    markNeedsLayout();
  }

  // The border radii of each corner of the button.
  BorderRadius get borderRadius => _borderRadius;
  BorderRadius _borderRadius;
  set borderRadius(BorderRadius value) {
    if (_borderRadius == value)
      return;
    _borderRadius = value;
    markNeedsLayout();
  }

  // Whether or not this toggle button is the first button in the list.
  bool get isFirstButton => _isFirstButton;
  bool _isFirstButton;
  set isFirstButton(bool value) {
    if (_isFirstButton == value)
      return;
    _isFirstButton = value;
    markNeedsLayout();
  }

  // Whether or not this toggle button is the last button in the list.
  bool get isLastButton => _isLastButton;
  bool _isLastButton;
  set isLastButton(bool value) {
    if (_isLastButton == value)
      return;
    _isLastButton = value;
    markNeedsLayout();
  }

  // The direction in which text flows for this application.
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value)
      return;
    _textDirection = value;
    markNeedsLayout();
  }

  static double _maxHeight(RenderBox box, double width) {
    return box == null ? 0.0 : box.getMaxIntrinsicHeight(width);
  }

  static double _minWidth(RenderBox box, double height) {
    return box == null ? 0.0 : box.getMinIntrinsicWidth(height);
  }

  static double _maxWidth(RenderBox box, double height) {
    return box == null ? 0.0 : box.getMaxIntrinsicWidth(height);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    // The baseline of this widget is the baseline of its child
    return child.computeDistanceToActualBaseline(baseline) +
      horizontalBorderSide.width;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return horizontalBorderSide.width +
      _maxHeight(child, width) +
      horizontalBorderSide.width;
  }

  @override
  double computeMinIntrinsicHeight(double width) => computeMaxIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicWidth(double height) {
    final double trailingWidth = trailingBorderSide == null ? 0.0 : trailingBorderSide.width;
    return leadingBorderSide.width +
           _maxWidth(child, height) +
           trailingWidth;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final double trailingWidth = trailingBorderSide == null ? 0.0 : trailingBorderSide.width;
    return leadingBorderSide.width +
           _minWidth(child, height) +
           trailingWidth;
  }

  @override
  void performLayout() {
    if (child == null) {
      size = constraints.constrain(Size(
        leadingBorderSide.width + trailingBorderSide.width,
        horizontalBorderSide.width * 2.0,
      ));
      return;
    }

    final double trailingBorderOffset = isLastButton ? trailingBorderSide.width : 0.0;
    double leftConstraint;
    double rightConstraint;

    switch (textDirection) {
      case TextDirection.ltr:
        rightConstraint = trailingBorderOffset;
        leftConstraint = leadingBorderSide.width;

        final BoxConstraints innerConstraints = constraints.deflate(
          EdgeInsets.only(
            left: leftConstraint,
            top: horizontalBorderSide.width,
            right: rightConstraint,
            bottom: horizontalBorderSide.width,
          ),
        );

        child.layout(innerConstraints, parentUsesSize: true);
        final BoxParentData childParentData = child.parentData as BoxParentData;
        childParentData.offset = Offset(leadingBorderSide.width, leadingBorderSide.width);

        size = constraints.constrain(Size(
          leftConstraint + child.size.width + rightConstraint,
          horizontalBorderSide.width * 2.0 + child.size.height,
        ));
        break;
      case TextDirection.rtl:
        rightConstraint = leadingBorderSide.width;
        leftConstraint = trailingBorderOffset;

        final BoxConstraints innerConstraints = constraints.deflate(
          EdgeInsets.only(
            left: leftConstraint,
            top: horizontalBorderSide.width,
            right: rightConstraint,
            bottom: horizontalBorderSide.width,
          ),
        );

        child.layout(innerConstraints, parentUsesSize: true);
        final BoxParentData childParentData = child.parentData as BoxParentData;

        if (isLastButton) {
          childParentData.offset = Offset(trailingBorderOffset, trailingBorderOffset);
        } else {
          childParentData.offset = Offset(0, horizontalBorderSide.width);
        }

        size = constraints.constrain(Size(
          leftConstraint + child.size.width + rightConstraint,
          horizontalBorderSide.width * 2.0 + child.size.height,
        ));
        break;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final Offset bottomRight = size.bottomRight(offset);
    final Rect outer = Rect.fromLTRB(offset.dx, offset.dy, bottomRight.dx, bottomRight.dy);
    final Rect center = outer.deflate(horizontalBorderSide.width / 2.0);
    const double sweepAngle = math.pi / 2.0;

    final RRect rrect = RRect.fromRectAndCorners(
      center,
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    ).scaleRadii();

    final Rect tlCorner = Rect.fromLTWH(
      rrect.left,
      rrect.top,
      rrect.tlRadiusX * 2.0,
      rrect.tlRadiusY * 2.0,
    );
    final Rect blCorner = Rect.fromLTWH(
      rrect.left,
      rrect.bottom - (rrect.blRadiusY * 2.0),
      rrect.blRadiusX * 2.0,
      rrect.blRadiusY * 2.0,
    );
    final Rect trCorner = Rect.fromLTWH(
      rrect.right - (rrect.trRadiusX * 2),
      rrect.top,
      rrect.trRadiusX * 2,
      rrect.trRadiusY * 2,
    );
    final Rect brCorner = Rect.fromLTWH(
      rrect.right - (rrect.brRadiusX * 2),
      rrect.bottom - (rrect.brRadiusY * 2),
      rrect.brRadiusX * 2,
      rrect.brRadiusY * 2,
    );

    final Paint leadingPaint = leadingBorderSide.toPaint();
    switch (textDirection) {
      case TextDirection.ltr:
        if (isLastButton) {
          final Path leftPath = Path()
            ..moveTo(rrect.left, rrect.bottom + leadingBorderSide.width / 2)
            ..lineTo(rrect.left, rrect.top - leadingBorderSide.width / 2);
          context.canvas.drawPath(leftPath, leadingPaint);

          final Paint endingPaint = trailingBorderSide.toPaint();
          final Path endingPath = Path()
            ..moveTo(rrect.left + horizontalBorderSide.width / 2.0, rrect.top)
            ..lineTo(rrect.right - rrect.trRadiusX, rrect.top)
            ..addArc(trCorner, math.pi * 3.0 / 2.0, sweepAngle)
            ..lineTo(rrect.right, rrect.bottom - rrect.brRadiusY)
            ..addArc(brCorner, 0, sweepAngle)
            ..lineTo(rrect.left + horizontalBorderSide.width / 2.0, rrect.bottom);
          context.canvas.drawPath(endingPath, endingPaint);
        } else if (isFirstButton) {
          final Path leadingPath = Path()
            ..moveTo(outer.right, rrect.bottom)
            ..lineTo(rrect.left + rrect.blRadiusX, rrect.bottom)
            ..addArc(blCorner, math.pi / 2.0, sweepAngle)
            ..lineTo(rrect.left, rrect.top + rrect.tlRadiusY)
            ..addArc(tlCorner, math.pi, sweepAngle)
            ..lineTo(outer.right, rrect.top);
          context.canvas.drawPath(leadingPath, leadingPaint);
        } else {
          final Path leadingPath = Path()
            ..moveTo(rrect.left, rrect.bottom + leadingBorderSide.width / 2)
            ..lineTo(rrect.left, rrect.top - leadingBorderSide.width / 2);
          context.canvas.drawPath(leadingPath, leadingPaint);

          final Paint horizontalPaint = horizontalBorderSide.toPaint();
          final Path horizontalPaths = Path()
            ..moveTo(rrect.left + horizontalBorderSide.width / 2.0, rrect.top)
            ..lineTo(outer.right - rrect.trRadiusX, rrect.top)
            ..moveTo(rrect.left + horizontalBorderSide.width / 2.0 + rrect.tlRadiusX, rrect.bottom)
            ..lineTo(outer.right - rrect.trRadiusX, rrect.bottom);
          context.canvas.drawPath(horizontalPaths, horizontalPaint);
        }
        break;
      case TextDirection.rtl:
        if (isLastButton) {
          final Path leadingPath = Path()
            ..moveTo(rrect.right, rrect.bottom + leadingBorderSide.width / 2)
            ..lineTo(rrect.right, rrect.top - leadingBorderSide.width / 2);
          context.canvas.drawPath(leadingPath, leadingPaint);

          final Paint endingPaint = trailingBorderSide.toPaint();
          final Path endingPath = Path()
            ..moveTo(rrect.right - horizontalBorderSide.width / 2.0, rrect.top)
            ..lineTo(rrect.left + rrect.tlRadiusX, rrect.top)
            ..addArc(tlCorner, math.pi * 3.0 / 2.0, -sweepAngle)
            ..lineTo(rrect.left, rrect.bottom - rrect.blRadiusY)
            ..addArc(blCorner, math.pi, -sweepAngle)
            ..lineTo(rrect.right - horizontalBorderSide.width / 2.0, rrect.bottom);
          context.canvas.drawPath(endingPath, endingPaint);
        } else if (isFirstButton) {
          final Path leadingPath = Path()
            ..moveTo(outer.left, rrect.bottom)
            ..lineTo(rrect.right - rrect.brRadiusX, rrect.bottom)
            ..addArc(brCorner, math.pi / 2.0, -sweepAngle)
            ..lineTo(rrect.right, rrect.top + rrect.trRadiusY)
            ..addArc(trCorner, 0, -sweepAngle)
            ..lineTo(outer.left, rrect.top);
          context.canvas.drawPath(leadingPath, leadingPaint);
        } else {
          final Path leadingPath = Path()
            ..moveTo(rrect.right, rrect.bottom + leadingBorderSide.width / 2)
            ..lineTo(rrect.right, rrect.top - leadingBorderSide.width / 2);
          context.canvas.drawPath(leadingPath, leadingPaint);

          final Paint horizontalPaint = horizontalBorderSide.toPaint();
          final Path horizontalPaths = Path()
            ..moveTo(rrect.right - horizontalBorderSide.width / 2.0, rrect.top)
            ..lineTo(outer.left - rrect.tlRadiusX, rrect.top)
            ..moveTo(rrect.right - horizontalBorderSide.width / 2.0 + rrect.trRadiusX, rrect.bottom)
            ..lineTo(outer.left - rrect.tlRadiusX, rrect.bottom);
          context.canvas.drawPath(horizontalPaths, horizontalPaint);
        }
        break;
    }
  }
}
