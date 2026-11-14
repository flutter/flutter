// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Flutter code sample for [Text.selectionHeightStyle].

void main() => runApp(const SelectionHeightStyleExampleApp());

class SelectionHeightStyleExampleApp extends StatelessWidget {
  const SelectionHeightStyleExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const ui.Color(0xFFFFFFFF),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => builder(context),
          ),
      home: DefaultSelectionStyle.merge(
        selectionHeightStyle: ui.BoxHeightStyle.max,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SelectableRegion(
            selectionControls: emptyTextSelectionControls,
            child: Center(
              child: Text(
                'Select this text. The line height is larger than the glyph height.',
                style: TextStyle(fontSize: 20, height: 3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
