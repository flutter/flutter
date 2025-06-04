// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

    final TestSemantics expectedSemantics = TestSemantics.root(
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

  testWidgets('Detach and reattach assert', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
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

    TestSemantics expectedSemantics = TestSemantics.root(
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
    final SemanticsTester semantics = SemanticsTester(tester);

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
    final SemanticsTester semantics = SemanticsTester(tester);

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
    final SemanticsTester semantics = SemanticsTester(tester);

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

    final TestSemantics expectedSemantics = TestSemantics.root(
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
    final SemanticsTester semantics = SemanticsTester(tester);

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

    final TestSemantics expectedSemantics = TestSemantics.root(
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
    final SemanticsTester semantics = SemanticsTester(tester);

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

    final TestSemantics expectedSemantics = TestSemantics.root(
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
    final SemanticsTester semantics = SemanticsTester(tester);

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

    final TestSemantics expectedSemantics = TestSemantics.root(
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
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                Semantics(hint: 'hint one', child: const SizedBox(height: 10.0)),
                Semantics(hint: 'hint two', child: const SizedBox(height: 10.0)),
              ]),
            ),
          ),
        ],
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
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
    final SemanticsTester semantics = SemanticsTester(tester);

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

    final TestSemantics expectedSemantics = TestSemantics.root(
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
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                Semantics(value: 'value one', child: const SizedBox(height: 10.0)),
                Semantics(value: 'value two', child: const SizedBox(height: 10.0)),
              ]),
            ),
          ),
        ],
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
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
    final SemanticsTester semantics = SemanticsTester(tester);

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

    final TestSemantics expectedSemantics = TestSemantics.root(
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
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                Semantics(hint: 'hint', child: const SizedBox(height: 10.0)),
                Semantics(value: 'value', child: const SizedBox(height: 10.0)),
              ]),
            ),
          ),
        ],
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
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
    final SemanticsTester semantics = SemanticsTester(tester);

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

    final TestSemantics expectedSemantics = TestSemantics.root(
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
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            container: true,
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                Semantics(container: true, child: const Text('child 1')),
                Semantics(container: true, child: const Text('child 2')),
              ]),
            ),
          ),
        ],
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
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
    final SemanticsTester semantics = SemanticsTester(tester);

    final List<SemanticsAction> performedActions = <SemanticsAction>[];

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
            onMoveCursorForwardByCharacter:
                (bool _) => performedActions.add(SemanticsAction.moveCursorForwardByCharacter),
            onMoveCursorBackwardByCharacter:
                (bool _) => performedActions.add(SemanticsAction.moveCursorBackwardByCharacter),
            onSetSelection: (TextSelection _) => performedActions.add(SemanticsAction.setSelection),
            onSetText: (String _) => performedActions.add(SemanticsAction.setText),
            onDidGainAccessibilityFocus:
                () => performedActions.add(SemanticsAction.didGainAccessibilityFocus),
            onDidLoseAccessibilityFocus:
                () => performedActions.add(SemanticsAction.didLoseAccessibilityFocus),
            onFocus: () => performedActions.add(SemanticsAction.focus),
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

    final Set<SemanticsAction> allActions =
        SemanticsAction.values.toSet()
          ..remove(SemanticsAction.moveCursorForwardByWord)
          ..remove(SemanticsAction.moveCursorBackwardByWord)
          ..remove(SemanticsAction.customAction) // customAction is not user-exposed.
          ..remove(SemanticsAction.showOnScreen) // showOnScreen is not user-exposed
          ..remove(SemanticsAction.scrollToOffset); // scrollToOffset is not user-exposed

    const int expectedId = 2;
    final TestSemantics expectedSemantics = TestSemantics.root(
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
    int expectedLength = 1;
    for (final SemanticsAction action in allActions) {
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
          semanticsOwner.performAction(expectedId, action);
      }
      expect(performedActions.length, expectedLength);
      expect(performedActions.last, action);
      expectedLength += 1;
    }

    semantics.dispose();
  });

  testWidgets('supports all flags', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    // Checked state and toggled state are mutually exclusive.
    await tester.pumpWidget(
      boilerPlate(
        slivers: <Widget>[
          SliverSemantics(
            key: const Key('a'),
            container: true,
            explicitChildNodes: true,
            // flags
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

    TestSemantics expectedSemantics = TestSemantics.root(
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
            // flags
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
    final SemanticsTester semantics = SemanticsTester(tester);

    final TestSemantics expectedSemantics = TestSemantics.root(
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
    final SemanticsTester semantics = SemanticsTester(tester);
    int semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.semanticsOwner!.addListener(() {
      semanticsUpdateCount += 1;
    });

    final List<String> performedActions = <String>[];

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

    const int expectedId = 2;
    final TestSemantics expectedSemantics = TestSemantics.root(
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

    // Updating existing handler should not trigger semantics update
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

    // Adding a handler works
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

    final TestSemantics expectedSemanticsWithLongPress = TestSemantics.root(
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

    // Removing a handler works
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
}
