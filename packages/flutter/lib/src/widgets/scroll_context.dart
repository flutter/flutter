// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'ticker_provider.dart';

/// An interface that [Scrollable] widgets implement in order to use
/// [ScrollPosition].
///
/// See also:
///
///  * [ScrollableState], which is the most common implementation of this
///    interface.
///  * [ScrollPosition], which uses this interface to communicate with the
///    scrollable widget.
abstract class ScrollContext {
  /// The [BuildContext] that should be used when dispatching
  /// [ScrollNotification]s.
  ///
  /// This context is typically different that the context of the scrollable
  /// widget itself. For example, [Scrollable] uses a context outside the
  /// [Viewport] but inside the widgets created by
  /// [ScrollBehavior.buildViewportChrome].
  BuildContext get notificationContext;

  /// A [TickerProvider] to use when animating the scroll position.
  TickerProvider get vsync;

  /// The direction in which the widget scrolls.
  AxisDirection get axisDirection;

  /// Whether the contents of the widget should ignore [PointerEvent] inputs.
  ///
  /// Setting this value to true prevents the use from interacting with the
  /// contents of the widget with pointer events. The widget itself is still
  /// interactive.
  ///
  /// For example, if the scroll position is being driven by an animation, it
  /// might be appropriate to set this value to ignore pointer events to
  /// prevent the user from accidentially interacting with the contents of the
  /// widget as it animates. The user will still be able to touch the widget,
  /// potentially stopping the animation.
  void setIgnorePointer(bool value);

  /// Whether the user can drag the widget, for example to initiate a scroll.
  void setCanDrag(bool value);
}
