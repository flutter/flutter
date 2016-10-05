// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'arc.dart';
import 'colors.dart';
import 'overscroll_indicator.dart';
import 'page.dart';
import 'theme.dart';

export 'dart:ui' show Locale;

const TextStyle _errorTextStyle = const TextStyle(
  color: const Color(0xD0FF0000),
  fontFamily: 'monospace',
  fontSize: 48.0,
  fontWeight: FontWeight.w900,
  decoration: TextDecoration.underline,
  decorationColor: const Color(0xFFFFFF00),
  decorationStyle: TextDecorationStyle.double
);

/// An application that uses material design.
///
/// A convenience widget that wraps a number of widgets that are commonly
/// required for material design applications. It builds upon a
/// [WidgetsApp] by adding material-design specific functionality, such as
/// [AnimatedTheme] and [GridPaper]. This widget also configures the top-level
/// [Navigator]'s observer to perform [Hero] animations.
///
/// See also:
///
///  * [WidgetsApp]
///  * [Scaffold]
///  * [MaterialPageRoute]
class MaterialApp extends StatefulWidget {

  /// Creates a MaterialApp.
  ///
  /// At least one of [home], [routes], or [onGenerateRoute] must be
  /// given. If only [routes] is given, it must include an entry for
  /// the [Navigator.defaultRouteName] (`'/'`).
  ///
  /// This class creates an instance of [WidgetsApp].
  MaterialApp({
    Key key,
    this.title,
    this.color,
    this.theme,
    this.home,
    this.routes: const <String, WidgetBuilder>{},
    this.initialRoute,
    this.onGenerateRoute,
    this.onLocaleChanged,
    this.debugShowMaterialGrid: false,
    this.showPerformanceOverlay: false,
    this.showSemanticsDebugger: false,
    this.debugShowCheckedModeBanner: true
  }) : super(key: key) {
    assert(debugShowMaterialGrid != null);
    assert(routes != null);
    assert(!routes.containsKey(Navigator.defaultRouteName) || (home == null));
    assert(routes.containsKey(Navigator.defaultRouteName) || (home != null) || (onGenerateRoute != null));
 }
  /// A one-line description of this app for use in the window manager.
  final String title;

  /// The colors to use for the application's widgets.
  final ThemeData theme;

  /// The widget for the default route of the app
  /// ([Navigator.defaultRouteName], which is `'/'`).
  ///
  /// This is the page that is displayed first when the application is
  /// started normally.
  ///
  /// To be able to directly call [Theme.of], [MediaQuery.of],
  /// [LocaleQuery.of], etc, in the code sets the [home] argument in
  /// the constructor, you can use a [Builder] widget to get a
  /// [BuildContext].
  ///
  /// If this is not specified, then either the route with name `'/'`
  /// must be given in [routes], or the [onGenerateRoute] callback
  /// must be able to build a widget for that route.
  final Widget home;

  /// The primary color to use for the application in the operating system
  /// interface.
  ///
  /// For example, on Android this is the color used for the application in the
  /// application switcher.
  final Color color;

  /// The application's top-level routing table.
  ///
  /// When a named route is pushed with [Navigator.pushNamed], the route name is
  /// looked up in this map. If the name is present, the associated
  /// [WidgetBuilder] is used to construct a [MaterialPageRoute] that performs
  /// an appropriate transition, including [Hero] animations, to the new route.
  ///
  /// If the app only has one page, then you can specify it using [home] instead.
  ///
  /// If [home] is specified, then it is an error to provide a route
  /// in this map for the [Navigator.defaultRouteName] route (`'/'`).
  ///
  /// If a route is requested that is not specified in this table (or
  /// by [home]), then the [onGenerateRoute] callback is called to
  /// build the page instead.
  final Map<String, WidgetBuilder> routes;

  /// The name of the first route to show.
  ///
  /// Defaults to [Window.defaultRouteName].
  final String initialRoute;

  /// The route generator callback used when the app is navigated to a
  /// named route.
  final RouteFactory onGenerateRoute;

  /// Callback that is called when the operating system changes the
  /// current locale.
  final LocaleChangedCallback onLocaleChanged;

  /// Turns on a performance overlay.
  /// https://flutter.io/debugging/#performanceoverlay
  final bool showPerformanceOverlay;

  /// Turns on an overlay that shows the accessibility information
  /// reported by the framework.
  final bool showSemanticsDebugger;

