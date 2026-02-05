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
// TODO(rkishan516): Move this to flutter_test package.
// Tracking issue: https://github.com/flutter/flutter/issues/181283
class TestWidgetsApp extends StatelessWidget {
  /// Creates a minimal [WidgetsApp] for testing.
  const TestWidgetsApp({super.key, required this.home, this.color = const Color(0xFFFFFFFF)});

  /// The widget to display within the app.
  final Widget home;

  /// The primary color for the application.
  ///
  /// Defaults to white.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: color,
      home: home,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
        return PageRouteBuilder<T>(
          pageBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) => builder(context),
        );
      },
    );
  }
}
