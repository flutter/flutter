// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/cupertino.dart';
/// @docImport 'package:flutter/material.dart';
/// @docImport 'package:flutter_test/flutter_test.dart';
library;

import 'package:flutter/widgets.dart';

/// A minimal [WidgetsApp] wrapper for use in widget tests.
///
/// This provides a convenient way to wrap test widgets with the necessary
/// app-level widgets (like [Directionality], [MediaQuery], etc.) that
/// [WidgetsApp] provides, without the overhead of [MaterialApp] or [CupertinoApp].
///
/// The [pageRouteBuilder] creates a [Navigator] which provides an [Overlay],
/// so widgets that need overlay support (like [Draggable], [Tooltip], etc.)
/// will work correctly when placed in [home].
///
/// Example usage:
/// ```dart
/// testWidgets('my test', (WidgetTester tester) async {
///   await tester.pumpWidget(
///     TestWidgetsApp(
///       home: GestureDetector(
///         onTap: () {},
///         child: Container(),
///       ),
///     ),
///   );
/// });
/// ```
///
/// For navigation tests with routes:
/// ```dart
/// testWidgets('navigation test', (WidgetTester tester) async {
///   await tester.pumpWidget(
///     TestWidgetsApp(
///       home: const Text('Home'),
///       routes: <String, WidgetBuilder>{
///         '/details': (BuildContext context) => const Text('Details'),
///       },
///     ),
///   );
///   tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/details');
///   await tester.pumpAndSettle();
/// });
/// ```
// TODO(rkishan516): Move this to flutter_test package.
// Tracking issue: https://github.com/flutter/flutter/issues/181283
class TestWidgetsApp extends StatelessWidget {
  /// Creates a minimal [WidgetsApp] for testing.
  const TestWidgetsApp({
    super.key,
    this.navigatorKey,
    this.home,
    this.routes = const <String, WidgetBuilder>{},
    this.color = const Color(0xFFFFFFFF),
    this.pageRouteBuilder = _defaultPageRouteBuilder,
  });

  /// A key to use when building the [Navigator].
  ///
  /// In tests, this allows direct access to the [NavigatorState] for
  /// programmatic navigation without needing to find the [Navigator] widget:
  ///
  /// ```dart
  /// final navigatorKey = GlobalKey<NavigatorState>();
  /// await tester.pumpWidget(TestWidgetsApp(
  ///   navigatorKey: navigatorKey,
  ///   home: const Text('Home'),
  /// ));
  /// navigatorKey.currentState!.pushNamed('/details');
  /// ```
  ///
  /// See also:
  ///
  ///  * [WidgetsApp.navigatorKey], the equivalent property in [WidgetsApp].
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The widget displayed when the app launches.
  ///
  /// In tests, this is where you place the widget under test. The widget
  /// will have access to [Navigator], [Overlay], and other app-level
  /// services provided by [WidgetsApp].
  ///
  /// See also:
  ///
  ///  * [WidgetsApp.home], the equivalent property in [WidgetsApp].
  final Widget? home;

  /// The application's top-level routing table.
  ///
  /// Maps route names to widget builders. When navigating to a named route,
  /// the corresponding builder is called to create the route's content.
  ///
  /// In tests, routes are built using [pageRouteBuilder], which defaults to
  /// zero-duration transitions for instant navigation without waiting for
  /// animations.
  ///
  /// Defaults to an empty map.
  ///
  /// See also:
  ///
  ///  * [WidgetsApp.routes], the equivalent property in [WidgetsApp].
  final Map<String, WidgetBuilder> routes;

  /// The primary color to use for the application in the operating system
  /// interface.
  ///
  /// This is typically unused in tests as OS-level features are not
  /// exercised.
  ///
  /// Defaults to white.
  ///
  /// See also:
  ///
  ///  * [WidgetsApp.color], the equivalent property in [WidgetsApp].
  final Color color;

  /// A function that creates page routes for named navigation.
  ///
  /// Defaults to a [PageRouteBuilder] with no transition animation, allowing
  /// instant navigation without calling [WidgetTester.pumpAndSettle].
  ///
  /// Override this to customize route behavior or test specific transitions:
  ///
  /// ```dart
  /// TestWidgetsApp(
  ///   pageRouteBuilder: <T>(settings, builder) {
  ///     return PageRouteBuilder<T>(
  ///       settings: settings,
  ///       transitionDuration: const Duration(milliseconds: 300),
  ///       pageBuilder: (context, _, __) => builder(context),
  ///       transitionsBuilder: (_, animation, __, child) {
  ///         return FadeTransition(opacity: animation, child: child);
  ///       },
  ///     );
  ///   },
  ///   home: const Text('Home'),
  /// )
  /// ```
  ///
  /// See also:
  ///
  ///  * [WidgetsApp.pageRouteBuilder], the equivalent property in [WidgetsApp].
  final PageRouteFactory pageRouteBuilder;

  static PageRoute<T> _defaultPageRouteBuilder<T>(RouteSettings settings, WidgetBuilder builder) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) => builder(context),
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: color,
      navigatorKey: navigatorKey,
      home: home,
      routes: routes,
      pageRouteBuilder: pageRouteBuilder,
    );
  }
}
