// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/widgets/animated_component.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/mimic.dart';

class MimicOverlay extends AnimatedComponent {
  MimicOverlay({
    Key key,
    this.children,
    this.overlay,
    this.duration: const Duration(milliseconds: 200),
    this.curve: linear,
    this.targetRect
  }) : super(key: key);

  List<Widget> children;
  GlobalKey overlay;
  Duration duration;
  Curve curve;
  Rect targetRect;

  void syncConstructorArguments(MimicOverlay source) {
    children = source.children;

    duration = source.duration;
    _expandPerformance.duration = duration;

    targetRect = source.targetRect;
    _mimicBounds.end = targetRect;
    if (_expandPerformance.isCompleted) {
      _mimicBounds.value = _mimicBounds.end;
    }

    curve = source.curve;
    _mimicBounds.curve = curve;

    if (overlay != source.overlay) {
      overlay = source.overlay;
      if (_expandPerformance.isDismissed) {
        _activeOverlay = overlay;
      } else {
        _expandPerformance.reverse();
      }
    }
  }

  void initState() {
    _mimicBounds = new AnimatedRect(new Rect(), curve: curve);
    _mimicBounds.end = targetRect;
    _expandPerformance = new AnimationPerformance()
      ..duration = duration
      ..addVariable(_mimicBounds)
      ..addStatusListener(_handleAnimationStatusChanged);
    watch(_expandPerformance);
  }

  GlobalKey _activeOverlay;
  AnimatedRect _mimicBounds;
  AnimationPerformance _expandPerformance;

  void _handleAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      setState(() {
        _activeOverlay = overlay;
      });
    }
  }

  void _handleMimicCallback(Rect globalBounds) {
    setState(() {
      // TODO(abarth): We need to convert global bounds into local coordinates.
      _mimicBounds.begin =
          globalToLocal(globalBounds.topLeft) & globalBounds.size;
      _mimicBounds.value = _mimicBounds.begin;
    });
    _expandPerformance.forward();
  }

  Widget build() {
    List<Widget> layers = new List<Widget>();

    if (children != null) {
      layers.addAll(children);
    }

    if (_activeOverlay != null) {
      layers.add(
        new Positioned(
          left: _mimicBounds.value.left,
          top: _mimicBounds.value.top,
          child: new SizedBox(
            width: _mimicBounds.value.width,
            height: _mimicBounds.value.height,
            child: new Mimic(
              callback: _handleMimicCallback,
              original: _activeOverlay
            )
          )
        )
      );
    }

    return new Stack(layers);
  }
}
