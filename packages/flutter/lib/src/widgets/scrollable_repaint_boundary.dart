// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'animated_repaint_notifier.dart';
import 'basic.dart';
import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_notification.dart';

/// A [ScrollableRepaintBoundaryManager] tracks the scrollable state and notifies
/// descendant [ScrollableRepaintBoundary].
class ScrollableRepaintBoundaryManager extends StatefulWidget {
  /// Create a new [ScrollableRepaintBoundaryManager].
  const ScrollableRepaintBoundaryManager({required this.child, super.key});

  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  State<ScrollableRepaintBoundaryManager> createState() {
    return _ScrollableRepaintBoundaryManager();
  }
}

class _ScrollableRepaintBoundaryManager extends State<ScrollableRepaintBoundaryManager> {
  final ValueNotifier<bool> boundary = ValueNotifier<bool>(false);

  bool _onScrollUpdateNotification(ScrollNotification notification) {
    if (notification.depth != 0) {
      return false;
    }
    if (notification is ScrollStartNotification) {
      boundary.value = true;
    } else if (notification is ScrollUpdateNotification) {
      boundary.value = true;
    } else if (notification is ScrollEndNotification) {
      boundary.value = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollUpdateNotification,
      child: _ScrollableRepaintBoundaryNotifier(
        state: boundary,
        child: widget.child,
      ),
    );
  }
}

/// An inherited widget that listens to the scroll state and notifies the
/// child [ScrollableRepaintBoundary] to enable/disable the repaint
/// boundary.
class _ScrollableRepaintBoundaryNotifier extends InheritedWidget {
  const _ScrollableRepaintBoundaryNotifier({
    required super.child,
    required this.state,
  });

  final ValueNotifier<bool> state;

  @override
  bool updateShouldNotify(covariant _ScrollableRepaintBoundaryNotifier oldWidget) {
    return oldWidget.state != state;
  }
}

/// A [RepaintBoundary] specialized for the children scrollable widgets.
///
/// Generally speaking, dividing a scene with repaint boundaries is only
/// advantageous if it would both stabilize the picture and only to the point
/// where there are a few (1-3) dozen pictures in a frame. If a picture is already
/// protected by some parent repaint boundary and does not change, further dividing
/// it with more repaint boundaries is counter productive as it degrades the
/// efficiency of the Flutter engine's raster cache.
///
/// In the case of scrolling widgets, dividing each child item with a repaint boundary
/// is usually ideal as it both prevents them from changing during the scroll
/// (allowing them to be cached) and protects siblings from hover or material ink
/// splash animations.
///
/// Nevertheless, there are several scenarios where this is counter-productive. If
/// the list is nested in another list, the nested repaint boundaries will often
/// create too many pictures for the raster cache to be effective. These pictures are
/// often so small as to not meet the threshold for cache admission. If this list is
/// shrink-wrapped or on a cross-axis but not able to scroll, then the most common
/// case that makes repaint boundaries effective is removed.
///
/// Another scenario is where a list is used instead of a Row/Column/Wrap because
/// its children may overflow, but often don't. In this case, the benefits observed
/// during scrolling are also removed.
///
/// This widget attempts to address these cases, by making the repaint boundary used
/// to wrap scrollable children conditional on whether the scrollable is currently
/// scrolling.
class ScrollableRepaintBoundary extends StatefulWidget {
  /// Create a new [ScrollableRepaintBoundary].
  const ScrollableRepaintBoundary({super.key, required this.child});

  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  State<ScrollableRepaintBoundary> createState() {
    return _ScrollableRepaintBoundaryState();
  }
}

class _ScrollableRepaintBoundaryState extends State<ScrollableRepaintBoundary> {
  final ValueNotifier<bool> combinedBoundary = ValueNotifier<bool>(false);
  ValueNotifier<bool>? scrolling;
  late _ScrollableRepaintBoundaryNotifier _notifier;
  bool _animating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notifier = context.dependOnInheritedWidgetOfExactType<_ScrollableRepaintBoundaryNotifier>()!;
    scrolling?.removeListener(_onNotifierChange);
    scrolling = _notifier.state;
    scrolling!.addListener(_onNotifierChange);
    _onNotifierChange();
  }

  void _onNotifierChange() {
    combinedBoundary.value = scrolling!.value || _animating;
  }

  bool _onNotification(AnimatedRepaintNotification notification) {
    if (notification is AnimationStart) {
      _animating = true;
      _onNotifierChange();
      return true;
    }
    if (notification is AnimationEnd) {
      _animating = false;
      _onNotifierChange();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<AnimatedRepaintNotification>(
      onNotification: _onNotification,
      child: _ConditionalRepaintBoundary(combinedBoundary, child: widget.child),
    );
  }
}

class _ConditionalRepaintBoundary extends SingleChildRenderObjectWidget {
  const _ConditionalRepaintBoundary(this.boundary, { super.child });

  final ValueListenable<bool> boundary;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderConditionalRepaintBoundary(boundary);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderConditionalRepaintBoundary renderObject) {
    renderObject.boundary = boundary;
  }
}
