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
///  * [CupertinoPageRoute] a modal page route that typically hosts a [CupertinoPageRoute]
///    with support for iOS style page transitions.
class CupertinoPageScaffold extends StatelessWidget {
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
    double topPadding = 0.0;
    if (navigationBar != null) {
      topPadding += navigationBar.preferredSize.height;
      if (topPadding > 0.0)
        topPadding += MediaQuery.of(context).padding.top;
    }

    // The main content being at the bottom is added to the stack first.
    stacked.add(new Padding(
      padding: new EdgeInsets.only(top: topPadding),
      child: child,
    ));

    if (navigationBar != null) {
      stacked.add(new Align(
        alignment: FractionalOffset.topCenter,
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