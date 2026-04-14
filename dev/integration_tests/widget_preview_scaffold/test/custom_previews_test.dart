// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/utils.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';

import 'utils/widget_preview_scaffold_test_utils.dart';

base class BrightnessPreview extends MultiPreview {
  const BrightnessPreview({required this.name});

  final String name;

  @override
  final previews = const <Preview>[
    FixedSizePreview(brightness: Brightness.light),
    FixedSizePreview(brightness: Brightness.dark),
  ];

  static bool wrapperInvoked = false;

  Widget _wrapper(Widget child) {
    wrapperInvoked = true;
    return Container(child: child);
  }

  @override
  List<Preview> transform() {
    final parentPreviews = super.transform();
    final transformed = <Preview>[];
    for (final preview in parentPreviews) {
      final builder = preview.toBuilder()
        ..name =
            '$name - ${preview.name} - Brightness(${preview.brightness!.name})'
        ..addWrapper(_wrapper);
      transformed.add(builder.build());
    }
    return transformed;
  }
}

base class FixedSizePreview extends Preview {
  const FixedSizePreview({super.brightness})
    : super(size: const Size(100, 100));

  static bool wrapperInvoked = false;

  Widget _wrapper(Widget child) {
    wrapperInvoked = true;
    return Container(child: child);
  }

  @override
  Preview transform() {
    final parent = super.transform();
    final builder = parent.toBuilder()
      ..name = 'Fixed Size'
      ..addWrapper(_wrapper);
    return builder.build();
  }
}

WidgetPreviewerWidgetScaffolding previewsForCustomMultiPreview() {
  final previews = buildMultiWidgetPreview(
    packageName: '',
    scriptUri: '',
    preview: BrightnessPreview(name: 'MyPreview'),
    previewFunction: () => Text('Foo'),
    line: -1,
    column: -1,
  );
  final controller = FakeWidgetPreviewScaffoldController();
  return WidgetPreviewerWidgetScaffolding(
    child: Column(
      children: [
        ...previews.map(
          (e) => WidgetPreviewWidget(preview: e, controller: controller),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('Custom preview annotations are properly transformed and rendered', (
    tester,
  ) async {
    WidgetPreviewerWidgetScaffolding widgetPreview =
        previewsForCustomMultiPreview();
    await tester.pumpWidget(widgetPreview);
    // This test mimics applying @BrightnessPreview(name: 'MyPreview'), which expands into two
    // transformed instances of FixedSizePreview.
    //
    // This involves two transformation steps (in this order):
    //   - `FixedSizePreview.transform()`, which performs the initial transformation which sets
    //     the name of the transformed preview to 'Fixed Size' and adds a wrapper.
    //   - `BrightnessPreview.transform()` processes the two transformed `FixedSizePreview`
    //     instances, adding another wrapper around each child preview and setting the name to
    //     'MyPreview - ${fixedPreview.name} - Brightness(${brightness.name})'.
    expect(
      find.text('MyPreview - Fixed Size - Brightness(light)'),
      findsOneWidget,
    );
    expect(
      find.text('MyPreview - Fixed Size - Brightness(dark)'),
      findsOneWidget,
    );

    // Verifies that the wrapper callbacks are actually invoked.
    expect(FixedSizePreview.wrapperInvoked, true);
    expect(BrightnessPreview.wrapperInvoked, true);
  });
}
