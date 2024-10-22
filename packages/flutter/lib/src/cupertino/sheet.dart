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
  end: const Offset(0.0, 0.1),
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
    const Offset begin = Offset.zero;
    const Offset end = Offset(0.0, 0.05);
    const Curve curve = Curves.ease;

    final Animatable<Offset> tween = Tween<Offset>(begin: begin, end: end).chain(CurveTween(curve: curve));

    return SlideTransition(
      position: secondaryAnimation.drive(tween),
      child: child,
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
  Widget buildContent(BuildContext context) => pageBuilder(context);

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
