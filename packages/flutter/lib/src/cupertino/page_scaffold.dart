// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

/// Implements a single iOS application page's layout.
///
/// The scaffold lays out the navigation bar on top and the content between or
/// behind the navigation bar.
///
/// See also:
///
///  * [CupertinoTabScaffold], a similar widget for tabbed applications.
///  * [CupertinoPageRoute], a modal page route that typically hosts a
///    [CupertinoPageScaffold] with support for iOS-style page transitions.
class CupertinoPageScaffold extends StatelessWidget {
  /// Creates a layout for pages with a navigation bar at the top.
  const CupertinoPageScaffold({
    Key key,
    this.navigationBar,
    this.backgroundColor: CupertinoColors.white,
    @required this.child,
  }) : assert(child != null),
       super(key: key);

  /// The [navigationBar], typically a [CupertinoNavigationBar], is drawn at the
  /// top of the screen.
  ///
  /// If translucent, the main content may slide behind it.
  /// Otherwise, the main content's top margin will be offset by its height.
  ///
  /// The scaffold assumes the navigation bar will consume the [MediaQuery] top padding.
  // TODO(xster): document its page transition animation when ready
  final ObstructingPreferredSizeWidget navigationBar;

  /// Widget to show in the main content area.
  ///
  /// Content can slide under the [navigationBar] when they're translucent.
  /// In that case, the child's [BuildContext]'s [MediaQuery] will have a
  /// top padding indicating the area of obstructing overlap from the
  /// [navigationBar].
  final Widget child;

  /// The color of the widget that underlies the entire scaffold.
  ///
  /// By default uses [CupertinoColors.white] color.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final List<Widget> stacked = <Widget>[];

    Widget paddedContent = child;
    if (navigationBar != null) {
      final MediaQueryData existingMediaQuery = MediaQuery.of(context);

      // TODO(xster): Use real size after partial layout instead of preferred size.
      // https://github.com/flutter/flutter/issues/12912
      final double topPadding = navigationBar.preferredSize.height
          + existingMediaQuery.padding.top;

      // If navigation bar is opaquely obstructing, directly shift the main content
      // down. If translucent, let main content draw behind navigation bar but hint the
      // obstructed area.
      if (navigationBar.fullObstruction) {
        paddedContent = new Padding(
          padding: new EdgeInsets.only(top: topPadding),
          child: child,
        );
      } else {
        paddedContent = new MediaQuery(
          data: existingMediaQuery.copyWith(
            padding: existingMediaQuery.padding.copyWith(
              top: topPadding,
            ),
          ),
          child: child,
        );
      }
    }

    // The main content being at the bottom is added to the stack first.
    stacked.add(paddedContent);

    if (navigationBar != null) {
      stacked.add(new Positioned(
        top: 0.0,
        left: 0.0,
        right: 0.0,
        child: navigationBar,
      ));
    }

    return new DecoratedBox(
      decoration: new BoxDecoration(color: backgroundColor),
      child: new Stack(
        children: stacked,
      ),
    );
  }
}

/// Widget that has a preferred size and reports whether it fully obstructs
/// widgets behind it.
///
/// Used by [CupertinoPageScaffold] to either shift away fully obstructed content
/// or provide a padding guide to partially obstructed content.
abstract class ObstructingPreferredSizeWidget extends PreferredSizeWidget {
  /// If true, this widget fully obstructs widgets behind it by the specified
  /// size.
  ///
  /// If false, this widget partially obstructs.
  bool get fullObstruction;
}
