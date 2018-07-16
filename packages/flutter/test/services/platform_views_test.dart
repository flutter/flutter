// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:test/test.dart';

import 'fake_platform_views.dart';

void main() {
  FakePlatformViewsController viewsController;

  group('Android', () {
    setUp(() {
      viewsController = new FakePlatformViewsController(TargetPlatform.android);
    });

    test('create Android view of unregistered type', () async {
      expect(
          () => PlatformViewsService.initAndroidView(
              id: 0, viewType: 'web').setSize(const Size(100.0, 100.0)),
          throwsA(const isInstanceOf<PlatformException>()));
    });

    test('create Android views', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview').setSize(const Size(100.0, 100.0));
      await PlatformViewsService.initAndroidView(
          id: 1, viewType: 'webview').setSize(const Size(200.0, 300.0));
      expect(
          viewsController.views,
          unorderedEquals(<FakePlatformView>[
            new FakePlatformView(0, 'webview', const Size(100.0, 100.0)),
            new FakePlatformView(1, 'webview', const Size(200.0, 300.0)),
          ]));
    });

    test('reuse Android view id', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview').setSize(const Size(100.0, 100.0));
      expect(
          () => PlatformViewsService.initAndroidView(
              id: 0, viewType: 'web').setSize(const Size(100.0, 100.0)),
          throwsA(const isInstanceOf<PlatformException>()));
    });

    test('dispose Android view', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview').setSize(const Size(100.0, 100.0));
      final AndroidViewController viewController =
          PlatformViewsService.initAndroidView(id: 1, viewType: 'webview');
      await viewController.setSize(const Size(200.0, 300.0));

      viewController.dispose();
      expect(
          viewsController.views,
          unorderedEquals(<FakePlatformView>[
            new FakePlatformView(0, 'webview', const Size(100.0, 100.0)),
          ]));
    });

    test('dispose inexisting Android view', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview').setSize(const Size(100.0, 100.0));
      final AndroidViewController viewController =
          PlatformViewsService.initAndroidView(id: 1, viewType: 'webview');
      await viewController.setSize(const Size(200.0, 300.0));
      await viewController.dispose();
      await viewController.dispose();
    });

    test('resize Android view', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview').setSize(const Size(100.0, 100.0));
      final AndroidViewController viewController =
          PlatformViewsService.initAndroidView(id: 1, viewType: 'webview');
      await viewController.setSize(const Size(200.0, 300.0));
      await viewController.setSize(const Size(500.0, 500.0));
      expect(
          viewsController.views,
          unorderedEquals(<FakePlatformView>[
            new FakePlatformView(0, 'webview', const Size(100.0, 100.0)),
            new FakePlatformView(1, 'webview', const Size(500.0, 500.0)),
          ]));
    });
  });
}
