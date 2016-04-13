// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'constants.dart';

const Duration _kToggleDuration = const Duration(milliseconds: 200);
final Tween<double> _kRadialReactionRadiusTween = new Tween<double>(begin: 0.0, end: kRadialReactionRadius);

// RenderToggleable is a base class for material style toggleable controls with
// toggle animations. It handles storing the current value, dispatching
// ValueChanged on a tap gesture and driving a changed animation. Subclasses are
// responsible for painting.
abstract class RenderToggleable extends RenderConstrainedBox implements SemanticActionHandler {
  RenderToggleable({
    bool value,
    Size size,
    Color activeColor,
    Color inactiveColor,
    ValueChanged<bool> onChanged
  }) : _value = value,
       _activeColor = activeColor,
       _inactiveColor = inactiveColor,
       _onChanged = onChanged,
       super(additionalConstraints: new BoxConstraints.tight(size)) {
    assert(value != null);
    assert(activeColor != null);
    assert(inactiveColor != null);
    _tap = new TapGestureRecognizer()
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap
      ..onTapUp = _handleTapUp
      ..onTapCancel = _handleTapCancel;

    _positionController = new AnimationController(
      duration: _kToggleDuration,
      value: _value ? 1.0 : 0.0
    );
    _position = new CurvedAnimation(
      parent: _positionController
    )..addListener(markNeedsPaint)
     ..addStatusListener(_handlePositionStateChanged);

    _reactionController = new AnimationController(duration: kRadialReactionDuration);
    _reaction = new CurvedAnimation(
      parent: _reactionController,
      curve: Curves.ease
    )..addListener(markNeedsPaint);
  }

  bool get value => _value;
  bool _value;
  void set value(bool value) {
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

  Color get activeColor => _activeColor;
  Color _activeColor;
  void set activeColor(Color value) {
    assert(value != null);
    if (value == _activeColor)
      return;
    _activeColor = value;
    markNeedsPaint();
  }

  Color get inactiveColor => _inactiveColor;
  Color _inactiveColor;
  void set inactiveColor(Color value) {
    assert(value != null);
    if (value == _inactiveColor)
      return;
    _inactiveColor = value;
    markNeedsPaint();
  }

  ValueChanged<bool> get onChanged => _onChanged;
  ValueChanged<bool> _onChanged;
  void set onChanged(ValueChanged<bool> value) {
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

  CurvedAnimation get position => _position;
  CurvedAnimation _position;

  AnimationController get positionController => _positionController;
  AnimationController _positionController;

  AnimationController get reactionController => _reactionController;
  AnimationController _reactionController;
  Animation<double> _reaction;

  TapGestureRecognizer _tap;
  Point _downPosition;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_positionController != null) {
      if (value)
        _positionController.forward();
      else
        _positionController.reverse();
    }
    if (_reactionController != null && isInteractive) {
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
    _positionController?.stop();
    _reactionController?.stop();
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

  void _handleTapDown(Point globalPosition) {
    if (isInteractive) {
      _downPosition = globalToLocal(globalPosition);
      _reactionController.forward();
    }
  }

  void _handleTap() {
    if (isInteractive)
      onChanged(!_value);
  }

  void _handleTapUp(Point globalPosition) {
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
  bool hitTestSelf(Point position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent && isInteractive)
      _tap.addPointer(event);
  }

  void paintRadialReaction(Canvas canvas, Offset offset, Point origin) {
    if (!_reaction.isDismissed) {
      // TODO(abarth): We should have a different reaction color when position is zero.
      Paint reactionPaint = new Paint()..color = activeColor.withAlpha(kRadialReactionAlpha);
      Point center = Point.lerp(_downPosition ?? origin, origin, _reaction.value);
      double radius = _kRadialReactionRadiusTween.evaluate(_reaction);
      canvas.drawCircle(center + offset, radius, reactionPaint);
    }
  }

  @override
  bool get hasSemantics => isInteractive;

  @override
  Iterable<SemanticAnnotator> getSemanticAnnotators() sync* {
    yield (SemanticsNode semantics) {
      semantics.hasCheckedState = true;
      semantics.isChecked = _value;
      semantics.canBeTapped = isInteractive;
    };
  }

  @override
  void handleSemanticTap() => _handleTap();

  @override
  void handleSemanticLongPress() { }

  @override
  void handleSemanticScrollLeft() { }

  @override
  void handleSemanticScrollRight() { }

  @override
  void handleSemanticScrollUp() { }

  @override
  void handleSemanticScrollDown() { }
}
