// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

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

  /// The [BuildContext] that should be used when searching for a [PageStorage].
  ///
  /// This context is typically the context of the scrollable widget itself. In
  /// particular, it should involve any [GlobalKey]s that are dynamically
  /// created as part of creating the scrolling widget, since those would be
  /// different each time the widget is created.
  // TODO(goderbauer): Deprecate this when state restoration supports all features of PageStorage.
  BuildContext get storageContext;

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
  /// prevent the user from accidentally interacting with the contents of the
  /// widget as it animates. The user will still be able to touch the widget,
  /// potentially stopping the animation.
  void setIgnorePointer(bool value);

  /// Whether the user can drag the widget, for example to initiate a scroll.
  void setCanDrag(bool value);

  /// Set the [SemanticsAction]s that should be expose to the semantics tree.
  void setSemanticsActions(Set<SemanticsAction> actions);

  /// Called by the [ScrollPosition] whenever scrolling ends to persist the
  /// provided scroll `offset` for state restoration purposes.
  ///
  /// The [ScrollContext] may pass the value back to a [ScrollPosition] by
  /// calling [ScrollPosition.restoreOffset] at a later point in time or after
  /// the application has restarted to restore the scroll offset.
  void saveOffset(double offset);
}
