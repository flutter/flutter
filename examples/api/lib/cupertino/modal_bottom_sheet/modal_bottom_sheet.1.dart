// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) {
                      return  const MyHomePage(title: 'Zoom Transition');
                    },
                  ),
                );},
                child: const Text('Zoom Transition'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (BuildContext context) {
                      return  const MyHomePage(title: 'Cupertino Transition');
                    }
                  ),
                );},
                child: const Text('Cupertino Transition'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MBSPageRoute<void>(
                      context: context,
                    ),
                  );
                },
                child: const Text('Modal Bottom Sheet'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MBSPageRoute<void>(
                      context: context,
                      firstRoute: '/page2'
                    ),
                  );
                },
                child: const Text('Modal Bottom Sheet Page 2'),
              ),
              if (MBSNavigator.of(context) != null)
                TextButton(
                  onPressed: () {
                    (Navigator.of(context).widget as MBSNavigator).popMBS();
                  },
                  child: const Text('Pop Bottom Sheet')
                ),
            ],
          ),
        ),
    );
  }
}

class PageOne extends StatelessWidget {
  const PageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Page One'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Page One'),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/page2');},
                child: const Text('Go to Page 2'),
              ),
              if (MBSNavigator.of(context) != null)
                TextButton(
                  onPressed: () {
                    (Navigator.of(context).widget as MBSNavigator).popMBS();
                  },
                  child: const Text('Pop Bottom Sheet')
                ),
            ],
          ),
        ),
    );
  }
}

class PageTwo extends StatelessWidget {
  const PageTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Page Two'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Page Two'),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/page3');},
                child: const Text('Go to Page 3'),
              ),
              if (MBSNavigator.of(context) != null)
                TextButton(
                  onPressed: () {
                    (Navigator.of(context).widget as MBSNavigator).popMBS();
                  },
                  child: const Text('Pop Bottom Sheet')
                ),
            ],
          ),
        ),
    );
  }
}

class PageThree extends StatelessWidget {
  const PageThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Page Three'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Page Three'),
              if (MBSNavigator.of(context) != null)
                TextButton(
                  onPressed: () {
                    (Navigator.of(context).widget as MBSNavigator).popMBS();
                  },
                  child: const Text('Pop Bottom Sheet')
                ),
            ],
          ),
        ),
    );
  }
}

// Offset from offscreen below to stopping below the top of the screen.
final Animatable<Offset> _kBottomUpTween = Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: const Offset(0.0, 0.1),
);

final Animatable<Offset> _kFullBottomUpTween = Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: Offset.zero,
);

// Offset from offscreen below to stopping below the top of the screen.
final Animatable<Offset> _kMidUpTween = Tween<Offset>(
  begin: Offset.zero,
  end: const Offset(0.0, -0.05),
);

