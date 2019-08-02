// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show Diagnosticable;
import 'package:flutter/rendering.dart';
import 'package:flutter/src/cupertino/interface_level.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'colors.dart';
import 'icons.dart';
import 'localizations.dart';
import 'route.dart';
import 'theme.dart';

/// An application that uses Cupertino design.
///
/// A convenience widget that wraps a number of widgets that are commonly
/// required for an iOS-design targeting application. It builds upon a
/// [WidgetsApp] by iOS specific defaulting such as fonts and scrolling
/// physics.
///
/// The [CupertinoApp] configures the top-level [Navigator] to search for routes
/// in the following order:
///
///  1. For the `/` route, the [home] property, if non-null, is used.
///
///  2. Otherwise, the [routes] table is used, if it has an entry for the route.
///
///  3. Otherwise, [onGenerateRoute] is called, if provided. It should return a
///     non-null value for any _valid_ route not handled by [home] and [routes].
///
///  4. Finally if all else fails [onUnknownRoute] is called.
///
/// If [home], [routes], [onGenerateRoute], and [onUnknownRoute] are all null,
/// and [builder] is not null, then no [Navigator] is created.
///
/// This widget also configures the observer of the top-level [Navigator] (if
/// any) to perform [Hero] animations.
///
/// Use this widget with caution on Android since it may produce behaviors
/// Android users are not expecting such as:
///
///  * Pages will be dismissible via a back swipe.
///  * Scrolling past extremities will trigger iOS-style spring overscrolls.
///  * The San Francisco font family is unavailable on Android and can result
///    in undefined font behavior.
///
/// See also:
///
///  * [CupertinoPageScaffold], which provides a standard page layout default
///    with nav bars.
///  * [Navigator], which is used to manage the app's stack of pages.
///  * [CupertinoPageRoute], which defines an app page that transitions in an
///    iOS-specific way.
///  * [WidgetsApp], which defines the basic app elements but does not depend
///    on the Cupertino library.
class CupertinoApp extends StatefulWidget {
  /// Creates a CupertinoApp.
  ///
  /// At least one of [home], [routes], [onGenerateRoute], or [builder] must be
  /// non-null. If only [routes] is given, it must include an entry for the
  /// [Navigator.defaultRouteName] (`/`), since that is the route used when the
  /// application is launched with an intent that specifies an otherwise
  /// unsupported route.
  ///
  /// This class creates an instance of [WidgetsApp].
  ///
  /// The boolean arguments, [routes], and [navigatorObservers], must not be null.
  const CupertinoApp({
    Key key,
    this.navigatorKey,
    this.home,
    this.theme,
    this.routes = const <String, WidgetBuilder>{},
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorObservers = const <NavigatorObserver>[],
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
  }) : assert(routes != null),
       assert(navigatorObservers != null),
       assert(title != null),
       assert(showPerformanceOverlay != null),
       assert(checkerboardRasterCacheImages != null),
       assert(checkerboardOffscreenLayers != null),
       assert(showSemanticsDebugger != null),
       assert(debugShowCheckedModeBanner != null),
       super(key: key);

  /// {@macro flutter.widgets.widgetsApp.navigatorKey}
  final GlobalKey<NavigatorState> navigatorKey;

  /// {@macro flutter.widgets.widgetsApp.home}
  final Widget home;

  /// The top-level [CupertinoTheme] styling.
  ///
  /// A null [theme] or unspecified [theme] attributes will default to iOS
  /// system values.
  final CupertinoThemeData theme;

  /// The application's top-level routing table.
  ///
  /// When a named route is pushed with [Navigator.pushNamed], the route name is
  /// looked up in this map. If the name is present, the associated
  /// [WidgetBuilder] is used to construct a [CupertinoPageRoute] that performs
  /// an appropriate transition, including [Hero] animations, to the new route.
  ///
  /// {@macro flutter.widgets.widgetsApp.routes}
  final Map<String, WidgetBuilder> routes;

  /// {@macro flutter.widgets.widgetsApp.initialRoute}
  final String initialRoute;

  /// {@macro flutter.widgets.widgetsApp.onGenerateRoute}
  final RouteFactory onGenerateRoute;

