// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoImplicitViewPlatformDispatcher extends TestPlatformDispatcher {
  _NoImplicitViewPlatformDispatcher() : super(platformDispatcher: PlatformDispatcher.instance);

  @override
  TestFlutterView? get implicitView => null;
}

class _NoImplicitViewTestBinding extends AutomatedTestWidgetsFlutterBinding {
  TestPlatformDispatcher? _testPlatformDispatcher;

  @override
  TestPlatformDispatcher get platformDispatcher =>
      _testPlatformDispatcher ??= _NoImplicitViewPlatformDispatcher();
}

void main() {
  final binding = _NoImplicitViewTestBinding();

  testWidgets('testWidgets renders and handles gestures without an implicit view', (
    WidgetTester tester,
  ) async {
    expect(binding.platformDispatcher.implicitView, isNull);
    expect(binding.renderViews, isEmpty);

    final TestFlutterView view = tester.platformDispatcher.views.first;
    var taps = 0;
    var longPresses = 0;
    await tester.pumpWidget(
      View(
        view: view,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GestureDetector(onTap: () => taps += 1, child: const Text('tap target')),
                GestureDetector(
                  onLongPress: () => longPresses += 1,
                  child: const Text('long press target'),
                ),
              ],
            ),
          ),
        ),
      ),
      wrapWithView: false,
    );
    expect(binding.renderViews, hasLength(1));
    await tester.tap(find.text('tap target'));
    await tester.longPress(find.text('long press target'));
    expect(taps, 1);
    expect(longPresses, 1);
  });

  testWidgets('the previous multi-view tree is unmounted after a test', (
    WidgetTester tester,
  ) async {
    expect(find.text('tap target'), findsNothing);
    expect(find.text('long press target'), findsNothing);
    expect(binding.renderViews, isEmpty);
  });
}
