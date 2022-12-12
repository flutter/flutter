// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Widgets running with runApp can find View.of', (WidgetTester tester) async {
    FlutterView? view;

    runApp(
      Builder(
        builder: (BuildContext context) {
          view = View.of(context);
          return Container();
        },
      ),
    );

    expect(view, isNotNull);
    expect(view, isA<FlutterView>());
  });

  testWidgets('Widgets running with pumpWidget can find View.of', (WidgetTester tester) async {
    FlutterView? view;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          view = View.of(context);
          return Container();
        },
      ),
    );

    expect(view, isNotNull);
    expect(view, isA<FlutterView>());
  });
}
