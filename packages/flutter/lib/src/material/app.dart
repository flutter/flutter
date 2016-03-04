// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show WindowPadding, window;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
  decorationColor: const Color(0xFFFF00),
  decorationStyle: TextDecorationStyle.double
);

AssetBundle _initDefaultBundle() {
  if (rootBundle != null)
    return rootBundle;
  return new NetworkAssetBundle(Uri.base);
}

final AssetBundle _defaultBundle = _initDefaultBundle();

class RouteArguments {
  const RouteArguments({ this.context });
  final BuildContext context;
}
typedef Widget RouteBuilder(RouteArguments args);

typedef Future<LocaleQueryData> LocaleChangedCallback(Locale locale);

class MaterialApp extends StatefulComponent {
  MaterialApp({
    Key key,
    this.title,
    this.theme,
    this.routes: const <String, RouteBuilder>{},
    this.onGenerateRoute,
    this.onLocaleChanged,
    this.debugShowMaterialGrid: false,
    this.showPerformanceOverlay: false,
    this.showSemanticsDebugger: false,
    this.debugShowCheckedModeBanner: true
  }) : super(key: key) {
    assert(routes != null);
    assert(routes.containsKey(Navigator.defaultRouteName) || onGenerateRoute != null);
    assert(debugShowMaterialGrid != null);
    assert(showPerformanceOverlay != null);
    assert(showSemanticsDebugger != null);
  }

  /// A one-line description of this app for use in the window manager.
  final String title;

  /// The colors to use for the application's widgets.
  final ThemeData theme;

  /// The default table of routes for the application. When the
  /// [Navigator] is given a named route, the name will be looked up
  /// in this table first. If the name is not available, then
  /// [onGenerateRoute] will be called instead.
  final Map<String, RouteBuilder> routes;

  /// The route generator callback used when the app is navigated to a
  /// named route but the name is not in the [routes] table.
  final RouteFactory onGenerateRoute;

  /// Callback that is invoked when the operating system changes the
  /// current locale.
  final LocaleChangedCallback onLocaleChanged;

  /// Turns on a [GridPaper] overlay that paints a baseline grid
  /// Material apps:
  /// https://www.google.com/design/spec/layout/metrics-keylines.html
  /// Only available in checked mode.
  final bool debugShowMaterialGrid;

  /// Turns on a performance overlay.
  /// https://flutter.io/debugging/#performanceoverlay
  final bool showPerformanceOverlay;

  /// Turns on an overlay that shows the accessibility information
  /// reported by the framework.
  final bool showSemanticsDebugger;

  /// Turns on a "SLOW MODE" little banner in checked mode to indicate
  /// that the app is in checked mode. This is on by default (in
  /// checked mode), to turn it off, set the constructor argument to
  /// false. In release mode this has no effect.
  ///
  /// To get this banner in your application if you're not using
  /// MaterialApp, include a [CheckedModeBanner] widget in your app.
  ///
  /// This banner is intended to avoid people complaining that your
  /// app is slow when it's in checked mode. In checked mode, Flutter
  /// enables a large number of expensive diagnostics to aid in
  /// development, and so performance in checked mode is not
  /// representative of what will happen in release mode.
  final bool debugShowCheckedModeBanner;

  _MaterialAppState createState() => new _MaterialAppState();
}

EdgeDims _getPadding(ui.WindowPadding padding) {
  return new EdgeDims.TRBL(padding.top, padding.right, padding.bottom, padding.left);
}

class _MaterialAppState extends State<MaterialApp> implements BindingObserver {

  GlobalObjectKey _navigator;

  LocaleQueryData _localeData;

  void initState() {
    super.initState();
    _navigator = new GlobalObjectKey(this);
    didChangeLocale(ui.window.locale);
    WidgetFlutterBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetFlutterBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool didPopRoute() {
    assert(mounted);
    NavigatorState navigator = _navigator.currentState;
    assert(navigator != null);
    bool result = false;
    navigator.openTransaction((NavigatorTransaction transaction) {
      result = transaction.pop();
    });
    return result;
  }

  void didChangeMetrics() {
    setState(() {
      // The properties of ui.window have changed. We use them in our build
      // function, so we need setState(), but we don't cache anything locally.
    });
  }

  void didChangeLocale(Locale locale) {
    if (config.onLocaleChanged != null) {
      config.onLocaleChanged(locale).then((LocaleQueryData data) {
        if (mounted)
          setState(() { _localeData = data; });
      });
    }
  }

  void didChangeAppLifecycleState(AppLifecycleState state) { }

  final HeroController _heroController = new HeroController();

  Route _generateRoute(RouteSettings settings) {
    RouteBuilder builder = config.routes[settings.name];
    if (builder != null) {
      return new MaterialPageRoute(
        builder: (BuildContext context) {
          return builder(new RouteArguments(context: context));
        },
        settings: settings
      );
    }
    if (config.onGenerateRoute != null)
      return config.onGenerateRoute(settings);
    return null;
  }

  Widget build(BuildContext context) {
    if (config.onLocaleChanged != null && _localeData == null) {
      // If the app expects a locale but we don't yet know the locale, then
      // don't build the widgets now.
      return new Container();
    }

    ThemeData theme = config.theme ?? new ThemeData.fallback();
    Widget result = new MediaQuery(
      data: new MediaQueryData(
        size: ui.window.size,
        devicePixelRatio: ui.window.devicePixelRatio,
        padding: _getPadding(ui.window.padding)
      ),
      child: new LocaleQuery(
        data: _localeData,
        child: new AnimatedTheme(
          data: theme,
          duration: kThemeAnimationDuration,
          child: new DefaultTextStyle(
            style: _errorTextStyle,
            child: new AssetVendor(
              bundle: _defaultBundle,
              devicePixelRatio: ui.window.devicePixelRatio,
              child: new Title(
                title: config.title,
                color: theme.primaryColor,
                child: new Navigator(
                  key: _navigator,
                  initialRoute: ui.window.defaultRouteName,
                  onGenerateRoute: _generateRoute,
                  observer: _heroController
                )
              )
            )
          )
        )
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
    if (config.showPerformanceOverlay) {
      result = new Stack(
        children: <Widget>[
          result,
          new Positioned(bottom: 0.0, left: 0.0, right: 0.0, child: new PerformanceOverlay.allEnabled()),
        ]
      );
    }
    if (config.showSemanticsDebugger) {
      result = new SemanticsDebugger(
        child: result
      );
    }
    assert(() {
      if (config.debugShowCheckedModeBanner) {
        result = new CheckedModeBanner(
          child: result
        );
      }
      return true;
    });
    return result;
  }

}
