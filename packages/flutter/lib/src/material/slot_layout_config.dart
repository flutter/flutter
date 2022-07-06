// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// A Widget that takes a child and a Function that returns an animated Widget
/// then displays the child with this animation.
///
/// Most commonly used in [LayoutSlot] however it would be functional outside of
/// this Widget as well
///
class SlotLayoutConfig extends StatefulWidget {
  /// Creates a new [SlotLayoutConfig].
  ///
  /// Returns the child widget as is but holds properties to be accessed by other
  /// classes.
  const SlotLayoutConfig({
    required this.child,
    this.inAnimation,
    this.overtakeAnimation,
    required super.key,
  });

  /// The child Widget that the parent eventually returns with an animation.
  final Widget child;

  /// A function that takes an [AnimationController] and a [Widget] and returns
  /// a [Widget].
  ///
  /// The animation to be played when the child enters.
  ///
  /// While it is not enforced, the recommended usage for this property is to
  /// return a Widget of type [AnimatedWidget] or [ImplicitlyAnimatedWidget]
  final Widget Function(Widget, AnimationController)? inAnimation;

  /// A function that takes an [AnimationController] and a [Widget] and returns
  /// a [Widget].
  ///
  /// This animation is ran on the overtaken Widget when this child Widget is
  /// animated into view, replacing the other Widget.
  ///
  /// While it is not enforced, the recommended usage for this property is to
  /// return a Widget of type [AnimatedWidget] or [ImplicitlyAnimatedWidget]
  final Widget Function(Widget, AnimationController)? overtakeAnimation;

  @override
  State<SlotLayoutConfig> createState() => _SlotLayoutConfigState();
}

class _SlotLayoutConfigState extends State<SlotLayoutConfig> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
