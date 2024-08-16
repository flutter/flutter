// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
///
/// @docImport 'checkbox.dart';
/// @docImport 'slider.dart';
/// @docImport 'switch.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

// Examples can assume:
// late BuildContext context;
// enum SingingCharacter { lafayette }
// late SingingCharacter? _character;
// late StateSetter setState;

const Size _size = Size(18.0, 18.0);
const double _kOuterRadius = 7.0;
const double _kInnerRadius = 2.975;

// The relative values needed to transform a color to its equivalent focus
// outline color.
const double _kCupertinoFocusColorOpacity = 0.80;
const double _kCupertinoFocusColorBrightness = 0.69;
const double _kCupertinoFocusColorSaturation = 0.835;

/// A macOS-style radio button.
///
/// Used to select between a number of mutually exclusive values. When one radio
/// button in a group is selected, the other radio buttons in the group are
/// deselected. The values are of type `T`, the type parameter of the
/// [CupertinoRadio] class. Enums are commonly used for this purpose.
///
/// The radio button itself does not maintain any state. Instead, selecting the
/// radio invokes the [onChanged] callback, passing [value] as a parameter. If
/// [groupValue] and [value] match, this radio will be selected. Most widgets
/// will respond to [onChanged] by calling [State.setState] to update the
/// radio button's [groupValue].
///
/// {@tool dartpad}
/// Here is an example of CupertinoRadio widgets wrapped in CupertinoListTiles.
///
/// The currently selected character is passed into `groupValue`, which is
/// maintained by the example's `State`. In this case, the first [CupertinoRadio]
/// will start off selected because `_character` is initialized to
/// `SingingCharacter.lafayette`.
///
/// If the second radio button is pressed, the example's state is updated
/// with `setState`, updating `_character` to `SingingCharacter.jefferson`.
/// This causes the buttons to rebuild with the updated `groupValue`, and
/// therefore the selection of the second button.
///
/// ** See code in examples/api/lib/cupertino/radio/cupertino_radio.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [CupertinoSlider], for selecting a value in a range.
///  * [CupertinoCheckbox] and [CupertinoSwitch], for toggling a particular value on or off.
///  * [Radio], the Material Design equivalent.
///  * <https://developer.apple.com/design/human-interface-guidelines/components/selection-and-input/toggles/>
class CupertinoRadio<T> extends StatefulWidget {
  /// Creates a macOS-styled radio button.
  ///
  /// The following arguments are required:
  ///
  /// * [value] and [groupValue] together determine whether the radio button is
  ///   selected.
  /// * [onChanged] is called when the user selects this radio button.
  const CupertinoRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.mouseCursor,
    this.toggleable = false,
    this.activeColor,
    this.inactiveColor,
    this.fillColor,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.useCheckmarkStyle = false,
  });

  /// The value represented by this radio button.
  ///
  /// If this equals the [groupValue], then this radio button will appear
  /// selected.
  final T value;

  /// The currently selected value for a group of radio buttons.
  ///
  /// This radio button is considered selected if its [value] matches the
  /// [groupValue].
  final T? groupValue;

  /// Called when the user selects this [CupertinoRadio] button.
  ///
  /// The radio button passes [value] as a parameter to this callback. It does
  /// not actually change state until the parent widget rebuilds the radio
  /// button with a new [groupValue].
  ///
  /// If null, the radio button will be displayed as disabled.
  ///
  /// The provided callback will not be invoked if this radio button is already
  /// selected.
  ///
  /// The callback provided to [onChanged] should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt; for example:
  ///
  /// ```dart
  /// CupertinoRadio<SingingCharacter>(
  ///   value: SingingCharacter.lafayette,
  ///   groupValue: _character,
  ///   onChanged: (SingingCharacter? newValue) {
  ///     setState(() {
  ///       _character = newValue;
  ///     });
  ///   },
  /// )
  /// ```
  final ValueChanged<T?>? onChanged;

  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// If [mouseCursor] is a [WidgetStateMouseCursor],
  /// [WidgetStateMouseCursor.resolve] is used for the following [WidgetState]s:
  ///
  ///  * [WidgetState.selected].
  ///  * [WidgetState.hovered].
  ///  * [WidgetState.focused].
  ///  * [WidgetState.disabled].
  ///
  /// If null, then [SystemMouseCursors.basic] is used when this radio button is disabled.
  /// When this radio button is enabled, [SystemMouseCursors.click] is used on Web, and
  /// [SystemMouseCursors.basic] is used on other platforms.
  ///
  /// See also:
  ///
  ///  * [WidgetStateMouseCursor], a [MouseCursor] that implements
  ///    `WidgetStateProperty` which is used in APIs that need to accept
  ///    either a [MouseCursor] or a [WidgetStateProperty<MouseCursor>].
  final MouseCursor? mouseCursor;

  /// Set to true if this radio button is allowed to be returned to an
  /// indeterminate state by selecting it again when selected.
  ///
  /// To indicate returning to an indeterminate state, [onChanged] will be
  /// called with null.
  ///
  /// If true, [onChanged] can be called with [value] when selected while
  /// [groupValue] != [value], or with null when selected again while
  /// [groupValue] == [value].
  ///
  /// If false, [onChanged] will be called with [value] when it is selected
  /// while [groupValue] != [value], and only by selecting another radio button
  /// in the group (i.e. changing the value of [groupValue]) can this radio
  /// button be unselected.
  ///
  /// The default is false.
  ///
  /// {@tool dartpad}
  /// This example shows how to enable deselecting a radio button by setting the
  /// [toggleable] attribute.
  ///
  /// ** See code in examples/api/lib/cupertino/radio/cupertino_radio.toggleable.0.dart **
  /// {@end-tool}
  final bool toggleable;

  /// Controls whether the radio displays in a checkbox style or the default iOS
  /// radio style.
  ///
  /// Defaults to false.
  final bool useCheckmarkStyle;

  /// The color to use when this radio button is selected.
  ///
  /// Defaults to [CupertinoColors.activeBlue].
  final Color? activeColor;

  /// The color to use when this radio button is not selected.
  ///
  /// Defaults to [CupertinoColors.white].
  final Color? inactiveColor;

  /// The color that fills the inner circle of the radio button when selected.
  ///
  /// Defaults to [CupertinoColors.white].
  final Color? fillColor;

  /// The color for the radio's border when it has the input focus.
  ///
  /// If null, then a paler form of the [activeColor] will be used.
  final Color? focusColor;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  bool get _selected => value == groupValue;

  @override
  State<CupertinoRadio<T>> createState() => _CupertinoRadioState<T>();
}

