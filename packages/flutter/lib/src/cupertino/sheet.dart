// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';

// Offset from offscreen below to stopping below the top of the screen.
final Animatable<Offset> _kBottomUpTween = Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: const Offset(0.0, 0.08),
);

final Animatable<Offset> _kFullBottomUpTween = Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: const Offset(0.0, -0.02),
);

// Offset slightly up when a sheet gets covered by another sheet.
final Animatable<Offset> _kMidUpTween = Tween<Offset>(
  begin: Offset.zero,
  end: const Offset(0.0, -0.005),
);

// Offset from top of screen to slightly down when covered by a sheet.
final Animatable<Offset> _kTopDownTween = Tween<Offset>(
  begin: Offset.zero,
  end: const Offset(0.0, 0.07),
);

// Amount the sheet in the background scales down. Found by measuring the width
// of the sheet in the background and comparing against the screen width. The
// scale transition will go from a default of 1.0 to 1.0 - _kSheetScaleFactor.
const double _kSheetScaleFactor = 0.0835;

final Animatable<double> _kScaleTween = Tween<double>(begin: 1.0, end: 1.0 - _kSheetScaleFactor);

/// Docs placeholder
class CupertinoSheetTransition extends StatelessWidget {
  /// Docs placeholder
  const CupertinoSheetTransition({
    super.key,
    required this.primaryRouteAnimation,
    required this.secondaryRouteAnimation,
    required this.child,
  });

  /// Animation
  final Animation<double> primaryRouteAnimation;

  /// Animation
  final Animation<double> secondaryRouteAnimation;

  /// The widget below this widget in the tree.
  final Widget child;

  /// The primary delegated transition. Will slide a non [CupertinoSheetRoute] page down.
  ///
  /// If a [CupertinoSheetController] already exists in the stack, then it will
  /// slide the previous sheet upwards instead.
  static Widget delegateTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, bool allowSnapshotting, Widget? child) {
    if (CupertinoSheetController.maybeOf(context) != null) {
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
      CupertinoSheetController.maybeOf(context) == null ?
      _kBottomUpTween :
      _kFullBottomUpTween;

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

/// Docs placeholder
class CupertinoSheetRoute<T> extends PageRoute<T> with CupertinoSheetRouteTransitionMixin<T> {
  /// Creates a page route for use in an iOS designed app.
  CupertinoSheetRoute({
    required this.pageBuilder,
  });

  /// Docs placeholder
  final WidgetBuilder pageBuilder;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => CupertinoSheetTransition.delegateTransition;

  @override
  Widget buildContent(BuildContext context) {
    final BuildContext? topLevelContext = CupertinoSheetController.maybeOf(context)?.topLevelContext;
    return CupertinoSheetController(
      context: context,
      topLevelContext: topLevelContext ?? context,
      child: pageBuilder(context),
    );
  }

  /// Docs placeholder
  static CupertinoSheetController? maybeOf(BuildContext context) {
    return CupertinoSheetController.maybeOf(context);
  }

  /// Docs placeholder
  static CupertinoSheetController of(BuildContext context) {
    return CupertinoSheetController.of(context);
  }

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

/// Docs placeholder
class CupertinoSheetController extends InheritedWidget {
  /// Docs placeholder
  const CupertinoSheetController({
    super.key,
    required this.context,
    required this.topLevelContext,
    required super.child,
  });

  /// Context for the location of the [CupertinoSheetController].
  ///
  /// Used to pop the whole sheet route at once from any location below the sheet
  /// on the tree.
  final BuildContext context;

  /// Context for the location of the top level [CupertinoSheetController].
  ///
  /// If there is a [Navigator] within a [CupertinoSheetRoute], then this
  /// `topLevelContext` is useful for pushing routes to the [Navigator] that
  /// wraps all of the sheets in the stack. Usefull for adding a new
  /// [CupertinoSheetRoute], or any page route that needs to animate outside the
  /// bounds of the sheet.
  final BuildContext topLevelContext;

  /// Docs placeholder
  static CupertinoSheetController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CupertinoSheetController>();
  }

  /// Docs placeholder
  static CupertinoSheetController of(BuildContext context) {
    final CupertinoSheetController? result = maybeOf(context);
    assert(result != null, 'No CupertinoSheetController found in context');
    return result!;
  }

  /// Docs placeholder
  void popSheet() {
    Navigator.of(context).pop();
  }

  @override
  bool updateShouldNotify(CupertinoSheetController oldWidget) => context != oldWidget.context;
}

/// Docs placeholder
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

  /// Docs placeholder
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
