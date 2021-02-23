// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'material_state.dart';
import 'shadows.dart';
import 'theme.dart';
import 'theme_data.dart';
import 'toggleable.dart';

const double _kTrackHeight = 14.0;
const double _kTrackWidth = 33.0;
const double _kTrackRadius = _kTrackHeight / 2.0;
const double _kThumbRadius = 10.0;
const double _kSwitchMinSize = kMinInteractiveDimension - 8.0;
const double _kSwitchWidth = _kTrackWidth - 2 * _kTrackRadius + _kSwitchMinSize;
const double _kSwitchHeight = _kSwitchMinSize + 8.0;
const double _kSwitchHeightCollapsed = _kSwitchMinSize;

enum _SwitchType { material, adaptive }

/// A material design switch.
///
/// Used to toggle the on/off state of a single setting.
///
/// The switch itself does not maintain any state. Instead, when the state of
/// the switch changes, the widget calls the [onChanged] callback. Most widgets
/// that use a switch will listen for the [onChanged] callback and rebuild the
/// switch with a new [value] to update the visual appearance of the switch.
///
/// If the [onChanged] callback is null, then the switch will be disabled (it
/// will not respond to input). A disabled switch's thumb and track are rendered
/// in shades of grey by default. The default appearance of a disabled switch
/// can be overridden with [inactiveThumbColor] and [inactiveTrackColor].
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [SwitchListTile], which combines this widget with a [ListTile] so that
///    you can give the switch a label.
///  * [Checkbox], another widget with similar semantics.
///  * [Radio], for selecting among a set of explicit values.
///  * [Slider], for selecting a value in a range.
///  * <https://material.io/design/components/selection-controls.html#switches>
class Switch extends StatelessWidget {
  /// Creates a material design switch.
  ///
  /// The switch itself does not maintain any state. Instead, when the state of
  /// the switch changes, the widget calls the [onChanged] callback. Most widgets
  /// that use a switch will listen for the [onChanged] callback and rebuild the
  /// switch with a new [value] to update the visual appearance of the switch.
  ///
  /// The following arguments are required:
  ///
  /// * [value] determines whether this switch is on or off.
  /// * [onChanged] is called when the user toggles the switch on or off.
  const Switch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.activeThumbImage,
    this.onActiveThumbImageError,
    this.inactiveThumbImage,
    this.onInactiveThumbImageError,
    this.thumbColor,
    this.trackColor,
    this.materialTapTargetSize,
    this.dragStartBehavior = DragStartBehavior.start,
    this.mouseCursor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.focusNode,
    this.autofocus = false,
  })  : _switchType = _SwitchType.material,
        assert(dragStartBehavior != null),
        assert(activeThumbImage != null || onActiveThumbImageError == null),
        assert(inactiveThumbImage != null || onInactiveThumbImageError == null),
        super(key: key);

  /// Creates an adaptive [Switch] based on whether the target platform is iOS
  /// or macOS, following Material design's
  /// [Cross-platform guidelines](https://material.io/design/platform-guidance/cross-platform-adaptation.html).
  ///
  /// On iOS and macOS, this constructor creates a [CupertinoSwitch], which has
  /// matching functionality and presentation as Material switches, and are the
  /// graphics expected on iOS. On other platforms, this creates a Material
  /// design [Switch].
  ///
  /// If a [CupertinoSwitch] is created, the following parameters are ignored:
  /// [activeTrackColor], [inactiveThumbColor], [inactiveTrackColor],
  /// [activeThumbImage], [onActiveThumbImageError], [inactiveThumbImage],
  /// [onInactiveThumbImageError], [materialTapTargetSize].
  ///
  /// The target platform is based on the current [Theme]: [ThemeData.platform].
  const Switch.adaptive({
    Key? key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.activeThumbImage,
    this.onActiveThumbImageError,
    this.inactiveThumbImage,
    this.onInactiveThumbImageError,
    this.materialTapTargetSize,
    this.thumbColor,
    this.trackColor,
    this.dragStartBehavior = DragStartBehavior.start,
    this.mouseCursor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.focusNode,
    this.autofocus = false,
  })  : assert(autofocus != null),
        assert(activeThumbImage != null || onActiveThumbImageError == null),
        assert(inactiveThumbImage != null || onInactiveThumbImageError == null),
        _switchType = _SwitchType.adaptive,
        super(key: key);

  /// Whether this switch is on or off.
  ///
  /// This property must not be null.
  final bool value;

  /// Called when the user toggles the switch on or off.
  ///
  /// The switch passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the switch with the new
  /// value.
  ///
  /// If null, the switch will be displayed as disabled.
  ///
  /// The callback provided to [onChanged] should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt; for example:
  ///
  /// ```dart
  /// Switch(
  ///   value: _giveVerse,
  ///   onChanged: (bool newValue) {
  ///     setState(() {
  ///       _giveVerse = newValue;
  ///     });
  ///   },
  /// )
  /// ```
  final ValueChanged<bool>? onChanged;

  /// The color to use when this switch is on.
  ///
  /// Defaults to [ThemeData.toggleableActiveColor].
  ///
  /// If [thumbColor] returns a non-null color in the [MaterialState.selected]
  /// state, it will be used instead of this color.
  final Color? activeColor;

  /// The color to use on the track when this switch is on.
  ///
  /// Defaults to [ThemeData.toggleableActiveColor] with the opacity set at 50%.
  ///
  /// Ignored if this switch is created with [Switch.adaptive].
  ///
  /// If [trackColor] returns a non-null color in the [MaterialState.selected]
  /// state, it will be used instead of this color.
  final Color? activeTrackColor;

  /// The color to use on the thumb when this switch is off.
  ///
  /// Defaults to the colors described in the Material design specification.
  ///
  /// Ignored if this switch is created with [Switch.adaptive].
  ///
  /// If [thumbColor] returns a non-null color in the default state, it will be
  /// used instead of this color.
  final Color? inactiveThumbColor;

  /// The color to use on the track when this switch is off.
  ///
  /// Defaults to the colors described in the Material design specification.
  ///
  /// Ignored if this switch is created with [Switch.adaptive].
  ///
  /// If [trackColor] returns a non-null color in the default state, it will be
  /// used instead of this color.
  final Color? inactiveTrackColor;

  /// An image to use on the thumb of this switch when the switch is on.
  ///
  /// Ignored if this switch is created with [Switch.adaptive].
  final ImageProvider? activeThumbImage;

  /// An optional error callback for errors emitted when loading
  /// [activeThumbImage].
  final ImageErrorListener? onActiveThumbImageError;

  /// An image to use on the thumb of this switch when the switch is off.
  ///
  /// Ignored if this switch is created with [Switch.adaptive].
  final ImageProvider? inactiveThumbImage;

  /// An optional error callback for errors emitted when loading
  /// [inactiveThumbImage].
  final ImageErrorListener? onInactiveThumbImageError;

  /// {@template flutter.material.switch.thumbColor}
  /// The color of this [Switch]'s thumb.
  ///
  /// Resolved in the following states:
  ///  * [MaterialState.selected].
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  ///  * [MaterialState.disabled].
  /// {@endtemplate}
  ///
  /// If null, then the value of [activeColor] is used in the selected
  /// state and [inactiveThumbColor] in the default state. If that is also null,
  /// then the value of [SwitchThemeData.thumbColor] is used. If that is also
  /// null, then the following colors are used:
  ///
  /// | State    | Light theme                       | Dark theme                        |
  /// |----------|-----------------------------------|-----------------------------------|
  /// | Default  | `Colors.grey.shade50`             | `Colors.grey.shade400`            |
  /// | Selected | [ThemeData.toggleableActiveColor] | [ThemeData.toggleableActiveColor] |
  /// | Disabled | `Colors.grey.shade400`            | `Colors.grey.shade800`            |
  final MaterialStateProperty<Color?>? thumbColor;

  /// {@template flutter.material.switch.trackColor}
  /// The color of this [Switch]'s track.
  ///
  /// Resolved in the following states:
  ///  * [MaterialState.selected].
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  ///  * [MaterialState.disabled].
  /// {@endtemplate}
  ///
  /// If null, then the value of [activeTrackColor] is used in the selected
  /// state and [inactiveTrackColor] in the default state. If that is also null,
  /// then the value of [SwitchThemeData.trackColor] is used. If that is also
  /// null, then the following colors are used:
  ///
  /// | State    | Light theme                     | Dark theme                      |
  /// |----------|---------------------------------|---------------------------------|
  /// | Default  | `Colors.grey.shade50`           | `Colors.grey.shade400`          |
  /// | Selected | [activeColor] with alpha `0x80` | [activeColor] with alpha `0x80` |
  /// | Disabled | `Color(0x52000000)`             | `Colors.white30`                |
  final MaterialStateProperty<Color?>? trackColor;

  /// {@template flutter.material.switch.materialTapTargetSize}
  /// Configures the minimum size of the tap target.
  /// {@endtemplate}
  ///
  /// If null, then the value of [SwitchThemeData.materialTapTargetSize] is
  /// used. If that is also null, then the value of
  /// [ThemeData.materialTapTargetSize] is used.
  ///
  /// See also:
  ///
  ///  * [MaterialTapTargetSize], for a description of how this affects tap targets.
  final MaterialTapTargetSize? materialTapTargetSize;

  final _SwitchType _switchType;

  /// {@macro flutter.cupertino.CupertinoSwitch.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@template flutter.material.switch.mouseCursor}
  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// If [mouseCursor] is a [MaterialStateProperty<MouseCursor>],
  /// [MaterialStateProperty.resolve] is used for the following [MaterialState]s:
  ///
  ///  * [MaterialState.selected].
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  ///  * [MaterialState.disabled].
  /// {@endtemplate}
  ///
  /// If null, then the value of [SwitchThemeData.mouseCursor] is used. If that
  /// is also null, then [MaterialStateMouseCursor.clickable] is used.
  ///
  /// See also:
  ///
  ///  * [MaterialStateMouseCursor], a [MouseCursor] that implements
  ///    `MaterialStateProperty` which is used in APIs that need to accept
  ///    either a [MouseCursor] or a [MaterialStateProperty<MouseCursor>].
  final MouseCursor? mouseCursor;

  /// The color for the button's [Material] when it has the input focus.
  ///
  /// If [overlayColor] returns a non-null color in the [MaterialState.focused]
  /// state, it will be used instead.
  ///
  /// If null, then the value of [SwitchThemeData.overlayColor] is used in the
  /// focused state. If that is also null, then the value of
  /// [ThemeData.focusColor] is used.
  final Color? focusColor;

  /// The color for the button's [Material] when a pointer is hovering over it.
  ///
  /// If [overlayColor] returns a non-null color in the [MaterialState.hovered]
  /// state, it will be used instead.
  ///
  /// If null, then the value of [SwitchThemeData.overlayColor] is used in the
  /// hovered state. If that is also null, then the value of
  /// [ThemeData.hoverColor] is used.
  final Color? hoverColor;

  /// {@template flutter.material.switch.overlayColor}
  /// The color for the switch's [Material].
  ///
  /// Resolves in the following states:
  ///  * [MaterialState.pressed].
  ///  * [MaterialState.selected].
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  /// {@endtemplate}
  ///
  /// If null, then the value of [activeColor] with alpha
  /// [kRadialReactionAlpha], [focusColor] and [hoverColor] is used in the
  /// pressed, focused and hovered state. If that is also null,
  /// the value of [SwitchThemeData.overlayColor] is used. If that is
  /// also null, then the value of [ThemeData.toggleableActiveColor] with alpha
  /// [kRadialReactionAlpha], [ThemeData.focusColor] and [ThemeData.hoverColor]
  /// is used in the pressed, focused and hovered state.
  final MaterialStateProperty<Color?>? overlayColor;

  /// {@template flutter.material.switch.splashRadius}
  /// The splash radius of the circular [Material] ink response.
  /// {@endtemplate}
  ///
  /// If null, then the value of [SwitchThemeData.splashRadius] is used. If that
  /// is also null, then [kRadialReactionRadius] is used.
  final double? splashRadius;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  Size _getSwitchSize(ThemeData theme) {
    final MaterialTapTargetSize effectiveMaterialTapTargetSize = materialTapTargetSize
        ?? theme.switchTheme.materialTapTargetSize
        ?? theme.materialTapTargetSize;
    switch (effectiveMaterialTapTargetSize) {
      case MaterialTapTargetSize.padded:
        return const Size(_kSwitchWidth, _kSwitchHeight);
      case MaterialTapTargetSize.shrinkWrap:
        return const Size(_kSwitchWidth, _kSwitchHeightCollapsed);
    }
  }

  Widget _buildCupertinoSwitch(BuildContext context) {
    final Size size = _getSwitchSize(Theme.of(context));
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      child: Container(
        width: size.width, // Same size as the Material switch.
        height: size.height,
        alignment: Alignment.center,
        child: CupertinoSwitch(
            dragStartBehavior: dragStartBehavior,
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            trackColor: inactiveTrackColor
        ),
      ),
    );
  }

  Widget _buildMaterialSwitch(BuildContext context) {
    return _MaterialSwitch();
  }

  @override
  Widget build(BuildContext context) {
    switch (_switchType) {
      case _SwitchType.material:
        return _buildMaterialSwitch(context);

      case _SwitchType.adaptive: {
        final ThemeData theme = Theme.of(context);
        assert(theme.platform != null);
        switch (theme.platform) {
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.linux:
          case TargetPlatform.windows:
            return _buildMaterialSwitch(context);
          case TargetPlatform.iOS:
          case TargetPlatform.macOS:
            return _buildCupertinoSwitch(context);
        }
      }
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('value', value: value, ifTrue: 'on', ifFalse: 'off', showName: true));
    properties.add(ObjectFlagProperty<ValueChanged<bool>>('onChanged', onChanged, ifNull: 'disabled'));
  }
}

