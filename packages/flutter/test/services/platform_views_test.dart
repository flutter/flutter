// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import '../flutter_test_alternative.dart';

import 'fake_platform_views.dart';

void main() {

  group('Android', () {
    FakeAndroidPlatformViewsController viewsController;
    setUp(() {
      viewsController = FakeAndroidPlatformViewsController();
    });

    test('create Android view of unregistered type', () async {
      expect(
        () {
          return PlatformViewsService.initAndroidView(
            id: 0,
            viewType: 'web',
            layoutDirection: TextDirection.ltr,
          ).setSize(const Size(100.0, 100.0));
        },
        throwsA(isInstanceOf<PlatformException>()),
      );
    });

    test('create Android views', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(id: 0, viewType: 'webview', layoutDirection: TextDirection.ltr)
          .setSize(const Size(100.0, 100.0));
      await PlatformViewsService.initAndroidView( id: 1, viewType: 'webview', layoutDirection: TextDirection.rtl)
          .setSize(const Size(200.0, 300.0));
      expect(
          viewsController.views,
          unorderedEquals(<FakeAndroidPlatformView>[
            FakeAndroidPlatformView(0, 'webview', const Size(100.0, 100.0), AndroidViewController.kAndroidLayoutDirectionLtr),
            FakeAndroidPlatformView(1, 'webview', const Size(200.0, 300.0), AndroidViewController.kAndroidLayoutDirectionRtl),
          ]));
    });

    test('reuse Android view id', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      ).setSize(const Size(100.0, 100.0));
      expect(
          () => PlatformViewsService.initAndroidView(
              id: 0, viewType: 'web', layoutDirection: TextDirection.ltr).setSize(const Size(100.0, 100.0)),
          throwsA(isInstanceOf<PlatformException>()));
    });

    test('dispose Android view', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview', layoutDirection: TextDirection.ltr).setSize(const Size(100.0, 100.0));
      final AndroidViewController viewController =
          PlatformViewsService.initAndroidView(id: 1, viewType: 'webview', layoutDirection: TextDirection.ltr);
      await viewController.setSize(const Size(200.0, 300.0));

      await viewController.dispose();
      expect(
          viewsController.views,
          unorderedEquals(<FakeAndroidPlatformView>[
            FakeAndroidPlatformView(0, 'webview', const Size(100.0, 100.0), AndroidViewController.kAndroidLayoutDirectionLtr),
          ]));
    });

    test('dispose inexisting Android view', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview', layoutDirection: TextDirection.ltr).setSize(const Size(100.0, 100.0));
      final AndroidViewController viewController =
          PlatformViewsService.initAndroidView(id: 1, viewType: 'webview', layoutDirection: TextDirection.ltr);
      await viewController.setSize(const Size(200.0, 300.0));
      await viewController.dispose();
      await viewController.dispose();
    });

    test('resize Android view', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview', layoutDirection: TextDirection.ltr).setSize(const Size(100.0, 100.0));
      final AndroidViewController viewController =
          PlatformViewsService.initAndroidView(id: 1, viewType: 'webview', layoutDirection: TextDirection.ltr);
      await viewController.setSize(const Size(200.0, 300.0));
      await viewController.setSize(const Size(500.0, 500.0));
      expect(
          viewsController.views,
          unorderedEquals(<FakeAndroidPlatformView>[
            FakeAndroidPlatformView(0, 'webview', const Size(100.0, 100.0), AndroidViewController.kAndroidLayoutDirectionLtr),
            FakeAndroidPlatformView(1, 'webview', const Size(500.0, 500.0), AndroidViewController.kAndroidLayoutDirectionLtr),
          ]));
    });

    test('OnPlatformViewCreated callback', () async {
      viewsController.registerViewType('webview');
      final List<int> createdViews = <int>[];
      final PlatformViewCreatedCallback callback = (int id) { createdViews.add(id); };

      final AndroidViewController controller1 = PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview', layoutDirection: TextDirection.ltr, onPlatformViewCreated:  callback);
      expect(createdViews, isEmpty);

      await controller1.setSize(const Size(100.0, 100.0));
      expect(createdViews, orderedEquals(<int>[0]));

      final AndroidViewController controller2 = PlatformViewsService.initAndroidView(
          id: 5, viewType: 'webview', layoutDirection: TextDirection.ltr, onPlatformViewCreated:  callback);
      expect(createdViews, orderedEquals(<int>[0]));

      await controller2.setSize(const Size(100.0, 200.0));
      expect(createdViews, orderedEquals(<int>[0, 5]));

    });

    test('change Android view\'s directionality before creation', () async {
      viewsController.registerViewType('webview');
      final AndroidViewController viewController =
      PlatformViewsService.initAndroidView(id: 0, viewType: 'webview', layoutDirection: TextDirection.rtl);
      await viewController.setLayoutDirection(TextDirection.ltr);
      await viewController.setSize(const Size(100.0, 100.0));
      expect(
          viewsController.views,
          unorderedEquals(<FakeAndroidPlatformView>[
            FakeAndroidPlatformView(0, 'webview', const Size(100.0, 100.0), AndroidViewController.kAndroidLayoutDirectionLtr),
          ]));
    });

    test('change Android view\'s directionality after creation', () async {
      viewsController.registerViewType('webview');
      final AndroidViewController viewController =
      PlatformViewsService.initAndroidView(id: 0, viewType: 'webview', layoutDirection: TextDirection.ltr);
      await viewController.setSize(const Size(100.0, 100.0));
      await viewController.setLayoutDirection(TextDirection.rtl);
      expect(
          viewsController.views,
          unorderedEquals(<FakeAndroidPlatformView>[
            FakeAndroidPlatformView(0, 'webview', const Size(100.0, 100.0), AndroidViewController.kAndroidLayoutDirectionRtl),
          ]));
    });
  });

  group('iOS', ()
  {
    FakeIosPlatformViewsController viewsController;
    setUp(() {
      viewsController = FakeIosPlatformViewsController();
    });

    test('create iOS view of unregistered type', () async {
      expect(
            () {
          return PlatformViewsService.initUiKitView(
            id: 0,
            viewType: 'web',
            layoutDirection: TextDirection.ltr,
          );
        },
        throwsA(isInstanceOf<PlatformException>()),
      );
    });

    test('create iOS views', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initUiKitView(
          id: 0, viewType: 'webview', layoutDirection: TextDirection.ltr);
      await PlatformViewsService.initUiKitView(
          id: 1, viewType: 'webview', layoutDirection: TextDirection.rtl);
      expect(
        viewsController.views,
        unorderedEquals(<FakeUiKitView>[
          FakeUiKitView(0, 'webview'),
          FakeUiKitView(1, 'webview'),
        ]),
      );
    });

    test('reuse iOS view id', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initUiKitView(
        id: 0,
        viewType: 'webview',
        layoutDirection: TextDirection.ltr,
      );
      expect(
            () => PlatformViewsService.initUiKitView(
            id: 0, viewType: 'web', layoutDirection: TextDirection.ltr),
        throwsA(isInstanceOf<PlatformException>()),
      );
    });

    test('dispose iOS view', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initUiKitView(
          id: 0, viewType: 'webview', layoutDirection: TextDirection.ltr);
      final UiKitViewController viewController = await PlatformViewsService.initUiKitView(
          id: 1, viewType: 'webview', layoutDirection: TextDirection.ltr);

      viewController.dispose();
      expect(
          viewsController.views,
          unorderedEquals(<FakeUiKitView>[
            FakeUiKitView(0, 'webview'),
          ]));
    });

    test('dispose inexisting iOS view', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initUiKitView(id: 0, viewType: 'webview', layoutDirection: TextDirection.ltr);
      final UiKitViewController viewController = await PlatformViewsService.initUiKitView(
          id: 1, viewType: 'webview', layoutDirection: TextDirection.ltr);
      await viewController.dispose();
      expect(
          () async {
            await viewController.dispose();
          },
          throwsA(isInstanceOf<PlatformException>()),
      );
    });
  });
}
