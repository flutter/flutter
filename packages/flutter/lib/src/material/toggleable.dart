// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'constants.dart';

// Duration of the animation that moves the toggle from one state to another.
const Duration _kToggleDuration = Duration(milliseconds: 200);

// Radius of the radial reaction over time.
final Animatable<double> _kRadialReactionRadiusTween = Tween<double>(begin: 0.0, end: kRadialReactionRadius);

// Duration of the fade animation for the reaction when focus and hover occur.
const Duration _kReactionFadeDuration = Duration(milliseconds: 50);

/// A base class for material style toggleable controls with toggle animations.
///
/// This class handles storing the current value, dispatching ValueChanged on a
/// tap gesture and driving a changed animation. Subclasses are responsible for
/// painting.
abstract class RenderToggleable extends RenderConstrainedBox {
  /// Creates a toggleable render object.
  ///
  /// The [activeColor], and [inactiveColor] arguments must not be
  /// null. The [value] can only be null if tristate is true.
  RenderToggleable({
    @required bool value,
    bool tristate = false,
    @required Color activeColor,
    @required Color inactiveColor,
    Color hoverColor,
    Color focusColor,
    ValueChanged<bool> onChanged,
    BoxConstraints additionalConstraints,
    @required TickerProvider vsync,
    bool hasFocus = false,
    bool hovering = false,
  }) : assert(tristate != null),
       assert(tristate || value != null),
       assert(activeColor != null),
       assert(inactiveColor != null),
       assert(vsync != null),
       _value = value,
       _tristate = tristate,
       _activeColor = activeColor,
       _inactiveColor = inactiveColor,
       _hoverColor = hoverColor ?? activeColor.withAlpha(kRadialReactionAlpha),
       _focusColor = focusColor ?? activeColor.withAlpha(kRadialReactionAlpha),
       _onChanged = onChanged,
       _hasFocus = hasFocus,
       _hovering = hovering,
       _vsync = vsync,
       super(additionalConstraints: additionalConstraints) {
    _tap = TapGestureRecognizer()
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap
      ..onTapUp = _handleTapUp
      ..onTapCancel = _handleTapCancel;
    _positionController = AnimationController(
      duration: _kToggleDuration,
      value: value == false ? 0.0 : 1.0,
      vsync: vsync,
    );
    _position = CurvedAnimation(
      parent: _positionController,
      curve: Curves.linear,
    )..addListener(markNeedsPaint);
    _reactionController = AnimationController(
      duration: kRadialReactionDuration,
      vsync: vsync,
    );
    _reaction = CurvedAnimation(
      parent: _reactionController,
      curve: Curves.fastOutSlowIn,
    )..addListener(markNeedsPaint);
    _reactionHoverFadeController = AnimationController(
      duration: _kReactionFadeDuration,
      value: hovering || hasFocus ? 1.0 : 0.0,
      vsync: vsync,
    );
    _reactionHoverFade = CurvedAnimation(
      parent: _reactionHoverFadeController,
      curve: Curves.fastOutSlowIn,
    )..addListener(markNeedsPaint);
    _reactionFocusFadeController = AnimationController(
      duration: _kReactionFadeDuration,
      value: hovering || hasFocus ? 1.0 : 0.0,
      vsync: vsync,
    );
    _reactionFocusFade = CurvedAnimation(
      parent: _reactionFocusFadeController,
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
  /// the value 0.0. When the control is active, the value either true or tristate
  /// is true and the value is null. When the control is active the animation
  /// has a value of 1.0. When the control is changing from inactive
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

  /// Used by subclasses to control the radial reaction's opacity animation for
  /// [hasFocus] changes.
  ///
  /// Some controls have a radial ink reaction to focus. This animation
  /// controller can be used to start or stop these ink reaction fade-ins and
  /// fade-outs.
  ///
  /// Subclasses should call [paintRadialReaction] to actually paint the radial
  /// reaction.
  @protected
  AnimationController get reactionFocusFadeController => _reactionFocusFadeController;
  AnimationController _reactionFocusFadeController;
  Animation<double> _reactionFocusFade;

  /// Used by subclasses to control the radial reaction's opacity animation for
  /// [hovering] changes.
  ///
  /// Some controls have a radial ink reaction to pointer hover. This animation
  /// controller can be used to start or stop these ink reaction fade-ins and
  /// fade-outs.
  ///
  /// Subclasses should call [paintRadialReaction] to actually paint the radial
  /// reaction.
  @protected
  AnimationController get reactionHoverFadeController => _reactionHoverFadeController;
  AnimationController _reactionHoverFadeController;
  Animation<double> _reactionHoverFade;

  /// True if this toggleable has the input focus.
  bool get hasFocus => _hasFocus;
  bool _hasFocus;
  set hasFocus(bool value) {
    assert(value != null);
    if (value == _hasFocus)
      return;
    _hasFocus = value;
    if (_hasFocus) {
      _reactionFocusFadeController.forward();
    } else {
      _reactionFocusFadeController.reverse();
    }
    markNeedsPaint();
  }

  /// True if this toggleable is being hovered over by a pointer.
  bool get hovering => _hovering;
  bool _hovering;
  set hovering(bool value) {
    assert(value != null);
    if (value == _hovering)
      return;
    _hovering = value;
    if (_hovering) {
      _reactionHoverFadeController.forward();
    } else {
      _reactionHoverFadeController.reverse();
    }
    markNeedsPaint();
  }

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

  /// False if this control is "inactive" (not checked, off, or unselected).
  ///
  /// If value is true then the control "active" (checked, on, or selected). If
  /// tristate is true and value is null, then the control is considered to be
  /// in its third or "indeterminate" state.
  ///
  /// When the value changes, this object starts the [positionController] and
  /// [position] animations to animate the visual appearance of the control to
  /// the new value.
  bool get value => _value;
  bool _value;
  set value(bool value) {
    assert(tristate || value != null);
    if (value == _value)
      return;
    _value = value;
    markNeedsSemanticsUpdate();
    _position
      ..curve = Curves.easeIn
      ..reverseCurve = Curves.easeOut;
    if (tristate) {
      switch (_positionController.status) {
        case AnimationStatus.forward:
        case AnimationStatus.completed:
          _positionController.reverse();
          break;
        default:
          _positionController.forward();
      }
    } else {
      if (value == true)
        _positionController.forward();
      else
        _positionController.reverse();
    }
  }

  /// If true, [value] can be true, false, or null, otherwise [value] must
  /// be true or false.
  ///
  /// When [tristate] is true and [value] is null, then the control is
  /// considered to be in its third or "indeterminate" state.
  bool get tristate => _tristate;
  bool _tristate;
  set tristate(bool value) {
    assert(tristate != null);
    if (value == _tristate)
      return;
    _tristate = value;
    markNeedsSemanticsUpdate();
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

  /// The color that should be used for the reaction when [hovering] is true.
  ///
  /// Used when the toggleable needs to change the reaction color/transparency,
  /// when it is being hovered over.
  ///
  /// Defaults to the [activeColor] at alpha [kRadialReactionAlpha].
  Color get hoverColor => _hoverColor;
  Color _hoverColor;
  set hoverColor(Color value) {
    assert(value != null);
    if (value == _hoverColor)
      return;
    _hoverColor = value;
    markNeedsPaint();
  }

  /// The color that should be used for the reaction when [hasFocus] is true.
  ///
  /// Used when the toggleable needs to change the reaction color/transparency,
  /// when it has focus.
  ///
  /// Defaults to the [activeColor] at alpha [kRadialReactionAlpha].
  Color get focusColor => _focusColor;
  Color _focusColor;
  set focusColor(Color value) {
    assert(value != null);
    if (value == _focusColor)
      return;
    _focusColor = value;
    markNeedsPaint();
  }

  /// The color that should be used for the reaction when drawn.
  ///
  /// Used when the toggleable needs to change the reaction color/transparency
  /// that is displayed when the toggleable is toggled by a tap.
  ///
  /// Defaults to the [activeColor] at alpha [kRadialReactionAlpha].
  Color get reactionColor => _reactionColor;
  Color _reactionColor;
  set reactionColor(Color value) {
    assert(value != null);
    if (value == _reactionColor)
      return;
    _reactionColor = value;
    markNeedsPaint();
  }

  /// Called when the control changes value.
  ///
  /// If the control is tapped, [onChanged] is called immediately with the new
  /// value.
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
      markNeedsSemanticsUpdate();
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
    if (value == false)
      _positionController.reverse();
    else
      _positionController.forward();
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
    _reactionHoverFadeController.stop();
    _reactionFocusFadeController.stop();
    super.detach();
  }

  void _handleTapDown(TapDownDetails details) {
    if (isInteractive) {
      _downPosition = globalToLocal(details.globalPosition);
      _reactionController.forward();
    }
  }

  void _handleTap() {
    if (!isInteractive)
      return;
    switch (value) {
      case false:
        onChanged(true);
        break;
      case true:
        onChanged(tristate ? null : false);
        break;
      default: // case null:
        onChanged(false);
        break;
    }
    sendSemanticsEvent(const TapSemanticEvent());
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
    if (!_reaction.isDismissed || !_reactionFocusFade.isDismissed || !_reactionHoverFade.isDismissed) {
      final Paint reactionPaint = Paint()
        ..color = Color.lerp(
          Color.lerp(activeColor.withAlpha(kRadialReactionAlpha), hoverColor, _reactionHoverFade.value),
          focusColor,
          _reactionFocusFade.value,
        );
      final Offset center = Offset.lerp(_downPosition ?? origin, origin, _reaction.value);
      final double reactionRadius = hasFocus || hovering
          ? kRadialReactionRadius
          : _kRadialReactionRadiusTween.evaluate(_reaction);
      if (reactionRadius > 0.0) {
        canvas.drawCircle(center + offset, reactionRadius, reactionPaint);
      }
    }
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config.isEnabled = isInteractive;
    if (isInteractive)
      config.onTap = _handleTap;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('value', value: value, ifTrue: 'checked', ifFalse: 'unchecked', showName: true));
    properties.add(FlagProperty('isInteractive', value: isInteractive, ifTrue: 'enabled', ifFalse: 'disabled', defaultValue: true));
  }
}
