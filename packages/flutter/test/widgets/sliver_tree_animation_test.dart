// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TreeSliver can handle rapid taps while collapsing', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/170757.
    final controller = TreeSliverController();
    final parent = TreeSliverNode<String>(
      'Second',
      children: <TreeSliverNode<String>>[
        TreeSliverNode<String>(
          'alpha',
          children: <TreeSliverNode<String>>[
            TreeSliverNode<String>('uno'),
            TreeSliverNode<String>('dos'),
            TreeSliverNode<String>('tres'),
          ],
        ),
        TreeSliverNode<String>('beta'),
        TreeSliverNode<String>('kappa'),
      ],
    );
    final tree = <TreeSliverNode<String>>[
      TreeSliverNode<String>('First'),
      parent,
      TreeSliverNode<String>(
        'Third',
        expanded: true,
        children: <TreeSliverNode<String>>[
          TreeSliverNode<String>('gamma'),
          TreeSliverNode<String>('delta'),
          TreeSliverNode<String>('epsilon'),
        ],
      ),
      TreeSliverNode<String>('Fourth'),
    ];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return CustomScrollView(
              slivers: <Widget>[
                TreeSliver<String>(
                  tree: tree,
                  controller: controller,
                  treeNodeBuilder:
                      (
                        BuildContext context,
                        TreeSliverNode<Object?> node,
                        AnimationStyle animationStyle,
                      ) {
                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => setState(() => controller.toggleNode(node)),
                          child: TreeSliver.defaultTreeNodeBuilder(context, node, animationStyle),
                        );
                      },
                ),
              ],
            );
          },
        ),
      ),
    );

    final Offset position = tester.getCenter(find.text('Second'));
    await tester.tapAt(position);
    await tester.pumpAndSettle();
    expect(find.text('alpha'), findsOneWidget);

    await tester.tapAt(position);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    await tester.tapAt(position);
    await tester.pumpAndSettle();

    expect(parent.isExpanded, isFalse);
    expect(find.text('alpha'), findsNothing);
    expect(find.text('Fourth'), findsOneWidget);
  });

  for (final childStartsFirst in <bool>[false, true]) {
    testWidgets(
      'Hidden node animations do not move visible nodes (${childStartsFirst ? 'child' : 'parent'} animates first)',
      (WidgetTester tester) async {
        final controller = TreeSliverController();
        final child = TreeSliverNode<String>(
          'Child',
          children: <TreeSliverNode<String>>[TreeSliverNode<String>('Grandchild')],
        );
        final parent = TreeSliverNode<String>(
          'Parent',
          expanded: true,
          children: <TreeSliverNode<String>>[child],
        );

        Widget buildTree(Duration duration) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: <Widget>[
                TreeSliver<String>(
                  tree: <TreeSliverNode<String>>[parent, TreeSliverNode<String>('Tail')],
                  controller: controller,
                  toggleAnimationStyle: AnimationStyle(curve: Curves.linear, duration: duration),
                  treeNodeBuilder:
                      (
                        BuildContext context,
                        TreeSliverNode<Object?> node,
                        AnimationStyle animationStyle,
                      ) {
                        return Text(node.content.toString());
                      },
                ),
              ],
            ),
          );
        }

        await tester.pumpWidget(buildTree(Duration(milliseconds: childStartsFirst ? 400 : 200)));
        if (childStartsFirst) {
          controller.expandNode(child);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
          // Keep the child's existing controller, but give the parent's new
          // controller a shorter duration so its collapse completes first.
          await tester.pumpWidget(buildTree(const Duration(milliseconds: 200)));
          controller.collapseNode(parent);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 210));
        } else {
          controller.collapseNode(parent);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
          controller.expandNode(child);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 160));
        }

        // The parent's collapse has finished while its child is still expanding.
        expect(tester.takeException(), isNull);
        expect(controller.isActive(child), isFalse);
        expect(find.text('Child'), findsNothing);
        expect(tester.getTopLeft(find.text('Tail')).dy, 40.0);

        // Reopening the parent restores its child's in-progress expansion.
        controller.expandNode(parent);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(controller.isActive(child), isTrue);
        expect(find.text('Grandchild'), findsOneWidget);
        expect(tester.getTopLeft(find.text('Tail')).dy, 120.0);
      },
    );
  }
}
