// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [WidgetsApp].

void main() => runApp(const WidgetsAppExampleApp());

class WidgetsAppExampleApp extends StatelessWidget {
  const WidgetsAppExampleApp({super.key});

  @override
  Widget build(final BuildContext context) {
    return WidgetsApp(
      title: 'Example',
      color: const Color(0xFF000000),
      home: const Center(child: Text('Hello World')),
      pageRouteBuilder: <T>(final RouteSettings settings, final WidgetBuilder builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (final BuildContext context, final Animation<double> animation, final Animation<double> secondaryAnimation) =>
            builder(context),
      ),
    );
  }
}
