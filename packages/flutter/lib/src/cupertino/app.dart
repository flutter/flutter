// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show Diagnosticable;
import 'package:flutter/rendering.dart';
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
    );
  }
}

@immutable
class CupertinoSystemColorData extends Diagnosticable {
  const CupertinoSystemColorData(
    @required this.label,
    @required this.secondaryLabel,
    @required this.tertiaryLabel,
    @required this.quaternaryLabel,
    @required this.systemFill,
    @required this.secondarySystemFill,
    @required this.tertiarySystemFill,
    @required this.quaternarySystemFill,
    @required this.placeholderText,
    @required this.systemBackground,
    @required this.secondarySystemBackground,
    @required this.tertiarySystemBackground,
    @required this.systemGroupedBackground,
    @required this.secondarySystemGroupedBackground,
    @required this.tertiarySystemGroupedBackground,
    @required this.separator,
    @required this.opaqueSeparator,
    @required this.link,
    @required this.systemBlue,
    @required this.systemGreen,
    @required this.systemIndigo,
    @required this.systemOrange,
    @required this.systemPink,
    @required this.systemPurple,
    @required this.systemRed,
    @required this.systemTeal,
    @required this.systemYellow,
    @required this.systemGray,
    @required this.systemGray2,
    @required this.systemGray3,
    @required this.systemGray4,
    @required this.systemGray5,
    @required this.systemGray6,
  ) : assert(label != null),
      assert(label != null),
      assert(secondaryLabel != null),
      assert(tertiaryLabel != null),
      assert(quaternaryLabel != null),
      assert(systemFill != null),
      assert(secondarySystemFill != null),
      assert(tertiarySystemFill != null),
      assert(quaternarySystemFill != null),
      assert(placeholderText != null),
      assert(systemBackground != null),
      assert(secondarySystemBackground != null),
      assert(tertiarySystemBackground != null),
      assert(systemGroupedBackground != null),
      assert(secondarySystemGroupedBackground != null),
      assert(tertiarySystemGroupedBackground != null),
      assert(separator != null),
      assert(opaqueSeparator != null),
      assert(link != null),
      assert(systemBlue != null),
      assert(systemGreen != null),
      assert(systemIndigo != null),
      assert(systemOrange != null),
      assert(systemPink != null),
      assert(systemPurple != null),
      assert(systemRed != null),
      assert(systemTeal != null),
      assert(systemYellow != null),
      assert(systemGray != null),
      assert(systemGray2 != null),
      assert(systemGray3 != null),
      assert(systemGray4 != null),
      assert(systemGray5 != null),
      assert(systemGray6 != null),
      super();
  // Label Colors
  /// The color for text labels containing primary content.
  final CupertinoDynamicColor label;

  /// The color for text labels containing secondary content.
  final CupertinoDynamicColor secondaryLabel;

  /// The color for text labels containing tertiary content.
  final CupertinoDynamicColor tertiaryLabel;

  /// The color for text labels containing quaternary content.
  final CupertinoDynamicColor quaternaryLabel;

  // FIll Colors
  /// An overlay fill color for thin and small shapes.
  final CupertinoDynamicColor systemFill;

  /// An overlay fill color for medium-size shapes.
  final CupertinoDynamicColor secondarySystemFill;

  /// An overlay fill color for large shapes.
  final CupertinoDynamicColor tertiarySystemFill;

  /// An overlay fill color for large areas containing complex content.
  final CupertinoDynamicColor quaternarySystemFill;

  // Text Colors
  /// The color for placeholder text in controls or text views.
  final CupertinoDynamicColor placeholderText;

  // Standard Content Background Colors
  // Use these colors for standard table views and designs that have a white primary background in a light environment.

  /// The color for the main background of your interface.
  final CupertinoDynamicColor systemBackground;

  /// The color for content layered on top of the main background.
  final CupertinoDynamicColor secondarySystemBackground;

  /// The color for content layered on top of secondary backgrounds.
  final CupertinoDynamicColor tertiarySystemBackground;

  // Grouped Content Background Colors
  // Use these colors for grouped content, including table views and platter-based designs.

  /// The color for the main background of your grouped interface.
  final CupertinoDynamicColor systemGroupedBackground;

  /// The color for content layered on top of the main background of your grouped interface.
  final CupertinoDynamicColor secondarySystemGroupedBackground;

  /// The color for content layered on top of secondary backgrounds of your grouped interface.
  final CupertinoDynamicColor tertiarySystemGroupedBackground;

  // Separator Colors
  /// The color for thin borders or divider lines that allows some underlying content to be visible.
  final CupertinoDynamicColor separator;

  /// The color for borders or divider lines that hide any underlying content.
  final CupertinoDynamicColor opaqueSeparator;

  /// The color for links.
  final CupertinoDynamicColor link;

  /// A blue color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemBlue;

  /// A green color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemGreen;

  /// An indigo color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemIndigo;

  /// An orange color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemOrange;

  /// A pink color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemPink;

  /// A purple color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemPurple;

  /// A red color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemRed;

  /// A teal color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemTeal;

  /// A yellow color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemYellow;

  /// The base gray color.
  final CupertinoDynamicColor systemGray;

  /// A second-level shade of grey.
  final CupertinoDynamicColor systemGray2;

  /// A third-level shade of grey.
  final CupertinoDynamicColor systemGray3;

  /// A fourth-level shade of grey.
  final CupertinoDynamicColor systemGray4;

  /// A fifth-level shade of grey.
  final CupertinoDynamicColor systemGray5;

  /// A sixth-level shade of grey.
  final CupertinoDynamicColor systemGray6;

}