class MBSTransition extends StatelessWidget {
  MBSTransition({
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
           .drive(_kMidUpTween),
      _tertiaryPositionAnimation =
            CurvedAnimation(
                 parent: primaryRouteAnimation,
                 curve: Curves.linearToEaseOut,
                 reverseCurve: Curves.easeInToLinear,
               )
           .drive(_kFullBottomUpTween);

  // When this page is coming in to cover another page.
  final Animation<Offset> _primaryPositionAnimation;

  // When this page is coming in to cover another page.
  final Animation<Offset> _tertiaryPositionAnimation;

  // When this page is coming in to cover another page.
  final Animation<Offset> _secondaryPositionAnimation;

  /// Animation
  final Animation<double> secondaryRouteAnimation;

  /// The widget below this widget in the tree.
  final Widget child;

  /// The delegated transition.
  static Widget delegateTransition(BuildContext context, Widget? child, Animation<double> secondaryAnimation) {
    const Offset begin = Offset.zero;
    const Offset end = Offset(0.0, 0.05);
    const Curve curve = Curves.ease;

    final Animatable<Offset> tween = Tween<Offset>(begin: begin, end: end).chain(CurveTween(curve: curve));

    return SlideTransition(
      position: secondaryAnimation.drive(tween),
      child: child,
    );
  }

  /// The secondary delegated transition.
  static Widget secondaryDelegateTransition(BuildContext context, Widget? child, Animation<double> secondaryAnimation) {
    const Offset begin = Offset.zero;
    const Offset end = Offset(0.0, -0.05);
    const Curve curve = Curves.ease;

    final Animatable<Offset> tween = Tween<Offset>(begin: begin, end: end).chain(CurveTween(curve: curve));

    return SlideTransition(
      position: secondaryAnimation.drive(tween),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    final TextDirection textDirection = Directionality.of(context);
    final bool topLevelMBS = Navigator.of(context).widget is! MBSNavigator;
    return DelegatedTransition(
      context: context,
      animation: secondaryRouteAnimation,
      builder: (BuildContext context, Widget? child) {
        return SlideTransition(
          position: _secondaryPositionAnimation,
          textDirection: textDirection,
          transformHitTests: false,
          child: child,
        );
      },
      child: SlideTransition(
        position: topLevelMBS ? _primaryPositionAnimation : _tertiaryPositionAnimation,
        textDirection: textDirection,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: child,
        )
      ),
    );
  }
}

class MBSPageRoute<T> extends PageRoute<T> with MBSRouteTransitionMixin<T>,FlexibleTransitionRouteMixin<T> {
  /// Creates a page route for use in an iOS designed app.
  MBSPageRoute({
    required BuildContext context,
    this.firstRoute,
  }) : _delegatedTransition = (Navigator.of(context).widget is MBSNavigator) ?
      MBSTransition.secondaryDelegateTransition : MBSTransition.delegateTransition;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _delegatedTransition;

  final DelegatedTransitionBuilder _delegatedTransition;

  final String? firstRoute;

  @override
  String? get initialRoute => firstRoute;

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

mixin MBSRouteTransitionMixin<T> on PageRoute<T> {

  @protected
  String? initialRoute;

  @override
  // A relatively rigorous eyeball estimation.
  Duration get transitionDuration => const Duration(milliseconds: 500);


  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    late Widget child;
    return MBSNavigator(
      parentNavigatorContext: context,
      initialRoute: initialRoute ?? '/',
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/' :
            child = const PageOne();
          case '/page2' :
            child = const PageTwo();
          case '/page3' :
            child = const PageThree();
          default:
            child = const PageOne();
        }
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) {
            return Semantics(
              scopesRoute: true,
              explicitChildNodes: true,
              child: child,
            );
          }
        );
      },
    );
  }

  /// Returns a [CupertinoFullscreenDialogTransition] if [route] is a full
  /// screen dialog, otherwise a [CupertinoPageTransition] is returned.
  ///
  /// Used by [CupertinoPageRoute.buildTransitions].
  ///
  /// This method can be applied to any [PageRoute], not just
  /// [CupertinoPageRoute]. It's typically used to provide a Cupertino style
  /// horizontal transition for material widgets when the target platform
  /// is [TargetPlatform.iOS].
  ///
  /// See also:
  ///
  ///  * [CupertinoPageTransitionsBuilder], which uses this method to define a
  ///    [PageTransitionsBuilder] for the [PageTransitionsTheme].
  static Widget buildPageTransitions<T>(
    ModalRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return MBSTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      child: child,
    );
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is MBSRouteTransitionMixin;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return buildPageTransitions<T>(this, context, animation, secondaryAnimation, child);
  }
}

class MBSNavigator extends Navigator {

  const MBSNavigator({
    super.key,
    super.pages,
    super.onPopPage,
    super.initialRoute,
    super.onGenerateInitialRoutes,
    super.onGenerateRoute,
    super.onUnknownRoute,
    super.transitionDelegate,
    super.reportsRouteUpdateToEngine,
    super.clipBehavior,
    super.observers,
    super.requestFocus,
    super.restorationScopeId,
    super.routeTraversalEdgeBehavior,
    required this.parentNavigatorContext,
  });

  final BuildContext parentNavigatorContext;

  void popMBS() {
    Navigator.of(parentNavigatorContext).pop();
    // Navigator.of(parentNavigatorContext).delegateTransitionBuilder = null;
  }

  static NavigatorState? of(
    BuildContext context, {
    bool rootNavigator = false,
  }) {
    // Handles the case where the input context is a navigator element.
    NavigatorState? navigator;
    if (context is StatefulElement && context.state is NavigatorState) {
      navigator = context.state as NavigatorState;
    }
    if (rootNavigator) {
      navigator = context.findRootAncestorStateOfType<NavigatorState>() ?? navigator;
    } else {
      navigator = navigator ?? context.findAncestorStateOfType<NavigatorState>();
    }
    if (navigator?.widget is! MBSNavigator) {
      return null;
    }

    return navigator;
  }
}
