// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'debug.dart';
import 'material.dart';
import 'slider_theme.dart';
import 'theme.dart';

/// A Material Design slider.
///
/// Used to select from a range of values.
///
/// A slider can be used to select from either a continuous or a discrete set of
/// values. The default is to use a continuous range of values from [min] to
/// [max]. To use discrete values, use a non-null value for [divisions], which
/// indicates the number of discrete intervals. For example, if [min] is 0.0 and
/// [max] is 50.0 and [divisions] is 5, then the slider can take on the
/// discrete values 0.0, 10.0, 20.0, 30.0, 40.0, and 50.0.
///
/// The terms for the parts of a slider are:
///
///  * The "thumb", which is a shape that slides horizontally when the user
///    drags it.
///  * The "rail", which is the line that the slider thumb slides along.
///  * The "value indicator", which is a shape that pops up when the user
///    is dragging the thumb to indicate the value being selected.
///  * The "active" side of the slider is the side between the thumb and the
///    minimum value.
///  * The "inactive" side of the slider is the side between the thumb and the
///    maximum value.
///
/// The slider will be disabled if [onChanged] is null or if the range given by
/// [min]..[max] is empty (i.e. if [min] is equal to [max]).
///
/// The slider widget itself does not maintain any state. Instead, when the state
/// of the slider changes, the widget calls the [onChanged] callback. Most
/// widgets that use a slider will listen for the [onChanged] callback and
/// rebuild the slider with a new [value] to update the visual appearance of the
/// slider.
///
/// By default, a slider will be as wide as possible, centered vertically. When
/// given unbounded constraints, it will attempt to make the rail 144 pixels
/// wide (with margins on each side) and will shrink-wrap vertically.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// Requires one of its ancestors to be a [MediaQuery] widget. Typically, these
/// are introduced by the [MaterialApp] or [WidgetsApp] widget at the top of
/// your application widget tree.
///
/// To determine how it should be displayed (e.g. colors, thumb shape, etc.),
/// a slider uses the [SliderThemeData] available from either a [SliderTheme]
/// widget or the [ThemeData.sliderTheme] a [Theme] widget above it in the
/// widget tree. You can also override some of the colors with the [activeColor]
/// and [inactiveColor] properties, although more fine-grained control of the
/// look is achieved using a [SliderThemeData].
///
/// See also:
///
///  * [SliderTheme] and [SliderThemeData] for information about controlling
///    the visual appearance of the slider.
///  * [Radio], for selecting among a set of explicit values.
///  * [Checkbox] and [Switch], for toggling a particular value on or off.
///  * <https://material.google.com/components/sliders.html>
///  * [MediaQuery], from which the text scale factor is obtained.
class Slider extends StatefulWidget {
  /// Creates a material design slider.
  ///
  /// The slider itself does not maintain any state. Instead, when the state of
  /// the slider changes, the widget calls the [onChanged] callback. Most
  /// widgets that use a slider will listen for the [onChanged] callback and
  /// rebuild the slider with a new [value] to update the visual appearance of
  /// the slider.
  ///
  /// * [value] determines currently selected value for this slider.
  /// * [onChanged] is called when the user selects a new value for the slider.
  ///
  /// You can override some of the colors with the [activeColor] and
  /// [inactiveColor] properties, although more fine-grained control of the
  /// appearance is achieved using a [SliderThemeData].
  const Slider({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.min: 0.0,
    this.max: 1.0,
    this.divisions,
    this.label,
    this.activeColor,
    this.inactiveColor,
  }) : assert(value != null),
       assert(min != null),
       assert(max != null),
       assert(min <= max),
       assert(value >= min && value <= max),
       assert(divisions == null || divisions > 0),
       super(key: key);

  /// The currently selected value for this slider.
  ///
  /// The slider's thumb is drawn at a position that corresponds to this value.
  final double value;