  /// Turns on a little "SLOW MODE" banner in checked mode to indicate
  /// that the app is in checked mode. This is on by default (in
  /// checked mode), to turn it off, set the constructor argument to
  /// false. In release mode this has no effect.
  ///
  /// To get this banner in your application if you're not using
  /// WidgetsApp, include a [CheckedModeBanner] widget in your app.
  ///
  /// This banner is intended to deter people from complaining that your
  /// app is slow when it's in checked mode. In checked mode, Flutter
  /// enables a large number of expensive diagnostics to aid in
  /// development, and so performance in checked mode is not
  /// representative of what will happen in release mode.
  final bool debugShowCheckedModeBanner;

  /// Turns on a [GridPaper] overlay that paints a baseline grid
  /// Material apps:
  /// https://www.google.com/design/spec/layout/metrics-keylines.html
  /// Only available in checked mode.
  final bool debugShowMaterialGrid;

  @override
  _MaterialAppState createState() => new _MaterialAppState();
}

class _ScrollLikeCupertinoDelegate extends ScrollConfigurationDelegate {
  const _ScrollLikeCupertinoDelegate();

  @override
  TargetPlatform get platform => TargetPlatform.iOS;

  @override
  ExtentScrollBehavior createScrollBehavior() => new OverscrollWhenScrollableBehavior(platform: TargetPlatform.iOS);

  @override
  bool updateShouldNotify(ScrollConfigurationDelegate old) => false;
}

class _ScrollLikeMountainViewDelegate extends ScrollConfigurationDelegate {
  const _ScrollLikeMountainViewDelegate(this.platform);

  @override
  final TargetPlatform platform;

  @override
  ExtentScrollBehavior createScrollBehavior() => new OverscrollWhenScrollableBehavior(platform: TargetPlatform.android);

  ScrollableEdge _overscrollIndicatorEdge(ScrollableEdge edge) {
    switch (edge) {
      case ScrollableEdge.leading:
        return ScrollableEdge.trailing;
      case ScrollableEdge.trailing:
        return ScrollableEdge.leading;
      case ScrollableEdge.both:
        return ScrollableEdge.none;
      case ScrollableEdge.none:
        return ScrollableEdge.both;
    }
    return ScrollableEdge.both;
  }

  @override
  Widget wrapScrollWidget(BuildContext context, Widget scrollWidget) {
    // Only introduce an overscroll indicator for the edges of the scrollable
    // that aren't already clamped.
    return new OverscrollIndicator(
      edge: _overscrollIndicatorEdge(ClampOverscrolls.of(context)?.edge),
      child: scrollWidget
    );
  }

  @override
  bool updateShouldNotify(ScrollConfigurationDelegate old) => false;
}

class _MaterialAppState extends State<MaterialApp> {
  HeroController _heroController;

  @override
  void initState() {
    super.initState();
    _heroController = new HeroController(createRectTween: _createRectTween);
  }

  RectTween _createRectTween(Rect begin, Rect end) {
    return new MaterialRectArcTween(begin: begin, end: end);
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    WidgetBuilder builder = config.routes[settings.name];
    if (builder == null && config.home != null && settings.name == Navigator.defaultRouteName)
      builder = (BuildContext context) => config.home;
    if (builder != null) {
      return new MaterialPageRoute<Null>(
        builder: builder,
        settings: settings
      );
    }
    if (config.onGenerateRoute != null)
      return config.onGenerateRoute(settings);
    return null;
  }

  ScrollConfigurationDelegate _getScrollDelegate(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
        return const _ScrollLikeMountainViewDelegate(TargetPlatform.android);
      case TargetPlatform.fuchsia:
        return const _ScrollLikeMountainViewDelegate(TargetPlatform.fuchsia);
      case TargetPlatform.iOS:
        return const _ScrollLikeCupertinoDelegate();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = config.theme ?? new ThemeData.fallback();
    Widget result = new AnimatedTheme(
      data: theme,
      isMaterialAppTheme: true,
      child: new WidgetsApp(
        key: new GlobalObjectKey(this),
        title: config.title,
        textStyle: _errorTextStyle,
        // blue[500] is the primary color of the default theme
        color: config.color ?? theme?.primaryColor ?? Colors.blue[500],
        navigatorObserver: _heroController,
        initialRoute: config.initialRoute,
        onGenerateRoute: _onGenerateRoute,
        onLocaleChanged: config.onLocaleChanged,
        showPerformanceOverlay: config.showPerformanceOverlay,
        showSemanticsDebugger: config.showSemanticsDebugger,
        debugShowCheckedModeBanner: config.debugShowCheckedModeBanner
      )
    );

    assert(() {
      if (config.debugShowMaterialGrid) {
        result = new GridPaper(
          color: const Color(0xE0F9BBE0),
          interval: 8.0,
          divisions: 2,
          subDivisions: 1,
          child: result
        );
      }
      return true;
    });

    return new ScrollConfiguration(
      delegate: _getScrollDelegate(theme.platform),
      child: result
    );
  }
}
