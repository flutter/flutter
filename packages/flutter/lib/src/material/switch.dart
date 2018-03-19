// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'shadows.dart';
import 'theme.dart';
import 'toggleable.dart';

/// A material design switch.
///
/// Used to toggle the on/off state of a single setting.
///
/// The switch itself does not maintain any state. Instead, when the state of
/// the switch changes, the widget calls the [onChanged] callback. Most widgets
/// that use a switch will listen for the [onChanged] callback and rebuild the
/// switch with a new [value] to update the visual appearance of the switch.
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
///  * <https://material.google.com/components/selection-controls.html#selection-controls-switch>
class Switch extends StatefulWidget {
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
    Key key,
    @required this.value,
    @required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.activeThumbImage,
    this.inactiveThumbImage
  }) : super(key: key);

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
  /// new Switch(
  ///   value: _giveVerse,
  ///   onChanged: (bool newValue) {
  ///     setState(() {
  ///       _giveVerse = newValue;
  ///     });
  ///   },
  /// )
  /// ```
  final ValueChanged<bool> onChanged;

  /// The color to use when this switch is on.
  ///
  /// Defaults to accent color of the current [Theme].
  final Color activeColor;

  /// The color to use on the track when this switch is on.
  ///
  /// Defaults to accent color of the current [Theme] with the opacity set at 50%.
  final Color activeTrackColor;

  /// The color to use on the thumb when this switch is off.
  ///
  /// Defaults to the colors described in the Material design specification.
  final Color inactiveThumbColor;

  /// The color to use on the track when this switch is off.
  ///
  /// Defaults to the colors described in the Material design specification.
  final Color inactiveTrackColor;

  /// An image to use on the thumb of this switch when the switch is on.
  final ImageProvider activeThumbImage;

  /// An image to use on the thumb of this switch when the switch is off.
  final ImageProvider inactiveThumbImage;

  @override
  _SwitchState createState() => new _SwitchState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new FlagProperty('value', value: value, ifTrue: 'on', ifFalse: 'off', showName: true));
    description.add(new ObjectFlagProperty<ValueChanged<bool>>('onChanged', onChanged, ifNull: 'disabled'));
  }
}

class _SwitchState extends State<Switch> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData themeData = Theme.of(context);
    final bool isDark = themeData.brightness == Brightness.dark;

    final Color activeThumbColor = widget.activeColor ?? themeData.accentColor;
    final Color activeTrackColor = widget.activeTrackColor ?? activeThumbColor.withAlpha(0x80);

    Color inactiveThumbColor;
    Color inactiveTrackColor;
    if (widget.onChanged != null) {
      inactiveThumbColor = widget.inactiveThumbColor ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade50);
      inactiveTrackColor = widget.inactiveTrackColor ?? (isDark ? Colors.white30 : Colors.black26);
    } else {
      inactiveThumbColor = widget.inactiveThumbColor ?? (isDark ? Colors.grey.shade800 : Colors.grey.shade400);
      inactiveTrackColor = widget.inactiveTrackColor ?? (isDark ? Colors.white10 : Colors.black12);
    }

    return new _SwitchRenderObjectWidget(
      value: widget.value,
      activeColor: activeThumbColor,
      inactiveColor: inactiveThumbColor,
      activeThumbImage: widget.activeThumbImage,
      inactiveThumbImage: widget.inactiveThumbImage,
      activeTrackColor: activeTrackColor,
      inactiveTrackColor: inactiveTrackColor,
      configuration: createLocalImageConfiguration(context),
      onChanged: widget.onChanged,
      vsync: this,
    );
  }
}

class _SwitchRenderObjectWidget extends LeafRenderObjectWidget {
  const _SwitchRenderObjectWidget({
    Key key,
    this.value,
    this.activeColor,
    this.inactiveColor,
    this.activeThumbImage,
    this.inactiveThumbImage,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.configuration,
    this.onChanged,
    this.vsync,
  }) : super(key: key);

