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
    void mockOnSendFeedback() {
      hasFeedback = true;
    }

    await tester.pumpWidget(new GalleryApp(onSendFeedback: mockOnSendFeedback));
    await tester.pump(); // see https://github.com/flutter/flutter/issues/1865
    await tester.pump(); // triggers a frame

    final Finder finder = find.byWidgetPredicate((Widget widget) {
      return widget is Tooltip && widget.message == 'Open navigation menu';
    });
    expect(finder, findsOneWidget);

    // Open drawer
    await tester.tap(finder);
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1)); // end animation

    MaterialApp app = find.byType(MaterialApp).evaluate().first.widget;
    expect(app.theme.brightness, equals(Brightness.light));

    // Change theme
    await tester.tap(find.text('Dark'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1)); // end animation
    app = find.byType(MaterialApp).evaluate().first.widget;
    expect(app.theme.brightness, equals(Brightness.dark));
    expect(app.theme.platform, equals(TargetPlatform.android));

    // Change platform
    await tester.tap(find.text('iOS'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1)); // end animation
    app = find.byType(MaterialApp).evaluate().first.widget;
    expect(app.theme.platform, equals(TargetPlatform.iOS));

    // Verify the font scale.
    final Size origTextSize = tester.getSize(find.text('Small'));
    expect(origTextSize, equals(const Size(176.0, 14.0)));

    // Switch font scale.
    await tester.tap(find.text('Small'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Wait until it's changed.
    final Size textSize = tester.getSize(find.text('Small'));
    expect(textSize, equals(const Size(176.0, 11.0)));

    // Set font scale back to default.
    await tester.tap(find.text('System Default'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Wait until it's changed.
    final Size newTextSize = tester.getSize(find.text('Small'));
    expect(newTextSize, equals(origTextSize));

    // Scroll to the bottom of the menu.
    await tester.drag(find.text('Small'), const Offset(0.0, -1000.0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Wait until it's changed.

    // Test slow animations.
    expect(timeDilation, equals(1.0));
    await tester.tap(find.text('Animate Slowly'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Wait until it's changed.
    expect(timeDilation, greaterThan(1.0));

    // Put back time dilation (so as not to throw off tests after this one).
    await tester.tap(find.text('Animate Slowly'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Wait until it's changed.
    expect(timeDilation, equals(1.0));

    // Send feedback.
    expect(hasFeedback, false);
    await tester.tap(find.text('Send feedback'));
    await tester.pump();
    expect(hasFeedback, true);

    // Close drawer
    await tester.tap(find.byType(DrawerController));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1)); // end animation
  });
}
