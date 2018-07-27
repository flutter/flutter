// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import '../services/fake_platform_views.dart';

void main() {

  testWidgets('Create Android view', (WidgetTester tester) async {
    final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
    final FakePlatformViewsController viewsController = new FakePlatformViewsController(TargetPlatform.android);
    viewsController.registerViewType('webview');

    await tester.pumpWidget(
        const Center(
            child: const SizedBox(
              width: 200.0,
              height: 100.0,
              child: const AndroidView(viewType: 'webview'),
            )
        )
    );

    expect(
      viewsController.views,
      unorderedEquals(<FakePlatformView>[
        new FakePlatformView(currentViewId + 1, 'webview', const Size(200.0, 100.0))
      ])
    );
  });

  testWidgets('Resize Android view', (WidgetTester tester) async {
    final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
    final FakePlatformViewsController viewsController = new FakePlatformViewsController(TargetPlatform.android);
    viewsController.registerViewType('webview');
    await tester.pumpWidget(
        const Center(
            child: const SizedBox(
              width: 200.0,
              height: 100.0,
              child: const AndroidView(viewType: 'webview'),
            )
        )
    );

    await tester.pumpWidget(
        const Center(
            child: const SizedBox(
              width: 400.0,
              height: 200.0,
              child: const AndroidView(viewType: 'webview'),
            )
        )
    );

    expect(
        viewsController.views,
        unorderedEquals(<FakePlatformView>[
          new FakePlatformView(currentViewId + 1, 'webview', const Size(400.0, 200.0))
        ])
    );
  });

  testWidgets('Change Android view type', (WidgetTester tester) async {
    final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
    final FakePlatformViewsController viewsController = new FakePlatformViewsController(TargetPlatform.android);
    viewsController.registerViewType('webview');
    viewsController.registerViewType('maps');
    await tester.pumpWidget(
        const Center(
            child: const SizedBox(
              width: 200.0,
              height: 100.0,
              child: const AndroidView(viewType: 'webview'),
            )
        )
    );

    await tester.pumpWidget(
        const Center(
            child: const SizedBox(
              width: 200.0,
              height: 100.0,
              child: const AndroidView(viewType: 'maps'),
            )
        )
    );

    expect(
        viewsController.views,
        unorderedEquals(<FakePlatformView>[
          new FakePlatformView(currentViewId + 2, 'maps', const Size(200.0, 100.0))
        ])
    );
  });

  testWidgets('Dispose Android view', (WidgetTester tester) async {
    final FakePlatformViewsController viewsController = new FakePlatformViewsController(TargetPlatform.android);
    viewsController.registerViewType('webview');
    await tester.pumpWidget(
        const Center(
            child: const SizedBox(
              width: 200.0,
              height: 100.0,
              child: const AndroidView(viewType: 'webview'),
            )
        )
    );

    await tester.pumpWidget(
        const Center(
            child: const SizedBox(
              width: 200.0,
              height: 100.0,
            )
        )
    );

    expect(
      viewsController.views,
      isEmpty,
    );
  });

  testWidgets('Android view survives widget tree change', (WidgetTester tester) async {
    final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
    final FakePlatformViewsController viewsController = new FakePlatformViewsController(TargetPlatform.android);
    viewsController.registerViewType('webview');
    final GlobalKey key = new GlobalKey();
    await tester.pumpWidget(
        new Center(
            child: new SizedBox(
              width: 200.0,
              height: 100.0,
              child: new AndroidView(viewType: 'webview', key: key),
            )
        )
    );

    await tester.pumpWidget(
      new Center(
        child: new Container(
          child: new SizedBox(
            width: 200.0,
            height: 100.0,
            child: new AndroidView(viewType: 'webview', key: key),
          ),
        ),
      ),
    );

    expect(
        viewsController.views,
        unorderedEquals(<FakePlatformView>[
          new FakePlatformView(currentViewId + 1, 'webview', const Size(200.0, 100.0))
        ])
    );
  });
}