  final bool value;
  final Color activeColor;
  final Color inactiveColor;
  final ImageProvider activeThumbImage;
  final ImageProvider inactiveThumbImage;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final ImageConfiguration configuration;
  final ValueChanged<bool> onChanged;
  final TickerProvider vsync;

  @override
  _RenderSwitch createRenderObject(BuildContext context) {
    return new _RenderSwitch(
      value: value,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      activeThumbImage: activeThumbImage,
      inactiveThumbImage: inactiveThumbImage,
      activeTrackColor: activeTrackColor,
      inactiveTrackColor: inactiveTrackColor,
      configuration: configuration,
      onChanged: onChanged,
      textDirection: Directionality.of(context),
      vsync: vsync,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSwitch renderObject) {
    renderObject
      ..value = value
      ..activeColor = activeColor
      ..inactiveColor = inactiveColor
      ..activeThumbImage = activeThumbImage
      ..inactiveThumbImage = inactiveThumbImage
      ..activeTrackColor = activeTrackColor
      ..inactiveTrackColor = inactiveTrackColor
      ..configuration = configuration
      ..onChanged = onChanged
      ..textDirection = Directionality.of(context)
      ..vsync = vsync;
  }
}

const double _kTrackHeight = 14.0;
const double _kTrackWidth = 33.0;
const double _kTrackRadius = _kTrackHeight / 2.0;
const double _kThumbRadius = 10.0;
const double _kSwitchWidth = _kTrackWidth - 2 * _kTrackRadius + 2 * kRadialReactionRadius;
const double _kSwitchHeight = 2 * kRadialReactionRadius;

class _RenderSwitch extends RenderToggleable {
  _RenderSwitch({
    bool value,
    Color activeColor,
    Color inactiveColor,
    ImageProvider activeThumbImage,
    ImageProvider inactiveThumbImage,
    Color activeTrackColor,
    Color inactiveTrackColor,
    ImageConfiguration configuration,
    @required TextDirection textDirection,
    ValueChanged<bool> onChanged,
    @required TickerProvider vsync,
  }) : assert(textDirection != null),
       _activeThumbImage = activeThumbImage,
       _inactiveThumbImage = inactiveThumbImage,
       _activeTrackColor = activeTrackColor,
       _inactiveTrackColor = inactiveTrackColor,
       _configuration = configuration,
       _textDirection = textDirection,
       super(
         value: value,
         tristate: false,
         activeColor: activeColor,
         inactiveColor: inactiveColor,
         onChanged: onChanged,
         size: const Size(_kSwitchWidth, _kSwitchHeight),
         vsync: vsync,
       ) {
    _drag = new HorizontalDragGestureRecognizer()
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd;
  }

  ImageProvider get activeThumbImage => _activeThumbImage;
  ImageProvider _activeThumbImage;
  set activeThumbImage(ImageProvider value) {
    if (value == _activeThumbImage)
      return;
    _activeThumbImage = value;
    markNeedsPaint();
  }

  ImageProvider get inactiveThumbImage => _inactiveThumbImage;
  ImageProvider _inactiveThumbImage;
  set inactiveThumbImage(ImageProvider value) {
    if (value == _inactiveThumbImage)
      return;
    _inactiveThumbImage = value;
    markNeedsPaint();
  }

  Color get activeTrackColor => _activeTrackColor;
  Color _activeTrackColor;
  set activeTrackColor(Color value) {
    assert(value != null);
    if (value == _activeTrackColor)
      return;
    _activeTrackColor = value;
    markNeedsPaint();
  }

  Color get inactiveTrackColor => _inactiveTrackColor;
  Color _inactiveTrackColor;
  set inactiveTrackColor(Color value) {
    assert(value != null);
    if (value == _inactiveTrackColor)
      return;
    _inactiveTrackColor = value;
    markNeedsPaint();
  }

