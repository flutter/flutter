// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widget_previews.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widget_preview_scaffold/src/controls.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_scaffold_controller.dart';

import 'utils/widget_preview_scaffold_test_utils.dart';

const _testWidths = <double>[250.0, 300.0, 350.0, 400.0, 520.0, 560.0];
const _viewportHeight = 800.0;
const _minSearchFieldWidth = 80.0;
const _testSearchQuery = 'test query';

void _expectValidLayout(List<Rect> rects, double maxWidth) {
  for (final rect in rects) {
    expect(
      rect.left >= 0 && rect.right <= maxWidth,
      isTrue,
      reason: 'Rect $rect exceeds viewport width $maxWidth',
    );
  }
  for (var i = 0; i < rects.length; i++) {
    for (var j = i + 1; j < rects.length; j++) {
      final intersection = rects[i].intersect(rects[j]);
      expect(
        intersection.width <= 0 || intersection.height <= 0,
        isTrue,
        reason: 'Rect ${rects[i]} overlaps with ${rects[j]}',
      );
    }
  }
}

void main() {
  for (final width in _testWidths) {
    testWidgets(
      'WidgetPreviewScaffold toolbar controls do not overflow or overlap at ${width.toInt()}px width with no previews',
      (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, _viewportHeight);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = WidgetPreviewScaffoldController(
          dtdServicesOverride: FakeWidgetPreviewScaffoldDtdServices(),
          previews: () => const <WidgetPreview>[],
        );
        await controller.initialize();

        await tester.pumpWidget(
          TestWidgetPreviewScaffold(controller: controller),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final layoutSelectorFinder = find.byType(LayoutTypeSelector);
        final filterByFileFinder = find.byType(FilterBySelectedFileToggle);
        final searchControlsFinder = find.byType(PreviewSearchControls);
        final inspectorToggleFinder = find.byType(WidgetInspectorToggle);
        final restartButtonFinder = find.byType(WidgetPreviewerRestartButton);

        expect(layoutSelectorFinder, findsOneWidget);
        expect(filterByFileFinder, findsOneWidget);
        expect(searchControlsFinder, findsOneWidget);
        expect(inspectorToggleFinder, findsOneWidget);
        expect(restartButtonFinder, findsOneWidget);

        final controlRects = <Rect>[
          tester.getRect(layoutSelectorFinder),
          tester.getRect(filterByFileFinder),
          tester.getRect(searchControlsFinder),
          tester.getRect(inspectorToggleFinder),
          tester.getRect(restartButtonFinder),
        ];
        _expectValidLayout(controlRects, width);

        // Verify search field and filter menu button inside PreviewSearchControls
        // do not overlap and the search TextField remains usable.
        final textFieldFinder = find.descendant(
          of: searchControlsFinder,
          matching: find.byType(TextField),
        );
        final searchIconFinder = find.descendant(
          of: searchControlsFinder,
          matching: find.byIcon(Icons.search),
        );
        final filterButtonFinder = find.descendant(
          of: searchControlsFinder,
          matching: find.byTooltip('Search fields'),
        );

        expect(textFieldFinder, findsOneWidget);
        expect(searchIconFinder, findsOneWidget);
        expect(filterButtonFinder, findsOneWidget);

        final textFieldRect = tester.getRect(textFieldFinder);
        expect(textFieldRect.width, greaterThanOrEqualTo(_minSearchFieldWidth));
        _expectValidLayout(<Rect>[
          textFieldRect,
          tester.getRect(filterButtonFinder),
        ], width);

        await tester.enterText(textFieldFinder, _testSearchQuery);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(controller.searchQueryListenable.value, _testSearchQuery);

        final clearButtonFinder = find.descendant(
          of: searchControlsFinder,
          matching: find.byTooltip('Clear search'),
        );
        expect(clearButtonFinder, findsOneWidget);
        _expectValidLayout(<Rect>[
          tester.getRect(searchIconFinder),
          tester.getRect(clearButtonFinder),
          tester.getRect(filterButtonFinder),
        ], width);
      },
    );

    testWidgets(
      'WidgetPreviewScaffold preview controls do not overflow or overlap at ${width.toInt()}px width with previews',
      (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, _viewportHeight);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = WidgetPreviewScaffoldController(
          dtdServicesOverride: FakeWidgetPreviewScaffoldDtdServices(),
          previews: () => <WidgetPreview>[
            WidgetPreview.test(
              builder: () => const Text('Preview content'),
              previewData: const Preview(name: 'Sample Preview'),
            ),
          ],
        );
        await controller.initialize();
        if (controller.filterBySelectedFileListenable.value) {
          await controller.toggleFilterBySelectedFile();
        }

        await tester.pumpWidget(
          TestWidgetPreviewScaffold(controller: controller),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final zoomControlsFinder = find.byType(ZoomControls);
        final brightnessToggleFinder = find.byType(BrightnessToggleButton);
        final softRestartFinder = find.byType(SoftRestartButton);

        expect(zoomControlsFinder, findsOneWidget);
        expect(brightnessToggleFinder, findsOneWidget);
        expect(softRestartFinder, findsOneWidget);

        _expectValidLayout(<Rect>[
          tester.getRect(zoomControlsFinder),
          tester.getRect(brightnessToggleFinder),
          tester.getRect(softRestartFinder),
        ], width);
      },
    );
  }
}
