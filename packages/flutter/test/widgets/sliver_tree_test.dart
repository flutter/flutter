// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

List<SliverTreeNode<String>> simpleNodeSet = <SliverTreeNode<String>>[
  SliverTreeNode<String>('Root 0'),
  SliverTreeNode<String>(
    'Root 1',
    expanded: true,
    children: <SliverTreeNode<String>>[
      SliverTreeNode<String>('Child 1:0'),
      SliverTreeNode<String>('Child 1:1'),
    ],
  ),
  SliverTreeNode<String>(
    'Root 2',
    children: <SliverTreeNode<String>>[
      SliverTreeNode<String>('Child 2:0'),
      SliverTreeNode<String>('Child 2:1'),
    ],
  ),
  SliverTreeNode<String>('Root 3'),
];

void main() {
  group('SliverTreeNode', () {
    test('getters, toString', () {
      final List<SliverTreeNode<String>> children = <SliverTreeNode<String>>[
        SliverTreeNode<String>('child'),
      ];
      final SliverTreeNode<String> node = SliverTreeNode<String>(
        'parent',
        children: children,
        expanded: true,
      );
      expect(node.content, 'parent');
      expect(node.children, children);
      expect(node.isExpanded, isTrue);
      expect(node.children.first.content, 'child');
      expect(node.children.first.children.isEmpty, isTrue);
      expect(node.children.first.isExpanded, isFalse);
      // Set by TreeView when built for tree integrity
      expect(node.depth, isNull);
      expect(node.parent, isNull);
      expect(node.children.first.depth, isNull);
      expect(node.children.first.parent, isNull);

      expect(
        node.toString(),
        'SliverTreeNode: parent, depth: null, parent, expanded: true',
      );
      expect(
        node.children.first.toString(),
        'SliverTreeNode: child, depth: null, leaf',
      );
    });

    testWidgets('SliverTreeNode sets ups parent and depth properties', (WidgetTester tester) async {
      final List<SliverTreeNode<String>> children = <SliverTreeNode<String>>[
        SliverTreeNode<String>('child'),
      ];
      final SliverTreeNode<String> node = SliverTreeNode<String>(
        'parent',
        children: children,
        expanded: true,
      );
      await tester.pumpWidget(MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverTree<String>(
              tree: <SliverTreeNode<String>>[node],
            ),
          ],
        )
      ));
      expect(node.content, 'parent');
      expect(node.children, children);
      expect(node.isExpanded, isTrue);
      expect(node.children.first.content, 'child');
      expect(node.children.first.children.isEmpty, isTrue);
      expect(node.children.first.isExpanded, isFalse);
      // Set by TreeView when built for tree integrity
      expect(node.depth, 0);
      expect(node.parent, isNull);
      expect(node.children.first.depth, 1);
      expect(node.children.first.parent, node);

      expect(
        node.toString(),
        'SliverTreeNode: parent, depth: root, parent, expanded: true',
      );
      expect(
        node.children.first.toString(),
        'SliverTreeNode: child, depth: 1, leaf',
      );
    });
  });

  group('TreeController', () {
    setUp(() {
      // Reset node conditions for each test.
      simpleNodeSet = <SliverTreeNode<String>>[
        SliverTreeNode<String>('Root 0'),
        SliverTreeNode<String>(
          'Root 1',
          expanded: true,
          children: <SliverTreeNode<String>>[
            SliverTreeNode<String>('Child 1:0'),
            SliverTreeNode<String>('Child 1:1'),
          ],
        ),
        SliverTreeNode<String>(
          'Root 2',
          children: <SliverTreeNode<String>>[
            SliverTreeNode<String>('Child 2:0'),
            SliverTreeNode<String>('Child 2:1'),
          ],
        ),
        SliverTreeNode<String>('Root 3'),
      ];
    });
    testWidgets('Can set controller on SliverTree', (WidgetTester tester) async {
      final SliverTreeController controller = SliverTreeController();
      SliverTreeController? returnedController;
      await tester.pumpWidget(MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverTree<String>(
              tree: simpleNodeSet,
              controller: controller,
              treeNodeBuilder: (BuildContext context, SliverTreeNode<dynamic> node, {AnimationStyle? animationStyle}) {
                returnedController ??= SliverTreeController.of(context);
                return SliverTree.defaultTreeNodeBuilder(
                  context,
                  node,
                  animationStyle: animationStyle,
                );
              },
            ),
          ],
        ),
      ));
      expect(controller, returnedController);
    });

    testWidgets('Can get default controller on SliverTree', (WidgetTester tester) async {
      SliverTreeController? returnedController;
      await tester.pumpWidget(MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverTree<String>(
              tree: simpleNodeSet,
              treeNodeBuilder: (
                BuildContext context,
                SliverTreeNode<dynamic> node, {
                AnimationStyle? animationStyle,
              }) {
                returnedController ??= SliverTreeController.maybeOf(context);
                return SliverTree.defaultTreeNodeBuilder(
                  context,
                  node,
                  animationStyle: animationStyle,
                );
              },
            ),
          ],
        ),
      ));
      expect(returnedController, isNotNull);
    });

    testWidgets('Can get node for SliverTreeNode.content', (WidgetTester tester) async {
      final SliverTreeController controller = SliverTreeController();
      await tester.pumpWidget(MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverTree<String>(
              tree: simpleNodeSet,
              controller: controller,
            ),
          ],
        ),
      ));

      expect(controller.getNodeFor('Root 0'), simpleNodeSet[0]);
    });

    testWidgets('Can get isExpanded for a node', (WidgetTester tester) async {
      final SliverTreeController controller = SliverTreeController();
      await tester.pumpWidget(MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverTree<String>(
              tree: simpleNodeSet,
              controller: controller,
            ),
          ],
        ),
      ));
      expect(
        controller.isExpanded(simpleNodeSet[0]),
        isFalse,
      );
      expect(
        controller.isExpanded(simpleNodeSet[1]),
        isTrue,
      );
    });

    testWidgets('Can get isActive for a node', (WidgetTester tester) async {
      final SliverTreeController controller = SliverTreeController();
      await tester.pumpWidget(MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverTree<String>(
              tree: simpleNodeSet,
              controller: controller,
            ),
          ],
        ),
      ));
      expect(
        controller.isActive(simpleNodeSet[0]),
        isTrue,
      );
      expect(
        controller.isActive(simpleNodeSet[1]),
        isTrue,
      );
      // The parent 'Root 2' is not expanded, so its children are not active.
      expect(
        controller.isExpanded(simpleNodeSet[2]),
        isFalse,
      );
      expect(
        controller.isActive(simpleNodeSet[2].children[0]),
        isFalse,
      );
    });

    testWidgets('Can toggleNode, to collapse or expand', (WidgetTester tester) async {
      final SliverTreeController controller = SliverTreeController();
      await tester.pumpWidget(MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverTree<String>(
              tree: simpleNodeSet,
              controller: controller,
            ),
          ],
        ),
      ));

      // The parent 'Root 2' is not expanded, so its children are not active.
      expect(
        controller.isExpanded(simpleNodeSet[2]),
        isFalse,
      );
      expect(
        controller.isActive(simpleNodeSet[2].children[0]),
        isFalse,
      );
      // Toggle 'Root 2' to expand it
      controller.toggleNode(simpleNodeSet[2]);
      expect(
        controller.isExpanded(simpleNodeSet[2]),
        isTrue,
      );
      expect(
        controller.isActive(simpleNodeSet[2].children[0]),
        isTrue,
      );

      // The parent 'Root 1' is expanded, so its children are active.
      expect(
        controller.isExpanded(simpleNodeSet[1]),
        isTrue,
      );
      expect(
        controller.isActive(simpleNodeSet[1].children[0]),
        isTrue,
      );
      // Collapse 'Root 1'
      controller.toggleNode(simpleNodeSet[1]);
      expect(
        controller.isExpanded(simpleNodeSet[1]),
        isTrue,
      );
      expect(
        controller.isActive(simpleNodeSet[1].children[0]),
        isTrue,
      );
      // Nodes are not removed from the active list until the collapse animation
      // completes. The parent expansion state also updates.
      await tester.pumpAndSettle();
      expect(
        controller.isExpanded(simpleNodeSet[1]),
        isFalse,
      );
      expect(
        controller.isActive(simpleNodeSet[1].children[0]),
        isFalse,
      );
    });

    testWidgets('Can expandNode, then collapseAll',
        (WidgetTester tester) async {
      final SliverTreeController controller = SliverTreeController();
      await tester.pumpWidget(MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverTree<String>(
              tree: simpleNodeSet,
              controller: controller,
            ),
          ],
        ),
      ));

      // The parent 'Root 2' is not expanded, so its children are not active.
      expect(
        controller.isExpanded(simpleNodeSet[2]),
        isFalse,
      );
      expect(
        controller.isActive(simpleNodeSet[2].children[0]),
        isFalse,
      );
      // Expand 'Root 2'
      controller.expandNode(simpleNodeSet[2]);
      expect(
        controller.isExpanded(simpleNodeSet[2]),
        isTrue,
      );
      expect(
        controller.isActive(simpleNodeSet[2].children[0]),
        isTrue,
      );

      // Both parents from our simple node set are expanded.
      // 'Root 1'
      expect(controller.isExpanded(simpleNodeSet[1]), isTrue);
      // 'Root 2'
      expect(controller.isExpanded(simpleNodeSet[2]), isTrue);
      // Collapse both.
      controller.collapseAll();
      await tester.pumpAndSettle();
      // Both parents from our simple node set have collapsed.
      // 'Root 1'
      expect(controller.isExpanded(simpleNodeSet[1]), isFalse);
      // 'Root 2'
      expect(controller.isExpanded(simpleNodeSet[2]), isFalse);
    });

    testWidgets('Can collapseNode, then expandAll', (WidgetTester tester) async {
      final SliverTreeController controller = SliverTreeController();
      await tester.pumpWidget(MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverTree<String>(
              tree: simpleNodeSet,
              controller: controller,
            ),
          ],
        ),
      ));

      // The parent 'Root 1' is expanded, so its children are active.
      expect(
        controller.isExpanded(simpleNodeSet[1]),
        isTrue,
      );
      expect(
        controller.isActive(simpleNodeSet[1].children[0]),
        isTrue,
      );
      // Collapse 'Root 1'
      controller.collapseNode(simpleNodeSet[1]);
      expect(
        controller.isExpanded(simpleNodeSet[1]),
        isTrue,
      );
      expect(
        controller.isActive(simpleNodeSet[1].children[0]),
        isTrue,
      );
      // Nodes are not removed from the active list until the collapse animation
      // completes.
      await tester.pumpAndSettle();
      expect(
        controller.isActive(simpleNodeSet[1].children[0]),
        isFalse,
      );

      // Both parents from our simple node set are collapsed.
      // 'Root 1'
      expect(controller.isExpanded(simpleNodeSet[1]), isFalse);
      // 'Root 2'
      expect(controller.isExpanded(simpleNodeSet[2]), isFalse);
      // Expand both.
      controller.expandAll();
      // Both parents from our simple node set are expanded.
      // 'Root 1'
      expect(controller.isExpanded(simpleNodeSet[1]), isTrue);
      // 'Root 2'
      expect(controller.isExpanded(simpleNodeSet[2]), isTrue);
    });
  });

  test('SliverTreeIndentationType values are properly reflected', () {
    double value = SliverTreeIndentationType.standard.value;
    expect(value, 10.0);

    value = SliverTreeIndentationType.none.value;
    expect(value, 0.0);

    value = SliverTreeIndentationType.custom(50.0).value;
    expect(value, 50.0);
  });

  testWidgets('.toggleNodeWith, onNodeToggle', (WidgetTester tester) async {
    final SliverTreeController controller = SliverTreeController();
    // The default node builder wraps the leading icon with toggleNodeWith.
    bool toggled = false;
    SliverTreeNode<String>? toggledNode;
    await tester.pumpWidget(MaterialApp(
      home: CustomScrollView(
        slivers: <Widget>[
          SliverTree<String>(
            tree: simpleNodeSet,
            controller: controller,
            onNodeToggle: (SliverTreeNode<dynamic> node) {
              toggled = true;
              toggledNode = node as SliverTreeNode<String>;
            },
          ),
        ],
      ),
    ));
    expect(controller.isExpanded(simpleNodeSet[1]), isTrue);
    await tester.tap(find.byType(Icon).first);
    await tester.pump();
    expect(controller.isExpanded(simpleNodeSet[1]), isTrue);
    expect(toggled, isTrue);
    expect(toggledNode, simpleNodeSet[1]);
    await tester.pumpAndSettle();
    expect(controller.isExpanded(simpleNodeSet[1]), isFalse);
    toggled = false;
    toggledNode = null;
    // Use toggleNodeWith to make the whole row trigger the node state.
    await tester.pumpWidget(MaterialApp(
      home: CustomScrollView(
        slivers: <Widget>[
          SliverTree<String>(
            tree: simpleNodeSet,
            controller: controller,
            onNodeToggle: (SliverTreeNode<dynamic> node) {
              toggled = true;
              toggledNode = node as SliverTreeNode<String>;
            },
            treeNodeBuilder: (
              BuildContext context,
              SliverTreeNode<dynamic> node, {
              AnimationStyle? animationStyle,
            }) {
              final Duration animationDuration =
                animationStyle?.duration ?? SliverTree.defaultAnimationDuration;
              final Curve animationCurve =
                animationStyle?.curve ?? SliverTree.defaultAnimationCurve;
              // This makes the whole row trigger toggling.
              return SliverTree.toggleNodeWith(
                node: node,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(children: <Widget>[
                    // Icon for parent nodes
                    SizedBox.square(
                    dimension: 30.0,
                    child: node.children.isNotEmpty
                      ? AnimatedRotation(
                          turns: node.isExpanded ? 0.25 : 0.0,
                          duration: animationDuration,
                          curve: animationCurve,
                          child: const Icon(IconData(0x25BA), size: 14),
                        )
                      : null,
                    ),
                    // Spacer
                    const SizedBox(width: 8.0),
                    // Content
                    Text(node.content.toString()),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    ));
    // Still collapsed from earlier
    expect(controller.isExpanded(simpleNodeSet[1]), isFalse);
    // Tapping on the text instead of the Icon.
    await tester.tap(find.text('Root 1'));
    await tester.pump();
    expect(controller.isExpanded(simpleNodeSet[1]), isTrue);
    expect(toggled, isTrue);
    expect(toggledNode, simpleNodeSet[1]);
  });

  testWidgets('AnimationStyle is piped through to node builder', (WidgetTester tester) async {
    AnimationStyle? style;
    await tester.pumpWidget(MaterialApp(
      home: CustomScrollView(
        slivers: <Widget>[
          SliverTree<String>(
            tree: simpleNodeSet,
            treeNodeBuilder: (
              BuildContext context,
              SliverTreeNode<dynamic> node, {
              AnimationStyle? animationStyle,
            }) {
              style ??= animationStyle;
              return Text(node.content.toString());
            },
          ),
        ],
      ),
    ));
    // Default
    expect(style, isNull);

    await tester.pumpWidget(MaterialApp(
      home: CustomScrollView(
        slivers: <Widget>[
          SliverTree<String>(
            tree: simpleNodeSet,
            animationStyle: AnimationStyle.noAnimation,
            treeNodeBuilder: (
              BuildContext context,
              SliverTreeNode<dynamic> node, {
              AnimationStyle? animationStyle,
            }) {
              style ??= animationStyle;
              return Text(node.content.toString());
            },
          ),
        ],
      ),
    ));
    expect(style, isNotNull);
    expect(style!.curve, null);
    expect(style!.duration, Duration.zero);
    style = null;

    await tester.pumpWidget(MaterialApp(
      home: CustomScrollView(
        slivers: <Widget>[
          SliverTree<String>(
            tree: simpleNodeSet,
            animationStyle: AnimationStyle(
              curve: Curves.easeIn,
              duration: const Duration(milliseconds: 200),
            ),
            treeNodeBuilder: (
              BuildContext context,
              SliverTreeNode<dynamic> node, {
              AnimationStyle? animationStyle,
            }) {
              style ??= animationStyle;
              return Text(node.content.toString());
            },
          ),
        ],
      ),
    ));
    expect(style, isNotNull);
    expect(style!.curve, Curves.easeIn);
    expect(style!.duration, const Duration(milliseconds: 200));
  });
}
