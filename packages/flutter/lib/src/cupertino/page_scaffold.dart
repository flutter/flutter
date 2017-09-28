// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'nav_bar.dart';

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
    @required this.child,
  }) : assert(child != null),
       super(key: key);

  /// The [navigationBar], typically a [CupertinoNavigationBar], is drawn at the
  /// top of the screen.
  ///
  /// If translucent, the main content may slide behind it.
  /// Otherwise, the main content's top margin will be offset by its height.
  // TODO(xster): document its page transition animation when ready
  final PreferredSizeWidget navigationBar;

  /// Widget to show in the main content area.
  ///
  /// Content can slide under the [navigationBar] when they're translucent.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final List<Widget> stacked = <Widget>[];
    Widget childWithMediaQuery = child;

    double topPadding = 0.0;
    if (navigationBar != null) {
      topPadding += navigationBar.preferredSize.height;
      // If the navigation bar has a preferred size, pad it and the OS status
      // bar as well. Otherwise, let the content extend to the complete top
      // of the page.
      if (topPadding > 0.0) {
        final EdgeInsets mediaQueryPadding = MediaQuery.of(context).padding;
        topPadding += mediaQueryPadding.top;
        childWithMediaQuery = new MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: mediaQueryPadding.copyWith(top: 0.0),
          ),
          child: child,
        );
      }
    }

    // The main content being at the bottom is added to the stack first.
    stacked.add(new Padding(
      padding: new EdgeInsets.only(top: topPadding),
      child: childWithMediaQuery,
    ));

    if (navigationBar != null) {
      stacked.add(new Positioned(
        top: 0.0,
        left: 0.0,
        right: 0.0,
        child: navigationBar,
      ));
    }

    return new DecoratedBox(
      decoration: const BoxDecoration(color: CupertinoColors.white),
      child: new Stack(
        children: stacked,
      ),
    );
  }
}