class _MaterialSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? activeTrackColor;
  final Color? inactiveThumbColor;
  final Color? inactiveTrackColor;
  final ImageProvider? activeThumbImage;
  final ImageErrorListener? onActiveThumbImageError;
  final ImageProvider? inactiveThumbImage;
  final ImageErrorListener? onInactiveThumbImageError;
  final MaterialStateProperty<Color?>? thumbColor;
  final MaterialStateProperty<Color?>? trackColor;
  final MaterialTapTargetSize? materialTapTargetSize;
  final DragStartBehavior dragStartBehavior;
  final MouseCursor? mouseCursor;
  final Color? focusColor;
  final Color? hoverColor;
  final MaterialStateProperty<Color?>? overlayColor;
  final double? splashRadius;
  final FocusNode? focusNode;
  final bool autofocus;
  final Size size;

  @override
  State<StatefulWidget> createState() => _MaterialSwitchState();

}

class _MaterialSwitchState extends State<_MaterialSwitch> with TickerProviderStateMixin {
  bool get isInteractive => widget.onChanged != null;

  late AnimationController reactionController;
  late AnimationController positionController;
  late CurvedAnimation position;

  MaterialStateProperty<Color?> get _widgetThumbColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return widget.inactiveThumbColor;
      }
      if (states.contains(MaterialState.selected)) {
        return widget.activeColor;
      }
      return widget.inactiveThumbColor;
    });
  }

  MaterialStateProperty<Color> get _defaultThumbColor {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return isDark ? Colors.grey.shade800 : Colors.grey.shade400;
      }
      if (states.contains(MaterialState.selected)) {
        return theme.toggleableActiveColor;
      }
      return isDark ? Colors.grey.shade400 : Colors.grey.shade50;
    });
  }

  MaterialStateProperty<Color?> get _widgetTrackColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return widget.inactiveTrackColor;
      }
      if (states.contains(MaterialState.selected)) {
        return widget.activeTrackColor;
      }
      return widget.inactiveTrackColor;
    });
  }

  MaterialStateProperty<Color> get _defaultTrackColor {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    const Color black32 = Color(0x52000000); // Black with 32% opacity

    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return isDark ? Colors.white10 : Colors.black12;
      }
      if (states.contains(MaterialState.selected)) {
        final Set<MaterialState> activeState = states..add(MaterialState.selected);
        final Color activeColor = _widgetThumbColor.resolve(activeState) ?? _defaultThumbColor.resolve(activeState);
        return activeColor.withAlpha(0x80);
      }
      return isDark ? Colors.white30 : black32;
    });
  }

  double get _trackInnerLength => widget.size.width - _kSwitchMinSize;

  void _handleDragStart(DragStartDetails details) {
    if (isInteractive)
      reactionController.forward();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (isInteractive) {
      position
        ..curve = Curves.linear
        ..reverseCurve = null;
      final double delta = details.primaryDelta! / _trackInnerLength;
      switch (Directionality.of(context)) {
        case TextDirection.rtl:
          positionController.value -= delta;
          break;
        case TextDirection.ltr:
          positionController.value += delta;
          break;
      }
    }
  }

  bool _needsPositionAnimation = false;

  void _handleDragEnd(DragEndDetails details) {
    if (position.value >= 0.5 != widget.value)
      widget.onChanged!(!widget.value);
    reactionController.reverse();
    setState(() {
      _needsPositionAnimation = true;
    });
  }

  void _handleChanged(bool? value) {
    assert(value != null);
    assert(widget.onChanged != null);
    widget.onChanged!(value!);
  }

  void _animateToValueAndResetCurve() {
    final TickerFuture future = widget.value ? positionController.forward() : positionController.reverse();
    future.whenCompleteOrCancel(() {
      position
        ..curve = Curves.easeIn
        ..reverseCurve = Curves.easeOut;
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));

    if (_needsPositionAnimation) {
      _needsPositionAnimation = false;
      _animateToValueAndResetCurve();
    }

    final ThemeData theme = Theme.of(context);

    final MaterialStateProperty<MouseCursor> effectiveMouseCursor = MaterialStateProperty.resolveWith<MouseCursor>((Set<MaterialState> states) {
      return MaterialStateProperty.resolveAs<MouseCursor?>(widget.mouseCursor, states)
        ?? theme.switchTheme.mouseCursor?.resolve(states)
        ?? MaterialStateProperty.resolveAs<MouseCursor>(MaterialStateMouseCursor.clickable, states);
    });

    return Semantics(
      toggled: widget.value,
      child: GestureDetector(
        onHorizontalDragStart: _handleDragStart,
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        child: Toggleable(
          size: widget.size,
          value: widget.value,
          tristate: false,
          onChanged: widget.onChanged != null ? _handleChanged : null,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          mouseCursor: effectiveMouseCursor,
          positionController: positionController,
          reactionController: reactionController,
          position: position,
          painterBuilder: (BuildContext context, ToggleableDetails data) {
            // Colors need to be resolved in selected and non selected states separately
            // so that they can be lerped between.
            final Set<MaterialState> activeStates = data.states..add(MaterialState.selected);
            final Set<MaterialState> inactiveStates = data.states..remove(MaterialState.selected);
            final Color effectiveActiveThumbColor = widget.thumbColor?.resolve(activeStates)
                ?? _widgetThumbColor.resolve(activeStates)
                ?? theme.switchTheme.thumbColor?.resolve(activeStates)
                ?? _defaultThumbColor.resolve(activeStates);
            final Color effectiveInactiveThumbColor = widget.thumbColor?.resolve(inactiveStates)
                ?? _widgetThumbColor.resolve(inactiveStates)
                ?? theme.switchTheme.thumbColor?.resolve(inactiveStates)
                ?? _defaultThumbColor.resolve(inactiveStates);
            final Color effectiveActiveTrackColor = widget.trackColor?.resolve(activeStates)
                ?? _widgetTrackColor.resolve(activeStates)
                ?? theme.switchTheme.trackColor?.resolve(activeStates)
                ?? _defaultTrackColor.resolve(activeStates);
            final Color effectiveInactiveTrackColor = widget.trackColor?.resolve(inactiveStates)
                ?? _widgetTrackColor.resolve(inactiveStates)
                ?? theme.switchTheme.trackColor?.resolve(inactiveStates)
                ?? _defaultTrackColor.resolve(inactiveStates);


            final Set<MaterialState> focusedStates = data.states..add(MaterialState.focused);
            final Color effectiveFocusOverlayColor = widget.overlayColor?.resolve(focusedStates)
                ?? widget.focusColor
                ?? theme.switchTheme.overlayColor?.resolve(focusedStates)
                ?? theme.focusColor;

            final Set<MaterialState> hoveredStates = data.states..add(MaterialState.hovered);
            final Color effectiveHoverOverlayColor = widget.overlayColor?.resolve(hoveredStates)
                ?? widget.hoverColor
                ?? theme.switchTheme.overlayColor?.resolve(hoveredStates)
                ?? theme.hoverColor;

            final Set<MaterialState> activePressedStates = activeStates..add(MaterialState.pressed);
            final Color effectiveActivePressedOverlayColor = widget.overlayColor?.resolve(activePressedStates)
                ?? theme.switchTheme.overlayColor?.resolve(activePressedStates)
                ?? effectiveActiveThumbColor.withAlpha(kRadialReactionAlpha);

            final Set<MaterialState> inactivePressedStates = inactiveStates..add(MaterialState.pressed);
            final Color effectiveInactivePressedOverlayColor = widget.overlayColor?.resolve(inactivePressedStates)
                ?? theme.switchTheme.overlayColor?.resolve(inactivePressedStates)
                ?? effectiveActiveThumbColor.withAlpha(kRadialReactionAlpha);

            return _SwitchPainter(
              // data: data,
              // activeColor: effectiveActiveColor,
              // inactiveColor: effectiveInactiveColor,
              // focusColor: effectiveFocusOverlayColor,
              // hoverColor: effectiveHoverOverlayColor,
              // reactionColor: effectiveActivePressedOverlayColor,
              // inactiveReactionColor: effectiveInactivePressedOverlayColor,
              // splashRadius: splashRadius ?? themeData.radioTheme.splashRadius ?? kRadialReactionRadius,
            );
          },
        ),
      ),
    );
  }
}

