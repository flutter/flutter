// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'interface_level.dart';
import 'route.dart';
import 'theme.dart';

// Smoothing factor applied to the device's top padding (which approximates the corner radius)
// to achieve a smoother end to the corner radius animation.  A value of 1.0 would use
// the full top padding. Values less than 1.0 reduce the effective corner radius, improving
// the animation's appearance.  Determined through empirical testing.
const double _kDeviceCornerRadiusSmoothingFactor = 0.9;

// Threshold in logical pixels. If the calculated device corner radius (after applying
// the smoothing factor) is below this value, the corner radius transition animation will
// start from zero. This prevents abrupt transitions for devices with small or negligible
// corner radii.  This value, combined with the smoothing factor, corresponds roughly
// to double the targeted radius of 12.  Determined through testing and visual inspection.
const double _kRoundedDeviceCornersThreshold = 20.0;

// The distance from the top of the open sheet to the top of the screen, as a ratio
// of the total height of the screen. Found from eyeballing a simulator running
// iOS 18.0.
const double _kTopGapRatio = 0.08;

// The minimum distance (i.e., maximum upward stretch) from the top of the sheet
// to the top of the screen, as a ratio of total screen height. This value represents
// how far the sheet can be temporarily pulled upward before snapping back.
// Determined through visual tuning to feel natural on <iPhone16, iPhone 16 Pro>
// running iOS 18.0 simulators.
const double _kStretchedTopGapRatio = 0.072;

// Tween for animating a Cupertino sheet onto the screen.
//
// Begins fully offscreen below the screen and ends onscreen with a small gap at
// the top of the screen. Values found from eyeballing a simulator running iOS 18.0.
final Animatable<Offset> _kBottomUpTween = Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: Offset.zero,
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

// The minimum velocity needed for a drag downwards to dismiss the sheet. Eyeballed
// from a comparison against a simulator running iOS 18.0.
const double _kMinFlingVelocity = 2.0; // Screen heights per second.

// The duration for a page to animate when the user releases it mid-swipe. Eyeballed
// from a comparison against a simulator running iOS 18.0.
const Duration _kDroppedSheetDragAnimationDuration = Duration(milliseconds: 300);

// Amount the sheet in the background scales down. Found by measuring the width
// of the sheet in the background and comparing against the screen width on the
// iOS simulator showing an iPhone 16 pro running iOS 18.0. The scale transition
// will go from a default of 1.0 to 1.0 - _kSheetScaleFactor.
const double _kSheetScaleFactor = 0.0835;

final Animatable<double> _kScaleTween = Tween<double>(begin: 1.0, end: 1.0 - _kSheetScaleFactor);

