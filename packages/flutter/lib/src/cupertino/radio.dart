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
import 'constants.dart';
import 'theme.dart';

// Examples can assume:
// late BuildContext context;
// enum SingingCharacter { lafayette }
// late SingingCharacter? _character;
// late StateSetter setState;

const Size _size = Size(18.0, 18.0);
const double _kOuterRadius = 7.0;
const double _kInnerRadius = 2.975;

// Eyeballed from a radio on a physical Macbook Pro running macOS version 14.5.
final Color _kDisabledOuterColor = CupertinoColors.white.withOpacity(0.50);
const Color _kDisabledInnerColor = CupertinoDynamicColor.withBrightness(
  color: Color.fromARGB(64, 0, 0, 0),
  darkColor: Color.fromARGB(64, 255, 255, 255),
);
const Color _kDisabledBorderColor = CupertinoDynamicColor.withBrightness(
  color: Color.fromARGB(64, 0, 0, 0),
  darkColor: Color.fromARGB(64, 0, 0, 0),
);
const CupertinoDynamicColor _kDefaultBorderColor = CupertinoDynamicColor.withBrightness(
  color: Color.fromARGB(255, 209, 209, 214),
  darkColor: Color.fromARGB(64, 0, 0, 0),
);
const CupertinoDynamicColor _kDefaultInnerColor = CupertinoDynamicColor.withBrightness(
  color: CupertinoColors.white,
  darkColor: Color.fromARGB(255, 222, 232, 248),
);
const CupertinoDynamicColor _kDefaultOuterColor = CupertinoDynamicColor.withBrightness(
  color: CupertinoColors.activeBlue,
  darkColor: Color.fromARGB(255, 50, 100, 215),
);
const double _kPressedOverlayOpacity = 0.15;
const double _kCheckmarkStrokeWidth = 2.0;
const double _kFocusOutlineStrokeWidth = 3.0;
const double _kBorderOutlineStrokeWidth = 0.3;
// In dark mode, the outer color of a radio is an opacity gradient of the
// background color.
const List<double> _kDarkGradientOpacities = <double>[0.14, 0.29];
const List<double> _kDisabledDarkGradientOpacities = <double>[0.08, 0.14];

/// A widget that builds a [RawRadio] with a macOS-style UI.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=D0xwcz2IqAY}
///
/// Used to select between a number of mutually exclusive values. When one radio
/// button in a group is selected, the other radio buttons in the group are
/// deselected. The values are of type `T`, the type parameter of the
/// [CupertinoRadio] class. Enums are commonly used for this purpose.
///
/// This widget typically has a [RadioGroup] ancestor, which takes in a
/// [RadioGroup.groupValue], and the [CupertinoRadio] under it with matching
/// [value] will be selected.
///
/// {@tool dartpad}
/// Here is an example of CupertinoRadio widgets wrapped in CupertinoListTiles.
///
/// The currently selected character is passed into `RadioGroup.groupValue`, which is
/// maintained by the example's `State`. In this case, the first [CupertinoRadio]
/// will start off selected because `_character` is initialized to
/// `SingingCharacter.lafayette`.
///
/// If the second radio button is pressed, the example's state is updated
/// with `setState`, updating `_character` to `SingingCharacter.jefferson`.
/// This causes the buttons to rebuild with the updated `RadioGroup.groupValue`, and
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
    @Deprecated(
      'Use a RadioGroup ancestor to manage group value instead. '
      'This feature was deprecated after v3.32.0-0.0.pre.',
    )
    this.groupValue,
    @Deprecated(
      'Use RadioGroup to handle value change instead. '
      'This feature was deprecated after v3.32.0-0.0.pre.',
    )
    this.onChanged,
    this.mouseCursor,
    this.toggleable = false,
    this.activeColor,
    this.inactiveColor,
    this.fillColor,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.useCheckmarkStyle = false,
    this.enabled,
    this.groupRegistry,
  });

  /// {@macro flutter.widget.RawRadio.value}
  final T value;

  /// {@macro flutter.material.Radio.groupValue}
  @Deprecated(
    'Use a RadioGroup ancestor to manage group value instead. '
    'This feature was deprecated after v3.32.0-0.0.pre.',
  )
  final T? groupValue;

  /// {@macro flutter.material.Radio.onChanged}
  ///
  /// For example:
  ///
  /// ```dart
  /// CupertinoRadio<SingingCharacter>(
  ///   value: SingingCharacter.lafayette,
  ///   // ignore: deprecated_member_use
  ///   groupValue: _character,
  ///   // ignore: deprecated_member_use
  ///   onChanged: (SingingCharacter? newValue) {
  ///     setState(() {
  ///       _character = newValue;
  ///     });
  ///   },
  /// )
  /// ```
  @Deprecated(
    'Use RadioGroup to handle value change instead. '
    'This feature was deprecated after v3.32.0-0.0.pre.',
  )
  final ValueChanged<T?>? onChanged;

  /// {@macro flutter.widget.RawRadio.mouseCursor}
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

  /// {@macro flutter.widget.RawRadio.toggleable}
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

  /// {@macro flutter.widget.RawRadio.groupRegistry}
  ///
  /// Unless provided, the [BuildContext] will be used to look up the ancestor
  /// [RadioGroupRegistry].
  final RadioGroupRegistry<T>? groupRegistry;

  /// {@macro flutter.material.Radio.enabled}
  final bool? enabled;

  @override
  State<CupertinoRadio<T>> createState() => _CupertinoRadioState<T>();
}