class _SwitchPainter extends ToggleablePainter {
  _RenderSwitch({
    required ToggleableDetails data,
    required Color activeColor,
    required Color inactiveColor,
    required Color hoverColor,
    required Color focusColor,
    required Color reactionColor,
    required Color inactiveReactionColor,
    required double splashRadius,

    required this.activeThumbImage,
    required this.onActiveThumbImageError,
    required this.inactiveThumbImage,
    required this.onInactiveThumbImageError,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.configuration,
    required this.surfaceColor,
    required this.textDirection,
  }) : super(
         data: data,
         activeColor: activeColor,
         inactiveColor: inactiveColor,
         focusColor: focusColor,
         hoverColor: hoverColor,
         reactionColor: reactionColor,
         inactiveReactionColor: inactiveReactionColor,
         splashRadius: splashRadius,
       );

  ImageProvider? activeThumbImage;
  ImageErrorListener? onActiveThumbImageError;
  ImageProvider? inactiveThumbImage;
  ImageErrorListener? onInactiveThumbImageError;
  Color activeTrackColor;
  Color inactiveTrackColor;
  ImageConfiguration configuration;
  Color surfaceColor;
  TextDirection textDirection;

  Color? _cachedThumbColor;
  ImageProvider? _cachedThumbImage;
  ImageErrorListener? _cachedThumbErrorListener;
  BoxPainter? _cachedThumbPainter;

