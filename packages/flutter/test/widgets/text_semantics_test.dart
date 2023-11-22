// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import 'semantics_tester.dart';

void main() {
  testWidgetsWithLeakTracking('SemanticsNode ids are stable', (WidgetTester tester) async {
    // Regression test for b/151732341.
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
      child: Text.rich(
        TextSpan(
          text: 'Hallo ',
          recognizer: TapGestureRecognizer()..onTap = () {},
          children: <TextSpan>[
            TextSpan(
              text: 'Welt ',
              recognizer: TapGestureRecognizer()..onTap = () {},
            ),
            TextSpan(
              text: '!!!',
              recognizer: TapGestureRecognizer()..onTap = () {},
            ),
          ],
        ),
      ),
    ));
    expect(find.text('Hallo Welt !!!'), findsOneWidget);
    final SemanticsNode node = tester.getSemantics(find.text('Hallo Welt !!!'));
    final Map<String, int> labelToNodeId = <String, int>{};
    node.visitChildren((SemanticsNode node) {
      labelToNodeId[node.label] = node.id;
       return true;
    });
    expect(node.id, 1);
    expect(labelToNodeId['Hallo '], 2);
    expect(labelToNodeId['Welt '], 3);
    expect(labelToNodeId['!!!'], 4);
    expect(labelToNodeId.length, 3);

    // Rebuild semantics.
    tester.renderObject(find.text('Hallo Welt !!!')).markNeedsSemanticsUpdate();
    await tester.pump();

    final SemanticsNode nodeAfterRebuild = tester.getSemantics(find.text('Hallo Welt !!!'));
    final Map<String, int> labelToNodeIdAfterRebuild = <String, int>{};
    nodeAfterRebuild.visitChildren((SemanticsNode node) {
      labelToNodeIdAfterRebuild[node.label] = node.id;
      return true;
    });

    // Node IDs are stable.
    expect(nodeAfterRebuild.id, node.id);
    expect(labelToNodeIdAfterRebuild['Hallo '], labelToNodeId['Hallo ']);
    expect(labelToNodeIdAfterRebuild['Welt '], labelToNodeId['Welt ']);
    expect(labelToNodeIdAfterRebuild['!!!'], labelToNodeId['!!!']);
    expect(labelToNodeIdAfterRebuild.length, 3);

    // Remove one node.
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Text.rich(
        TextSpan(
          text: 'Hallo ',
          recognizer: TapGestureRecognizer()..onTap = () {},
          children: <TextSpan>[
            TextSpan(
              text: 'Welt ',
              recognizer: TapGestureRecognizer()..onTap = () {},
            ),
          ],
        ),
      ),
    ));

    final SemanticsNode nodeAfterRemoval = tester.getSemantics(find.text('Hallo Welt '));
    final Map<String, int> labelToNodeIdAfterRemoval = <String, int>{};
    nodeAfterRemoval.visitChildren((SemanticsNode node) {
      labelToNodeIdAfterRemoval[node.label] = node.id;
      return true;
    });

    // Node IDs are stable.
    expect(nodeAfterRemoval.id, node.id);
    expect(labelToNodeIdAfterRemoval['Hallo '], labelToNodeId['Hallo ']);
    expect(labelToNodeIdAfterRemoval['Welt '], labelToNodeId['Welt ']);
    expect(labelToNodeIdAfterRemoval.length, 2);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Text.rich(
        TextSpan(
          text: 'Hallo ',
          recognizer: TapGestureRecognizer()..onTap = () {},
          children: <TextSpan>[
            TextSpan(
              text: 'Welt ',
              recognizer: TapGestureRecognizer()..onTap = () {},
            ),
            TextSpan(
              text: '!!!',
              recognizer: TapGestureRecognizer()..onTap = () {},
            ),
          ],
        ),
      ),
    ));
    expect(find.text('Hallo Welt !!!'), findsOneWidget);
    final SemanticsNode nodeAfterAddition = tester.getSemantics(find.text('Hallo Welt !!!'));
    final Map<String, int> labelToNodeIdAfterAddition = <String, int>{};
    nodeAfterAddition.visitChildren((SemanticsNode node) {
      labelToNodeIdAfterAddition[node.label] = node.id;
      return true;
    });

    // New node gets a new ID.
    expect(nodeAfterAddition.id, node.id);
    expect(labelToNodeIdAfterAddition['Hallo '], labelToNodeId['Hallo ']);
    expect(labelToNodeIdAfterAddition['Welt '], labelToNodeId['Welt ']);
    expect(labelToNodeIdAfterAddition['!!!'], isNot(labelToNodeId['!!!']));
    expect(labelToNodeIdAfterAddition['!!!'], isNotNull);
    expect(labelToNodeIdAfterAddition.length, 3);

    semantics.dispose();
  });
}
