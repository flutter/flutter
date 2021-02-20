// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';

// Duration of the animation that moves the toggle from one state to another.
const Duration _kToggleDuration = Duration(milliseconds: 200);

// Duration of the fade animation for the reaction when focus and hover occur.
const Duration _kReactionFadeDuration = Duration(milliseconds: 50);

class Toggleable extends StatefulWidget {
  const Toggleable({
    Key? key,
    required this.value,
    this.tristate = false,
    required this.onChanged,
    required this.painter,
    required this.size,
    required this.hasFocus,
    required this.hovering,
  }) : assert(tristate || value != null), super(key: key);

  final bool? value;
  final bool tristate;
  final ValueChanged<bool?>? onChanged;
  final ToogleablePainter painter;
  final Size size;
  final bool hasFocus;
  final bool hovering;

  bool get isInteractive => onChanged != null;

  @override
  State<Toggleable> createState() => _ToggleableState();
}

class _ToggleableState extends State<Toggleable> with TickerProviderStateMixin {
  late AnimationController _positionController;
  late CurvedAnimation _position;
  late AnimationController _reactionController;
  late Animation<double> _reaction;
  late AnimationController _reactionHoverFadeController;
  late Animation<double> _reactionHoverFade;
  late AnimationController _reactionFocusFadeController;
  late Animation<double> _reactionFocusFade;

  bool? _previousValue;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _positionController = AnimationController(
      duration: _kToggleDuration,
      value: widget.value == false ? 0.0 : 1.0,
      vsync: this,
    );
    _position = CurvedAnimation(
      parent: _positionController,
      curve: Curves.linear,
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
      value: widget.hovering || widget.hasFocus ? 1.0 : 0.0,
      vsync: this,
    );
    _reactionHoverFade = CurvedAnimation(
      parent: _reactionHoverFadeController,
      curve: Curves.fastOutSlowIn,
    );
    _reactionFocusFadeController = AnimationController(
      duration: _kReactionFadeDuration,
      value: widget.hovering || widget.hasFocus ? 1.0 : 0.0,
      vsync: this,
    );
    _reactionFocusFade = CurvedAnimation(
      parent: _reactionFocusFadeController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void didUpdateWidget(Toggleable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _position
        ..curve = Curves.easeIn
        ..reverseCurve = Curves.easeOut;
      if (widget.tristate) {
        if (widget.value == null)
          _positionController.value = 0.0;
        if (widget.value != false)
          _positionController.forward();
        else
          _positionController.reverse();
      } else {
        if (widget.value == true)
          _positionController.forward();
        else
          _positionController.reverse();
      }
    }
    if (oldWidget.hasFocus != widget.hasFocus) {
      if (widget.hasFocus) {
        _reactionFocusFadeController.forward();
      } else {
        _reactionFocusFadeController.reverse();
      }
    }
    if (oldWidget.hovering != widget.hovering) {
      if (widget.hovering) {
        _reactionHoverFadeController.forward();
      } else {
        _reactionHoverFadeController.reverse();
      }
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

  Offset? _downPosition;

  void _handleTapDown(TapDownDetails details) {
    if (widget.isInteractive) {
      _downPosition = details.localPosition;
      _reactionController.forward();
    }
  }

  void _handleTap() {
    if (!widget.isInteractive)
      return;
    switch (widget.value) {
      case false:
        widget.onChanged!(true);
        break;
      case true:
        widget.onChanged!(widget.tristate ? null : false);
        break;
      case null:
        widget.onChanged!(false);
        break;
    }
    context.findRenderObject()!.sendSemanticsEvent(const TapSemanticEvent());
  }

  void _handleTapUp(TapUpDetails details) {
    _downPosition = null;
    if (widget.isInteractive)
      _reactionController.reverse();
  }

  void _handleTapCancel() {
    _downPosition = null;
    if (widget.isInteractive)
      _reactionController.reverse();
  }

  ToggleableDetails get _toggleableDetails => ToggleableDetails._(
    position: _position,
    reaction: _reaction,
    reactionFocusFade: _reactionFocusFade,
    reactionHoverFade: _reactionHoverFade,
    downPosition: _downPosition,
    hasFocus: widget.hasFocus,
    hovering: widget.hovering,
    value: widget.value,
    previousValue: _previousValue,
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      excludeFromSemantics: !widget.isInteractive,
      onTapDown: _handleTapDown,
      onTap: _handleTap,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Semantics(
        enabled: widget.isInteractive,
        child: CustomPaint(
          size: widget.size,
          painter: _ToggleablePainter(_toggleableDetails, widget.painter),
        ),
      ),
    );
  }
}

class ToggleableDetails {
  ToggleableDetails._({
    required this.position,
    required this.reaction,
    required this.reactionFocusFade,
    required this.reactionHoverFade,
    required this.downPosition,
    required this.hasFocus,
    required this.hovering,
    required this.value,
    required this.previousValue,
  });

