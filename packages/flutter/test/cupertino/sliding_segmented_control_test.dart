// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

dynamic getRenderSegmentedControl(WidgetTester tester) {
  return tester.allRenderObjects.firstWhere(
    (RenderObject currentObject) {
      return currentObject.toStringShort().contains('_RenderSegmentedControl');
    },
  );
}

Rect currentUnscaledThumbRect(WidgetTester tester) => getRenderSegmentedControl(tester).currentThumbRect;
Rect currentThumbScale(WidgetTester tester) => getRenderSegmentedControl(tester).currentThumbScale;

StatefulBuilder setupSimpleSegmentedControl() {
  final Map<int, Widget> children = <int, Widget>{};
  children[0] = const Text('Child 1');
  children[1] = const Text('Child 2');
  final ValueNotifier<int> controller = ValueNotifier<int>(0);

  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      return boilerplate(
        child: CupertinoSlidingSegmentedControl<int>(
          children: children,
          controller: controller,
        ),
      );
    },
  );
}

Widget boilerplate({ Widget child }) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  );
}

void main() {
  testWidgets('Children and controller and padding arguments can not be null', (WidgetTester tester) async {
    try {
      await tester.pumpWidget(
        boilerplate(
          child: CupertinoSlidingSegmentedControl<int>(
            children: null,
            controller: ValueNotifier<int>(null),
          ),
        ),
      );
      fail('Should not be possible to create segmented control with null children');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('children'));
    }

    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    try {
      await tester.pumpWidget(
        boilerplate(
          child: CupertinoSlidingSegmentedControl<int>(
            children: children,
            controller: null,
          ),
        ),
      );
      fail('Should not be possible to create segmented control without a controller');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('controller'));
    }

    try {
      await tester.pumpWidget(
        boilerplate(
          child: CupertinoSlidingSegmentedControl<int>(
            children: children,
            controller: ValueNotifier<int>(null),
            padding: null,
          ),
        ),
      );
      fail('Should not be possible to create segmented control with null padding');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('padding'));
    }
  });

  testWidgets('Need at least 2 children', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    try {
      await tester.pumpWidget(
        boilerplate(
          child: CupertinoSlidingSegmentedControl<int>(
            children: children,
            controller: ValueNotifier<int>(null),
          ),
        ),
      );
      fail('Should not be possible to create a segmented control with no children');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('children.length'));
    }
    try {
      children[0] = const Text('Child 1');

      await tester.pumpWidget(
        boilerplate(
          child: CupertinoSlidingSegmentedControl<int>(
            children: children,
            controller: ValueNotifier<int>(null),
          ),
        ),
      );
      fail('Should not be possible to create a segmented control with just one child');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('children.length'));
    }

    try {
      children[1] = const Text('Child 2');
      children[2] = const Text('Child 3');
      await tester.pumpWidget(
        boilerplate(
          child: CupertinoSlidingSegmentedControl<int>(
            children: children,
            controller: ValueNotifier<int>(-1),
          ),
        ),
      );
      fail('Should not be possible to create a segmented control with a controller pointing to a non-existent child');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('value must be either null or one of the keys in the children map'));
    }
  });

  testWidgets('Padding works', (WidgetTester tester) async {
    const Key key = Key('Container');

    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const SizedBox(
      height: double.infinity,
      width: 100,
      child: Text('Child 1'),
    ) ;
    children[1] = const SizedBox(
      height: double.infinity,
      width: 100,
      child: Text('Child 2'),
    ) ;

    Future<void> verifyPadding({ EdgeInsets padding }) async {
      final EdgeInsets effectivePadding = padding ?? const EdgeInsets.symmetric(vertical: 2, horizontal: 3);
      final Rect segmentedControlRect = tester.getRect(find.byKey(key));
      debugDumpRenderTree();
      expect(
          tester.getTopLeft(find.byWidget(children[0])),
          segmentedControlRect.topLeft + effectivePadding.topLeft,
      );
      expect(
        tester.getBottomLeft(find.byWidget(children[0])),
        segmentedControlRect.bottomLeft + effectivePadding.bottomLeft,
      );

      expect(
        tester.getTopRight(find.byWidget(children[1])),
        segmentedControlRect.topRight + effectivePadding.topRight,
      );
      expect(
        tester.getBottomRight(find.byWidget(children[1])),
        segmentedControlRect.bottomRight + effectivePadding.bottomRight,
      );
    }

    await tester.pumpWidget(
        boilerplate(
          child: CupertinoSlidingSegmentedControl<int>(
            key: key,
            children: children,
            controller: ValueNotifier<int>(null),
          ),
        ),
    );

    // Default padding works.
    await verifyPadding();

    // Switch to Child 2 padding should remain the same.
    await tester.tap(find.text('Child 2'));
    await tester.pumpAndSettle();

    await verifyPadding();

    await tester.pumpWidget(
        boilerplate(
          child: CupertinoSlidingSegmentedControl<int>(
            key: key,
            padding: const EdgeInsets.fromLTRB(1, 3, 5, 7),
            children: children,
            controller: ValueNotifier<int>(null),
          ),
        ),
    );

    // Custom padding works.
    await verifyPadding(padding: const EdgeInsets.fromLTRB(1, 3, 5, 7));

    // Switch back to Child 1 padding should remain the same.
    await tester.tap(find.text('Child 1'));
    await tester.pumpAndSettle();

    await verifyPadding(padding: const EdgeInsets.fromLTRB(1, 3, 5, 7));
  });

  testWidgets('Tap changes toggle state', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');
    children[2] = const Text('Child 3');

    final ValueNotifier<int> controller = ValueNotifier<int>(0);

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSlidingSegmentedControl<int>(
              key: const ValueKey<String>('Segmented Control'),
              children: children,
              controller: controller,
            ),
          );
        },
      ),
    );

    expect(controller.value, 0);

    await tester.tap(find.text('Child 2'));

    expect(controller.value, 1);

    // Tapping the currently selected item should not change controller's value.
    bool valueChanged = false;
    controller.addListener(() { valueChanged = true; });

    await tester.tap(find.text('Child 2'));

    expect(valueChanged, isFalse);
    expect(controller.value, 1);
  });

  testWidgets('Widgets have correct default text/icon styles, change correctly on selection', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Icon(IconData(1));

    final ValueNotifier<int> controller = ValueNotifier<int>(0);

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSlidingSegmentedControl<int>(
              children: children,
              controller: controller,
            ),
          );
        },
      ),
    );

    await tester.pumpAndSettle();

    DefaultTextStyle textStyle = tester.widget(find.widgetWithText(DefaultTextStyle, 'Child 1'));
    IconTheme iconTheme = tester.widget(find.widgetWithIcon(IconTheme, const IconData(1)));

    expect(textStyle.style.color, CupertinoColors.white);
    expect(iconTheme.data.color, CupertinoColors.activeBlue);

    await tester.tap(find.widgetWithIcon(IconTheme, const IconData(1)));
    await tester.pumpAndSettle();

    textStyle = tester.widget(find.widgetWithText(DefaultTextStyle, 'Child 1'));
    iconTheme = tester.widget(find.widgetWithIcon(IconTheme, const IconData(1)));

    expect(textStyle.style.color, CupertinoColors.activeBlue);
    expect(iconTheme.data.color, CupertinoColors.white);
  });

  testWidgets(
    'Segmented controls respect theme',
    (WidgetTester tester) async {
      final Map<int, Widget> children = <int, Widget>{};
      children[0] = const Text('Child 1');
      children[1] = const Icon(IconData(1));

      final ValueNotifier<int> controller = ValueNotifier<int>(0);

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return CupertinoSlidingSegmentedControl<int>(
                children: children,
                controller: controller,
              );
            },
          ),
        ),
      );

      DefaultTextStyle textStyle = tester.widget(find.widgetWithText(DefaultTextStyle, 'Child 1').first);

      expect(textStyle.style.fontWeight, FontWeight.w400);

      await tester.tap(find.byIcon(const IconData(1)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      textStyle = tester.widget(find.widgetWithText(DefaultTextStyle, 'Child 1').first);

      expect(textStyle.style.fontWeight, FontWeight.normal);
    },
  );

  testWidgets('SegmentedControl dark mode', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Icon(IconData(1));

    final ValueNotifier<int> controller = ValueNotifier<int>(0);
    Brightness brightness = Brightness.light;
    StateSetter setState;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          setState = setter;
          return MediaQuery(
            data: MediaQueryData(platformBrightness: brightness),
            child: boilerplate(
              child: CupertinoSlidingSegmentedControl<int>(
                children: children,
                controller: controller,
                thumbColor: CupertinoColors.activeGreen,
                backgroundColor: CupertinoColors.systemRed,
              ),
            ),
          );
        },
      ),
    );

    final BoxDecoration decoration = tester.widget<Container>(find.descendant(
      of: find.byType(CupertinoSlidingSegmentedControl),
      matching: find.byType(Container),
    )).decoration;

    expect(getRenderSegmentedControl(tester).thumbColor, CupertinoColors.activeGreen.color);
    expect(decoration.color, CupertinoColors.systemRed.color);

    setState(() { brightness = Brightness.dark; });

    final BoxDecoration decorationDark = tester.widget<Container>(find.descendant(
      of: find.byType(CupertinoSlidingSegmentedControl),
      matching: find.byType(Container),
    )).decoration;


    expect(getRenderSegmentedControl(tester).thumbColor, CupertinoColors.activeGreen.darkColor);
    expect(decorationDark.color, CupertinoColors.systemRed.darkColor);
  });

  testWidgets(
    'Children can be non-Text or Icon widgets (in this case, '
        'a Container or Placeholder widget)',
    (WidgetTester tester) async {
      final Map<int, Widget> children = <int, Widget>{};
      children[0] = const Text('Child 1');
      children[1] = Container(
        constraints: const BoxConstraints.tightFor(width: 50.0, height: 50.0),
      );
      children[2] = const Placeholder();

      final ValueNotifier<int> controller = ValueNotifier<int>(0);

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return boilerplate(
              child: CupertinoSlidingSegmentedControl<int>(
                children: children,
                controller: controller,
              ),
            );
          },
        ),
      );
    },
  );

  testWidgets('Passed in value is child initially selected', (WidgetTester tester) async {
    await tester.pumpWidget(setupSimpleSegmentedControl());

    expect(getRenderSegmentedControl(tester).highlightedIndex, 0);
  });

  testWidgets('Null input for value results in no child initially selected', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    final ValueNotifier<int> controller = ValueNotifier<int>(null);

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSlidingSegmentedControl<int>(
              children: children,
              controller: controller,
            ),
          );
        },
      ),
    );

    expect(getRenderSegmentedControl(tester).highlightedIndex, null);
  });

  testWidgets('Long press not-selected child interactions', (WidgetTester tester) async {
    const Map<int, Widget> children = <int, Widget>{
      0: Text('Child 1'),
      1: Text('Child 2'),
      2: Text('Child 3'),
      3: Text('Child 4'),
      4: Text('Child 5'),
    };

    // Child 3 is intially selected.
    final ValueNotifier<int> controller = ValueNotifier<int>(2);

    await tester.pumpWidget(
      boilerplate(
        child: CupertinoSlidingSegmentedControl<int>(
          children: children,
          controller: controller,
        ),
      ),
    );

    double getChildOpacityByName(String childName) {
      return tester.widget<Opacity>(
        find.ancestor(matching: find.byType(Opacity), of: find.text(childName)),
      ).opacity;
    }

    // Opacity 1 with no interaction.
    expect(getChildOpacityByName('Child 1'), 1);

    final Offset center = tester.getCenter(find.text('Child 1'));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pumpAndSettle();

    // Opacity drops to 0.2.
    expect(getChildOpacityByName('Child 1'), 0.2);

    // Move down slightly, slightly outside of the segmented control.
    await gesture.moveBy(const Offset(0, 50));
    await tester.pumpAndSettle();
    expect(getChildOpacityByName('Child 1'), 0.2);

    // Move further down and far away from the segmented control.
    await gesture.moveBy(const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(getChildOpacityByName('Child 1'), 1);

    // Move to child 5.
    await gesture.moveTo(tester.getCenter(find.text('Child 5')));
    await tester.pumpAndSettle();
    expect(getChildOpacityByName('Child 1'), 1);
    expect(getChildOpacityByName('Child 5'), 0.2);

    // Move to child 2.
    await gesture.moveTo(tester.getCenter(find.text('Child 2')));
    await tester.pumpAndSettle();
    expect(getChildOpacityByName('Child 1'), 1);
    expect(getChildOpacityByName('Child 5'), 1);
    expect(getChildOpacityByName('Child 2'), 0.2);
  });

  testWidgets('Long press does not change background color of currently-selected child', (WidgetTester tester) async {
    double getChildOpacityByName(String childName) {
      return tester.widget<Opacity>(
        find.ancestor(matching: find.byType(Opacity), of: find.text(childName)),
      ).opacity;
    }

    await tester.pumpWidget(setupSimpleSegmentedControl());

    final Offset center = tester.getCenter(find.text('Child 1'));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    expect(getChildOpacityByName('Child 1'), 1);
  });

  testWidgets('Height of segmented control is determined by tallest widget', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = Container(
      constraints: const BoxConstraints.tightFor(height: 100.0),
    );
    children[1] = Container(
      constraints: const BoxConstraints.tightFor(height: 400.0),
    );
    children[2] = Container(
      constraints: const BoxConstraints.tightFor(height: 200.0),
    );

    final ValueNotifier<int> controller = ValueNotifier<int>(null);

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSlidingSegmentedControl<int>(
              key: const ValueKey<String>('Segmented Control'),
              children: children,
              controller: controller,
            ),
          );
        },
      ),
    );

    final RenderBox buttonBox = tester.renderObject(
      find.byKey(const ValueKey<String>('Segmented Control')),
    );

    expect(buttonBox.size.height, 400.0);
  });

  testWidgets('Width of each segmented control segment is determined by widest widget', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = Container(
      constraints: const BoxConstraints.tightFor(width: 50.0),
    );
    children[1] = Container(
      constraints: const BoxConstraints.tightFor(width: 100.0),
    );
    children[2] = Container(
      constraints: const BoxConstraints.tightFor(width: 200.0),
    );

    final ValueNotifier<int> controller = ValueNotifier<int>(null);
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSlidingSegmentedControl<int>(
              key: const ValueKey<String>('Segmented Control'),
              children: children,
              controller: controller,
            ),
          );
        },
      ),
    );

    final RenderBox segmentedControl = tester.renderObject(
      find.byKey(const ValueKey<String>('Segmented Control')),
    );

    // Subtract the 16.0px from each side. Remaining width should be allocated
    // to each child equally.
    final double childWidth = (segmentedControl.size.width - 32.0) / 3;

    expect(childWidth, 200.0);
  });

  testWidgets('Width is finite in unbounded space', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    final ValueNotifier<int> controller = ValueNotifier<int>(null);

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: Row(
              children: <Widget>[
                CupertinoSlidingSegmentedControl<int>(
                  key: const ValueKey<String>('Segmented Control'),
                  children: children,
                  controller: controller,
                ),
              ],
            ),
          );
        },
      ),
    );

    final RenderBox segmentedControl = tester.renderObject(
      find.byKey(const ValueKey<String>('Segmented Control')),
    );

    expect(segmentedControl.size.width.isFinite, isTrue);
  });

  testWidgets('Directionality test - RTL should reverse order of widgets', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    final ValueNotifier<int> controller = ValueNotifier<int>(null);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: CupertinoSlidingSegmentedControl<int>(
            children: children,
            controller: controller,
          ),
        ),
      ),
    );

    expect(tester.getTopRight(find.text('Child 1')).dx >
        tester.getTopRight(find.text('Child 2')).dx, isTrue);
  });

  testWidgets('Correct initial selection and toggling behavior - RTL', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    final ValueNotifier<int> controller = ValueNotifier<int>(0);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: CupertinoSlidingSegmentedControl<int>(
            children: children,
            controller: controller,
          ),
        ),
      ),
    );

    // highlightedIndex is 1 instead of 0 because of RTL.
    expect(getRenderSegmentedControl(tester).highlightedIndex, 1);

    await tester.tap(find.text('Child 2'));
    await tester.pump();

    expect(getRenderSegmentedControl(tester).highlightedIndex, 0);

    await tester.tap(find.text('Child 2'));
    await tester.pump();

    expect(getRenderSegmentedControl(tester).highlightedIndex, 0);
  });

  testWidgets('Segmented control semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');
    final ValueNotifier<int> controller = ValueNotifier<int>(0);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: CupertinoSlidingSegmentedControl<int>(
            children: children,
            controller: controller,
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
                label: 'Child 1',
                flags: <SemanticsFlag>[
                  SemanticsFlag.isButton,
                  SemanticsFlag.isInMutuallyExclusiveGroup,
                  SemanticsFlag.isSelected,
                ],
                actions: <SemanticsAction>[
                  SemanticsAction.tap,
                ],
              ),
              TestSemantics.rootChild(
                label: 'Child 2',
                flags: <SemanticsFlag>[
                  SemanticsFlag.isButton,
                  SemanticsFlag.isInMutuallyExclusiveGroup,
                ],
                actions: <SemanticsAction>[
                  SemanticsAction.tap,
                ],
              ),
            ],
          ),
          ignoreId: true,
          ignoreRect: true,
          ignoreTransform: true,
        ),
    );

    await tester.tap(find.text('Child 2'));
    await tester.pump();

    expect(
        semantics,
        hasSemantics(
          TestSemantics.root(
            children: <TestSemantics>[
              TestSemantics.rootChild(
                label: 'Child 1',
                flags: <SemanticsFlag>[
                  SemanticsFlag.isButton,
                  SemanticsFlag.isInMutuallyExclusiveGroup,
                ],
                actions: <SemanticsAction>[
                  SemanticsAction.tap,
                ],
              ),
              TestSemantics.rootChild(
                label: 'Child 2',
                flags: <SemanticsFlag>[
                  SemanticsFlag.isButton,
                  SemanticsFlag.isInMutuallyExclusiveGroup,
                  SemanticsFlag.isSelected,
                ],
                actions: <SemanticsAction>[
                  SemanticsAction.tap,
                ],
              ),
            ],
          ),
          ignoreId: true,
          ignoreRect: true,
          ignoreTransform: true,
        ));

    semantics.dispose();
  });

  testWidgets('Non-centered taps work on smaller widgets', (WidgetTester tester) async {
    const Key key = Key('smol widget');
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const SizedBox(key: key);

    final ValueNotifier<int> controller = ValueNotifier<int>(1);

    await tester.pumpWidget(
      boilerplate(
        child: CupertinoSlidingSegmentedControl<int>(
          key: const ValueKey<String>('Segmented Control'),
          children: children,
          controller: controller,
        ),
      ),
    );

    expect(controller.value, 1);

    final double childWidth = getRenderSegmentedControl(tester).firstChild.size.width;
    final Offset centerOfSegmentedControl = tester.getCenter(find.byKey(key));

    // Tap just inside segment bounds
    await tester.tapAt(
      Offset(
        centerOfSegmentedControl.dx + (childWidth / 2) - 10.0,
        centerOfSegmentedControl.dy,
      ),
    );

    expect(controller.value, 0);
  });

  testWidgets('Thumb animation is correct when the selected segment changes', (WidgetTester tester) async {
    await tester.pumpWidget(setupSimpleSegmentedControl());

    final Rect initialRect = currentUnscaledThumbRect(tester);
    expect(currentThumbScale(tester), 1);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Child 2')));
    await tester.pump();

    // Does not move until tapUp.
    expect(currentThumbScale(tester), 1);
    expect(currentUnscaledThumbRect(tester), initialRect);

    // Tap up and the sliding animation should play.
    await gesture.up();
    await tester.pump();

    expect(currentThumbScale(tester), 1);
    expect(currentUnscaledThumbRect(tester).center.dy, lessThan(initialRect.center.dy));

    await tester.pumpAndSettle();

    expect(currentThumbScale(tester), 1);
    expect(currentUnscaledThumbRect(tester).center, tester.getCenter(find.text('Child 2')));

    // Press the currently selected widget.
    await gesture.down(tester.getCenter(find.text('Child 2')));
    await tester.pump();

    // The thumb shrinks but does not moves towards left.
    expect(currentThumbScale(tester), lessThan(1));
    expect(currentUnscaledThumbRect(tester).center, tester.getCenter(find.text('Child 2')));

    await tester.pumpAndSettle();
    expect(currentThumbScale(tester), 0.95);
    expect(currentUnscaledThumbRect(tester).center, tester.getCenter(find.text('Child 2')));

    // Drag to Child 1.
    await gesture.moveTo(tester.getCenter(find.text('Child 1')));
    await tester.pump();

    // Moved slightly to the left
    expect(currentThumbScale(tester), 0.95);
    expect(currentUnscaledThumbRect(tester).center.dx, greaterThan(tester.getCenter(find.text('Child 2')).dx));

    await tester.pumpAndSettle();
    expect(currentThumbScale(tester), 0.95);
    expect(currentUnscaledThumbRect(tester).center, tester.getCenter(find.text('Child 1')));

    await gesture.up();
    await tester.pump();
    expect(currentThumbScale(tester), greaterThan(0.95));

    await tester.pumpAndSettle();
    expect(currentThumbScale(tester), 1);
  });

  testWidgets('Transition is triggered while a transition is already occurring', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('A');
    children[1] = const Text('B');
    children[2] = const Text('C');
    final ValueNotifier<int> controller = ValueNotifier<int>(0);

    await tester.pumpWidget(
      boilerplate(
        child: CupertinoSlidingSegmentedControl<int>(
          key: const ValueKey<String>('Segmented Control'),
          children: children,
          controller: controller,
        ),
      ),
    );

    await tester.tap(find.text('B'));

    await tester.pump(const Duration(milliseconds: 40));

    // Between A and B.
    final Rect initialThumbRect = currentUnscaledThumbRect(tester);
    expect(initialThumbRect.center.dx, greaterThan(tester.getCenter(find.text('A')).dx));
    expect(initialThumbRect.center.dx, lessThan(tester.getCenter(find.text('B')).dx));

    // While A to B transition is occurring, press on C.
    await tester.tap(find.text('C'));
    await tester.pump();

    final Rect secondThumbRect = currentUnscaledThumbRect(tester);

    // Between the initial Rect and B.
    expect(secondThumbRect.center.dx, initialThumbRect.center.dx);
    expect(initialThumbRect.center.dx, lessThan(tester.getCenter(find.text('B')).dx));

    await tester.pump(const Duration(milliseconds: 500));

    // Eventually moves to C.
    expect(currentUnscaledThumbRect(tester).center, tester.getCenter(find.text('C')));
  });

  testWidgets('Insert segment while animation is running', (WidgetTester tester) async {
    final Map<int, Widget> children = SplayTreeMap<int, Widget>(
      (int a, int b) => a - b,
      (dynamic key) => true,
    );

    children[0] = const Text('A');
    children[2] = const Text('C');
    children[3] = const Text('D');

    final ValueNotifier<int> controller = ValueNotifier<int>(0);

    await tester.pumpWidget(
      boilerplate(
        child: CupertinoSlidingSegmentedControl<int>(
          key: const ValueKey<String>('Segmented Control'),
          children: children,
          controller: controller,
        ),
      ),
    );

    await tester.tap(find.text('D'));
    await tester.pump(const Duration(milliseconds: 40));

    children[1] = const Text('B');
    await tester.pumpWidget(
      boilerplate(
        child: CupertinoSlidingSegmentedControl<int>(
          key: const ValueKey<String>('Segmented Control'),
          children: children,
          controller: controller,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    // Eventually moves to D.
    expect(currentUnscaledThumbRect(tester).center, tester.getCenter(find.text('D')));
  });
}
