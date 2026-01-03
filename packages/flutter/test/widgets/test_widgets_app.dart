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
/// Example usage:
/// ```dart
/// await tester.pumpWidget(
///   TestWidgetsApp(
///     child: GestureDetector(
///       onTap: () {},
///       child: Container(),
///     ),
///   ),
/// );
/// ```
class TestWidgetsApp extends StatelessWidget {
  /// Creates a minimal [WidgetsApp] for testing.
  const TestWidgetsApp({super.key, required this.child, this.color = const Color(0xFFFFFFFF)});

  /// The widget to display within the app.
  final Widget child;

  /// The primary color for the application.
  ///
  /// Defaults to white.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: color,
      builder: (BuildContext context, Widget? navigatorChild) {
        return child;
      },
    );
  }
}