  /// Called when the user selects a new value for the slider.
  ///
  /// The slider passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the slider with the new
  /// value.
  ///
  /// If null, the slider will be displayed as disabled.
  ///
  /// The callback provided to onChanged should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt; for example:
  ///
  /// ```dart
  /// new Slider(
  ///   value: _duelCommandment.toDouble(),
  ///   min: 1.0,
  ///   max: 10.0,
  ///   divisions: 10,
  ///   label: '$_duelCommandment',
  ///   onChanged: (double newValue) {
  ///     setState(() {
  ///       _duelCommandment = newValue.round();
  ///     });
  ///   },
  /// )
  /// ```
  final ValueChanged<double> onChanged;

  /// The minimum value the user can select.
  ///
  /// Defaults to 0.0. Must be less than or equal to [max].
  ///
  /// If the [max] is equal to the [min], then the slider is disabled.
  final double min;

  /// The maximum value the user can select.
  ///
  /// Defaults to 1.0. Must be greater than or equal to [min].
  ///
  /// If the [max] is equal to the [min], then the slider is disabled.
  final double max;

  /// The number of discrete divisions.
  ///
  /// Typically used with [label] to show the current discrete value.
  ///
  /// If null, the slider is continuous.
  final int divisions;

  /// A label to show above the slider when the slider is active.
  ///
  /// It is used to display the value of a discrete slider, and it is displayed
  /// as part of the value indicator shape.
  ///
  /// The label is rendered using the active [ThemeData]'s
  /// [ThemeData.accentTextTheme.body2] text style.
  ///
  /// If null, then the value indicator will not be displayed.
  ///
  /// See also:
  ///
  ///  * [SliderComponentShape] for how to create a custom value indicator
  ///    shape.
  final String label;

  /// The color to use for the portion of the slider rail that is active.
  ///
  /// The "active" side of the slider is the side between the thumb and the
  /// minimum value.
  ///
  /// Defaults to [SliderTheme.activeRailColor] of the current [SliderTheme].
  ///
  /// Using a [SliderTheme] gives much more fine-grained control over the
  /// appearance of various components of the slider.
  final Color activeColor;

  /// The color for the inactive portion of the slider rail.
  ///
  /// The "inactive" side of the slider is the side between the thumb and the
  /// maximum value.
  ///
  /// Defaults to the [SliderTheme.inactiveRailColor] of the current
  /// [SliderTheme].
  ///
  /// Using a [SliderTheme] gives much more fine-grained control over the
  /// appearance of various components of the slider.
  final Color inactiveColor;

  @override
  _SliderState createState() => new _SliderState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DoubleProperty('value', value));
    description.add(new DoubleProperty('min', min));
    description.add(new DoubleProperty('max', max));
  }
}

class _SliderState extends State<Slider> with TickerProviderStateMixin {
  static const Duration enableAnimationDuration = const Duration(milliseconds: 75);
  static const Duration valueIndicatorAnimationDuration = const Duration(milliseconds: 100);

  // Animation controller that is run when the overlay (a.k.a radial reaction)
  // is shown in response to user interaction.
  AnimationController overlayController;
  // Animation controller that is run when the value indicator is being shown
  // or hidden.
  AnimationController valueIndicatorController;
  // Animation controller that is run when enabling/disabling the slider.
  AnimationController enableController;
  // Animation controller that is run when transitioning between one value
  // and the next on a discrete slider.
  AnimationController positionController;
  Timer interactionTimer;

  @override
  void initState() {
    super.initState();
    overlayController = new AnimationController(
      duration: kRadialReactionDuration,
      vsync: this,
    );
    valueIndicatorController = new AnimationController(
      duration: valueIndicatorAnimationDuration,
      vsync: this,
    );
    enableController = new AnimationController(
      duration: enableAnimationDuration,
      vsync: this,
    );
    positionController = new AnimationController(
      duration: Duration.zero,
      vsync: this,
    );
    // Create timer in a cancelled state, so that we don't have to
    // check for null below.
    interactionTimer = new Timer(Duration.zero, () {});
    interactionTimer.cancel();
    enableController.value = widget.onChanged != null ? 1.0 : 0.0;
    positionController.value = _unlerp(widget.value);
  }