  /// {@macro flutter.widgets.widgetsApp.onUnknownRoute}
  final RouteFactory onUnknownRoute;

  /// {@macro flutter.widgets.widgetsApp.navigatorObservers}
  final List<NavigatorObserver> navigatorObservers;

  /// {@macro flutter.widgets.widgetsApp.builder}
  final TransitionBuilder builder;

  /// {@macro flutter.widgets.widgetsApp.title}
  ///
  /// This value is passed unmodified to [WidgetsApp.title].
  final String title;

  /// {@macro flutter.widgets.widgetsApp.onGenerateTitle}
  ///
  /// This value is passed unmodified to [WidgetsApp.onGenerateTitle].
  final GenerateAppTitle onGenerateTitle;

  /// {@macro flutter.widgets.widgetsApp.color}
  final Color color;

  /// {@macro flutter.widgets.widgetsApp.locale}
  final Locale locale;

  /// {@macro flutter.widgets.widgetsApp.localizationsDelegates}
  final Iterable<LocalizationsDelegate<dynamic>> localizationsDelegates;

  /// {@macro flutter.widgets.widgetsApp.localeListResolutionCallback}
  ///
  /// This callback is passed along to the [WidgetsApp] built by this widget.
  final LocaleListResolutionCallback localeListResolutionCallback;

  /// {@macro flutter.widgets.widgetsApp.localeResolutionCallback}
  ///
  /// This callback is passed along to the [WidgetsApp] built by this widget.
  final LocaleResolutionCallback localeResolutionCallback;

  /// {@macro flutter.widgets.widgetsApp.supportedLocales}
  ///
  /// It is passed along unmodified to the [WidgetsApp] built by this widget.
  final Iterable<Locale> supportedLocales;

  /// Turns on a performance overlay.
  ///
  /// See also:
  ///
  ///  * <https://flutter.dev/debugging/#performanceoverlay>
  final bool showPerformanceOverlay;

  /// Turns on checkerboarding of raster cache images.
  final bool checkerboardRasterCacheImages;

  /// Turns on checkerboarding of layers rendered to offscreen bitmaps.
  final bool checkerboardOffscreenLayers;

  /// Turns on an overlay that shows the accessibility information
  /// reported by the framework.
  final bool showSemanticsDebugger;

  /// {@macro flutter.widgets.widgetsApp.debugShowCheckedModeBanner}
  final bool debugShowCheckedModeBanner;

  @override
  _CupertinoAppState createState() => _CupertinoAppState();

  /// The [HeroController] used for Cupertino page transitions.
  ///
  /// Used by [CupertinoTabView] and [CupertinoApp].
  static HeroController createCupertinoHeroController() =>
      HeroController(); // Linear tweening.
}

class _AlwaysCupertinoScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    // Never build any overscroll glow indicators.
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

class _CupertinoAppState extends State<CupertinoApp> {
  HeroController _heroController;

  @override
  void initState() {
    super.initState();
    _heroController = CupertinoApp.createCupertinoHeroController();
    _updateNavigator();
  }

