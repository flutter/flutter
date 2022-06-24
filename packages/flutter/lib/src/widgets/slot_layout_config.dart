// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// A Widget that takes a child and a Function that returns an animated Widget
/// then displays the child with this animation.
///
/// Most commonly used in [LayoutSlot] however it would be functional outside of
/// this Widget as well
// ignore: must_be_immutable
class SlotLayoutConfig extends StatefulWidget {
  SlotLayoutConfig({
    required this.child,
    this.controller,
    this.animation,
    super.key,
  });

  /// The child Widget that the parent eventually returns with an animation.
  final Widget child;

  /// A function that takes an [AnimatedController] and a [Widget] and returns a
  /// [Widget].
  ///
  /// While it is not enforced, the recommended usage for this property is to
  /// return a Widget of type [AnimatedWidget] or [ImplicitlyAnimatedWidget]
  final Widget Function(AnimationController?, Widget)? animation;

  /// The [AnimationController] that runs this Widget's animation cycle.
  ///
  /// When [SlotLayoutConfig] is used within a [SlotLayout], the controller is
  /// passed in by the [SlotLayout] to ensure that animations run as intended.
  AnimationController? controller;

  @override
  State<SlotLayoutConfig> createState() => _SlotLayoutConfigState();
}

class _SlotLayoutConfigState extends State<SlotLayoutConfig> {
  @override
  Widget build(BuildContext context) {
    return (widget.animation != null && widget.controller != null)
        ? widget.animation!(widget.controller, widget.child)
        : widget.child;
  }
}
