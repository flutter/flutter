// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'page.dart';
import 'theme.dart';

export 'dart:ui' show Locale;

const TextStyle _errorTextStyle = const TextStyle(
  color: const Color(0xD0FF0000),
  fontFamily: 'monospace',
  fontSize: 48.0,
  fontWeight: FontWeight.w900,
  textAlign: TextAlign.right,
  decoration: TextDecoration.underline,
  decorationColor: const Color(0xFFFFFF00),
  decorationStyle: TextDecorationStyle.double
);

/// An application that uses material design.
///
/// A convenience widget that wraps a number of widgets that are commonly
/// required for material design applications. It builds upon
/// [WidgetsApp] by adding material-design specific functionality, such as
/// [AnimatedTheme] and [GridPaper]. This widget also configures the top-level
/// [Navigator] to perform [Hero] animations.
///
/// See also:
///
///  * [WidgetsApp]
///  * [Scaffold]
///  * [MaterialPageRoute]
class MaterialApp extends WidgetsApp {
  /// Creates a MaterialApp.
  ///
  /// At least one of [home], [routes], or [onGenerateRoute] must be
  /// given. If only [routes] is given, it must include an entry for
  /// the [Navigator.defaultRouteName] (`'/'`).
  ///
  /// See also the [new WidgetsApp] constructor (which this extends).
  MaterialApp({
    Key key,
    String title,
    ThemeData theme,
    Widget home,
    Map<String, WidgetBuilder> routes: const <String, WidgetBuilder>{},
    RouteFactory onGenerateRoute,
    LocaleChangedCallback onLocaleChanged,
    this.debugShowMaterialGrid: false,
    bool showPerformanceOverlay: false,
    bool showSemanticsDebugger: false,
    bool debugShowCheckedModeBanner: true
  }) : theme = theme,
       home = home,
       routes = routes,
       super(
    key: key,
    title: title,
    textStyle: _errorTextStyle,
    color: theme?.primaryColor ?? Colors.blue[500], // blue[500] is the primary color of the default theme
    onGenerateRoute: (RouteSettings settings) {
      WidgetBuilder builder = routes[settings.name];
      if (builder == null && home != null && settings.name == Navigator.defaultRouteName)
        builder = (BuildContext context) => home;
      if (builder != null) {
        return new MaterialPageRoute<Null>(
          builder: builder,
          settings: settings
        );
      }
      if (onGenerateRoute != null)
        return onGenerateRoute(settings);
      return null;
    },
    onLocaleChanged: onLocaleChanged,
    showPerformanceOverlay: showPerformanceOverlay,
    showSemanticsDebugger: showSemanticsDebugger,
    debugShowCheckedModeBanner: debugShowCheckedModeBanner
  ) {
    assert(debugShowMaterialGrid != null);
    assert(routes != null);
    assert(!routes.containsKey(Navigator.defaultRouteName) || (home == null));
    assert(routes.containsKey(Navigator.defaultRouteName) || (home != null) || (onGenerateRoute != null));
  }

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
  /// by [home]), then the [onGenerateRoute] callback is invoked to
  /// build the page instead.
  final Map<String, WidgetBuilder> routes;

  /// Turns on a [GridPaper] overlay that paints a baseline grid
  /// Material apps:
  /// https://www.google.com/design/spec/layout/metrics-keylines.html
  /// Only available in checked mode.
  final bool debugShowMaterialGrid;

  @override
  _MaterialAppState createState() => new _MaterialAppState();
}

class _MaterialAppState extends WidgetsAppState<MaterialApp> {
  final HeroController _heroController = new HeroController();

  @override
  NavigatorObserver get navigatorObserver => _heroController;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = config.theme ?? new ThemeData.fallback();
    Widget result = new AnimatedTheme(
      data: theme,
      duration: kThemeAnimationDuration,
      child: super.build(context)
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
    return result;
  }

}
