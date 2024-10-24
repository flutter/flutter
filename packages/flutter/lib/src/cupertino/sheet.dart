// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/foundation.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';


// Offset from offscreen below to stopping below the top of the screen.
final Animatable<Offset> _kBottomUpTween = Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: const Offset(0.0, 0.08),
);

// final Animatable<Offset> _kFullBottomUpTween = Tween<Offset>(
//   begin: const Offset(0.0, 1.0),
//   end: Offset.zero,
// );

// Offset from offscreen below to stopping below the top of the screen.
final Animatable<Offset> _kMidUpTween = Tween<Offset>(
  begin: Offset.zero,
  end: const Offset(0.0, -0.05),
);

// Amount the sheet in the background scales down. Found by measuring the width
// of the sheet in the background and comparing against the screen width. The
// scale transition will go from a default of 1.0 to 1.0 - _kSheetScaleFactor.
const double _kSheetScaleFactor = 0.0835;

/// Docs placeholder
class CupertinoSheetTransition extends StatelessWidget {
  /// Docs placeholder
  CupertinoSheetTransition({
    super.key,
    required Animation<double> primaryRouteAnimation,
    required this.secondaryRouteAnimation,
    required this.child,
  }) : _primaryPositionAnimation =
           CurvedAnimation(
                 parent: primaryRouteAnimation,
                 curve: Curves.fastEaseInToSlowEaseOut,
                 reverseCurve: Curves.fastEaseInToSlowEaseOut.flipped,
               ).drive(_kBottomUpTween),
      _secondaryPositionAnimation =
           CurvedAnimation(
                 parent: secondaryRouteAnimation,
                 curve: Curves.linearToEaseOut,
                 reverseCurve: Curves.easeInToLinear,
               )
           .drive(_kMidUpTween);
      // _primaryPositionAnimationCupertinoSheet =
      //       CurvedAnimation(
      //            parent: primaryRouteAnimation,
      //            curve: Curves.linearToEaseOut,
      //            reverseCurve: Curves.easeInToLinear,
      //          )
      //      .drive(_kFullBottomUpTween);

  // When this page is coming in to cover another page.
  final Animation<Offset> _primaryPositionAnimation;

  // When this page is coming in to cover another CupertinoSheet. Because it's nested within
  // a CupertinoSheet, a 0 y offset is not the top of the physical screen, but the top of
  // the previous CupertinoSheet.
  // final Animation<Offset> _primaryPositionAnimationCupertinoSheet;

  // When this page is being covered by another CupertinoSheet. It slides up slightly to
  // look like it's joining the stack of previous routes.
  final Animation<Offset> _secondaryPositionAnimation;

  /// Animation
  final Animation<double> secondaryRouteAnimation;

  /// The widget below this widget in the tree.
  final Widget child;

  /// The primary delegated transition. Will slide a non CupertinoSheet page down.
  static Widget delegateTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, bool allowSnapshotting, Widget? child) {
    if (CupertinoSheetController.maybeOf(context) != null) {
      return _coverSheetDelegatedTransition(secondaryAnimation, child);
    }

    const Offset begin = Offset.zero;
    const Offset end = Offset(0.0, 0.025);
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

    final Animatable<Offset> slideTween = Tween<Offset>(begin: begin, end: end);
    final Animatable<double> scaleTween = Tween<double>(begin: 1.0, end: 1.0 - _kSheetScaleFactor);

    return SlideTransition(
      position: curvedAnimation.drive(slideTween),
      child: ScaleTransition(
        scale: curvedAnimation.drive(scaleTween),
        filterQuality: FilterQuality.medium,
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

  static Widget _coverSheetDelegatedTransition(Animation<double> secondaryAnimation, Widget? child) {

    const Offset begin = Offset.zero;
    const Offset end = Offset(0.0, -0.05);
    const Curve curve = Curves.linearToEaseOut;
    const Curve reverseCurve = Curves.easeInToLinear;
    final Animation<double> curvedAnimation = CurvedAnimation(
      curve: curve,
      reverseCurve: reverseCurve,
      parent: secondaryAnimation
    );

    final Animatable<Offset> slideTween = Tween<Offset>(begin: begin, end: end);
    final Animatable<double> scaleTween = Tween<double>(begin: 1.0, end: 1.0 - _kSheetScaleFactor);

    return SlideTransition(
      position: curvedAnimation.drive(slideTween),
      child: ScaleTransition(
        scale: curvedAnimation.drive(scaleTween),
        filterQuality: FilterQuality.medium,
        child: child,
      ),
    );
  }

  /// The secondary delegated transition. Will slide a CupertinoSheet page up.
  // static Widget secondaryDelegateTransition(BuildContext context, Widget? child, Animation<double> secondaryAnimation) {
  //   const Offset begin = Offset.zero;
  //   const Offset end = Offset(0.0, -0.05);
  //   const Curve curve = Curves.ease;

  //   final Animatable<Offset> tween = Tween<Offset>(begin: begin, end: end).chain(CurveTween(curve: curve));

  //   return SlideTransition(
  //     position: secondaryAnimation.drive(tween),
  //     child: child,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    final TextDirection textDirection = Directionality.of(context);
    // const bool topLevelCupertinoSheet = true;
    return SlideTransition(
      position: _secondaryPositionAnimation,
      textDirection: textDirection,
      transformHitTests: false,
      child: SlideTransition(
        position: _primaryPositionAnimation,
        textDirection: textDirection,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: child,
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
    return CupertinoSheetController(
      context: context,
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
    required super.child,
  });

  /// Docs placeholder
  final BuildContext context;

  /// Docs placeholder
  static CupertinoSheetController? maybeOf(BuildContext context) {
    print("checking...");
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
