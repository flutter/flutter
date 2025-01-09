// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'interface_level.dart';
import 'route.dart';

// Tween for animating a Cupertino sheet onto the screen.
//
// Begins fully offscreen below the screen and ends onscreen with a small gap at
// the top of the screen. Values found from eyeballing a simulator running iOS 18.0.
final Animatable<Offset> _kBottomUpTween = Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: const Offset(0.0, 0.08),
);

// Offset change for when a new sheet covers another sheet. '0.0' represents the
// top of the space available for the new sheet, but because the previous sheet
// was lowered slightly, the new sheet needs to go slightly higher than that.
// Values found from eyeballing a simulator running iOS 18.0.
final Animatable<Offset> _kBottomUpTweenWhenCoveringOtherSheet = Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: const Offset(0.0, -0.02),
);

// Tween that animates a sheet slightly up when it is covered by a new sheet.
// Values found from eyeballing a simulator running iOS 18.0.
final Animatable<Offset> _kMidUpTween = Tween<Offset>(
  begin: Offset.zero,
  end: const Offset(0.0, -0.005),
);

// Offset from top of screen to slightly down when a fullscreen page is covered
// by a sheet. Values found from eyeballing a simulator running iOS 18.0.
final Animatable<Offset> _kTopDownTween = Tween<Offset>(
  begin: Offset.zero,
  end: const Offset(0.0, 0.07),
);

// Opacity of the overlay color put over the sheet as it moves into the background.
// Used to distinguish the sheet from the background. Value derived from eyeballing
// a simulator running iOS 18.0.
final Animatable<double> _kOpacityTween = Tween<double>(begin: 0.0, end: 0.10);

// Amount the sheet in the background scales down. Found by measuring the width
// of the sheet in the background and comparing against the screen width on the
// iOS simulator showing an iPhone 16 pro running iOS 18.0. The scale transition
// will go from a default of 1.0 to 1.0 - _kSheetScaleFactor.
const double _kSheetScaleFactor = 0.0835;

final Animatable<double> _kScaleTween = Tween<double>(begin: 1.0, end: 1.0 - _kSheetScaleFactor);

/// Shows a Cupertino-style sheet widget that slides up from the bottom of the
/// screen and stacks the previous route behind the new sheet.
///
/// This is a convenience method for displaying [CupertinoSheetRoute] for common,
/// straightforward use cases. The Widget returned from `pageBuilder` will be
/// used to display the content on the [CupertinoSheetRoute].
///
/// `useNestedNavigation` allows new routes to be pushed inside of a [CupertinoSheetRoute]
/// by adding a new [Navigator] inside of the [CupertinoSheetRoute].
///
/// When `useNestedNavigation` is set to `true`, any route pushed to the stack
/// from within the context of the [CupertinoSheetRoute] will display within that
/// sheet. System back gestures and programatic pops on the initial route in a
/// sheet will also be intercepted to pop the whole [CupertinoSheetRoute]. If
/// a custom [Navigator] setup is needed, like for example to enable named routes
/// or the pages API, then it is recommended to directly push a [CupertinoSheetRoute]
/// to the stack with whatever configuration needed. See [CupertinoSheetRoute] for
/// an example that manually sets up nested navigation.
///
/// The whole sheet can be popped at once by either dragging down on the sheet,
/// or calling [CupertinoSheetRoute.popSheet].
///
/// iOS sheet widgets are generally designed to be tightly coupled to the context
/// of the widget that opened the sheet. As such, it is not recommended to push
/// a non-sheet route that covers the sheet without first popping the sheet. If
/// necessary however, it can be done by pushing to the root [Navigator].
///
/// If `useNestedNavigation` is `false` (the default), then a [CupertinoSheetRoute]
/// will be shown with no [Navigator] widget. Multiple calls to `showCupertinoSheet`
/// can still be made to show multiple stacked sheets, if desired.
///
/// `showCupertinoSheet` always pushes the [CupertinoSheetRoute] to the root
/// [Navigator]. This is to ensure the previous route animates correctly.
///
/// Returns a [Future] that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the sheet was closed.
///
/// {@tool dartpad}
/// This example shows how to navigate to use [showCupertinoSheet] to display a
/// Cupertino sheet widget with nested navigation.
///
/// ** See code in examples/api/lib/cupertino/sheet/cupertino_sheet.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [CupertinoSheetRoute] the basic route version of the sheet view.
///  * [showCupertinoDialog] which displays an iOS-styled dialog.
///  * <https://developer.apple.com/design/human-interface-guidelines/sheets>
Future<T?> showCupertinoSheet<T>({
  required BuildContext context,
  required WidgetBuilder pageBuilder,
  bool useNestedNavigation = false,
}) {
  final WidgetBuilder builder;
  final GlobalKey<NavigatorState> nestedNavigatorKey = GlobalKey<NavigatorState>();
  if (!useNestedNavigation) {
    builder = pageBuilder;
  } else {
    builder = (BuildContext context) {
      return NavigatorPopHandler(
        onPopWithResult: (T? result) {
          nestedNavigatorKey.currentState!.maybePop();
        },
        child: Navigator(
          key: nestedNavigatorKey,
          initialRoute: '/',
          onGenerateInitialRoutes: (NavigatorState navigator, String initialRouteName) {
            return <Route<void>>[
              CupertinoPageRoute<void>(
                builder: (BuildContext context) {
                  return PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (bool didPop, Object? result) {
                      if (didPop) {
                        return;
                      }
                      Navigator.of(context, rootNavigator: true).pop(result);
                    },
                    child: pageBuilder(context),
                  );
                },
              ),
            ];
          },
        ),
      );
    };
  }

  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<T>(CupertinoSheetRoute<T>(builder: builder));
}

