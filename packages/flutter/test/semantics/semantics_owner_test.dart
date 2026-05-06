// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Performing SemanticsAction.showOnScreen does not crash if node no longer exist', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/100358.

    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(explicitChildNodes: true, child: const Text('Hello World')),
      ),
    );

    final int nodeId = tester.semantics.find(find.bySemanticsLabel('Hello World')).id;

    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Container()));

    // Node with $nodeId is no longer in the tree.
    expect(semantics, isNot(hasSemantics(TestSemantics(id: nodeId))));

    // Executing SemanticsAction.showOnScreen on that node does not crash.
    // (A platform may not have processed the semantics update yet and send
    // actions for no longer existing nodes.)
    tester.binding.performSemanticsAction(
      SemanticsActionEvent(
        type: SemanticsAction.showOnScreen,
        nodeId: nodeId,
        viewId: tester.view.viewId,
      ),
    );
    semantics.dispose();
  });

  group('MergeSemantics dispatches custom actions to the owning descendant', () {
    // Regression tests for https://github.com/flutter/flutter/issues/183833.
    //
    // When MergeSemantics merges nodes that each register distinct
    // CustomSemanticsActions, the framework must dispatch a platform request
    // for a specific custom action ID to the descendant that owns that
    // particular action — not to the first descendant that happens to have
    // *any* custom action.

    testWidgets('routes to inner or outer based on action id (chunhtai counter-example)', (
      WidgetTester tester,
    ) async {
      final semantics = SemanticsTester(tester);

      const outerAction = CustomSemanticsAction(label: 'Activate outer node');
      const innerAction = CustomSemanticsAction(label: 'Activate inner node');

      var outerCalled = 0;
      var innerCalled = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MergeSemantics(
            child: Semantics(
              customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                outerAction: () => outerCalled++,
              },
              child: Semantics(
                customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                  innerAction: () => innerCalled++,
                },
                child: const Text('Test'),
              ),
            ),
          ),
        ),
      );

      final int mergedNodeId = tester.getSemantics(find.text('Test')).id;
      final int innerActionId = CustomSemanticsAction.getIdentifier(innerAction);
      final int outerActionId = CustomSemanticsAction.getIdentifier(outerAction);

      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        mergedNodeId,
        SemanticsAction.customAction,
        innerActionId,
      );
      expect(innerCalled, 1);
      expect(outerCalled, 0);

      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        mergedNodeId,
        SemanticsAction.customAction,
        outerActionId,
      );
      expect(innerCalled, 1);
      expect(outerCalled, 1);

      semantics.dispose();
    });

    testWidgets('routes to the correct node in a three-deep merged nest', (
      WidgetTester tester,
    ) async {
      final semantics = SemanticsTester(tester);

      const actionA = CustomSemanticsAction(label: 'A');
      const actionB = CustomSemanticsAction(label: 'B');
      const actionC = CustomSemanticsAction(label: 'C');

      var aCalled = 0;
      var bCalled = 0;
      var cCalled = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MergeSemantics(
            child: Semantics(
              customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                actionA: () => aCalled++,
              },
              child: Semantics(
                customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                  actionB: () => bCalled++,
                },
                child: Semantics(
                  customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                    actionC: () => cCalled++,
                  },
                  child: const Text('Test'),
                ),
              ),
            ),
          ),
        ),
      );

      final int mergedNodeId = tester.getSemantics(find.text('Test')).id;
      final SemanticsOwner owner = tester.binding.pipelineOwner.semanticsOwner!;

      owner.performAction(
        mergedNodeId,
        SemanticsAction.customAction,
        CustomSemanticsAction.getIdentifier(actionC),
      );
      expect(aCalled, 0);
      expect(bCalled, 0);
      expect(cCalled, 1);

      owner.performAction(
        mergedNodeId,
        SemanticsAction.customAction,
        CustomSemanticsAction.getIdentifier(actionA),
      );
      expect(aCalled, 1);
      expect(bCalled, 0);
      expect(cCalled, 1);

      owner.performAction(
        mergedNodeId,
        SemanticsAction.customAction,
        CustomSemanticsAction.getIdentifier(actionB),
      );
      expect(aCalled, 1);
      expect(bCalled, 1);
      expect(cCalled, 1);

      semantics.dispose();
    });

    testWidgets('routes to the correct sibling descendant inside the merge group', (
      WidgetTester tester,
    ) async {
      // Two sibling Semantics inside a merge group, *and* a root-level
      // custom action that gets absorbed into the merge boundary. The root
      // action ensures the merge root itself has `customAction` in its
      // `_actions` map, which triggers chunhtai's bug — without it, the
      // outer guard `!result._canPerformAction(customAction)` would simply
      // pass and the inner walk would handle the dispatch.
      final semantics = SemanticsTester(tester);

      const rootAction = CustomSemanticsAction(label: 'root');
      const firstAction = CustomSemanticsAction(label: 'first');
      const secondAction = CustomSemanticsAction(label: 'second');

      var rootCalled = 0;
      var firstCalled = 0;
      var secondCalled = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MergeSemantics(
            child: Semantics(
              customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                rootAction: () => rootCalled++,
              },
              child: Column(
                children: <Widget>[
                  Semantics(
                    customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                      firstAction: () => firstCalled++,
                    },
                    child: const Text('first child'),
                  ),
                  Semantics(
                    customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                      secondAction: () => secondCalled++,
                    },
                    child: const Text('second child'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final int mergedNodeId = tester.getSemantics(find.text('first child')).id;
      final SemanticsOwner owner = tester.binding.pipelineOwner.semanticsOwner!;

      // The second sibling's action — would route to the merge root with
      // the broken outer-guard logic and fall through to a no-op.
      owner.performAction(
        mergedNodeId,
        SemanticsAction.customAction,
        CustomSemanticsAction.getIdentifier(secondAction),
      );
      expect(rootCalled, 0);
      expect(firstCalled, 0);
      expect(secondCalled, 1);

      owner.performAction(
        mergedNodeId,
        SemanticsAction.customAction,
        CustomSemanticsAction.getIdentifier(firstAction),
      );
      expect(rootCalled, 0);
      expect(firstCalled, 1);
      expect(secondCalled, 1);

      // The root action itself should still resolve to the merge root.
      owner.performAction(
        mergedNodeId,
        SemanticsAction.customAction,
        CustomSemanticsAction.getIdentifier(rootAction),
      );
      expect(rootCalled, 1);
      expect(firstCalled, 1);
      expect(secondCalled, 1);

      semantics.dispose();
    });

    testWidgets('performActionAt routes custom actions through merged descendants', (
      WidgetTester tester,
    ) async {
      // Covers _getSemanticsActionHandlerForPosition, which TalkBack uses for
      // double-tap dispatch and which the original PR also touched.
      final semantics = SemanticsTester(tester);

      const outerAction = CustomSemanticsAction(label: 'outer');
      const innerAction = CustomSemanticsAction(label: 'inner');

      var outerCalled = 0;
      var innerCalled = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: MergeSemantics(
                child: Semantics(
                  customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                    outerAction: () => outerCalled++,
                  },
                  child: Semantics(
                    customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                      innerAction: () => innerCalled++,
                    },
                    child: const Text('hit'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // performActionAt expects positions in the root semantics node's
      // coordinate space, which is physical pixels — see SemanticsDebugger.
      final Offset center = tester.getCenter(find.text('hit')) * tester.view.devicePixelRatio;
      final SemanticsOwner owner = tester.binding.pipelineOwner.semanticsOwner!;

      owner.performActionAt(
        center,
        SemanticsAction.customAction,
        CustomSemanticsAction.getIdentifier(innerAction),
      );
      expect(innerCalled, 1);
      expect(outerCalled, 0);

      owner.performActionAt(
        center,
        SemanticsAction.customAction,
        CustomSemanticsAction.getIdentifier(outerAction),
      );
      expect(innerCalled, 1);
      expect(outerCalled, 1);

      semantics.dispose();
    });
  });
}
