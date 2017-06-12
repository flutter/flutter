// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'constants.dart';

const Duration _kToggleDuration = const Duration(milliseconds: 200);
final Tween<double> _kRadialReactionRadiusTween = new Tween<double>(begin: 0.0, end: kRadialReactionRadius);

/// A base class for material style toggleable controls with toggle animations.
///
/// This class handles storing the current value, dispatching ValueChanged on a
/// tap gesture and driving a changed animation. Subclasses are responsible for
/// painting.
abstract class RenderToggleable extends RenderConstrainedBox implements SemanticsActionHandler {
  /// Creates a toggleable render object.
  ///
  /// The [value], [activeColor], and [inactiveColor] arguments must not be
  /// null.
  RenderToggleable({
    @required bool value,
    Size size,
    @required Color activeColor,
    @required Color inactiveColor,
    ValueChanged<bool> onChanged,
    @required TickerProvider vsync,
  }) : _value = value,
       _activeColor = activeColor,
       _inactiveColor = inactiveColor,
       _onChanged = onChanged,
       _vsync = vsync,
       super(additionalConstraints: new BoxConstraints.tight(size)) {
    assert(value != null);
    assert(activeColor != null);
    assert(inactiveColor != null);
    assert(vsync != null);
    _tap = new TapGestureRecognizer()
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap
      ..onTapUp = _handleTapUp
      ..onTapCancel = _handleTapCancel;
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
      duration: kRadialReactionDuration,
      vsync: vsync,
    );
    _reaction = new CurvedAnimation(
      parent: _reactionController,
      curve: Curves.fastOutSlowIn,
    )..addListener(markNeedsPaint);
  }

  /// Used by subclasses to manipulate the visual value of the control.
  ///
  /// Some controls respond to user input by updating their visual value. For
  /// example, the thumb of a switch moves from one position to another when
  /// dragged. These controls manipulate this animation controller to update
  /// their [position] and eventually trigger an [onChanged] callback when the
  /// animation reaches either 0.0 or 1.0.
  @protected
  AnimationController get positionController => _positionController;
  AnimationController _positionController;

  /// The visual value of the control.
  ///
  /// When the control is inactive, the [value] is false and this animation has
  /// the value 0.0. When the control is active, the value is true and this
  /// animation has the value 1.0. When the control is changing from inactive
  /// to active (or vice versa), [value] is the target value and this animation
  /// gradually updates from 0.0 to 1.0 (or vice versa).
  CurvedAnimation get position => _position;
  CurvedAnimation _position;

  /// Used by subclasses to control the radial reaction animation.
  ///
  /// Some controls have a radial ink reaction to user input. This animation
  /// controller can be used to start or stop these ink reactions.
  ///
  /// Subclasses should call [paintRadialReaction] to actually paint the radial
  /// reaction.
  @protected
  AnimationController get reactionController => _reactionController;
  AnimationController _reactionController;
  Animation<double> _reaction;

  /// The [TickerProvider] for the [AnimationController]s that run the animations.
  TickerProvider get vsync => _vsync;
  TickerProvider _vsync;
  set vsync(TickerProvider value) {
    assert(value != null);
    if (value == _vsync)
      return;
    _vsync = value;
    positionController.resync(vsync);
    reactionController.resync(vsync);
  }

  /// Whether this control is current "active" (checked, on, selected) or "inactive" (unchecked, off, not selected).
  ///
  /// When the value changes, this object starts the [positionController] and
  /// [position] animations to animate the visual appearance of the control to
  /// the new value.
  bool get value => _value;
  bool _value;
  set value(bool value) {
    assert(value != null);
    if (value == _value)
      return;
    _value = value;
    markNeedsSemanticsUpdate(onlyChanges: true, noGeometry: true);
    _position
      ..curve = Curves.easeIn
      ..reverseCurve = Curves.easeOut;
    if (value)
      _positionController.forward();
    else
      _positionController.reverse();
  }

  /// The color that should be used in the active state (i.e., when [value] is true).
  ///
  /// For example, a checkbox should use this color when checked.
  Color get activeColor => _activeColor;
  Color _activeColor;
  set activeColor(Color value) {
    assert(value != null);
    if (value == _activeColor)
      return;
    _activeColor = value;
    markNeedsPaint();
  }

  /// The color that should be used in the inactive state (i.e., when [value] is false).
  ///
  /// For example, a checkbox should use this color when unchecked.
  Color get inactiveColor => _inactiveColor;
  Color _inactiveColor;
  set inactiveColor(Color value) {
    assert(value != null);
    if (value == _inactiveColor)
      return;
    _inactiveColor = value;
    markNeedsPaint();
  }

  /// Called when the control changes value.
  ///
  /// If the control is tapped, [onChanged] is called immediately with the new
  /// value. If the control changes value due to an animation (see
  /// [positionController]), the callback is called when the animation
  /// completes.
  ///
  /// The control is considered interactive (see [isInteractive]) if this
  /// callback is non-null. If the callback is null, then the control is
  /// disabled, and non-interactive. A disabled checkbox, for example, is
  /// displayed using a grey color and its value cannot be changed.
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

  /// Whether [value] of this control can be changed by user interaction.
  ///
  /// The control is considered interactive if the [onChanged] callback is
  /// non-null. If the callback is null, then the control is disabled, and
  /// non-interactive. A disabled checkbox, for example, is displayed using a
  /// grey color and its value cannot be changed.
  bool get isInteractive => onChanged != null;

  TapGestureRecognizer _tap;
  Offset _downPosition;

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
    if (isInteractive) {
      _downPosition = globalToLocal(details.globalPosition);
      _reactionController.forward();
    }
  }

  void _handleTap() {
    if (isInteractive)
      onChanged(!_value);
  }

  void _handleTapUp(TapUpDetails details) {
    _downPosition = null;
    if (isInteractive)
      _reactionController.reverse();
  }

  void _handleTapCancel() {
    _downPosition = null;
    if (isInteractive)
      _reactionController.reverse();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && isInteractive)
      _tap.addPointer(event);
  }

  /// Used by subclasses to paint the radial ink reaction for this control.
  ///
  /// The reaction is painted on the given canvas at the given offset. The
  /// origin is the center point of the reaction (usually distinct from the
  /// point at which the user interacted with the control, which is handled
  /// automatically).
  void paintRadialReaction(Canvas canvas, Offset offset, Offset origin) {
    if (!_reaction.isDismissed) {
      // TODO(abarth): We should have a different reaction color when position is zero.
      final Paint reactionPaint = new Paint()..color = activeColor.withAlpha(kRadialReactionAlpha);
      final Offset center = Offset.lerp(_downPosition ?? origin, origin, _reaction.value);
      final double radius = _kRadialReactionRadiusTween.evaluate(_reaction);
      canvas.drawCircle(center + offset, radius, reactionPaint);
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

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('value: ${value ? "checked" : "unchecked"}');
    if (!isInteractive)
      description.add('disabled');
  }
}