class _CupertinoRadioState<T> extends State<CupertinoRadio<T>> with TickerProviderStateMixin, ToggleableStateMixin {
  final _RadioPainter _painter = _RadioPainter();

  bool focused = false;

  void _handleChanged(bool? selected) {
    if (selected == null) {
      widget.onChanged!(null);
      return;
    }
    if (selected) {
      widget.onChanged!(widget.value);
    }
  }

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }

  @override
  ValueChanged<bool?>? get onChanged => widget.onChanged != null ? _handleChanged : null;

  @override
  bool get tristate => widget.toggleable;

  @override
  bool? get value => widget._selected;

  void onFocusChange(bool value) {
    if (focused != value) {
      focused = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveActiveColor = widget.activeColor
      ?? CupertinoColors.activeBlue;
    final Color effectiveInactiveColor = widget.inactiveColor
      ?? CupertinoColors.white;

    final Color effectiveFocusOverlayColor = widget.focusColor
      ?? HSLColor
          .fromColor(effectiveActiveColor.withOpacity(_kCupertinoFocusColorOpacity))
          .withLightness(_kCupertinoFocusColorBrightness)
          .withSaturation(_kCupertinoFocusColorSaturation)
          .toColor();

    final Color effectiveActivePressedOverlayColor =
      HSLColor.fromColor(effectiveActiveColor).withLightness(0.45).toColor();

    final Color effectiveFillColor = widget.fillColor ?? CupertinoColors.white;

    final WidgetStateProperty<MouseCursor> effectiveMouseCursor =
      WidgetStateProperty.resolveWith<MouseCursor>((Set<WidgetState> states) {
        return WidgetStateProperty.resolveAs<MouseCursor?>(widget.mouseCursor, states)
          ?? (states.contains(WidgetState.disabled)
              ? SystemMouseCursors.basic
              : kIsWeb ? SystemMouseCursors.click : SystemMouseCursors.basic
            );
      });

    final bool? accessibilitySelected;
    // Apple devices also use `selected` to annotate radio button's semantics
    // state.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        accessibilitySelected = null;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        accessibilitySelected = widget._selected;
    }

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: widget._selected,
      selected: accessibilitySelected,
      child: buildToggleable(
        mouseCursor: effectiveMouseCursor,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onFocusChange: onFocusChange,
        size: _size,
        painter: _painter
          ..focusColor = effectiveFocusOverlayColor
          ..downPosition = downPosition
          ..isFocused = focused
          ..activeColor = downPosition != null ? effectiveActivePressedOverlayColor : effectiveActiveColor
          ..inactiveColor = effectiveInactiveColor
          ..fillColor = effectiveFillColor
          ..value = value
          ..checkmarkStyle = widget.useCheckmarkStyle,
      ),
    );
  }
}

