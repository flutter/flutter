// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/expansion_panel/expansion_panel_list.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Flat ExpansionPanelList preserves dividers with no MaterialGap', (WidgetTester tester) async {
    await tester.pumpWidget(const example.FlatExpansionPanelListExampleApp());

    await tester.tap(find.text('Panel A'));
    await tester.pumpAndSettle();

    final MergeableMaterial mergeableMaterial = tester.widget(find.byType(MergeableMaterial));
    expect(mergeableMaterial.children.whereType<MaterialGap>().length, 0);
    expect(mergeableMaterial.hasDividers, true);
  });
}
