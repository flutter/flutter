// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'thumb_painter.dart';

/// An iOS-style switch.
///
/// Used to toggle the on/off state of a single setting.
///
/// The switch itself does not maintain any state. Instead, when the state of
/// the switch changes, the widget calls the [onChanged] callback. Most widgets
/// that use a switch will listen for the [onChanged] callback and rebuild the
/// switch with a new [value] to update the visual appearance of the switch.
///
/// ## Sample code
///
/// This sample shows how to use a [CupertinoSwitch] in a [ListTile]. The
/// [MergeSemantics] is used to turn the entire [ListTile] into a single item
/// for accessibility tools.
///
/// ```dart
/// new MergeSemantics(
///   child: new ListTile(
///     title: new Text('Lights'),
///     trailing: new CupertinoSwitch(
///       value: _lights,
///       onChanged: (bool value) { setState(() { _lights = value; }); },
///     ),
///     onTap: () { setState(() { _lights = !_lights; }); },
///   ),
/// )
/// ```
///
/// See also:
///
///  * [Switch], the material design equivalent.
///  * <https://developer.apple.com/ios/human-interface-guidelines/ui-controls/switches/>
class CupertinoSwitch extends StatefulWidget {
  /// Creates an iOS-style switch.
  const CupertinoSwitch({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.activeColor: CupertinoColors.activeGreen,
  }) : super(key: key);

  /// Whether this switch is on or off.
  final bool value;

  /// Called when the user toggles with switch on or off.
  ///
  /// The switch passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the switch with the new
  /// value.
  ///
  /// If null, the switch will be displayed as disabled.
  ///
  /// The callback provided to onChanged should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt; for example:
  ///
  /// ```dart
  /// new CupertinoSwitch(
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
  final Color activeColor;

  @override
  _CupertinoSwitchState createState() => new _CupertinoSwitchState();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('value: ${value ? "on" : "off"}');
    if (onChanged == null)
      description.add('disabled');
  }
}

class _CupertinoSwitchState extends State<CupertinoSwitch> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return new _CupertinoSwitchRenderObjectWidget(
      value: widget.value,
      activeColor: widget.activeColor,
      onChanged: widget.onChanged,
      vsync: this,
    );
  }
}

class _CupertinoSwitchRenderObjectWidget extends LeafRenderObjectWidget {
  const _CupertinoSwitchRenderObjectWidget({
    Key key,
    this.value,
    this.activeColor,
    this.onChanged,
    this.vsync,
  }) : super(key: key);

  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;
  final TickerProvider vsync;

