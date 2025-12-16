// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'checkbox.dart';
/// @docImport 'list_tile.dart';
/// @docImport 'material.dart';
/// @docImport 'radio_list_tile.dart';
/// @docImport 'slider.dart';
/// @docImport 'switch.dart';
library;

import 'package:flutter/cupertino.dart';

import 'color_scheme.dart';
import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'radio_theme.dart';
import 'theme.dart';
import 'theme_data.dart';

// Examples can assume:
// late BuildContext context;
// enum SingingCharacter { lafayette }
// late SingingCharacter? _character;
// late StateSetter setState;

enum _RadioType { material, adaptive }

const double _kOuterRadius = 8.0;
const double _kInnerRadius = 4.5;

/// A Material Design radio button.
///
/// This widget builds a [RawRadio] with a material UI.
///
/// Used to select between a number of mutually exclusive values. When one radio
/// button in a group is selected, the other radio buttons in the group cease to
/// be selected. The values are of type `T`, the type parameter of the [Radio]
/// class. Enums are commonly used for this purpose.
///
/// This widget typically has a [RadioGroup] ancestor, which takes in a
/// [RadioGroup.groupValue], and the [Radio] under it with matching [value]
/// will be selected.
///
/// {@tool dartpad}
/// Here is an example of Radio widgets wrapped in ListTiles, which is similar
/// to what you could get with the RadioListTile widget.
///
/// The currently selected character is passed into `RadioGroup.groupValue`,
/// which is maintained by the example's `State`. In this case, the first [Radio]
/// will start off selected because `_character` is initialized to
/// `SingingCharacter.lafayette`.
///
/// If the second radio button is pressed, the example's state is updated
/// with `setState`, updating `_character` to `SingingCharacter.jefferson`.
/// This causes the buttons to rebuild with the updated `RadioGroup.groupValue`, and
/// therefore the selection of the second button.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// ** See code in examples/api/lib/material/radio/radio.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// Here is an example of how the you can override the default theme of a
/// [Radio] with [WidgetStateProperty].
///
/// In this example:
/// - The first [Radio] uses a custom [fillColor] that changes depending on whether
///   the radio button is selected.
/// - The second [Radio] applies a different [backgroundColor] based on its selection state.
/// - The third [Radio] customizes the [side] property to display a different border color
///   when selected or unselected.
///
/// ** See code in examples/api/lib/material/radio/radio.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [RadioListTile], which combines this widget with a [ListTile] so that
///    you can give the radio button a label.
///  * [Slider], for selecting a value in a range.
///  * [Checkbox] and [Switch], for toggling a particular value on or off.
///  * <https://material.io/design/components/selection-controls.html#radio-buttons>
class Radio<T> extends StatefulWidget {
  /// Creates a Material Design radio button.
  ///
  /// This widget typically has a [RadioGroup] ancestor, which takes in a
  /// [RadioGroup.groupValue], and the [Radio] under it with matching [value]
  /// will be selected.
  ///
  /// The [value] is required.
  const Radio({
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
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
    this.focusNode,
    this.autofocus = false,
    this.enabled,
    this.groupRegistry,
    this.backgroundColor,
    this.side,
    this.innerRadius,
  }) : _radioType = _RadioType.material,
       useCupertinoCheckmarkStyle = false;

  /// Creates an adaptive [Radio] based on whether the target platform is iOS
  /// or macOS, following Material design's
  /// [Cross-platform guidelines](https://material.io/design/platform-guidance/cross-platform-adaptation.html).
  ///
  /// On iOS and macOS, this constructor creates a [CupertinoRadio], which has
  /// matching functionality and presentation as Material checkboxes, and are the
  /// graphics expected on iOS. On other platforms, this creates a Material
  /// design [Radio].
  ///
  /// If a [CupertinoRadio] is created, the following parameters are ignored:
  /// [mouseCursor], [fillColor], [hoverColor], [overlayColor], [splashRadius],
  /// [materialTapTargetSize], [visualDensity].
  ///
  /// [useCupertinoCheckmarkStyle] is used only if a [CupertinoRadio] is created.
  ///
  /// The target platform is based on the current [Theme]: [ThemeData.platform].
  const Radio.adaptive({
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
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
    this.focusNode,
    this.autofocus = false,
    this.useCupertinoCheckmarkStyle = false,
    this.enabled,
    this.groupRegistry,
    this.backgroundColor,
    this.side,
    this.innerRadius,
  }) : _radioType = _RadioType.adaptive;

