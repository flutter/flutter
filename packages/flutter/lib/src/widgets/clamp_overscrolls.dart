// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'framework.dart';
import 'scrollable.dart';

/// Signature for building the contents of a scrollable widget.
///
/// Typically returns a tree of widgets that includes the viewport that will be
/// scrolled to the given `scrollOffset`.
typedef Widget ViewportBuilder(BuildContext context, ScrollableState state, double scrollOffset);

/// A widget that controls whether [Scrollable] descendants will overscroll.
///
/// If `true`, the ClampOverscroll's [Scrollable] descendant will clamp its
/// viewport's scrollOffsets to the [ScrollBehavior]'s min and max values.
/// In this case the Scrollable's scrollOffset will still over- and undershoot
/// the ScrollBehavior's limits, but the viewport itself will not.
class ClampOverscrolls extends InheritedWidget {
  /// Creates a widget that controls whether [Scrollable] descendants will overscroll.
  ///
  /// The [value] and [child] arguments must not be null.
  ClampOverscrolls({
    Key key,
    @required this.value,
    @required Widget child
  }) : super(key: key, child: child) {
    assert(value != null);
    assert(child != null);
  }

  /// Whether [Scrollable] descendants should clamp their viewport's
  /// scrollOffset values when they are less than the [ScrollBehavior]'s minimum
  /// or greater than its maximum.
  final bool value;

  /// Whether a [Scrollable] widget within the given context should overscroll.
  static bool of(BuildContext context) {
    final ClampOverscrolls result = context.inheritFromWidgetOfExactType(ClampOverscrolls);
    return result?.value ?? false;
  }

  /// If ClampOverscrolls is true, clamps the ScrollableState's scrollOffset to the
  /// [ScrollBehavior] minimum and maximum values and then constructs the viewport
  /// with the clamped scrollOffset. ClampOverscrolls is reset to false for viewport
  /// descendants.
  ///
  /// This utility function is typically used by [Scrollable.builder] callbacks.
  static Widget buildViewport(BuildContext context, ScrollableState state, ViewportBuilder builder) {
    final bool clampOverscrolls = ClampOverscrolls.of(context);
    final double clampedScrollOffset = clampOverscrolls
      ? state.scrollOffset.clamp(state.scrollBehavior.minScrollOffset, state.scrollBehavior.maxScrollOffset)
      : state.scrollOffset;
   Widget viewport = builder(context, state, clampedScrollOffset);
   if (clampOverscrolls)
     viewport = new ClampOverscrolls(value: false, child: viewport);
   return viewport;
  }

  @override
  bool updateShouldNotify(ClampOverscrolls old) => value != old.value;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('value: $value');
  }
}
