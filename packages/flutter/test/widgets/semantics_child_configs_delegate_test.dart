// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Semantics can merge sibling group', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const SemanticsTag first = SemanticsTag('1');
    const SemanticsTag second = SemanticsTag('2');
    const SemanticsTag third = SemanticsTag('3');
    ChildSemanticsConfigsResult delegate(List<SemanticsConfiguration> configs) {
      expect(configs.length, 3);
      final ChildSemanticsConfigsResultBuilder builder = ChildSemanticsConfigsResultBuilder();
      final List<SemanticsConfiguration> sibling = <SemanticsConfiguration>[];
      // Merge first and third
      for (final SemanticsConfiguration config in configs) {
        if (config.isChildrenTagged(first) || config.isChildrenTagged(third)) {
          sibling.add(config);
        } else {
          builder.markAsMergeUp(config);
        }
      }
      builder.markAsSiblingMergeGroup(sibling);
      return builder.build();
    }
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          label: 'parent',
          child: TestConfigDelegate(
            delegate: delegate,
            child: Column(
              children: <Widget>[
                Semantics(
                  label: '1',
                  tagForChildren: first,
                  child: const SizedBox(width: 100, height: 100),
                  // this tests that empty nodes disappear
                ),
                Semantics(
                  label: '2',
                  tagForChildren: second,
                  child: const SizedBox(width: 100, height: 100),
                ),
                Semantics(
                  label: '3',
                  tagForChildren: third,
                  child: const SizedBox(width: 100, height: 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          label: 'parent\n2',
        ),
        TestSemantics.rootChild(
          label: '1\n3',
        ),
      ],
    ), ignoreId: true, ignoreRect: true, ignoreTransform: true));
  });

  testWidgets('Semantics can drop semantics config', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const SemanticsTag first = SemanticsTag('1');
    const SemanticsTag second = SemanticsTag('2');
    const SemanticsTag third = SemanticsTag('3');
    ChildSemanticsConfigsResult delegate(List<SemanticsConfiguration> configs) {
      final ChildSemanticsConfigsResultBuilder builder = ChildSemanticsConfigsResultBuilder();
      // Merge first and third
      for (final SemanticsConfiguration config in configs) {
        if (config.isChildrenTagged(first) || config.isChildrenTagged(third)) {
          continue;
        }
        builder.markAsMergeUp(config);
      }
      return builder.build();
    }
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          label: 'parent',
          child: TestConfigDelegate(
            delegate: delegate,
            child: Column(
              children: <Widget>[
                Semantics(
                  label: '1',
                  tagForChildren: first,
                  child: const SizedBox(width: 100, height: 100),
                  // this tests that empty nodes disappear
                ),
                Semantics(
                  label: '2',
                  tagForChildren: second,
                  child: const SizedBox(width: 100, height: 100),
                ),
                Semantics(
                  label: '3',
                  tagForChildren: third,
                  child: const SizedBox(width: 100, height: 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          label: 'parent\n2',
        ),
      ],
    ), ignoreId: true, ignoreRect: true, ignoreTransform: true));
  });

  testWidgets('Semantics throws when mark the same config twice case 1', (WidgetTester tester) async {
    const SemanticsTag first = SemanticsTag('1');
    const SemanticsTag second = SemanticsTag('2');
    const SemanticsTag third = SemanticsTag('3');
    ChildSemanticsConfigsResult delegate(List<SemanticsConfiguration> configs) {
      final ChildSemanticsConfigsResultBuilder builder = ChildSemanticsConfigsResultBuilder();
      // Marks the same one twice.
      builder.markAsMergeUp(configs.first);
      builder.markAsMergeUp(configs.first);
      return builder.build();
    }
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          label: 'parent',
          child: TestConfigDelegate(
            delegate: delegate,
            child: Column(
              children: <Widget>[
                Semantics(
                  label: '1',
                  tagForChildren: first,
                  child: const SizedBox(width: 100, height: 100),
                  // this tests that empty nodes disappear
                ),
                Semantics(
                  label: '2',
                  tagForChildren: second,
                  child: const SizedBox(width: 100, height: 100),
                ),
                Semantics(
                  label: '3',
                  tagForChildren: third,
                  child: const SizedBox(width: 100, height: 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('Semantics throws when mark the same config twice case 2', (WidgetTester tester) async {
    const SemanticsTag first = SemanticsTag('1');
    const SemanticsTag second = SemanticsTag('2');
    const SemanticsTag third = SemanticsTag('3');
    ChildSemanticsConfigsResult delegate(List<SemanticsConfiguration> configs) {
      final ChildSemanticsConfigsResultBuilder builder = ChildSemanticsConfigsResultBuilder();
      // Marks the same one twice.
      builder.markAsMergeUp(configs.first);
      builder.markAsSiblingMergeGroup(<SemanticsConfiguration>[configs.first]);
      return builder.build();
    }
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          label: 'parent',
          child: TestConfigDelegate(
            delegate: delegate,
            child: Column(
              children: <Widget>[
                Semantics(
                  label: '1',
                  tagForChildren: first,
                  child: const SizedBox(width: 100, height: 100),
                  // this tests that empty nodes disappear
                ),
                Semantics(
                  label: '2',
                  tagForChildren: second,
                  child: const SizedBox(width: 100, height: 100),
                ),
                Semantics(
                  label: '3',
                  tagForChildren: third,
                  child: const SizedBox(width: 100, height: 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isAssertionError);
  });
}

class TestConfigDelegate extends SingleChildRenderObjectWidget {
  const TestConfigDelegate({super.key, required this.delegate, super.child});
  final ChildSemanticsConfigsDelegate delegate;

  @override
  RenderTestConfigDelegate createRenderObject(BuildContext context) => RenderTestConfigDelegate(
    delegate: delegate,
  );

  @override
  void updateRenderObject(BuildContext context, RenderTestConfigDelegate renderObject) {
    renderObject.delegate = delegate;
  }
}

class RenderTestConfigDelegate extends RenderProxyBox {
  RenderTestConfigDelegate({
    ChildSemanticsConfigsDelegate? delegate,
  }) : _delegate = delegate;

  ChildSemanticsConfigsDelegate? get delegate => _delegate;
  ChildSemanticsConfigsDelegate? _delegate;
  set delegate(ChildSemanticsConfigsDelegate? value) {
    if (value != _delegate) {
      markNeedsSemanticsUpdate();
    }
    _delegate = value;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    config.childConfigsDelegate = _delegate;
  }
}