  ImageConfiguration get configuration => _configuration;
  ImageConfiguration _configuration;
  set configuration(ImageConfiguration value) {
    assert(value != null);
    if (value == _configuration)
      return;
    _configuration = value;
    markNeedsPaint();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (_textDirection == value)
      return;
    _textDirection = value;
    markNeedsPaint();
  }

  @override
  void detach() {
    _cachedThumbPainter?.dispose();
    _cachedThumbPainter = null;
    super.detach();
  }

  double get _trackInnerLength => size.width - 2.0 * kRadialReactionRadius;

  HorizontalDragGestureRecognizer _drag;

  void _handleDragStart(DragStartDetails details) {
    if (isInteractive)
      reactionController.forward();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (isInteractive) {
      position
        ..curve = null
        ..reverseCurve = null;
      final double delta = details.primaryDelta / _trackInnerLength;
      switch (textDirection) {
        case TextDirection.rtl:
          positionController.value -= delta;
          break;
        case TextDirection.ltr:
          positionController.value += delta;
          break;
      }
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (position.value >= 0.5)
      positionController.forward();
    else
      positionController.reverse();
    reactionController.reverse();
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && onChanged != null)
      _drag.addPointer(event);
    super.handleEvent(event, entry);
  }

  Color _cachedThumbColor;
  ImageProvider _cachedThumbImage;
  BoxPainter _cachedThumbPainter;

  BoxDecoration _createDefaultThumbDecoration(Color color, ImageProvider image) {
    return new BoxDecoration(
      color: color,
      image: image == null ? null : new DecorationImage(image: image),
      shape: BoxShape.circle,
      boxShadow: kElevationToShadow[1]
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
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    final bool isActive = onChanged != null;
    final double currentValue = position.value;

    double visualPosition;
    switch (textDirection) {
      case TextDirection.rtl:
        visualPosition = 1.0 - currentValue;
        break;
      case TextDirection.ltr:
        visualPosition = currentValue;
        break;
    }

    final Color trackColor = isActive ? Color.lerp(inactiveTrackColor, activeTrackColor, currentValue) : inactiveTrackColor;

    // Paint the track
    final Paint paint = new Paint()
      ..color = trackColor;
    const double trackHorizontalPadding = kRadialReactionRadius - _kTrackRadius;
    final Rect trackRect = new Rect.fromLTWH(
      offset.dx + trackHorizontalPadding,
      offset.dy + (size.height - _kTrackHeight) / 2.0,
      size.width - 2.0 * trackHorizontalPadding,
      _kTrackHeight
    );
    final RRect trackRRect = new RRect.fromRectAndRadius(trackRect, const Radius.circular(_kTrackRadius));
    canvas.drawRRect(trackRRect, paint);

    final Offset thumbPosition = new Offset(
      kRadialReactionRadius + visualPosition * _trackInnerLength,
      size.height / 2.0
    );

    paintRadialReaction(canvas, offset, thumbPosition);

    try {
      _isPainting = true;
      BoxPainter thumbPainter;
      final Color thumbColor = isActive ? Color.lerp(inactiveColor, activeColor, currentValue) : inactiveColor;
      final ImageProvider thumbImage = isActive ? (currentValue < 0.5 ? inactiveThumbImage : activeThumbImage) : inactiveThumbImage;
      if (_cachedThumbPainter == null || thumbColor != _cachedThumbColor || thumbImage != _cachedThumbImage) {
        _cachedThumbColor = thumbColor;
        _cachedThumbImage = thumbImage;
        _cachedThumbPainter = _createDefaultThumbDecoration(thumbColor, thumbImage).createBoxPainter(_handleDecorationChanged);
      }
      thumbPainter = _cachedThumbPainter;

      // The thumb contracts slightly during the animation
      final double inset = 1.0 - (currentValue - 0.5).abs() * 2.0;
      final double radius = _kThumbRadius - inset;
      thumbPainter.paint(
        canvas,
        thumbPosition + offset - new Offset(radius, radius),
        configuration.copyWith(size: new Size.fromRadius(radius))
      );
    } finally {
      _isPainting = false;
    }
  }
}