/// Provides an iOS-style sheet transition.
///
/// The page slides up and stops below the top of the screen. When covered by
/// another sheet view, it will slide slightly up and scale down to appear
/// stacked behind the new sheet.
class CupertinoSheetTransition extends StatefulWidget {
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
  static Widget delegateTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    if (CupertinoSheetRoute.hasParentSheet(context)) {
      return _delegatedCoverSheetSecondaryTransition(secondaryAnimation, child);
    }

    const Curve curve = Curves.linearToEaseOut;
    const Curve reverseCurve = Curves.easeInToLinear;
    final CurvedAnimation curvedAnimation = CurvedAnimation(
      curve: curve,
      reverseCurve: reverseCurve,
      parent: secondaryAnimation,
    );
    final double deviceCornerRadius = MediaQuery.maybeViewPaddingOf(context)?.top ?? 0;

    final Animatable<BorderRadiusGeometry> decorationTween = Tween<BorderRadiusGeometry>(
      begin: BorderRadius.circular(deviceCornerRadius),
      end: BorderRadius.circular(12),
    );

    final Animation<BorderRadiusGeometry> radiusAnimation = curvedAnimation.drive(decorationTween);
    final Animation<double> opacityAnimation = curvedAnimation.drive(_kOpacityTween);
    final Animation<Offset> slideAnimation = curvedAnimation.drive(_kTopDownTween);
    final Animation<double> scaleAnimation = curvedAnimation.drive(_kScaleTween);
    curvedAnimation.dispose();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final Color overlayColor = isDarkMode ? const Color(0xFFc8c8c8) : const Color(0xFF000000);

    final Widget? contrastedChild =
        child != null && !secondaryAnimation.isDismissed
            ? Stack(
              children: <Widget>[
                child,
                FadeTransition(
                  opacity: opacityAnimation,
                  child: ColoredBox(color: overlayColor, child: const SizedBox.expand()),
                ),
              ],
            )
            : child;

