// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

Widget boilerplate({required Widget child}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  );
}

void main() {

  testWidgets('SegmentedButton supports exclusive choice by default', (WidgetTester tester) async {
    int callbackCount = 0;
    int selectedSegment = 2;

    Widget frameWithSelection(int selected) {
      return Material(
        child: boilerplate(
          child: SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 1, label: Text('1')),
              ButtonSegment<int>(value: 2, label: Text('2')),
              ButtonSegment<int>(value: 3, label: Text('3')),
            ],
            selected: <int>{selected},
            onSelectionChanged: (Set<int> selected) {
              assert(selected.length == 1);
              selectedSegment = selected.first;
              callbackCount += 1;
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(frameWithSelection(selectedSegment));
    expect(selectedSegment, 2);
    expect(callbackCount, 0);

    // Tap on segment 1.
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(callbackCount, 1);
    expect(selectedSegment, 1);

    // Update the selection in the widget
    await tester.pumpWidget(frameWithSelection(1));

    // Tap on segment 1 again should do nothing.
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(callbackCount, 1);
    expect(selectedSegment, 1);

    // Tap on segment 3.
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(callbackCount, 2);
    expect(selectedSegment, 3);
  });

  testWidgets('SegmentedButton supports multiple selected segments', (WidgetTester tester) async {
    int callbackCount = 0;
    Set<int> selection = <int>{1};

    Widget frameWithSelection(Set<int> selected) {
      return Material(
        child: boilerplate(
          child: SegmentedButton<int>(
            multiSelectionEnabled: true,
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 1, label: Text('1')),
              ButtonSegment<int>(value: 2, label: Text('2')),
              ButtonSegment<int>(value: 3, label: Text('3')),
            ],
            selected: selected,
            onSelectionChanged: (Set<int> selected) {
              selection = selected;
              callbackCount += 1;
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(frameWithSelection(selection));
    expect(selection, <int>{1});
    expect(callbackCount, 0);

    // Tap on segment 2.
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(callbackCount, 1);
    expect(selection, <int>{1, 2});

    // Update the selection in the widget
    await tester.pumpWidget(frameWithSelection(<int>{1, 2}));
    await tester.pumpAndSettle();

    // Tap on segment 1 again should remove it from selection.
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(callbackCount, 2);
    expect(selection, <int>{2});

    // Update the selection in the widget
    await tester.pumpWidget(frameWithSelection(<int>{2}));
    await tester.pumpAndSettle();

    // Tap on segment 3.
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(callbackCount, 3);
    expect(selection, <int>{2, 3});
  });

testWidgets('SegmentedButton allows for empty selection', (WidgetTester tester) async {
    int callbackCount = 0;
    int? selectedSegment = 1;

    Widget frameWithSelection(int? selected) {
      return Material(
        child: boilerplate(
          child: SegmentedButton<int>(
            emptySelectionAllowed: true,
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 1, label: Text('1')),
              ButtonSegment<int>(value: 2, label: Text('2')),
              ButtonSegment<int>(value: 3, label: Text('3')),
            ],
            selected: <int>{if (selected != null) selected},
            onSelectionChanged: (Set<int> selected) {
              selectedSegment = selected.isEmpty ? null : selected.first;
              callbackCount += 1;
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(frameWithSelection(selectedSegment));
    expect(selectedSegment,1);
    expect(callbackCount, 0);

    // Tap on segment 1 should deselect it and make the selection empty.
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(callbackCount, 1);
    expect(selectedSegment, null);

    // Update the selection in the widget
    await tester.pumpWidget(frameWithSelection(null));

    // Tap on segment 2 should select it.
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(callbackCount, 2);
    expect(selectedSegment, 2);

    // Update the selection in the widget
    await tester.pumpWidget(frameWithSelection(2));

    // Tap on segment 3.
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(callbackCount, 3);
    expect(selectedSegment, 3);
  });

testWidgets('SegmentedButton shows checkboxes for selected segments', (WidgetTester tester) async {
    Widget frameWithSelection(int selected) {
      return Material(
        child: boilerplate(
          child: SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 1, label: Text('1')),
              ButtonSegment<int>(value: 2, label: Text('2')),
              ButtonSegment<int>(value: 3, label: Text('3')),
            ],
            selected: <int>{selected},
            onSelectionChanged: (Set<int> selected) {},
          ),
        ),
      );
    }

    Finder textHasIcon(String text, IconData icon) {
      return find.descendant(
        of: find.widgetWithText(Row, text),
        matching: find.byIcon(icon)
      );
    }

    await tester.pumpWidget(frameWithSelection(1));
    expect(textHasIcon('1', Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.pumpWidget(frameWithSelection(2));
    expect(textHasIcon('2', Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.pumpWidget(frameWithSelection(2));
    expect(textHasIcon('2', Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('SegmentedButton shows selected checkboxes in place of icon if it has a label as well', (WidgetTester tester) async {
    Widget frameWithSelection(int selected) {
      return Material(
        child: boilerplate(
          child: SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 1, icon: Icon(Icons.add), label: Text('1')),
              ButtonSegment<int>(value: 2, icon: Icon(Icons.add_a_photo), label: Text('2')),
              ButtonSegment<int>(value: 3, icon: Icon(Icons.add_alarm), label: Text('3')),
            ],
            selected: <int>{selected},
            onSelectionChanged: (Set<int> selected) {},
          ),
        ),
      );
    }

    Finder textHasIcon(String text, IconData icon) {
      return find.descendant(
        of: find.widgetWithText(Row, text),
        matching: find.byIcon(icon)
      );
    }

    await tester.pumpWidget(frameWithSelection(1));
    expect(textHasIcon('1', Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(textHasIcon('2', Icons.add_a_photo), findsOneWidget);
    expect(textHasIcon('3', Icons.add_alarm), findsOneWidget);

    await tester.pumpWidget(frameWithSelection(2));
    expect(textHasIcon('1', Icons.add), findsOneWidget);
    expect(textHasIcon('2', Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.add_a_photo), findsNothing);
    expect(textHasIcon('3', Icons.add_alarm), findsOneWidget);

    await tester.pumpWidget(frameWithSelection(3));
    expect(textHasIcon('1', Icons.add), findsOneWidget);
    expect(textHasIcon('2', Icons.add_a_photo), findsOneWidget);
    expect(textHasIcon('3', Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.add_alarm), findsNothing);
  });

  testWidgets('SegmentedButton shows selected checkboxes next to icon if there is no label', (WidgetTester tester) async {
    Widget frameWithSelection(int selected) {
      return Material(
        child: boilerplate(
          child: SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 1, icon: Icon(Icons.add)),
              ButtonSegment<int>(value: 2, icon: Icon(Icons.add_a_photo)),
              ButtonSegment<int>(value: 3, icon: Icon(Icons.add_alarm)),
            ],
            selected: <int>{selected},
            onSelectionChanged: (Set<int> selected) {},
          ),
        ),
      );
    }

    Finder rowWithIcons(IconData icon1, IconData icon2) {
      return find.descendant(
        of: find.widgetWithIcon(Row, icon1),
        matching: find.byIcon(icon2)
      );
    }

    await tester.pumpWidget(frameWithSelection(1));
    expect(rowWithIcons(Icons.add, Icons.check), findsOneWidget);
    expect(rowWithIcons(Icons.add_a_photo, Icons.check), findsNothing);
    expect(rowWithIcons(Icons.add_alarm, Icons.check), findsNothing);

    await tester.pumpWidget(frameWithSelection(2));
    expect(rowWithIcons(Icons.add, Icons.check), findsNothing);
    expect(rowWithIcons(Icons.add_a_photo, Icons.check), findsOneWidget);
    expect(rowWithIcons(Icons.add_alarm, Icons.check), findsNothing);

    await tester.pumpWidget(frameWithSelection(3));
    expect(rowWithIcons(Icons.add, Icons.check), findsNothing);
    expect(rowWithIcons(Icons.add_a_photo, Icons.check), findsNothing);
    expect(rowWithIcons(Icons.add_alarm, Icons.check), findsOneWidget);

  });

  testWidgets('SegmentedButtons have correct semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 1, label: Text('1')),
              ButtonSegment<int>(value: 2, label: Text('2')),
              ButtonSegment<int>(value: 3, label: Text('3'), enabled: false),
            ],
            selected: const <int>{2},
            onSelectionChanged: (Set<int> selected) {},
          ),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            // First is an unselected, enabled button.
            TestSemantics(
              flags: <SemanticsFlag>[
                SemanticsFlag.isButton,
                SemanticsFlag.isEnabled,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.hasCheckedState,
                SemanticsFlag.isFocusable,
                SemanticsFlag.isInMutuallyExclusiveGroup,
              ],
              label: '1',
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
            ),

            // Second is a selected, enabled button.
            TestSemantics(
              flags: <SemanticsFlag>[
                SemanticsFlag.isButton,
                SemanticsFlag.isEnabled,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.hasCheckedState,
                SemanticsFlag.isChecked,
                SemanticsFlag.isFocusable,
                SemanticsFlag.isInMutuallyExclusiveGroup,
              ],
              label: '2',
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
            ),

            // Third is an unselected, disabled button.
            TestSemantics(
              flags: <SemanticsFlag>[
                SemanticsFlag.isButton,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.hasCheckedState,
                SemanticsFlag.isInMutuallyExclusiveGroup,
              ],
              label: '3',
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


  testWidgets('Multi-select SegmentedButtons have correct semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 1, label: Text('1')),
              ButtonSegment<int>(value: 2, label: Text('2')),
              ButtonSegment<int>(value: 3, label: Text('3'), enabled: false),
            ],
            selected: const <int>{1, 3},
            onSelectionChanged: (Set<int> selected) {},
            multiSelectionEnabled: true,
          ),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            // First is selected, enabled button.
            TestSemantics(
              flags: <SemanticsFlag>[
                SemanticsFlag.isButton,
                SemanticsFlag.isEnabled,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.hasCheckedState,
                SemanticsFlag.isChecked,
                SemanticsFlag.isFocusable,
              ],
              label: '1',
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
            ),

            // Second is an unselected, enabled button.
            TestSemantics(
              flags: <SemanticsFlag>[
                SemanticsFlag.isButton,
                SemanticsFlag.isEnabled,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.hasCheckedState,
                SemanticsFlag.isFocusable,
              ],
              label: '2',
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
            ),

            // Third is a selected, disabled button.
            TestSemantics(
              flags: <SemanticsFlag>[
                SemanticsFlag.isButton,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.isChecked,
                SemanticsFlag.hasCheckedState,
              ],
              label: '3',
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
}