  BoxDecoration _createDefaultThumbDecoration(Color color, ImageProvider? image, ImageErrorListener? errorListener) {
    return BoxDecoration(
      color: color,
      image: image == null ? null : DecorationImage(image: image, onError: errorListener),
      shape: BoxShape.circle,
      boxShadow: kElevationToShadow[1],
    );
  }

  bool _isPainting = false;

  void _handleDecorationChanged() {
    // If the image decoration is available synchronously, we'll get called here
    // during paint. There's no reason to mark ourselves as needing paint if we
    // are already in the middle of painting. (In fact, doing so would trigger
    // an assert).
    if (!_isPainting)
      markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Size size) {
    final Canvas canvas = context.canvas;
    final bool isEnabled = onChanged != null;
    final double currentValue = position.value;

    final double visualPosition;
    switch (textDirection) {
      case TextDirection.rtl:
        visualPosition = 1.0 - currentValue;
        break;
      case TextDirection.ltr:
        visualPosition = currentValue;
        break;
    }

    final Color trackColor = Color.lerp(inactiveTrackColor, activeTrackColor, currentValue)!;
    final Color lerpedThumbColor = Color.lerp(inactiveColor, activeColor, currentValue)!;
    // Blend the thumb color against a `surfaceColor` background in case the
    // thumbColor is not opaque. This way we do not see through the thumb to the
    // track underneath.
    final Color thumbColor = Color.alphaBlend(lerpedThumbColor, surfaceColor);

    final ImageProvider? thumbImage = isEnabled
      ? (currentValue < 0.5 ? inactiveThumbImage : activeThumbImage)
      : inactiveThumbImage;

    final ImageErrorListener? thumbErrorListener = isEnabled
      ? (currentValue < 0.5 ? onInactiveThumbImageError : onActiveThumbImageError)
      : onInactiveThumbImageError;

    // Paint the track
    final Paint paint = Paint()
      ..color = trackColor;
    const double trackHorizontalPadding = kRadialReactionRadius - _kTrackRadius;
    final Rect trackRect = Rect.fromLTWH(
      offset.dx + trackHorizontalPadding,
      offset.dy + (size.height - _kTrackHeight) / 2.0,
      size.width - 2.0 * trackHorizontalPadding,
      _kTrackHeight,
    );
    final RRect trackRRect = RRect.fromRectAndRadius(trackRect, const Radius.circular(_kTrackRadius));
    canvas.drawRRect(trackRRect, paint);

    final Offset thumbPosition = Offset(
      kRadialReactionRadius + visualPosition * _trackInnerLength,
      size.height / 2.0,
    );

    paintRadialReaction(canvas, thumbPosition);

    try {
      _isPainting = true;
      if (_cachedThumbPainter == null || thumbColor != _cachedThumbColor || thumbImage != _cachedThumbImage || thumbErrorListener != _cachedThumbErrorListener) {
        _cachedThumbColor = thumbColor;
        _cachedThumbImage = thumbImage;
        _cachedThumbErrorListener = thumbErrorListener;
        _cachedThumbPainter = _createDefaultThumbDecoration(thumbColor, thumbImage, thumbErrorListener).createBoxPainter(_handleDecorationChanged);
      }
      final BoxPainter thumbPainter = _cachedThumbPainter!;

      // The thumb contracts slightly during the animation
      final double inset = 1.0 - (currentValue - 0.5).abs() * 2.0;
      final double radius = _kThumbRadius - inset;
      thumbPainter.paint(
        canvas,
        thumbPosition + offset - Offset(radius, radius),
        configuration.copyWith(size: Size.fromRadius(radius)),
      );
    } finally {
      _isPainting = false;
    }
  }
}