  /// {@macro flutter.widget.RawRadio.value}
  final T value;

  /// {@template flutter.material.Radio.groupValue}
  /// The currently selected value for a group of radio buttons.
  ///
  /// This radio button is considered selected if its [value] matches the
  /// [groupValue].
  ///
  /// This is deprecated, use [RadioGroup] to manage group value instead.
  /// {@endtemplate}
  @Deprecated(
    'Use a RadioGroup ancestor to manage group value instead. '
    'This feature was deprecated after v3.32.0-0.0.pre.',
  )
  final T? groupValue;

  /// {@template flutter.material.Radio.onChanged}
  /// Called when the user selects this radio button.
  ///
  /// The radio button passes [value] as a parameter to this callback. The radio
  /// button does not actually change state until the parent widget rebuilds the
  /// radio button with the new [groupValue].
  ///
  /// If null, the radio button will be displayed as disabled.
  ///
  /// The provided callback will not be invoked if this radio button is already
  /// selected and [toggleable] is not set to true.
  ///
  /// If the [toggleable] is set to true, tapping a already selected radio will
  /// invoke this callback with `null` as value.
  ///
  /// The callback provided to [onChanged] should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt.
  /// {@endtemplate}
  ///
  /// For example:
  ///
  /// ```dart
  /// Radio<SingingCharacter>(
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
  ///
  /// This is deprecated, use [RadioGroup] to handle value change instead.
  @Deprecated(
    'Use RadioGroup to handle value change instead. '
    'This feature was deprecated after v3.32.0-0.0.pre.',
  )
  final ValueChanged<T?>? onChanged;

  /// {@macro flutter.widget.RawRadio.mouseCursor}
  ///
  /// If null, the value of [RadioThemeData.mouseCursor] is used. If that is
  /// also null, [WidgetStateMouseCursor.adaptiveClickable] is used.
  final MouseCursor? mouseCursor;

  /// {@macro flutter.widget.RawRadio.toggleable}
  ///
  /// {@tool dartpad}
  /// This example shows how to enable deselecting a radio button by setting the
  /// [toggleable] attribute.
  ///
  /// ** See code in examples/api/lib/material/radio/radio.toggleable.0.dart **
  /// {@end-tool}
  final bool toggleable;

  /// The color to use when this radio button is selected.
  ///
  /// Defaults to [ColorScheme.secondary].
  ///
  /// If [fillColor] returns a non-null color in the [WidgetState.selected]
  /// state, it will be used instead of this color.
  final Color? activeColor;

  /// {@template flutter.material.radio.fillColor}
  /// The color that fills the radio button, in all [WidgetState]s.
  ///
  /// Resolves in the following states:
  ///  * [WidgetState.selected].
  ///  * [WidgetState.hovered].
  ///  * [WidgetState.focused].
  ///  * [WidgetState.disabled].
  ///
  /// {@tool snippet}
  /// This example resolves the [fillColor] based on the current [WidgetState]
  /// of the [Radio], providing a different [Color] when it is
  /// [WidgetState.disabled].
  ///
  /// ```dart
  /// Radio<int>(
  ///   value: 1,
  ///   fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
  ///     if (states.contains(WidgetState.disabled)) {
  ///       return Colors.orange.withValues(alpha: .32);
  ///     }
  ///     return Colors.orange;
  ///   })
  /// )
  /// ```
  /// {@end-tool}
  /// {@endtemplate}
  ///
  /// If null, then the value of [activeColor] is used in the selected state. If
  /// that is also null, then the value of [RadioThemeData.fillColor] is used.
  /// If that is also null and [ThemeData.useMaterial3] is false, then
  /// [ThemeData.disabledColor] is used in the disabled state, [ColorScheme.secondary]
  /// is used in the selected state, and [ThemeData.unselectedWidgetColor] is used in the
  /// default state; if [ThemeData.useMaterial3] is true, then [ColorScheme.onSurface]
  /// is used in the disabled state, [ColorScheme.primary] is used in the
  /// selected state and [ColorScheme.onSurfaceVariant] is used in the default state.
  final WidgetStateProperty<Color?>? fillColor;

