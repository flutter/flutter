// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show window;

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'banner.dart';
import 'basic.dart';
import 'binding.dart';
import 'container.dart';
import 'framework.dart';
import 'locale_query.dart';
import 'media_query.dart';
import 'navigator.dart';
import 'performance_overlay.dart';
import 'semantics_debugger.dart';
import 'text.dart';
import 'title.dart';

/// Signature for a function that is called when the operating system changes the current locale.
typedef Future<LocaleQueryData> LocaleChangedCallback(Locale locale);

/// A convenience class that wraps a number of widgets that are commonly
/// required for an application.
///
/// See also: [CheckedModeBanner], [DefaultTextStyle], [MediaQuery],
/// [LocaleQuery], [Title], [Navigator], [Overlay], [SemanticsDebugger] (the
/// widgets wrapped by this one).
///
/// The [onGenerateRoute] argument is required, and corresponds to
/// [Navigator.onGenerateRoute].
class WidgetsApp extends StatefulWidget {
  /// Creates a widget that wraps a number of widgets that are commonly
  /// required for an application.
  WidgetsApp({
    Key key,
    @required this.onGenerateRoute,
    this.title,
    this.textStyle,
    this.color,
    this.navigatorObserver,
    this.initialRoute,
    this.onLocaleChanged,
    this.showPerformanceOverlay: false,
    this.showSemanticsDebugger: false,
    this.debugShowCheckedModeBanner: true
  }) : super(key: key) {
    assert(onGenerateRoute != null);
    assert(showPerformanceOverlay != null);
    assert(showSemanticsDebugger != null);
  }

  /// A one-line description of this app for use in the window manager.
  final String title;

  /// The default text style for [Text] in the application.
  final TextStyle textStyle;

  /// The primary color to use for the application in the operating system
  /// interface.
  ///
  /// For example, on Android this is the color used for the application in the
  /// application switcher.
  final Color color;

  /// The route generator callback used when the app is navigated to a
  /// named route.
  final RouteFactory onGenerateRoute;

  /// The name of the first route to show.
  ///
  /// Defaults to [Window.defaultRouteName].
  final String initialRoute;

  /// Callback that is called when the operating system changes the
  /// current locale.
  final LocaleChangedCallback onLocaleChanged;

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
  /// WidgetsApp, include a [CheckedModeBanner] widget in your app.
  ///
  /// This banner is intended to avoid people complaining that your
  /// app is slow when it's in checked mode. In checked mode, Flutter
  /// enables a large number of expensive diagnostics to aid in
  /// development, and so performance in checked mode is not
  /// representative of what will happen in release mode.
  final bool debugShowCheckedModeBanner;

  /// The observer for the Navigator created for this app.
  final NavigatorObserver navigatorObserver;

  /// If true, forces the performance overlay to be visible in all instances.
  ///
  /// Used by `showPerformanceOverlay` observatory extension.
  static bool showPerformanceOverlayOverride = false;

  @override
  _WidgetsAppState createState() => new _WidgetsAppState();
}

class _WidgetsAppState extends State<WidgetsApp> implements WidgetsBindingObserver {
  GlobalObjectKey<NavigatorState> _navigator;
  LocaleQueryData _localeData;

  @override
  void initState() {
    super.initState();
    _navigator = new GlobalObjectKey<NavigatorState>(this);
    didChangeLocale(ui.window.locale);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool didPopRoute() {
    assert(mounted);
    NavigatorState navigator = _navigator.currentState;
    assert(navigator != null);
    return navigator.pop();
  }

  @override
  void didChangeMetrics() {
    setState(() {
      // The properties of ui.window have changed. We use them in our build
      // function, so we need setState(), but we don't cache anything locally.
    });
  }

  @override
  void didChangeLocale(Locale locale) {
    if (config.onLocaleChanged != null) {
      config.onLocaleChanged(locale).then((LocaleQueryData data) {
        if (mounted)
          setState(() { _localeData = data; });
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { }

  @override
  Widget build(BuildContext context) {
    if (config.onLocaleChanged != null && _localeData == null) {
      // If the app expects a locale but we don't yet know the locale, then
      // don't build the widgets now.
      // TODO(ianh): Make this unnecessary. See https://github.com/flutter/flutter/issues/1865
      // TODO(ianh): The following line should not be included in release mode, only in profile and debug modes.
      WidgetsBinding.instance.preventThisFrameFromBeingReportedAsFirstFrame();
      return new Container();
    }

    Widget result = new MediaQuery(
      data: new MediaQueryData.fromWindow(ui.window),
      child: new LocaleQuery(
        data: _localeData,
        child: new Title(
          title: config.title,
          color: config.color,
          child: new Navigator(
            key: _navigator,
            initialRoute: config.initialRoute ?? ui.window.defaultRouteName,
            onGenerateRoute: config.onGenerateRoute,
            observer: config.navigatorObserver
          )
        )
      )
    );
    if (config.textStyle != null) {
      result = new DefaultTextStyle(
        style: config.textStyle,
        child: result
      );
    }
    if (config.showPerformanceOverlay || WidgetsApp.showPerformanceOverlayOverride) {
      result = new Stack(
        children: <Widget>[
          result,
          new Positioned(top: 0.0, left: 0.0, right: 0.0, child: new PerformanceOverlay.allEnabled()),
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
