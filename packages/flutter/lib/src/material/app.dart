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


class MaterialApp extends WidgetsApp {
  MaterialApp({
    Key key,
    String title,
    ThemeData theme,
    Map<String, RouteBuilder> routes: const <String, RouteBuilder>{},
    RouteFactory onGenerateRoute,
    LocaleChangedCallback onLocaleChanged,
    this.debugShowMaterialGrid: false,
    bool showPerformanceOverlay: false,
    bool showSemanticsDebugger: false,
    bool debugShowCheckedModeBanner: true
  }) : theme = theme,
       super(
    key: key,
    title: title,
    textStyle: _errorTextStyle,
    color: theme?.primaryColor ?? Colors.blue[500], // blue[500] is the primary color of the default theme
    routes: routes,
    onGenerateRoute: (RouteSettings settings) {
      RouteBuilder builder = routes[settings.name];
      if (builder != null) {
        return new MaterialPageRoute<Null>(
          builder: (BuildContext context) {
            return builder(new RouteArguments(context: context));
          },
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
  }

  /// The colors to use for the application's widgets.
  final ThemeData theme;

  /// Turns on a [GridPaper] overlay that paints a baseline grid
  /// Material apps:
  /// https://www.google.com/design/spec/layout/metrics-keylines.html
  /// Only available in checked mode.
  final bool debugShowMaterialGrid;

  _MaterialAppState createState() => new _MaterialAppState();
}

class _MaterialAppState extends WidgetsAppState<MaterialApp> {

  final HeroController _heroController = new HeroController();
  NavigatorObserver get navigatorObserver => _heroController;

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