  /// {@template flutter.material.radio.materialTapTargetSize}
  /// Configures the minimum size of the tap target.
  /// {@endtemplate}
  ///
  /// If null, then the value of [RadioThemeData.materialTapTargetSize] is used.
  /// If that is also null, then the value of [ThemeData.materialTapTargetSize]
  /// is used.
  ///
  /// See also:
  ///
  ///  * [MaterialTapTargetSize], for a description of how this affects tap targets.
  final MaterialTapTargetSize? materialTapTargetSize;

  /// {@template flutter.material.radio.visualDensity}
  /// Defines how compact the radio's layout will be.
  /// {@endtemplate}
  ///
  /// {@macro flutter.material.themedata.visualDensity}
  ///
  /// If null, then the value of [RadioThemeData.visualDensity] is used. If that
  /// is also null, then the value of [ThemeData.visualDensity] is used.
  ///
  /// See also:
  ///
  ///  * [ThemeData.visualDensity], which specifies the [visualDensity] for all
  ///    widgets within a [Theme].
  final VisualDensity? visualDensity;

  /// The color for the radio's [Material] when it has the input focus.
  ///
  /// If [overlayColor] returns a non-null color in the [WidgetState.focused]
  /// state, it will be used instead.
  ///
  /// If null, then the value of [RadioThemeData.overlayColor] is used in the
  /// focused state. If that is also null, then the value of
  /// [ThemeData.focusColor] is used.
  final Color? focusColor;

  /// {@template flutter.material.radio.hoverColor}
  /// The color for the radio's [Material] when a pointer is hovering over it.
  ///
  /// If [overlayColor] returns a non-null color in the [WidgetState.hovered]
  /// state, it will be used instead.
  /// {@endtemplate}
  ///
  /// If null, then the value of [RadioThemeData.overlayColor] is used in the
  /// hovered state. If that is also null, then the value of
  /// [ThemeData.hoverColor] is used.
  final Color? hoverColor;

  /// {@template flutter.material.radio.overlayColor}
  /// The color for the radio's [Material].
  ///
  /// Resolves in the following states:
  ///  * [WidgetState.pressed].
  ///  * [WidgetState.selected].
  ///  * [WidgetState.hovered].
  ///  * [WidgetState.focused].
  /// {@endtemplate}
  ///
  /// If null, then the value of [activeColor] with alpha
  /// [kRadialReactionAlpha], [focusColor] and [hoverColor] is used in the
  /// pressed, focused and hovered state. If that is also null,
  /// the value of [RadioThemeData.overlayColor] is used. If that is also null,
  /// then in Material 2, the value of [ColorScheme.secondary] with alpha
  /// [kRadialReactionAlpha], [ThemeData.focusColor] and [ThemeData.hoverColor]
  /// is used in the pressed, focused and hovered state. In Material3, the default
  /// values are:
  ///   * selected
  ///     * pressed - Theme.colorScheme.onSurface(0.1)
  ///     * hovered - Theme.colorScheme.primary(0.08)
  ///     * focused - Theme.colorScheme.primary(0.1)
  ///   * pressed - Theme.colorScheme.primary(0.1)
  ///   * hovered - Theme.colorScheme.onSurface(0.08)
  ///   * focused - Theme.colorScheme.onSurface(0.1)
  final WidgetStateProperty<Color?>? overlayColor;

  /// {@template flutter.material.radio.splashRadius}
  /// The splash radius of the circular [Material] ink response.
  /// {@endtemplate}
  ///
  /// If null, then the value of [RadioThemeData.splashRadius] is used. If that
  /// is also null, then [kRadialReactionRadius] is used.
  final double? splashRadius;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// Controls whether the checkmark style is used in an iOS-style radio.
  ///
  /// Only usable under the [Radio.adaptive] constructor. If set to true, on
  /// Apple platforms the radio button will appear as an iOS styled checkmark.
  /// Controls the [CupertinoRadio] through [CupertinoRadio.useCheckmarkStyle].
  ///
  /// Defaults to false.
  final bool useCupertinoCheckmarkStyle;

  /// {@macro flutter.widget.RawRadio.groupRegistry}
  ///
  /// Unless provided, the [BuildContext] will be used to look up the ancestor
  /// [RadioGroupRegistry].
  final RadioGroupRegistry<T>? groupRegistry;

  final _RadioType _radioType;

