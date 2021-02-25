// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'material_state.dart';

// Duration of the animation that moves the toggle from one state to another.
const Duration _kToggleDuration = Duration(milliseconds: 200);

// Duration of the fade animation for the reaction when focus and hover occur.
const Duration _kReactionFadeDuration = Duration(milliseconds: 50);

@optionalTypeArgs
mixin ToggleableStateMixin<S extends StatefulWidget> on TickerProviderStateMixin<S> {
  /// Used by subclasses to manipulate the visual value of the control.
  ///
  /// Some controls respond to user input by updating their visual value. For
  /// example, the thumb of a switch moves from one position to another when
  /// dragged. These controls manipulate this animation controller to update
  /// their [position] and eventually trigger an [onChanged] callback when the
  /// animation reaches either 0.0 or 1.0.
  @protected
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
  @protected
  CurvedAnimation get position => _position;
  late CurvedAnimation _position;

  /// Used by subclasses to control the radial reaction animation.
  ///
  /// Some controls have a radial ink reaction to user input. This animation
  /// controller can be used to start or stop these ink reactions.
  ///
  /// To paint the actual radial reaction, [ToggleablePainter.paintRadialReaction]
  /// may be used.
  @protected
  AnimationController get reactionController => _reactionController;
  late AnimationController _reactionController;

  /// The visual value of the radial reaction animation.
  ///
  /// Some controls have a radial ink reaction to user input. This animation
  /// controls the progress of these ink reactions.
  ///
  /// To paint the actual radial reaction, [ToggleablePainter.paintRadialReaction]
  /// may be used.
  @protected
  Animation<double> get reaction => _reaction;
  late Animation<double> _reaction;

  /// Controls the radial reaction's opacity animation for hover changes.
  ///
  /// Some controls have a radial ink reaction to pointer hover. This animation
  /// controls these ink reaction fade-ins and
  /// fade-outs.
  ///
  /// To paint the actual radial reaction, [ToggleablePainter.paintRadialReaction]
  /// may be used.
  @protected
  Animation<double> get reactionHoverFade => _reactionHoverFade;
  late Animation<double> _reactionHoverFade;
  late AnimationController _reactionHoverFadeController;

  /// Controls the radial reaction's opacity animation for focus changes.
  ///
  /// Some controls have a radial ink reaction to focus. This animation
  /// controls these ink reaction fade-ins and fade-outs.
  ///
  /// To paint the actual radial reaction, [ToggleablePainter.paintRadialReaction]
  /// may be used.
  @protected
  Animation<double> get reactionFocusFade => _reactionFocusFade;
  late Animation<double> _reactionFocusFade;
  late AnimationController _reactionFocusFadeController;

  bool get isInteractive => onChanged != null;

  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _handleTap),
  };

  ValueChanged<bool?>? get onChanged;
  bool? get value;
  bool get tristate;

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
      value: _hovering || _focused ? 1.0 : 0.0,
      vsync: this,
    );
    _reactionHoverFade = CurvedAnimation(
      parent: _reactionHoverFadeController,
      curve: Curves.fastOutSlowIn,
    );
    _reactionFocusFadeController = AnimationController(
      duration: _kReactionFadeDuration,
      value: _hovering || _focused ? 1.0 : 0.0,
      vsync: this,
    );
    _reactionFocusFade = CurvedAnimation(
      parent: _reactionFocusFadeController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @protected
  void animateToValue() {
    if (tristate) {
      if (value == null)
        _positionController.value = 0.0;
      if (value != false)
        _positionController.forward();
      else
        _positionController.reverse();
    } else {
      if (value == true)
        _positionController.forward();
      else
        _positionController.reverse();
    }
  }

  @override
  void dispose() {
    _positionController.dispose();
    _reactionController.dispose();
    _reactionHoverFadeController.dispose();
    _reactionFocusFadeController.dispose();
    super.dispose();
  }

  @protected
  Offset? get downPosition => _downPosition;
  Offset? _downPosition;

  void _handleTapDown(TapDownDetails details) {
    if (isInteractive) {
      setState(() {
        _downPosition = details.localPosition;
      });
      _reactionController.forward();
    }
  }

  void _handleTap([Intent? _]) {
    if (!isInteractive)
      return;
    switch (value) {
      case false:
        onChanged!(true);
        break;
      case true:
        onChanged!(tristate ? null : false);
        break;
      case null:
        onChanged!(false);
        break;
    }
    context.findRenderObject()!.sendSemanticsEvent(const TapSemanticEvent());
  }

  void _handleTapEnd([TapUpDetails? _]) {
    setState(() {
      _downPosition = null;
    });
    _reactionController.reverse();
  }

  bool _focused = false;
  void _handleFocusHighlightChanged(bool focused) {
    if (focused != _focused) {
      setState(() { _focused = focused; });
      if (focused) {
        _reactionFocusFadeController.forward();
      } else {
        _reactionFocusFadeController.reverse();
      }
    }
  }

  bool _hovering = false;
  void _handleHoverChanged(bool hovering) {
    if (hovering != _hovering) {
      setState(() { _hovering = hovering; });
      if (hovering) {
        _reactionHoverFadeController.forward();
      } else {
        _reactionHoverFadeController.reverse();
      }
    }
  }

  @protected
  Set<MaterialState> get states => <MaterialState>{
    if (!isInteractive) MaterialState.disabled,
    if (_hovering) MaterialState.hovered,
    if (_focused) MaterialState.focused,
    if (value != false) MaterialState.selected,
  };

  @protected
  Widget buildToggleable({
    FocusNode? focusNode,
    bool autofocus = false,
    required MaterialStateProperty<MouseCursor> mouseCursor,
    required Size size,
    required CustomPainter painter,
  }) {
    return FocusableActionDetector(
      actions: _actionMap,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: isInteractive,
      onShowFocusHighlight: _handleFocusHighlightChanged,
      onShowHoverHighlight: _handleHoverChanged,
      mouseCursor: mouseCursor.resolve(states),
      child: GestureDetector(
        excludeFromSemantics: !isInteractive,
        onTapDown: _handleTapDown,
        onTap: _handleTap,
        onTapUp: _handleTapEnd,
        onTapCancel: _handleTapEnd,
        child: Semantics(
          enabled: isInteractive,
          child: CustomPaint(
            size: size,
            painter: painter,
          ),
        ),
      ),
    );
  }
}

