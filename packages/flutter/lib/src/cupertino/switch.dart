// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Examples can assume:
// bool _giveVerse = false;

/// @docImport 'package:flutter/material.dart';
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme.dart';
import 'thumb_painter.dart';

// Examples can assume:
// bool _lights = false;
// void setState(VoidCallback fn) { }

/// An iOS-style switch.
///
/// Used to toggle the on/off state of a single setting.
///
/// The switch itself does not maintain any state. Instead, when the state of
/// the switch changes, the widget calls the [onChanged] callback. Most widgets
/// that use a switch will listen for the [onChanged] callback and rebuild the
/// switch with a new [value] to update the visual appearance of the switch.
///
/// {@tool dartpad}
/// This example shows a toggleable [CupertinoSwitch]. When the thumb slides to
/// the other side of the track, the switch is toggled between on/off.
///
/// ** See code in examples/api/lib/cupertino/switch/cupertino_switch.0.dart **
/// {@end-tool}
///
/// {@tool snippet}
///
/// This sample shows how to use a [CupertinoSwitch] in a [ListTile]. The
/// [MergeSemantics] is used to turn the entire [ListTile] into a single item
/// for accessibility tools.
///
/// ```dart
/// MergeSemantics(
///   child: ListTile(
///     title: const Text('Lights'),
///     trailing: CupertinoSwitch(
///       value: _lights,
///       onChanged: (bool value) { setState(() { _lights = value; }); },
///     ),
///     onTap: () { setState(() { _lights = !_lights; }); },
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Switch], the Material Design equivalent.
///  * <https://developer.apple.com/design/human-interface-guidelines/toggles/>
class CupertinoSwitch extends StatefulWidget {
  /// Creates an iOS-style switch.
  ///
  /// The [dragStartBehavior] parameter defaults to [DragStartBehavior.start].
  const CupertinoSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.trackColor,
    this.thumbColor,
    this.applyTheme,
    this.focusColor,
    this.onLabelColor,
    this.offLabelColor,
    this.focusNode,
    this.onFocusChange,
    this.autofocus = false,
    this.dragStartBehavior = DragStartBehavior.start,
  });

  /// Whether this switch is on or off.
  final bool value;

  /// Called when the user toggles with switch on or off.
  ///
  /// The switch passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the switch with the new
  /// value.
  ///
  /// If null, the switch will be displayed as disabled, which has a reduced opacity.
  ///
  /// The callback provided to onChanged should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt; for example:
  ///
  /// ```dart
  /// CupertinoSwitch(
  ///   value: _giveVerse,
  ///   onChanged: (bool newValue) {
  ///     setState(() {
  ///       _giveVerse = newValue;
  ///     });
  ///   },
  /// )
  /// ```
  final ValueChanged<bool>? onChanged;

  /// The color to use for the track when the switch is on.
  ///
  /// If null and [applyTheme] is false, defaults to [CupertinoColors.systemGreen]
  /// in accordance to native iOS behavior. Otherwise, defaults to
  /// [CupertinoThemeData.primaryColor].
  final Color? activeColor;


  /// The color to use for the track when the switch is off.
  ///
  /// Defaults to [CupertinoColors.secondarySystemFill] when null.
  final Color? trackColor;

  /// The color to use for the thumb of the switch.
  ///
  /// Defaults to [CupertinoColors.white] when null.
  final Color? thumbColor;

  /// The color to use for the focus highlight for keyboard interactions.
  ///
  /// Defaults to a slightly transparent [activeColor].
  final Color? focusColor;

  /// The color to use for the accessibility label when the switch is on.
  ///
  /// Defaults to [CupertinoColors.white] when null.
  final Color? onLabelColor;

  /// The color to use for the accessibility label when the switch is off.
  ///
  /// Defaults to [Color.fromARGB(255, 179, 179, 179)]
  /// (or [Color.fromARGB(255, 255, 255, 255)] in high contrast) when null.
  final Color? offLabelColor;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.material.inkwell.onFocusChange}
  final ValueChanged<bool>? onFocusChange;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// {@template flutter.cupertino.CupertinoSwitch.applyTheme}
  /// Whether to apply the ambient [CupertinoThemeData].
  ///
  /// If true, the track uses [CupertinoThemeData.primaryColor] for the track
  /// when the switch is on.
  ///
  /// Defaults to [CupertinoThemeData.applyThemeToAll].
  /// {@endtemplate}
  final bool? applyTheme;

  /// {@template flutter.cupertino.CupertinoSwitch.dragStartBehavior}
  /// Determines the way that drag start behavior is handled.
  ///
  /// If set to [DragStartBehavior.start], the drag behavior used to move the
  /// switch from on to off will begin at the position where the drag gesture won
  /// the arena. If set to [DragStartBehavior.down] it will begin at the position
  /// where a down event was first detected.
  ///
  /// In general, setting this to [DragStartBehavior.start] will make drag
  /// animation smoother and setting it to [DragStartBehavior.down] will make
  /// drag behavior feel slightly more reactive.
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// See also:
  ///
  ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for
  ///    the different behaviors.
  ///
  /// {@endtemplate}
  final DragStartBehavior dragStartBehavior;

  @override
  State<CupertinoSwitch> createState() => _CupertinoSwitchState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('value', value: value, ifTrue: 'on', ifFalse: 'off', showName: true));
    properties.add(ObjectFlagProperty<ValueChanged<bool>>('onChanged', onChanged, ifNull: 'disabled'));
  }
}

