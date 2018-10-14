// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gallery/gallery/app.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  if (binding is LiveTestWidgetsFlutterBinding)
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Flutter Gallery drawer item test', (WidgetTester tester) async {
    bool hasFeedback = false;

    await tester.pumpWidget(
      GalleryApp(
        testMode: true,
        onSendFeedback: () {
          hasFeedback = true;
        },
      ),
    );
    await tester.pump(); // see https://github.com/flutter/flutter/issues/1865
    await tester.pump(); // triggers a frame

    // Show the options page
    await tester.tap(find.byTooltip('Toggle options page'));
    await tester.pumpAndSettle();

    MaterialApp app = find.byType(MaterialApp).evaluate().first.widget;
    expect(app.theme.brightness, equals(Brightness.light));

    // Switch to the dark theme: first switch control
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    app = find.byType(MaterialApp).evaluate().first.widget;
    expect(app.theme.brightness, equals(Brightness.dark));
    expect(app.theme.platform, equals(TargetPlatform.android));

    // Popup the platform menu: second menu button, choose 'Cupertino'
    await tester.tap(find.byIcon(Icons.arrow_drop_down).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cupertino').at(1));
    await tester.pumpAndSettle();
    app = find.byType(MaterialApp).evaluate().first.widget;
    expect(app.theme.platform, equals(TargetPlatform.iOS));

    // Verify the font scale.
    final Size origTextSize = tester.getSize(find.text('Text size'));
    expect(origTextSize, equals(const Size(144.0, 16.0)));

    // Popup the text size menu: first menu button, choose 'Small'
    await tester.tap(find.byIcon(Icons.arrow_drop_down).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Small'));
    await tester.pumpAndSettle();
    Size textSize = tester.getSize(find.text('Text size'));
    expect(textSize, equals(const Size(116.0, 13.0)));

    // Set font scale back to the default.
    await tester.tap(find.byIcon(Icons.arrow_drop_down).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('System Default'));
    await tester.pumpAndSettle();
    textSize = tester.getSize(find.text('Text size'));
    expect(textSize, origTextSize);

    // Switch to slow animation: third switch control
    expect(timeDilation, 1.0);
    await tester.tap(find.byType(Switch).at(2));
    await tester.pumpAndSettle();
    expect(timeDilation, greaterThan(1.0));

    // Restore normal animation: third switch control
    await tester.tap(find.byType(Switch).at(2));
    await tester.pumpAndSettle();
    expect(timeDilation, 1.0);

    // Send feedback.
    expect(hasFeedback, false);

    // Scroll to the end
    await tester.drag(find.text('Text size'), const Offset(0.0, -1000.0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send feedback'));
    await tester.pumpAndSettle();
    expect(hasFeedback, true);

    // Hide the options page
    await tester.tap(find.byTooltip('Toggle options page'));
    await tester.pumpAndSettle();
  });
}