  final CurvedAnimation position;
  final Animation<double> reaction;
  final Animation<double> reactionFocusFade;
  final Animation<double> reactionHoverFade;
  final Offset? downPosition;
  final bool hasFocus;
  final bool hovering;
  final bool? value;
  final bool? previousValue;
}

class _ToggleablePainter extends CustomPainter {
  _ToggleablePainter(this.details, this.painter)
     : super(repaint: Listenable.merge(<Listenable>[
    details.position,
    details.reaction,
    details.reactionFocusFade,
    details.reactionHoverFade,
  ]));

  final ToggleableDetails details;
  final ToogleablePainter painter;

  @override
  void paint(Canvas canvas, Size size) {
    painter.paint(canvas, size, details);
  }

  @override
  bool shouldRepaint(_ToggleablePainter oldDelegate) => oldDelegate.painter != painter || oldDelegate.details != details;
}

abstract class ToogleablePainter {
  ToogleablePainter({
    required this.activeColor,
    required this.inactiveColor,
    required this.splashRadius,
    Color? hoverColor,
    Color? focusColor,
    Color? reactionColor,
    Color? inactiveReactionColor,
  }) : hoverColor = hoverColor ?? activeColor.withAlpha(kRadialReactionAlpha),
       focusColor = focusColor ?? activeColor.withAlpha(kRadialReactionAlpha),
       reactionColor = reactionColor ?? activeColor.withAlpha(kRadialReactionAlpha),
       inactiveReactionColor = inactiveReactionColor ?? activeColor.withAlpha(kRadialReactionAlpha);

  final Color activeColor;
  final Color inactiveColor;
  final Color hoverColor;
  final Color focusColor;
  final Color reactionColor;
  final Color inactiveReactionColor;
  final double splashRadius;

  void paint(Canvas canvas, Size size, ToggleableDetails details);

  /// Used by subclasses to paint the radial ink reaction for this control.
  ///
  /// The reaction is painted on the given canvas at the given offset. The
  /// origin is the center point of the reaction (usually distinct from the
  /// point at which the user interacted with the control, which is handled
  /// automatically).
  void paintRadialReaction(Canvas canvas, Offset origin, ToggleableDetails details) {
    if (!details.reaction.isDismissed || !details.reactionFocusFade.isDismissed || !details.reactionHoverFade.isDismissed) {
      final Paint reactionPaint = Paint()
        ..color = Color.lerp(
          Color.lerp(
            Color.lerp(inactiveReactionColor, reactionColor, details.position.value),
            hoverColor,
            details.reactionHoverFade.value,
          ),
          focusColor,
          details.reactionFocusFade.value,
        )!;
      final Offset center = Offset.lerp(details.downPosition ?? origin, origin, details.reaction.value)!;
      final Animatable<double> radialReactionRadiusTween = Tween<double>(
        begin: 0.0,
        end: splashRadius,
      );
      final double reactionRadius = details.hasFocus || details.hovering
          ? splashRadius
          : radialReactionRadiusTween.evaluate(details.reaction);
      if (reactionRadius > 0.0) {
        canvas.drawCircle(center, reactionRadius, reactionPaint);
      }
    }
  }
}

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
    required bool? value,
    bool tristate = false,
    required Color activeColor,
    required Color inactiveColor,
    Color? hoverColor,
    Color? focusColor,
    Color? reactionColor,
    Color? inactiveReactionColor,
    required double splashRadius,
    ValueChanged<bool?>? onChanged,
    required BoxConstraints additionalConstraints,
    required TickerProvider vsync,
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
       _reactionColor = reactionColor ?? activeColor.withAlpha(kRadialReactionAlpha),
       _inactiveReactionColor = inactiveReactionColor ?? activeColor.withAlpha(kRadialReactionAlpha),
       _splashRadius = splashRadius,
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
  late AnimationController _positionController;