  /// {@template flutter.material.Radio.enabled}
  /// Whether this widget is interactive.
  ///
  /// If not provided, this widget will be interactable if one of the following
  /// is true:
  ///
  /// * A [onChanged] is provided.
  /// * Having a [RadioGroup] with the same type T above this widget.
  /// * A [groupRegistry] is provided.
  ///
  /// If this is set to true, one of the above condition must also be true.
  /// Otherwise, an assertion error is thrown.
  /// {@endtemplate}
  final bool? enabled;

  /// {@template flutter.material.Radio.backgroundColor}
  /// The color of the background of the radio button, in all [WidgetState]s.
  ///
  /// Resolves in the following states:
  ///  * [WidgetState.selected].
  ///  * [WidgetState.hovered].
  ///  * [WidgetState.focused].
  ///  * [WidgetState.disabled].
  /// {@endtemplate}
  ///
  /// If null, then the ambient [RadioThemeData.backgroundColor] is used.
  /// If that is also null the default value is transparent in all states.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// {@template flutter.material.Radio.side}
  /// The side for the circular border of the radio button, in all
  /// [WidgetState]s.
  ///
  /// This property can be a [BorderSide] or a [WidgetStateBorderSide] to leverage
  /// widget state resolution.
  ///
  /// Resolves in the following states:
  ///  * [WidgetState.selected].
  ///  * [WidgetState.hovered].
  ///  * [WidgetState.focused].
  ///  * [WidgetState.disabled].
  /// {@endtemplate}
  ///
  /// If null, then the ambient [RadioThemeData.side] is used. If that is
  /// also null, the default value is a border using the fill color.
  final BorderSide? side;

  /// {@template flutter.material.Radio.innerRadius}
  /// The radius of the inner circle of the radio button, in all [WidgetState]s.
  ///
  /// Resolves in the following states:
  ///  * [WidgetState.hovered].
  ///  * [WidgetState.focused].
  ///  * [WidgetState.disabled].
  /// {@endtemplate}
  ///
  /// If null, then the ambient [RadioThemeData.innerRadius] is used.
  /// If that is also null, the default value is `4.5` in all states.
  final WidgetStateProperty<double?>? innerRadius;

  @override
  State<Radio<T>> createState() => _RadioState<T>();
}

class _RadioState<T> extends State<Radio<T>> {
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());

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
      'Radio is enabled but has no Radio.onChange or registry above',
    );
    assert(debugCheckHasMaterial(context));
    switch (widget._radioType) {
      case _RadioType.material:
        break;

      case _RadioType.adaptive:
        final ThemeData theme = Theme.of(context);
        switch (theme.platform) {
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.linux:
          case TargetPlatform.windows:
            break;
          case TargetPlatform.iOS:
          case TargetPlatform.macOS:
            return CupertinoRadio<T>(
              value: widget.value,
              groupValue: widget.groupValue,
              onChanged: widget.onChanged,
              mouseCursor: widget.mouseCursor,
              toggleable: widget.toggleable,
              activeColor: widget.activeColor,
              focusColor: widget.focusColor,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              useCheckmarkStyle: widget.useCupertinoCheckmarkStyle,
              groupRegistry: _effectiveRegistry,
              enabled: _enabled,
            );
        }
    }

    final RadioThemeData radioTheme = RadioTheme.of(context);
    final WidgetStateProperty<MouseCursor> effectiveMouseCursor =
        WidgetStateProperty.resolveWith<MouseCursor>((Set<WidgetState> states) {
          return WidgetStateProperty.resolveAs<MouseCursor?>(widget.mouseCursor, states) ??
              radioTheme.mouseCursor?.resolve(states) ??
              WidgetStateProperty.resolveAs<MouseCursor>(
                WidgetStateMouseCursor.adaptiveClickable,
                states,
              );
        });
    return RawRadio<T>(
      value: widget.value,
      mouseCursor: effectiveMouseCursor,
      toggleable: widget.toggleable,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      groupRegistry: _effectiveRegistry,
      enabled: _enabled,
      builder: (BuildContext context, ToggleableStateMixin state) {
        return _RadioPaint(
          toggleableState: state,
          activeColor: widget.activeColor,
          fillColor: widget.fillColor,
          hoverColor: widget.hoverColor,
          focusColor: widget.focusColor,
          overlayColor: widget.overlayColor,
          splashRadius: widget.splashRadius,
          visualDensity: widget.visualDensity,
          materialTapTargetSize: widget.materialTapTargetSize,
          backgroundColor: widget.backgroundColor,
          side: widget.side,
          innerRadius: widget.innerRadius,
        );
      },
    );
  }
}

