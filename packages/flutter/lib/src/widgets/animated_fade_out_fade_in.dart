// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'implicit_animations.dart';
import 'transitions.dart';

class AnimatedFadeOutFadeIn extends ImplicitlyAnimatedWidget {
  const AnimatedFadeOutFadeIn({
    Key key,
    @required this.target,
    @required this.placeholder,
    @required this.isTargetLoaded,
    @required this.fadeOutDuration,
    @required this.fadeOutCurve,
    @required this.fadeInDuration,
    @required this.fadeInCurve,
  }) : assert(target != null),
       assert(placeholder != null),
       assert(isTargetLoaded != null),
       assert(fadeOutDuration != null),
       assert(fadeOutCurve != null),
       assert(fadeInDuration != null),
       assert(fadeInCurve != null),
       super(key: key, duration: fadeInDuration + fadeOutDuration);

  final Widget target;
  final Widget placeholder;
  final bool isTargetLoaded;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final Curve fadeInCurve;
  final Curve fadeOutCurve;

  @override
  _AnimatedFadeOutFadeInState createState() => _AnimatedFadeOutFadeInState();
}

class _AnimatedFadeOutFadeInState extends ImplicitlyAnimatedWidgetState<AnimatedFadeOutFadeIn> {
  Tween<double> _targetOpacity;
  Tween<double> _placeholderOpacity;
  Animation<double> _targetOpacityAnimation;
  Animation<double> _placeholderOpacityAnimation;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _targetOpacity = visitor(
      _targetOpacity,
      widget.isTargetLoaded ? 1.0 : 0.0,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>;
    _placeholderOpacity = visitor(
      _placeholderOpacity,
      widget.isTargetLoaded ? 0.0 : 1.0,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>;
  }

  @override
  void didUpdateTweens() {
    _placeholderOpacityAnimation = animation.drive(TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: _placeholderOpacity.chain(CurveTween(curve: widget.fadeOutCurve)),
        weight: widget.fadeOutDuration.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0),
        weight: widget.fadeInDuration.inMilliseconds.toDouble(),
      ),
    ]))..addStatusListener((AnimationStatus status) {
      if (_placeholderOpacityAnimation.isCompleted) {
        // Need to rebuild to remove placeholder now that it is invisibile.
        setState(() {});
      }
    });

    _targetOpacityAnimation = animation.drive(TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0),
        weight: widget.fadeOutDuration.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: _targetOpacity.chain(CurveTween(curve: widget.fadeInCurve)),
        weight: widget.fadeInDuration.inMilliseconds.toDouble(),
      ),
    ]));
    if (!widget.isTargetLoaded && _isValid(_placeholderOpacity) && _isValid(_targetOpacity)) {
      // Jump (don't fade) back to the placeholder image, so as to be ready
      // for the full animation when the new target image becomes ready.
      controller.value = controller.upperBound;
    }
  }

  bool _isValid(Tween<double> tween) {
    return tween.begin != null && tween.end != null;
  }

  @override
  Widget build(BuildContext context) {
    final Widget target = FadeTransition(
      opacity: _targetOpacityAnimation,
      child: widget.target,
    );

    if (_placeholderOpacityAnimation.isCompleted) {
      return target;
    }

    return Stack(
      fit: StackFit.passthrough,
      alignment: AlignmentDirectional.center,
      // Text direction is irrelevant here since we're using center alignment,
      // but it allows the Stack to avoid a call to Directionality.of()
      textDirection: TextDirection.ltr,
      children: <Widget>[
        target,
        FadeTransition(
          opacity: _placeholderOpacityAnimation,
          child: widget.placeholder,
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Animation<double>>('targetOpacity', _targetOpacityAnimation));
    properties.add(DiagnosticsProperty<Animation<double>>('placeholderOpacity', _placeholderOpacityAnimation));
  }
}