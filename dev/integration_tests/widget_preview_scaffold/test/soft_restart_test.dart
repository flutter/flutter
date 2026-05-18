// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/controls.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart'
    hide PreviewWidget;

import 'utils/widget_preview_scaffold_test_utils.dart';

void main() {
  testWidgets(
    'Soft restart removes and re-inserts previewed widget into the widget tree',
    (tester) async {
      const String kTestText = 'Foo';
      final controller = FakeWidgetPreviewScaffoldController();
      final widgetPreview = WidgetPreviewerWidgetScaffolding(
        child: WidgetPreviewWidget(
          controller: controller,
          preview: WidgetPreview.test(
            builder: () => const Text(kTestText),
            previewData: Preview(),
          ),
        ),
      );

      await tester.pumpWidget(widgetPreview);
      final Finder softRestartButton = find.byType(SoftRestartButton);
      final WidgetPreviewWidgetState state = tester
          .state<WidgetPreviewWidgetState>(find.byWidget(widgetPreview.child));

      bool removedFromTree = false;
      final Completer<void> completer = Completer<void>();
      state.softRestartListenable.addListener(() {
        if (state.softRestartListenable.value) {
          expect(removedFromTree, false);
          removedFromTree = true;
        } else {
          expect(removedFromTree, true);
          completer.complete();
        }
      });

      // Start with the widget in the tree.
      expect(removedFromTree, false);
      final Size originalSize = state.lastChildSize;
      final Finder fooTextFinder = find.text(kTestText);
      expect(fooTextFinder, findsOne);

      // Perform a "soft" restart and render a single frame.
      await tester.tap(softRestartButton);
      await tester.pump();

      // The previewed widget should be replaced by a SizedBox of the same size for a single frame.
      final Finder placeholderBoxFinder = find.byWidgetPredicate(
        (Widget widget) =>
            widget is SizedBox &&
            widget.height == originalSize.height &&
            widget.width == originalSize.width,
      );
      expect(placeholderBoxFinder, findsOne);
      expect(fooTextFinder, findsNothing);
      expect(removedFromTree, true);

      // Render another frame and verify the previewed widget is added back to the tree.
      await tester.pump();
      expect(placeholderBoxFinder, findsNothing);
      expect(fooTextFinder, findsOne);

      await completer.future;
    },
  );
}
