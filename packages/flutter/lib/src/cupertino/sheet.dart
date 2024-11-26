// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'route.dart';

// Offset from offscreen below to stopping below the top of the screen.
final Animatable<Offset> _kBottomUpTween = Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: const Offset(0.0, 0.08),
);

// Offset change for when a new sheet covers another sheet. '0.0' represents the
// top of the space available for the new sheet, but because the previous sheet
// was lowered slightly, the new sheet needs to go slightly higher than that.
final Animatable<Offset> _kFullBottomUpTween = Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: const Offset(0.0, -0.02),
);

// Offset slightly up when a sheet gets covered by another sheet.
final Animatable<Offset> _kMidUpTween = Tween<Offset>(
  begin: Offset.zero,
  end: const Offset(0.0, -0.005),
);

// Offset from top of screen to slightly down when a fullscreen page is covered
// by a sheet.
final Animatable<Offset> _kTopDownTween = Tween<Offset>(
  begin: Offset.zero,
  end: const Offset(0.0, 0.07),
);

// Amount the sheet in the background scales down. Found by measuring the width
// of the sheet in the background and comparing against the screen width. The
// scale transition will go from a default of 1.0 to 1.0 - _kSheetScaleFactor.
const double _kSheetScaleFactor = 0.0835;

final Animatable<double> _kScaleTween = Tween<double>(begin: 1.0, end: 1.0 - _kSheetScaleFactor);

/// Shows a Cupertino style sheet widget that slides up from the bottom of the
/// screen and stacks the previous route behind the new sheet.
///
/// This is a convenience method for displaying [CupertinoSheetRoute] for common,
/// straightforward use cases. The return of `pageBuilder` will be used to display
/// the content on the [CupertinoSheetRoute].
///
/// `useNestedNavigation` controls whether or not boilerplate code is setup for
/// enabling nested navigation for the sheet.
///
/// When `useNestedNavigation` is set to `true`, any route pushed to the stack
/// from within the context of the [CupertinoSheetRoute] will display within that
/// sheet. System back gestures, and programatic pops on the initial route in a
/// sheet will also be intercepted to pop the whole [CupertinoSheetRoute]. If
/// another [Navigator] setup is needed, like for example to enamble named routes
/// or the pages API, then it is recommended to directly push a [CupertinoSheetRoute]
/// to the stack with whatever configuration needed. See the implementation below
/// for the boilerplate provided by `showCupertinoSheet` to get started.
///
/// The whole sheet can be popped at once by either dragging down on the shet,
/// or calling [CupertinoSheetRoute.popSheet].
///
/// iOS sheet widgets are generally designed to be tightly coupled to the context
/// of the widget that opened the sheet. As such, it is not recommended to directly
/// link to a route outside of the sheet, without first popping the sheet. If that
/// is needed however, it can be done by pushing to the root Navigator.
///
/// If `useNestedNavigation` is left as `false`, then a [CupertinoSheetRoute]
/// will be shown with no [Navigator] widget. Multiple calls to `showCupertinoSheet`
/// can still be made to show multiple stacked sheets, if desired.
///
/// In both cases, new [CupertinoSheetRoute]s will be pushed to the root
/// [Navigator]. This is to ensure the previous routes animate correctly.
///
/// Returns a [Future] that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the sheet was closed.
///
/// {@tool dartpad}
/// This example shows how to navigate to use [showCupertinoSheet] to display a
/// Cupertino sheet widget with nested navigation.
///
/// ** See code in examples/api/lib/cupertino/sheet/cupertino_sheet.2.dart **
/// {@end-tool}
///
/// See also:
///
///  * [CupertinoSheetRoute] the basic route version of the sheet view.
///  * [showCupertinoDialog] which displays an iOS-styled dialog.
Future<T?> showCupertinoSheet<T>({
  required BuildContext context,
  required WidgetBuilder pageBuilder,
  bool useNestedNavigation = false,
}) {
  final WidgetBuilder builder;
  if (!useNestedNavigation) {
    builder = pageBuilder;
  } else {
    builder = (BuildContext context) {
      return NavigatorPopHandler(
        onPopWithResult: (T? result) {
          Navigator.of(context, rootNavigator: true).maybePop(result);
        },
        child: Navigator(
          initialRoute: '/',
          onGenerateRoute: (RouteSettings settings) {
            return CupertinoPageRoute<void>(
              builder: (BuildContext context) {
                return PopScope(
                  canPop: settings.name != '/',
                  onPopInvokedWithResult: (bool didPop, Object? result) {
                    if (didPop) {
                      return;
                    }
                    Navigator.of(context, rootNavigator: true).pop(result);
                  },
                  child: pageBuilder(context),
                );
              }
            );
          },
        ),
      );
    };
  }

  return Navigator.of(context, rootNavigator: true).push<T>(CupertinoSheetRoute<T>(
    builder: builder,
  ));
}

