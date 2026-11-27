// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class _Portal extends StatefulWidget {
  const _Portal({required this.label, this.child});

  final String label;
  final Widget? child;

  @override
  State<_Portal> createState() => _PortalState();
}

class _PortalState extends State<_Portal> {
  final OverlayPortalController controller = OverlayPortalController()..show();

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: controller,
      overlayChildBuilder: (BuildContext context) => Align(child: Text(widget.label)),
      child: widget.child ?? const SizedBox(width: 10.0, height: 10.0),
    );
  }
}

Widget _app(Widget body) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Overlay(
      initialEntries: <OverlayEntry>[
        OverlayEntry(builder: (BuildContext context) => Center(child: body)),
      ],
    ),
  );
}

List<SemanticsNode> _orphans() {
  final kept = <SemanticsNode>{};
  final listed = <SemanticsNode>{};
  void keep(SemanticsNode n) {
    kept.add(n);
    n.visitChildren((SemanticsNode c) {
      keep(c);
      return true;
    });
  }

  void list(SemanticsNode n) {
    if (!listed.add(n)) {
      return;
    }
    n.debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder).forEach(list);
  }

  void visit(PipelineOwner owner) {
    if (owner.semanticsOwner?.rootSemanticsNode case final SemanticsNode root) {
      keep(root);
      list(root);
    }
    owner.visitChildren(visit);
  }

  visit(RendererBinding.instance.rootPipelineOwner);
  return <SemanticsNode>[...kept.difference(listed)];
}

void main() {
  testWidgets('control: plain portal has no orphaned semantics nodes', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(const _Portal(label: 'overlay')));
    expect(_orphans(), isEmpty);
    expect(find.semantics.byLabel('overlay'), findsOne);
    handle.dispose();
  });

  testWidgets('anchor under Opacity(0) skips overlay from traversal tree', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(const Opacity(opacity: 0.0, child: _Portal(label: 'overlay'))));
    final SemanticsNode root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
    final listedLabels = <String>[];
    void walk(SemanticsNode node) {
      if (node.label.isNotEmpty) {
        listedLabels.add(node.label);
      }
      node.debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder).forEach(walk);
    }

    walk(root);
    expect(listedLabels, isNot(contains('overlay')));
    handle.dispose();
  });

  testWidgets('anchor under ExcludeSemantics skips overlay from traversal tree', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(const ExcludeSemantics(child: _Portal(label: 'overlay'))));
    final SemanticsNode root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
    final listedLabels = <String>[];
    void walk(SemanticsNode node) {
      if (node.label.isNotEmpty) {
        listedLabels.add(node.label);
      }
      node.debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder).forEach(walk);
    }

    walk(root);
    expect(listedLabels, isNot(contains('overlay')));
    handle.dispose();
  });

  testWidgets('portal inside another portal anchor keeps both overlays listed', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const _Portal(
          label: 'outer',
          child: _Portal(label: 'inner'),
        ),
      ),
    );
    expect(_orphans(), isEmpty);
    expect(find.semantics.byLabel('outer'), findsOne);
    expect(find.semantics.byLabel('inner'), findsOne);
    handle.dispose();
  });

  testWidgets('RawMenuAnchor inside RawTooltip keeps menu items reachable', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final menu = MenuController();
    final Widget anchor = RawTooltip(
      semanticsTooltip: 'More actions',
      tooltipBuilder: (BuildContext context, Animation<double> animation) => const SizedBox(),
      child: RawMenuAnchor(
        controller: menu,
        overlayBuilder: (BuildContext context, RawMenuOverlayInfo info) => Positioned(
          left: 0.0,
          top: 0.0,
          child: Semantics(
            button: true,
            label: 'Copy',
            child: const SizedBox.square(dimension: 40.0),
          ),
        ),
        child: Semantics(
          button: true,
          label: 'More',
          child: const SizedBox.square(dimension: 40.0),
        ),
      ),
    );
    await tester.pumpWidget(_app(anchor));
    menu.open();
    await tester.pump();

    expect(_orphans(), isEmpty);
    expect(find.semantics.byLabel('Copy'), findsOne);
    handle.dispose();
  });

  testWidgets('SwitchListTile with Tooltip and MenuAnchor keeps menu items reachable', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final menu = MenuController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Tooltip(message: 'Setting', child: Text('Option')),
            secondary: MenuAnchor(
              controller: menu,
              menuChildren: <Widget>[MenuItemButton(onPressed: () {}, child: const Text('Copy'))],
              builder: (BuildContext context, MenuController controller, Widget? child) {
                return IconButton(icon: const Icon(Icons.more_vert), onPressed: controller.open);
              },
            ),
          ),
        ),
      ),
    );
    menu.open();
    await tester.pump();

    expect(_orphans(), isEmpty);
    expect(find.semantics.byLabel('Copy'), findsOne);
    handle.dispose();
  });
}
