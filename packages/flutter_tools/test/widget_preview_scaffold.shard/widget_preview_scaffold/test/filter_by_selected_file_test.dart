// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:widget_preview_scaffold/src/controls.dart';
import 'package:widget_preview_scaffold/src/dtd/editor_service.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';
import 'package:widget_preview_scaffold/src/widget_preview_scaffold_controller.dart';

import 'utils/widget_preview_scaffold_test_utils.dart';

Future<void> testImpl({
  required WidgetTester tester,
  required Uri script1Uri,
  required Uri script2Uri,
  required String textEditorScript1Uri,
  required String textEditorScript2Uri,
  required bool isWindows,
}) async {
  // Use a Context to handle platform-specific strangeness around paths.
  final context = path.Context(
    style: isWindows ? path.Style.windows : path.Style.posix,
  );
  final dtdServices = FakeWidgetPreviewScaffoldDtdServices(
    isWindows: isWindows,
  );
  final previews = <WidgetPreview>[
    WidgetPreview.test(
      builder: () => Text('widget1'),
      scriptUri: script1Uri.toString(),
      previewData: Preview(group: 'group'),
    ),
    WidgetPreview.test(
      builder: () => Text('widget2'),
      scriptUri: script2Uri.toString(),
      previewData: Preview(group: 'group'),
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

  // No file is selected, so no previews should be visible.
  await tester.pumpWidget(widgetPreview);
  expect(controller.filterBySelectedFileListenable.value, true);
  expect(dtdServices.selectedSourceFile.value, isNull);
  expect(controller.filteredPreviewSetListenable.value, isEmpty);

  // Select textEditorScript1Uri
  dtdServices.selectedSourceFile.value = TextDocument(
    uriAsString: textEditorScript1Uri,
    version: 0,
  );
  await tester.pumpWidget(widgetPreview);

  // Verify only previews from script1Uri are displayed.
  expect(
    context.equals(
      context.fromUri(dtdServices.selectedSourceFile.value!.uriAsString),
      context.fromUri(script1Uri),
    ),
    true,
  );
  expect(
    controller
        .filteredPreviewSetListenable
        .value
        .single
        .previews
        .single
        .scriptUri,
    script1Uri.toString(),
  );

  // Select a 'null' script. This simulates focusing on a non-source file
  // (e.g., the embedded widget previewer).
  dtdServices.selectedSourceFile.value = null;

  // Verify the selected source file is null but previews from script1Uri are
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
    script1Uri.toString(),
  );

  // Select textEditorScript2Uri
  dtdServices.selectedSourceFile.value = TextDocument(
    uriAsString: textEditorScript2Uri,
    version: 0,
  );
  await tester.pumpWidget(widgetPreview);

  // Verify only previews from script2Uri are displayed.
  expect(
    context.equals(
      context.fromUri(dtdServices.selectedSourceFile.value!.uriAsString),
      context.fromUri(script2Uri),
    ),
    true,
  );
  expect(
    controller
        .filteredPreviewSetListenable
        .value
        .single
        .previews
        .single
        .scriptUri,
    script2Uri.toString(),
  );

  final Finder filterBySelectedFileToggle = find.byType(
    FilterBySelectedFileToggle,
  );

  // Press the "Filter by selected file" button and disable preview filtering.
  expect(controller.filterBySelectedFileListenable.value, true);
  await tester.tap(filterBySelectedFileToggle);
  expect(controller.filterBySelectedFileListenable.value, false);
  // Verify the currently selected source is still script2Uri but all previews are displayed.
  expect(
    context.equals(
      context.fromUri(dtdServices.selectedSourceFile.value!.uriAsString),
      context.fromUri(script2Uri),
    ),
    true,
  );
  expect(controller.filteredPreviewSetListenable.value, hasLength(1));
  expect(
    controller.filteredPreviewSetListenable.value.single.previews,
    previews,
  );
}

void main() {
  testWidgets('Filter previews based on currently selected file (POSIX)', (
    tester,
  ) async {
    final kScript1 = Uri.parse('file:///script1');
    final kScript2 = Uri.parse('file:///script2');
    await testImpl(
      tester: tester,
      script1Uri: kScript1,
      script2Uri: kScript2,
      textEditorScript1Uri: kScript1.toString(),
      textEditorScript2Uri: kScript2.toString(),
      isWindows: false,
    );
  });

  testWidgets('Filter previews based on currently selected file (Windows)', (
    tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/175524
    final kScript1 = Uri.parse('file:///c:/script1');
    final kScript2 = Uri.parse('file:///C:/script2');
    const kTextEditorScript1 = 'file:///C%3A/script1';
    const kTextEditorScript2 = 'file:///c%3A/script2';
    await testImpl(
      tester: tester,
      script1Uri: kScript1,
      script2Uri: kScript2,
      textEditorScript1Uri: kTextEditorScript1,
      textEditorScript2Uri: kTextEditorScript2,
      isWindows: true,
    );
  });

  testWidgets('Filter previews is responsive to Editor service availability', (
    tester,
  ) async {
    final dtdServices = FakeWidgetPreviewScaffoldDtdServices();
    final previews = <WidgetPreview>[
      WidgetPreview.test(
        builder: () => Text('widget1'),
        previewData: Preview(group: 'group'),
      ),
      WidgetPreview.test(
        builder: () => Text('widget2'),
        previewData: Preview(group: 'group'),
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
    // Disable the Editor service to mimic a preview session not managed by an IDE.
    dtdServices.editorServiceAvailable.value = false;

    // The Editor service isn't available, so the filter by selected file toggle should not be
    // shown and all previews should be rendered.
    await tester.pumpWidget(widgetPreview);
    final Finder filterBySelectedFileToggle = find.byTooltip(
      FilterBySelectedFileToggle.kTooltip,
    );
    expect(filterBySelectedFileToggle, findsNothing);
    expect(controller.filteredPreviewSetListenable.value, hasLength(1));
    expect(
      controller.filteredPreviewSetListenable.value.first.previews,
      previews,
    );

    // Mimic an IDE registering the Editor service after the previewer starts.
    dtdServices.editorServiceAvailable.value = true;

    // The Editor service is available, so the filter by selected file toggle should be shown.
    await tester.pumpWidget(widgetPreview);
    expect(filterBySelectedFileToggle, findsOne);

    // No file is selected, so no previews should be visible.
    await tester.pumpWidget(widgetPreview);
    expect(controller.filterBySelectedFileListenable.value, true);
    expect(dtdServices.selectedSourceFile.value, isNull);
    expect(controller.filteredPreviewSetListenable.value, isEmpty);
  });

  testWidgets('Filter by selected file preference is persisted', (
    tester,
  ) async {
    final dtdServices = FakeWidgetPreviewScaffoldDtdServices();

    bool? getFilterBySelectedFileValue() =>
        dtdServices.preferences[WidgetPreviewScaffoldController
                .kFilterBySelectedFilePreference]
            as bool?;

    // Validate setting isn't set in preferences yet.
    expect(getFilterBySelectedFileValue(), null);

    final controller = FakeWidgetPreviewScaffoldController(
      dtdServicesOverride: dtdServices,
    );
    await controller.initialize();
    expect(controller.filterBySelectedFileListenable.value, true);
    // Still null as we've just used the default value and haven't actually
    // written to the preferences.
    expect(getFilterBySelectedFileValue(), null);

    // Toggle the setting, which will cause it to be written to the preferences.
    await controller.toggleFilterBySelectedFile();
    expect(controller.filterBySelectedFileListenable.value, false);
    expect(getFilterBySelectedFileValue(), false);

    await controller.toggleFilterBySelectedFile();
    expect(controller.filterBySelectedFileListenable.value, true);
    expect(getFilterBySelectedFileValue(), true);
  });
}
