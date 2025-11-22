// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('Semantics shutdown and restart', (WidgetTester tester) async {
    SemanticsTester? semantics = SemanticsTester(tester);

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(label: 'test1', textDirection: TextDirection.ltr),
      ],
    );

    await tester.pumpWidget(
      Semantics(label: 'test1', textDirection: TextDirection.ltr, child: Container()),
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true),
    );

    semantics.dispose();
    semantics = null;

    expect(tester.binding.hasScheduledFrame, isFalse);
    semantics = SemanticsTester(tester);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true),
    );
    semantics.dispose();
  }, semanticsEnabled: false);

  testWidgets('Semantics tag only applies to immediate child', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          children: <Widget>[
            SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Container(padding: const EdgeInsets.only(top: 20.0)),
                  const Text('label'),
                ],
              ),
            ),
          ],
        ),
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

  testWidgets('Semantics tooltip', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(tooltip: 'test1', textDirection: TextDirection.ltr),
      ],
    );

    await tester.pumpWidget(Semantics(tooltip: 'test1', textDirection: TextDirection.ltr));

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true),
    );
    semantics.dispose();
  });

  testWidgets('Detach and reattach assert', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final GlobalKey key = GlobalKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          label: 'test1',
          child: Semantics(key: key, container: true, label: 'test2a', child: Container()),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              label: 'test1',
              children: <TestSemantics>[TestSemantics(label: 'test2a')],
            ),
          ],
        ),
        ignoreId: true,
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          label: 'test1',
          child: Semantics(
            container: true,
            label: 'middle',
            child: Semantics(key: key, container: true, label: 'test2b', child: Container()),
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
        ignoreId: true,
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('Semantics and Directionality - RTL', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Semantics(label: 'test1', child: Container()),
      ),
    );

    expect(semantics, includesNodeWith(label: 'test1', textDirection: TextDirection.rtl));
    semantics.dispose();
  });

  testWidgets('Semantics and Directionality - LTR', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(label: 'test1', child: Container()),
      ),
    );

    expect(semantics, includesNodeWith(label: 'test1', textDirection: TextDirection.ltr));
    semantics.dispose();
  });

  testWidgets('Semantics and Directionality - cannot override RTL with LTR', (
    WidgetTester tester,
  ) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(label: 'test1', textDirection: TextDirection.ltr),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Semantics(label: 'test1', textDirection: TextDirection.ltr, child: Container()),
      ),
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true),
    );
    semantics.dispose();
  });

  testWidgets('Semantics and Directionality - cannot override LTR with RTL', (
    WidgetTester tester,
  ) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(label: 'test1', textDirection: TextDirection.rtl),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(label: 'test1', textDirection: TextDirection.rtl, child: Container()),
      ),
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true),
    );
    semantics.dispose();
  });

  testWidgets('Semantics label and hint', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(label: 'label', hint: 'hint', value: 'value', child: Container()),
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          label: 'label',
          hint: 'hint',
          value: 'value',
          textDirection: TextDirection.ltr,
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true),
    );
    semantics.dispose();
  });

  testWidgets('Semantics hints can merge', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          container: true,
          child: Column(
            children: <Widget>[
              Semantics(hint: 'hint one'),
              Semantics(hint: 'hint two'),
            ],
          ),
        ),
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(hint: 'hint one\nhint two', textDirection: TextDirection.ltr),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true),
    );
    semantics.dispose();
  });

  testWidgets('Semantics values do not merge', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          container: true,
          child: Column(
            children: <Widget>[
              Semantics(value: 'value one', child: const SizedBox(height: 10.0, width: 10.0)),
              Semantics(value: 'value two', child: const SizedBox(height: 10.0, width: 10.0)),
            ],
          ),
        ),
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(value: 'value one', textDirection: TextDirection.ltr),
            TestSemantics(value: 'value two', textDirection: TextDirection.ltr),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true),
    );
    semantics.dispose();
  });

  testWidgets('Semantics value and hint can merge', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          container: true,
          child: Column(
            children: <Widget>[
              Semantics(hint: 'hint'),
              Semantics(value: 'value'),
            ],
          ),
        ),
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(hint: 'hint', value: 'value', textDirection: TextDirection.ltr),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true),
    );
    semantics.dispose();
  });

  testWidgets('Semantics tagForChildren works', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          container: true,
          tagForChildren: const SemanticsTag('custom tag'),
          child: Column(
            children: <Widget>[
              Semantics(container: true, child: const Text('child 1')),
              Semantics(container: true, child: const Text('child 2')),
            ],
          ),
        ),
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(
              label: 'child 1',
              tags: <SemanticsTag>[const SemanticsTag('custom tag')],
              textDirection: TextDirection.ltr,
            ),
            TestSemantics(
              label: 'child 2',
              tags: <SemanticsTag>[const SemanticsTag('custom tag')],
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ],
    );

    expect(
      semantics,
      hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true),
    );
    semantics.dispose();
  });

  testWidgets('Semantics widget supports all actions', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final List<SemanticsAction> performedActions = <SemanticsAction>[];

    await tester.pumpWidget(
      Semantics(
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
      ),
    );

    final Set<SemanticsAction> allActions = SemanticsAction.values.toSet()
      ..remove(SemanticsAction.moveCursorForwardByWord)
      ..remove(SemanticsAction.moveCursorBackwardByWord)
      ..remove(SemanticsAction.customAction) // customAction is not user-exposed.
      ..remove(SemanticsAction.showOnScreen) // showOnScreen is not user-exposed
      ..remove(SemanticsAction.scrollToOffset); // scrollToOffset is not user-exposed

    const int expectedId = 1;
    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: expectedId,
          rect: TestSemantics.fullScreen,
          actions: allActions.fold<int>(
            0,
            (int previous, SemanticsAction action) => previous | action.index,
          ),
        ),
      ],
    );
    expect(semantics, hasSemantics(expectedSemantics));

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

  testWidgets('Semantics widget supports all flags', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    // Checked state and toggled state are mutually exclusive.
    // Focused and isAccessibilityFocusBlocked are mutually exclusive.
    await tester.pumpWidget(
      Semantics(
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
      ),
    );
    SemanticsFlags flags = SemanticsFlags(
      isChecked: CheckedState.isTrue,
      isSelected: Tristate.isTrue,
      isEnabled: Tristate.isTrue,
      isExpanded: Tristate.isTrue,
      isRequired: Tristate.isTrue,
      isFocused: Tristate.isTrue,
      isButton: true,
      isTextField: true,
      isInMutuallyExclusiveGroup: true,
      isObscured: true,
      scopesRoute: true,
      namesRoute: true,
      isHidden: true,
      isImage: true,
      isHeader: true,
      isLiveRegion: true,
      isMultiline: true,
      isReadOnly: true,
      isLink: true,
      isSlider: true,
      isKeyboardKey: true,
    );

    TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(rect: TestSemantics.fullScreen, flags: flags),
      ],
    );
    expect(semantics, hasSemantics(expectedSemantics, ignoreId: true));

    await tester.pumpWidget(Semantics(key: const Key('b'), container: true, scopesRoute: false));
    expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(rect: TestSemantics.fullScreen, flags: <SemanticsFlag>[]),
      ],
    );
    expect(semantics, hasSemantics(expectedSemantics, ignoreId: true));

    await tester.pumpWidget(Semantics(key: const Key('c'), toggled: true));

    expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          rect: TestSemantics.fullScreen,
          flags: <SemanticsFlag>[SemanticsFlag.hasToggledState, SemanticsFlag.isToggled],
        ),
      ],
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreId: true));

    await tester.pumpWidget(
      Semantics(
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
      ),
    );
    flags = flags.copyWith(isChecked: CheckedState.mixed);
    semantics.dispose();
    expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(rect: TestSemantics.fullScreen, flags: flags),
      ],
    );
    expect(semantics, hasSemantics(expectedSemantics, ignoreId: true));
  });

  testWidgets('Actions can be replaced without triggering semantics update', (
    WidgetTester tester,
  ) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    int semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.semanticsOwner!.addListener(() {
      semanticsUpdateCount += 1;
    });

    final List<String> performedActions = <String>[];

    await tester.pumpWidget(Semantics(container: true, onTap: () => performedActions.add('first')));

    const int expectedId = 1;
    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: expectedId,
          rect: TestSemantics.fullScreen,
          actions: SemanticsAction.tap.index,
        ),
      ],
    );

    final SemanticsOwner semanticsOwner = tester.binding.pipelineOwner.semanticsOwner!;

    expect(semantics, hasSemantics(expectedSemantics));
    semanticsOwner.performAction(expectedId, SemanticsAction.tap);
    expect(semanticsUpdateCount, 1);
    expect(performedActions, <String>['first']);

    semanticsUpdateCount = 0;
    performedActions.clear();

    // Updating existing handler should not trigger semantics update
    await tester.pumpWidget(
      Semantics(container: true, onTap: () => performedActions.add('second')),
    );

    expect(semantics, hasSemantics(expectedSemantics));
    semanticsOwner.performAction(expectedId, SemanticsAction.tap);
    expect(semanticsUpdateCount, 0);
    expect(performedActions, <String>['second']);

    semanticsUpdateCount = 0;
    performedActions.clear();

    // Adding a handler works
    await tester.pumpWidget(
      Semantics(
        container: true,
        onTap: () => performedActions.add('second'),
        onLongPress: () => performedActions.add('longPress'),
      ),
    );

    final TestSemantics expectedSemanticsWithLongPress = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: expectedId,
          rect: TestSemantics.fullScreen,
          actions: SemanticsAction.tap.index | SemanticsAction.longPress.index,
        ),
      ],
    );

    expect(semantics, hasSemantics(expectedSemanticsWithLongPress));
    semanticsOwner.performAction(expectedId, SemanticsAction.longPress);
    expect(semanticsUpdateCount, 1);
    expect(performedActions, <String>['longPress']);

    semanticsUpdateCount = 0;
    performedActions.clear();

    // Removing a handler works
    await tester.pumpWidget(
      Semantics(container: true, onTap: () => performedActions.add('second')),
    );

    expect(semantics, hasSemantics(expectedSemantics));
    expect(semanticsUpdateCount, 1);

    semantics.dispose();
  });

  testWidgets('onTapHint and onLongPressHint create custom actions', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(Semantics(container: true, onTap: () {}, onTapHint: 'test'));

    expect(
      tester.getSemantics(find.byType(Semantics)),
      matchesSemantics(hasTapAction: true, onTapHint: 'test'),
    );

    await tester.pumpWidget(Semantics(container: true, onLongPress: () {}, onLongPressHint: 'foo'));

    expect(
      tester.getSemantics(find.byType(Semantics)),
      matchesSemantics(hasLongPressAction: true, onLongPressHint: 'foo'),
    );
    semantics.dispose();
  });

  testWidgets('CustomSemanticsActions can be added to a Semantics widget', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      Semantics(
        container: true,
        customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
          const CustomSemanticsAction(label: 'foo'): () {},
          const CustomSemanticsAction(label: 'bar'): () {},
        },
      ),
    );

    expect(
      tester.getSemantics(find.byType(Semantics)),
      matchesSemantics(
        customActions: <CustomSemanticsAction>[
          const CustomSemanticsAction(label: 'bar'),
          const CustomSemanticsAction(label: 'foo'),
        ],
      ),
    );
    semantics.dispose();
  });

  testWidgets('MergeSemantics merges CustomSemanticsActions from its children', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MergeSemantics(
        child: Column(
          children: <Widget>[
            Semantics(
              container: true,
              customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                const CustomSemanticsAction(label: 'action1'): () {},
              },
              child: const SizedBox(width: 10, height: 10),
            ),
            Semantics(
              container: true,
              customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                const CustomSemanticsAction(label: 'action2'): () {},
              },
              child: const SizedBox(width: 10, height: 10),
            ),
          ],
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(MergeSemantics)),
      matchesSemantics(
        customActions: <CustomSemanticsAction>[
          const CustomSemanticsAction(label: 'action1'),
          const CustomSemanticsAction(label: 'action2'),
        ],
      ),
    );

    semantics.dispose();
  });
  testWidgets('AccessiblityFocusBlockType.blockSubtree is applied to the subtree,', (
    WidgetTester tester,
  ) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Semantics(
        container: true,
        accessiblityFocusBlockType: AccessiblityFocusBlockType.blockSubtree,
        child: Column(
          children: <Widget>[
            // If the child set blockSubTreeAccessibilityFocus to `none`, it's still blcok because its parent.
            Semantics(
              container: true,
              accessiblityFocusBlockType: AccessiblityFocusBlockType.none,
              customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                const CustomSemanticsAction(label: 'action1'): () {},
              },
              child: const SizedBox(width: 10, height: 10),
            ),
            // If the child doesn't have a value for accessibilityFocusable, it will also use the parent data.
            Semantics(
              container: true,
              customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                const CustomSemanticsAction(label: 'action2'): () {},
              },
              child: const SizedBox(width: 10, height: 10),
            ),
          ],
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              flags: SemanticsFlags(isAccessibilityFocusBlocked: true),
              children: <TestSemantics>[
                TestSemantics(
                  id: 2,
                  flags: SemanticsFlags(isAccessibilityFocusBlocked: true),
                  actions: <SemanticsAction>[SemanticsAction.customAction],
                ),
                TestSemantics(
                  id: 3,
                  flags: SemanticsFlags(isAccessibilityFocusBlocked: true),
                  actions: <SemanticsAction>[SemanticsAction.customAction],
                ),
              ],
            ),
          ],
        ),
        ignoreTransform: true,
        ignoreRect: true,
        ignoreId: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('AccessiblityFocusBlockType.blockNode is not applied to the subtree,', (
    WidgetTester tester,
  ) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Semantics(
        container: true,
        accessiblityFocusBlockType: AccessiblityFocusBlockType.blockNode,
        child: Column(
          children: <Widget>[
            Semantics(
              container: true,
              accessiblityFocusBlockType: AccessiblityFocusBlockType.none,
              customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                const CustomSemanticsAction(label: 'action1'): () {},
              },
              child: const SizedBox(width: 10, height: 10),
            ),
            Semantics(
              container: true,
              customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                const CustomSemanticsAction(label: 'action2'): () {},
              },
              child: const SizedBox(width: 10, height: 10),
            ),
          ],
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              flags: SemanticsFlags(isAccessibilityFocusBlocked: true),
              children: <TestSemantics>[
                TestSemantics(id: 2, actions: <SemanticsAction>[SemanticsAction.customAction]),
                TestSemantics(id: 3, actions: <SemanticsAction>[SemanticsAction.customAction]),
              ],
            ),
          ],
        ),
        ignoreTransform: true,
        ignoreRect: true,
        ignoreId: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('MergeSemantics merges children with AccessiblityFocusBlockType.blockNode', (
    WidgetTester tester,
  ) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MergeSemantics(
          child: Column(
            children: <Widget>[
              Semantics(
                container: true,
                accessiblityFocusBlockType: AccessiblityFocusBlockType.blockNode,
                label: 'node1',
                child: const SizedBox(width: 10, height: 10),
              ),
              Semantics(
                container: true,
                label: 'node2',
                child: const SizedBox(width: 10, height: 10),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              flags: SemanticsFlags(isAccessibilityFocusBlocked: true),
              label: 'node1\nnode2',
            ),
          ],
        ),
        ignoreTransform: true,
        ignoreRect: true,
        ignoreId: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('AccessiblityFocusBlockType.blockNode doesnt merge up or merge down', (
    WidgetTester tester,
  ) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          label: 'root',
          child: Semantics(
            accessiblityFocusBlockType: AccessiblityFocusBlockType.blockNode,
            label: 'semantics label 0',
            child: Column(
              children: <Widget>[
                Semantics(label: 'semantics label 1', child: const SizedBox(width: 10, height: 10)),
                Semantics(label: 'semantics label 2', child: const SizedBox(width: 10, height: 10)),
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
            TestSemantics(
              id: 1,
              label: 'root',
              children: <TestSemantics>[
                TestSemantics(
                  id: 2,
                  label: 'semantics label 0',
                  flags: SemanticsFlags(isAccessibilityFocusBlocked: true),
                  children: <TestSemantics>[
                    TestSemantics(id: 3, label: 'semantics label 1'),
                    TestSemantics(id: 4, label: 'semantics label 2'),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreTransform: true,
        ignoreRect: true,
        ignoreId: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('AccessiblityFocusBlockType.blockSubtree doesnt merge up', (
    WidgetTester tester,
  ) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          label: 'root',
          child: Semantics(
            accessiblityFocusBlockType: AccessiblityFocusBlockType.blockSubtree,
            label: 'semantics label 0',
            child: Column(
              children: <Widget>[
                Semantics(label: 'semantics label 1', child: const SizedBox(width: 10, height: 10)),
                Semantics(label: 'semantics label 2', child: const SizedBox(width: 10, height: 10)),
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
            TestSemantics(
              id: 1,
              label: 'root',
              children: <TestSemantics>[
                TestSemantics(
                  id: 2,
                  label: 'semantics label 0\nsemantics label 1\nsemantics label 2',
                  flags: SemanticsFlags(isAccessibilityFocusBlocked: true),
                ),
              ],
            ),
          ],
        ),
        ignoreTransform: true,
        ignoreRect: true,
        ignoreId: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('semantics node cant be keyboard focusable but accessibility unfocusable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Semantics(
        container: true,
        accessiblityFocusBlockType: AccessiblityFocusBlockType.blockSubtree,
        focused: true,
        customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
          const CustomSemanticsAction(label: 'action1'): () {},
        },
        child: const SizedBox(width: 10, height: 10),
      ),
    );
    final Object? exception = tester.takeException();
    expect(exception, isFlutterError);
    final FlutterError error = exception! as FlutterError;
    expect(
      error.message,
      startsWith('A node that is keyboard focusable cannot be set to accessibility unfocusable'),
    );
  });

  testWidgets('Increased/decreased values are annotated', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          container: true,
          value: '10s',
          increasedValue: '11s',
          decreasedValue: '9s',
          onIncrease: () => () {},
          onDecrease: () => () {},
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              actions: SemanticsAction.increase.index | SemanticsAction.decrease.index,
              textDirection: TextDirection.ltr,
              value: '10s',
              increasedValue: '11s',
              decreasedValue: '9s',
            ),
          ],
        ),
        ignoreTransform: true,
        ignoreRect: true,
        ignoreId: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('Semantics widgets built in a widget tree are sorted properly', (
    WidgetTester tester,
  ) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    int semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.semanticsOwner!.addListener(() {
      semanticsUpdateCount += 1;
    });
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          sortKey: const CustomSortKey(0.0),
          explicitChildNodes: true,
          child: Column(
            children: <Widget>[
              Semantics(sortKey: const CustomSortKey(3.0), child: const Text('Label 1')),
              Semantics(sortKey: const CustomSortKey(2.0), child: const Text('Label 2')),
              Semantics(
                sortKey: const CustomSortKey(1.0),
                explicitChildNodes: true,
                child: Row(
                  children: <Widget>[
                    Semantics(sortKey: const OrdinalSortKey(3.0), child: const Text('Label 3')),
                    Semantics(sortKey: const OrdinalSortKey(2.0), child: const Text('Label 4')),
                    Semantics(sortKey: const OrdinalSortKey(1.0), child: const Text('Label 5')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(semanticsUpdateCount, 1);
    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              children: <TestSemantics>[
                TestSemantics(
                  id: 4,
                  children: <TestSemantics>[
                    TestSemantics(id: 7, label: r'Label 5', textDirection: TextDirection.ltr),
                    TestSemantics(id: 6, label: r'Label 4', textDirection: TextDirection.ltr),
                    TestSemantics(id: 5, label: r'Label 3', textDirection: TextDirection.ltr),
                  ],
                ),
                TestSemantics(id: 3, label: r'Label 2', textDirection: TextDirection.ltr),
                TestSemantics(id: 2, label: r'Label 1', textDirection: TextDirection.ltr),
              ],
            ),
          ],
        ),
        ignoreTransform: true,
        ignoreRect: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('Semantics widgets built with explicit sort orders are sorted properly', (
    WidgetTester tester,
  ) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    int semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.semanticsOwner!.addListener(() {
      semanticsUpdateCount += 1;
    });
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: <Widget>[
            Semantics(sortKey: const CustomSortKey(3.0), child: const Text('Label 1')),
            Semantics(sortKey: const CustomSortKey(1.0), child: const Text('Label 2')),
            Semantics(sortKey: const CustomSortKey(2.0), child: const Text('Label 3')),
          ],
        ),
      ),
    );
    expect(semanticsUpdateCount, 1);
    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(id: 2, label: r'Label 2', textDirection: TextDirection.ltr),
            TestSemantics(id: 3, label: r'Label 3', textDirection: TextDirection.ltr),
            TestSemantics(id: 1, label: r'Label 1', textDirection: TextDirection.ltr),
          ],
        ),
        ignoreTransform: true,
        ignoreRect: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('Semantics widgets without sort orders are sorted properly', (
    WidgetTester tester,
  ) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    int semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.semanticsOwner!.addListener(() {
      semanticsUpdateCount += 1;
    });
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            Text('Label 1'),
            Text('Label 2'),
            Row(children: <Widget>[Text('Label 3'), Text('Label 4'), Text('Label 5')]),
          ],
        ),
      ),
    );
    expect(semanticsUpdateCount, 1);
    expect(
      semantics,
      hasSemantics(
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(label: r'Label 1', textDirection: TextDirection.ltr),
            TestSemantics(label: r'Label 2', textDirection: TextDirection.ltr),
            TestSemantics(label: r'Label 3', textDirection: TextDirection.ltr),
            TestSemantics(label: r'Label 4', textDirection: TextDirection.ltr),
            TestSemantics(label: r'Label 5', textDirection: TextDirection.ltr),
          ],
        ),
        ignoreTransform: true,
        ignoreRect: true,
        ignoreId: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('Semantics widgets that are transformed are sorted properly', (
    WidgetTester tester,
  ) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    int semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.semanticsOwner!.addListener(() {
      semanticsUpdateCount += 1;
    });
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            const Text('Label 1'),
            const Text('Label 2'),
            Transform.rotate(
              angle: pi / 2.0,
              child: const Row(
                children: <Widget>[Text('Label 3'), Text('Label 4'), Text('Label 5')],
              ),
            ),
          ],
        ),
      ),
    );
    expect(semanticsUpdateCount, 1);
    expect(
      semantics,
      hasSemantics(
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(label: r'Label 1', textDirection: TextDirection.ltr),
            TestSemantics(label: r'Label 2', textDirection: TextDirection.ltr),
            TestSemantics(label: r'Label 3', textDirection: TextDirection.ltr),
            TestSemantics(label: r'Label 4', textDirection: TextDirection.ltr),
            TestSemantics(label: r'Label 5', textDirection: TextDirection.ltr),
          ],
        ),
        ignoreTransform: true,
        ignoreRect: true,
        ignoreId: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets(
    'Semantics widgets without sort orders are sorted properly when no Directionality is present',
    (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      int semanticsUpdateCount = 0;
      tester.binding.pipelineOwner.semanticsOwner!.addListener(() {
        semanticsUpdateCount += 1;
      });
      await tester.pumpWidget(
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Set this up so that the placeholder takes up the whole screen,
            // and place the positioned boxes so that if we traverse in the
            // geometric order, we would go from box [4, 3, 2, 1, 0], but if we
            // go in child order, then we go from box [4, 1, 2, 3, 0]. We're verifying
            // that we go in child order here, not geometric order, since there
            // is no directionality, so we don't have a geometric opinion about
            // horizontal order. We do still want to sort vertically, however,
            // which is why the order isn't [0, 1, 2, 3, 4].
            Semantics(button: true, child: const Placeholder()),
            Positioned(
              top: 200.0,
              left: 100.0,
              child: Semantics(
                // Box 0
                button: true,
                child: const SizedBox(width: 30.0, height: 30.0),
              ),
            ),
            Positioned(
              top: 100.0,
              left: 200.0,
              child: Semantics(
                // Box 1
                button: true,
                child: const SizedBox(width: 30.0, height: 30.0),
              ),
            ),
            Positioned(
              top: 100.0,
              left: 100.0,
              child: Semantics(
                // Box 2
                button: true,
                child: const SizedBox(width: 30.0, height: 30.0),
              ),
            ),
            Positioned(
              top: 100.0,
              left: 0.0,
              child: Semantics(
                // Box 3
                button: true,
                child: const SizedBox(width: 30.0, height: 30.0),
              ),
            ),
            Positioned(
              top: 10.0,
              left: 100.0,
              child: Semantics(
                // Box 4
                button: true,
                child: const SizedBox(width: 30.0, height: 30.0),
              ),
            ),
          ],
        ),
      );
      expect(semanticsUpdateCount, 1);
      expect(
        semantics,
        hasSemantics(
          TestSemantics(
            children: <TestSemantics>[
              TestSemantics(flags: <SemanticsFlag>[SemanticsFlag.isButton]),
              TestSemantics(flags: <SemanticsFlag>[SemanticsFlag.isButton]),
              TestSemantics(flags: <SemanticsFlag>[SemanticsFlag.isButton]),
              TestSemantics(flags: <SemanticsFlag>[SemanticsFlag.isButton]),
              TestSemantics(flags: <SemanticsFlag>[SemanticsFlag.isButton]),
              TestSemantics(flags: <SemanticsFlag>[SemanticsFlag.isButton]),
            ],
          ),
          ignoreTransform: true,
          ignoreRect: true,
          ignoreId: true,
        ),
      );

      semantics.dispose();
    },
  );

  testWidgets('Semantics excludeSemantics ignores children', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Semantics(
        label: 'label',
        excludeSemantics: true,
        textDirection: TextDirection.ltr,
        child: Semantics(label: 'other label', textDirection: TextDirection.ltr),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(label: 'label', textDirection: TextDirection.ltr),
          ],
        ),
        ignoreId: true,
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('Can change handlers', (WidgetTester tester) async {
    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr, onTap: () {}),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasTapAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr, onDismiss: () {}),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasDismissAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(
        container: true,
        label: 'foo',
        textDirection: TextDirection.ltr,
        onLongPress: () {},
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasLongPressAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(
        container: true,
        label: 'foo',
        textDirection: TextDirection.ltr,
        onScrollLeft: () {},
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasScrollLeftAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(
        container: true,
        label: 'foo',
        textDirection: TextDirection.ltr,
        onScrollRight: () {},
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasScrollRightAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr, onScrollUp: () {}),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasScrollUpAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(
        container: true,
        label: 'foo',
        textDirection: TextDirection.ltr,
        onScrollDown: () {},
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasScrollDownAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr, onIncrease: () {}),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasIncreaseAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr, onDecrease: () {}),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasDecreaseAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr, onCopy: () {}),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasCopyAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr, onCut: () {}),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasCutAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr, onPaste: () {}),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasPasteAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(
        container: true,
        label: 'foo',
        textDirection: TextDirection.ltr,
        onSetSelection: (TextSelection _) {},
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', hasSetSelectionAction: true, textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(
        container: true,
        label: 'foo',
        textDirection: TextDirection.ltr,
        onDidGainAccessibilityFocus: () {},
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
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );

    await tester.pumpWidget(
      Semantics(
        container: true,
        label: 'foo',
        textDirection: TextDirection.ltr,
        onDidLoseAccessibilityFocus: () {},
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
      Semantics(container: true, label: 'foo', textDirection: TextDirection.ltr),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('foo')),
      matchesSemantics(label: 'foo', textDirection: TextDirection.ltr),
    );
  });

  testWidgets('Semantics with zero transform gets dropped', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/110671.
    // Construct a widget tree that will end up with a fitted box that applies
    // a zero transform because it does not actually draw its children.
    // Assert that this subtree gets dropped (the root node has no children).
    await tester.pumpWidget(
      const Column(
        children: <Widget>[
          SizedBox(
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
        ],
      ),
    );

    final SemanticsNode node = RendererBinding.instance.renderView.debugSemantics!;

    expect(node.transform, null); // Make sure the zero transform didn't end up on the root somehow.
    expect(node.childrenCount, 0);
  });

  testWidgets('blocking user interaction works on explicit child node.', (
    WidgetTester tester,
  ) async {
    final UniqueKey key1 = UniqueKey();
    final UniqueKey key2 = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Semantics(
          blockUserActions: true,
          explicitChildNodes: true,
          child: Column(
            children: <Widget>[
              Semantics(
                key: key1,
                label: 'label1',
                onTap: () {},
                child: const SizedBox(width: 10, height: 10),
              ),
              Semantics(
                key: key2,
                label: 'label2',
                onTap: () {},
                child: const SizedBox(width: 10, height: 10),
              ),
            ],
          ),
        ),
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
    final UniqueKey key = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Semantics(
          key: key,
          container: true,
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
                onLongPress: () {},
                child: const SizedBox(width: 10, height: 10),
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byKey(key)),
      // Tap action in label1 is blocked,
      matchesSemantics(label: 'label1\nlabel2', hasLongPressAction: true),
    );
  });

  testWidgets('does not merge conflicting actions even if one of them is blocked', (
    WidgetTester tester,
  ) async {
    final UniqueKey key = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Semantics(
          key: key,
          container: true,
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

  testWidgets('supports heading levels', (WidgetTester tester) async {
    // Default: not a heading.
    expect(Semantics(child: const Text('dummy text')).properties.headingLevel, isNull);

    // Headings level 1-6.
    for (int level = 1; level <= 6; level++) {
      final Semantics semantics = Semantics(headingLevel: level, child: const Text('dummy text'));
      expect(semantics.properties.headingLevel, level);
    }

    // Invalid heading levels.
    for (final int badLevel in const <int>[-1, 0, 7, 8, 9]) {
      expect(
        () => Semantics(headingLevel: badLevel, child: const Text('dummy text')),
        throwsAssertionError,
      );
    }
  });

  testWidgets('parent heading level takes precedence when it absorbs a child', (
    WidgetTester tester,
  ) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    Future<SemanticsConfiguration> pumpHeading(int? level) async {
      final ValueKey<String> key = ValueKey<String>('heading-$level');
      await tester.pumpWidget(
        Semantics(
          key: key,
          headingLevel: level,
          child: Text('Heading level $level', textDirection: TextDirection.ltr),
        ),
      );
      final RenderSemanticsAnnotations object = tester.renderObject<RenderSemanticsAnnotations>(
        find.byKey(key),
      );
      final SemanticsConfiguration config = SemanticsConfiguration();
      object.describeSemanticsConfiguration(config);
      return config;
    }

    // Tuples contain (parent level, child level, expected combined level).
    final List<(int, int, int)> scenarios = <(int, int, int)>[
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

    for (final (int, int, int) scenario in scenarios) {
      final int parentLevel = scenario.$1;
      final int childLevel = scenario.$2;
      final int resultLevel = scenario.$3;

      final SemanticsConfiguration parent = await pumpHeading(
        parentLevel == 0 ? null : parentLevel,
      );
      final SemanticsConfiguration child = SemanticsConfiguration()..headingLevel = childLevel;
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
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Headings')),
          body: ListView(
            children: <Widget>[
              for (int level = 1; level <= 6; level++)
                Semantics(
                  key: ValueKey<String>('heading-$level'),
                  headingLevel: level,
                  child: Text('Heading level $level'),
                ),
              const Text('This is not a heading'),
            ],
          ),
        ),
      ),
    );

    for (int level = 1; level <= 6; level++) {
      final ValueKey<String> key = ValueKey<String>('heading-$level');
      final SemanticsNode node = tester.getSemantics(find.byKey(key));
      expect('$node', contains('headingLevel: $level'));
    }

    final SemanticsNode notHeading = tester.getSemantics(find.text('This is not a heading'));
    expect(notHeading, isNot(contains('headingLevel')));

    semantics.dispose();
  });

  testWidgets('RenderSemanticsAnnotations provides validation result', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    Future<SemanticsConfiguration> pumpValidationResult(SemanticsValidationResult result) async {
      final ValueKey<String> key = ValueKey<String>('validation-$result');
      await tester.pumpWidget(
        Semantics(
          key: key,
          validationResult: result,
          child: Text('Validation result $result', textDirection: TextDirection.ltr),
        ),
      );
      final RenderSemanticsAnnotations object = tester.renderObject<RenderSemanticsAnnotations>(
        find.byKey(key),
      );
      final SemanticsConfiguration config = SemanticsConfiguration();
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
    final SemanticsTester semantics = SemanticsTester(tester);

    Future<void> expectValidationResult({
      required SemanticsValidationResult outer,
      required SemanticsValidationResult inner,
      required SemanticsValidationResult expected,
    }) async {
      const ValueKey<String> key = ValueKey<String>('validated-widget');
      await tester.pumpWidget(
        Semantics(
          validationResult: outer,
          child: Semantics(
            validationResult: inner,
            child: Text(
              key: key,
              'Outer = $outer; inner = $inner',
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      );
      final SemanticsNode result = tester.getSemantics(find.byKey(key));
      expect(
        result,
        containsSemantics(label: 'Outer = $outer; inner = $inner', validationResult: expected),
      );
    }

    // Outer is none
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

    // Outer is valid
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

    // Outer is invalid
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

  testWidgets('semantics grafting in traversal order', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const String identifier = '111';
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          body: Column(
            children: <Widget>[
              Semantics(
                traversalParentIdentifier: identifier,
                child: const SizedBox.square(dimension: 10),
              ),
              Semantics(
                traversalChildIdentifier: identifier,
                child: const SizedBox.square(dimension: 10),
              ),
              const SizedBox.square(dimension: 10),
            ],
          ),
        ),
      ),
    );

    // Semantics tree in traversal order. On web, no grafting.
    expect(
      semantics,
      kIsWeb
          ? hasSemantics(
              TestSemantics.root(
                children: <TestSemantics>[
                  TestSemantics(id: 1, traversalParentIdentifier: identifier),
                  TestSemantics(id: 2, traversalChildIdentifier: identifier),
                ],
              ),
              ignoreRect: true,
              ignoreTransform: true,
            )
          : hasSemantics(
              TestSemantics.root(
                children: <TestSemantics>[
                  TestSemantics.rootChild(
                    id: 1,
                    traversalParentIdentifier: identifier,
                    children: <TestSemantics>[
                      TestSemantics(id: 2, traversalChildIdentifier: identifier),
                    ],
                  ),
                ],
              ),
              ignoreRect: true,
              ignoreTransform: true,
            ),
    );

    // Semantics tree in hit-test order.
    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(id: 1, traversalParentIdentifier: identifier),
            TestSemantics(id: 2, traversalChildIdentifier: identifier),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
        childOrder: DebugSemanticsDumpOrder.inverseHitTest,
      ),
    );

    semantics.dispose();
  });

  testWidgets('semantics grafting in traversal order with multiple same traversalChildIdentifier', (
    WidgetTester tester,
  ) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const String identifier = '111';
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          body: Column(
            children: <Widget>[
              Semantics(
                traversalParentIdentifier: identifier,
                child: const SizedBox.square(dimension: 10),
              ),
              Semantics(
                traversalChildIdentifier: identifier,
                child: const SizedBox.square(dimension: 10),
              ),
              Semantics(
                traversalChildIdentifier: identifier,
                child: const SizedBox.square(dimension: 10),
              ),
              const SizedBox.square(dimension: 10),
            ],
          ),
        ),
      ),
    );

    // Semantics tree in traversal order. On web, no grafting.
    expect(
      semantics,
      kIsWeb
          ? hasSemantics(
              TestSemantics.root(
                children: <TestSemantics>[
                  TestSemantics(id: 1, traversalParentIdentifier: identifier),
                  TestSemantics(id: 2, traversalChildIdentifier: identifier),
                  TestSemantics(id: 3, traversalChildIdentifier: identifier),
                ],
              ),
              ignoreRect: true,
              ignoreTransform: true,
            )
          : hasSemantics(
              TestSemantics.root(
                children: <TestSemantics>[
                  TestSemantics.rootChild(
                    id: 1,
                    traversalParentIdentifier: identifier,
                    children: <TestSemantics>[
                      TestSemantics(id: 2, traversalChildIdentifier: identifier),
                      TestSemantics(id: 3, traversalChildIdentifier: identifier),
                    ],
                  ),
                ],
              ),
              ignoreRect: true,
              ignoreTransform: true,
            ),
    );

    // Semantics tree in hit-test order.
    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(id: 1, traversalParentIdentifier: identifier),
            TestSemantics(id: 2, traversalChildIdentifier: identifier),
            TestSemantics(id: 3, traversalChildIdentifier: identifier),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
        childOrder: DebugSemanticsDumpOrder.inverseHitTest,
      ),
    );

    semantics.dispose();
  });

  testWidgets(
    'no grafting in traversal order when traversal child is the parent of its traversal parent',
    (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      const String identifier = '111';
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: Column(
              children: <Widget>[
                Semantics(
                  traversalChildIdentifier: identifier,
                  child: TextButton(
                    onPressed: () {},
                    child: Semantics(traversalParentIdentifier: identifier),
                  ),
                ),
                const SizedBox.square(dimension: 10),
              ],
            ),
          ),
        ),
      );

      final Object? exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception! as FlutterError;
      expect(
        error.message,
        'The traversalParent 2 cannot be the child of the traversalChild 1 in hit-test order',
      );
      semantics.dispose();
    },
    skip: kIsWeb, // [intended] the web traversal order by using ARIA-OWNS.
  );
}

class CustomSortKey extends OrdinalSortKey {
  const CustomSortKey(super.order, {super.name});
}
