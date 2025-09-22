// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/controls.dart';
import 'package:widget_preview_scaffold/src/dtd/editor_service.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';

import 'utils/widget_preview_scaffold_test_utils.dart';

Future<void> testImpl({
  required WidgetTester tester,
  required String script1Uri,
  required String script2Uri,
  required String textEditorScript1Uri,
  required String textEditorScript2Uri,
}) async {
  final FakeWidgetPreviewScaffoldDtdServices dtdServices =
      FakeWidgetPreviewScaffoldDtdServices();
  final groups = <WidgetPreviewGroup>[
    WidgetPreviewGroup(
      name: 'group',
      previews: <WidgetPreview>[
        WidgetPreview(builder: () => Text('widget1'), scriptUri: script1Uri),
        WidgetPreview(builder: () => Text('widget2'), scriptUri: script2Uri),
      ],
    ),
  ];
  final controller = FakeWidgetPreviewScaffoldController(
    dtdServicesOverride: dtdServices,
    previews: groups,
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
  expect(controller.filteredPreviewSetListenable.value, groups);
  expect(
    controller.filteredPreviewSetListenable.value.single.previews,
    hasLength(2),
  );

  // Select textEditorScript1Uri
  dtdServices.selectedSourceFile.value = TextDocument(
    uriAsString: textEditorScript1Uri,
    version: 0,
  );
  await tester.pumpWidget(widgetPreview);

  // Verify only previews from script1Uri are displayed.
  expect(dtdServices.selectedSourceFile.value?.uriAsString, script1Uri);
  expect(
    controller
        .filteredPreviewSetListenable
        .value
        .single
        .previews
        .single
        .scriptUri,
    script1Uri,
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
    script1Uri,
  );

  // Select textEditorScript2Uri
  dtdServices.selectedSourceFile.value = TextDocument(
    uriAsString: textEditorScript2Uri,
    version: 0,
  );
  await tester.pumpWidget(widgetPreview);

  // Verify only previews from script2Uri are displayed.
  expect(dtdServices.selectedSourceFile.value?.uriAsString, script2Uri);
  expect(
    controller
        .filteredPreviewSetListenable
        .value
        .single
        .previews
        .single
        .scriptUri,
    script2Uri,
  );

  final Finder filterBySelectedFileToggle = find.byType(
    FilterBySelectedFileToggle,
  );

  // Press the "Filter by selected file" button and disable preview filtering.
  expect(controller.filterBySelectedFileListenable.value, true);
  await tester.tap(filterBySelectedFileToggle);
  expect(controller.filterBySelectedFileListenable.value, false);
  // Verify the currently selected source is still script2Uri but all previews are displayed.
  expect(dtdServices.selectedSourceFile.value?.uriAsString, script2Uri);
  expect(controller.filteredPreviewSetListenable.value, groups);
}

void main() {
  testWidgets('Filter previews based on currently selected file (POSIX)', (
    tester,
  ) async {
    const kScript1 = 'file:///script1';
    const kScript2 = 'file:///script2';
    await testImpl(
      tester: tester,
      script1Uri: kScript1,
      script2Uri: kScript2,
      textEditorScript1Uri: kScript1,
      textEditorScript2Uri: kScript2,
    );
  });
  testWidgets('Filter previews based on currently selected file (Windows)', (
    tester,
  ) async {
    const kScript1 = 'file:///C:/script1';
    const kScript2 = 'file:///C:/script2';
    final kTextEditorScript1 = 'file:///C%3A/script1';
    final kTextEditorScript2 = Uri.encodeFull(kScript2);
    print(kTextEditorScript1);
    await testImpl(
      tester: tester,
      script1Uri: kScript1,
      script2Uri: kScript2,
      textEditorScript1Uri: kTextEditorScript1,
      textEditorScript2Uri: kTextEditorScript2,
    );
  });
}