  @override
  void didUpdateWidget(CupertinoApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigatorKey != oldWidget.navigatorKey) {
      // If the Navigator changes, we have to create a new observer, because the
      // old Navigator won't be disposed (and thus won't unregister with its
      // observers) until after the new one has been created (because the
      // Navigator has a GlobalKey).
      _heroController = CupertinoApp.createCupertinoHeroController();
    }
    _updateNavigator();
  }

  List<NavigatorObserver> _navigatorObservers;

  void _updateNavigator() {
    if (widget.home != null ||
        widget.routes.isNotEmpty ||
        widget.onGenerateRoute != null ||
        widget.onUnknownRoute != null) {
      _navigatorObservers = List<NavigatorObserver>.from(widget.navigatorObservers)
        ..add(_heroController);
    } else {
      _navigatorObservers = const <NavigatorObserver>[];
    }
  }

  // Combine the default localization for Cupertino with the ones contributed
  // by the localizationsDelegates parameter, if any. Only the first delegate
  // of a particular LocalizationsDelegate.type is loaded so the
  // localizationsDelegate parameter can be used to override
  // _CupertinoLocalizationsDelegate.
  Iterable<LocalizationsDelegate<dynamic>> get _localizationsDelegates sync* {
    if (widget.localizationsDelegates != null)
      yield* widget.localizationsDelegates;
    yield DefaultCupertinoLocalizations.delegate;
  }

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData effectiveThemeData = widget.theme ?? const CupertinoThemeData();

    return ScrollConfiguration(
      behavior: _AlwaysCupertinoScrollBehavior(),
      child: CupertinoTheme(
        data: effectiveThemeData,
        child: _CupertinoSystemColor(
          data: CupertinoSystemColor.fromSystem ?? CupertinoSystemColor.fallbackValues,
          child: WidgetsApp(
            key: GlobalObjectKey(this),
            navigatorKey: widget.navigatorKey,
            navigatorObservers: _navigatorObservers,
            pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
              CupertinoPageRoute<T>(settings: settings, builder: builder),
            home: widget.home,
            routes: widget.routes,
            initialRoute: widget.initialRoute,
            onGenerateRoute: widget.onGenerateRoute,
            onUnknownRoute: widget.onUnknownRoute,
            builder: widget.builder,
            title: widget.title,
            onGenerateTitle: widget.onGenerateTitle,
            textStyle: effectiveThemeData.textTheme.textStyle,
            color: widget.color ?? CupertinoColors.activeBlue,
            locale: widget.locale,
            localizationsDelegates: _localizationsDelegates,
            localeResolutionCallback: widget.localeResolutionCallback,
            localeListResolutionCallback: widget.localeListResolutionCallback,
            supportedLocales: widget.supportedLocales,
            showPerformanceOverlay: widget.showPerformanceOverlay,
            checkerboardRasterCacheImages: widget.checkerboardRasterCacheImages,
            checkerboardOffscreenLayers: widget.checkerboardOffscreenLayers,
            showSemanticsDebugger: widget.showSemanticsDebugger,
            debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
            inspectorSelectButtonBuilder: (BuildContext context, VoidCallback onPressed) {
              return CupertinoButton.filled(
                child: const Icon(
                  CupertinoIcons.search,
                  size: 28.0,
                  color: CupertinoColors.white,
                ),
                padding: EdgeInsets.zero,
                onPressed: onPressed,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CupertinoSystemColor extends InheritedWidget {
  const _CupertinoSystemColor({
    Key key,
    this.data,
    Widget child,
  }) : super(key: key, child: child);

  final CupertinoSystemColorData data;

  @override
  bool updateShouldNotify(_CupertinoSystemColor oldWidget) => oldWidget.data != data;
}

class CupertinoSystemColor {
  const CupertinoSystemColor._();
  static CupertinoSystemColorData of(BuildContext context) {
    final _CupertinoSystemColor widget = context.inheritFromWidgetOfExactType(_CupertinoSystemColor);
    assert(() {
        if (widget == null) {
          final Element element = context;
          throw FlutterError(
            'No _CupertinoSystemColor widget found.\n'
            '${context.widget.runtimeType} widgets require a _CupertinoSystemColor widget ancestor.\n'
            'The specific widget that could not find a _CupertinoSystemColor ancestor was:\n'
            '  ${context.widget}\n'
            'The ownership chain for the affected widget is:\n'
            '  ${element.debugGetCreatorChain(10)}'
          );
        }
        return true;
      }());

    return widget.data;
  }

  static CupertinoSystemColorData get fromSystem {

  }

  /// Fallback System Colors, extracted from:
  /// https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/color/#dynamic-system-colors
  /// https://developer.apple.com/design/resources/
  static CupertinoSystemColorData get fallbackValues {
    return CupertinoSystemColorData(
      label: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(255, 0, 0, 0),
        darkColor: const Color.fromARGB(255, 255, 255, 255),
        highContrastColor: const Color.fromARGB(255, 0, 0, 0),
        darkHighContrastColor: const Color.fromARGB(255, 255, 255, 255),
        elevatedColor: const Color.fromARGB(255, 0, 0, 0),
        darkElevatedColor: const Color.fromARGB(255, 255, 255, 255),
        highContrastElevatedColor: const Color.fromARGB(255, 0, 0, 0),
        darkHighContrastElevatedColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      secondaryLabel: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(255, 0, 0, 0),
        darkColor: const Color.fromARGB(255, 255, 255, 255),
        highContrastColor: const Color.fromARGB(255, 0, 0, 0),
        darkHighContrastColor: const Color.fromARGB(255, 255, 255, 255),
        elevatedColor: const Color.fromARGB(255, 0, 0, 0),
        darkElevatedColor: const Color.fromARGB(255, 255, 255, 255),
        highContrastElevatedColor: const Color.fromARGB(255, 0, 0, 0),
        darkHighContrastElevatedColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      tertiaryLabel: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(76, 60, 60, 67),
        darkColor: const Color.fromARGB(76, 235, 235, 245),
        highContrastColor: const Color.fromARGB(96, 60, 60, 67),
        darkHighContrastColor: const Color.fromARGB(96, 235, 235, 245),
        elevatedColor: const Color.fromARGB(76, 60, 60, 67),
        darkElevatedColor: const Color.fromARGB(76, 235, 235, 245),
        highContrastElevatedColor: const Color.fromARGB(96, 60, 60, 67),
        darkHighContrastElevatedColor: const Color.fromARGB(96, 235, 235, 245),
      ),
      quaternaryLabel: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(45, 60, 60, 67),
        darkColor: const Color.fromARGB(40, 235, 235, 245),
        highContrastColor: const Color.fromARGB(66, 60, 60, 67),
        darkHighContrastColor: const Color.fromARGB(61, 235, 235, 245),
        elevatedColor: const Color.fromARGB(45, 60, 60, 67),
        darkElevatedColor: const Color.fromARGB(40, 235, 235, 245),
        highContrastElevatedColor: const Color.fromARGB(66, 60, 60, 67),
        darkHighContrastElevatedColor: const Color.fromARGB(61, 235, 235, 245),
      ),
      systemFill: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(51, 120, 120, 128),
        darkColor: const Color.fromARGB(91, 120, 120, 128),
        highContrastColor: const Color.fromARGB(71, 120, 120, 128),
        darkHighContrastColor: const Color.fromARGB(112, 120, 120, 128),
        elevatedColor: const Color.fromARGB(51, 120, 120, 128),
        darkElevatedColor: const Color.fromARGB(91, 120, 120, 128),
        highContrastElevatedColor: const Color.fromARGB(71, 120, 120, 128),
        darkHighContrastElevatedColor: const Color.fromARGB(112, 120, 120, 128),
      ),
      secondarySystemFill: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(153, 60, 60, 67),
        darkColor: const Color.fromARGB(153, 235, 235, 245),
        highContrastColor: const Color.fromARGB(173, 60, 60, 67),
        darkHighContrastColor: const Color.fromARGB(173, 235, 235, 245),
        elevatedColor: const Color.fromARGB(153, 60, 60, 67),
        darkElevatedColor: const Color.fromARGB(153, 235, 235, 245),
        highContrastElevatedColor: const Color.fromARGB(173, 60, 60, 67),
        darkHighContrastElevatedColor: const Color.fromARGB(173, 235, 235, 245),
      ),
      tertiarySystemFill: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(30, 118, 118, 128),
        darkColor: const Color.fromARGB(61, 118, 118, 128),
        highContrastColor: const Color.fromARGB(51, 118, 118, 128),
        darkHighContrastColor: const Color.fromARGB(81, 118, 118, 128),
        elevatedColor: const Color.fromARGB(30, 118, 118, 128),
        darkElevatedColor: const Color.fromARGB(61, 118, 118, 128),
        highContrastElevatedColor: const Color.fromARGB(51, 118, 118, 128),
        darkHighContrastElevatedColor: const Color.fromARGB(81, 118, 118, 128),
      ),
      quaternarySystemFill: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(20, 116, 116, 128),
        darkColor: const Color.fromARGB(45, 118, 118, 128),
        highContrastColor: const Color.fromARGB(40, 116, 116, 128),
        darkHighContrastColor: const Color.fromARGB(66, 118, 118, 128),
        elevatedColor: const Color.fromARGB(20, 116, 116, 128),
        darkElevatedColor: const Color.fromARGB(45, 118, 118, 128),
        highContrastElevatedColor: const Color.fromARGB(40, 116, 116, 128),
        darkHighContrastElevatedColor: const Color.fromARGB(66, 118, 118, 128),
      ),
      placeholderText: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(76, 60, 60, 67),
        darkColor: const Color.fromARGB(76, 235, 235, 245),
        highContrastColor: const Color.fromARGB(96, 60, 60, 67),
        darkHighContrastColor: const Color.fromARGB(96, 235, 235, 245),
        elevatedColor: const Color.fromARGB(76, 60, 60, 67),
        darkElevatedColor: const Color.fromARGB(76, 235, 235, 245),
        highContrastElevatedColor: const Color.fromARGB(96, 60, 60, 67),
        darkHighContrastElevatedColor: const Color.fromARGB(96, 235, 235, 245),
      ),
      systemBackground: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(255, 255, 255, 255),
        darkColor: const Color.fromARGB(255, 0, 0, 0),
        highContrastColor: const Color.fromARGB(255, 255, 255, 255),
        darkHighContrastColor: const Color.fromARGB(255, 0, 0, 0),
        elevatedColor: const Color.fromARGB(255, 255, 255, 255),
        darkElevatedColor: const Color.fromARGB(255, 28, 28, 30),
        highContrastElevatedColor: const Color.fromARGB(255, 255, 255, 255),
        darkHighContrastElevatedColor: const Color.fromARGB(255, 36, 36, 38),
      ),
      secondarySystemBackground: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(255, 242, 242, 247),
        darkColor: const Color.fromARGB(255, 28, 28, 30),
        highContrastColor: const Color.fromARGB(255, 235, 235, 240),
        darkHighContrastColor: const Color.fromARGB(255, 36, 36, 38),
        elevatedColor: const Color.fromARGB(255, 242, 242, 247),
        darkElevatedColor: const Color.fromARGB(255, 44, 44, 46),
        highContrastElevatedColor: const Color.fromARGB(255, 235, 235, 240),
        darkHighContrastElevatedColor: const Color.fromARGB(255, 54, 54, 56),
      ),
      tertiarySystemBackground: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(255, 255, 255, 255),
        darkColor: const Color.fromARGB(255, 44, 44, 46),
        highContrastColor: const Color.fromARGB(255, 255, 255, 255),
        darkHighContrastColor: const Color.fromARGB(255, 54, 54, 56),
        elevatedColor: const Color.fromARGB(255, 255, 255, 255),
        darkElevatedColor: const Color.fromARGB(255, 58, 58, 60),
        highContrastElevatedColor: const Color.fromARGB(255, 255, 255, 255),
        darkHighContrastElevatedColor: const Color.fromARGB(255, 68, 68, 70),
      ),
      systemGroupedBackground: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(255, 242, 242, 247),
        darkColor: const Color.fromARGB(255, 0, 0, 0),
        highContrastColor: const Color.fromARGB(255, 235, 235, 240),
        darkHighContrastColor: const Color.fromARGB(255, 0, 0, 0),
        elevatedColor: const Color.fromARGB(255, 242, 242, 247),
        darkElevatedColor: const Color.fromARGB(255, 28, 28, 30),
        highContrastElevatedColor: const Color.fromARGB(255, 235, 235, 240),
        darkHighContrastElevatedColor: const Color.fromARGB(255, 36, 36, 38),
      ),
      secondarySystemGroupedBackground: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(255, 242, 242, 247),
        darkColor: const Color.fromARGB(255, 0, 0, 0),
        highContrastColor: const Color.fromARGB(255, 235, 235, 240),
        darkHighContrastColor: const Color.fromARGB(255, 0, 0, 0),
        elevatedColor: const Color.fromARGB(255, 242, 242, 247),
        darkElevatedColor: const Color.fromARGB(255, 28, 28, 30),
        highContrastElevatedColor: const Color.fromARGB(255, 235, 235, 240),
        darkHighContrastElevatedColor: const Color.fromARGB(255, 36, 36, 38),
      ),
      tertiarySystemGroupedBackground: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(255, 242, 242, 247),
        darkColor: const Color.fromARGB(255, 44, 44, 46),
        highContrastColor: const Color.fromARGB(255, 235, 235, 240),
        darkHighContrastColor: const Color.fromARGB(255, 54, 54, 56),
        elevatedColor: const Color.fromARGB(255, 242, 242, 247),
        darkElevatedColor: const Color.fromARGB(255, 58, 58, 60),
        highContrastElevatedColor: const Color.fromARGB(255, 235, 235, 240),
        darkHighContrastElevatedColor: const Color.fromARGB(255, 68, 68, 70),
      ),
      separator: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(73, 60, 60, 67),
        darkColor: const Color.fromARGB(153, 84, 84, 88),
        highContrastColor: const Color.fromARGB(94, 60, 60, 67),
        darkHighContrastColor: const Color.fromARGB(173, 84, 84, 88),
        elevatedColor: const Color.fromARGB(73, 60, 60, 67),
        darkElevatedColor: const Color.fromARGB(153, 84, 84, 88),
        highContrastElevatedColor: const Color.fromARGB(94, 60, 60, 67),
        darkHighContrastElevatedColor: const Color.fromARGB(173, 84, 84, 88),
      ),
      opaqueSeparator: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(255, 198, 198, 200),
        darkColor: const Color.fromARGB(255, 56, 56, 58),
        highContrastColor: const Color.fromARGB(255, 198, 198, 200),
        darkHighContrastColor: const Color.fromARGB(255, 56, 56, 58),
        elevatedColor: const Color.fromARGB(255, 198, 198, 200),
        darkElevatedColor: const Color.fromARGB(255, 56, 56, 58),
        highContrastElevatedColor: const Color.fromARGB(255, 198, 198, 200),
        darkHighContrastElevatedColor: const Color.fromARGB(255, 56, 56, 58),
      ),
      link: CupertinoDynamicColor(
        normalColor: const Color.fromARGB(255, 0, 122, 255),
        darkColor: const Color.fromARGB(255, 9, 132, 255),
        highContrastColor: const Color.fromARGB(255, 0, 122, 255),
        darkHighContrastColor: const Color.fromARGB(255, 9, 132, 255),
        elevatedColor: const Color.fromARGB(255, 0, 122, 255),
        darkElevatedColor: const Color.fromARGB(255, 9, 132, 255),
        highContrastElevatedColor: const Color.fromARGB(255, 0, 122, 255),
        darkHighContrastElevatedColor: const Color.fromARGB(255, 9, 132, 255),
      ),
      systemBlue: CupertinoDynamicColor.withVibrancyAndContrast(
        normalColor: const Color.fromARGB(255, 0, 122, 255),
        darkColor: const Color.fromARGB(255, 10, 132, 255),
        highContrastColor: const Color.fromARGB(255, 0, 64, 221),
        darkHighContrastColor: const Color.fromARGB(255, 64, 156, 255),
      ),
      systemGreen: CupertinoDynamicColor.withVibrancyAndContrast(
        normalColor: const Color.fromARGB(255, 52, 199, 89),
        darkColor: const Color.fromARGB(255, 48, 209, 88),
        highContrastColor: const Color.fromARGB(255, 36, 138, 61),
        darkHighContrastColor: const Color.fromARGB(255, 48, 219, 91),
      ),
      systemIndigo: CupertinoDynamicColor.withVibrancyAndContrast(
        normalColor: const Color.fromARGB(255, 88, 86, 214),
        darkColor: const Color.fromARGB(255, 94, 92, 230),
        highContrastColor: const Color.fromARGB(255, 54, 52, 163),
        darkHighContrastColor: const Color.fromARGB(255, 125, 122, 255),
      ),
      systemOrange: CupertinoDynamicColor.withVibrancyAndContrast(
        normalColor: const Color.fromARGB(255, 255, 149, 0),
        darkColor: const Color.fromARGB(255, 255, 159, 10),
        highContrastColor: const Color.fromARGB(255, 201, 52, 0),
        darkHighContrastColor: const Color.fromARGB(255, 255, 179, 64),
      ),
      systemPink: CupertinoDynamicColor.withVibrancyAndContrast(
        normalColor: const Color.fromARGB(255, 255, 45, 85),
        darkColor: const Color.fromARGB(255, 255, 55, 95),
        highContrastColor: const Color.fromARGB(255, 211, 15, 69),
        darkHighContrastColor: const Color.fromARGB(255, 255, 100, 130),
      ),
      systemPurple: CupertinoDynamicColor.withVibrancyAndContrast(
        normalColor: const Color.fromARGB(255, 175, 82, 222),
        darkColor: const Color.fromARGB(255, 191, 90, 242),
        highContrastColor: const Color.fromARGB(255, 137, 68, 171),
        darkHighContrastColor: const Color.fromARGB(255, 218, 143, 255),
      ),
      systemRed: CupertinoDynamicColor.withVibrancyAndContrast(
        normalColor: const Color.fromARGB(255, 255, 59, 48),
        darkColor: const Color.fromARGB(255, 255, 69, 58),
        highContrastColor: const Color.fromARGB(255, 215, 0, 21),
        darkHighContrastColor: const Color.fromARGB(255, 255, 105, 97),
      ),
      systemTeal: CupertinoDynamicColor.withVibrancyAndContrast(
        normalColor: const Color.fromARGB(255, 90, 200, 250),
        darkColor: const Color.fromARGB(255, 100, 210, 255),
        highContrastColor: const Color.fromARGB(255, 0, 113, 164),
        darkHighContrastColor: const Color.fromARGB(255, 112, 215, 255),
      ),
      systemYellow: CupertinoDynamicColor.withVibrancyAndContrast(
        normalColor: const Color.fromARGB(255, 255, 204, 0),
        darkColor: const Color.fromARGB(255, 255, 214, 10),
        highContrastColor: const Color.fromARGB(255, 160, 90, 0),
        darkHighContrastColor: const Color.fromARGB(255, 255, 212, 38),
      ),
      systemGray: CupertinoDynamicColor.withVibrancyAndContrast(
        normalColor: const Color.fromARGB(255, 142, 142, 147),
        darkColor: const Color.fromARGB(255, 142, 142, 147),
        highContrastColor: const Color.fromARGB(255, 108, 108, 112),
        darkHighContrastColor: const Color.fromARGB(255, 174, 174, 178),
      ),
      systemGray2: CupertinoDynamicColor.withVibrancyAndContrast(
        normalColor: const Color.fromARGB(255, 174, 174, 178),
        darkColor: const Color.fromARGB(255, 99, 99, 102),
        highContrastColor: const Color.fromARGB(255, 142, 142, 147),
        darkHighContrastColor: const Color.fromARGB(255, 124, 124, 128),
      ),
      systemGray3: CupertinoDynamicColor.withVibrancyAndContrast(
        normalColor: const Color.fromARGB(255, 199, 199, 204),
        darkColor: const Color.fromARGB(255, 72, 72, 74),
        highContrastColor: const Color.fromARGB(255, 174, 174, 178),
        darkHighContrastColor: const Color.fromARGB(255, 84, 84, 86),
      ),
      systemGray4: CupertinoDynamicColor.withVibrancyAndContrast(
        normalColor: const Color.fromARGB(255, 209, 209, 214),
        darkColor: const Color.fromARGB(255, 58, 58, 60),
        highContrastColor: const Color.fromARGB(255, 188, 188, 192),
        darkHighContrastColor: const Color.fromARGB(255, 68, 68, 70),
      ),
      systemGray5: CupertinoDynamicColor.withVibrancyAndContrast(
        normalColor: const Color.fromARGB(255, 229, 229, 234),
        darkColor: const Color.fromARGB(255, 44, 44, 46),
        highContrastColor: const Color.fromARGB(255, 216, 216, 220),
        darkHighContrastColor: const Color.fromARGB(255, 54, 54, 56),
      ),
      systemGray6: CupertinoDynamicColor.withVibrancyAndContrast(
        normalColor: const Color.fromARGB(255, 242, 242, 247),
        darkColor: const Color.fromARGB(255, 28, 28, 30),
        highContrastColor: const Color.fromARGB(255, 235, 235, 240),
        darkHighContrastColor: const Color.fromARGB(255, 36, 36, 38),
      ),
    );
  }
}
