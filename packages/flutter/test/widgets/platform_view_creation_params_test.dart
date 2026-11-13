// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('!chrome')
library;

import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../services/fake_platform_views.dart';

void main() {
  group('creationParams rebuild', () {
    testWidgets('AndroidView keeps the view when map contents are unchanged', (
      WidgetTester tester,
    ) async {
      final FakeAndroidPlatformViewsController viewsController =
          FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');
      final _MarkerHost host = _MarkerHost(platform: _Platform.android);

      await tester.pumpWidget(host);
      final int firstId = viewsController.views.single.id;

      host.rebuildSame();
      await tester.pump();

      expect(viewsController.views.map((FakeAndroidPlatformView view) => view.id), <int>[firstId]);
    });

    testWidgets('AndroidView recreates the view when creationParams change', (
      WidgetTester tester,
    ) async {
      final FakeAndroidPlatformViewsController viewsController =
          FakeAndroidPlatformViewsController();
      viewsController.registerViewType('webview');
      final _MarkerHost host = _MarkerHost(platform: _Platform.android);

      await tester.pumpWidget(host);
      final int firstId = viewsController.views.single.id;

      host.marker = 'zh-Hans';
      await tester.pump();

      expect(viewsController.views, hasLength(1));
      expect(viewsController.views.single.id, isNot(firstId));
      expect(_decoded(viewsController.views.single.creationParams), <String, dynamic>{
        'marker': 'zh-Hans',
      });
    });

    testWidgets('UiKitView recreates the view when creationParams change', (
      WidgetTester tester,
    ) async {
      final FakeIosPlatformViewsController viewsController = FakeIosPlatformViewsController();
      viewsController.registerViewType('webview');
      final _MarkerHost host = _MarkerHost(platform: _Platform.ios);

      await tester.pumpWidget(host);
      final int firstId = viewsController.views.single.id;

      host.rebuildSame();
      await tester.pump();
      expect(viewsController.views.single.id, firstId);

      host.marker = 'zh-Hans';
      await tester.pump();

      expect(viewsController.views, hasLength(1));
      expect(viewsController.views.single.id, isNot(firstId));
      expect(_decoded(viewsController.views.single.creationParams), <String, dynamic>{
        'marker': 'zh-Hans',
      });
    });

    testWidgets('AppKitView recreates the view when creationParams change', (
      WidgetTester tester,
    ) async {
      final FakeMacosPlatformViewsController viewsController = FakeMacosPlatformViewsController();
      viewsController.registerViewType('webview');
      final _MarkerHost host = _MarkerHost(platform: _Platform.macos);

      await tester.pumpWidget(host);
      final int firstId = viewsController.views.single.id;

      host.rebuildSame();
      await tester.pump();
      expect(viewsController.views.single.id, firstId);

      host.marker = 'zh-Hans';
      await tester.pump();

      expect(viewsController.views, hasLength(1));
      expect(viewsController.views.single.id, isNot(firstId));
      expect(_decoded(viewsController.views.single.creationParams), <String, dynamic>{
        'marker': 'zh-Hans',
      });
    });
  });
}

enum _Platform { android, ios, macos }

class _MarkerHost extends StatefulWidget {
  _MarkerHost({required this.platform});

  final _Platform platform;
  late final _MarkerHostState state;

  @override
  State<_MarkerHost> createState() {
    state = _MarkerHostState();
    return state;
  }

  void rebuildSame() => state.rebuildSame();

  set marker(String value) => state.setMarker(value);
}

class _MarkerHostState extends State<_MarkerHost> {
  String _marker = 'en';

  void rebuildSame() {
    setState(() {});
  }

  void setMarker(String value) {
    setState(() {
      _marker = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> params = <String, String>{'marker': _marker};
    const StandardMessageCodec codec = StandardMessageCodec();
    final Widget view;
    switch (widget.platform) {
      case _Platform.android:
        view = AndroidView(
          viewType: 'webview',
          layoutDirection: TextDirection.ltr,
          creationParams: params,
          creationParamsCodec: codec,
        );
      case _Platform.ios:
        view = UiKitView(
          viewType: 'webview',
          layoutDirection: TextDirection.ltr,
          creationParams: params,
          creationParamsCodec: codec,
        );
      case _Platform.macos:
        view = AppKitView(
          viewType: 'webview',
          layoutDirection: TextDirection.ltr,
          creationParams: params,
          creationParamsCodec: codec,
        );
    }
    return Center(child: SizedBox(width: 200, height: 100, child: view));
  }
}

Map<Object?, Object?> _decoded(Uint8List? bytes) {
  final ByteData data = ByteData.view(bytes!.buffer, bytes.offsetInBytes, bytes.lengthInBytes);
  return StandardMessageCodec().decodeMessage(data)! as Map<Object?, Object?>;
}