  @override
  _RenderCupertinoSwitch createRenderObject(BuildContext context) {
    return new _RenderCupertinoSwitch(
      value: value,
      activeColor: activeColor,
      onChanged: onChanged,
      vsync: vsync,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderCupertinoSwitch renderObject) {
    renderObject
      ..value = value
      ..activeColor = activeColor
      ..onChanged = onChanged
      ..vsync = vsync;
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

const Color _kTrackColor = CupertinoColors.lightBackgroundGray;
const Duration _kReactionDuration = const Duration(milliseconds: 300);
const Duration _kToggleDuration = const Duration(milliseconds: 200);

class _RenderCupertinoSwitch extends RenderConstrainedBox implements SemanticsActionHandler {
  _RenderCupertinoSwitch({
    @required bool value,
    @required Color activeColor,
    ValueChanged<bool> onChanged,
    @required TickerProvider vsync,
  }) : assert(value != null),
       assert(activeColor != null),
       assert(vsync != null),
       _value = value,
       _activeColor = activeColor,
       _onChanged = onChanged,
       _vsync = vsync,
       super(additionalConstraints: const BoxConstraints.tightFor(width: _kSwitchWidth, height: _kSwitchHeight)) {
    _tap = new TapGestureRecognizer()
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap
      ..onTapUp = _handleTapUp
      ..onTapCancel = _handleTapCancel;
    _drag = new HorizontalDragGestureRecognizer()
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd;
    _positionController = new AnimationController(
      duration: _kToggleDuration,
      value: value ? 1.0 : 0.0,
      vsync: vsync,
    );
    _position = new CurvedAnimation(
      parent: _positionController,
      curve: Curves.linear,
    )..addListener(markNeedsPaint)
     ..addStatusListener(_handlePositionStateChanged);
    _reactionController = new AnimationController(
      duration: _kReactionDuration,
      vsync: vsync,
    );
    _reaction = new CurvedAnimation(
      parent: _reactionController,
      curve: Curves.ease,
    )..addListener(markNeedsPaint);
  }

  AnimationController _positionController;
  CurvedAnimation _position;

  AnimationController _reactionController;
  Animation<double> _reaction;

  bool get value => _value;
  bool _value;
  set value(bool value) {
    assert(value != null);
    if (value == _value)
      return;
    _value = value;
    markNeedsSemanticsUpdate(onlyChanges: true, noGeometry: true);
    _position
      ..curve = Curves.ease
      ..reverseCurve = Curves.ease.flipped;
    if (value)
      _positionController.forward();
    else
      _positionController.reverse();
  }

  TickerProvider get vsync => _vsync;
  TickerProvider _vsync;
  set vsync(TickerProvider value) {
    assert(value != null);
    if (value == _vsync)
      return;
    _vsync = value;
    _positionController.resync(vsync);
    _reactionController.resync(vsync);
  }

  Color get activeColor => _activeColor;
  Color _activeColor;
  set activeColor(Color value) {
    assert(value != null);
    if (value == _activeColor)
      return;
    _activeColor = value;
    markNeedsPaint();
  }

  ValueChanged<bool> get onChanged => _onChanged;
  ValueChanged<bool> _onChanged;
  set onChanged(ValueChanged<bool> value) {
    if (value == _onChanged)
      return;
    final bool wasInteractive = isInteractive;
    _onChanged = value;
    if (wasInteractive != isInteractive) {
      markNeedsPaint();
      markNeedsSemanticsUpdate(noGeometry: true);
    }
  }

  bool get isInteractive => onChanged != null;

  TapGestureRecognizer _tap;
  HorizontalDragGestureRecognizer _drag;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (value)
      _positionController.forward();
    else
      _positionController.reverse();
    if (isInteractive) {
      switch (_reactionController.status) {
        case AnimationStatus.forward:
          _reactionController.forward();
          break;
        case AnimationStatus.reverse:
          _reactionController.reverse();
          break;
        case AnimationStatus.dismissed:
        case AnimationStatus.completed:
          // nothing to do
          break;
      }
    }
  }

  @override
  void detach() {
    _positionController.stop();
    _reactionController.stop();
    super.detach();
  }

  void _handlePositionStateChanged(AnimationStatus status) {
    if (isInteractive) {
      if (status == AnimationStatus.completed && !_value)
        onChanged(true);
      else if (status == AnimationStatus.dismissed && _value)
        onChanged(false);
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (isInteractive)
      _reactionController.forward();
  }

  void _handleTap() {
    if (isInteractive)
      onChanged(!_value);
  }

  void _handleTapUp(TapUpDetails details) {
    if (isInteractive)
      _reactionController.reverse();
  }

  void _handleTapCancel() {
    if (isInteractive)
      _reactionController.reverse();
  }

  void _handleDragStart(DragStartDetails details) {
    if (isInteractive)
      _reactionController.forward();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (isInteractive) {
      _position
        ..curve = null
        ..reverseCurve = null;
      _positionController.value += details.primaryDelta / _kTrackInnerLength;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_position.value >= 0.5)
      _positionController.forward();
    else
      _positionController.reverse();
    _reactionController.reverse();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && isInteractive) {
      _drag.addPointer(event);
      _tap.addPointer(event);
    }
  }

  @override
  bool get isSemanticBoundary => isInteractive;

  @override
  SemanticsAnnotator get semanticsAnnotator => _annotate;

  void _annotate(SemanticsNode semantics) {
    semantics
      ..hasCheckedState = true
      ..isChecked = _value;
    if (isInteractive)
      semantics.addAction(SemanticsAction.tap);
  }

  @override
  void performAction(SemanticsAction action) {
    if (action == SemanticsAction.tap)
      _handleTap();
  }

  final CupertinoThumbPainter _thumbPainter = new CupertinoThumbPainter();

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    final double currentPosition = _position.value;
    final double currentReactionValue = _reaction.value;

    final Color trackColor = _value ? activeColor : _kTrackColor;
    final double borderThickness = 1.5 + (_kTrackRadius - 1.5) * math.max(currentReactionValue, currentPosition);

    final Paint paint = new Paint()
      ..color = trackColor;

    final Rect trackRect = new Rect.fromLTWH(
        offset.dx + (size.width - _kTrackWidth) / 2.0,
        offset.dy + (size.height - _kTrackHeight) / 2.0,
        _kTrackWidth,
        _kTrackHeight
    );
    final RRect outerRRect = new RRect.fromRectAndRadius(trackRect, const Radius.circular(_kTrackRadius));
    final RRect innerRRect = new RRect.fromRectAndRadius(trackRect.deflate(borderThickness), const Radius.circular(_kTrackRadius));
    canvas.drawDRRect(outerRRect, innerRRect, paint);

    final double currentThumbExtension = CupertinoThumbPainter.extension * currentReactionValue;
    final double thumbLeft = lerpDouble(
      trackRect.left + _kTrackInnerStart - CupertinoThumbPainter.radius,
      trackRect.left + _kTrackInnerEnd - CupertinoThumbPainter.radius - currentThumbExtension,
      currentPosition,
    );
    final double thumbRight = lerpDouble(
      trackRect.left + _kTrackInnerStart + CupertinoThumbPainter.radius + currentThumbExtension,
      trackRect.left + _kTrackInnerEnd + CupertinoThumbPainter.radius,
      currentPosition,
    );
    final double thumbCenterY = offset.dy + size.height / 2.0;

    _thumbPainter.paint(canvas, new Rect.fromLTRB(
      thumbLeft,
      thumbCenterY - CupertinoThumbPainter.radius,
      thumbRight,
      thumbCenterY + CupertinoThumbPainter.radius,
    ));
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('value: ${value ? "checked" : "unchecked"}');
    if (!isInteractive)
      description.add('disabled');
  }
}
