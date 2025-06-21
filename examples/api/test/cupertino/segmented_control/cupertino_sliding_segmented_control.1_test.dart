// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_api_samples/cupertino/segmented_control/cupertino_sliding_segmented_control.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

RenderBox getRenderSegmentedControl(WidgetTester tester) {
  return tester.allRenderObjects.firstWhere((RenderObject currentObject) {
        return currentObject.toStringShort().contains('_RenderSegmentedControl');
      })
      as RenderBox;
}

int? getHighlightedIndex(WidgetTester tester) {
  return (getRenderSegmentedControl(tester) as dynamic).highlightedIndex as int?;
}

void main() {
  testWidgets('Momentary segmented control does not highlight selected segment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.SegmentedControlApp());

    expect(getHighlightedIndex(tester), null);

    await tester.tap(find.text('Cerulean'));
    await tester.pumpAndSettle();

    expect(getHighlightedIndex(tester), null);
  });
}
