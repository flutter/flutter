// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('FloatingActionButton is navigated before body in Scaffold', (
    WidgetTester tester,
  ) async {
    final fabFocusNode = FocusNode();
    final itemFocusNodes = List<FocusNode>.generate(3, (_) => FocusNode());
    addTearDown(() {
      fabFocusNode.dispose();
      for (final node in itemFocusNodes) {
        node.dispose();
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Title')),
          body: ListView.builder(
            itemCount: itemFocusNodes.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                focusNode: itemFocusNodes[index],
                title: Text('Item $index'),
                onTap: () {},
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            focusNode: fabFocusNode,
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );

    // Initial focus should be nowhere or on the first focusable element.
    // Tab once to move focus to the first element.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    // FAB should be focused because it's at order 4.0 (AppBar at 2.0 has no focusable elements).
    expect(fabFocusNode.hasFocus, isTrue);
    expect(itemFocusNodes[0].hasFocus, isFalse);

    // Tab to move focus to the first item in the body (order 5.0)
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(itemFocusNodes[0].hasFocus, isTrue);

    // Tab through the remaining items
    for (var i = 1; i < itemFocusNodes.length; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(itemFocusNodes[i].hasFocus, isTrue);
    }
  });

  testWidgets('Scaffold reverse navigation (Shift+Tab) follows the expected order', (
    WidgetTester tester,
  ) async {
    final fabFocusNode = FocusNode();
    final itemFocusNodes = List<FocusNode>.generate(3, (_) => FocusNode());
    addTearDown(() {
      fabFocusNode.dispose();
      for (final node in itemFocusNodes) {
        node.dispose();
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Title')),
          body: ListView.builder(
            itemCount: itemFocusNodes.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                focusNode: itemFocusNodes[index],
                title: Text('Item $index'),
                onTap: () {},
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            focusNode: fabFocusNode,
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );

    // Focus the first item in the body (order 5.0)
    itemFocusNodes[0].requestFocus();
    await tester.pump();
    expect(itemFocusNodes[0].hasFocus, isTrue);

    // Shift+Tab should move focus back to the FAB (order 4.0)
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();
    expect(fabFocusNode.hasFocus, isTrue);

    // Another Shift+Tab would move to AppBar (2.0) if it had focusable elements.
    // In this case, it will wrap around to the last element (Item 2 - order 5.0).
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();
    expect(itemFocusNodes[2].hasFocus, isTrue);
  });

  testWidgets('Scaffold semantics order follows focus order', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Title')),
          body: ListView.builder(
            itemCount: 2,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(title: Text('Item $index'), onTap: () {});
            },
          ),
          floatingActionButton: Semantics(
            label: 'FAB',
            child: FloatingActionButton(
              tooltip: 'Add',
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );

    final Iterable<SemanticsNode> fabNodes = semantics.nodesWith(label: 'FAB');
    expect(fabNodes, hasLength(1));
    final SemanticsNode fabNode = fabNodes.single;

    final Iterable<SemanticsNode> item0Nodes = semantics.nodesWith(label: 'Item 0');
    expect(item0Nodes, hasLength(1));
    final SemanticsNode item0Node = item0Nodes.single;

    final Iterable<SemanticsNode> titleNodes = semantics.nodesWith(label: 'Title');
    expect(titleNodes, hasLength(1));
    final SemanticsNode titleNode = titleNodes.single;

    SemanticsNode? findNodeWithSortKey(SemanticsNode? node) {
      while (node != null && node.sortKey == null) {
        node = node.parent;
      }
      return node;
    }

    final SemanticsNode? fabSortNode = findNodeWithSortKey(fabNode);
    final SemanticsNode? titleSortNode = findNodeWithSortKey(titleNode);
    final SemanticsNode? item0SortNode = findNodeWithSortKey(item0Node);

    expect(fabSortNode, isNotNull);
    expect(titleSortNode, isNotNull);
    expect(item0SortNode, isNotNull);

    expect((fabSortNode!.sortKey! as OrdinalSortKey).order, 4.0);
    expect((titleSortNode!.sortKey! as OrdinalSortKey).order, 2.0);
    expect((item0SortNode!.sortKey! as OrdinalSortKey).order, 5.0);

    semantics.dispose();
  });
}
