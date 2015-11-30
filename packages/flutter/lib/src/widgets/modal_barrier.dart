// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';

import 'basic.dart';
import 'framework.dart';
import 'navigator.dart';
import 'transitions.dart';

class ModalBarrier extends StatelessComponent {
  ModalBarrier({
    Key key,
    this.color,
    this.dismissable: true
  }) : super(key: key);

  final Color color;
  final bool dismissable;

  Widget build(BuildContext context) {
    return new Listener(
      onPointerDown: (_) {
        if (dismissable)
          Navigator.pop(context);
      },
      behavior: HitTestBehavior.opaque,
      child: new ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: color == null ? null : new DecoratedBox(
          decoration: new BoxDecoration(
            backgroundColor: color
          )
        )
      )
    );
  }
}

class AnimatedModalBarrier extends StatelessComponent {
  AnimatedModalBarrier({
    Key key,
    this.color,
    this.performance,
    this.dismissable: true
  }) : super(key: key);

  final AnimatedColorValue color;
  final PerformanceView performance;
  final bool dismissable;

  Widget build(BuildContext context) {
    return new BuilderTransition(
      performance: performance,
      variables: <AnimatedColorValue>[color],
      builder: (BuildContext context) {
        return new IgnorePointer(
          ignoring: performance.status == PerformanceStatus.reverse,
          child: new ModalBarrier(
            color: color.value,
            dismissable: dismissable
          )
        );
      }
    );
  }
}
