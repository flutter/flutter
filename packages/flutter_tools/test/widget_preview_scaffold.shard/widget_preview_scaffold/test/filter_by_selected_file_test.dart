// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:widget_preview_scaffold/src/controls.dart';
import 'package:widget_preview_scaffold/src/dtd/editor_service.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';

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
  final groups = <WidgetPreviewGroup>[
    WidgetPreviewGroup(
      name: 'group',
      previews: <WidgetPreview>[
        WidgetPreview(
          builder: () => Text('widget1'),
          scriptUri: script1Uri.toString(),
        ),
        WidgetPreview(
          builder: () => Text('widget2'),
          scriptUri: script2Uri.toString(),
        ),
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
    isWindows: isWindows,
  );
  await tester.pumpWidget(widgetPreview);

  // Verify only previews from script1Uri are displayed.
  expect(
    context.equals(
      dtdServices.selectedSourceFile.value!.uriAsString,
      script1Uri.toFilePath(windows: isWindows),
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
    isWindows: isWindows,
  );
  await tester.pumpWidget(widgetPreview);

  // Verify only previews from script2Uri are displayed.
  expect(
    context.equals(
      dtdServices.selectedSourceFile.value!.uriAsString,
      script2Uri.toFilePath(windows: isWindows),
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
      dtdServices.selectedSourceFile.value!.uriAsString,
      script2Uri.toFilePath(windows: isWindows),
    ),
    true,
  );
  expect(controller.filteredPreviewSetListenable.value, groups);
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
}
