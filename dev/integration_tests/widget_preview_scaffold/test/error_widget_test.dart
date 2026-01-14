// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';
import 'package:widget_preview_scaffold/src/widget_preview_scaffold_controller.dart';

import 'utils/widget_preview_scaffold_test_utils.dart';

/// Looks for the first [TextSpan] in [selectableText] that contains [text] and
/// taps it if it has a gesture recognizer set.
bool tryTapFirstSpanContaining(SelectableText selectableText, String text) {
  final textSpan = selectableText.textSpan;
  if (textSpan == null) {
    return false;
  }
  return !textSpan.visitChildren((v) {
    if (v is! TextSpan) {
      return true;
    }
    if (v.text?.contains(text) ?? false) {
      final recognizer = v.recognizer;
      if (recognizer != null && recognizer is TapGestureRecognizer) {
        recognizer.onTap?.call();
      }
      return false;
    }
    return true;
  });
}

void main() {
  testWidgets('$WidgetPreviewErrorWidget handles navigation to sources', (
    tester,
  ) async {
    final fakeDtdServices = FakeWidgetPreviewScaffoldDtdServices();
    final controller = WidgetPreviewScaffoldController(
      dtdServicesOverride: fakeDtdServices,
      previews: () => [
        WidgetPreview.test(
          builder: () => throw Exception('Error!'),
          previewData: Preview(),
        ),
      ],
    );

    if (controller.filterBySelectedFileListenable.value) {
      // Disable filter by selected file.
      await controller.toggleFilterBySelectedFile();
    }
    await controller.initialize();

    await tester.pumpWidget(TestWidgetPreviewScaffold(controller: controller));

    // Ensure the WidgetPreviewErrorWidget exists.
    final errorWidgetFinder = find.byType(WidgetPreviewErrorWidget);
    expect(errorWidgetFinder, findsOne);

    final findAndTapErrorWidgetTest = find.byWidgetPredicate(
      (widget) =>
          widget is SelectableText &&
          tryTapFirstSpanContaining(widget, 'test/error_widget_test.dart'),
    );

    final findAndTapDartCoreLibrary = find.byWidgetPredicate(
      (widget) =>
          widget is SelectableText &&
          tryTapFirstSpanContaining(widget, 'dart:'),
    );

    final findAndTapPackageUri = find.byWidgetPredicate(
      (widget) =>
          widget is SelectableText &&
          tryTapFirstSpanContaining(widget, 'package:'),
    );

    // Frame entries for both test/error_widget_test.dart and dart: should be
    // found.
    expect(findAndTapErrorWidgetTest, findsOne);
    expect(findAndTapDartCoreLibrary, findsOne);
    expect(findAndTapPackageUri, findsOne);

    // Ensure the `navigateToCode` call has a chance to run.
    await Future.microtask(() {});

    // dart:* frames shouldn't have tap handlers installed as it's not possible
    // to navigate to dart:* sources.
    expect(fakeDtdServices.navigationEvents, hasLength(2));
    expect(
      fakeDtdServices.navigationEvents[0].uri,
      endsWith('test/error_widget_test.dart'),
    );
    expect(fakeDtdServices.navigationEvents[1].uri, startsWith('package:'));

    // Mimic having no IDE connection.
    fakeDtdServices.editorServiceAvailable.value = false;
    fakeDtdServices.navigationEvents.clear();

    await tester.pumpWidget(TestWidgetPreviewScaffold(controller: controller));

    // Frame entries for both test/error_widget_test.dart and dart: should
    // still be found.
    expect(findAndTapErrorWidgetTest, findsOne);
    expect(findAndTapDartCoreLibrary, findsOne);
    expect(findAndTapPackageUri, findsOne);

    // Ensure any possible `navigateToCode` call has a chance to run.
    await Future.microtask(() {});

    // Since there's no Editor service, no navigation events should have
    // occurred.
    expect(fakeDtdServices.navigationEvents, isEmpty);
  });
}