  @override
  void dispose() {
    overlayController.dispose();
    valueIndicatorController.dispose();
    enableController.dispose();
    positionController.dispose();
    interactionTimer?.cancel();
    super.dispose();
  }

  void _handleChanged(double value) {
    assert(widget.onChanged != null);
    final double lerpValue = _lerp(value);
    if (lerpValue != widget.value) {
      widget.onChanged(lerpValue);
    }
  }

  // Returns a number between min and max, proportional to value, which must
  // be between 0.0 and 1.0.
  double _lerp(double value) {
    assert(value >= 0.0);
    assert(value <= 1.0);
    return value * (widget.max - widget.min) + widget.min;
  }

  // Returns a number between 0.0 and 1.0, given a value between min and max.
  double _unlerp(double value) {
    assert(value <= widget.max);
    assert(value >= widget.min);
    return widget.max > widget.min ? (value - widget.min) / (widget.max - widget.min) : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMediaQuery(context));

    SliderThemeData sliderTheme = SliderTheme.of(context);

    // If the widget has active or inactive colors specified, then we plug them
    // in to the slider theme as best we can. If the developer wants more
    // control than that, then they need to use a SliderTheme.
    if (widget.activeColor != null || widget.inactiveColor != null) {
      sliderTheme = sliderTheme.copyWith(
        activeRailColor: widget.activeColor,
        inactiveRailColor: widget.inactiveColor,
        activeTickMarkColor: widget.inactiveColor,
        inactiveTickMarkColor: widget.activeColor,
        thumbColor: widget.activeColor,
        valueIndicatorColor: widget.activeColor,
        overlayColor: widget.activeColor?.withAlpha(0x29),
      );
    }

    return new _SliderRenderObjectWidget(
      value: _unlerp(widget.value),
      divisions: widget.divisions,
      label: widget.label,
      sliderTheme: sliderTheme,
      mediaQueryData: MediaQuery.of(context),
      onChanged: (widget.onChanged != null) && (widget.max > widget.min) ? _handleChanged : null,
      state: this,
    );
  }
}

class _SliderRenderObjectWidget extends LeafRenderObjectWidget {
  const _SliderRenderObjectWidget({
    Key key,
    this.value,
    this.divisions,
    this.label,
    this.sliderTheme,
    this.mediaQueryData,
    this.onChanged,
    this.state,
  }) : super(key: key);

  final double value;
  final int divisions;
  final String label;
  final SliderThemeData sliderTheme;
  final MediaQueryData mediaQueryData;
  final ValueChanged<double> onChanged;
  final _SliderState state;

  @override
  _RenderSlider createRenderObject(BuildContext context) {
    return new _RenderSlider(
      value: value,
      divisions: divisions,
      label: label,
      sliderTheme: sliderTheme,
      theme: Theme.of(context),
      mediaQueryData: mediaQueryData,
      onChanged: onChanged,
      state: state,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSlider renderObject) {
    renderObject
      ..value = value
      ..divisions = divisions
      ..label = label
      ..sliderTheme = sliderTheme
      ..theme = Theme.of(context)
      ..mediaQueryData = mediaQueryData
      ..onChanged = onChanged
      ..textDirection = Directionality.of(context);
    // Ticker provider cannot change since there's a 1:1 relationship between
    // the _SliderRenderObjectWidget object and the _SliderState object.
  }
}

class _RenderSlider extends RenderBox {
  _RenderSlider({
    @required double value,
    int divisions,
    String label,
    SliderThemeData sliderTheme,
    ThemeData theme,
    MediaQueryData mediaQueryData,
    ValueChanged<double> onChanged,
    @required _SliderState state,
    @required TextDirection textDirection,
  }) : assert(value != null && value >= 0.0 && value <= 1.0),
       assert(state != null),
       assert(textDirection != null),
       _label = label,
       _value = value,
       _divisions = divisions,
       _sliderTheme = sliderTheme,
       _theme = theme,
       _mediaQueryData = mediaQueryData,
       _onChanged = onChanged,
       _state = state,
       _textDirection = textDirection {
    _updateLabelPainter();
    final GestureArenaTeam team = new GestureArenaTeam();
    _drag = new HorizontalDragGestureRecognizer()
      ..team = team
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _endInteraction;
    _tap = new TapGestureRecognizer()
      ..team = team
      ..onTapDown = _handleTapDown
      ..onTapUp = _handleTapUp
      ..onTapCancel = _endInteraction;
    _overlayAnimation = new CurvedAnimation(
      parent: _state.overlayController,
      curve: Curves.fastOutSlowIn,
    );
    _valueIndicatorAnimation = new CurvedAnimation(
      parent: _state.valueIndicatorController,
      curve: Curves.fastOutSlowIn,
    );
    _enableAnimation = new CurvedAnimation(
      parent: _state.enableController,
      curve: Curves.easeInOut,
    );
  }

