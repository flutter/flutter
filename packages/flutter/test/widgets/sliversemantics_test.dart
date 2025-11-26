// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  group('SliverSemantics', () {
    setUp(() {
      debugResetSemanticsIdCounter();
    });

    _tests();
  });
}

Widget boilerPlate({required List<Widget> slivers, bool wrapWithDirectionality = true}) {
  Widget child = MediaQuery(
    data: const MediaQueryData(),
    child: CustomScrollView(slivers: slivers),
  );
  if (wrapWithDirectionality) {
    child = Directionality(textDirection: TextDirection.ltr, child: child);
  }
  return child;
}

void _tests() {
  testWidgets('Semantics shutdown and restart', (WidgetTester tester) async {
    SemanticsTester? semantics = SemanticsTester(tester);

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  textDirection: TextDirection.ltr,
                  label: 'test1',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            label: 'test1',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );

    semantics.dispose();
    semantics = null;
    await tester.pump();

    expect(tester.binding.hasScheduledFrame, isFalse);
    semantics = SemanticsTester(tester);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );
    semantics.dispose();
  }, semanticsEnabled: false);

  testWidgets('tag only applies to immediate child', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverMainAxisGroup(
            slivers: <Widget>[
              SliverToBoxAdapter(child: Container(padding: const EdgeInsets.only(top: 20.0))),
              const SliverToBoxAdapter(child: Text('label')),
            ],
          ),
        ],
      ),
    );

    expect(
      semantics,
      isNot(
        includesNodeWith(
          flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
          tags: <SemanticsTag>{RenderViewport.useTwoPaneSemantics},
        ),
      ),
    );

    await tester.pump();
    // Semantics should stay the same after a frame update.
    expect(
      semantics,
      isNot(
        includesNodeWith(
          flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
          tags: <SemanticsTag>{RenderViewport.useTwoPaneSemantics},
        ),
      ),
    );

    semantics.dispose();
  }, semanticsEnabled: false);

  testWidgets('Detach and reattach assert', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    final GlobalKey key = GlobalKey();

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            label: 'test1',
            sliver: SliverSemantics(
              key: key,
              container: true,
              label: 'test2a',
              sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
            ),
          ),
        ],
      ),
    );

    var expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  label: 'test1',
                  children: <TestSemantics>[TestSemantics(label: 'test2a')],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            label: 'test1',
            sliver: SliverSemantics(
              container: true,
              label: 'middle',
              sliver: SliverSemantics(
                key: key,
                container: true,
                label: 'test2b',
                sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
              ),
            ),
          ),
        ],
      ),
    );

    expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  label: 'test1',
                  children: <TestSemantics>[
                    TestSemantics(
                      label: 'middle',
                      children: <TestSemantics>[TestSemantics(label: 'test2b')],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );

    semantics.dispose();
  });

  testWidgets('Semantics and Directionality - RTL', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: boilerPlate(
          wrapWithDirectionality: false,
          slivers: <Widget>[
            SliverSemantics(
              label: 'test1',
              sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
            ),
          ],
        ),
      ),
    );

    expect(semantics, includesNodeWith(label: 'test1', textDirection: TextDirection.rtl));
    semantics.dispose();
  });

  testWidgets('Semantics and Directionality - LTR', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        // Wraps with a default Directionality widget with TextDirection.ltr.
        slivers: <Widget>[
          SliverSemantics(
            label: 'test1',
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(semantics, includesNodeWith(label: 'test1', textDirection: TextDirection.ltr));
    semantics.dispose();
  });

  testWidgets('Semantics and Directionality - cannot override RTL with LTR', (
    WidgetTester tester,
  ) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: boilerPlate(
          wrapWithDirectionality: false,
          slivers: <Widget>[
            SliverSemantics(
              label: 'test1',
              textDirection: TextDirection.ltr,
              sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
            ),
          ],
        ),
      ),
    );

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  textDirection: TextDirection.ltr,
                  label: 'test1',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );
    semantics.dispose();
  });

  testWidgets('Semantics and Directionality - cannot override LTR with RTL', (
    WidgetTester tester,
  ) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        // Wraps with a default Directionality widget with TextDirection.ltr.
        slivers: <Widget>[
          SliverSemantics(
            label: 'test1',
            textDirection: TextDirection.rtl,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  textDirection: TextDirection.rtl,
                  label: 'test1',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );
    semantics.dispose();
  });

  testWidgets('label and hint', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            label: 'label',
            hint: 'hint',
            value: 'value',
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  label: 'label',
                  hint: 'hint',
                  value: 'value',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );
    semantics.dispose();
  });

  testWidgets('hints can merge', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            sliver: SliverMainAxisGroup(
              slivers: <Widget>[
                SliverSemantics(
                  hint: 'hint one',
                  sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                ),
                SliverSemantics(
                  hint: 'hint two',
                  sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  textDirection: TextDirection.ltr,
                  hint: 'hint one\nhint two',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );
    semantics.dispose();
  });

  testWidgets('hints can merge with Semantics widget', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            sliver: SliverList.list(
              children: <Widget>[
                Semantics(hint: 'hint one', child: const SizedBox(height: 10.0)),
                Semantics(hint: 'hint two', child: const SizedBox(height: 10.0)),
              ],
            ),
          ),
        ],
      ),
    );

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  textDirection: TextDirection.ltr,
                  hint: 'hint one\nhint two',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );
    semantics.dispose();
  });

  testWidgets('values do not merge', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            sliver: SliverMainAxisGroup(
              slivers: <Widget>[
                SliverSemantics(
                  value: 'value one',
                  sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                ),
                SliverSemantics(
                  value: 'value two',
                  sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  children: <TestSemantics>[
                    TestSemantics(value: 'value one', textDirection: TextDirection.ltr),
                    TestSemantics(value: 'value two', textDirection: TextDirection.ltr),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );
    semantics.dispose();
  });

  testWidgets('values do not merge with Semantics widget', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            sliver: SliverList.list(
              children: <Widget>[
                Semantics(value: 'value one', child: const SizedBox(height: 10.0)),
                Semantics(value: 'value two', child: const SizedBox(height: 10.0)),
              ],
            ),
          ),
        ],
      ),
    );

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  children: <TestSemantics>[
                    TestSemantics(value: 'value one', textDirection: TextDirection.ltr),
                    TestSemantics(value: 'value two', textDirection: TextDirection.ltr),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );
    semantics.dispose();
  });

  testWidgets('value and hint can merge', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            sliver: SliverMainAxisGroup(
              slivers: <Widget>[
                SliverSemantics(
                  hint: 'hint',
                  sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                ),
                SliverSemantics(
                  value: 'value',
                  sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  hint: 'hint',
                  value: 'value',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );
    semantics.dispose();
  });

  testWidgets('value and hint can merge with Semantics widget', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            sliver: SliverList.list(
              children: <Widget>[
                Semantics(hint: 'hint', child: const SizedBox(height: 10.0)),
                Semantics(value: 'value', child: const SizedBox(height: 10.0)),
              ],
            ),
          ),
        ],
      ),
    );

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  hint: 'hint',
                  value: 'value',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );
    semantics.dispose();
  });

  testWidgets('tagForChildren works', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            sliver: SliverMainAxisGroup(
              slivers: <Widget>[
                SliverSemantics(
                  container: true,
                  sliver: const SliverToBoxAdapter(child: Text('child 1')),
                ),
                SliverSemantics(
                  container: true,
                  sliver: const SliverToBoxAdapter(child: Text('child 2')),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  children: <TestSemantics>[
                    TestSemantics(label: 'child 1', textDirection: TextDirection.ltr),
                    TestSemantics(label: 'child 2', textDirection: TextDirection.ltr),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );
    semantics.dispose();
  });

  testWidgets('tagForChildren works with Semantics widget', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            sliver: SliverList.list(
              children: <Widget>[
                Semantics(container: true, child: const Text('child 1')),
                Semantics(container: true, child: const Text('child 2')),
              ],
            ),
          ),
        ],
      ),
    );

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  children: <TestSemantics>[
                    TestSemantics(label: 'child 1', textDirection: TextDirection.ltr),
                    TestSemantics(label: 'child 2', textDirection: TextDirection.ltr),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );
    semantics.dispose();
  });

  testWidgets('supports all actions', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    final performedActions = <SemanticsAction>[];

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            onDismiss: () => performedActions.add(SemanticsAction.dismiss),
            onTap: () => performedActions.add(SemanticsAction.tap),
            onLongPress: () => performedActions.add(SemanticsAction.longPress),
            onScrollLeft: () => performedActions.add(SemanticsAction.scrollLeft),
            onScrollRight: () => performedActions.add(SemanticsAction.scrollRight),
            onScrollUp: () => performedActions.add(SemanticsAction.scrollUp),
            onScrollDown: () => performedActions.add(SemanticsAction.scrollDown),
            onIncrease: () => performedActions.add(SemanticsAction.increase),
            onDecrease: () => performedActions.add(SemanticsAction.decrease),
            onCopy: () => performedActions.add(SemanticsAction.copy),
            onCut: () => performedActions.add(SemanticsAction.cut),
            onPaste: () => performedActions.add(SemanticsAction.paste),
            onMoveCursorForwardByCharacter: (bool _) =>
                performedActions.add(SemanticsAction.moveCursorForwardByCharacter),
            onMoveCursorBackwardByCharacter: (bool _) =>
                performedActions.add(SemanticsAction.moveCursorBackwardByCharacter),
            onSetSelection: (TextSelection _) => performedActions.add(SemanticsAction.setSelection),
            onSetText: (String _) => performedActions.add(SemanticsAction.setText),
            onDidGainAccessibilityFocus: () =>
                performedActions.add(SemanticsAction.didGainAccessibilityFocus),
            onDidLoseAccessibilityFocus: () =>
                performedActions.add(SemanticsAction.didLoseAccessibilityFocus),
            onFocus: () => performedActions.add(SemanticsAction.focus),
            onExpand: () => performedActions.add(SemanticsAction.expand),
            onCollapse: () => performedActions.add(SemanticsAction.collapse),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Lorem Ipsum $index'),
                  ),
                );
              }, childCount: 1),
            ),
          ),
        ],
      ),
    );

    final Set<SemanticsAction> allActions = SemanticsAction.values.toSet()
      ..remove(SemanticsAction.moveCursorForwardByWord)
      ..remove(SemanticsAction.moveCursorBackwardByWord)
      ..remove(SemanticsAction.customAction) // customAction is not user-exposed.
      ..remove(SemanticsAction.showOnScreen) // showOnScreen is not user-exposed.
      ..remove(SemanticsAction.scrollToOffset); // scrollToOffset is not user-exposed.

    const expectedId = 2;
    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  id: expectedId,
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  actions: <SemanticsAction>[
                    SemanticsAction.tap,
                    SemanticsAction.longPress,
                    SemanticsAction.scrollLeft,
                    SemanticsAction.scrollRight,
                    SemanticsAction.scrollUp,
                    SemanticsAction.scrollDown,
                    SemanticsAction.increase,
                    SemanticsAction.decrease,
                    SemanticsAction.moveCursorForwardByCharacter,
                    SemanticsAction.moveCursorBackwardByCharacter,
                    SemanticsAction.setSelection,
                    SemanticsAction.copy,
                    SemanticsAction.cut,
                    SemanticsAction.paste,
                    SemanticsAction.didGainAccessibilityFocus,
                    SemanticsAction.didLoseAccessibilityFocus,
                    SemanticsAction.dismiss,
                    SemanticsAction.setText,
                    SemanticsAction.focus,
                    SemanticsAction.expand,
                    SemanticsAction.collapse,
                  ],
                  children: <TestSemantics>[
                    TestSemantics(label: 'Lorem Ipsum 0', textDirection: TextDirection.ltr),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );

    // Do the actions work?
    final SemanticsOwner semanticsOwner = tester.binding.pipelineOwner.semanticsOwner!;
    var expectedLength = 1;
    for (final action in allActions) {
      switch (action) {
        case SemanticsAction.moveCursorBackwardByCharacter:
        case SemanticsAction.moveCursorForwardByCharacter:
          semanticsOwner.performAction(expectedId, action, true);
        case SemanticsAction.setSelection:
          semanticsOwner.performAction(expectedId, action, <dynamic, dynamic>{
            'base': 4,
            'extent': 5,
          });
        case SemanticsAction.setText:
          semanticsOwner.performAction(expectedId, action, 'text');
        case SemanticsAction.copy:
        case SemanticsAction.customAction:
        case SemanticsAction.cut:
        case SemanticsAction.decrease:
        case SemanticsAction.didGainAccessibilityFocus:
        case SemanticsAction.didLoseAccessibilityFocus:
        case SemanticsAction.dismiss:
        case SemanticsAction.increase:
        case SemanticsAction.longPress:
        case SemanticsAction.moveCursorBackwardByWord:
        case SemanticsAction.moveCursorForwardByWord:
        case SemanticsAction.paste:
        case SemanticsAction.scrollDown:
        case SemanticsAction.scrollLeft:
        case SemanticsAction.scrollRight:
        case SemanticsAction.scrollUp:
        case SemanticsAction.scrollToOffset:
        case SemanticsAction.showOnScreen:
        case SemanticsAction.tap:
        case SemanticsAction.focus:
        case SemanticsAction.expand:
        case SemanticsAction.collapse:
          semanticsOwner.performAction(expectedId, action);
      }
      expect(performedActions.length, expectedLength);
      expect(performedActions.last, action);
      expectedLength += 1;
    }

    semantics.dispose();
  });

  testWidgets('supports all flags', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    // Checked state and toggled state are mutually exclusive.
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            key: const Key('a'),
            container: true,
            explicitChildNodes: true,
            // flags.
            enabled: true,
            hidden: true,
            checked: true,
            selected: true,
            button: true,
            slider: true,
            keyboardKey: true,
            link: true,
            textField: true,
            readOnly: true,
            focused: true,
            focusable: true,
            inMutuallyExclusiveGroup: true,
            header: true,
            obscured: true,
            multiline: true,
            scopesRoute: true,
            namesRoute: true,
            image: true,
            liveRegion: true,
            expanded: true,
            isRequired: true,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Lorem Ipsum $index'),
                  ),
                );
              }, childCount: 1),
            ),
          ),
        ],
      ),
    );
    final List<SemanticsFlag> flags = SemanticsFlag.values.toList();
    flags
      ..remove(SemanticsFlag.hasToggledState)
      ..remove(SemanticsFlag.isToggled)
      ..remove(SemanticsFlag.hasImplicitScrolling)
      ..remove(SemanticsFlag.isCheckStateMixed);

    var expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  flags: flags,
                  children: <TestSemantics>[
                    TestSemantics(
                      children: <TestSemantics>[
                        TestSemantics(label: 'Lorem Ipsum 0', textDirection: TextDirection.ltr),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            key: const Key('b'),
            container: true,
            scopesRoute: false,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Lorem Ipsum $index'),
                  ),
                );
              }, childCount: 1),
            ),
          ),
        ],
      ),
    );
    expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  flags: <SemanticsFlag>[],
                  children: <TestSemantics>[
                    TestSemantics(label: 'Lorem Ipsum 0', textDirection: TextDirection.ltr),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            key: const Key('c'),
            toggled: true,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Lorem Ipsum $index'),
                  ),
                );
              }, childCount: 1),
            ),
          ),
        ],
      ),
    );

    expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  flags: <SemanticsFlag>[SemanticsFlag.hasToggledState, SemanticsFlag.isToggled],
                  children: <TestSemantics>[
                    TestSemantics(label: 'Lorem Ipsum 0', textDirection: TextDirection.ltr),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            key: const Key('a'),
            container: true,
            explicitChildNodes: true,
            // flags.
            enabled: true,
            hidden: true,
            checked: false,
            mixed: true,
            selected: true,
            button: true,
            slider: true,
            keyboardKey: true,
            link: true,
            textField: true,
            readOnly: true,
            focused: true,
            focusable: true,
            inMutuallyExclusiveGroup: true,
            header: true,
            obscured: true,
            multiline: true,
            scopesRoute: true,
            namesRoute: true,
            image: true,
            liveRegion: true,
            expanded: true,
            isRequired: true,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Lorem Ipsum $index'),
                  ),
                );
              }, childCount: 1),
            ),
          ),
        ],
      ),
    );
    flags
      ..remove(SemanticsFlag.isChecked)
      ..add(SemanticsFlag.isCheckStateMixed);
    semantics.dispose();
    expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  flags: flags,
                  children: <TestSemantics>[
                    TestSemantics(
                      children: <TestSemantics>[
                        TestSemantics(label: 'Lorem Ipsum 0', textDirection: TextDirection.ltr),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );
  });

  testWidgets('supports tooltip', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  tooltip: 'test1',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            tooltip: 'test1',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );
    semantics.dispose();
  });

  testWidgets('actions can be replaced without triggering semantics update', (
    WidgetTester tester,
  ) async {
    final semantics = SemanticsTester(tester);
    var semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.semanticsOwner!.addListener(() {
      semanticsUpdateCount += 1;
    });

    final performedActions = <String>[];

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            onTap: () => performedActions.add('first'),
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    const expectedId = 2;
    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          id: 1,
          children: <TestSemantics>[
            TestSemantics(
              id: 3,
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  id: expectedId,
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  actions: SemanticsAction.tap.index,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    final SemanticsOwner semanticsOwner = tester.binding.pipelineOwner.semanticsOwner!;

    expect(semantics, hasSemantics(expectedSemantics, ignoreRect: true, ignoreTransform: true));
    semanticsOwner.performAction(expectedId, SemanticsAction.tap);
    expect(semanticsUpdateCount, 1);
    expect(performedActions, <String>['first']);

    semanticsUpdateCount = 0;
    performedActions.clear();

    // Updating existing handler should not trigger semantics update.
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            onTap: () => performedActions.add('second'),
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreRect: true, ignoreTransform: true));
    semanticsOwner.performAction(expectedId, SemanticsAction.tap);
    expect(semanticsUpdateCount, 0);
    expect(performedActions, <String>['second']);

    semanticsUpdateCount = 0;
    performedActions.clear();

    // Adding a handler works.
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            onTap: () => performedActions.add('second'),
            onLongPress: () => performedActions.add('longPress'),
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    final expectedSemanticsWithLongPress = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          id: 1,
          children: <TestSemantics>[
            TestSemantics(
              id: 3,
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  id: expectedId,
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  actions: SemanticsAction.tap.index | SemanticsAction.longPress.index,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemanticsWithLongPress, ignoreRect: true, ignoreTransform: true),
    );
    semanticsOwner.performAction(expectedId, SemanticsAction.longPress);
    expect(semanticsUpdateCount, 1);
    expect(performedActions, <String>['longPress']);

    semanticsUpdateCount = 0;
    performedActions.clear();

    // Removing a handler works.
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            onTap: () => performedActions.add('second'),
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreRect: true, ignoreTransform: true));
    expect(semanticsUpdateCount, 1);

    semantics.dispose();
  });

  testWidgets('onTapHint and onLongPressHint create custom actions', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            onTap: () {},
            onTapHint: 'test',
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.byType(SliverSemantics)),
      matchesSemantics(hasTapAction: true, onTapHint: 'test'),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            onLongPress: () {},
            onLongPressHint: 'foo',
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.byType(SliverSemantics)),
      matchesSemantics(hasLongPressAction: true, onLongPressHint: 'foo'),
    );
    semantics.dispose();
  });

  testWidgets('supports CustomSemanticsActions', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
              const CustomSemanticsAction(label: 'foo'): () {},
              const CustomSemanticsAction(label: 'bar'): () {},
            },
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.byType(SliverSemantics)),
      matchesSemantics(
        customActions: <CustomSemanticsAction>[
          const CustomSemanticsAction(label: 'bar'),
          const CustomSemanticsAction(label: 'foo'),
        ],
      ),
    );
    semantics.dispose();
  });

  testWidgets('increased/decreased values are annotated', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            value: '10s',
            increasedValue: '11s',
            decreasedValue: '9s',
            onIncrease: () => () {},
            onDecrease: () => () {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  actions: SemanticsAction.increase.index | SemanticsAction.decrease.index,
                  textDirection: TextDirection.ltr,
                  value: '10s',
                  increasedValue: '11s',
                  decreasedValue: '9s',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );

    semantics.dispose();
  });

  testWidgets('excludeSemantics ignores children', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            label: 'label',
            excludeSemantics: true,
            textDirection: TextDirection.ltr,
            sliver: SliverSemantics(
              label: 'other label',
              textDirection: TextDirection.ltr,
              sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
            ),
          ),
        ],
      ),
    );

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  label: 'label',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );
    semantics.dispose();
  });

  testWidgets('slivers built in a widget tree are sorted properly', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    var semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.semanticsOwner!.addListener(() {
      semanticsUpdateCount += 1;
    });
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            sortKey: const CustomSortKey(0.0),
            explicitChildNodes: true,
            sliver: SliverMainAxisGroup(
              slivers: <Widget>[
                SliverSemantics(
                  sortKey: const CustomSortKey(3.0),
                  sliver: const SliverToBoxAdapter(child: Text('Label 1')),
                ),
                SliverSemantics(
                  sortKey: const CustomSortKey(2.0),
                  sliver: const SliverToBoxAdapter(child: Text('Label 2')),
                ),
                SliverSemantics(
                  sortKey: const CustomSortKey(1.0),
                  explicitChildNodes: true,
                  sliver: SliverCrossAxisGroup(
                    slivers: <Widget>[
                      SliverSemantics(
                        sortKey: const OrdinalSortKey(3.0),
                        sliver: const SliverToBoxAdapter(child: Text('Label 3')),
                      ),
                      SliverSemantics(
                        sortKey: const OrdinalSortKey(2.0),
                        sliver: const SliverToBoxAdapter(child: Text('Label 4')),
                      ),
                      SliverSemantics(
                        sortKey: const OrdinalSortKey(1.0),
                        sliver: const SliverToBoxAdapter(child: Text('Label 5')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    expect(semanticsUpdateCount, 1);
    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          id: 1,
          children: <TestSemantics>[
            TestSemantics(
              id: 9,
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(
                  id: 2,
                  tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 5,
                      children: <TestSemantics>[
                        TestSemantics(id: 8, label: 'Label 5', textDirection: TextDirection.ltr),
                        TestSemantics(id: 7, label: 'Label 4', textDirection: TextDirection.ltr),
                        TestSemantics(id: 6, label: 'Label 3', textDirection: TextDirection.ltr),
                      ],
                    ),
                    TestSemantics(id: 4, label: 'Label 2', textDirection: TextDirection.ltr),
                    TestSemantics(id: 3, label: 'Label 1', textDirection: TextDirection.ltr),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(semantics, hasSemantics(expectedSemantics, ignoreRect: true, ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('Semantics widgets built with explicit sort orders are sorted properly', (
    WidgetTester tester,
  ) async {
    final semantics = SemanticsTester(tester);
    var semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.semanticsOwner!.addListener(() {
      semanticsUpdateCount += 1;
    });
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverCrossAxisGroup(
            slivers: <Widget>[
              SliverSemantics(
                sortKey: const CustomSortKey(3.0),
                sliver: const SliverToBoxAdapter(child: Text('Label 1')),
              ),
              SliverSemantics(
                sortKey: const CustomSortKey(1.0),
                sliver: const SliverToBoxAdapter(child: Text('Label 2')),
              ),
              SliverSemantics(
                sortKey: const CustomSortKey(2.0),
                sliver: const SliverToBoxAdapter(child: Text('Label 3')),
              ),
            ],
          ),
        ],
      ),
    );
    expect(semanticsUpdateCount, 1);
    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          id: 1,
          children: <TestSemantics>[
            TestSemantics(
              id: 5,
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(id: 3, label: 'Label 2', textDirection: TextDirection.ltr),
                TestSemantics(id: 4, label: 'Label 3', textDirection: TextDirection.ltr),
                TestSemantics(id: 2, label: 'Label 1', textDirection: TextDirection.ltr),
              ],
            ),
          ],
        ),
      ],
    );
    expect(semantics, hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true));

    semantics.dispose();
  });

  testWidgets('slivers without sort orders are sorted properly', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    var semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.semanticsOwner!.addListener(() {
      semanticsUpdateCount += 1;
    });
    await tester.pumpWidget(
      boilerPlate(
        slivers: const <Widget>[
          SliverMainAxisGroup(
            slivers: <Widget>[
              SliverToBoxAdapter(child: Text('Label 1')),
              SliverToBoxAdapter(child: Text('Label 2')),
              SliverCrossAxisGroup(
                slivers: <Widget>[
                  SliverToBoxAdapter(child: Text('Label 3')),
                  SliverToBoxAdapter(child: Text('Label 4')),
                  SliverToBoxAdapter(child: Text('Label 5')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    expect(semanticsUpdateCount, 1);
    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(label: 'Label 1', textDirection: TextDirection.ltr),
                TestSemantics(label: 'Label 2', textDirection: TextDirection.ltr),
                TestSemantics(label: 'Label 3', textDirection: TextDirection.ltr),
                TestSemantics(label: 'Label 4', textDirection: TextDirection.ltr),
                TestSemantics(label: 'Label 5', textDirection: TextDirection.ltr),
              ],
            ),
          ],
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );

    semantics.dispose();
  });

  testWidgets('Can change handlers', (WidgetTester tester) async {
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            onTap: () {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasTapAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            onDismiss: () {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasDismissAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            onLongPress: () {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasLongPressAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            onScrollLeft: () {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasScrollLeftAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            onScrollRight: () {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasScrollRightAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            onScrollUp: () {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasScrollUpAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            onScrollDown: () {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasScrollDownAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            onIncrease: () {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasIncreaseAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            onDecrease: () {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasDecreaseAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            onCopy: () {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasCopyAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            onCut: () {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasCutAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            onPaste: () {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasPasteAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            onSetSelection: (TextSelection _) {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasSetSelectionAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            onDidGainAccessibilityFocus: () {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(
        label: 'foo',
        hasDidGainAccessibilityFocusAction: true,
        textDirection: TextDirection.ltr,
      ),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            onDidLoseAccessibilityFocus: () {},
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(
        label: 'foo',
        hasDidLoseAccessibilityFocusAction: true,
        textDirection: TextDirection.ltr,
      ),
    );

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            label: 'foo',
            textDirection: TextDirection.ltr,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );
  });

  testWidgets('blocking user interaction works on explicit child node', (
    WidgetTester tester,
  ) async {
    final key1 = UniqueKey();
    final key2 = UniqueKey();
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            blockUserActions: true,
            explicitChildNodes: true,
            sliver: SliverMainAxisGroup(
              slivers: <Widget>[
                SliverSemantics(
                  key: key1,
                  label: 'label1',
                  onTap: () {},
                  sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                ),
                SliverSemantics(
                  key: key2,
                  label: 'label2',
                  onTap: () {},
                  sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    expect(
      tester.getSemantics(find.byKey(key1)),
      // Tap action is blocked.
      matchesSemantics(label: 'label1'),
    );
    expect(
      tester.getSemantics(find.byKey(key2)),
      // Tap action is blocked.
      matchesSemantics(label: 'label2'),
    );
  });

  testWidgets('blocking user interaction works on explicit child node with Semantics widget', (
    WidgetTester tester,
  ) async {
    final key1 = UniqueKey();
    final key2 = UniqueKey();
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            blockUserActions: true,
            explicitChildNodes: true,
            sliver: SliverList.list(
              children: <Widget>[
                Semantics(
                  key: key1,
                  label: 'label1',
                  onTap: () {},
                  child: const SizedBox(height: 10),
                ),
                Semantics(
                  key: key2,
                  label: 'label2',
                  onTap: () {},
                  child: const SizedBox(height: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    expect(
      tester.getSemantics(find.byKey(key1)),
      // Tap action is blocked.
      matchesSemantics(label: 'label1'),
    );
    expect(
      tester.getSemantics(find.byKey(key2)),
      // Tap action is blocked.
      matchesSemantics(label: 'label2'),
    );
  });

  testWidgets('blocking user interaction on a merged child', (WidgetTester tester) async {
    final key = UniqueKey();
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            key: key,
            container: true,
            sliver: SliverMainAxisGroup(
              slivers: <Widget>[
                SliverSemantics(
                  blockUserActions: true,
                  label: 'label1',
                  onTap: () {},
                  sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                ),
                SliverSemantics(
                  label: 'label2',
                  onLongPress: () {},
                  sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    expect(
      tester.getSemantics(find.byKey(key)),
      // Tap action in label1 is blocked.
      matchesSemantics(label: 'label1\nlabel2', hasLongPressAction: true),
    );
  });

  testWidgets('blocking user interaction on a merged child with Semantics widget', (
    WidgetTester tester,
  ) async {
    final key = UniqueKey();
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            key: key,
            container: true,
            sliver: SliverList.list(
              children: <Widget>[
                Semantics(
                  blockUserActions: true,
                  label: 'label1',
                  onTap: () {},
                  child: const SizedBox(height: 10),
                ),
                Semantics(label: 'label2', onLongPress: () {}, child: const SizedBox(height: 10)),
              ],
            ),
          ),
        ],
      ),
    );
    expect(
      tester.getSemantics(find.byKey(key)),
      // Tap action in label1 is blocked.
      matchesSemantics(label: 'label1\nlabel2', hasLongPressAction: true),
    );
  });

  testWidgets('does not merge conflicting actions even if one of them is blocked', (
    WidgetTester tester,
  ) async {
    final key = UniqueKey();
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            key: key,
            container: true,
            sliver: SliverMainAxisGroup(
              slivers: <Widget>[
                SliverSemantics(
                  blockUserActions: true,
                  label: 'label1',
                  onTap: () {},
                  sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                ),
                SliverSemantics(
                  label: 'label2',
                  onTap: () {},
                  sliver: const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final SemanticsNode node = tester.getSemantics(find.byKey(key));
    expect(
      node,
      matchesSemantics(
        children: <Matcher>[
          containsSemantics(label: 'label1'),
          containsSemantics(label: 'label2'),
        ],
      ),
    );
  });

  testWidgets(
    'does not merge conflicting actions even if one of them is blocked with Semantics widget',
    (WidgetTester tester) async {
      final key = UniqueKey();
      await tester.pumpWidget(
        boilerPlate(
          slivers: <Widget>[
            SliverSemantics(
              key: key,
              container: true,
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: <Widget>[
                    Semantics(
                      blockUserActions: true,
                      label: 'label1',
                      onTap: () {},
                      child: const SizedBox(width: 10, height: 10),
                    ),
                    Semantics(
                      label: 'label2',
                      onTap: () {},
                      child: const SizedBox(width: 10, height: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
      final SemanticsNode node = tester.getSemantics(find.byKey(key));
      expect(
        node,
        matchesSemantics(
          children: <Matcher>[
            containsSemantics(label: 'label1'),
            containsSemantics(label: 'label2'),
          ],
        ),
      );
    },
  );

  testWidgets('RenderSliverSemanticsAnnotations provides validation result', (
    WidgetTester tester,
  ) async {
    final semantics = SemanticsTester(tester);

    Future<SemanticsConfiguration> pumpValidationResult(SemanticsValidationResult result) async {
      final key = ValueKey<String>('validation-$result');
      await tester.pumpWidget(
        boilerPlate(
          slivers: <Widget>[
            SliverSemantics(
              key: key,
              validationResult: result,
              sliver: SliverToBoxAdapter(
                child: Text('Validation result $result', textDirection: TextDirection.ltr),
              ),
            ),
          ],
        ),
      );
      final RenderSliverSemanticsAnnotations object = tester
          .renderObject<RenderSliverSemanticsAnnotations>(find.byKey(key));
      final config = SemanticsConfiguration();
      object.describeSemanticsConfiguration(config);
      return config;
    }

    final SemanticsConfiguration noneResult = await pumpValidationResult(
      SemanticsValidationResult.none,
    );
    expect(noneResult.validationResult, SemanticsValidationResult.none);

    final SemanticsConfiguration validResult = await pumpValidationResult(
      SemanticsValidationResult.valid,
    );
    expect(validResult.validationResult, SemanticsValidationResult.valid);

    final SemanticsConfiguration invalidResult = await pumpValidationResult(
      SemanticsValidationResult.invalid,
    );
    expect(invalidResult.validationResult, SemanticsValidationResult.invalid);

    semantics.dispose();
  });

  testWidgets('validation result precedence', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    Future<void> expectValidationResult({
      required SemanticsValidationResult outer,
      required SemanticsValidationResult inner,
      required SemanticsValidationResult expected,
    }) async {
      const key = ValueKey<String>('validated-widget');
      await tester.pumpWidget(
        boilerPlate(
          slivers: <Widget>[
            SliverSemantics(
              validationResult: outer,
              sliver: SliverSemantics(
                validationResult: inner,
                sliver: SliverToBoxAdapter(
                  child: Text(
                    key: key,
                    'Outer = $outer; inner = $inner',
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      final SemanticsNode result = tester.getSemantics(find.byKey(key));
      expect(
        result,
        containsSemantics(label: 'Outer = $outer; inner = $inner', validationResult: expected),
      );
    }

    // Outer is none.
    await expectValidationResult(
      outer: SemanticsValidationResult.none,
      inner: SemanticsValidationResult.none,
      expected: SemanticsValidationResult.none,
    );
    await expectValidationResult(
      outer: SemanticsValidationResult.none,
      inner: SemanticsValidationResult.valid,
      expected: SemanticsValidationResult.valid,
    );
    await expectValidationResult(
      outer: SemanticsValidationResult.none,
      inner: SemanticsValidationResult.invalid,
      expected: SemanticsValidationResult.invalid,
    );

    // Outer is valid.
    await expectValidationResult(
      outer: SemanticsValidationResult.valid,
      inner: SemanticsValidationResult.none,
      expected: SemanticsValidationResult.valid,
    );
    await expectValidationResult(
      outer: SemanticsValidationResult.valid,
      inner: SemanticsValidationResult.valid,
      expected: SemanticsValidationResult.valid,
    );
    await expectValidationResult(
      outer: SemanticsValidationResult.valid,
      inner: SemanticsValidationResult.invalid,
      expected: SemanticsValidationResult.invalid,
    );

    // Outer is invalid.
    await expectValidationResult(
      outer: SemanticsValidationResult.invalid,
      inner: SemanticsValidationResult.none,
      expected: SemanticsValidationResult.invalid,
    );
    await expectValidationResult(
      outer: SemanticsValidationResult.invalid,
      inner: SemanticsValidationResult.valid,
      expected: SemanticsValidationResult.invalid,
    );
    await expectValidationResult(
      outer: SemanticsValidationResult.invalid,
      inner: SemanticsValidationResult.invalid,
      expected: SemanticsValidationResult.invalid,
    );

    semantics.dispose();
  });

  testWidgets('supports heading levels', (WidgetTester tester) async {
    // Default: not a heading.
    expect(
      SliverSemantics(
        sliver: const SliverToBoxAdapter(child: Text('dummy text')),
      ).properties.headingLevel,
      isNull,
    );

    // Headings level 1-6.
    for (var level = 1; level <= 6; level++) {
      final semantics = SliverSemantics(
        headingLevel: level,
        sliver: const SliverToBoxAdapter(child: Text('dummy text')),
      );
      expect(semantics.properties.headingLevel, level);
    }

    // Invalid heading levels.
    for (final badLevel in const <int>[-1, 0, 7, 8, 9]) {
      expect(
        () => SliverSemantics(
          headingLevel: badLevel,
          sliver: const SliverToBoxAdapter(child: Text('dummy text')),
        ),
        throwsAssertionError,
      );
    }
  });

  testWidgets('parent heading level takes precedence when it absorbs a child', (
    WidgetTester tester,
  ) async {
    final semantics = SemanticsTester(tester);

    Future<SemanticsConfiguration> pumpHeading(int? level) async {
      final key = ValueKey<String>('heading-$level');
      await tester.pumpWidget(
        boilerPlate(
          slivers: <Widget>[
            SliverSemantics(
              key: key,
              headingLevel: level,
              sliver: SliverToBoxAdapter(
                child: Text('Heading level $level', textDirection: TextDirection.ltr),
              ),
            ),
          ],
        ),
      );
      final RenderSliverSemanticsAnnotations object = tester
          .renderObject<RenderSliverSemanticsAnnotations>(find.byKey(key));
      final config = SemanticsConfiguration();
      object.describeSemanticsConfiguration(config);
      return config;
    }

    // Tuples contain (parent level, child level, expected combined level).
    final scenarios = <(int, int, int)>[
      // Case: neither are headings
      (0, 0, 0), // expect not a heading
      // Case: parent not a heading, child always wins.
      (0, 1, 1),
      (0, 2, 2),

      // Case: child not a heading, parent always wins.
      (1, 0, 1),
      (2, 0, 2),

      // Case: child heading level higher, parent still wins.
      (3, 2, 3),
      (4, 1, 4),

      // Case: parent heading level higher, parent still wins.
      (2, 3, 2),
      (1, 5, 1),
    ];

    for (final scenario in scenarios) {
      final int parentLevel = scenario.$1;
      final int childLevel = scenario.$2;
      final int resultLevel = scenario.$3;

      final SemanticsConfiguration parent = await pumpHeading(
        parentLevel == 0 ? null : parentLevel,
      );
      final child = SemanticsConfiguration()..headingLevel = childLevel;
      parent.absorb(child);
      expect(
        reason:
            'parent heading level is $parentLevel, '
            'child heading level is $childLevel, '
            'expecting $resultLevel.',
        parent.headingLevel,
        resultLevel,
      );
    }

    semantics.dispose();
  });

  testWidgets('applies heading semantics to semantics tree', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverMainAxisGroup(
            slivers: <Widget>[
              for (int level = 1; level <= 6; level++)
                SliverSemantics(
                  key: ValueKey<String>('heading-$level'),
                  headingLevel: level,
                  sliver: SliverToBoxAdapter(child: Text('Heading level $level')),
                ),
              const SliverToBoxAdapter(child: Text('This is not a heading')),
            ],
          ),
        ],
      ),
    );

    for (var level = 1; level <= 6; level++) {
      final key = ValueKey<String>('heading-$level');
      final SemanticsNode node = tester.getSemantics(find.byKey(key));
      expect('$node', contains('headingLevel: $level'));
    }

    final SemanticsNode notHeading = tester.getSemantics(find.text('This is not a heading'));
    expect(notHeading, isNot(contains('headingLevel')));

    semantics.dispose();
  });

  testWidgets('sliver with zero transform gets dropped', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/110671.
    // Construct a widget tree that will end up with a fitted box that applies
    // a zero transform because it does not actually draw its children.
    // Assert that this subtree gets dropped (the root node has no children).
    final semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          const SliverMainAxisGroup(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 0,
                  width: 500,
                  child: FittedBox(
                    child: SizedBox(
                      height: 55,
                      width: 266,
                      child: SingleChildScrollView(child: Column()),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling]),
      ],
    );
    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );

    final SemanticsNode node = RendererBinding.instance.renderView.debugSemantics!;

    expect(node.transform, null); // Make sure the zero transform didn't end up on the root somehow.
    expect(node.childrenCount, 1);
    semantics.dispose();
  });

  testWidgets('slivers that are transformed are sorted properly', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    var semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.semanticsOwner!.addListener(() {
      semanticsUpdateCount += 1;
    });
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverMainAxisGroup(
            slivers: <Widget>[
              const SliverToBoxAdapter(child: Text('Label 1')),
              const SliverToBoxAdapter(child: Text('Label 2')),
              SliverToBoxAdapter(
                child: Transform.rotate(
                  angle: pi / 2.0,
                  child: const Row(
                    children: <Widget>[Text('Label 3'), Text('Label 4'), Text('Label 5')],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    expect(semanticsUpdateCount, 1);
    // Label 3 is off-screen so it gets dropped.
    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
              children: <TestSemantics>[
                TestSemantics(label: 'Label 1', textDirection: TextDirection.ltr),
                TestSemantics(label: 'Label 2', textDirection: TextDirection.ltr),
                TestSemantics(
                  flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                  label: 'Label 4',
                  textDirection: TextDirection.ltr,
                ),
                TestSemantics(
                  flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                  label: 'Label 5',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true),
    );

    semantics.dispose();
  });
}

class CustomSortKey extends OrdinalSortKey {
  const CustomSortKey(super.order, {super.name});
}
