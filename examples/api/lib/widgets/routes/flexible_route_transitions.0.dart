// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FlexibleRouteTransitionsApp());
}

class FlexibleRouteTransitionsApp extends StatelessWidget {
  const FlexibleRouteTransitionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mixing Routes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          },
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Zoom Transition'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    VerticalTransitionPageRoute<void>(
                      builder: (BuildContext context) {
                        return  const MyHomePage(title: 'Crazy Vertical Transition');
                      },
                    ),
                  );
                },
                child: const Text('Crazy Vertical Transition'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return  const MyHomePage(title: 'Zoom Transition');
                      },
                    ),
                  );
                },
                child: const Text('Zoom Transition'),
              ),
              TextButton(
                onPressed: () {
                  final CupertinoPageRoute<void> route = CupertinoPageRoute<void>(
                    builder: (BuildContext context) {
                      return  const MyHomePage(title: 'Cupertino Transition');
                    }
                  );
                  Navigator.of(context).push(route);
                },
                child: const Text('Cupertino Transition'),
              ),
            ],
          ),
        ),
    );
  }
}

class VerticalTransitionPageRoute<T> extends PageRoute<T> {
  /// Creates a page route for use in an iOS designed app.
  VerticalTransitionPageRoute({
    required this.builder,
  });

  final WidgetBuilder builder;

  @override
  DelegatedTransition? get delegatedTransition => VerticalPageTransition._delegatedTransition;

  @override
  Color? get barrierColor => const Color(0x00000000);

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => 'Should be no visible barrier...';

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  // Begin PageRoute.

  @override
  Duration get transitionDuration => const Duration(milliseconds: 2000);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return builder(context);
  }

  static Widget buildPageTransitions<T>(
    ModalRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return VerticalPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      child: child,
    );
  }

  // TODO(justinmc): No canTransitionTo needed? I want to be able to have
  // back-to-back VerticalPageTransitions.

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return buildPageTransitions<T>(this, context, animation, secondaryAnimation, child);
  }

  // End PageRoute.
}

class VerticalPageTransition extends StatelessWidget {
  VerticalPageTransition({
    super.key,
    required Animation<double> primaryRouteAnimation,
    required this.secondaryRouteAnimation,
    required this.child,
  }) : _primaryPositionAnimation =
           CurvedAnimation(
                 parent: primaryRouteAnimation,
                 curve: curve,
                 reverseCurve: curve,
               ).drive(_kBottomUpTween),
      _secondaryPositionAnimation =
           CurvedAnimation(
                 parent: secondaryRouteAnimation,
                 curve: curve,
                 reverseCurve: curve,
               )
           .drive(_kTopDownTween);

  // When this page is coming in to cover another page.
  final Animation<Offset> _primaryPositionAnimation;

  // When this page is being coverd by another page.
  final Animation<Offset> _secondaryPositionAnimation;

  /// Animation
  final Animation<double> secondaryRouteAnimation;

  /// The widget below this widget in the tree.
  final Widget child;

  static const Curve curve = Curves.decelerate;

  static final Animatable<Offset> _kBottomUpTween = Tween<Offset>(
    begin: const Offset(0.0, 1.0),
    end: Offset.zero,
  );

  static final Animatable<Offset> _kTopDownTween = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0.0, -1.0),
  );

  static const DelegatedTransition _delegatedTransition = DelegatedTransition(
    builder: _delegatedTransitionBuilder,
    name: 'Vertical-Transition',
  );

  static Widget _delegatedTransitionBuilder(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget? child) {
    final Animatable<Offset> tween = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -1.0),
    ).chain(CurveTween(curve: curve));

    return SlideTransition(
      position: secondaryAnimation.drive(tween),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    final TextDirection textDirection = Directionality.of(context);
    return SlideTransition(
      position: _secondaryPositionAnimation,
      textDirection: textDirection,
      transformHitTests: false,
      child:  SlideTransition(
        position: _primaryPositionAnimation,
        textDirection: textDirection,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: child,
        )
      ),
    );
  }
}