class _RadioPainter extends ToggleablePainter {
  bool? get value => _value;
  bool? _value;
  set value(bool? value) {
    if (_value == value) {
      return;
    }
    _value = value;
    notifyListeners();
  }

  Color get fillColor => _fillColor!;
  Color? _fillColor;
  set fillColor(Color value) {
    if (value == _fillColor) {
      return;
    }
    _fillColor = value;
    notifyListeners();
  }

  bool get checkmarkStyle => _checkmarkStyle;
  bool _checkmarkStyle = false;
  set checkmarkStyle(bool value) {
    if (value == _checkmarkStyle) {
      return;
    }
    _checkmarkStyle = value;
    notifyListeners();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = (Offset.zero & size).center;

    final Paint paint = Paint()
        ..color = inactiveColor
        ..style = PaintingStyle.fill
        ..strokeWidth = 0.1;

    if (checkmarkStyle) {
      if (value ?? false) {
        final Path path = Path();
        final Paint checkPaint = Paint()
          ..color = activeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        final double width = _size.width;
        final Offset origin = Offset(center.dx - (width/2), center.dy - (width/2));
        final Offset start = Offset(width * 0.25, width * 0.52);
        final Offset mid = Offset(width * 0.46, width * 0.75);
        final Offset end = Offset(width * 0.85, width * 0.29);
        path.moveTo(origin.dx + start.dx, origin.dy + start.dy);
        path.lineTo(origin.dx + mid.dx, origin.dy + mid.dy);
        canvas.drawPath(path, checkPaint);
        path.moveTo(origin.dx + mid.dx, origin.dy + mid.dy);
        path.lineTo(origin.dx + end.dx, origin.dy + end.dy);
        canvas.drawPath(path, checkPaint);
      }
    } else {
      // Outer border
      canvas.drawCircle(center, _kOuterRadius, paint);

      paint.style = PaintingStyle.stroke;
      paint.color = CupertinoColors.inactiveGray;
      canvas.drawCircle(center, _kOuterRadius, paint);

      if (value ?? false) {
        paint.style = PaintingStyle.fill;
        paint.color = activeColor;
        canvas.drawCircle(center, _kOuterRadius, paint);
        paint.color = fillColor;
        canvas.drawCircle(center, _kInnerRadius, paint);
      }
    }

    if (isFocused) {
      paint.style = PaintingStyle.stroke;
      paint.color = focusColor;
      paint.strokeWidth = 3.0;
      canvas.drawCircle(center, _kOuterRadius + 1.5, paint);
    }
  }
}
