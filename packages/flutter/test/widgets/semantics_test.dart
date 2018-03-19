// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('Semantics shutdown and restart', (WidgetTester tester) async {
    SemanticsTester semantics = new SemanticsTester(tester);

    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          label: 'test1',
          textDirection: TextDirection.ltr,
        )
      ],
    );

    await tester.pumpWidget(
      new Container(
        child: new Semantics(
          label: 'test1',
          textDirection: TextDirection.ltr,
          child: new Container()
        )
      )
    );

    expect(semantics, hasSemantics(
      expectedSemantics,
      ignoreTransform: true,
      ignoreRect: true,
      ignoreId: true,
    ));

    semantics.dispose();
    semantics = null;

    expect(tester.binding.hasScheduledFrame, isFalse);
    semantics = new SemanticsTester(tester);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();

    expect(semantics, hasSemantics(
      expectedSemantics,
      ignoreTransform: true,
      ignoreRect: true,
      ignoreId: true,
    ));
    semantics.dispose();
  });

  testWidgets('Detach and reattach assert', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    final GlobalKey key = new GlobalKey();

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Container(
        child: new Semantics(
          label: 'test1',
          child: new Semantics(
            key: key,
            container: true,
            label: 'test2a',
            child: new Container()
          )
        )
      )
    ));

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            label: 'test1',
            children: <TestSemantics>[
              new TestSemantics(
                label: 'test2a',
              )
            ]
          )
        ]
      ),
      ignoreId: true,
      ignoreRect: true,
      ignoreTransform: true,
    ));

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Container(
        child: new Semantics(
          label: 'test1',
          child: new Semantics(
            container: true,
            label: 'middle',
            child: new Semantics(
              key: key,
              container: true,
              label: 'test2b',
              child: new Container()
            )
          )
        )
      )
    ));

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            label: 'test1',
            children: <TestSemantics>[
              new TestSemantics(
                label: 'middle',
                children: <TestSemantics>[
                  new TestSemantics(
                    label: 'test2b',
                  ),
                ],
              )
            ]
          )
        ]
      ),
      ignoreId: true,
      ignoreRect: true,
      ignoreTransform: true,
    ));

    semantics.dispose();
  });

  testWidgets('Semantics and Directionality - RTL', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Semantics(
          label: 'test1',
          child: new Container(),
        ),
      ),
    );

    expect(semantics, includesNodeWith(label: 'test1', textDirection: TextDirection.rtl));
  });

  testWidgets('Semantics and Directionality - LTR', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Semantics(
          label: 'test1',
          child: new Container(),
        ),
      ),
    );

    expect(semantics, includesNodeWith(label: 'test1', textDirection: TextDirection.ltr));
  });

  testWidgets('Semantics and Directionality - cannot override RTL with LTR', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          label: 'test1',
          textDirection: TextDirection.ltr,
        )
      ]
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Semantics(
          label: 'test1',
          textDirection: TextDirection.ltr,
          child: new Container(),
        ),
      ),
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true));
  });

  testWidgets('Semantics and Directionality - cannot override LTR with RTL', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          label: 'test1',
          textDirection: TextDirection.rtl,
        )
      ]
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Semantics(
          label: 'test1',
          textDirection: TextDirection.rtl,
          child: new Container(),
        ),
      ),
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true));
  });

  testWidgets('Semantics label and hint', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Semantics(
          label: 'label',
          hint: 'hint',
          value: 'value',
          child: new Container(),
        ),
      ),
    );

    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          label: 'label',
          hint: 'hint',
          value: 'value',
          textDirection: TextDirection.ltr,
        )
      ]
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true));
  });

  testWidgets('Semantics hints can merge', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Semantics(
          container: true,
          child: new Column(
            children: <Widget>[
              new Semantics(
                hint: 'hint one',
              ),
              new Semantics(
                hint: 'hint two',
              )

            ],
          ),
        ),
      ),
    );

    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          hint: 'hint one\nhint two',
          textDirection: TextDirection.ltr,
        )
      ]
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true));
  });

  testWidgets('Semantics values do not merge', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Semantics(
          container: true,
          child: new Column(
            children: <Widget>[
              new Semantics(
                value: 'value one',
                child: new Container(
                  height: 10.0,
                  width: 10.0,
                )
              ),
              new Semantics(
                value: 'value two',
                child: new Container(
                  height: 10.0,
                  width: 10.0,
                )
              )
            ],
          ),
        ),
      ),
    );

    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          children: <TestSemantics>[
            new TestSemantics(
              value: 'value one',
              textDirection: TextDirection.ltr,
            ),
            new TestSemantics(
              value: 'value two',
              textDirection: TextDirection.ltr,
            ),
          ]
        )
      ],
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true));
  });

  testWidgets('Semantics value and hint can merge', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Semantics(
          container: true,
          child: new Column(
            children: <Widget>[
              new Semantics(
                hint: 'hint',
              ),
              new Semantics(
                value: 'value',
              ),
            ],
          ),
        ),
      ),
    );

    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          hint: 'hint',
          value: 'value',
          textDirection: TextDirection.ltr,
        )
      ]
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true));
  });

  testWidgets('Semantics widget supports all actions', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final List<SemanticsAction> performedActions = <SemanticsAction>[];

    await tester.pumpWidget(
      new Semantics(
        container: true,
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
        onMoveCursorForwardByCharacter: (bool _) => performedActions.add(SemanticsAction.moveCursorForwardByCharacter),
        onMoveCursorBackwardByCharacter: (bool _) => performedActions.add(SemanticsAction.moveCursorBackwardByCharacter),
        onSetSelection: (TextSelection _) => performedActions.add(SemanticsAction.setSelection),
        onDidGainAccessibilityFocus: () => performedActions.add(SemanticsAction.didGainAccessibilityFocus),
        onDidLoseAccessibilityFocus: () => performedActions.add(SemanticsAction.didLoseAccessibilityFocus),
      )
    );

    final Set<SemanticsAction> allActions = SemanticsAction.values.values.toSet()
      ..remove(SemanticsAction.showOnScreen); // showOnScreen is non user-exposed.

    const int expectedId = 2;
    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: expectedId,
          rect: TestSemantics.fullScreen,
          actions: allActions.fold(0, (int previous, SemanticsAction action) => previous | action.index),
          previousNodeId: -1,
          nextNodeId: -1,
        ),
      ],
    );
    expect(semantics, hasSemantics(expectedSemantics));

    // Do the actions work?
    final SemanticsOwner semanticsOwner = tester.binding.pipelineOwner.semanticsOwner;
    int expectedLength = 1;
    for (SemanticsAction action in allActions) {
      switch (action) {
        case SemanticsAction.moveCursorBackwardByCharacter:
        case SemanticsAction.moveCursorForwardByCharacter:
          semanticsOwner.performAction(expectedId, action, true);
          break;
        case SemanticsAction.setSelection:
          semanticsOwner.performAction(expectedId, action, <String, int>{
            'base': 4,
            'extent': 5,
          });
          break;
        default:
          semanticsOwner.performAction(expectedId, action);
      }
      expect(performedActions.length, expectedLength);
      expect(performedActions.last, action);
      expectedLength += 1;
    }

    semantics.dispose();
  });

  testWidgets('Semantics widget supports all flags', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
        new Semantics(
          container: true,
          // flags
          enabled: true,
          checked: true,
          selected: true,
          button: true,
          textField: true,
          focused: true,
          inMutuallyExclusiveGroup: true,
          header: true,
        )
    );

    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          rect: TestSemantics.fullScreen,
          flags: SemanticsFlag.values.values.toList(),
          previousNodeId: -1,
          nextNodeId: -1,
        ),
      ],
    );
    expect(semantics, hasSemantics(expectedSemantics, ignoreId: true));

    semantics.dispose();
  });

  testWidgets('Actions can be replaced without triggering semantics update', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    int semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.ensureSemantics(
      listener: () {
        semanticsUpdateCount += 1;
      }
    );

    final List<String> performedActions = <String>[];

    await tester.pumpWidget(
      new Semantics(
        container: true,
        onTap: () => performedActions.add('first'),
      ),
    );

    const int expectedId = 2;
    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: expectedId,
          rect: TestSemantics.fullScreen,
          actions: SemanticsAction.tap.index,
        ),
      ],
    );

    final SemanticsOwner semanticsOwner = tester.binding.pipelineOwner.semanticsOwner;

    expect(semantics, hasSemantics(expectedSemantics));
    semanticsOwner.performAction(expectedId, SemanticsAction.tap);
    expect(semanticsUpdateCount, 1);
    expect(performedActions, <String>['first']);

    semanticsUpdateCount = 0;
    performedActions.clear();

    // Updating existing handler should not trigger semantics update
    await tester.pumpWidget(
      new Semantics(
        container: true,
        onTap: () => performedActions.add('second'),
      ),
    );

    expect(semantics, hasSemantics(expectedSemantics));
    semanticsOwner.performAction(expectedId, SemanticsAction.tap);
    expect(semanticsUpdateCount, 0);
    expect(performedActions, <String>['second']);

    semanticsUpdateCount = 0;
    performedActions.clear();

    // Adding a handler works
    await tester.pumpWidget(
      new Semantics(
        container: true,
        onTap: () => performedActions.add('second'),
        onLongPress: () => performedActions.add('longPress'),
      ),
    );

    final TestSemantics expectedSemanticsWithLongPress = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
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
      new Semantics(
        container: true,
        onTap: () => performedActions.add('second'),
      ),
    );

    expect(semantics, hasSemantics(expectedSemantics));
    expect(semanticsUpdateCount, 1);

    semantics.dispose();
  });

  testWidgets('Increased/decreased values are annotated', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Semantics(
          container: true,
          value: '10s',
          increasedValue: '11s',
          decreasedValue: '9s',
          onIncrease: () => () {},
          onDecrease: () => () {},
        ),
      ),
    );

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          actions: SemanticsAction.increase.index | SemanticsAction.decrease.index,
          textDirection: TextDirection.ltr,
          value: '10s',
          increasedValue: '11s',
          decreasedValue: '9s',
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true, ignoreId: true));

    semantics.dispose();
  });

  testWidgets('Semantics widgets built in a widget tree are sorted properly', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    int semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.ensureSemantics(
      listener: () {
        semanticsUpdateCount += 1;
      }
    );
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Semantics(
          sortKey: const CustomSortKey(0.0),
          explicitChildNodes: true,
          child: new Column(
            children: <Widget>[
              new Semantics(sortKey: const CustomSortKey(3.0), child: const Text('Label 1')),
              new Semantics(sortKey: const CustomSortKey(2.0), child: const Text('Label 2')),
              new Semantics(
                sortKey: const CustomSortKey(1.0),
                explicitChildNodes: true,
                child: new Row(
                  children: <Widget>[
                    new Semantics(sortKey: const OrdinalSortKey(3.0), child: const Text('Label 3')),
                    new Semantics(sortKey: const OrdinalSortKey(2.0), child: const Text('Label 4')),
                    new Semantics(sortKey: const OrdinalSortKey(1.0), child: const Text('Label 5')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(semanticsUpdateCount, 1);
    expect(semantics, hasSemantics(
      new TestSemantics(
        id: 0,
        children: <TestSemantics>[
          new TestSemantics(
            id: 2,
            nextNodeId: 5,
            previousNodeId: -1,
            children: <TestSemantics>[
              new TestSemantics(
                id: 3,
                label: r'Label 1',
                textDirection: TextDirection.ltr,
                nextNodeId: -1,
                previousNodeId: 4,
              ),
              new TestSemantics(
                id: 4,
                label: r'Label 2',
                textDirection: TextDirection.ltr,
                nextNodeId: 3,
                previousNodeId: 6,
              ),
              new TestSemantics(
                id: 5,
                nextNodeId: 8,
                previousNodeId: 2,
                children: <TestSemantics>[
                  new TestSemantics(
                    id: 6,
                    label: r'Label 3',
                    textDirection: TextDirection.ltr,
                    nextNodeId: 4,
                    previousNodeId: 7,
                  ),
                  new TestSemantics(
                    id: 7,
                    label: r'Label 4',
                    textDirection: TextDirection.ltr,
                    nextNodeId: 6,
                    previousNodeId: 8,
                  ),
                  new TestSemantics(
                    id: 8,
                    label: r'Label 5',
                    textDirection: TextDirection.ltr,
                    nextNodeId: 7,
                    previousNodeId: 5,
                  ),
                ],
              ),
            ],
          ),
        ],
      ), ignoreTransform: true, ignoreRect: true),
    );
    semantics.dispose();
  });

  testWidgets('Semantics widgets built with explicit sort orders are sorted properly', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    int semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.ensureSemantics(
      listener: () {
        semanticsUpdateCount += 1;
      }
    );
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Column(
          children: <Widget>[
            new Semantics(
              sortOrder: new SemanticsSortOrder(
                keys: <SemanticsSortKey>[const CustomSortKey(3.0), const OrdinalSortKey(5.0)],
              ),
              child: const Text('Label 1'),
            ),
            new Semantics(
              sortOrder: new SemanticsSortOrder(
                keys: <SemanticsSortKey>[const CustomSortKey(2.0), const OrdinalSortKey(4.0)],
              ),
              child: const Text('Label 2'),
            ),
            new Row(
              children: <Widget>[
                new Semantics(
                  sortOrder: new SemanticsSortOrder(
                    keys: <SemanticsSortKey>[const CustomSortKey(1.0), const OrdinalSortKey(3.0)],
                  ),
                  child: const Text('Label 3'),
                ),
                new Semantics(
                  sortOrder: new SemanticsSortOrder(
                    keys: <SemanticsSortKey>[const CustomSortKey(1.0), const OrdinalSortKey(2.0)],
                  ),
                  child: const Text('Label 4'),
                ),
                new Semantics(
                  sortOrder: new SemanticsSortOrder(
                    keys: <SemanticsSortKey>[const CustomSortKey(1.0), const OrdinalSortKey(1.0)],
                  ),
                  child: const Text('Label 5'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    expect(semanticsUpdateCount, 1);
    expect(semantics, hasSemantics(
      new TestSemantics(
        children: <TestSemantics>[
          new TestSemantics(
            label: r'Label 1',
            textDirection: TextDirection.ltr,
            nextNodeId: -1,
            previousNodeId: 3,
          ),
          new TestSemantics(
            label: r'Label 2',
            textDirection: TextDirection.ltr,
            nextNodeId: 2,
            previousNodeId: 4,
          ),
          new TestSemantics(
            label: r'Label 3',
            textDirection: TextDirection.ltr,
            nextNodeId: 3,
            previousNodeId: 5,
          ),
          new TestSemantics(
            label: r'Label 4',
            textDirection: TextDirection.ltr,
            nextNodeId: 4,
            previousNodeId: 6,
          ),
          new TestSemantics(
            label: r'Label 5',
            textDirection: TextDirection.ltr,
            nextNodeId: 5,
            previousNodeId: -1,
          ),
        ],
      ), ignoreTransform: true, ignoreRect: true, ignoreId: true));
    semantics.dispose();
  });

  testWidgets('Semantics widgets built with some discarded sort orders are sorted properly', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    int semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.ensureSemantics(
      listener: () {
        semanticsUpdateCount += 1;
      }
    );
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Semantics(
          sortKey: const OrdinalSortKey(0.0),
          explicitChildNodes: true,
          child: new Column(
            children: <Widget>[
              new Semantics(
                sortOrder: new SemanticsSortOrder(
                  keys: <SemanticsSortKey>[const CustomSortKey(3.0), const OrdinalSortKey(5.0)],
                  discardParentOrder: true,  // Replace this one.
                ),
                child: const Text('Label 1'),
              ),
              new Semantics(
                sortOrder: new SemanticsSortOrder(
                  keys: <SemanticsSortKey>[const CustomSortKey(2.0), const OrdinalSortKey(4.0)],
                ),
                child: const Text('Label 2'),
              ),
              new Row(
                children: <Widget>[
                  new Semantics(
                    sortOrder: new SemanticsSortOrder(
                      keys: <SemanticsSortKey>[const CustomSortKey(1.0), const OrdinalSortKey(3.0)],
                      discardParentOrder: true,  // Replace this one.
                    ),
                    child: const Text('Label 3'),
                  ),
                  new Semantics(
                    sortOrder: new SemanticsSortOrder(
                      keys: <SemanticsSortKey>[const CustomSortKey(1.0), const OrdinalSortKey(2.0)],
                    ),
                    child: const Text('Label 4'),
                  ),
                  new Semantics(
                    sortOrder: new SemanticsSortOrder(
                      keys: <SemanticsSortKey>[const CustomSortKey(1.0), const OrdinalSortKey(1.0)],
                    ),
                    child: const Text('Label 5'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    expect(semanticsUpdateCount, 1);
    expect(semantics, hasSemantics(
      new TestSemantics(
        children: <TestSemantics>[
          new TestSemantics(
            nextNodeId: 5,
            previousNodeId: -1,
            children: <TestSemantics>[
              new TestSemantics(
                label: r'Label 1',
                textDirection: TextDirection.ltr,
                nextNodeId: 7,
                previousNodeId: 5,
              ),
              new TestSemantics(
                label: r'Label 2',
                textDirection: TextDirection.ltr,
                nextNodeId: -1,
                previousNodeId: 6,
              ),
              new TestSemantics(
                label: r'Label 3',
                textDirection: TextDirection.ltr,
                nextNodeId: 3,
                previousNodeId: 2,
              ),
              new TestSemantics(
                label: r'Label 4',
                textDirection: TextDirection.ltr,
                nextNodeId: 4,
                previousNodeId: 7,
              ),
              new TestSemantics(
                label: r'Label 5',
                textDirection: TextDirection.ltr,
                nextNodeId: 6,
                previousNodeId: 3,
              ),
            ],
          ),
        ],
      ), ignoreTransform: true, ignoreRect: true, ignoreId: true),
    );
    semantics.dispose();
  });

  testWidgets('Semantics widgets without sort orders are sorted properly', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    int semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.ensureSemantics(
      listener: () {
        semanticsUpdateCount += 1;
      }
    );
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Column(
          children: <Widget>[
            const Text('Label 1'),
            const Text('Label 2'),
            new Row(
              children: const <Widget>[
                const Text('Label 3'),
                const Text('Label 4'),
                const Text('Label 5'),
              ],
            ),
          ],
        ),
      ),
    );
    expect(semanticsUpdateCount, 1);
    expect(semantics, hasSemantics(
      new TestSemantics(
        children: <TestSemantics>[
          new TestSemantics(
            label: r'Label 1',
            textDirection: TextDirection.ltr,
            previousNodeId: -1,
          ),
          new TestSemantics(
            label: r'Label 2',
            textDirection: TextDirection.ltr,
            previousNodeId: 2,
          ),
          new TestSemantics(
            label: r'Label 3',
            textDirection: TextDirection.ltr,
            previousNodeId: 3,
          ),
          new TestSemantics(
            label: r'Label 4',
            textDirection: TextDirection.ltr,
            previousNodeId: 4,
          ),
          new TestSemantics(
            label: r'Label 5',
            textDirection: TextDirection.ltr,
            previousNodeId: 5,
          ),
        ],
      ), ignoreTransform: true, ignoreRect: true, ignoreId: true),
    );
    semantics.dispose();
  });

  testWidgets('Semantics widgets that are transformed are sorted properly', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    int semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.ensureSemantics(
      listener: () {
        semanticsUpdateCount += 1;
      }
    );
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Column(
          children: <Widget>[
            const Text('Label 1'),
            const Text('Label 2'),
            new Transform.rotate(
              angle: pi / 2.0,
              child: new Row(
                children: const <Widget>[
                  const Text('Label 3'),
                  const Text('Label 4'),
                  const Text('Label 5'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    expect(semanticsUpdateCount, 1);
    expect(semantics, hasSemantics(
      new TestSemantics(
        children: <TestSemantics>[
          new TestSemantics(
            label: r'Label 1',
            textDirection: TextDirection.ltr,
            previousNodeId: 6,
          ),
          new TestSemantics(
            label: r'Label 2',
            textDirection: TextDirection.ltr,
            previousNodeId: 2,
          ),
          new TestSemantics(
            label: r'Label 3',
            textDirection: TextDirection.ltr,
            previousNodeId: -1,
          ),
          new TestSemantics(
            label: r'Label 4',
            textDirection: TextDirection.ltr,
            previousNodeId: 4,
          ),
          new TestSemantics(
            label: r'Label 5',
            textDirection: TextDirection.ltr,
            previousNodeId: 5,
          ),
        ],
      ), ignoreTransform: true, ignoreRect: true, ignoreId: true),
    );
    semantics.dispose();
  });

  testWidgets(
      'Semantics widgets without sort orders are sorted properly when no Directionality is present',
      (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    int semanticsUpdateCount = 0;
    tester.binding.pipelineOwner.ensureSemantics(listener: () {
      semanticsUpdateCount += 1;
    });
    await tester.pumpWidget(
      new Stack(
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
          new Semantics(
            button: true,
            child: const Placeholder(),
          ),
          new Positioned(
            top: 200.0,
            left: 100.0,
            child: new Semantics( // Box 0
              button: true,
              child: const SizedBox(width: 30.0, height: 30.0),
            ),
          ),
          new Positioned(
            top: 100.0,
            left: 200.0,
            child: new Semantics( // Box 1
              button: true,
              child: const SizedBox(width: 30.0, height: 30.0),
            ),
          ),
          new Positioned(
            top: 100.0,
            left: 100.0,
            child: new Semantics( // Box 2
              button: true,
              child: const SizedBox(width: 30.0, height: 30.0),
            ),
          ),
          new Positioned(
            top: 100.0,
            left: 0.0,
            child: new Semantics( // Box 3
              button: true,
              child: const SizedBox(width: 30.0, height: 30.0),
            ),
          ),
          new Positioned(
            top: 10.0,
            left: 100.0,
            child: new Semantics( // Box 4
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
        new TestSemantics(
          children: <TestSemantics>[
            new TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.isButton],
              previousNodeId: -1,
            ),
            new TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.isButton],
              previousNodeId: 6,
            ),
            new TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.isButton],
              previousNodeId: 7,
            ),
            new TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.isButton],
              previousNodeId: 4,
            ),
            new TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.isButton],
              previousNodeId: 5,
            ),
            new TestSemantics(
              flags: <SemanticsFlag>[SemanticsFlag.isButton],
              previousNodeId: 2,
            ),
          ],
        ),
        ignoreTransform: true,
        ignoreRect: true,
        ignoreId: true),
    );
    semantics.dispose();
  });
}

class CustomSortKey extends OrdinalSortKey {
  const CustomSortKey(double order, {String name}) : super(order, name: name);
}
