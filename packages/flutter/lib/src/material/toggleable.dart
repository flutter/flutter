// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'material_state.dart';

// Duration of the animation that moves the toggle from one state to another.
const Duration _kToggleDuration = Duration(milliseconds: 200);

// Duration of the fade animation for the reaction when focus and hover occur.
const Duration _kReactionFadeDuration = Duration(milliseconds: 50);

/// A mixin for [StatefulWidget]s that implement material-themed toggleable
/// controls with toggle animations (e.g. [Switch]es, [Checkbox]es, and
/// [Radio]s).
///
/// The mixin implements the logic for toggling the control (e.g. when tapped)
/// and provides a series of animation controllers to transition the control
/// from one state to another. It does not have any opinion about the visual
/// representation of the toggleable widget. The visuals are defined by a
/// [CustomPainter] passed to the [buildToggleable]. [State] objects using this
/// mixin should call that method from their [build] method.
///
/// This mixin is used to implement the material components for [Switch],
/// [Checkbox], and [Radio] controls.
@optionalTypeArgs
abstract mixin class ToggleableStateMixin extends RawToggleableStateMixin {
  /// Used by subclasses to manipulate the visual value of the control.
  ///
  /// Some controls respond to user input by updating their visual value. For
  /// example, the thumb of a switch moves from one position to another when
  /// dragged. These controls manipulate this animation controller to update
  /// their [position] and eventually trigger an [onChanged] callback when the
  /// animation reaches either 0.0 or 1.0.
  AnimationController get positionController => _positionController;
  late AnimationController _positionController;

  /// The visual value of the control.
  ///
  /// When the control is inactive, the [value] is false and this animation has
  /// the value 0.0. When the control is active, the value is either true or
  /// tristate is true and the value is null. When the control is active the
  /// animation has a value of 1.0. When the control is changing from inactive
  /// to active (or vice versa), [value] is the target value and this animation
  /// gradually updates from 0.0 to 1.0 (or vice versa).
  CurvedAnimation get position => _position;
  late CurvedAnimation _position;

  /// Used by subclasses to control the radial reaction animation.
  ///
  /// Some controls have a radial ink reaction to user input. This animation
  /// controller can be used to start or stop these ink reactions.
  ///
  /// To paint the actual radial reaction, [ToggleablePainter.paintRadialReaction]
  /// may be used.
  AnimationController get reactionController => _reactionController;
  late AnimationController _reactionController;

  /// The visual value of the radial reaction animation.
  ///
  /// Some controls have a radial ink reaction to user input. This animation
  /// controls the progress of these ink reactions.
  ///
  /// To paint the actual radial reaction, [ToggleablePainter.paintRadialReaction]
  /// may be used.
  CurvedAnimation get reaction => _reaction;
  late CurvedAnimation _reaction;

  /// Controls the radial reaction's opacity animation for hover changes.
  ///
  /// Some controls have a radial ink reaction to pointer hover. This animation
  /// controls these ink reaction fade-ins and
  /// fade-outs.
  ///
  /// To paint the actual radial reaction, [ToggleablePainter.paintRadialReaction]
  /// may be used.
  CurvedAnimation get reactionHoverFade => _reactionHoverFade;
  late CurvedAnimation _reactionHoverFade;
  late AnimationController _reactionHoverFadeController;

  /// Controls the radial reaction's opacity animation for focus changes.
  ///
  /// Some controls have a radial ink reaction to focus. This animation
  /// controls these ink reaction fade-ins and fade-outs.
  ///
  /// To paint the actual radial reaction, [ToggleablePainter.paintRadialReaction]
  /// may be used.
  CurvedAnimation get reactionFocusFade => _reactionFocusFade;
  late CurvedAnimation _reactionFocusFade;
  late AnimationController _reactionFocusFadeController;

  @override
  void initState() {
    super.initState();
    _positionController = AnimationController(
      duration: _kToggleDuration,
      value: value == false ? 0.0 : 1.0,
      vsync: this,
    );
    _position = CurvedAnimation(
      parent: _positionController,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOut,
    );
    _reactionController = AnimationController(
      duration: kRadialReactionDuration,
      vsync: this,
    );
    _reaction = CurvedAnimation(
      parent: _reactionController,
      curve: Curves.fastOutSlowIn,
    );
    _reactionHoverFadeController = AnimationController(
      duration: _kReactionFadeDuration,
      value: hovering || focused ? 1.0 : 0.0,
      vsync: this,
    );
    _reactionHoverFade = CurvedAnimation(
      parent: _reactionHoverFadeController,
      curve: Curves.fastOutSlowIn,
    );
    _reactionFocusFadeController = AnimationController(
      duration: _kReactionFadeDuration,
      value: hovering || focused ? 1.0 : 0.0,
      vsync: this,
    );
    _reactionFocusFade = CurvedAnimation(
      parent: _reactionFocusFadeController,
      curve: Curves.fastOutSlowIn,
    );
  }

  /// Runs the [position] animation to transition the Toggleable's appearance
  /// to match [value].
  ///
  /// This method must be called whenever [value] changes to ensure that the
  /// visual representation of the Toggleable matches the current [value].
  void animateToValue() {
    if (tristate) {
      if (value == null) {
        _positionController.value = 0.0;
      }
      if (value ?? true) {
        _positionController.forward();
      } else {
        _positionController.reverse();
      }
    } else {
      if (value ?? false) {
        _positionController.forward();
      } else {
        _positionController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _positionController.dispose();
    _position.dispose();
    _reactionController.dispose();
    _reaction.dispose();
    _reactionHoverFadeController.dispose();
    _reactionHoverFade.dispose();
    _reactionFocusFadeController.dispose();
    _reactionFocusFade.dispose();
    super.dispose();
  }

  @override
  void handleTapDown(TapDownDetails details) {
    super.handleTapDown(details);
    if (isInteractive) {
      _reactionController.forward();
    }
  }

  @override
  void handleTapEnd([TapUpDetails? details]) {
    super.handleTapEnd(details);
    _reactionController.reverse();
  }

  @override
  void handleFocusHighlightChanged(bool focused) {
    super.handleFocusHighlightChanged(focused);
    if (focused != super.focused) {
      if (focused) {
        _reactionFocusFadeController.forward();
      } else {
        _reactionFocusFadeController.reverse();
      }
    }
  }

  @override
  void handleHoverChanged(bool hovering) {
    super.handleHoverChanged(hovering);
    if (hovering != super.hovering) {
      if (hovering) {
        _reactionHoverFadeController.forward();
      } else {
        _reactionHoverFadeController.reverse();
      }
    }
  }

  /// Typically wraps a `painter` that draws the actual visuals of the
  /// Toggleable with logic to toggle it.
  ///
  /// Consider providing a subclass of [ToggleablePainter] as a `painter`, which
  /// implements logic to draw a radial ink reaction for this control. The
  /// painter is usually configured with the [reaction], [position],
  /// [reactionHoverFade], and [reactionFocusFade] animation provided by this
  /// mixin. It is expected to draw the visuals of the Toggleable based on the
  /// current value of these animations. The animations are triggered by
  /// this mixin to transition the Toggleable from one state to another.
  ///
  /// This method must be called from the [build] method of the [State] class
  /// that uses this mixin. The returned [Widget] must be returned from the
  /// build method - potentially after wrapping it in other widgets.
  Widget buildToggleable({
    FocusNode? focusNode,
    ValueChanged<bool>? onFocusChange,
    bool autofocus = false,
    required MaterialStateProperty<MouseCursor> mouseCursor,
    required Size size,
    required CustomPainter painter,
  }) {
    return buildRawToggleable(
      focusNode: focusNode,
      autofocus: autofocus,
      onFocusChange: onFocusChange,
      mouseCursor: mouseCursor,
      size: size,
      painter: painter,
    );
  }
}

/// A base class for a [CustomPainter] that may be passed to
/// [ToggleableStateMixin.buildToggleable] to draw the visual representation of
/// a Toggleable.
///
/// Subclasses must implement the [paint] method to draw the actual visuals of
/// the Toggleable. In their [paint] method subclasses may call
/// [paintRadialReaction] to draw a radial ink reaction for this control.
abstract class ToggleablePainter extends RawToggleablePainter {
  /// The visual value of the control.
  ///
  /// Usually set to [ToggleableStateMixin.position].
  Animation<double> get position => _position!;
  Animation<double>? _position;
  set position(Animation<double> value) {
    if (value == _position) {
      return;
    }
    _position?.removeListener(notifyListeners);
    value.addListener(notifyListeners);
    _position = value;
    notifyListeners();
  }

  /// The visual value of the radial reaction animation.
  ///
  /// Usually set to [ToggleableStateMixin.reaction].
  Animation<double> get reaction => _reaction!;
  Animation<double>? _reaction;
  set reaction(Animation<double> value) {
    if (value == _reaction) {
      return;
    }
    _reaction?.removeListener(notifyListeners);
    value.addListener(notifyListeners);
    _reaction = value;
    notifyListeners();
  }

  /// Controls the radial reaction's opacity animation for focus changes.
  ///
  /// Usually set to [ToggleableStateMixin.reactionFocusFade].
  Animation<double> get reactionFocusFade => _reactionFocusFade!;
  Animation<double>? _reactionFocusFade;
  set reactionFocusFade(Animation<double> value) {
    if (value == _reactionFocusFade) {
      return;
    }
    _reactionFocusFade?.removeListener(notifyListeners);
    value.addListener(notifyListeners);
    _reactionFocusFade = value;
    notifyListeners();
  }

  /// Controls the radial reaction's opacity animation for hover changes.
  ///
  /// Usually set to [ToggleableStateMixin.reactionHoverFade].
  Animation<double> get reactionHoverFade => _reactionHoverFade!;
  Animation<double>? _reactionHoverFade;
  set reactionHoverFade(Animation<double> value) {
    if (value == _reactionHoverFade) {
      return;
    }
    _reactionHoverFade?.removeListener(notifyListeners);
    value.addListener(notifyListeners);
    _reactionHoverFade = value;
    notifyListeners();
  }

  /// The color that should be used for the reaction when the toggleable is
  /// inactive.
  ///
  /// Used when the toggleable needs to change the reaction color/transparency
  /// that is displayed when the toggleable is inactive and tapped.
  Color get inactiveReactionColor => _inactiveReactionColor!;
  Color? _inactiveReactionColor;
  set inactiveReactionColor(Color value) {
    if (value == _inactiveReactionColor) {
      return;
    }
    _inactiveReactionColor = value;
    notifyListeners();
  }

  /// The color that should be used for the reaction when the toggleable is
  /// active.
  ///
  /// Used when the toggleable needs to change the reaction color/transparency
  /// that is displayed when the toggleable is active and tapped.
  Color get reactionColor => _reactionColor!;
  Color? _reactionColor;
  set reactionColor(Color value) {
    if (value == _reactionColor) {
      return;
    }
    _reactionColor = value;
    notifyListeners();
  }

  /// The color that should be used for the reaction when [isHovered] is true.
  ///
  /// Used when the toggleable needs to change the reaction color/transparency,
  /// when it is being hovered over.
  Color get hoverColor => _hoverColor!;
  Color? _hoverColor;
  set hoverColor(Color value) {
    if (value == _hoverColor) {
      return;
    }
    _hoverColor = value;
    notifyListeners();
  }

  /// The splash radius for the radial reaction.
  double get splashRadius => _splashRadius!;
  double? _splashRadius;
  set splashRadius(double value) {
    if (value == _splashRadius) {
      return;
    }
    _splashRadius = value;
    notifyListeners();
  }

  /// Used by subclasses to paint the radial ink reaction for this control.
  ///
  /// The reaction is painted on the given canvas at the given offset. The
  /// origin is the center point of the reaction (usually distinct from the
  /// [downPosition] at which the user interacted with the control).
  void paintRadialReaction({
    required Canvas canvas,
    Offset offset = Offset.zero,
    required Offset origin,
  }) {
    if (!reaction.isDismissed || !reactionFocusFade.isDismissed || !reactionHoverFade.isDismissed) {
      final Paint reactionPaint = Paint()
        ..color = Color.lerp(
          Color.lerp(
            Color.lerp(inactiveReactionColor, reactionColor, position.value),
            hoverColor,
            reactionHoverFade.value,
          ),
          focusColor,
          reactionFocusFade.value,
        )!;
      final Animatable<double> radialReactionRadiusTween = Tween<double>(
        begin: 0.0,
        end: splashRadius,
      );
      final double reactionRadius = isFocused || isHovered
          ? splashRadius
          : radialReactionRadiusTween.evaluate(reaction);
      if (reactionRadius > 0.0) {
        canvas.drawCircle(origin + offset, reactionRadius, reactionPaint);
      }
    }
  }

  @override
  void dispose() {
    _position?.removeListener(notifyListeners);
    _reaction?.removeListener(notifyListeners);
    _reactionFocusFade?.removeListener(notifyListeners);
    _reactionHoverFade?.removeListener(notifyListeners);
    super.dispose();
  }
}