class _CupertinoRadioState<T> extends State<CupertinoRadio<T>> {
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  FocusNode? _internalFocusNode;

  bool get _enabled =>
      widget.enabled ??
      (widget.onChanged != null ||
          widget.groupRegistry != null ||
          RadioGroup.maybeOf<T>(context) != null);

  _RadioRegistry<T>? _internalRadioRegistry;
  RadioGroupRegistry<T> get _effectiveRegistry {
    if (widget.groupRegistry != null) {
      return widget.groupRegistry!;
    }

    final RadioGroupRegistry<T>? inheritedRegistry = RadioGroup.maybeOf<T>(context);
    if (inheritedRegistry != null) {
      return inheritedRegistry;
    }

    // Handles deprecated API.
    return _internalRadioRegistry ??= _RadioRegistry<T>(this);
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      !(widget.enabled ?? false) ||
          widget.onChanged != null ||
          widget.groupRegistry != null ||
          RadioGroup.maybeOf<T>(context) != null,
      'Radio is enabled but has no CupertinoRadio.onChange, '
      'CupertinoRadio.groupRegistry, or RadioGroup above',
    );
    final WidgetStateProperty<MouseCursor> effectiveMouseCursor =
        WidgetStateProperty.resolveWith<MouseCursor>((Set<WidgetState> states) {
          return WidgetStateProperty.resolveAs<MouseCursor?>(widget.mouseCursor, states) ??
              (!states.contains(WidgetState.disabled) && kIsWeb
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic);
        });

    return RawRadio<T>(
      value: widget.value,
      groupRegistry: _effectiveRegistry,
      mouseCursor: effectiveMouseCursor,
      toggleable: widget.toggleable,
      focusNode: _effectiveFocusNode,
      autofocus: widget.autofocus,
      enabled: _enabled,
      builder: (BuildContext context, ToggleableStateMixin state) {
        return _RadioPaint(
          activeColor: widget.activeColor,
          inactiveColor: widget.inactiveColor,
          fillColor: widget.fillColor,
          focusColor: widget.focusColor,
          useCheckmarkStyle: widget.useCheckmarkStyle,
          isActive: _enabled,
          toggleableState: state,
          focused: _effectiveFocusNode.hasFocus,
        );
      },
    );
  }
}

/// A registry for deprecated API.
// TODO(chunhtai): Remove this once deprecated API is removed.
class _RadioRegistry<T> extends RadioGroupRegistry<T> {
  _RadioRegistry(this.state);
  final _CupertinoRadioState<T> state;
  @override
  T? get groupValue => state.widget.groupValue;

  @override
  ValueChanged<T?> get onChanged => state.widget.onChanged!;

  @override
  void registerClient(RadioClient<T> radio) {}

  @override
  void unregisterClient(RadioClient<T> radio) {}
}

