// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';

import 'basic.dart';
import 'framework.dart';
import 'navigator.dart';
import 'transitions.dart';

/// Prevents the user from interacting with widgets behind itself.
class ModalBarrier extends StatelessComponent {
  ModalBarrier({
    Key key,
    this.color,
    this.dismissable: true
  }) : super(key: key);

  /// If non-null, fill the barrier with this color.
  final Color color;

  /// Whether touching the barrier will pop the current route off the [Navigator].
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

/// Prevents the user from interacting with widgets behind itself.
class AnimatedModalBarrier extends AnimatedComponent {
  AnimatedModalBarrier({
    Key key,
    Animated<Color> color,
    this.dismissable: true
  }) : color = color, super(key: key, animation: color);

  /// If non-null, fill the barrier with this color.
  final Animated<Color> color;

  /// Whether touching the barrier will pop the current route off the [Navigator].
  final bool dismissable;

  Widget build(BuildContext context) {
    return new ModalBarrier(
      color: color.value,
      dismissable: dismissable
    );
  }
}
