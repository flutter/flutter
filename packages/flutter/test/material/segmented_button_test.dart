// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
import 'dart:ui';

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
  testWidgets('SegmentsButton when compositing does not crash', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/135747
    // If the render object holds on to a stale canvas reference, this will
    // throw an exception.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(
                value: 0,
                label: Opacity(
                  opacity: 0.5,
                  child: Text('option'),
                ),
                icon: Opacity(
                  opacity: 0.5,
                  child: Icon(Icons.add),
                ),
              ),
            ],
            selected: const <int>{0},
          ),
        ),
      ),
    );

    expect(find.byType(SegmentedButton<int>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SegmentedButton releases state controllers for deleted segments', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);
    final Key key = UniqueKey();

    Widget buildApp(Widget button) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: button,
          ),
        ),
      );
    }

    await tester.pumpWidget(
      buildApp(
        SegmentedButton<int>(
          key: key,
          segments: const <ButtonSegment<int>>[
            ButtonSegment<int>(value: 1, label: Text('1')),
            ButtonSegment<int>(value: 2, label: Text('2')),
          ],
          selected: const <int>{2},
        ),
      ),
    );

    await tester.pumpWidget(
      buildApp(
        SegmentedButton<int>(
          key: key,
          segments: const <ButtonSegment<int>>[
            ButtonSegment<int>(value: 2, label: Text('2')),
            ButtonSegment<int>(value: 3, label: Text('3')),
          ],
          selected: const <int>{2},
        ),
      ),
    );

    final SegmentedButtonState<int> state = tester.state(find.byType(SegmentedButton<int>));
    expect(state.statesControllers, hasLength(2));
    expect(state.statesControllers.keys.first.value, 2);
    expect(state.statesControllers.keys.last.value, 3);
  });

  testWidgets('SegmentedButton is built with Material of type MaterialType.transparency', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(value: 1, label: Text('1')),
                ButtonSegment<int>(value: 2, label: Text('2')),
                ButtonSegment<int>(value: 3, label: Text('3'), enabled: false),
              ],
              selected: const <int>{2},
              onSelectionChanged: (Set<int> selected) { },
            ),
          ),
        ),
      ),
    );

    // Expect SegmentedButton to be built with type MaterialType.transparency.
    final Finder text = find.text('1');
    final Finder parent = find.ancestor(of: text, matching: find.byType(Material)).first;
    final Finder parentMaterial = find.ancestor(of: parent, matching: find.byType(Material)).first;
    final Material material = tester.widget<Material>(parentMaterial);
    expect(material.type, MaterialType.transparency);
  });

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

  testWidgets('SegmentedButton default overlayColor and foregroundColor resolve pressed state', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(value: 1, label: Text('1')),
                ButtonSegment<int>(value: 2, label: Text('2')),
              ],
              selected: const <int>{1},
              onSelectionChanged: (Set<int> selected) {},
            ),
          ),
        ),
      ),
    );

    RenderObject overlayColor() {
      return tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    }

    final Material material = tester.widget<Material>(find.descendant(
      of: find.byType(TextButton),
      matching: find.byType(Material),
    ));

    // Hovered.
    final Offset center = tester.getCenter(find.text('2'));
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    expect(overlayColor(), paints..rect(color: theme.colorScheme.onSurface.withOpacity(0.08)));
    expect(material.textStyle?.color, theme.colorScheme.onSurface);

    // Highlighted (pressed).
    await gesture.down(center);
    await tester.pumpAndSettle();
    expect(overlayColor(), paints..rect()..rect(color: theme.colorScheme.onSurface.withOpacity(0.1)));
    expect(material.textStyle?.color, theme.colorScheme.onSurface);
  });

  testWidgets('SegmentedButton has no tooltips by default', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(value: 1, label: Text('1')),
                ButtonSegment<int>(value: 2, label: Text('2')),
                ButtonSegment<int>(value: 3, label: Text('3'), enabled: false),
              ],
              selected: const <int>{2},
              onSelectionChanged: (Set<int> selected) { },
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets('SegmentedButton has correct tooltips', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(value: 1, label: Text('1')),
                ButtonSegment<int>(value: 2, label: Text('2'), tooltip: 't2'),
                ButtonSegment<int>(
                  value: 3,
                  label: Text('3'),
                  tooltip: 't3',
                  enabled: false,
                ),
              ],
              selected: const <int>{2},
              onSelectionChanged: (Set<int> selected) { },
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsNWidgets(2));
    expect(find.byTooltip('t2'), findsOneWidget);
    expect(find.byTooltip('t3'), findsOneWidget);
  });

  testWidgets('SegmentedButton.styleFrom is applied to the SegmentedButton', (WidgetTester tester) async {
    const Color foregroundColor = Color(0xfffffff0);
    const Color backgroundColor =  Color(0xfffffff1);
    const Color selectedBackgroundColor = Color(0xfffffff2);
    const Color selectedForegroundColor = Color(0xfffffff3);
    const Color disabledBackgroundColor = Color(0xfffffff4);
    const Color disabledForegroundColor = Color(0xfffffff5);
    const MouseCursor enabledMouseCursor = SystemMouseCursors.text;
    const MouseCursor disabledMouseCursor = SystemMouseCursors.grab;

    final ButtonStyle styleFromStyle = SegmentedButton.styleFrom(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      selectedForegroundColor: selectedForegroundColor,
      selectedBackgroundColor: selectedBackgroundColor,
      disabledForegroundColor: disabledForegroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      shadowColor: const Color(0xfffffff6),
      surfaceTintColor: const Color(0xfffffff7),
      elevation: 1,
      textStyle: const TextStyle(color: Color(0xfffffff8)),
      padding: const EdgeInsets.all(2),
      side: const BorderSide(color: Color(0xfffffff9)),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
      enabledMouseCursor: enabledMouseCursor,
      disabledMouseCursor: disabledMouseCursor,
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      animationDuration: const Duration(milliseconds: 100),
      enableFeedback: true,
      alignment: Alignment.center,
      splashFactory: NoSplash.splashFactory,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SegmentedButton<int>(
            style: styleFromStyle,
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 1, label: Text('1')),
              ButtonSegment<int>(value: 2, label: Text('2')),
              ButtonSegment<int>(value: 3, label: Text('3'), enabled: false),
            ],
            selected: const <int>{2},
            onSelectionChanged: (Set<int> selected) { },
            selectedIcon: const Icon(Icons.alarm),
          ),
        ),
      ),
    ));

    // Test provided button style is applied to the enabled button segment.
    ButtonStyle? buttonStyle = tester.widget<TextButton>(find.byType(TextButton).first).style;
    expect(buttonStyle?.foregroundColor?.resolve(enabled), foregroundColor);
    expect(buttonStyle?.backgroundColor?.resolve(enabled), backgroundColor);
    expect(buttonStyle?.overlayColor, styleFromStyle.overlayColor);
    expect(buttonStyle?.surfaceTintColor, styleFromStyle.surfaceTintColor);
    expect(buttonStyle?.elevation, styleFromStyle.elevation);
    expect(buttonStyle?.textStyle, styleFromStyle.textStyle);
    expect(buttonStyle?.padding, styleFromStyle.padding);
    expect(buttonStyle?.mouseCursor?.resolve(enabled), enabledMouseCursor);
    expect(buttonStyle?.visualDensity, styleFromStyle.visualDensity);
    expect(buttonStyle?.tapTargetSize, styleFromStyle.tapTargetSize);
    expect(buttonStyle?.animationDuration, styleFromStyle.animationDuration);
    expect(buttonStyle?.enableFeedback, styleFromStyle.enableFeedback);
    expect(buttonStyle?.alignment, styleFromStyle.alignment);
    expect(buttonStyle?.splashFactory, styleFromStyle.splashFactory);

    // Test provided button style is applied selected button segment.
    buttonStyle = tester.widget<TextButton>(find.byType(TextButton).at(1)).style;
    expect(buttonStyle?.foregroundColor?.resolve(selected), selectedForegroundColor);
    expect(buttonStyle?.backgroundColor?.resolve(selected), selectedBackgroundColor);
    expect(buttonStyle?.mouseCursor?.resolve(enabled), enabledMouseCursor);

    // Test provided button style is applied disabled button segment.
    buttonStyle = tester.widget<TextButton>(find.byType(TextButton).last).style;
    expect(buttonStyle?.foregroundColor?.resolve(disabled), disabledForegroundColor);
    expect(buttonStyle?.backgroundColor?.resolve(disabled), disabledBackgroundColor);
    expect(buttonStyle?.mouseCursor?.resolve(disabled), disabledMouseCursor);

    // Test provided button style is applied to the segmented button material.
    final Material material = tester.widget<Material>(find.descendant(
      of: find.byType(SegmentedButton<int>),
      matching: find.byType(Material),
    ).first);
    expect(material.elevation, styleFromStyle.elevation?.resolve(enabled));
    expect(material.shadowColor, styleFromStyle.shadowColor?.resolve(enabled));
    expect(material.surfaceTintColor, styleFromStyle.surfaceTintColor?.resolve(enabled));

    // Test provided button style border is applied to the segmented button border.
    expect(
      find.byType(SegmentedButton<int>),
      paints..line(color: styleFromStyle.side?.resolve(enabled)?.color),
    );

    // Test foreground color is applied to the overlay color.
    RenderObject overlayColor() {
      return tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    }
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    await gesture.down(tester.getCenter(find.text('1')));
    await tester.pumpAndSettle();
    expect(overlayColor(), paints..rect(color: foregroundColor.withOpacity(0.08)));
  });

  testWidgets('Disabled SegmentedButton has correct states when rebuilding', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  children: <Widget>[
                    SegmentedButton<int>(
                      segments: const <ButtonSegment<int>>[
                        ButtonSegment<int>(value: 0, label: Text('foo')),
                      ],
                      selected: const <int>{0},
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Trigger rebuild'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    final Set<MaterialState> states = <MaterialState>{ MaterialState.selected, MaterialState.disabled };
    // Check the initial states.
    SegmentedButtonState<int> state = tester.state(find.byType(SegmentedButton<int>));
    expect(state.statesControllers.values.first.value, states);
    // Trigger a rebuild.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    // Check the states after the rebuild.
    state = tester.state(find.byType(SegmentedButton<int>));
    expect(state.statesControllers.values.first.value, states);
  });

  testWidgets('Min button hit target height is 48.0 and min (painted) button height is 40 '
    'by default with standard density and MaterialTapTargetSize.padded', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: Column(
              children: <Widget>[
                SegmentedButton<int>(
                  segments: const <ButtonSegment<int>>[
                    ButtonSegment<int>(value: 0, label: Text('Day'), icon: Icon(Icons.calendar_view_day)),
                    ButtonSegment<int>(value: 1, label: Text('Week'), icon: Icon(Icons.calendar_view_week)),
                    ButtonSegment<int>(value: 2, label: Text('Month'), icon: Icon(Icons.calendar_view_month)),
                    ButtonSegment<int>(value: 3, label: Text('Year'), icon: Icon(Icons.calendar_today)),
                  ],
                  selected: const <int>{0},
                  onSelectionChanged: (Set<int> value) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(theme.visualDensity, VisualDensity.standard);
    expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);

    final Finder button = find.byType(SegmentedButton<int>);
    expect(tester.getSize(button).height, 48.0);
    expect(
      find.byType(SegmentedButton<int>),
      paints..rrect(
        style: PaintingStyle.stroke,
        strokeWidth: 1.0,
        // Button border height is button.bottom(43.5) - button.top(4.5) + stoke width(1) = 40.
        rrect: RRect.fromLTRBR(0.5, 4.5, 497.5, 43.5, const Radius.circular(19.5))
      )
    );
  });
}

Set<MaterialState> enabled = const <MaterialState>{};
Set<MaterialState> disabled = const <MaterialState>{ MaterialState.disabled };
Set<MaterialState> selected = const <MaterialState>{ MaterialState.selected };
