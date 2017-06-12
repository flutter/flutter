// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'container.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'navigator.dart';
import 'transitions.dart';

/// A widget that prevents the user from interacting with widgets behind itself.
class ModalBarrier extends StatelessWidget {
  /// Creates a widget that blocks user interaction.
  const ModalBarrier({
    Key key,
    this.color,
    this.dismissible: true
  }) : super(key: key);

  /// If non-null, fill the barrier with this color.
  final Color color;

  /// Whether touching the barrier will pop the current route off the [Navigator].
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    return new ExcludeSemantics(
      excluding: !dismissible,
      child: new Semantics(
        container: true,
        child: new GestureDetector(
          onTapDown: (TapDownDetails details) {
            if (dismissible)
              Navigator.pop(context);
          },
          behavior: HitTestBehavior.opaque,
          child: new ConstrainedBox(
            constraints: const BoxConstraints.expand(),
            child: color == null ? null : new DecoratedBox(
              decoration: new BoxDecoration(
                color: color
              )
            )
          )
        )
      )
    );
  }
}

/// A widget that prevents the user from interacting with widgets behind itself.
class AnimatedModalBarrier extends AnimatedWidget {
  /// Creates a widget that blocks user interaction.
  const AnimatedModalBarrier({
    Key key,
    Animation<Color> color,
    this.dismissible: true
  }) : super(key: key, listenable: color);

  /// If non-null, fill the barrier with this color.
  Animation<Color> get color => listenable;

  /// Whether touching the barrier will pop the current route off the [Navigator].
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    return new ModalBarrier(
      color: color?.value,
      dismissible: dismissible
    );
  }
}