/// A registry for deprecated API.
// TODO(chunhtai): Remove this once deprecated API is removed.
class _RadioRegistry<T> extends RadioGroupRegistry<T> {
  _RadioRegistry(this.state);
  final _RadioState<T> state;
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
    required this.toggleableState,
    required this.activeColor,
    required this.fillColor,
    required this.hoverColor,
    required this.focusColor,
    required this.overlayColor,
    required this.splashRadius,
    required this.visualDensity,
    required this.materialTapTargetSize,
    required this.backgroundColor,
    required this.side,
    required this.innerRadius,
  });

  final ToggleableStateMixin toggleableState;
  final Color? activeColor;
  final WidgetStateProperty<Color?>? fillColor;
  final Color? hoverColor;
  final Color? focusColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final double? splashRadius;
  final VisualDensity? visualDensity;
  final MaterialTapTargetSize? materialTapTargetSize;
  final WidgetStateProperty<Color?>? backgroundColor;
  final BorderSide? side;
  final WidgetStateProperty<double?>? innerRadius;

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

  WidgetStateProperty<Color?> get _widgetFillColor {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return null;
      }
      if (states.contains(WidgetState.selected)) {
        return widget.activeColor;
      }
      return null;
    });
  }

  BorderSide? _resolveSide(BorderSide? side, Set<WidgetState> states) {
    if (side is WidgetStateProperty) {
      return WidgetStateProperty.resolveAs<BorderSide?>(side, states);
    }
    if (!states.contains(WidgetState.selected)) {
      return side;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final RadioThemeData radioTheme = RadioTheme.of(context);
    final RadioThemeData defaults = Theme.of(context).useMaterial3
        ? _RadioDefaultsM3(context)
        : _RadioDefaultsM2(context);

    // Colors need to be resolved in selected and non selected states separately
    // so that they can be lerped between.
    final Set<WidgetState> activeStates = widget.toggleableState.states..add(WidgetState.selected);
    final Set<WidgetState> inactiveStates = widget.toggleableState.states
      ..remove(WidgetState.selected);
    final Color? activeColor =
        widget.fillColor?.resolve(activeStates) ??
        _widgetFillColor.resolve(activeStates) ??
        radioTheme.fillColor?.resolve(activeStates);
    final Color effectiveActiveColor = activeColor ?? defaults.fillColor!.resolve(activeStates)!;
    final Color? inactiveColor =
        widget.fillColor?.resolve(inactiveStates) ??
        _widgetFillColor.resolve(inactiveStates) ??
        radioTheme.fillColor?.resolve(inactiveStates);
    final Color effectiveInactiveColor =
        inactiveColor ?? defaults.fillColor!.resolve(inactiveStates)!;
    final Color activeBackgroundColor =
        widget.backgroundColor?.resolve(activeStates) ??
        radioTheme.backgroundColor?.resolve(activeStates) ??
        defaults.backgroundColor!.resolve(activeStates)!;
    final Color inactiveBackgroundColor =
        widget.backgroundColor?.resolve(inactiveStates) ??
        radioTheme.backgroundColor?.resolve(inactiveStates) ??
        defaults.backgroundColor!.resolve(inactiveStates)!;

    final Set<WidgetState> focusedStates = widget.toggleableState.states..add(WidgetState.focused);
    Color effectiveFocusOverlayColor =
        widget.overlayColor?.resolve(focusedStates) ??
        widget.focusColor ??
        radioTheme.overlayColor?.resolve(focusedStates) ??
        defaults.overlayColor!.resolve(focusedStates)!;

    final Set<WidgetState> hoveredStates = widget.toggleableState.states..add(WidgetState.hovered);
    Color effectiveHoverOverlayColor =
        widget.overlayColor?.resolve(hoveredStates) ??
        widget.hoverColor ??
        radioTheme.overlayColor?.resolve(hoveredStates) ??
        defaults.overlayColor!.resolve(hoveredStates)!;

    final activePressedStates = activeStates..add(WidgetState.pressed);
    final Color effectiveActivePressedOverlayColor =
        widget.overlayColor?.resolve(activePressedStates) ??
        radioTheme.overlayColor?.resolve(activePressedStates) ??
        activeColor?.withAlpha(kRadialReactionAlpha) ??
        defaults.overlayColor!.resolve(activePressedStates)!;

    final inactivePressedStates = inactiveStates..add(WidgetState.pressed);
    final Color effectiveInactivePressedOverlayColor =
        widget.overlayColor?.resolve(inactivePressedStates) ??
        radioTheme.overlayColor?.resolve(inactivePressedStates) ??
        inactiveColor?.withAlpha(kRadialReactionAlpha) ??
        defaults.overlayColor!.resolve(inactivePressedStates)!;

    if (widget.toggleableState.downPosition != null) {
      effectiveHoverOverlayColor = widget.toggleableState.states.contains(WidgetState.selected)
          ? effectiveActivePressedOverlayColor
          : effectiveInactivePressedOverlayColor;
      effectiveFocusOverlayColor = widget.toggleableState.states.contains(WidgetState.selected)
          ? effectiveActivePressedOverlayColor
          : effectiveInactivePressedOverlayColor;
    }

    final MaterialTapTargetSize effectiveMaterialTapTargetSize =
        widget.materialTapTargetSize ??
        radioTheme.materialTapTargetSize ??
        defaults.materialTapTargetSize!;
    final VisualDensity effectiveVisualDensity =
        widget.visualDensity ?? radioTheme.visualDensity ?? defaults.visualDensity!;
    Size size = switch (effectiveMaterialTapTargetSize) {
      MaterialTapTargetSize.padded => const Size(
        kMinInteractiveDimension,
        kMinInteractiveDimension,
      ),
      MaterialTapTargetSize.shrinkWrap => const Size(
        kMinInteractiveDimension - 8.0,
        kMinInteractiveDimension - 8.0,
      ),
    };
    size += effectiveVisualDensity.baseSizeAdjustment;
    final BorderSide activeSide =
        _resolveSide(widget.side, activeStates) ??
        _resolveSide(radioTheme.side, activeStates) ??
        BorderSide(
          color: effectiveActiveColor,
          width: 2.0,
          strokeAlign: BorderSide.strokeAlignCenter,
        );
    final BorderSide inactiveSide =
        _resolveSide(widget.side, inactiveStates) ??
        _resolveSide(radioTheme.side, inactiveStates) ??
        BorderSide(
          color: effectiveInactiveColor,
          width: 2.0,
          strokeAlign: BorderSide.strokeAlignCenter,
        );

    final double innerRadius =
        widget.innerRadius?.resolve(activeStates) ??
        radioTheme.innerRadius?.resolve(activeStates) ??
        _kInnerRadius;

    return CustomPaint(
      size: size,
      painter: _painter
        ..position = widget.toggleableState.position
        ..reaction = widget.toggleableState.reaction
        ..reactionFocusFade = widget.toggleableState.reactionFocusFade
        ..reactionHoverFade = widget.toggleableState.reactionHoverFade
        ..inactiveReactionColor = effectiveInactivePressedOverlayColor
        ..reactionColor = effectiveActivePressedOverlayColor
        ..hoverColor = effectiveHoverOverlayColor
        ..focusColor = effectiveFocusOverlayColor
        ..splashRadius = widget.splashRadius ?? radioTheme.splashRadius ?? kRadialReactionRadius
        ..downPosition = widget.toggleableState.downPosition
        ..isFocused = widget.toggleableState.states.contains(WidgetState.focused)
        ..isHovered = widget.toggleableState.states.contains(WidgetState.hovered)
        ..activeColor = effectiveActiveColor
        ..inactiveColor = effectiveInactiveColor
        ..activeBackgroundColor = activeBackgroundColor
        ..inactiveBackgroundColor = inactiveBackgroundColor
        ..activeSide = activeSide
        ..inactiveSide = inactiveSide
        ..innerRadius = innerRadius,
    );
  }
}

