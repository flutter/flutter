// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'scroll_physics.dart';
library;

import 'package:flutter/foundation.dart';

import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_configuration.dart';
import 'scroll_metrics.dart';
import 'scroll_notification.dart';
import 'scrollable.dart';

/// A wrapper widget that enables browser-driven scrolling, forwards
/// touch-driven overscroll to the browser, and disables Flutter scrollbars.
///
/// Place this above the outermost scrollable. It sets
/// [ScrollBehavior.enableBrowserScrolling] to true, which causes
/// [ScrollableState] to set up browser scrolling via dart:ui and automatically
/// apply [BrowserScrollPhysics]. This widget adds two things on top:
///
/// 1. Catches [OverscrollNotification] from touch drag gestures and forwards
///    them to the browser via `scrollBy`, except at the edges where
///    [RefreshIndicator] or load-more indicators need the notification.
/// 2. Disables Flutter-drawn scrollbars since the browser provides its own.
///
/// Programmatic scrolling with [ScrollController.animateTo] and
/// [ScrollController.jumpTo] works automatically when browser scrolling is
/// active. Both are routed through the browser's native scroll mechanism,
/// so they respect the actual content height even under lazy layout.
///
/// Known limitations:
///
/// * Only one [BrowserScrollable] can drive the browser at a time. Mounting
///   a second one while another holds the slot leaves the second on
///   Dart-driven physics. This shows up with `Navigator.push` to a route
///   whose body is wrapped in [BrowserScrollable]: the pushed page is
///   rejected because the route below it still owns the slot. Slot
///   reclaim is on the roadmap; for now, build flows that have a single
///   browser-scroll route at a time.
/// * Only the full-page embedding strategy supports browser scrolling.
///   Custom-element views report unsupported, which means the wrapped
///   scrollable falls back to Dart-driven scrolling (no [BrowserScrollPhysics]
///   is applied).
/// * On iOS Safari, touch-drag inside a cross-origin iframe nested under
///   this widget waits for the iframe's internal momentum to finish before
///   chaining to the parent page. This is a browser-level behavior that
///   cannot be intercepted from the parent document.
///
/// Example:
/// ```dart
/// // ignore_for_file: experimental_member_use
/// BrowserScrollable(
///   child: ListView.builder(
///     itemCount: 100,
///     itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
///   ),
/// )
/// ```
@experimental
class BrowserScrollable extends StatelessWidget {
  /// Creates a widget that enables browser-driven scrolling for its child.
  const BrowserScrollable({super.key, required this.child});

  /// The child widget, typically a scrollable like [ListView].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollNotification>(
      onNotification: _handleOverscrollNotification,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(
          context,
        ).copyWith(scrollbars: false, enableBrowserScrolling: true),
        child: child,
      ),
    );
  }

  static bool _handleOverscrollNotification(OverscrollNotification notification) {
    final double delta = notification.overscroll;
    final ScrollMetrics metrics = notification.metrics;

    if (delta < 0 && metrics.pixels <= metrics.minScrollExtent) {
      return false;
    }
    if (delta > 0 && metrics.pixels >= metrics.maxScrollExtent) {
      return false;
    }

    if (delta.abs() > 0.5) {
      ScrollableState.browserScrollViewBinding?.browserScrollBy(delta);
    }
    return true;
  }
}
