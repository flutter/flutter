// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_catalog/custom_semantics.dart' as custom_semantics show main;
import 'package:sample_catalog/custom_semantics.dart';

void main() {
  testWidgets('custom_semantics sample smoke test', (WidgetTester tester) async {
    // Turn on Semantics
    final SemanticsHandle semanticsHandler = tester.binding.pipelineOwner.ensureSemantics();
    final SemanticsOwner semanticsOwner = tester.binding.pipelineOwner.semanticsOwner;

    // Build the sample app
    custom_semantics.main();
    await tester.pump();

    // Verify it correctly exposes its semantics.
    // TODO(goderbauer): Use `SemanticsTester` after https://github.com/flutter/flutter/issues/12286.
    final SemanticsNode semantics = tester
        .renderObject(find.byType(AdjustableDropdownListTile))
        .debugSemantics;

    expectAdjustable(semantics,
      hasIncreaseAction: true,
      hasDecreaseAction: true,
      label: 'Timeout',
      decreasedValue: '5 seconds',
      value: '15 seconds',
      increasedValue: '30 seconds',
    );

    // Increase
    semanticsOwner.performAction(semantics.id, SemanticsAction.increase);
    await tester.pump();

    expectAdjustable(semantics,
      hasIncreaseAction: true,
      hasDecreaseAction: true,
      label: 'Timeout',
      decreasedValue: '15 seconds',
      value: '30 seconds',
      increasedValue: '1 minute',
    );

    // Increase all the way to highest value
    semanticsOwner.performAction(semantics.id, SemanticsAction.increase);
    await tester.pump();

    expectAdjustable(semantics,
      hasIncreaseAction: false,
      hasDecreaseAction: true,
      label: 'Timeout',
      decreasedValue: '30 seconds',
      value: '1 minute',
    );

    // Decrease
    semanticsOwner.performAction(semantics.id, SemanticsAction.decrease);
    await tester.pump();

    expectAdjustable(semantics,
      hasIncreaseAction: true,
      hasDecreaseAction: true,
      label: 'Timeout',
      decreasedValue: '15 seconds',
      value: '30 seconds',
      increasedValue: '1 minute',
    );

    // Decrease all the way to lowest value
    semanticsOwner.performAction(semantics.id, SemanticsAction.decrease);
    await tester.pump();
    semanticsOwner.performAction(semantics.id, SemanticsAction.decrease);
    await tester.pump();
    semanticsOwner.performAction(semantics.id, SemanticsAction.decrease);
    await tester.pump();

    expectAdjustable(semantics,
      hasIncreaseAction: true,
      hasDecreaseAction: false,
      label: 'Timeout',
      value: '1 second',
      increasedValue: '5 seconds',
    );

    // Clean-up
    semanticsHandler.dispose();
  });
}

void expectAdjustable(SemanticsNode node, {
  bool hasIncreaseAction = true,
  bool hasDecreaseAction = true,
  String label = '',
  String decreasedValue = '',
  String value = '',
  String increasedValue = '',
}) {
  final SemanticsData semanticsData = node.getSemanticsData();

  int actions = 0;
  if (hasIncreaseAction)
    actions |= SemanticsAction.increase.index;
  if (hasDecreaseAction)
    actions |= SemanticsAction.decrease.index;

  expect(semanticsData.actions, actions);
  expect(semanticsData.label, label);
  expect(semanticsData.decreasedValue, decreasedValue);
  expect(semanticsData.value, value);
  expect(semanticsData.increasedValue, increasedValue);
}
