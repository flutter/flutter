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
          Navigator.of(context, rootNavigator: true).maybePop();
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
                    Navigator.of(context, rootNavigator: true).pop();
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

/// Docs placeholder
class CupertinoSheetRoute<T> extends PageRoute<T> with CupertinoSheetRouteTransitionMixin<T> {
  /// Creates a page route for use in an iOS designed app.
  CupertinoSheetRoute({
    required this.builder,
  });

  /// Docs placeholder
  final WidgetBuilder builder;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => CupertinoSheetTransition.delegateTransition;

  @override
  Widget buildContent(BuildContext context) {
    return _CupertinoSheetScope(
      child: builder(context),
    );
  }

  /// Docs placeholder
  static bool hasParentSheet(BuildContext context) {
    return _CupertinoSheetScope.maybeOf(context) != null;
  }

  /// Docs placeholder
  static void popSheet(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
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
class _CupertinoSheetScope extends InheritedWidget {
  /// Docs placeholder
  const _CupertinoSheetScope({
    required super.child,
  });

  static _CupertinoSheetScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_CupertinoSheetScope>();
  }

  // FOR REVIEW: Not sure what the smartest way to do this is. My intinct is to
  // always have this return false. But if so, should this widget not be an
  // InheritedWidget?
  @override
  bool updateShouldNotify(_CupertinoSheetScope oldWidget) => oldWidget.key != null && key != null && oldWidget.key != key;
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
