// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';

class WidgetPreviewerWidgetScaffolding extends StatelessWidget {
  const WidgetPreviewerWidgetScaffolding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: Colors.blue,
      home: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return WidgetPreviewerWindowConstraints(
            constraints: constraints,
            child: child,
          );
        },
      ),
      pageRouteBuilder:
          <T>(RouteSettings settings, WidgetBuilder builder) =>
              PageRouteBuilder<T>(
                settings: settings,
                pageBuilder:
                    (
                      BuildContext context,
                      Animation<double> animation,
                      Animation<double> secondaryAnimation,
                    ) => builder(context),
              ),
    );
  }
}
