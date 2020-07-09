// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'basic.dart';
import 'framework.dart';
import 'navigator.dart';
import 'routes.dart';

/// A modal route that replaces the entire screen.
abstract class PageRoute<T> extends ModalRoute<T> {
  /// Creates a modal route that replaces the entire screen.
  PageRoute({
    RouteSettings settings,
    this.fullscreenDialog = false,
  }) : super(settings: settings);

  /// {@template flutter.widgets.pageRoute.fullscreenDialog}
  /// Whether this page route is a full-screen dialog.
  ///
  /// In Material and Cupertino, being fullscreen has the effects of making
  /// the app bars have a close button instead of a back button. On
  /// iOS, dialogs transitions animate differently and are also not closeable
  /// with the back swipe gesture.
  /// {@endtemplate}
  final bool fullscreenDialog;

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => nextRoute is PageRoute;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => previousRoute is PageRoute;
}

Widget _defaultTransitionsBuilder(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  return child;
}

/// A utility class for defining one-off page routes in terms of callbacks.
///
/// Callers must define the [pageBuilder] function which creates the route's
/// primary contents. To add transitions define the [transitionsBuilder] function.
///
/// See also:
///
///  * [TransitionBuilderPage], which is a [Page] of this class.
class PageRouteBuilder<T> extends PageRoute<T> {
  /// Creates a route that delegates to builder callbacks.
  ///
  /// The [pageBuilder], [transitionsBuilder], [opaque], [barrierDismissible],
  /// [maintainState], and [fullscreenDialog] arguments must not be null.
  PageRouteBuilder({
    RouteSettings settings,
    @required this.pageBuilder,
    this.transitionsBuilder = _defaultTransitionsBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    bool fullscreenDialog = false,
  }) : assert(pageBuilder != null),
       assert(transitionsBuilder != null),
       assert(opaque != null),
       assert(barrierDismissible != null),
       assert(maintainState != null),
       assert(fullscreenDialog != null),
       super(settings: settings, fullscreenDialog: fullscreenDialog);

  /// {@template flutter.widgets.pageRouteBuilder.pageBuilder}
  /// Used build the route's primary contents.
  ///
  /// See [ModalRoute.buildPage] for complete definition of the parameters.
  /// {@endtemplate}
  final RoutePageBuilder pageBuilder;

  /// {@template flutter.widgets.pageRouteBuilder.transitionsBuilder}
  /// Used to build the route's transitions.
  ///
  /// See [ModalRoute.buildTransitions] for complete definition of the parameters.
  /// {@endtemplate}
  final RouteTransitionsBuilder transitionsBuilder;

  @override
  final Duration transitionDuration;

  @override
  final bool opaque;

  @override
  final bool barrierDismissible;

  @override
  final Color barrierColor;

  @override
  final String barrierLabel;

  @override
  final bool maintainState;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return pageBuilder(context, animation, secondaryAnimation);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return transitionsBuilder(context, animation, secondaryAnimation, child);
  }
}

/// A page that creates a [PageRoute] with customizable transition.
///
/// Similar to the [PageRouteBuilder], callers must define the [pageBuilder]
/// function which creates the route's primary contents. To add transitions
/// define the [transitionsBuilder] function.
///
/// See also:
///
///  * [PageRouteBuilder], which is a [PageRoute] version of this class.
class TransitionBuilderPage<T> extends Page<T> {
  /// Creates a [TransitionBuilderPage].
  const TransitionBuilderPage({
    @required this.pageBuilder,
    this.transitionsBuilder = _defaultTransitionsBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    this.fullscreenDialog = false,
    LocalKey key,
    String name,
    Object arguments,
  }) : assert(pageBuilder != null),
       assert(transitionsBuilder != null),
       assert(opaque != null),
       assert(barrierDismissible != null),
       assert(maintainState != null),
       assert(fullscreenDialog != null),
       super(key: key, name: name, arguments: arguments);

  /// {@macro flutter.widgets.pageRouteBuilder.pageBuilder}
  final RoutePageBuilder pageBuilder;

  /// {@macro flutter.widgets.pageRouteBuilder.transitionsBuilder}
  final RouteTransitionsBuilder transitionsBuilder;

  /// {@macro flutter.widgets.transitionRoute.transitionDuration}
  final Duration transitionDuration;

  /// {@macro flutter.widgets.transitionRoute.opaque}
  final bool opaque;

  /// {@macro flutter.widgets.modalRoute.barrierDismissible}
  final bool barrierDismissible;

  /// {@macro flutter.widgets.modalRoute.barrierColor}
  final Color barrierColor;

  /// {@macro flutter.widgets.modalRoute.barrierLabel}
  final String barrierLabel;

  /// {@macro flutter.widgets.modalRoute.maintainState}
  final bool maintainState;

  /// {@macro flutter.widgets.pageRoute.fullscreenDialog}
  final bool fullscreenDialog;

  @override
  Route<T> createRoute(BuildContext context) => _PageBasedPageRouteBuilder<T>(this);
}

// A page-based version of the [PageRouteBuilder].
//
// This class gets its builder and settings directly from the [TransitionBuilderPage],
// so that its content updates accordingly to the [TransitionBuilderPage].
class _PageBasedPageRouteBuilder<T> extends PageRoute<T>{
  _PageBasedPageRouteBuilder(
    TransitionBuilderPage<T> page,
  ) : assert(page != null),
       super(settings: page, fullscreenDialog: page.fullscreenDialog);

  TransitionBuilderPage<T> get _page => settings as TransitionBuilderPage<T>;

  @override
  Duration get transitionDuration => _page.transitionDuration;

  @override
  bool get opaque => _page.opaque;

  @override
  bool get barrierDismissible => _page.barrierDismissible;

  @override
  Color get barrierColor => _page.barrierColor;

  @override
  String get barrierLabel => _page.barrierLabel;

  @override
  bool get maintainState => _page.maintainState;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return _page.pageBuilder(context, animation, secondaryAnimation);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return _page.transitionsBuilder(context, animation, secondaryAnimation, child);
  }
}
