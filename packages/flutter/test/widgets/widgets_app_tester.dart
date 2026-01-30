// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/cupertino.dart';
/// @docImport 'package:flutter/material.dart';
library;

import 'package:flutter/widgets.dart';

/// A minimal [WidgetsApp] wrapper for use in widget tests.
///
/// This provides a convenient way to wrap test widgets with the necessary
/// app-level widgets (like [Directionality], [MediaQuery], etc.) that
/// [WidgetsApp] provides, without the overhead of [MaterialApp] or [CupertinoApp].
///
/// The [PageRouteBuilder] creates a [Navigator] which provides an [Overlay],
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
    this.home,
    this.routes = const <String, WidgetBuilder>{},
    this.color = const Color(0xFFFFFFFF),
    this.transitionsBuilder = _defaultTransitionsBuilder,
  });

  /// The widget to display within the app.
  final Widget? home;

  /// The application's top-level routing table.
  ///
  /// When a named route is pushed with [Navigator.pushNamed], the route name is
  /// looked up in this map. If the name is present, the associated
  /// [WidgetBuilder] is used to construct a [PageRouteBuilder] that performs
  /// a fade transition to the new route.
  ///
  /// Defaults to an empty map.
  final Map<String, WidgetBuilder> routes;

  /// The primary color for the application.
  ///
  /// Defaults to white.
  final Color color;

  /// The transition builder used for page route animations.
  ///
  /// Defaults to a simple [FadeTransition].
  final RouteTransitionsBuilder transitionsBuilder;

  static Widget _defaultTransitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: animation, child: child);

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: color,
      home: home,
      routes: routes,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) => builder(context),
          transitionsBuilder: transitionsBuilder,
        );
      },
    );
  }
}
