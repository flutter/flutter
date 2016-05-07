// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'navigator.dart';
import 'transitions.dart';

/// Prevents the user from interacting with widgets behind itself.
class ModalBarrier extends StatelessWidget {
  ModalBarrier({
    Key key,
    this.color,
    this.dismissable: true
  }) : super(key: key);

  /// If non-null, fill the barrier with this color.
  final Color color;

  /// Whether touching the barrier will pop the current route off the [Navigator].
  final bool dismissable;

  @override
  Widget build(BuildContext context) {
    return new Semantics(
      container: true,
      child: new GestureDetector(
        onTapDown: (Point position) {
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
      )
    );
  }
}

/// Prevents the user from interacting with widgets behind itself.
class AnimatedModalBarrier extends AnimatedWidget {
  AnimatedModalBarrier({
    Key key,
    Animation<Color> color,
    this.dismissable: true
  }) : super(key: key, animation: color);

  /// If non-null, fill the barrier with this color.
  Animation<Color> get color => animation;

  /// Whether touching the barrier will pop the current route off the [Navigator].
  final bool dismissable;

  @override
  Widget build(BuildContext context) {
    return new ModalBarrier(
      color: color.value,
      dismissable: dismissable
    );
  }
}