  /// The visual value of the control.
  ///
  /// When the control is inactive, the [value] is false and this animation has
  /// the value 0.0. When the control is active, the value either true or tristate
  /// is true and the value is null. When the control is active the animation
  /// has a value of 1.0. When the control is changing from inactive
  /// to active (or vice versa), [value] is the target value and this animation
  /// gradually updates from 0.0 to 1.0 (or vice versa).
  CurvedAnimation get position => _position;
  late CurvedAnimation _position;

  /// Used by subclasses to control the radial reaction animation.
  ///
  /// Some controls have a radial ink reaction to user input. This animation
  /// controller can be used to start or stop these ink reactions.
  ///
  /// Subclasses should call [paintRadialReaction] to actually paint the radial
  /// reaction.
  @protected
  AnimationController get reactionController => _reactionController;
  late AnimationController _reactionController;
  late Animation<double> _reaction;

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
  late AnimationController _reactionFocusFadeController;
  late Animation<double> _reactionFocusFade;

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
  late AnimationController _reactionHoverFadeController;
  late Animation<double> _reactionHoverFade;

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
  bool? get value => _value;
  bool? _value;
  set value(bool? value) {
    assert(tristate || value != null);
    if (value == _value)
      return;
    _value = value;
    markNeedsSemanticsUpdate();
    _position
      ..curve = Curves.easeIn
      ..reverseCurve = Curves.easeOut;
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

  /// The color that should be used for the reaction when the toggleable is
  /// active.
  ///
  /// Used when the toggleable needs to change the reaction color/transparency
  /// that is displayed when the toggleable is active and tapped.
  ///
  /// Defaults to the [activeColor] at alpha [kRadialReactionAlpha].
  Color? get reactionColor => _reactionColor;
  Color? _reactionColor;
  set reactionColor(Color? value) {
    assert(value != null);
    if (value == _reactionColor)
      return;
    _reactionColor = value;
    markNeedsPaint();
  }

  /// The color that should be used for the reaction when the toggleable is
  /// inactive.
  ///
  /// Used when the toggleable needs to change the reaction color/transparency
  /// that is displayed when the toggleable is inactive and tapped.
  ///
  /// Defaults to the [activeColor] at alpha [kRadialReactionAlpha].
  Color? get inactiveReactionColor => _inactiveReactionColor;
  Color? _inactiveReactionColor;
  set inactiveReactionColor(Color? value) {
    assert(value != null);
    if (value == _inactiveReactionColor)
      return;
    _inactiveReactionColor = value;
    markNeedsPaint();
  }

  /// The splash radius for the radial reaction.
  double get splashRadius => _splashRadius;
  double _splashRadius;
  set splashRadius(double value) {
    if (value == _splashRadius)
      return;
    _splashRadius = value;
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
  ValueChanged<bool?>? get onChanged => _onChanged;
  ValueChanged<bool?>? _onChanged;
  set onChanged(ValueChanged<bool?>? value) {
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

  late TapGestureRecognizer _tap;
  Offset? _downPosition;

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
        onChanged!(true);
        break;
      case true:
        onChanged!(tristate ? null : false);
        break;
      case null:
        onChanged!(false);
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
          Color.lerp(
            Color.lerp(inactiveReactionColor, reactionColor, _position.value),
            hoverColor,
            _reactionHoverFade.value,
          ),
          focusColor,
          _reactionFocusFade.value,
        )!;
      final Offset center = Offset.lerp(_downPosition ?? origin, origin, _reaction.value)!;
      final Animatable<double> radialReactionRadiusTween = Tween<double>(
        begin: 0.0,
        end: splashRadius,
      );
      final double reactionRadius = hasFocus || hovering
          ? splashRadius
          : radialReactionRadiusTween.evaluate(_reaction);
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
