// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

dynamic getRenderSegmentedControl(WidgetTester tester) {
  return tester.allRenderObjects.firstWhere(
    (RenderObject currentObject) {
      return currentObject.toStringShort().contains('_RenderSegmentedControl');
    },
  );
}

StatefulBuilder setupSimpleSegmentedControl() {
  final Map<int, Widget> children = <int, Widget>{};
  children[0] = const Text('Child 1');
  children[1] = const Text('Child 2');

  int sharedValue = 0;

  return new StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      return boilerplate(
        child: new SegmentedControl<int>(
          children: children,
          onValueChanged: (int newValue) {
            setState(() {
              sharedValue = newValue;
            });
          },
          groupValue: sharedValue,
        ),
      );
    },
  );
}

Widget boilerplate({Widget child}) {
  return new Directionality(
    textDirection: TextDirection.ltr,
    child: new Center(child: child),
  );
}

void main() {
  testWidgets('Tap changes toggle state', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');
    children[2] = const Text('Child 3');

    int sharedValue = 0;

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: new SegmentedControl<int>(
              key: const ValueKey<String>('Segmented Control'),
              children: children,
              onValueChanged: (int newValue) {
                setState(() {
                  sharedValue = newValue;
                });
              },
              groupValue: sharedValue,
            ),
          );
        },
      ),
    );

    expect(sharedValue, 0);

    await tester.tap(find.byKey(const ValueKey<String>('Segmented Control')));

    expect(sharedValue, 1);
  });

  testWidgets('Need at least 2 children', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    try {
      await tester.pumpWidget(
        boilerplate(
          child: new SegmentedControl<int>(
            children: children,
            onValueChanged: (int newValue) {},
          ),
        ),
      );
      fail(
          'Should not be possible to create a segmented control with no children');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('children.length'));
    }
    try {
      children[0] = const Text('Child 1');

      await tester.pumpWidget(
        boilerplate(
          child: new SegmentedControl<int>(
            children: children,
            onValueChanged: (int newValue) {},
          ),
        ),
      );
      fail(
          'Should not be possible to create a segmented control with just one child');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('children.length'));
    }
  });

  testWidgets('Value attribute must be the key of one of the children widgets',
      (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    try {
      await tester.pumpWidget(
        boilerplate(
          child: new SegmentedControl<int>(
            children: children,
            onValueChanged: (int newValue) {},
            groupValue: 2,
          ),
        ),
      );
      fail('Should not be possible to create segmented control in which '
          'value is not the key of one of the children widgets');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('children'));
    }
  });

  testWidgets('Children and onValueChanged can not be null',
      (WidgetTester tester) async {
    try {
      await tester.pumpWidget(
        boilerplate(
          child: new SegmentedControl<int>(
            children: null,
            onValueChanged: (int newValue) {},
          ),
        ),
      );
      fail(
          'Should not be possible to create segmented control with null children');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('children'));
    }

    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    try {
      await tester.pumpWidget(
        boilerplate(
          child: new SegmentedControl<int>(
            children: children,
            onValueChanged: null,
          ),
        ),
      );
      fail(
          'Should not be possible to create segmented control with null onValueChanged');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('onValueChanged'));
    }
  });

  testWidgets(
      'Widgets have correct default text/icon styles, change correctly on selection',
      (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Icon(IconData(1));

    int sharedValue = 0;

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: new SegmentedControl<int>(
              children: children,
              onValueChanged: (int newValue) {
                setState(() {
                  sharedValue = newValue;
                });
              },
              groupValue: sharedValue,
            ),
          );
        },
      ),
    );

    DefaultTextStyle textStyle =
        tester.widget(find.widgetWithText(DefaultTextStyle, 'Child 1'));
    IconTheme iconTheme =
        tester.widget(find.widgetWithIcon(IconTheme, const IconData(1)));

    expect(textStyle.style.color, CupertinoColors.white);
    expect(iconTheme.data.color, CupertinoColors.activeBlue);

    await tester.tap(find.widgetWithIcon(IconTheme, const IconData(1)));
    await tester.pump();

    textStyle = tester.widget(find.widgetWithText(DefaultTextStyle, 'Child 1'));
    iconTheme =
        tester.widget(find.widgetWithIcon(IconTheme, const IconData(1)));

    expect(textStyle.style.color, CupertinoColors.activeBlue);
    expect(iconTheme.data.color, CupertinoColors.white);
  });

  testWidgets('Tap calls onValueChanged', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    bool value = false;

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: new SegmentedControl<int>(
              children: children,
              onValueChanged: (int newValue) {
                value = true;
              },
            ),
          );
        },
      ),
    );

    expect(value, isFalse);

    await tester.tap(find.text('Child 2'));

    expect(value, isTrue);
  });

  testWidgets(
      'State does not change if onValueChanged does not call setState()',
      (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    const int sharedValue = 0;

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: new SegmentedControl<int>(
              children: children,
              onValueChanged: (int newValue) {},
              groupValue: sharedValue,
            ),
          );
        },
      ),
    );

    final dynamic childList =
        getRenderSegmentedControl(tester).getChildrenAsList();

    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect(
          rrect: childList.elementAt(0).parentData.surroundingRect,
          color: CupertinoColors.activeBlue,
        ),
    );
    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect()
        ..rrect()
        ..rrect(
          rrect: childList.elementAt(1).parentData.surroundingRect,
          color: CupertinoColors.white,
        ),
    );

    await tester.tap(find.text('Child 2'));
    await tester.pump();

    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect(
          rrect: childList.elementAt(0).parentData.surroundingRect,
          color: CupertinoColors.activeBlue,
        ),
    );
    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect()
        ..rrect()
        ..rrect(
          rrect: childList.elementAt(1).parentData.surroundingRect,
          color: CupertinoColors.white,
        ),
    );
  });

  testWidgets(
      'Background color of child should change on selection, '
      'and should not change when tapped again', (WidgetTester tester) async {
    await tester.pumpWidget(setupSimpleSegmentedControl());

    final dynamic childList =
        getRenderSegmentedControl(tester).getChildrenAsList();

    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect()
        ..rrect()
        ..rrect(
          rrect: childList.elementAt(1).parentData.surroundingRect,
          color: CupertinoColors.white,
        ),
    );

    await tester.tap(find.text('Child 2'));
    await tester.pump();

    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect()
        ..rrect()
        ..rrect(
          rrect: childList.elementAt(1).parentData.surroundingRect,
          color: CupertinoColors.activeBlue,
        ),
    );

    await tester.tap(find.text('Child 2'));
    await tester.pump();

    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect()
        ..rrect()
        ..rrect(
          rrect: childList.elementAt(1).parentData.surroundingRect,
          color: CupertinoColors.activeBlue,
        ),
    );
  });

  testWidgets(
    'Children can be non-Text or Icon widgets (in this case, '
        'a Container or Placeholder widget)',
    (WidgetTester tester) async {
      final Map<int, Widget> children = <int, Widget>{};
      children[0] = const Text('Child 1');
      children[1] = new Container(
        constraints: const BoxConstraints.tightFor(width: 50.0, height: 50.0),
      );
      children[2] = const Placeholder();

      int sharedValue = 0;

      await tester.pumpWidget(
        new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return boilerplate(
              child: new SegmentedControl<int>(
                children: children,
                onValueChanged: (int newValue) {
                  setState(() {
                    sharedValue = newValue;
                  });
                },
                groupValue: sharedValue,
              ),
            );
          },
        ),
      );
    },
  );

  testWidgets('Passed in value is child initially selected',
      (WidgetTester tester) async {
    await tester.pumpWidget(setupSimpleSegmentedControl());

    expect(getRenderSegmentedControl(tester).selectedIndex, 0);

    final dynamic childList =
        getRenderSegmentedControl(tester).getChildrenAsList();

    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect(
          rrect: childList.elementAt(0).parentData.surroundingRect,
          color: CupertinoColors.activeBlue,
        ),
    );
    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect()
        ..rrect()
        ..rrect(
          rrect: childList.elementAt(1).parentData.surroundingRect,
          color: CupertinoColors.white,
        ),
    );
  });

  testWidgets('Null input for value results in no child initially selected',
      (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    int sharedValue;

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: new SegmentedControl<int>(
              children: children,
              onValueChanged: (int newValue) {
                setState(() {
                  sharedValue = newValue;
                });
              },
              groupValue: sharedValue,
            ),
          );
        },
      ),
    );

    expect(getRenderSegmentedControl(tester).selectedIndex, null);

    final dynamic childList =
        getRenderSegmentedControl(tester).getChildrenAsList();

    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect(
          rrect: childList.elementAt(0).parentData.surroundingRect,
          color: CupertinoColors.white,
        ),
    );
    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect()
        ..rrect()
        ..rrect(
          rrect: childList.elementAt(1).parentData.surroundingRect,
          color: CupertinoColors.white,
        ),
    );
  });

  testWidgets('Long press changes background color of not-selected child',
      (WidgetTester tester) async {
    await tester.pumpWidget(setupSimpleSegmentedControl());

    final dynamic childList =
        getRenderSegmentedControl(tester).getChildrenAsList();

    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect(
          rrect: childList.elementAt(0).parentData.surroundingRect,
          color: CupertinoColors.activeBlue,
        ),
    );
    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect()
        ..rrect()
        ..rrect(
          rrect: childList.elementAt(1).parentData.surroundingRect,
          color: CupertinoColors.white,
        ),
    );

    final Offset center = tester.getCenter(find.text('Child 2'));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect(
          rrect: childList.elementAt(0).parentData.surroundingRect,
          color: CupertinoColors.activeBlue,
        ),
    );
    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect()
        ..rrect()
        ..rrect(
          rrect: childList.elementAt(1).parentData.surroundingRect,
          color: const Color(0x33007aff),
        ),
    );
  });

  testWidgets(
      'Long press does not change background color of currently-selected child',
      (WidgetTester tester) async {
    await tester.pumpWidget(setupSimpleSegmentedControl());

    final dynamic childList =
        getRenderSegmentedControl(tester).getChildrenAsList();

    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect(
          rrect: childList.elementAt(0).parentData.surroundingRect,
          color: CupertinoColors.activeBlue,
        ),
    );
    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect()
        ..rrect()
        ..rrect(
          rrect: childList.elementAt(1).parentData.surroundingRect,
          color: CupertinoColors.white,
        ),
    );

    final Offset center = tester.getCenter(find.text('Child 1'));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect(
          rrect: childList.elementAt(0).parentData.surroundingRect,
          color: CupertinoColors.activeBlue,
        ),
    );
    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect()
        ..rrect()
        ..rrect(
          rrect: childList.elementAt(1).parentData.surroundingRect,
          color: CupertinoColors.white,
        ),
    );
  });

  testWidgets('Height of segmented control is determined by tallest widget',
      (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = new Container(
      constraints: const BoxConstraints.tightFor(height: 100.0),
    );
    children[1] = new Container(
      constraints: const BoxConstraints.tightFor(height: 400.0),
    );
    children[2] = new Container(
      constraints: const BoxConstraints.tightFor(height: 200.0),
    );

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: new SegmentedControl<int>(
              key: const ValueKey<String>('Segmented Control'),
              children: children,
              onValueChanged: (int newValue) {},
            ),
          );
        },
      ),
    );

    final RenderBox buttonBox = tester
        .renderObject(find.byKey(const ValueKey<String>('Segmented Control')));

    // Default height of Placeholder is 400.0px, which is greater than heights
    // of other child widgets.
    expect(buttonBox.size.height, 400.0);
  });

  testWidgets('Width of each child widget is the same',
      (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = new Container();
    children[1] = const Placeholder();
    children[2] = new Container();

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: new SegmentedControl<int>(
              key: const ValueKey<String>('Segmented Control'),
              children: children,
              onValueChanged: (int newValue) {},
            ),
          );
        },
      ),
    );

    final RenderBox segmentedControl = tester
        .renderObject(find.byKey(const ValueKey<String>('Segmented Control')));

    // Subtract the 16.0px from each side. Remaining width should be allocated
    // to each child equally.
    final double childWidth = (segmentedControl.size.width - 32.0) / 3;

    final dynamic childList =
        getRenderSegmentedControl(tester).getChildrenAsList();

    for (dynamic child in childList) {
      expect(childWidth, child.parentData.surroundingRect.width);
    }
  });

  testWidgets('Width is finite in unbounded space',
      (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: Row(
              children: <Widget>[
                new SegmentedControl<int>(
                  key: const ValueKey<String>('Segmented Control'),
                  children: children,
                  onValueChanged: (int newValue) {},
                ),
              ],
            ),
          );
        },
      ),
    );

    final RenderBox segmentedControl = tester
        .renderObject(find.byKey(const ValueKey<String>('Segmented Control')));

    expect(segmentedControl.size.width.isFinite, isTrue);
  });

  testWidgets('Directionality test - RTL should reverse order of widgets',
      (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: new Center(
          child: new SegmentedControl<int>(
            children: children,
            onValueChanged: (int newValue) {},
          ),
        ),
      ),
    );

    expect(
        tester.getTopRight(find.text('Child 1')).dx >
            tester.getTopRight(find.text('Child 2')).dx,
        isTrue);
  });

  testWidgets('Correct initial selection and toggling behavior - RTL',
      (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    int sharedValue = 0;

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: new Center(
              child: new SegmentedControl<int>(
                children: children,
                onValueChanged: (int newValue) {
                  setState(() {
                    sharedValue = newValue;
                  });
                },
                groupValue: sharedValue,
              ),
            ),
          );
        },
      ),
    );

    final dynamic childList =
        getRenderSegmentedControl(tester).getChildrenAsList();

    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect(
          rrect: childList.elementAt(0).parentData.surroundingRect,
          color: CupertinoColors.activeBlue,
        ),
    );
    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect()
        ..rrect()
        ..rrect(
          rrect: childList.elementAt(1).parentData.surroundingRect,
          color: CupertinoColors.white,
        ),
    );

    await tester.tap(find.text('Child 2'));
    await tester.pump();

    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect(
          rrect: childList.elementAt(0).parentData.surroundingRect,
          color: CupertinoColors.white,
        ),
    );
    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect()
        ..rrect()
        ..rrect(
          rrect: childList.elementAt(1).parentData.surroundingRect,
          color: CupertinoColors.activeBlue,
        ),
    );

    await tester.tap(find.text('Child 2'));
    await tester.pump();

    expect(
      getRenderSegmentedControl(tester),
      paints
        ..rrect()
        ..rrect()
        ..rrect(
          rrect: childList.elementAt(1).parentData.surroundingRect,
          color: CupertinoColors.activeBlue,
        ),
    );
  });

  testWidgets('Segmented control semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');
    int sharedValue = 0;

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: new Center(
              child: new SegmentedControl<int>(
                children: children,
                onValueChanged: (int newValue) {
                  setState(() {
                    sharedValue = newValue;
                  });
                },
                groupValue: sharedValue,
              ),
            ),
          );
        },
      ),
    );

    expect(
        semantics,
        hasSemantics(
          new TestSemantics.root(
            children: <TestSemantics>[
              new TestSemantics.rootChild(
                label: 'Child 1',
                flags: <SemanticsFlag>[
                  SemanticsFlag.isInMutuallyExclusiveGroup,
                  SemanticsFlag.isSelected,
                ],
                actions: <SemanticsAction>[
                  SemanticsAction.tap,
                ],
              ),
              new TestSemantics.rootChild(
                label: 'Child 2',
                flags: <SemanticsFlag>[
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
        ));

    await tester.tap(find.text('Child 2'));
    await tester.pump();

    expect(
        semantics,
        hasSemantics(
          new TestSemantics.root(
            children: <TestSemantics>[
              new TestSemantics.rootChild(
                label: 'Child 1',
                flags: <SemanticsFlag>[
                  SemanticsFlag.isInMutuallyExclusiveGroup,
                ],
                actions: <SemanticsAction>[
                  SemanticsAction.tap,
                ],
              ),
              new TestSemantics.rootChild(
                label: 'Child 2',
                flags: <SemanticsFlag>[
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

  testWidgets('Golden Test Placeholder Widget', (WidgetTester tester) async {
    // Different machines render this content differently. Since the golden
    // files are rendered on MacOS, this test should only be run on MacOS.
    // If the golden files are regenerated on another OS, please change this
    // test to only run on that OS.
    if (Platform.isMacOS)
      return;

    final Map<int, Widget> children = <int, Widget>{};
    children[0] = new Container();
    children[1] = const Placeholder();
    children[2] = new Container();

    const int currentValue = 0;

    await tester.pumpWidget(
      new RepaintBoundary(
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return boilerplate(
              child: new SegmentedControl<int>(
                key: const ValueKey<String>('Segmented Control'),
                children: children,
                onValueChanged: (int newValue) {},
                groupValue: currentValue,
              ),
            );
          },
        ),
      ),
    );

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('segmented_control_test.0.0.png'),
    );
  });

  testWidgets('Golden Test Pressed State', (WidgetTester tester) async {
    // Different machines render this content differently. Since the golden
    // files are rendered on MacOS, this test should only be run on MacOS.
    // If the golden files are regenerated on another OS, please change this
    // test to only run on that OS.
    if (!Platform.isMacOS)
      return;

    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('A');
    children[1] = const Text('B');
    children[2] = const Text('C');

    const int currentValue = 0;

    await tester.pumpWidget(
      new RepaintBoundary(
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return boilerplate(
              child: new SegmentedControl<int>(
                key: const ValueKey<String>('Segmented Control'),
                children: children,
                onValueChanged: (int newValue) {},
                groupValue: currentValue,
              ),
            );
          },
        ),
      ),
    );

    final Offset center = tester.getCenter(find.text('B'));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('segmented_control_test.1.0.png'),
    );
  });
}