class _RadioPaint extends StatefulWidget {
  const _RadioPaint({
    required this.focused,
    required this.toggleableState,
    required this.activeColor,
    required this.inactiveColor,
    required this.fillColor,
    required this.focusColor,
    required this.useCheckmarkStyle,
    required this.isActive,
  });

  final ToggleableStateMixin toggleableState;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? fillColor;
  final Color? focusColor;
  final bool useCheckmarkStyle;
  final bool isActive;

  final bool focused;
  @override
  State<StatefulWidget> createState() => _RadioPaintState();
}

class _RadioPaintState extends State<_RadioPaint> {
  final _RadioPainter _painter = _RadioPainter();

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }

  WidgetStateProperty<Color> get _defaultOuterColor {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return CupertinoDynamicColor.resolve(_kDisabledOuterColor, context);
      }
      if (states.contains(WidgetState.selected)) {
        return widget.activeColor ?? CupertinoDynamicColor.resolve(_kDefaultOuterColor, context);
      }
      return widget.inactiveColor ?? CupertinoColors.white;
    });
  }

  WidgetStateProperty<Color> get _defaultInnerColor {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled) && states.contains(WidgetState.selected)) {
        return widget.fillColor ?? CupertinoDynamicColor.resolve(_kDisabledInnerColor, context);
      }
      if (states.contains(WidgetState.selected)) {
        return widget.fillColor ?? CupertinoDynamicColor.resolve(_kDefaultInnerColor, context);
      }
      return CupertinoColors.white;
    });
  }

  WidgetStateProperty<Color> get _defaultBorderColor {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if ((states.contains(WidgetState.selected) || states.contains(WidgetState.focused)) &&
          !states.contains(WidgetState.disabled)) {
        return CupertinoColors.transparent;
      }
      if (states.contains(WidgetState.disabled)) {
        return CupertinoDynamicColor.resolve(_kDisabledBorderColor, context);
      }
      return CupertinoDynamicColor.resolve(_kDefaultBorderColor, context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Colors need to be resolved in selected and non selected states separately.
    final Set<WidgetState> activeStates = widget.toggleableState.states..add(WidgetState.selected);
    final Set<WidgetState> inactiveStates = widget.toggleableState.states
      ..remove(WidgetState.selected);

    // Since the states getter always makes a new set, make a copy to use
    // throughout the lifecycle of this build method.
    final Set<WidgetState> currentStates = widget.toggleableState.states;

    final Color effectiveActiveColor = _defaultOuterColor.resolve(activeStates);

    final Color effectiveInactiveColor = _defaultOuterColor.resolve(inactiveStates);

    final Color effectiveFocusOverlayColor =
        widget.focusColor ??
        HSLColor.fromColor(effectiveActiveColor.withOpacity(kCupertinoFocusColorOpacity))
            .withLightness(kCupertinoFocusColorBrightness)
            .withSaturation(kCupertinoFocusColorSaturation)
            .toColor();

    final Color effectiveFillColor = _defaultInnerColor.resolve(currentStates);

    final Color effectiveBorderColor = _defaultBorderColor.resolve(currentStates);

    return CustomPaint(
      size: _size,
      painter: _painter
        ..position = widget.toggleableState.position
        ..reaction = widget.toggleableState.reaction
        ..focusColor = effectiveFocusOverlayColor
        ..downPosition = widget.toggleableState.downPosition
        ..isFocused = widget.focused
        ..activeColor = effectiveActiveColor
        ..inactiveColor = effectiveInactiveColor
        ..fillColor = effectiveFillColor
        ..value = widget.toggleableState.value
        ..checkmarkStyle = widget.useCheckmarkStyle
        ..isActive = widget.isActive
        ..borderColor = effectiveBorderColor
        ..brightness = CupertinoTheme.of(context).brightness,
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

  Brightness? get brightness => _brightness;
  Brightness? _brightness;
  set brightness(Brightness? value) {
    if (_brightness == value) {
      return;
    }
    _brightness = value;
    notifyListeners();
  }

  Color get borderColor => _borderColor!;
  Color? _borderColor;
  set borderColor(Color value) {
    if (_borderColor == value) {
      return;
    }
    _borderColor = value;
    notifyListeners();
  }

  void _drawPressedOverlay(Canvas canvas, Offset center, double radius) {
    final pressedPaint = Paint()
      ..color = brightness == Brightness.light
          ? CupertinoColors.black.withOpacity(_kPressedOverlayOpacity)
          : CupertinoColors.white.withOpacity(_kPressedOverlayOpacity);
    canvas.drawCircle(center, radius, pressedPaint);
  }

  void _drawFillGradient(
    Canvas canvas,
    Offset center,
    double radius,
    Color topColor,
    Color bottomColor,
  ) {
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[topColor, bottomColor],
    );
    final circleRect = Rect.fromCircle(center: center, radius: radius);
    final gradientPaint = Paint()..shader = fillGradient.createShader(circleRect);
    canvas.drawPath(Path()..addOval(circleRect), gradientPaint);
  }

  void _drawOuterBorder(Canvas canvas, Offset center) {
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = borderColor
      ..strokeWidth = _kBorderOutlineStrokeWidth;
    canvas.drawCircle(center, _kOuterRadius, borderPaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = (Offset.zero & size).center;

    if (checkmarkStyle) {
      if (value ?? false) {
        final path = Path();
        final checkPaint = Paint()
          ..color = activeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _kCheckmarkStrokeWidth
          ..strokeCap = StrokeCap.round;
        final double width = _size.width;
        final origin = Offset(center.dx - (width / 2), center.dy - (width / 2));
        final start = Offset(width * 0.25, width * 0.52);
        final mid = Offset(width * 0.46, width * 0.75);
        final end = Offset(width * 0.85, width * 0.29);
        path.moveTo(origin.dx + start.dx, origin.dy + start.dy);
        path.lineTo(origin.dx + mid.dx, origin.dy + mid.dy);
        canvas.drawPath(path, checkPaint);
        path.moveTo(origin.dx + mid.dx, origin.dy + mid.dy);
        path.lineTo(origin.dx + end.dx, origin.dy + end.dy);
        canvas.drawPath(path, checkPaint);
      }
    } else {
      if (value ?? false) {
        final outerPaint = Paint()..color = activeColor;
        // Draw a gradient in dark mode if the radio is disabled.
        if (brightness == Brightness.dark && !isActive) {
          _drawFillGradient(
            canvas,
            center,
            _kOuterRadius,
            outerPaint.color.withOpacity(
              isActive ? _kDarkGradientOpacities[0] : _kDisabledDarkGradientOpacities[0],
            ),
            outerPaint.color.withOpacity(
              isActive ? _kDarkGradientOpacities[1] : _kDisabledDarkGradientOpacities[1],
            ),
          );
        } else {
          canvas.drawCircle(center, _kOuterRadius, outerPaint);
        }
        // The outer circle's opacity changes when the radio is pressed.
        if (downPosition != null) {
          _drawPressedOverlay(canvas, center, _kOuterRadius);
        }
        final innerPaint = Paint()..color = fillColor;
        canvas.drawCircle(center, _kInnerRadius, innerPaint);
        // Draw an outer border if the radio is disabled and selected.
        if (!isActive) {
          _drawOuterBorder(canvas, center);
        }
      } else {
        final paint = Paint();
        paint.color = isActive ? inactiveColor : _kDisabledOuterColor;
        if (brightness == Brightness.dark) {
          _drawFillGradient(
            canvas,
            center,
            _kOuterRadius,
            paint.color.withOpacity(
              isActive ? _kDarkGradientOpacities[0] : _kDisabledDarkGradientOpacities[0],
            ),
            paint.color.withOpacity(
              isActive ? _kDarkGradientOpacities[1] : _kDisabledDarkGradientOpacities[1],
            ),
          );
        } else {
          canvas.drawCircle(center, _kOuterRadius, paint);
        }
        // The entire circle's opacity changes when the radio is pressed.
        if (downPosition != null) {
          _drawPressedOverlay(canvas, center, _kOuterRadius);
        }
        _drawOuterBorder(canvas, center);
      }
    }
    if (isFocused) {
      final focusPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = focusColor
        ..strokeWidth = _kFocusOutlineStrokeWidth;
      canvas.drawCircle(center, _kOuterRadius + _kFocusOutlineStrokeWidth / 2, focusPaint);
    }
  }
}
