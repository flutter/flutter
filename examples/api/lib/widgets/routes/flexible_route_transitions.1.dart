// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(FlexibleRouteTransitionsApp());
}

class FlexibleRouteTransitionsApp extends StatelessWidget {
  FlexibleRouteTransitionsApp({super.key});

  final _MyRouteInformationParser _routeInformationParser = _MyRouteInformationParser();
  final MyRouterDelegate _routerDelegate = MyRouterDelegate();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
      routeInformationParser: _routeInformationParser,
      routerDelegate: _routerDelegate,
    );
  }
}

class _MyRouteInformationParser extends RouteInformationParser<MyPageConfiguration> {
  @override
  SynchronousFuture<MyPageConfiguration> parseRouteInformation(RouteInformation routeInformation) {
    return SynchronousFuture(MyPageConfiguration.values.firstWhere((MyPageConfiguration pageConfiguration) {
      return pageConfiguration.uriString == routeInformation.uri.toString();
    },
      orElse: () => MyPageConfiguration.unknown,
    ));
  }

  @override
  RouteInformation? restoreRouteInformation(MyPageConfiguration configuration) {
    return RouteInformation(uri: configuration.uri);
  }
}

class MyRouterDelegate extends RouterDelegate<MyPageConfiguration> {
  final Set<VoidCallback> _listeners = <VoidCallback>{};
  final List<MyPageConfiguration> _pages = <MyPageConfiguration>[];

  void _notifyListeners() {
    for (VoidCallback listener in _listeners) {
      listener();
    }
  }

  void onNavigateToHome() {
    _pages.clear();
    _pages.add(MyPageConfiguration.home);
    _notifyListeners();
  }

  void onNavigateToZoom() {
    _pages.add(MyPageConfiguration.zoom);
    _notifyListeners();
  }

  void onNavigateToIOS() {
    _pages.add(MyPageConfiguration.iOS);
    _notifyListeners();
  }

  void onNavigateToVertical() {
    _pages.add(MyPageConfiguration.vertical);
    _notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  @override
  Future<bool> popRoute() {
    if (_pages.isEmpty) {
      return SynchronousFuture(false);
    }
    _pages.removeLast();
    _notifyListeners();
    return SynchronousFuture(true);
  }

  @override
  Future<void> setNewRoutePath(MyPageConfiguration configuration) {
    _pages.add(configuration);
    _notifyListeners();
    return SynchronousFuture(null);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      restorationScopeId: 'root',
      onDidRemovePage: (Page page) {
        _pages.remove(MyPageConfiguration.fromName(page.name!));
      },
      pages: _pages.map((MyPageConfiguration page) => switch (page) {
        MyPageConfiguration.unknown => MyUnknownPage(),
        MyPageConfiguration.home => MyHomePage(routerDelegate: this),
        MyPageConfiguration.zoom => ZoomPage(routerDelegate: this),
        MyPageConfiguration.iOS => IOSPage(routerDelegate: this),
        MyPageConfiguration.vertical => VerticalPage(routerDelegate: this),
      }).toList(),
    );
  }
}

class MyUnknownPage extends MaterialPage {
  MyUnknownPage() : super(
    restorationId: 'unknown-page',
    child: Scaffold(
      appBar: AppBar(title: const Text('404')),
      body: const Center(
        child: Text('404'),
      ),
    ),
  );

  @override
  String get name => MyPageConfiguration.unknown.name;
}

class MyHomePage extends MaterialPage {
  MyHomePage({required this.routerDelegate}) : super(
    restorationId: 'home-page',
    child: MyPageScaffold(title: 'Home', routerDelegate: routerDelegate),
  );

  final MyRouterDelegate routerDelegate;

  @override
  String get name => MyPageConfiguration.home.name;
}

class ZoomPage extends MaterialPage {
  ZoomPage({required this.routerDelegate}) : super(
    restorationId: 'zoom-page',
    child: MyPageScaffold(title: 'Zoom Route', routerDelegate: routerDelegate),
  );

  final MyRouterDelegate routerDelegate;

  @override
  String get name => MyPageConfiguration.zoom.name;
}

class IOSPage extends CupertinoPage {
  IOSPage({required this.routerDelegate}) : super(
    restorationId: 'ios-page',
    child: MyPageScaffold(title: 'Cupertino Route', routerDelegate: routerDelegate),
  );

  final MyRouterDelegate routerDelegate;

  @override
  String get name => MyPageConfiguration.iOS.name;
}

class VerticalPage extends VerticalTransitionPage {
  VerticalPage({required this.routerDelegate}) : super(
    restorationId: 'vertical-page',
    child: MyPageScaffold(title: 'Vertical Route', routerDelegate: routerDelegate),
  );

  final MyRouterDelegate routerDelegate;

  @override
  String get name => MyPageConfiguration.vertical.name;
}

class MyPageScaffold extends StatelessWidget {
  const MyPageScaffold({super.key, required this.title, required this.routerDelegate});

  final String title;

  final MyRouterDelegate routerDelegate;

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
                  routerDelegate.onNavigateToVertical();
                },
                child: const Text('Crazy Vertical Transition'),
              ),
              TextButton(
                onPressed: () {
                  routerDelegate.onNavigateToZoom();
                },
                child: const Text('Zoom Transition'),
              ),
              TextButton(
                onPressed: () {
                  routerDelegate.onNavigateToIOS();
                },
                child: const Text('Cupertino Transition'),
              ),
            ],
          ),
        ),
    );
  }
}

class VerticalTransitionPage<T> extends Page<T> {

  const VerticalTransitionPage({
    required this.child,
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.allowSnapshotting = true,
    super.key,
    super.canPop,
    super.onPopInvoked,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  final bool maintainState;

  final bool fullscreenDialog;

  final bool allowSnapshotting;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedVerticalPageRoute<T>(page: this);
  }
}

class _PageBasedVerticalPageRoute<T> extends PageRoute<T> {
  _PageBasedVerticalPageRoute({
    required VerticalTransitionPage<T> page,
    super.allowSnapshotting,
  }) : super(settings: page);

  VerticalTransitionPage<T> get _page => settings as VerticalTransitionPage<T>;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  DelegatedTransitionBuilder? get delegatedTransition => VerticalPageTransition._delegatedTransition;

  @override
  Color? get barrierColor => const Color(0x00000000);

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => 'Should be no visible barrier...';

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 2000);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return _page.child;
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

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return buildPageTransitions<T>(this, context, animation, secondaryAnimation, child);
  }
}

class VerticalTransitionPageRoute<T> extends PageRoute<T> {
  /// Creates a page route for use in an iOS designed app.
  VerticalTransitionPageRoute({
    required this.builder,
  });

  final WidgetBuilder builder;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => VerticalPageTransition._delegatedTransition;

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

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return buildPageTransitions<T>(this, context, animation, secondaryAnimation, child);
  }
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

  static Widget _delegatedTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget? child) {
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

enum MyPageConfiguration {
  home(uriString: '/'),
  zoom(uriString: '/zoom'),
  iOS(uriString: '/iOS'),
  vertical(uriString: '/vertical'),
  unknown(uriString: '/404');

  const MyPageConfiguration({
    required this.uriString,
  });

  final String uriString;

  static MyPageConfiguration fromName(String testName) {
    return values.firstWhere((MyPageConfiguration page) => page.name == testName);
  }

  Uri get uri => Uri.parse(uriString);
}
