// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('MergeSemantics', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    // not merged
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: <Widget>[
            Semantics(container: true, child: const Text('test1')),
            Semantics(container: true, child: const Text('test2')),
          ],
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(id: 1, label: 'test1'),
            TestSemantics.rootChild(id: 2, label: 'test2'),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    // merged
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MergeSemantics(
          child: Row(
            children: <Widget>[
              Semantics(container: true, child: const Text('test1')),
              Semantics(container: true, child: const Text('test2')),
            ],
          ),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[TestSemantics.rootChild(id: 3, label: 'test1\ntest2')],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    // not merged
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: <Widget>[
            Semantics(container: true, child: const Text('test1')),
            Semantics(container: true, child: const Text('test2')),
          ],
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(id: 6, label: 'test1'),
            TestSemantics.rootChild(id: 7, label: 'test2'),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('MergeSemantics works if other nodes are implicitly merged into its node', (
    WidgetTester tester,
  ) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MergeSemantics(
          child: Semantics(
            selected: true, // this is implicitly merged into the MergeSemantics node
            child: Row(
              children: <Widget>[
                Semantics(container: true, child: const Text('test1')),
                Semantics(container: true, child: const Text('test2')),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              id: 1,
              flags: <SemanticsFlag>[SemanticsFlag.hasSelectedState, SemanticsFlag.isSelected],
              label: 'test1\ntest2',
            ),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('LinkUri from child is passed up to the parent when merging nodes', (
    WidgetTester tester,
  ) async {
    final semantics = SemanticsTester(tester);
    final Uri uri = Uri.parse('https://flutter.com');
    const label = 'test1';
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MergeSemantics(
          child: Semantics(
            linkUrl: uri,
            link: true,
            child: Semantics(
              button: true,
              enabled: true,
              focusable: true,
              child: Focus(
                onFocusChange: (bool value) {},
                child: GestureDetector(onTap: () {}, child: const Text(label)),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              id: 1,
              linkUrl: uri,
              flags: <SemanticsFlag>[
                SemanticsFlag.isButton,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.isEnabled,
                SemanticsFlag.isFocusable,
                SemanticsFlag.isLink,
              ],
              actions: <SemanticsAction>[SemanticsAction.tap, SemanticsAction.focus],
              label: label,
            ),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('MergeSemantics with child delegate', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    ChildSemanticsConfigurationsResult delegate(List<SemanticsConfiguration> configs) {
      final builder = ChildSemanticsConfigurationsResultBuilder();
      final sibling = <SemanticsConfiguration>[];
      for (final config in configs) {
        if (config.value == '123') {
          builder.markAsMergeUp(config);
        } else {
          sibling.add(config);
        }
      }
      builder.markAsSiblingMergeGroup(sibling);
      return builder.build();
    }

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MergeSemantics(
          child: Semantics(
            label: 'Room Height',
            child: TestConfigDelegate(
              delegate: delegate,
              child: Column(
                children: <Widget>[
                  Semantics(label: 'height', child: const SizedBox(width: 100, height: 100)),
                  Semantics(value: '123', child: const SizedBox(width: 100, height: 100)),
                  Semantics(label: 'feet', child: const SizedBox(width: 100, height: 100)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final SemanticsNode node = tester.getSemantics(find.byType(MergeSemantics));
    final SemanticsData data = node.getSemanticsData();
    expect(data.label, 'Room Height\nheight\nfeet');
    expect(data.value, '123');

    semantics.dispose();
  });

  // Regression test for https://github.com/flutter/flutter/issues/79029
  testWidgets('Semantics nodes added in assembleSemanticsNode update their merge flag', (
    WidgetTester tester,
  ) async {
    final semantics = SemanticsTester(tester);
    final GlobalKey paintKey = GlobalKey();

    Widget buildCustomPaint({required String label}) {
      return CustomPaint(
        key: paintKey,
        size: const Size(100.0, 100.0),
        painter: _PainterWithSemantics(label: label),
      );
    }

    // Not merged.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: buildCustomPaint(label: 'test1'),
      ),
    );

    expect(_semanticsChildrenOfCustomPaint(tester).single.isMergedIntoParent, isFalse);

    // Merged. The global key keeps the render object alive, and with it the
    // semantics nodes that RenderCustomPaint created in assembleSemanticsNode.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MergeSemantics(child: buildCustomPaint(label: 'test2')),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(_semanticsChildrenOfCustomPaint(tester).single.isMergedIntoParent, isTrue);
    expect(tester.getSemantics(find.byType(MergeSemantics)).getSemanticsData().label, 'test2');

    // Not merged again.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: buildCustomPaint(label: 'test3'),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(_semanticsChildrenOfCustomPaint(tester).single.isMergedIntoParent, isFalse);

    semantics.dispose();
  });
}

List<SemanticsNode> _semanticsChildrenOfCustomPaint(WidgetTester tester) {
  final children = <SemanticsNode>[];
  tester.getSemantics(find.byType(CustomPaint)).visitChildren((SemanticsNode child) {
    children.add(child);
    return true;
  });
  return children;
}

class _PainterWithSemantics extends CustomPainter {
  const _PainterWithSemantics({required this.label});

  final String label;

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  SemanticsBuilderCallback get semanticsBuilder {
    return (Size size) {
      return <CustomPainterSemantics>[
        CustomPainterSemantics(
          key: const ValueKey<int>(1),
          rect: const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0),
          properties: SemanticsProperties(label: label, textDirection: TextDirection.ltr),
        ),
      ];
    };
  }

  @override
  bool shouldRepaint(_PainterWithSemantics oldDelegate) => oldDelegate.label != label;

  @override
  bool shouldRebuildSemantics(_PainterWithSemantics oldDelegate) => oldDelegate.label != label;
}

class TestConfigDelegate extends SingleChildRenderObjectWidget {
  const TestConfigDelegate({super.key, required this.delegate, super.child});
  final ChildSemanticsConfigurationsDelegate delegate;

  @override
  RenderTestConfigDelegate createRenderObject(BuildContext context) =>
      RenderTestConfigDelegate(delegate: delegate);

  @override
  void updateRenderObject(BuildContext context, RenderTestConfigDelegate renderObject) {
    renderObject.delegate = delegate;
  }
}

class RenderTestConfigDelegate extends RenderProxyBox {
  RenderTestConfigDelegate({ChildSemanticsConfigurationsDelegate? delegate}) : _delegate = delegate;

  ChildSemanticsConfigurationsDelegate? get delegate => _delegate;
  ChildSemanticsConfigurationsDelegate? _delegate;
  set delegate(ChildSemanticsConfigurationsDelegate? value) {
    if (value != _delegate) {
      markNeedsSemanticsUpdate();
    }
    _delegate = value;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    config.childConfigurationsDelegate = delegate;
  }
}