abstract class ToggleablePainter extends ChangeNotifier implements CustomPainter  {
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

  Color get activeColor => _activeColor!;
  Color? _activeColor;
  set activeColor(Color value) {
    if (_activeColor == value) {
      return;
    }
    _activeColor = value;
    notifyListeners();
  }

  Color get inactiveColor => _inactiveColor!;
  Color? _inactiveColor;
  set inactiveColor(Color value) {
    if (_inactiveColor == value) {
      return;
    }
    _inactiveColor = value;
    notifyListeners();
  }

  Color get inactiveReactionColor => _inactiveReactionColor!;
  Color? _inactiveReactionColor;
  set inactiveReactionColor(Color value) {
    if (value == _inactiveReactionColor) {
      return;
    }
    _inactiveReactionColor = value;
    notifyListeners();
  }

  Color get reactionColor => _reactionColor!;
  Color? _reactionColor;
  set reactionColor(Color value) {
    if (value == _reactionColor) {
      return;
    }
    _reactionColor = value;
    notifyListeners();
  }

  Color get hoverColor => _hoverColor!;
  Color? _hoverColor;
  set hoverColor(Color value) {
    if (value == _hoverColor) {
      return;
    }
    _hoverColor = value;
    notifyListeners();
  }

  Color get focusColor => _focusColor!;
  Color? _focusColor;
  set focusColor(Color value) {
    if (value == _focusColor) {
      return;
    }
    _focusColor = value;
    notifyListeners();
  }

  double get splashRadius => _splashRadius!;
  double? _splashRadius;
  set splashRadius(double value) {
    if (value == _splashRadius) {
      return;
    }
    _splashRadius = value;
    notifyListeners();
  }

  Offset? get downPosition => _downPosition;
  Offset? _downPosition;
  set downPosition(Offset? value) {
    if (value == _downPosition) {
      return;
    }
    _downPosition = value;
    notifyListeners();
  }

  bool get isFocused => _isFocused!;
  bool? _isFocused;
  set isFocused(bool? value) {
    if (value == _isFocused) {
      return;
    }
    _isFocused = value;
    notifyListeners();
  }

  bool get isHovered => _isHovered!;
  bool? _isHovered;
  set isHovered(bool? value) {
    if (value == _isHovered) {
      return;
    }
    _isHovered = value;
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
      final Offset center = Offset.lerp(downPosition ?? origin, origin, reaction.value)!;
      final Animatable<double> radialReactionRadiusTween = Tween<double>(
        begin: 0.0,
        end: splashRadius,
      );
      final double reactionRadius = isFocused || isHovered
          ? splashRadius
          : radialReactionRadiusTween.evaluate(reaction);
      if (reactionRadius > 0.0) {
        canvas.drawCircle(center + offset, reactionRadius, reactionPaint);
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  @override
  bool? hitTest(Offset position) => null;

  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;

  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;
}
