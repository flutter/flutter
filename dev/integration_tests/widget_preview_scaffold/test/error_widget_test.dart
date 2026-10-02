// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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

  testWidgets('preview with unconstrained widget displays layout error', (
    tester,
  ) async {
    final fakeDtdServices = FakeWidgetPreviewScaffoldDtdServices();
    final controller = WidgetPreviewScaffoldController(
      dtdServicesOverride: fakeDtdServices,
      previews: () => [
        WidgetPreview.test(
          builder: () => const SizedBox.expand(child: Text('Oops')),
          previewData: const Preview(),
        ),
      ],
    );

    if (controller.filterBySelectedFileListenable.value) {
      await controller.toggleFilterBySelectedFile();
    }
    await controller.initialize();

    await tester.pumpWidget(TestWidgetPreviewScaffold(controller: controller));

    final Object? exception = tester.takeException();
    expect(exception, isA<FlutterError>());
    expect(
      (exception! as FlutterError).message,
      contains('A widget preview was rendered with unconstrained dimensions.'),
    );

    // Before the post-frame callback replaces the broken preview with
    // WidgetPreviewErrorWidget, _WidgetPreviewWrapperBox's child is still
    // unlaid-out. Verify pointer hit-testing over it does not trigger a
    // secondary 'RenderBox was not laid out' assertion.
    expect(find.byType(WidgetPreviewErrorWidget), findsNothing);
    await tester.tapAt(tester.getCenter(find.byType(WidgetPreviewWidget)));
    expect(tester.takeException(), isNull);

    await tester.pump();
    expect(find.byType(WidgetPreviewErrorWidget), findsOneWidget);
    expect(find.textContaining('unconstrained dimensions'), findsOneWidget);
  });

  testWidgets(
    'preview with TextField inside Row displays unconstrained layout error and recovers on hot reload',
    (tester) async {
      var isFixed = false;
      // Reuse one WidgetPreview instance so widget.preview identity is unchanged
      // across the reload; this verifies reassemble() (not didUpdateWidget)
      // clears _layoutError.
      final preview = WidgetPreview.test(
        builder: () => isFixed
            ? const SizedBox(width: 200, child: TextField())
            : const Row(children: [TextField()]),
        previewData: const Preview(),
      );
      final fakeDtdServices = FakeWidgetPreviewScaffoldDtdServices();
      final controller = WidgetPreviewScaffoldController(
        dtdServicesOverride: fakeDtdServices,
        previews: () => [preview],
      );

      if (controller.filterBySelectedFileListenable.value) {
        await controller.toggleFilterBySelectedFile();
      }
      await controller.initialize();

      await tester.pumpWidget(
        TestWidgetPreviewScaffold(controller: controller),
      );

      final Object? exception = tester.takeException();
      expect(exception, isA<FlutterError>());
      expect(
        (exception! as FlutterError).message,
        contains(
          'A widget preview was rendered with unconstrained dimensions.',
        ),
      );

      await tester.pump();
      expect(find.byType(WidgetPreviewErrorWidget), findsOneWidget);
      expect(find.textContaining('unconstrained dimensions'), findsOneWidget);

      // Simulate fixing the unconstrained preview and performing a hot reload.
      isFixed = true;
      unawaited(tester.binding.reassembleApplication());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(WidgetPreviewErrorWidget), findsNothing);
      expect(
        find.descendant(
          of: find.byType(PreviewWidget),
          matching: find.byType(TextField),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'preview with non-unconstrained layout error displays original error',
    (tester) async {
      final fakeDtdServices = FakeWidgetPreviewScaffoldDtdServices();
      final controller = WidgetPreviewScaffoldController(
        dtdServicesOverride: fakeDtdServices,
        previews: () => [
          WidgetPreview.test(
            builder: () => const _ThrowingLayoutWidget(),
            previewData: const Preview(),
          ),
        ],
      );

      if (controller.filterBySelectedFileListenable.value) {
        await controller.toggleFilterBySelectedFile();
      }
      await controller.initialize();

      await tester.pumpWidget(
        TestWidgetPreviewScaffold(controller: controller),
      );

      final Object? exception = tester.takeException();
      expect(exception, isA<StateError>());
      expect(
        (exception! as StateError).message,
        equals('custom layout failure'),
      );

      await tester.pump();
      expect(find.byType(WidgetPreviewErrorWidget), findsOneWidget);
      expect(
        find.textContaining('Bad state: custom layout failure'),
        findsOneWidget,
      );
      expect(find.textContaining('unconstrained dimensions'), findsNothing);
    },
  );

  testWidgets(
    'preview with CustomPaint(size: Size.infinite) inside Row displays layout error card and preserves preview name header',
    (tester) async {
      final fakeDtdServices = FakeWidgetPreviewScaffoldDtdServices();
      final controller = WidgetPreviewScaffoldController(
        dtdServicesOverride: fakeDtdServices,
        previews: () => [
          WidgetPreview.test(
            builder: () =>
                const Row(children: [CustomPaint(size: Size.infinite)]),
            previewData: const Preview(name: 'InfiniteCustomPaintPreview'),
          ),
        ],
      );

      if (controller.filterBySelectedFileListenable.value) {
        await controller.toggleFilterBySelectedFile();
      }
      await controller.initialize();

      await tester.pumpWidget(
        TestWidgetPreviewScaffold(controller: controller),
      );

      final Object? exception = tester.takeException();
      expect(exception, isA<FlutterError>());
      expect(
        (exception! as FlutterError).message,
        contains(
          'A widget preview was rendered with unconstrained dimensions.',
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(WidgetPreviewErrorWidget), findsOneWidget);
      expect(find.textContaining('unconstrained dimensions'), findsOneWidget);
      expect(find.text('InfiniteCustomPaintPreview'), findsOneWidget);
    },
  );
}

class _ThrowingLayoutWidget extends LeafRenderObjectWidget {
  const _ThrowingLayoutWidget();

  @override
  RenderObject createRenderObject(BuildContext context) => _ThrowingRenderBox();
}

class _ThrowingRenderBox extends RenderBox {
  @override
  void performLayout() {
    throw StateError('custom layout failure');
  }
}
