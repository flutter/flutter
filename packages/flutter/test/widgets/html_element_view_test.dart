// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

@TestOn('chrome')

import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../services/fake_platform_views.dart';

void main() {
  group('HtmlElementView', () {
    testWidgets('Create HTML view', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeHtmlPlatformViewsController viewsController = FakeHtmlPlatformViewsController();
      viewsController.registerViewType('webview');

      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: HtmlElementView(viewType: 'webview'),
          ),
        ),
      );

      expect(
        viewsController.views,
        unorderedEquals(<FakeHtmlPlatformView>[
          FakeHtmlPlatformView(currentViewId + 1, 'webview'),
        ]),
      );
    });

    testWidgets('Resize HTML view', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeHtmlPlatformViewsController viewsController = FakeHtmlPlatformViewsController();
      viewsController.registerViewType('webview');
      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: HtmlElementView(viewType: 'webview'),
          ),
        ),
      );

      viewsController.resizeCompleter = Completer<void>();

      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 100.0,
            height: 50.0,
            child: HtmlElementView(viewType: 'webview'),
          ),
        ),
      );

      viewsController.resizeCompleter.complete();
      await tester.pump();

      expect(
        viewsController.views,
        unorderedEquals(<FakeHtmlPlatformView>[
          FakeHtmlPlatformView(currentViewId + 1, 'webview'),
        ]),
      );
    });

    testWidgets('Change HTML view type', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeHtmlPlatformViewsController viewsController = FakeHtmlPlatformViewsController();
      viewsController.registerViewType('webview');
      viewsController.registerViewType('maps');
      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: HtmlElementView(viewType: 'webview'),
          ),
        ),
      );

      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: HtmlElementView(viewType: 'maps'),
          ),
        ),
      );

      expect(
        viewsController.views,
        unorderedEquals(<FakeHtmlPlatformView>[
          FakeHtmlPlatformView(currentViewId + 2, 'maps'),
        ]),
      );
    });

    testWidgets('Dispose HTML view', (WidgetTester tester) async {
      final FakeHtmlPlatformViewsController viewsController = FakeHtmlPlatformViewsController();
      viewsController.registerViewType('webview');
      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: HtmlElementView(viewType: 'webview'),
          ),
        ),
      );

      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
          ),
        ),
      );

      expect(
        viewsController.views,
        isEmpty,
      );
    });

    testWidgets('HTML view survives widget tree change', (WidgetTester tester) async {
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      final FakeHtmlPlatformViewsController viewsController = FakeHtmlPlatformViewsController();
      viewsController.registerViewType('webview');
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200.0,
            height: 100.0,
            child: HtmlElementView(viewType: 'webview', key: key),
          ),
        ),
      );

      await tester.pumpWidget(
        Center(
          child: Container(
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: HtmlElementView(viewType: 'webview', key: key),
            ),
          ),
        ),
      );

      expect(
        viewsController.views,
        unorderedEquals(<FakeHtmlPlatformView>[
          FakeHtmlPlatformView(currentViewId + 1, 'webview'),
        ]),
      );
    });

    testWidgets('HtmlElementView has correct semantics', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final int currentViewId = platformViewsRegistry.getNextPlatformViewId();
      expect(currentViewId, greaterThanOrEqualTo(0));
      final FakeHtmlPlatformViewsController viewsController = FakeHtmlPlatformViewsController();
      viewsController.registerViewType('webview');

      await tester.pumpWidget(
        Semantics(
          container: true,
          child: const Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: HtmlElementView(
                viewType: 'webview',
              ),
            ),
          ),
        ),
      );
      // First frame is before the platform view was created so the render object
      // is not yet in the tree.
      await tester.pump();

      // The platform view ID is set on the child of the HtmlElementView render object.
      final SemanticsNode semantics = tester.getSemantics(find.byType(PlatformViewSurface));

      expect(semantics.platformViewId, currentViewId + 1);
      expect(semantics.rect, const Rect.fromLTWH(0, 0, 200, 100));
      // A 200x100 rect positioned at bottom right of a 800x600 box.
      expect(semantics.transform, Matrix4.translationValues(600, 500, 0));
      expect(semantics.childrenCount, 0);

      handle.dispose();
    });
  });
}