/// Shows a Cupertino-style sheet widget that slides up from the bottom of the
/// screen and stacks the previous route behind the new sheet.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=5H-WvH5O29I}
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
/// sheet. System back gestures and programmatic pops on the initial route in a
/// sheet will also be intercepted to pop the whole [CupertinoSheetRoute]. If
/// a custom [Navigator] setup is needed, like for example to enable named routes
/// or the pages API, then it is recommended to directly push a [CupertinoSheetRoute]
/// to the stack with whatever configuration needed. See [CupertinoSheetRoute] for
/// an example that manually sets up nested navigation.
///
/// The whole sheet can be popped at once by either dragging down on the sheet,
/// or calling [CupertinoSheetRoute.popSheet].
///
/// When `enableDrag` is set to `true` (the default), users can dismiss the sheet
/// by dragging it down or by calling [CupertinoSheetRoute.popSheet]. When
/// `enableDrag` is `false`, users cannot dismiss the sheet by dragging, and it
/// can only be closed by calling [CupertinoSheetRoute.popSheet].
///
/// The `topGap` parameter can be used to customize the gap between the top of
/// the screen and the top of the sheet as a ratio of the screen height.
/// It should be a value between 0.0 and 0.9, where 0.0 means no gap and 0.9
/// means the sheet takes up only the bottom 10% of the screen. If not provided, defaults
/// to 0.08 (8% of screen height).
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
  @Deprecated(
    'Use builder instead. '
    'This feature was deprecated after v3.33.0-0.2.pre.',
  )
  WidgetBuilder? pageBuilder,
  WidgetBuilder? builder,
  bool useNestedNavigation = false,
  bool enableDrag = true,
  double? topGap,
}) {
  assert(topGap == null || (topGap >= 0.0 && topGap <= 0.9), 'topGap must be between 0.0 and 0.9');
  assert(pageBuilder != null || builder != null);

  final WidgetBuilder? effectivePageBuilder = builder ?? pageBuilder;
  final WidgetBuilder widgetBuilder;
  final nestedNavigatorKey = GlobalKey<NavigatorState>();
  if (!useNestedNavigation) {
    widgetBuilder = effectivePageBuilder!;
  } else {
    widgetBuilder = (BuildContext context) {
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
                    child: effectivePageBuilder!(context),
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
  ).push<T>(CupertinoSheetRoute<T>(builder: widgetBuilder, enableDrag: enableDrag, topGap: topGap));
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
    required this.linearTransition,
    required this.topGap,
  });

  /// `primaryRouteAnimation` is a linear route animation from 0.0 to 1.0 when
  /// this screen is being pushed.
  final Animation<double> primaryRouteAnimation;

  /// `secondaryRouteAnimation` is a linear route animation from 0.0 to 1.0 when
  /// another screen is being pushed on top of this one.
  final Animation<double> secondaryRouteAnimation;

  /// The widget below this widget in the tree.
  final Widget child;

  /// Whether to perform the transition linearly.
  ///
  /// Used to respond to a drag gesture.
  final bool linearTransition;

  /// The gap between the top of the screen and the top of the sheet as a ratio
  /// of the screen height.
  ///
  /// This value should be between 0.0 and 0.9, where 0.0 means no gap (sheet
  /// extends to the top of the screen) and 0.9 means the sheet covers only the
  /// bottom 10% of the screen. A value of 0.08 represents 8% of the screen height.
  final double topGap;

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
    final bool linear = Navigator.of(context).userGestureInProgress;

    final Curve curve = linear ? Curves.linear : Curves.linearToEaseOut;
    final Curve reverseCurve = linear ? Curves.linear : Curves.easeInToLinear;
    final curvedAnimation = CurvedAnimation(
      curve: curve,
      reverseCurve: reverseCurve,
      parent: secondaryAnimation,
    );

    final double deviceCornerRadius =
        (MediaQuery.maybeViewPaddingOf(context)?.top ?? 0) * _kDeviceCornerRadiusSmoothingFactor;
    final bool roundedDeviceCorners = deviceCornerRadius > _kRoundedDeviceCornersThreshold;

    final Animatable<BorderRadiusGeometry> decorationTween = Tween<BorderRadiusGeometry>(
      begin: BorderRadius.vertical(
        top: Radius.circular(roundedDeviceCorners ? deviceCornerRadius : 0),
      ),
      end: BorderRadius.circular(12),
    );

    final Animation<BorderRadiusGeometry> radiusAnimation = curvedAnimation.drive(decorationTween);
    final Animation<double> opacityAnimation = curvedAnimation.drive(_kOpacityTween);
    final Animation<Offset> slideAnimation = curvedAnimation.drive(_kTopDownTween);
    final Animation<double> scaleAnimation = curvedAnimation.drive(_kScaleTween);
    curvedAnimation.dispose();

    final isDarkMode = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final overlayColor = isDarkMode ? const Color(0xFFc8c8c8) : const Color(0xFF000000);

    final Widget? contrastedChild = child != null && !secondaryAnimation.isDismissed
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

    final double topGapHeight = MediaQuery.sizeOf(context).height * _kTopGapRatio;

    return Stack(
      children: <Widget>[
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
          ),
          child: SizedBox(height: topGapHeight, width: double.infinity),
        ),
        SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            filterQuality: FilterQuality.medium,
            alignment: Alignment.topCenter,
            child: AnimatedBuilder(
              animation: radiusAnimation,
              child: child,
              builder: (BuildContext context, Widget? child) {
                return ClipRSuperellipse(
                  borderRadius: !secondaryAnimation.isDismissed
                      ? radiusAnimation.value
                      : BorderRadius.circular(0),
                  child: contrastedChild,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  static Widget _delegatedCoverSheetSecondaryTransition(
    Animation<double> secondaryAnimation,
    Widget? child,
  ) {
    const Curve curve = Curves.linearToEaseOut;
    const Curve reverseCurve = Curves.easeInToLinear;
    final curvedAnimation = CurvedAnimation(
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
        child: ClipRSuperellipse(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: child,
        ),
      ),
    );
  }

  @override
  State<CupertinoSheetTransition> createState() => _CupertinoSheetTransitionState();
}

class _CupertinoSheetTransitionState extends State<CupertinoSheetTransition>
    with SingleTickerProviderStateMixin {
  // Controls the top padding animation when the sheet is being slightly stretched upward.
  late AnimationController _stretchDragController;

  // Animates the top padding of the sheet based on the _stretchDragController’s value.
  late Animation<double> _stretchDragAnimation;

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
    _stretchDragController = AnimationController(
      duration: const Duration(microseconds: 1),
      vsync: this,
    );
    // Maintain the same stretch distance (0.008 of screen height) regardless of custom topGap.
    const double stretchDistance = _kTopGapRatio - _kStretchedTopGapRatio;
    final double stretchedTopGap = widget.topGap - stretchDistance;
    _stretchDragAnimation = _stretchDragController.drive(
      Tween<double>(begin: widget.topGap, end: stretchedTopGap),
    );
    _secondaryPositionAnimation = _secondaryPositionCurve!.drive(_kMidUpTween);
    _secondaryScaleAnimation = _secondaryPositionCurve!.drive(_kScaleTween);
  }

  void _disposeCurve() {
    _stretchDragController.dispose();
    _primaryPositionCurve?.dispose();
    _secondaryPositionCurve?.dispose();
    _primaryPositionCurve = null;
    _secondaryPositionCurve = null;
  }

  Widget _coverSheetPrimaryTransition(
    BuildContext context,
    Animation<double> animation,
    bool linearTransition,
    Widget? child,
  ) {
    final Animatable<Offset> offsetTween = CupertinoSheetRoute.hasParentSheet(context)
        ? _kBottomUpTweenWhenCoveringOtherSheet
        : _kBottomUpTween;

    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: linearTransition ? Curves.linear : Curves.fastEaseInToSlowEaseOut,
      reverseCurve: linearTransition ? Curves.linear : Curves.fastEaseInToSlowEaseOut.flipped,
    );

    final Animation<Offset> positionAnimation = curvedAnimation.drive(offsetTween);

    curvedAnimation.dispose();

    return SlideTransition(position: positionAnimation, child: child);
  }

  Widget _coverSheetSecondaryTransition(Animation<double> secondaryAnimation, Widget? child) {
    return SlideTransition(
      position: _secondaryPositionAnimation,
      transformHitTests: false,
      child: ScaleTransition(
        scale: _secondaryScaleAnimation,
        filterQuality: FilterQuality.medium,
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _StretchDragControllerProvider(
      controller: _stretchDragController,
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _stretchDragAnimation,
          builder: (BuildContext context, Widget? child) {
            return Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.heightOf(context) * _stretchDragAnimation.value,
              ),
              child: _coverSheetSecondaryTransition(
                widget.secondaryRouteAnimation,
                _coverSheetPrimaryTransition(
                  context,
                  widget.primaryRouteAnimation,
                  widget.linearTransition,
                  widget.child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Internally used to provide the controller for upward stretch animation.
class _StretchDragControllerProvider extends InheritedWidget {
  const _StretchDragControllerProvider({required this.controller, required super.child});

  final AnimationController controller;

  static _StretchDragControllerProvider? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_StretchDragControllerProvider>();
  }

  @override
  bool updateShouldNotify(_StretchDragControllerProvider oldWidget) {
    return false;
  }
}

/// Route for displaying an iOS sheet styled page.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=5H-WvH5O29I}
///
/// The `CupertinoSheetRoute` will slide up from the bottom of the screen and stop
/// below the top of the screen. If the previous route is a non-sheet route, then
/// it will animate downwards to stack behind the new sheet. If the previous route
/// is a sheet route, then it will animate slightly upwards to look like it is laying
/// on top of the previous stack of sheets.
///
/// Typically called by [showCupertinoSheet], which provides some boilerplate for
/// pushing the `CupertinoSheetRoute` to the root navigator and providing simple
/// nested navigation.
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
  CupertinoSheetRoute({
    super.settings,
    required this.builder,
    this.enableDrag = true,
    double? topGap,
  }) : assert(
         topGap == null || (topGap >= 0.0 && topGap <= 0.9),
         'topGap must be between 0.0 and 0.9',
       ),
       _topGap = topGap;

  /// Builds the primary contents of the sheet route.
  final WidgetBuilder builder;

  @override
  final bool enableDrag;

  // The gap between the top of the screen and the top of the sheet.
  final double? _topGap;

  @override
  double get topGap => _topGap ?? _kTopGapRatio;

  @override
  bool get _hasCustomTopGap => _topGap != null;

  @override
  Widget buildContent(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ClipRSuperellipse(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.elevated,
          child: _CupertinoSheetScope(child: builder(context)),
        ),
      ),
    );
  }

  /// Checks if a Cupertino sheet view exists in the widget tree above the current
  /// context.
  static bool hasParentSheet(BuildContext context) {
    return _CupertinoSheetScope.maybeOf(context) != null;
  }

  /// Pops the entire [CupertinoSheetRoute], if a sheet route exists in the stack.
  ///
  /// Used if to pop an entire sheet at once, if there is nested navigation within
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
  DelegatedTransitionBuilder? get delegatedTransition {
    if (_hasCustomTopGap) {
      return null;
    }
    return CupertinoSheetTransition.delegateTransition;
  }

  /// Determines whether the content can be dragged.
  ///
  /// If `true`, dragging is enabled; otherwise, it remains fixed.
  bool get enableDrag;

  /// The gap between the top of the screen and the top of the sheet as a ratio
  /// of the screen height (0.0 to 1.0). Defaults to a value of 0.08.
  double get topGap;

  /// Whether a custom top gap has been set.
  bool get _hasCustomTopGap;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return buildContent(context);
  }

  static _CupertinoDragGestureController<T> _startPopGesture<T>(
    ModalRoute<T> route,
    double topGap,
  ) {
    return _CupertinoDragGestureController<T>(
      topGap: topGap,
      navigator: route.navigator!,
      getIsCurrent: () => route.isCurrent,
      getIsActive: () => route.isActive,
      popDragController: route.controller!, // protected access
    );
  }

  /// Returns a [CupertinoSheetTransition].
  static Widget buildPageTransitions<T>(
    ModalRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    bool enableDrag,
    double topGap,
  ) {
    final bool linearTransition = route.popGestureInProgress;
    return CupertinoSheetTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: linearTransition,
      topGap: topGap,
      child: _CupertinoDragGestureDetector<T>(
        enabledCallback: () => enableDrag,
        onStartPopGesture: () => _startPopGesture<T>(route, topGap),
        child: child,
      ),
    );
  }

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return !_hasCustomTopGap;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    if (this is CupertinoSheetRoute<dynamic> && _hasCustomTopGap) {
      return false;
    }
    return nextRoute is _CupertinoSheetRouteTransitionMixin;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildPageTransitions<T>(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
      enableDrag,
      topGap,
    );
  }
}