class _RadioPainter extends ToggleablePainter {
  Color get inactiveBackgroundColor => _inactiveBackgroundColor!;
  Color? _inactiveBackgroundColor;
  set inactiveBackgroundColor(Color? value) {
    if (_inactiveBackgroundColor == value) {
      return;
    }
    _inactiveBackgroundColor = value;
    notifyListeners();
  }

  Color get activeBackgroundColor => _activeBackgroundColor!;
  Color? _activeBackgroundColor;
  set activeBackgroundColor(Color? value) {
    if (_activeBackgroundColor == value) {
      return;
    }
    _activeBackgroundColor = value;
    notifyListeners();
  }

  BorderSide get inactiveSide => _inactiveSide!;
  BorderSide? _inactiveSide;
  set inactiveSide(BorderSide? value) {
    if (_inactiveSide == value) {
      return;
    }
    _inactiveSide = value;
    notifyListeners();
  }

  BorderSide get activeSide => _activeSide!;
  BorderSide? _activeSide;
  set activeSide(BorderSide? value) {
    if (_activeSide == value) {
      return;
    }
    _activeSide = value;
    notifyListeners();
  }

  double get innerRadius => _innerRadius!;
  double? _innerRadius;
  set innerRadius(double? value) {
    if (_innerRadius == value) {
      return;
    }
    _innerRadius = value;
    notifyListeners();
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintRadialReaction(canvas: canvas, origin: size.center(Offset.zero));

    final Rect rect = Offset.zero & size;
    final Offset center = rect.center;
    final Rect effectiveRect = (center & const Size.square(_kOuterRadius * 2)).translate(
      -_kOuterRadius,
      -_kOuterRadius,
    );

    // Background
    final backgroundPaint = Paint()
      ..color = Color.lerp(inactiveBackgroundColor, activeBackgroundColor, position.value)!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, _kOuterRadius, backgroundPaint);

