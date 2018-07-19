// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'route.dart';

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
class CupertinoPageScaffold extends StatefulWidget {
  /// Creates a layout for pages with a navigation bar at the top.
  const CupertinoPageScaffold({
    Key key,
    this.navigationBar,
    this.backgroundColor = CupertinoColors.white,
    this.title,
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

  final String title;

  @override
  _CupertinoPageScaffoldState createState() {
    return new _CupertinoPageScaffoldState();
  }
}

class _CupertinoPageScaffoldState extends State<CupertinoPageScaffold> implements CupertinoPageTitleProvider {
  CupertinoPageRoute<dynamic> currentRoute;

  @override
  void didChangeDependencies() {
    final ModalRoute<dynamic> route = ModalRoute.of(context);
    if (route is CupertinoPageRoute) {
      currentRoute = route;
      currentRoute.titleProvider = this;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    currentRoute?.titleProvider = null;
    super.dispose();
  }

  @override
  String get title => widget.title;

  @override
  Widget build(BuildContext context) {
    final List<Widget> stacked = <Widget>[];

    Widget paddedContent = widget.child;
    if (widget.navigationBar != null) {
      final MediaQueryData existingMediaQuery = MediaQuery.of(context);

      // TODO(xster): Use real size after partial layout instead of preferred size.
      // https://github.com/flutter/flutter/issues/12912
      final double topPadding = widget.navigationBar.preferredSize.height
          + existingMediaQuery.padding.top;

      // If navigation bar is opaquely obstructing, directly shift the main content
      // down. If translucent, let main content draw behind navigation bar but hint the
      // obstructed area.
      if (widget.navigationBar.fullObstruction) {
        paddedContent = new Padding(
          padding: new EdgeInsets.only(top: topPadding),
          child: widget.child,
        );
      } else {
        paddedContent = new MediaQuery(
          data: existingMediaQuery.copyWith(
            padding: existingMediaQuery.padding.copyWith(
              top: topPadding,
            ),
          ),
          child: widget.child,
        );
      }
    }

    // The main content being at the bottom is added to the stack first.
    stacked.add(paddedContent);

    if (widget.navigationBar != null) {
      stacked.add(new Positioned(
        top: 0.0,
        left: 0.0,
        right: 0.0,
        child: widget.navigationBar,
      ));
    }

    return new DecoratedBox(
      decoration: new BoxDecoration(color: widget.backgroundColor),
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