  static const Duration _positionAnimationDuration = const Duration(milliseconds: 75);
  static const double _overlayRadius = 16.0;
  static const double _overlayDiameter = _overlayRadius * 2.0;
  static const double _railHeight = 2.0;
  static const double _preferredRailWidth = 144.0;
  static const double _preferredTotalWidth = _preferredRailWidth + _overlayDiameter;
  static const Duration _minimumInteractionTime = const Duration(milliseconds: 500);
  static const double _adjustmentUnit = 0.1; // Matches iOS implementation of material slider.
  static final Tween<double> _overlayRadiusTween = new Tween<double>(begin: 0.0, end: _overlayRadius);

  _SliderState _state;
  Animation<double> _overlayAnimation;
  Animation<double> _valueIndicatorAnimation;
  Animation<double> _enableAnimation;
  final TextPainter _labelPainter = new TextPainter();
  HorizontalDragGestureRecognizer _drag;
  TapGestureRecognizer _tap;
  bool _active = false;
  double _currentDragValue = 0.0;

  double get _railLength => size.width - _overlayDiameter;

  bool get isInteractive => onChanged != null;

  bool get isDiscrete => divisions != null && divisions > 0;

  double get value => _value;
  double _value;
  set value(double newValue) {
    assert(newValue != null && newValue >= 0.0 && newValue <= 1.0);
    final double convertedValue = isDiscrete ? _discretize(newValue) : newValue;
    if (convertedValue == _value) {
      return;
    }
    _value = convertedValue;
    if (isDiscrete) {
      // Reset the duration to match the distance that we're traveling, so that
      // whatever the distance, we still do it in _positionAnimationDuration,
      // and if we get re-targeted in the middle, it still takes that long to
      // get to the new location.
      final double distance = (_value - _state.positionController.value).abs();
      _state.positionController.duration = distance != 0.0
        ? _positionAnimationDuration * (1.0 / distance)
        : 0.0;
      _state.positionController.animateTo(convertedValue, curve: Curves.easeInOut);
    } else {
      _state.positionController.value = convertedValue;
    }
  }

  int get divisions => _divisions;
  int _divisions;
  set divisions(int value) {
    if (value == _divisions) {
      return;
    }
    _divisions = value;
    markNeedsPaint();
  }

  String get label => _label;
  String _label;
  set label(String value) {
    if (value == _label) {
      return;
    }
    _label = value;
    _updateLabelPainter();
  }

  SliderThemeData get sliderTheme => _sliderTheme;
  SliderThemeData _sliderTheme;
  set sliderTheme(SliderThemeData value) {
    if (value == _sliderTheme) {
      return;
    }
    _sliderTheme = value;
    markNeedsPaint();
  }

  ThemeData get theme => _theme;
  ThemeData _theme;
  set theme(ThemeData value) {
    if (value == _theme) {
      return;
    }
    _theme = value;
    markNeedsPaint();
  }

  MediaQueryData get mediaQueryData => _mediaQueryData;
  MediaQueryData _mediaQueryData;
  set mediaQueryData(MediaQueryData value) {
    if (value == _mediaQueryData) {
      return;
    }
    _mediaQueryData = value;
    // Media query data includes the textScaleFactor, so we need to update the
    // label painter.
    _updateLabelPainter();
  }