    // Outer circle
    final BorderSide side = BorderSide.lerp(inactiveSide, activeSide, position.value);
    CircleBorder(side: side).paint(canvas, effectiveRect);

    // Inner circle
    if (!position.isDismissed) {
      final innerCirclePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Color.lerp(inactiveColor, activeColor, position.value)!;
      canvas.drawCircle(center, innerRadius * position.value, innerCirclePaint);
    }
  }
}

// Hand coded defaults based on Material Design 2.
class _RadioDefaultsM2 extends RadioThemeData {
  _RadioDefaultsM2(this.context);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;

  @override
  WidgetStateProperty<Color> get fillColor {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return _theme.disabledColor;
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.secondary;
      }
      return _theme.unselectedWidgetColor;
    });
  }

  @override
  WidgetStateProperty<Color> get overlayColor {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return fillColor.resolve(states).withAlpha(kRadialReactionAlpha);
      }
      if (states.contains(WidgetState.hovered)) {
        return _theme.hoverColor;
      }
      if (states.contains(WidgetState.focused)) {
        return _theme.focusColor;
      }
      return Colors.transparent;
    });
  }

  @override
  MaterialTapTargetSize get materialTapTargetSize => _theme.materialTapTargetSize;

  @override
  VisualDensity get visualDensity => _theme.visualDensity;

  @override
  WidgetStateProperty<Color> get backgroundColor =>
      WidgetStateProperty.all<Color>(Colors.transparent);
}

// BEGIN GENERATED TOKEN PROPERTIES - Radio<T>

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// dart format off
class _RadioDefaultsM3 extends RadioThemeData {
  _RadioDefaultsM3(this.context);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;

  @override
  WidgetStateProperty<Color> get fillColor {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.disabled)) {
          return _colors.onSurface.withOpacity(0.38);
        }
        if (states.contains(WidgetState.pressed)) {
          return _colors.primary;
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.primary;
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.primary;
        }
        return _colors.primary;
      }
      if (states.contains(WidgetState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      if (states.contains(WidgetState.pressed)) {
        return _colors.onSurface;
      }
      if (states.contains(WidgetState.hovered)) {
        return _colors.onSurface;
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.onSurface;
      }
      return _colors.onSurfaceVariant;
    });
  }

  @override
  WidgetStateProperty<Color> get overlayColor {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.onSurface.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.primary.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.primary.withOpacity(0.1);
        }
        return Colors.transparent;
      }
      if (states.contains(WidgetState.pressed)) {
        return _colors.primary.withOpacity(0.1);
      }
      if (states.contains(WidgetState.hovered)) {
        return _colors.onSurface.withOpacity(0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.onSurface.withOpacity(0.1);
      }
      return Colors.transparent;
    });
  }

  @override
  MaterialTapTargetSize get materialTapTargetSize => _theme.materialTapTargetSize;

  @override
  VisualDensity get visualDensity => _theme.visualDensity;

  @override
  WidgetStateProperty<Color> get backgroundColor =>
      WidgetStateProperty.all<Color>(Colors.transparent);
}
// dart format on

// END GENERATED TOKEN PROPERTIES - Radio<T>