class _CupertinoDragGestureDetector<T> extends StatefulWidget {
  const _CupertinoDragGestureDetector({
    super.key,
    required this.enabledCallback,
    required this.onStartPopGesture,
    required this.child,
  });

  final Widget child;

  final ValueGetter<bool> enabledCallback;

  final ValueGetter<_CupertinoDragGestureController<T>> onStartPopGesture;

  @override
  _CupertinoDragGestureDetectorState<T> createState() => _CupertinoDragGestureDetectorState<T>();
}

class _CupertinoDragGestureDetectorState<T> extends State<_CupertinoDragGestureDetector<T>> {
  _CupertinoDragGestureController<T>? _dragGestureController;

  late VerticalDragGestureRecognizer _recognizer;
  _StretchDragControllerProvider? _stretchDragController;

  @override
  void initState() {
    super.initState();
    assert(_stretchDragController == null);
    _stretchDragController = _StretchDragControllerProvider.maybeOf(context);
    _recognizer = VerticalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stretchDragController = _StretchDragControllerProvider.maybeOf(context);
  }

  @override
  void dispose() {
    _recognizer.dispose();

    // If this is disposed during a drag, call navigator.didStopUserGesture.
    if (_dragGestureController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dragGestureController?.navigator.mounted ?? false) {
          _dragGestureController?.navigator.didStopUserGesture();
        }
        _dragGestureController = null;
      });
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    assert(_dragGestureController == null);
    _dragGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    assert(_dragGestureController != null);
    if (_stretchDragController == null) {
      return;
    }
    _dragGestureController!.dragUpdate(details.primaryDelta!, _stretchDragController!.controller);
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    assert(_dragGestureController != null);
    if (_stretchDragController == null) {
      _dragGestureController = null;
      return;
    }
    _dragGestureController!.dragEnd(
      details.velocity.pixelsPerSecond.dy / context.size!.height,
      _stretchDragController!.controller,
    );
    _dragGestureController = null;
  }

  void _handleDragCancel() {
    assert(mounted);
    // This can be called even if start is not called, paired with the "down" event
    // that we don't consider here.
    if (_stretchDragController == null) {
      _dragGestureController = null;
      return;
    }
    _dragGestureController?.dragEnd(0.0, _stretchDragController!.controller);
    _dragGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback()) {
      _recognizer.addPointer(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

class _CupertinoDragGestureController<T> {
  /// Creates a controller for an iOS-style back gesture.
  _CupertinoDragGestureController({
    required this.navigator,
    required this.popDragController,
    required this.getIsActive,
    required this.getIsCurrent,
    required this.topGap,
  }) {
    navigator.didStartUserGesture();
  }

  final AnimationController popDragController;
  final NavigatorState navigator;
  final ValueGetter<bool> getIsActive;
  final ValueGetter<bool> getIsCurrent;
  final double topGap;

  /// The drag gesture has changed by [delta]. The total range of the drag
  /// should be 0.0 to 1.0.
  void dragUpdate(double delta, AnimationController upController) {
    if (popDragController.value == 1.0 && delta < 0) {
      // Divide by stretchable range (when dragging upward at max extent).
      // Maintain the same stretch distance regardless of custom topGap.
      const double stretchDistance = _kTopGapRatio - _kStretchedTopGapRatio;
      upController.value -= delta / (navigator.context.size!.height * stretchDistance);
    } else {
      // Divide by size of the sheet.
      popDragController.value -=
          delta / (navigator.context.size!.height - (navigator.context.size!.height * topGap));
    }
  }

  /// The drag gesture has ended with a vertical motion of [velocity] as a
  /// fraction of screen height per second.
  void dragEnd(double velocity, AnimationController upController) {
    // If the sheet is in a stretched state (dragged upward beyond max size),
    // reverse the stretch to return to the normal max height.
    if (upController.value > 0) {
      upController.animateBack(
        0.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
      navigator.didStopUserGesture();
      return;
    }

    // Fling in the appropriate direction.
    //
    // This curve has been determined through rigorously eyeballing native iOS
    // animations on a simulator running iOS 18.0.
    const Curve animationCurve = Curves.easeOut;
    final bool isCurrent = getIsCurrent();
    final bool animateForward;

    if (!isCurrent) {
      // If the page has already been navigated away from, then the animation
      // direction depends on whether or not it's still in the navigation stack,
      // regardless of velocity or drag position. For example, if a route is
      // being slowly dragged back by just a few pixels, but then a programmatic
      // pop occurs, the route should still be animated off the screen.
      // See https://github.com/flutter/flutter/issues/141268.
      animateForward = getIsActive();
    } else if (velocity.abs() >= _kMinFlingVelocity) {
      // If the user releases the page before mid screen with sufficient velocity,
      // or after mid screen, we should animate the page out. Otherwise, the page
      // should be animated back in.
      animateForward = velocity <= 0;
    } else {
      // If the drag is dropped with low velocity, the sheet will pop if the
      // the drag goes a little past the halfway point on the screen. This is
      // eyeballed on a simulator running iOS 18.0.
      animateForward = popDragController.value > 0.52;
    }

    if (animateForward) {
      popDragController.animateTo(
        1.0,
        duration: _kDroppedSheetDragAnimationDuration,
        curve: animationCurve,
      );
    } else {
      if (isCurrent) {
        // This route is destined to pop at this point. Reuse navigator's pop.
        navigator.pop();
      }

      if (popDragController.isAnimating) {
        popDragController.animateBack(
          0.0,
          duration: _kDroppedSheetDragAnimationDuration,
          curve: animationCurve,
        );
      }
    }

    if (popDragController.isAnimating) {
      // Keep the userGestureInProgress in true state so we don't change the
      // curve of the page transition mid-flight since CupertinoPageTransition
      // depends on userGestureInProgress.
      // late AnimationStatusListener animationStatusCallback;
      void animationStatusCallback(AnimationStatus status) {
        navigator.didStopUserGesture();
        popDragController.removeStatusListener(animationStatusCallback);
      }

      popDragController.addStatusListener(animationStatusCallback);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