  ValueChanged<double> get onChanged => _onChanged;
  ValueChanged<double> _onChanged;
  set onChanged(ValueChanged<double> value) {
    if (value == _onChanged) {
      return;
    }
    final bool wasInteractive = isInteractive;
    _onChanged = value;
    if (wasInteractive != isInteractive) {
      if (isInteractive) {
        _state.enableController.forward();
      } else {
        _state.enableController.reverse();
      }
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (value == _textDirection) {
      return;
    }
    _textDirection = value;
    _updateLabelPainter();
  }

  bool get showValueIndicator {
    bool showValueIndicator;
    switch (_sliderTheme.showValueIndicator) {
      case ShowValueIndicator.onlyForDiscrete:
        showValueIndicator = isDiscrete;
        break;
      case ShowValueIndicator.onlyForContinuous:
        showValueIndicator = !isDiscrete;
        break;
      case ShowValueIndicator.always:
        showValueIndicator = true;
        break;
      case ShowValueIndicator.never:
        showValueIndicator = false;
        break;
    }
    return showValueIndicator;
  }

  void _updateLabelPainter() {
    if (label != null) {
      _labelPainter
        ..text = new TextSpan(style: _theme.accentTextTheme.body2, text: label)
        ..textDirection = textDirection
        ..textScaleFactor = _mediaQueryData.textScaleFactor
        ..layout();
    } else {
      _labelPainter.text = null;
    }
    // Changing the textDirection can result in the layout changing, because the
    // bidi algorithm might line up the glyphs differently which can result in
    // different ligatures, different shapes, etc. So we always markNeedsLayout.
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _overlayAnimation.addListener(markNeedsPaint);
    _valueIndicatorAnimation.addListener(markNeedsPaint);
    _enableAnimation.addListener(markNeedsPaint);
    _state.positionController.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _overlayAnimation.removeListener(markNeedsPaint);
    _valueIndicatorAnimation.removeListener(markNeedsPaint);
    _enableAnimation.removeListener(markNeedsPaint);
    _state.positionController.removeListener(markNeedsPaint);
    super.detach();
  }

  double _getValueFromVisualPosition(double visualPosition) {
    switch (textDirection) {
      case TextDirection.rtl:
        return 1.0 - visualPosition;
      case TextDirection.ltr:
        return visualPosition;
    }
    return null;
  }

  double _getValueFromGlobalPosition(Offset globalPosition) {
    final double visualPosition = (globalToLocal(globalPosition).dx - _overlayRadius) / _railLength;
    return _getValueFromVisualPosition(visualPosition);
  }

  double _discretize(double value) {
    double result = value.clamp(0.0, 1.0);
    if (isDiscrete) {
      result = (result * divisions).round() / divisions;
    }
    return result;
  }

  void _startInteraction(Offset globalPosition) {
    if (isInteractive) {
      _active = true;
      _currentDragValue = _getValueFromGlobalPosition(globalPosition);
      onChanged(_discretize(_currentDragValue));
      _state.overlayController.forward();
      if (showValueIndicator) {
        _state.valueIndicatorController.forward();
        if (_state.interactionTimer.isActive) {
          _state.interactionTimer.cancel();
        }
        _state.interactionTimer = new Timer(_minimumInteractionTime * timeDilation, () {
          if (!_active && _state.valueIndicatorController.status == AnimationStatus.completed) {
            _state.valueIndicatorController.reverse();
          }
          _state.interactionTimer.cancel();
        });
      }
    }
  }

  void _endInteraction() {
    if (_active) {
      _active = false;
      _currentDragValue = 0.0;
      _state.overlayController.reverse();
      if (showValueIndicator && !_state.interactionTimer.isActive) {
        _state.valueIndicatorController.reverse();
      }
    }
  }

  void _handleDragStart(DragStartDetails details) => _startInteraction(details.globalPosition);

  void _handleDragUpdate(DragUpdateDetails details) {
    if (isInteractive) {
      final double valueDelta = details.primaryDelta / _railLength;
      switch (textDirection) {
        case TextDirection.rtl:
          _currentDragValue -= valueDelta;
          break;
        case TextDirection.ltr:
          _currentDragValue += valueDelta;
          break;
      }
      onChanged(_discretize(_currentDragValue));
    }
  }

  void _handleDragEnd(DragEndDetails details) => _endInteraction();

  void _handleTapDown(TapDownDetails details) => _startInteraction(details.globalPosition);

  void _handleTapUp(TapUpDetails details) => _endInteraction();

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && isInteractive) {
      // We need to add the drag first so that it has priority.
      _drag.addPointer(event);
      _tap.addPointer(event);
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return math.max(
      _overlayDiameter,
      _sliderTheme.thumbShape.getPreferredSize(isInteractive, isDiscrete).width,
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    // This doesn't quite match the definition of computeMaxIntrinsicWidth,
    // but it seems within the spirit...
    return _preferredTotalWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _overlayDiameter;

  @override
  double computeMaxIntrinsicHeight(double width) => _overlayDiameter;

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = new Size(
      constraints.hasBoundedWidth ? constraints.maxWidth : _preferredTotalWidth,
      constraints.hasBoundedHeight ? constraints.maxHeight : _overlayDiameter,
    );
  }

  void _paintTickMarks(
    Canvas canvas,
    Rect railLeft,
    Rect railRight,
    Paint leftPaint,
    Paint rightPaint,
  ) {
    if (isDiscrete) {
      // The ticks are tiny circles that are the same height as the rail.
      const double tickRadius = _railHeight / 2.0;
      final double railWidth = railRight.right - railLeft.left;
      final double dx = (railWidth - _railHeight) / divisions;
      // If the ticks would be too dense, don't bother painting them.
      if (dx >= 3.0 * _railHeight) {
        for (int i = 0; i <= divisions; i += 1) {
          final double left = railLeft.left + i * dx;
          final Offset center = new Offset(left + tickRadius, railLeft.top + tickRadius);
          if (railLeft.contains(center)) {
            canvas.drawCircle(center, tickRadius, leftPaint);
          } else if (railRight.contains(center)) {
            canvas.drawCircle(center, tickRadius, rightPaint);
          }
        }
      }
    }
  }

  void _paintOverlay(Canvas canvas, Offset center) {
    if (!_overlayAnimation.isDismissed) {
      // TODO(gspencer) : We don't really follow the spec here for overlays.
      // The spec says to use 16% opacity for drawing over light material,
      // and 32% for colored material, but we don't really have a way to
      // know what the underlying color is, so there's no easy way to
      // implement this. Choosing the "light" version for now.
      final Paint overlayPaint = new Paint()..color = _sliderTheme.overlayColor;
      final double radius = _overlayRadiusTween.evaluate(_overlayAnimation);
      canvas.drawCircle(center, radius, overlayPaint);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    final double railLength = size.width - 2 * _overlayRadius;
    final double value = _state.positionController.value;
    final ColorTween activeRailEnableColor = new ColorTween(begin: _sliderTheme.disabledActiveRailColor, end: _sliderTheme.activeRailColor);
    final ColorTween inactiveRailEnableColor = new ColorTween(begin: _sliderTheme.disabledInactiveRailColor, end: _sliderTheme.inactiveRailColor);
    final ColorTween activeTickMarkEnableColor = new ColorTween(begin: _sliderTheme.disabledActiveTickMarkColor, end: _sliderTheme.activeTickMarkColor);
    final ColorTween inactiveTickMarkEnableColor = new ColorTween(begin: _sliderTheme.disabledInactiveTickMarkColor, end: _sliderTheme.inactiveTickMarkColor);

    final Paint activeRailPaint = new Paint()..color = activeRailEnableColor.evaluate(_enableAnimation);
    final Paint inactiveRailPaint = new Paint()..color = inactiveRailEnableColor.evaluate(_enableAnimation);
    final Paint activeTickMarkPaint = new Paint()..color = activeTickMarkEnableColor.evaluate(_enableAnimation);
    final Paint inactiveTickMarkPaint = new Paint()..color = inactiveTickMarkEnableColor.evaluate(_enableAnimation);

    double visualPosition;
    Paint leftRailPaint;
    Paint rightRailPaint;
    Paint leftTickMarkPaint;
    Paint rightTickMarkPaint;
    switch (textDirection) {
      case TextDirection.rtl:
        visualPosition = 1.0 - value;
        leftRailPaint = inactiveRailPaint;
        rightRailPaint = activeRailPaint;
        leftTickMarkPaint = inactiveTickMarkPaint;
        rightTickMarkPaint = activeTickMarkPaint;
        break;
      case TextDirection.ltr:
        visualPosition = value;
        leftRailPaint = activeRailPaint;
        rightRailPaint = inactiveRailPaint;
        leftTickMarkPaint = activeTickMarkPaint;
        rightTickMarkPaint = inactiveTickMarkPaint;
        break;
    }

    const double railRadius = _railHeight / 2.0;
    const double thumbGap = 2.0;

    final double railVerticalCenter = offset.dy + (size.height) / 2.0;
    final double railLeft = offset.dx + _overlayRadius;
    final double railTop = railVerticalCenter - railRadius;
    final double railBottom = railVerticalCenter + railRadius;
    final double railRight = railLeft + railLength;
    final double railActive = railLeft + railLength * visualPosition;
    final double thumbRadius = _sliderTheme.thumbShape.getPreferredSize(isInteractive, isDiscrete).width / 2.0;
    final double railActiveLeft = math.max(0.0, railActive - thumbRadius - thumbGap * (1.0 - _enableAnimation.value));
    final double railActiveRight = math.min(railActive + thumbRadius + thumbGap * (1.0 - _enableAnimation.value), railRight);
    final Rect railLeftRect = new Rect.fromLTRB(railLeft, railTop, railActiveLeft, railBottom);
    final Rect railRightRect = new Rect.fromLTRB(railActiveRight, railTop, railRight, railBottom);

    final Offset thumbCenter = new Offset(railActive, railVerticalCenter);

    // Paint the rail.
    if (visualPosition > 0.0) {
      canvas.drawRect(railLeftRect, leftRailPaint);
    }
    if (visualPosition < 1.0) {
      canvas.drawRect(railRightRect, rightRailPaint);
    }

    _paintOverlay(canvas, thumbCenter);

    _paintTickMarks(
      canvas,
      railLeftRect,
      railRightRect,
      leftTickMarkPaint,
      rightTickMarkPaint,
    );

    if (isInteractive && label != null &&
        _valueIndicatorAnimation.status != AnimationStatus.dismissed) {
      if (showValueIndicator) {
        _sliderTheme.valueIndicatorShape.paint(
          this,
          context,
          isDiscrete,
          thumbCenter,
          _valueIndicatorAnimation,
          _enableAnimation,
          _labelPainter,
          _sliderTheme,
          _textDirection,
          value,
        );
      }
    }

    _sliderTheme.thumbShape.paint(
      this,
      context,
      isDiscrete,
      thumbCenter,
      _overlayAnimation,
      _enableAnimation,
      label != null ? _labelPainter : null,
      _sliderTheme,
      _textDirection,
      value,
    );
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config.isSemanticBoundary = isInteractive;
    if (isInteractive) {
      config.onIncrease = _increaseAction;
      config.onDecrease = _decreaseAction;
    }
  }

  double get _semanticActionUnit => divisions != null ? 1.0 / divisions : _adjustmentUnit;

  void _increaseAction() {
    if (isInteractive) {
      onChanged((value + _semanticActionUnit).clamp(0.0, 1.0));
    }
  }

  void _decreaseAction() {
    if (isInteractive) {
      onChanged((value - _semanticActionUnit).clamp(0.0, 1.0));
    }
  }
}
