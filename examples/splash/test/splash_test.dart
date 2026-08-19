// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splash/main.dart' as entrypoint;

void main() {
  testWidgets('Displays flutter logo and message', (WidgetTester tester) async {
    entrypoint.main();

    expect(find.byType(FlutterLogo), findsOneWidget);
    expect(
      find.text('This app is only meant to be run under the Flutter debugger'),
      findsOneWidget,
    );
  });

  testWidgets('Uses the original splash palette', (WidgetTester tester) async {
    entrypoint.main();

    // The outermost DecoratedBox is the app background; FlutterLogo builds one
    // of its own further down the tree.
    final background = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    expect(background.decoration, const BoxDecoration(color: Color(0xFFFFFFFF)));

    final message = tester.widget<Text>(
      find.text('This app is only meant to be run under the Flutter debugger'),
    );
    expect(message.style?.color, const Color(0xDD000000));
  });
}