class _CupertinoSwitchState extends State<CupertinoSwitch> with TickerProviderStateMixin {
  late TapGestureRecognizer _tap;
  late HorizontalDragGestureRecognizer _drag;

  late AnimationController _positionController;
  late final CurvedAnimation position;

  late AnimationController _reactionController;
  late CurvedAnimation _reaction;

  late bool isFocused;

  bool get isInteractive => widget.onChanged != null;

  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _handleTap),
  };

  // A non-null boolean value that changes to true at the end of a drag if the
  // switch must be animated to the position indicated by the widget's value.
  bool needsPositionAnimation = false;

  @override
  void initState() {
    super.initState();

    isFocused = false;

    _tap = TapGestureRecognizer()
      ..onTapDown = _handleTapDown
      ..onTapUp = _handleTapUp
      ..onTap = _handleTap
      ..onTapCancel = _handleTapCancel;
    _drag = HorizontalDragGestureRecognizer()
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..dragStartBehavior = widget.dragStartBehavior;

    _positionController = AnimationController(
      duration: _kToggleDuration,
      value: widget.value ? 1.0 : 0.0,
      vsync: this,
    );
    position = CurvedAnimation(
      parent: _positionController,
      curve: Curves.linear,
    );
    _reactionController = AnimationController(
      duration: _kReactionDuration,
      vsync: this,
    );
    _reaction = CurvedAnimation(
      parent: _reactionController,
      curve: Curves.ease,
    );
  }

  @override
  void didUpdateWidget(CupertinoSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    _drag.dragStartBehavior = widget.dragStartBehavior;

    if (needsPositionAnimation || oldWidget.value != widget.value) {
      _resumePositionAnimation(isLinear: needsPositionAnimation);
    }
  }

  // `isLinear` must be true if the position animation is trying to move the
  // thumb to the closest end after the most recent drag animation, so the curve
  // does not change when the controller's value is not 0 or 1.
  //
  // It can be set to false when it's an implicit animation triggered by
  // widget.value changes.
  void _resumePositionAnimation({ bool isLinear = true }) {
    needsPositionAnimation = false;
    position
      ..curve = isLinear ? Curves.linear : Curves.ease
      ..reverseCurve = isLinear ? Curves.linear : Curves.ease.flipped;
    if (widget.value) {
      _positionController.forward();
    } else {
      _positionController.reverse();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (isInteractive) {
      needsPositionAnimation = false;
    }
      _reactionController.forward();
  }

  void _handleTap([Intent? _]) {
    if (isInteractive) {
      widget.onChanged!(!widget.value);
      _emitVibration();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (isInteractive) {
      needsPositionAnimation = false;
      _reactionController.reverse();
    }
  }

  void _handleTapCancel() {
    if (isInteractive) {
      _reactionController.reverse();
    }
  }

  void _handleDragStart(DragStartDetails details) {
    if (isInteractive) {
      needsPositionAnimation = false;
      _reactionController.forward();
      _emitVibration();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (isInteractive) {
      position
        ..curve = Curves.linear
        ..reverseCurve = Curves.linear;
      final double delta = details.primaryDelta! / _kTrackInnerLength;
      _positionController.value += switch (Directionality.of(context)) {
        TextDirection.rtl => -delta,
        TextDirection.ltr =>  delta,
      };
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    // Deferring the animation to the next build phase.
    setState(() { needsPositionAnimation = true; });
    // Call onChanged when the user's intent to change value is clear.
    if (position.value >= 0.5 != widget.value) {
      widget.onChanged!(!widget.value);
    }
    _reactionController.reverse();
  }

  void _emitVibration() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        HapticFeedback.lightImpact();
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        break;
    }
  }

  void _onShowFocusHighlight(bool showHighlight) {
    setState(() { isFocused = showHighlight; });
  }

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final Color activeColor = CupertinoDynamicColor.resolve(
      widget.activeColor
      ?? ((widget.applyTheme ?? theme.applyThemeToAll) ? theme.primaryColor : null)
      ?? CupertinoColors.systemGreen,
      context,
    );
    final (Color onLabelColor, Color offLabelColor)? onOffLabelColors =
        MediaQuery.onOffSwitchLabelsOf(context)
            ? (
                CupertinoDynamicColor.resolve(
                  widget.onLabelColor ?? CupertinoColors.white,
                  context,
                ),
                CupertinoDynamicColor.resolve(
                  widget.offLabelColor ?? _kOffLabelColor,
                  context,
                ),
              )
            : null;
    if (needsPositionAnimation) {
      _resumePositionAnimation();
    }
    return MouseRegion(
      cursor: isInteractive && kIsWeb ? SystemMouseCursors.click : MouseCursor.defer,
      child: Opacity(
        opacity: widget.onChanged == null ? _kCupertinoSwitchDisabledOpacity : 1.0,
        child: FocusableActionDetector(
          onShowFocusHighlight: _onShowFocusHighlight,
          actions: _actionMap,
          enabled: isInteractive,
          focusNode: widget.focusNode,
          onFocusChange: widget.onFocusChange,
          autofocus: widget.autofocus,
          child: _CupertinoSwitchRenderObjectWidget(
            value: widget.value,
            activeColor: activeColor,
            trackColor: CupertinoDynamicColor.resolve(widget.trackColor ?? CupertinoColors.secondarySystemFill, context),
            thumbColor: CupertinoDynamicColor.resolve(widget.thumbColor ?? CupertinoColors.white, context),
            // Opacity, lightness, and saturation values were approximated with
            // color pickers on the switches in the macOS settings.
            focusColor: CupertinoDynamicColor.resolve(
              widget.focusColor ??
              HSLColor
                    .fromColor(activeColor.withOpacity(0.80))
                    .withLightness(0.69).withSaturation(0.835)
                    .toColor(),
              context),
            onChanged: widget.onChanged,
            textDirection: Directionality.of(context),
            isFocused: isFocused,
            state: this,
            onOffLabelColors: onOffLabelColors,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tap.dispose();
    _drag.dispose();

    _positionController.dispose();
    _reactionController.dispose();
    position.dispose();
    _reaction.dispose();
    super.dispose();
  }
}

class _CupertinoSwitchRenderObjectWidget extends LeafRenderObjectWidget {
  const _CupertinoSwitchRenderObjectWidget({
    required this.value,
    required this.activeColor,
    required this.trackColor,
    required this.thumbColor,
    required this.focusColor,
    required this.onChanged,
    required this.textDirection,
    required this.isFocused,
    required this.state,
    required this.onOffLabelColors,
  });

  final bool value;
  final Color activeColor;
  final Color trackColor;
  final Color thumbColor;
  final Color focusColor;
  final ValueChanged<bool>? onChanged;
  final _CupertinoSwitchState state;
  final TextDirection textDirection;
  final bool isFocused;
  final (Color onLabelColor, Color offLabelColor)? onOffLabelColors;

  @override
  _RenderCupertinoSwitch createRenderObject(BuildContext context) {
    return _RenderCupertinoSwitch(
      value: value,
      activeColor: activeColor,
      trackColor: trackColor,
      thumbColor: thumbColor,
      focusColor: focusColor,
      onChanged: onChanged,
      textDirection: textDirection,
      isFocused: isFocused,
      state: state,
      onOffLabelColors: onOffLabelColors,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderCupertinoSwitch renderObject) {
    assert(renderObject._state == state);
    renderObject
      ..value = value
      ..activeColor = activeColor
      ..trackColor = trackColor
      ..thumbColor = thumbColor
      ..focusColor = focusColor
      ..onChanged = onChanged
      ..textDirection = textDirection
      ..isFocused = isFocused;
  }
}

const double _kTrackWidth = 51.0;
const double _kTrackHeight = 31.0;
const double _kTrackRadius = _kTrackHeight / 2.0;
const double _kTrackInnerStart = _kTrackHeight / 2.0;
const double _kTrackInnerEnd = _kTrackWidth - _kTrackInnerStart;
const double _kTrackInnerLength = _kTrackInnerEnd - _kTrackInnerStart;
const double _kSwitchWidth = 59.0;
const double _kSwitchHeight = 39.0;
// Label sizes and padding taken from xcode inspector.
// See https://github.com/flutter/flutter/issues/4830#issuecomment-528495360
const double _kOnLabelWidth = 1.0;
const double _kOnLabelHeight = 10.0;
const double _kOnLabelPaddingHorizontal = 11.0;
const double _kOffLabelWidth = 1.0;
const double _kOffLabelPaddingHorizontal = 12.0;
const double _kOffLabelRadius = 5.0;
const CupertinoDynamicColor _kOffLabelColor = CupertinoDynamicColor.withBrightnessAndContrast(
  debugLabel: 'offSwitchLabel',
  // Source: https://github.com/flutter/flutter/pull/39993#discussion_r321946033
  color: Color.fromARGB(255, 179, 179, 179),
  // Source: https://github.com/flutter/flutter/pull/39993#issuecomment-535196665
  darkColor: Color.fromARGB(255, 179, 179, 179),
  // Source: https://github.com/flutter/flutter/pull/127776#discussion_r1244208264
  highContrastColor: Color.fromARGB(255, 255, 255, 255),
  darkHighContrastColor: Color.fromARGB(255, 255, 255, 255),
);
// Opacity of a disabled switch, as eye-balled from iOS Simulator on Mac.
const double _kCupertinoSwitchDisabledOpacity = 0.5;

const Duration _kReactionDuration = Duration(milliseconds: 300);
const Duration _kToggleDuration = Duration(milliseconds: 200);

class _RenderCupertinoSwitch extends RenderConstrainedBox {
  _RenderCupertinoSwitch({
    required bool value,
    required Color activeColor,
    required Color trackColor,
    required Color thumbColor,
    required Color focusColor,
    ValueChanged<bool>? onChanged,
    required TextDirection textDirection,
    required bool isFocused,
    required _CupertinoSwitchState state,
    required (Color onLabelColor, Color offLabelColor)? onOffLabelColors,
  }) : _value = value,
       _activeColor = activeColor,
       _trackColor = trackColor,
       _focusColor = focusColor,
       _thumbPainter = CupertinoThumbPainter.switchThumb(color: thumbColor),
       _onChanged = onChanged,
       _textDirection = textDirection,
       _isFocused = isFocused,
       _state = state,
       _onOffLabelColors = onOffLabelColors,
       super(additionalConstraints: const BoxConstraints.tightFor(width: _kSwitchWidth, height: _kSwitchHeight)) {
         state.position.addListener(markNeedsPaint);
         state._reaction.addListener(markNeedsPaint);
  }

  final _CupertinoSwitchState _state;

  bool get value => _value;
  bool _value;
  set value(bool value) {
    if (value == _value) {
      return;
    }
    _value = value;
    markNeedsSemanticsUpdate();
  }

  Color get activeColor => _activeColor;
  Color _activeColor;
  set activeColor(Color value) {
    if (value == _activeColor) {
      return;
    }
    _activeColor = value;
    markNeedsPaint();
  }

  Color get trackColor => _trackColor;
  Color _trackColor;
  set trackColor(Color value) {
    if (value == _trackColor) {
      return;
    }
    _trackColor = value;
    markNeedsPaint();
  }

  Color get thumbColor => _thumbPainter.color;
  CupertinoThumbPainter _thumbPainter;
  set thumbColor(Color value) {
    if (value == thumbColor) {
      return;
    }
    _thumbPainter = CupertinoThumbPainter.switchThumb(color: value);
    markNeedsPaint();
  }

  Color get focusColor => _focusColor;
  Color _focusColor;
  set focusColor(Color value) {
    if (value == _focusColor) {
      return;
    }
    _focusColor = value;
    markNeedsPaint();
  }

  ValueChanged<bool>? get onChanged => _onChanged;
  ValueChanged<bool>? _onChanged;
  set onChanged(ValueChanged<bool>? value) {
    if (value == _onChanged) {
      return;
    }
    final bool wasInteractive = isInteractive;
    _onChanged = value;
    if (wasInteractive != isInteractive) {
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsPaint();
  }

  bool get isFocused => _isFocused;
  bool _isFocused;
  set isFocused(bool value) {
    if (value == _isFocused) {
      return;
    }
    _isFocused = value;
    markNeedsPaint();
  }

  (Color onLabelColor, Color offLabelColor)? get onOffLabelColors => _onOffLabelColors;
  (Color onLabelColor, Color offLabelColor)? _onOffLabelColors;
  set onOffLabelColors((Color onLabelColor, Color offLabelColor)? value) {
    if (value == _onOffLabelColors) {
      return;
    }
    _onOffLabelColors = value;
    markNeedsPaint();
  }

  bool get isInteractive => onChanged != null;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && isInteractive) {
      _state._drag.addPointer(event);
      _state._tap.addPointer(event);
    }
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    if (isInteractive) {
      config.onTap = _state._handleTap;
    }

    config.isEnabled = isInteractive;
    config.isToggled = _value;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    final double currentValue = _state.position.value;
    final double currentReactionValue = _state._reaction.value;

    final double visualPosition = switch (textDirection) {
      TextDirection.rtl => 1.0 - currentValue,
      TextDirection.ltr => currentValue,
    };

    final Paint paint = Paint()
      ..color = Color.lerp(trackColor, activeColor, currentValue)!;

    final Rect trackRect = Rect.fromLTWH(
        offset.dx + (size.width - _kTrackWidth) / 2.0,
        offset.dy + (size.height - _kTrackHeight) / 2.0,
        _kTrackWidth,
        _kTrackHeight,
    );
    final RRect trackRRect = RRect.fromRectAndRadius(trackRect, const Radius.circular(_kTrackRadius));
    canvas.drawRRect(trackRRect, paint);

    if (_isFocused) {
      // Paints a border around the switch in the focus color.
      final RRect borderTrackRRect = trackRRect.inflate(1.75);

      final Paint borderPaint = Paint()
        ..color = focusColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;

      canvas.drawRRect(borderTrackRRect, borderPaint);
    }

    if (_onOffLabelColors != null) {
      final (Color onLabelColor, Color offLabelColor) = onOffLabelColors!;

      final double leftLabelOpacity = visualPosition * (1.0 - currentReactionValue);
      final double rightLabelOpacity = (1.0 - visualPosition) * (1.0 - currentReactionValue);
      final (double onLabelOpacity, double offLabelOpacity) =
          switch (textDirection) {
        TextDirection.ltr => (leftLabelOpacity, rightLabelOpacity),
        TextDirection.rtl => (rightLabelOpacity, leftLabelOpacity),
      };

      final (Offset onLabelOffset, Offset offLabelOffset) =
          switch (textDirection) {
        TextDirection.ltr => (
            trackRect.centerLeft.translate(_kOnLabelPaddingHorizontal, 0),
            trackRect.centerRight.translate(-_kOffLabelPaddingHorizontal, 0),
          ),
        TextDirection.rtl => (
            trackRect.centerRight.translate(-_kOnLabelPaddingHorizontal, 0),
            trackRect.centerLeft.translate(_kOffLabelPaddingHorizontal, 0),
          ),
      };

      // Draws '|' label
      final Rect onLabelRect = Rect.fromCenter(
        center: onLabelOffset,
        width: _kOnLabelWidth,
        height: _kOnLabelHeight,
      );
      final Paint onLabelPaint = Paint()
        ..color = onLabelColor.withOpacity(onLabelOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawRect(onLabelRect, onLabelPaint);

      // Draws 'O' label
      final Paint offLabelPaint = Paint()
        ..color = offLabelColor.withOpacity(offLabelOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _kOffLabelWidth;
      canvas.drawCircle(
        offLabelOffset,
        _kOffLabelRadius,
        offLabelPaint,
      );
    }

    final double currentThumbExtension = CupertinoThumbPainter.extension * currentReactionValue;
    final double thumbLeft = lerpDouble(
      trackRect.left + _kTrackInnerStart - CupertinoThumbPainter.radius,
      trackRect.left + _kTrackInnerEnd - CupertinoThumbPainter.radius - currentThumbExtension,
      visualPosition,
    )!;
    final double thumbRight = lerpDouble(
      trackRect.left + _kTrackInnerStart + CupertinoThumbPainter.radius + currentThumbExtension,
      trackRect.left + _kTrackInnerEnd + CupertinoThumbPainter.radius,
      visualPosition,
    )!;
    final double thumbCenterY = offset.dy + size.height / 2.0;
    final Rect thumbBounds = Rect.fromLTRB(
      thumbLeft,
      thumbCenterY - CupertinoThumbPainter.radius,
      thumbRight,
      thumbCenterY + CupertinoThumbPainter.radius,
    );

    _clipRRectLayer.layer = context.pushClipRRect(needsCompositing, Offset.zero, thumbBounds, trackRRect, (PaintingContext innerContext, Offset offset) {
      _thumbPainter.paint(innerContext.canvas, thumbBounds);
    }, oldLayer: _clipRRectLayer.layer);
  }

  final LayerHandle<ClipRRectLayer> _clipRRectLayer = LayerHandle<ClipRRectLayer>();

  @override
  void dispose() {
    _clipRRectLayer.layer = null;
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(FlagProperty('value', value: value, ifTrue: 'checked', ifFalse: 'unchecked', showName: true));
    description.add(FlagProperty('isInteractive', value: isInteractive, ifTrue: 'enabled', ifFalse: 'disabled', showName: true, defaultValue: true));
  }
}