    return SlideTransition(
      position: slideAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        filterQuality: FilterQuality.medium,
        alignment: Alignment.topCenter,
        child: AnimatedBuilder(
          animation: radiusAnimation,
          child: child,
          builder: (BuildContext context, Widget? child) {
            return ClipRRect(borderRadius: radiusAnimation.value, child: contrastedChild);
          },
        ),
      ),
    );
  }

  static Widget _delegatedCoverSheetSecondaryTransition(
    Animation<double> secondaryAnimation,
    Widget? child,
  ) {
    const Curve curve = Curves.linearToEaseOut;
    const Curve reverseCurve = Curves.easeInToLinear;
    final CurvedAnimation curvedAnimation = CurvedAnimation(
      curve: curve,
      reverseCurve: reverseCurve,
      parent: secondaryAnimation,
    );

    final Animation<Offset> slideAnimation = curvedAnimation.drive(_kMidUpTween);
    final Animation<double> scaleAnimation = curvedAnimation.drive(_kScaleTween);
    curvedAnimation.dispose();

    return SlideTransition(
      position: slideAnimation,
      transformHitTests: false,
      child: ScaleTransition(
        scale: scaleAnimation,
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
  State<CupertinoSheetTransition> createState() => _CupertinoSheetTransitionState();
}

class _CupertinoSheetTransitionState extends State<CupertinoSheetTransition> {
  // When this page is coming in to cover a non-sheet page.
  late Animation<Offset> _primaryPositionAnimation;
  // When this page is coming in to cover another sheet.
  late Animation<Offset> _primaryPositionAnimationWhenCoveringOtherSheet;
  // The offset animation when this page is being covered by another sheet.
  late Animation<Offset> _secondaryPositionAnimation;
  // The scale animation when this page is being covered by another sheet.
  late Animation<double> _secondaryScaleAnimation;
  // Curve of primary page which is coming in to cover another route.
  CurvedAnimation? _primaryPositionCurve;
  // Curve of secondary page which is becoming covered by another sheet.
  CurvedAnimation? _secondaryPositionCurve;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void didUpdateWidget(covariant CupertinoSheetTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryRouteAnimation != widget.primaryRouteAnimation ||
        oldWidget.secondaryRouteAnimation != widget.secondaryRouteAnimation) {
      _disposeCurve();
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _disposeCurve();
    super.dispose();
  }

  void _setupAnimation() {
    _primaryPositionCurve = CurvedAnimation(
      curve: Curves.fastEaseInToSlowEaseOut,
      reverseCurve: Curves.fastEaseInToSlowEaseOut.flipped,
      parent: widget.primaryRouteAnimation,
    );
    _secondaryPositionCurve = CurvedAnimation(
      curve: Curves.linearToEaseOut,
      reverseCurve: Curves.easeInToLinear,
      parent: widget.secondaryRouteAnimation,
    );
    _primaryPositionAnimation = _primaryPositionCurve!.drive(_kBottomUpTween);
    _primaryPositionAnimationWhenCoveringOtherSheet = _primaryPositionCurve!.drive(
      _kBottomUpTweenWhenCoveringOtherSheet,
    );
    _secondaryPositionAnimation = _secondaryPositionCurve!.drive(_kMidUpTween);
    _secondaryScaleAnimation = _secondaryPositionCurve!.drive(_kScaleTween);
  }

  void _disposeCurve() {
    _primaryPositionCurve?.dispose();
    _secondaryPositionCurve?.dispose();
    _primaryPositionCurve = null;
    _secondaryPositionCurve = null;
  }

  Widget _coverSheetPrimaryTransition(
    BuildContext context,
    Animation<double> animation,
    Widget? child,
  ) {
    final Animation<Offset> offsetAnimation =
        CupertinoSheetRoute.hasParentSheet(context)
            ? _primaryPositionAnimationWhenCoveringOtherSheet
            : _primaryPositionAnimation;

    return SlideTransition(position: offsetAnimation, child: child);
  }

  Widget _coverSheetSecondaryTransition(Animation<double> secondaryAnimation, Widget? child) {
    return SlideTransition(
      position: _secondaryPositionAnimation,
      transformHitTests: false,
      child: ScaleTransition(
        scale: _secondaryScaleAnimation,
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
    return SizedBox.expand(
      child: _coverSheetSecondaryTransition(
        widget.secondaryRouteAnimation,
        _coverSheetPrimaryTransition(
          context,
          widget.primaryRouteAnimation,
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Route for displaying an iOS sheet styled page.
///
/// The `CupertinoSheetRoute` will slide up from the bottom of the screen and stop
/// below the top of the screen. If the previous route is a non-sheet route, then
/// it will animate downwards to stack behind the new sheet. If the previous route
/// is a sheet route, then it will animate slightly upwards to look like it is laying
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
/// This example shows how to show a Cupertino Sheet with nested navigation manually
/// set up in order to enable restorable state.
///
/// ** See code in examples/api/lib/cupertino/sheet/cupertino_sheet.2.dart **
/// {@end-tool}
///
/// See also:
///   * [showCupertinoSheet], which is a convenience method for pushing a
///     `CupertinoSheetRoute`, with optional nested navigation built in.
class CupertinoSheetRoute<T> extends PageRoute<T> with _CupertinoSheetRouteTransitionMixin<T> {
  /// Creates a page route that displays an iOS styled sheet.
  CupertinoSheetRoute({required this.builder});

  /// Builds the primary contents of the sheet route.
  final WidgetBuilder builder;

  @override
  Widget buildContent(BuildContext context) {
    return CupertinoUserInterfaceLevel(
      data: CupertinoUserInterfaceLevelData.elevated,
      child: _CupertinoSheetScope(child: builder(context)),
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

  @override
  Color? get barrierColor => CupertinoColors.transparent;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;
}

// Internally used to see if another sheet is in the tree already.
class _CupertinoSheetScope extends InheritedWidget {
  const _CupertinoSheetScope({required super.child});

  static _CupertinoSheetScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_CupertinoSheetScope>();
  }

  @override
  bool updateShouldNotify(_CupertinoSheetScope oldWidget) => false;
}

/// A mixin that replaces the entire screen with an iOS sheet transition for a
/// [PageRoute].
///
/// See also:
///
///  * [CupertinoSheetRoute], which is a [PageRoute] that leverages this mixin.
mixin _CupertinoSheetRouteTransitionMixin<T> on PageRoute<T> {
  /// Builds the primary contents of the route.
  @protected
  Widget buildContent(BuildContext context);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 500);

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      CupertinoSheetTransition.delegateTransition;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return buildContent(context);
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
    return nextRoute is _CupertinoSheetRouteTransitionMixin;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildPageTransitions<T>(this, context, animation, secondaryAnimation, child);
  }
}
