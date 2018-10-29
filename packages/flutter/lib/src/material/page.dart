// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

import 'page_transitions_theme.dart';
import 'theme.dart';

/// A modal route that replaces the entire screen with a platform-adaptive
/// transition.
///
/// For Android, the entrance transition for the page slides the page upwards
/// and fades it in. The exit transition is the same, but in reverse.
///
/// The transition is adaptive to the platform and on iOS, the page slides in
/// from the right and exits in reverse. The page also shifts to the left in
/// parallax when another page enters to cover it. (These directions are flipped
/// in environments with a right-to-left reading direction.)
///
/// By default, when a modal route is replaced by another, the previous route
/// remains in memory. To free all the resources when this is not necessary, set
/// [maintainState] to false.
///
/// The `fullscreenDialog` property specifies whether the incoming page is a
/// fullscreen modal dialog. On iOS, those pages animate from the bottom to the
/// top rather than horizontally.
///
/// The type `T` specifies the return type of the route which can be supplied as
/// the route is popped from the stack via [Navigator.pop] by providing the
/// optional `result` argument.
///
/// See also:
///
///  * [PageTransitionsTheme], which defines the default page transitions used
///    by [MaterialPageRoute.buildTransitions].
///
class MaterialPageRoute<T> extends PageRoute<T> {
  /// Construct a MaterialPageRoute whose contents are defined by [builder].
  ///
  /// The values of [builder], [maintainState], and [fullScreenDialog] must not
  /// be null.
  MaterialPageRoute({
    @required this.builder,
    RouteSettings settings,
    this.maintainState = true,
    bool fullscreenDialog = false,
  }) : assert(builder != null),
       assert(maintainState != null),
       assert(fullscreenDialog != null),
       super(settings: settings, fullscreenDialog: fullscreenDialog) {
    // ignore: prefer_asserts_in_initializer_lists , https://github.com/dart-lang/sdk/issues/31223
    assert(opaque);
  }

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  @override
  final bool maintainState;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return previousRoute is MaterialPageRoute || previousRoute is CupertinoPageRoute;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    return (nextRoute is MaterialPageRoute && !nextRoute.fullscreenDialog)
        || (nextRoute is CupertinoPageRoute && !nextRoute.fullscreenDialog);
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final Widget result = builder(context);
    assert(() {
      if (result == null) {
        throw FlutterError(
          'The builder for route "${settings.name}" returned null.\n'
          'Route builders must never return null.'
        );
      }
      return true;
    }());
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: result,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final PageTransitionsTheme theme = Theme.of(context).pageTransitionsTheme;
    return theme.buildTransitions<T>(this, context, animation, secondaryAnimation, child);
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}
