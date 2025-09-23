// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/controls.dart';
import 'package:widget_preview_scaffold/src/dtd/editor_service.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';

import 'utils/widget_preview_scaffold_test_utils.dart';

void main() {
  testWidgets('Filter previews based on currently selected file', (
    tester,
  ) async {
    const kScript1 = 'file:///script1.dart';
    const kScript2 = 'file:///script2.dart';

    final FakeWidgetPreviewScaffoldDtdServices dtdServices =
        FakeWidgetPreviewScaffoldDtdServices();
    final previews = <WidgetPreview>[
      WidgetPreview(
        builder: () => Text('widget1'),
        scriptUri: kScript1,
        previewData: Preview(group: 'group'),
        packageName: '',
      ),
      WidgetPreview(
        builder: () => Text('widget2'),
        scriptUri: kScript2,
        previewData: Preview(group: 'group'),
        packageName: '',
      ),
    ];
    final controller = FakeWidgetPreviewScaffoldController(
      dtdServicesOverride: dtdServices,
      previews: previews,
    );
    await controller.initialize();
    final WidgetPreviewScaffold widgetPreview = WidgetPreviewScaffold(
      controller: controller,
    );

    // No file is selected, so all previews should be visible until
    // https://github.com/dart-lang/sdk/issues/61538 is resolved.
    await tester.pumpWidget(widgetPreview);
    expect(controller.filterBySelectedFileListenable.value, true);
    expect(dtdServices.selectedSourceFile.value, isNull);
    expect(controller.filteredPreviewSetListenable.value, hasLength(1));
    expect(
      controller.filteredPreviewSetListenable.value.single.previews,
      hasLength(2),
    );

    // Select kScript1
    dtdServices.selectedSourceFile.value = TextDocument(
      uriAsString: kScript1,
      version: 0,
    );
    await tester.pumpWidget(widgetPreview);

    // Verify only previews from kScript1 are displayed.
    expect(dtdServices.selectedSourceFile.value?.uriAsString, kScript1);
    expect(
      controller
          .filteredPreviewSetListenable
          .value
          .single
          .previews
          .single
          .scriptUri,
      kScript1,
    );

    // Select a 'null' script. This simulates focusing on a non-source file
    // (e.g., the embedded widget previewer).
    dtdServices.selectedSourceFile.value = null;

    // Verify the selected source file is null but previews from kScript1 are
    // still displayed.
    expect(dtdServices.selectedSourceFile.value?.uriAsString, null);
    expect(
      controller
          .filteredPreviewSetListenable
          .value
          .single
          .previews
          .single
          .scriptUri,
      kScript1,
    );

    // Select kScript2
    dtdServices.selectedSourceFile.value = TextDocument(
      uriAsString: kScript2,
      version: 0,
    );
    await tester.pumpWidget(widgetPreview);

    // Verify only previews from kScript2 are displayed.
    expect(dtdServices.selectedSourceFile.value?.uriAsString, kScript2);
    expect(
      controller
          .filteredPreviewSetListenable
          .value
          .single
          .previews
          .single
          .scriptUri,
      kScript2,
    );

    final Finder filterBySelectedFileToggle = find.byType(
      FilterBySelectedFileToggle,
    );

    // Press the "Filter by selected file" button and disable preview filtering.
    expect(controller.filterBySelectedFileListenable.value, true);
    await tester.tap(filterBySelectedFileToggle);
    expect(controller.filterBySelectedFileListenable.value, false);
    // Verify the currently selected source is still kScript2 but all previews are displayed.
    expect(dtdServices.selectedSourceFile.value?.uriAsString, kScript2);
    expect(controller.filteredPreviewSetListenable.value, hasLength(1));
    expect(
      controller.filteredPreviewSetListenable.value.first.previews,
      previews,
    );
  });
}