/// Provides an iOS style sheet transition.
///
/// The page slides up and stops below the top of the screen. When covered by
/// another sheet view, it will slide slightly up and scale down to appear
/// stacked behind the new sheet.
class CupertinoSheetTransition extends StatelessWidget {
  /// Creates an iOS style sheet transition.
  const CupertinoSheetTransition({
    super.key,
    required this.primaryRouteAnimation,
    required this.secondaryRouteAnimation,
    required this.child,
  });

  /// `primaryRouteAnimation` is a linear route animation from 0.0 to 1.0 when
  /// this screen is being pushed.
  final Animation<double> primaryRouteAnimation;

  /// `secondaryRouteAnimation` is a linear route animation from 0.0 to 1.0 when
  /// another screen is being pushed on top of this one.
  final Animation<double> secondaryRouteAnimation;

  /// The widget below this widget in the tree.
  final Widget child;

  /// The primary delegated transition. Will slide a non [CupertinoSheetRoute] page down.
  ///
  /// Provided to the previous route to coordinate transitions between routes.
  ///
  /// If a [CupertinoSheetRoute] already exists in the stack, then it will
  /// slide the previous sheet upwards instead.
  static Widget delegateTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, bool allowSnapshotting, Widget? child) {
    if (CupertinoSheetRoute.hasParentSheet(context)) {
      return _coverSheetSecondaryTransition(secondaryAnimation, child);
    }

    const Curve curve = Curves.linearToEaseOut;
    const Curve reverseCurve = Curves.easeInToLinear;
    final Animation<double> curvedAnimation = CurvedAnimation(
      curve: curve,
      reverseCurve: reverseCurve,
      parent: secondaryAnimation
    );
    final double deviceCornerRadius = MediaQuery.maybeViewPaddingOf(context)?.top ?? 0;

    final Animatable<BorderRadiusGeometry> decorationTween = Tween<BorderRadiusGeometry>(
      begin: BorderRadius.circular(deviceCornerRadius),
      end: BorderRadius.circular(12),
    );

    final Animation<BorderRadiusGeometry> radiusAnimation = curvedAnimation.drive(decorationTween);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return SlideTransition(
      position: curvedAnimation.drive(_kTopDownTween),
      child: ScaleTransition(
        scale: curvedAnimation.drive(_kScaleTween),
        filterQuality: FilterQuality.medium,
        alignment: Alignment.topCenter,
        child: AnimatedBuilder(
          animation: radiusAnimation,
          child: child,
          builder: (BuildContext context, Widget? child) {
            return ClipRRect(
              borderRadius: radiusAnimation.value,
              child: child
            );
          }
        )
      ),
    );
  }

  static Widget _coverSheetPrimaryTransition(BuildContext context, Animation<double> animation, Widget? child) {
    final Animatable<Offset> offsetTween =
      CupertinoSheetRoute.hasParentSheet(context) ?
      _kFullBottomUpTween :
      _kBottomUpTween;

    final Animation<Offset> positionAnimation =
      CurvedAnimation(
            parent: animation,
            curve: Curves.fastEaseInToSlowEaseOut,
            reverseCurve: Curves.fastEaseInToSlowEaseOut.flipped,
          ).drive(offsetTween);

    return SlideTransition(
      position: positionAnimation,
      child: child,
    );
  }

  static Widget _coverSheetSecondaryTransition(Animation<double> secondaryAnimation, Widget? child) {
    const Curve curve = Curves.linearToEaseOut;
    const Curve reverseCurve = Curves.easeInToLinear;
    final Animation<double> curvedAnimation = CurvedAnimation(
      curve: curve,
      reverseCurve: reverseCurve,
      parent: secondaryAnimation
    );

    return SlideTransition(
      position: curvedAnimation.drive(_kMidUpTween),
      transformHitTests: false,
      child: ScaleTransition(
        scale: curvedAnimation.drive(_kScaleTween),
        filterQuality: FilterQuality.medium,
        alignment: Alignment.topCenter,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CupertinoColors.transparent,
      child: _coverSheetSecondaryTransition(
        secondaryRouteAnimation,
        _coverSheetPrimaryTransition(
          context,
          primaryRouteAnimation,
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Route for displaying an iOS sheet styled page.
///
/// The `CupertinoSheetRoute` will slide up from the bottom of the screen and stop
/// below the top of the screen. If the previous route is a non-sheet route, than
/// it will animate downwards to stack behind the new sheet. If the previous route
/// is a sheet route, than it will animate slightly upwards to look like it is laying
/// on top of the previous stack of sheets.
///
/// Typically called by [showCupertinoSheet], which provides some boilerplate for
/// pushing the `CupertinoSheetRoute` to the root navigator and providing simple
/// nested naviagation.
///
/// The sheet will be dismissed by dragging downwards on the screen, or a call to
/// [CupertinoSheetRoute.popSheet].
///
/// {@tool dartpad}
/// This example shows how to navigate to [CupertinoSheetRoute] by using it the
/// same as a regular route.
///
/// ** See code in examples/api/lib/cupertino/sheet/cupertino_sheet.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows how to setup a [CupertinoSheetRoute] with nested navigation.
/// This allows for pushing to new routes that transition from within the sheet
/// view.
///
/// This example can be acieved by calling [showCupertinoSheet], which sets up
/// much of the same boilderplate by default.
///
/// ** See code in examples/api/lib/cupertino/sheet/cupertino_sheet.1.dart **
/// {@end-tool}
class CupertinoSheetRoute<T> extends PageRoute<T> with CupertinoSheetRouteTransitionMixin<T> {
  /// Creates a page route that displays an iOS styled sheet.
  CupertinoSheetRoute({
    required this.builder,
  });

  /// Builds the primary contents of the sheet route.
  final WidgetBuilder builder;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => CupertinoSheetTransition.delegateTransition;

  @override
  Widget buildContent(BuildContext context) {
    return _CupertinoSheetScope(
      child: builder(context),
    );
  }

  /// Checks if a Cupertino sheet view exists in the widget tree above the current
  /// context.
  static bool hasParentSheet(BuildContext context) {
    return _CupertinoSheetScope.maybeOf(context) != null;
  }

  /// Pops the entire [CupertinoSheetRoute], if a sheet route exists in the stack.
  ///
  /// Used if to pop an entire sheet at once, if there is nested naviagtion within
  /// that sheet.
  static void popSheet(BuildContext context) {
    if (hasParentSheet(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // Slightly darkens the sheet behind. Eyeballed from a simulator running iOS 18.0
  // TODO(mitchgoodwin): Adjust with darkmode logic.
  @override
  Color? get barrierColor => const Color(0x20000000);

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => 'Stacked card appearance for modal bottom sheet';

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;
}

// Internally used to see if another sheet is in the tree already.
class _CupertinoSheetScope extends InheritedWidget {
  const _CupertinoSheetScope({
    required super.child,
  });

  static _CupertinoSheetScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_CupertinoSheetScope>();
  }

  @override
  bool updateShouldNotify(_CupertinoSheetScope oldWidget) => oldWidget.key != null && key != null && oldWidget.key != key;
}

/// A mixin that replaces the entire screen with an iOS sheet transition for a
/// [PageRoute].
///
/// See also:
///
///  * [CupertinoSheetRoute], which is a [PageRoute] that leverages this mixin.
mixin CupertinoSheetRouteTransitionMixin<T> on PageRoute<T> {
  /// Builds the primary contents of the route.
  @protected
  Widget buildContent(BuildContext context);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 500);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final Widget child = buildContent(context);
    return child;
  }

  /// Returns a [CupertinoSheetTransition].
  static Widget buildPageTransitions<T>(
    ModalRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return CupertinoSheetTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      child: child,
    );
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is CupertinoSheetRouteTransitionMixin;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return buildPageTransitions<T>(this, context, animation, secondaryAnimation, child);
  }
}
