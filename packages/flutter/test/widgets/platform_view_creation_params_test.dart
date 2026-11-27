// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('!chrome')
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../services/fake_platform_views.dart';

void main() {
  testWidgets('AndroidView does not recreate when creationParams change', (
    WidgetTester tester,
  ) async {
    final viewsController = FakeAndroidPlatformViewsController();
    viewsController.registerViewType('webview');

    await tester.pumpWidget(_buildAndroidView('en'));
    final int firstId = viewsController.views.single.id;

    await tester.pumpWidget(_buildAndroidView('zh-Hans'));

    expect(viewsController.views.single.id, firstId);
  });

  testWidgets('UiKitView does not recreate when creationParams change', (
    WidgetTester tester,
  ) async {
    final viewsController = FakeIosPlatformViewsController();
    viewsController.registerViewType('webview');

    await tester.pumpWidget(_buildUiKitView('en'));
    final int firstId = viewsController.views.single.id;

    await tester.pumpWidget(_buildUiKitView('zh-Hans'));

    expect(viewsController.views.single.id, firstId);
  });

  testWidgets('AppKitView does not recreate when creationParams change', (
    WidgetTester tester,
  ) async {
    final viewsController = FakeMacosPlatformViewsController();
    viewsController.registerViewType('webview');

    await tester.pumpWidget(_buildAppKitView('en'));
    final int firstId = viewsController.views.single.id;

    await tester.pumpWidget(_buildAppKitView('zh-Hans'));

    expect(viewsController.views.single.id, firstId);
  });
}

Widget _buildAndroidView(String language) {
  return _host(
    AndroidView(
      viewType: 'webview',
      layoutDirection: TextDirection.ltr,
      creationParams: <String, String>{'language': language},
      creationParamsCodec: const StandardMessageCodec(),
    ),
  );
}

Widget _buildUiKitView(String language) {
  return _host(
    UiKitView(
      viewType: 'webview',
      layoutDirection: TextDirection.ltr,
      creationParams: <String, String>{'language': language},
      creationParamsCodec: const StandardMessageCodec(),
    ),
  );
}

Widget _buildAppKitView(String language) {
  return _host(
    AppKitView(
      viewType: 'webview',
      layoutDirection: TextDirection.ltr,
      creationParams: <String, String>{'language': language},
      creationParamsCodec: const StandardMessageCodec(),
    ),
  );
}

Widget _host(Widget view) {
  return Center(child: SizedBox(width: 200, height: 100, child: view));
}
