// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

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

StatefulBuilder setupSimpleSegmentedControl() {
  final Map<int, Widget> children = <int, Widget>{};
  children[0] = const Text('Child 1');
  children[1] = const Text('Child 2');
  int sharedValue = 0;

  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      return boilerplate(
        child: CupertinoSegmentedControl<int>(
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
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  );
}

Color getBackgroundColor(WidgetTester tester, int childIndex) {
  return getRenderSegmentedControl(tester).backgroundColors[childIndex];
}

void main() {
  testWidgets('Tap changes toggle state', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');
    children[2] = const Text('Child 3');

    int sharedValue = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
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
          child: CupertinoSegmentedControl<int>(
            children: children,
            onValueChanged: (int newValue) {},
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
          child: CupertinoSegmentedControl<int>(
            children: children,
            onValueChanged: (int newValue) {},
          ),
        ),
      );
      fail('Should not be possible to create a segmented control with just one child');
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
          child: CupertinoSegmentedControl<int>(
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

  testWidgets('Children, onValueChanged, and color arguments can not be null',
          (WidgetTester tester) async {
    try {
      await tester.pumpWidget(
        boilerplate(
          child: CupertinoSegmentedControl<int>(
            children: null,
            onValueChanged: (int newValue) {},
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
          child: CupertinoSegmentedControl<int>(
            children: children,
            onValueChanged: null,
          ),
        ),
      );
      fail('Should not be possible to create segmented control with null onValueChanged');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('onValueChanged'));
    }

    try {
      await tester.pumpWidget(
        boilerplate(
          child: CupertinoSegmentedControl<int>(
            children: children,
            onValueChanged: (int newValue) {},
            unselectedColor: null,
          ),
        ),
      );
      fail('Should not be possible to create segmented control with null unselectedColor');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('unselectedColor'));
    }
  });

  testWidgets('Widgets have correct default text/icon styles, change correctly on selection',
          (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Icon(IconData(1));

    int sharedValue = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
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

  testWidgets('SegmentedControl is correct when user provides custom colors',
          (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Icon(IconData(1));

    int sharedValue = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
              children: children,
              onValueChanged: (int newValue) {
                setState(() {
                  sharedValue = newValue;
                });
              },
              groupValue: sharedValue,
              unselectedColor: CupertinoColors.lightBackgroundGray,
              selectedColor: CupertinoColors.activeGreen,
              borderColor: CupertinoColors.black,
              pressedColor: const Color(0x638CFC7B),
            ),
          );
          },
      ),
    );

    DefaultTextStyle textStyle = tester.widget(find.widgetWithText(DefaultTextStyle, 'Child 1'));
    IconTheme iconTheme = tester.widget(find.widgetWithIcon(IconTheme, const IconData(1)));

    expect(getRenderSegmentedControl(tester).borderColor, CupertinoColors.black);
    expect(textStyle.style.color, CupertinoColors.lightBackgroundGray);
    expect(iconTheme.data.color, CupertinoColors.activeGreen);
    expect(getBackgroundColor(tester, 0), CupertinoColors.activeGreen);
    expect(getBackgroundColor(tester, 1), CupertinoColors.lightBackgroundGray);

    await tester.tap(find.widgetWithIcon(IconTheme, const IconData(1)));
    await tester.pumpAndSettle();

    textStyle = tester.widget(find.widgetWithText(DefaultTextStyle, 'Child 1'));
    iconTheme = tester.widget(find.widgetWithIcon(IconTheme, const IconData(1)));

    expect(textStyle.style.color, CupertinoColors.activeGreen);
    expect(iconTheme.data.color, CupertinoColors.lightBackgroundGray);
    expect(getBackgroundColor(tester, 0), CupertinoColors.lightBackgroundGray);
    expect(getBackgroundColor(tester, 1), CupertinoColors.activeGreen);

    final Offset center = tester.getCenter(find.text('Child 1'));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    expect(getBackgroundColor(tester, 0), const Color(0x638CFC7B));
    expect(getBackgroundColor(tester, 1), CupertinoColors.activeGreen);
  });

  testWidgets('Widgets are centered within segments', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200.0,
            height: 200.0,
            child: CupertinoSegmentedControl<int>(
              children: children,
              onValueChanged: (int newValue) {},
            ),
          ),
        ),
      ),
    );

    // Widgets are centered taking into account 16px of horizontal padding
    expect(tester.getCenter(find.text('Child 1')), const Offset(58.0, 100.0));
    expect(tester.getCenter(find.text('Child 2')), const Offset(142.0, 100.0));
  });

  testWidgets('Tap calls onValueChanged', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    bool value = false;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
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

  testWidgets('State does not change if onValueChanged does not call setState()',
          (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    const int sharedValue = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
              children: children,
              onValueChanged: (int newValue) {},
              groupValue: sharedValue,
            ),
          );
        },
      ),
    );

    expect(getBackgroundColor(tester, 0), CupertinoColors.activeBlue);
    expect(getBackgroundColor(tester, 1), CupertinoColors.white);

    await tester.tap(find.text('Child 2'));
    await tester.pump();

    expect(getBackgroundColor(tester, 0), CupertinoColors.activeBlue);
    expect(getBackgroundColor(tester, 1), CupertinoColors.white);
  });

  testWidgets(
      'Background color of child should change on selection, '
      'and should not change when tapped again', (WidgetTester tester) async {
    await tester.pumpWidget(setupSimpleSegmentedControl());

    expect(getBackgroundColor(tester, 1), CupertinoColors.white);

    await tester.tap(find.text('Child 2'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(getBackgroundColor(tester, 1), CupertinoColors.activeBlue);

    await tester.tap(find.text('Child 2'));
    await tester.pump();

    expect(getBackgroundColor(tester, 1), CupertinoColors.activeBlue);
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

      int sharedValue = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return boilerplate(
              child: CupertinoSegmentedControl<int>(
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

    expect(getBackgroundColor(tester, 0), CupertinoColors.activeBlue);
    expect(getBackgroundColor(tester, 1), CupertinoColors.white);
  });

  testWidgets('Null input for value results in no child initially selected',
          (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    int sharedValue;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
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

    expect(getBackgroundColor(tester, 0), CupertinoColors.white);
    expect(getBackgroundColor(tester, 1), CupertinoColors.white);
  });

  testWidgets('Long press changes background color of not-selected child',
          (WidgetTester tester) async {
    await tester.pumpWidget(setupSimpleSegmentedControl());

    expect(getBackgroundColor(tester, 0), CupertinoColors.activeBlue);
    expect(getBackgroundColor(tester, 1), CupertinoColors.white);

    final Offset center = tester.getCenter(find.text('Child 2'));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    expect(getBackgroundColor(tester, 0), CupertinoColors.activeBlue);
    expect(getBackgroundColor(tester, 1), const Color(0x33007aff));
  });

  testWidgets('Long press does not change background color of currently-selected child',
          (WidgetTester tester) async {
    await tester.pumpWidget(setupSimpleSegmentedControl());

    expect(getBackgroundColor(tester, 0), CupertinoColors.activeBlue);
    expect(getBackgroundColor(tester, 1), CupertinoColors.white);

    final Offset center = tester.getCenter(find.text('Child 1'));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    expect(getBackgroundColor(tester, 0), CupertinoColors.activeBlue);
    expect(getBackgroundColor(tester, 1), CupertinoColors.white);
  });

  testWidgets('Height of segmented control is determined by tallest widget',
          (WidgetTester tester) async {
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

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
              key: const ValueKey<String>('Segmented Control'),
              children: children,
              onValueChanged: (int newValue) {},
            ),
          );
        },
      ),
    );

    final RenderBox buttonBox = tester.renderObject(
        find.byKey(const ValueKey<String>('Segmented Control')));

    expect(buttonBox.size.height, 400.0);
  });

  testWidgets('Width of each segmented control segment is determined by widest widget',
          (WidgetTester tester) async {
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

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
              key: const ValueKey<String>('Segmented Control'),
              children: children,
              onValueChanged: (int newValue) {},
            ),
          );
        },
      ),
    );

    final RenderBox segmentedControl = tester.renderObject(
        find.byKey(const ValueKey<String>('Segmented Control')));

    // Subtract the 16.0px from each side. Remaining width should be allocated
    // to each child equally.
    final double childWidth = (segmentedControl.size.width - 32.0) / 3;

    expect(childWidth, 200.0);

    expect(childWidth,
        getRenderSegmentedControl(tester).getChildrenAsList()[0].parentData.surroundingRect.width);
    expect(childWidth,
        getRenderSegmentedControl(tester).getChildrenAsList()[1].parentData.surroundingRect.width);
    expect(childWidth,
        getRenderSegmentedControl(tester).getChildrenAsList()[2].parentData.surroundingRect.width);
  });

  testWidgets('Width is finite in unbounded space', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: Row(
              children: <Widget>[
                CupertinoSegmentedControl<int>(
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

    final RenderBox segmentedControl = tester.renderObject(
        find.byKey(const ValueKey<String>('Segmented Control')));

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
        child: Center(
          child: CupertinoSegmentedControl<int>(
            children: children,
            onValueChanged: (int newValue) {},
          ),
        ),
      ),
    );

    expect(tester.getTopRight(find.text('Child 1')).dx >
        tester.getTopRight(find.text('Child 2')).dx, isTrue);
  });

  testWidgets('Correct initial selection and toggling behavior - RTL',
          (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    int sharedValue = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: CupertinoSegmentedControl<int>(
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

    expect(getBackgroundColor(tester, 0), CupertinoColors.activeBlue);
    expect(getBackgroundColor(tester, 1), CupertinoColors.white);

    await tester.tap(find.text('Child 2'));
    await tester.pumpAndSettle();

    expect(getBackgroundColor(tester, 0), CupertinoColors.white);
    expect(getBackgroundColor(tester, 1), CupertinoColors.activeBlue);

    await tester.tap(find.text('Child 2'));
    await tester.pump();

    expect(getBackgroundColor(tester, 1), CupertinoColors.activeBlue);
  });

  testWidgets('Segmented control semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');
    int sharedValue = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: CupertinoSegmentedControl<int>(
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
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');

    int sharedValue = 1;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
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

    expect(sharedValue, 1);

    final double childWidth = getRenderSegmentedControl(tester).firstChild.size.width;
    final Offset centerOfSegmentedControl = tester.getCenter(find.text('Child 1'));

    // Tap just inside segment bounds
    await tester.tapAt(
      Offset(
        centerOfSegmentedControl.dx + (childWidth / 2) - 10.0,
        centerOfSegmentedControl.dy,
      ),
    );

    expect(sharedValue, 0);
  });

  testWidgets('Animation is correct when the selected segment changes',
          (WidgetTester tester) async {
    await tester.pumpWidget(setupSimpleSegmentedControl());

    await tester.tap(find.text('Child 2'));

    await tester.pump();
    expect(getBackgroundColor(tester, 0), CupertinoColors.activeBlue);
    expect(getBackgroundColor(tester, 1), const Color(0x33007aff));

    await tester.pump(const Duration(milliseconds: 40));
    expect(getBackgroundColor(tester, 0), const Color(0xff3d9aff));
    expect(getBackgroundColor(tester, 1), const Color(0x64007aff));

    await tester.pump(const Duration(milliseconds: 40));
    expect(getBackgroundColor(tester, 0), const Color(0xff7bbaff));
    expect(getBackgroundColor(tester, 1), const Color(0x95007aff));

    await tester.pump(const Duration(milliseconds: 40));
    expect(getBackgroundColor(tester, 0), const Color(0xffb9daff));
    expect(getBackgroundColor(tester, 1), const Color(0xc7007aff));

    await tester.pump(const Duration(milliseconds: 40));
    expect(getBackgroundColor(tester, 0), const Color(0xfff7faff));
    expect(getBackgroundColor(tester, 1), const Color(0xf8007aff));

    await tester.pump(const Duration(milliseconds: 40));
    expect(getBackgroundColor(tester, 0), CupertinoColors.white);
    expect(getBackgroundColor(tester, 1), CupertinoColors.activeBlue);
  });

  testWidgets('Animation is correct when widget is rebuilt', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('Child 1');
    children[1] = const Text('Child 2');
    int sharedValue = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
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

    await tester.tap(find.text('Child 2'));

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
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
    expect(getBackgroundColor(tester, 0), CupertinoColors.activeBlue);
    expect(getBackgroundColor(tester, 1), const Color(0x33007aff));

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
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
      const Duration(milliseconds: 40),
    );
    expect(getBackgroundColor(tester, 0), const Color(0xff3d9aff));
    expect(getBackgroundColor(tester, 1), const Color(0x64007aff));

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
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
      const Duration(milliseconds: 40),
    );
    expect(getBackgroundColor(tester, 0), const Color(0xff7bbaff));
    expect(getBackgroundColor(tester, 1), const Color(0x95007aff));

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
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
      const Duration(milliseconds: 40),
    );
    expect(getBackgroundColor(tester, 0), const Color(0xffb9daff));
    expect(getBackgroundColor(tester, 1), const Color(0xc7007aff));

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
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
      const Duration(milliseconds: 40),
    );
    expect(getBackgroundColor(tester, 0), const Color(0xfff7faff));
    expect(getBackgroundColor(tester, 1), const Color(0xf8007aff));

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
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
      const Duration(milliseconds: 40),
    );
    expect(getBackgroundColor(tester, 0), CupertinoColors.white);
    expect(getBackgroundColor(tester, 1), CupertinoColors.activeBlue);
  });

  testWidgets('Multiple segments are pressed', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('A');
    children[1] = const Text('B');
    children[2] = const Text('C');
    int sharedValue = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
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

    expect(getBackgroundColor(tester, 1), CupertinoColors.white);

    await tester.startGesture(tester.getCenter(find.text('B')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(getBackgroundColor(tester, 1), const Color(0x33007aff));
    expect(getBackgroundColor(tester, 2), CupertinoColors.white);

    await tester.startGesture(tester.getCenter(find.text('C')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // Press on C has no effect while B is held down.
    expect(getBackgroundColor(tester, 1), const Color(0x33007aff));
    expect(getBackgroundColor(tester, 2), CupertinoColors.white);
  });

  testWidgets('Transition is triggered while a transition is already occurring',
          (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('A');
    children[1] = const Text('B');
    children[2] = const Text('C');
    int sharedValue = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
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

    await tester.tap(find.text('B'));

    await tester.pump();
    expect(getBackgroundColor(tester, 0), CupertinoColors.activeBlue);
    expect(getBackgroundColor(tester, 1), const Color(0x33007aff));

    await tester.pump(const Duration(milliseconds: 40));
    expect(getBackgroundColor(tester, 0), const Color(0xff3d9aff));
    expect(getBackgroundColor(tester, 1), const Color(0x64007aff));

    // While A to B transition is occurring, press on C.
    await tester.tap(find.text('C'));

    await tester.pump();

    // A and B are now both transitioning to white.
    expect(getBackgroundColor(tester, 0), const Color(0xff3d9aff));
    expect(getBackgroundColor(tester, 1), const Color(0xffc1deff));
    expect(getBackgroundColor(tester, 2), const Color(0x33007aff));

    await tester.pump(const Duration(milliseconds: 40));
    // B background color has reached unselected state.
    expect(getBackgroundColor(tester, 0), const Color(0xff7bbaff));
    expect(getBackgroundColor(tester, 1), CupertinoColors.white);
    expect(getBackgroundColor(tester, 2), const Color(0x64007aff));

    await tester.pump(const Duration(milliseconds: 100));
    // A background color has reached unselected state.
    expect(getBackgroundColor(tester, 0), CupertinoColors.white);
    expect(getBackgroundColor(tester, 2), const Color(0xe0007aff));

    await tester.pump(const Duration(milliseconds: 40));
    // C background color has reached selected state.
    expect(getBackgroundColor(tester, 2), CupertinoColors.activeBlue);
  });

  testWidgets('Segment is selected while it is transitioning to unselected state',
          (WidgetTester tester) async {
    await tester.pumpWidget(setupSimpleSegmentedControl());

    await tester.tap(find.text('Child 2'));

    await tester.pump();
    expect(getBackgroundColor(tester, 0), CupertinoColors.activeBlue);
    expect(getBackgroundColor(tester, 1), const Color(0x33007aff));

    await tester.pump(const Duration(milliseconds: 40));
    expect(getBackgroundColor(tester, 0), const Color(0xff3d9aff));
    expect(getBackgroundColor(tester, 1), const Color(0x64007aff));

    // While A to B transition is occurring, press on A again.
    await tester.tap(find.text('Child 1'));

    await tester.pump();

    // Both transitions start to reverse.
    expect(getBackgroundColor(tester, 0), const Color(0xcd007aff));
    expect(getBackgroundColor(tester, 1), const Color(0xffc1deff));

    await tester.pump(const Duration(milliseconds: 40));
    // A and B finish transitioning.
    expect(getBackgroundColor(tester, 0), CupertinoColors.activeBlue);
    expect(getBackgroundColor(tester, 1), CupertinoColors.white);
  });

  testWidgets('Add segment while animation is running', (WidgetTester tester) async {
    Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('A');
    children[1] = const Text('B');
    children[2] = const Text('C');
    int sharedValue = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
              key: const ValueKey<String>('Segmented Control'),
              children: children,
              onValueChanged: (int newValue) {
                setState(() {
                  sharedValue = newValue;
                });
                if (sharedValue == 1) {
                  children = Map<int, Widget>.from(children);
                  children[3] = const Text('D');
                }
              },
              groupValue: sharedValue,
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('B'));

    await tester.pump();
    expect(getBackgroundColor(tester, 0), const Color(0xff007aff));
    expect(getBackgroundColor(tester, 1), const Color(0x33007aff));
    expect(getBackgroundColor(tester, 3), CupertinoColors.white);

    await tester.pump(const Duration(milliseconds: 40));
    expect(getBackgroundColor(tester, 0), const Color(0xff3d9aff));
    expect(getBackgroundColor(tester, 1), const Color(0x64007aff));
    expect(getBackgroundColor(tester, 3), CupertinoColors.white);

    await tester.pump(const Duration(milliseconds: 150));
    expect(getBackgroundColor(tester, 0), CupertinoColors.white);
    expect(getBackgroundColor(tester, 1), CupertinoColors.activeBlue);
    expect(getBackgroundColor(tester, 3), CupertinoColors.white);
  });

  testWidgets('Remove segment while animation is running', (WidgetTester tester) async {
    Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('A');
    children[1] = const Text('B');
    children[2] = const Text('C');
    int sharedValue = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
              key: const ValueKey<String>('Segmented Control'),
              children: children,
              onValueChanged: (int newValue) {
                setState(() {
                  sharedValue = newValue;
                });
                if (sharedValue == 1) {
                  children.remove(2);
                  children = Map<int, Widget>.from(children);
                }
              },
              groupValue: sharedValue,
            ),
          );
        },
      ),
    );

    expect(getRenderSegmentedControl(tester).getChildrenAsList().length, 3);

    await tester.tap(find.text('B'));

    await tester.pump();
    expect(getBackgroundColor(tester, 1), const Color(0x33007aff));
    expect(getRenderSegmentedControl(tester).getChildrenAsList().length, 2);

    await tester.pump(const Duration(milliseconds: 40));
    expect(getBackgroundColor(tester, 1), const Color(0x64007aff));

    await tester.pump(const Duration(milliseconds: 150));
    expect(getBackgroundColor(tester, 1), CupertinoColors.activeBlue);
  });

  testWidgets('Remove currently animating segment', (WidgetTester tester) async {
    Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('A');
    children[1] = const Text('B');
    children[2] = const Text('C');
    int sharedValue = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoSegmentedControl<int>(
              key: const ValueKey<String>('Segmented Control'),
              children: children,
              onValueChanged: (int newValue) {
                setState(() {
                  sharedValue = newValue;
                });
                if (sharedValue == 1) {
                  children.remove(1);
                  children = Map<int, Widget>.from(children);
                  sharedValue = null;
                }
              },
              groupValue: sharedValue,
            ),
          );
        },
      ),
    );

    expect(getRenderSegmentedControl(tester).getChildrenAsList().length, 3);

    await tester.tap(find.text('B'));

    await tester.pump();
    expect(getRenderSegmentedControl(tester).getChildrenAsList().length, 2);

    await tester.pump(const Duration(milliseconds: 40));
    expect(getBackgroundColor(tester, 0), const Color(0xff3d9aff));
    expect(getBackgroundColor(tester, 1), CupertinoColors.white);

    await tester.pump(const Duration(milliseconds: 40));
    expect(getBackgroundColor(tester, 0), const Color(0xff7bbaff));
    expect(getBackgroundColor(tester, 1), CupertinoColors.white);

    await tester.pump(const Duration(milliseconds: 100));
    expect(getBackgroundColor(tester, 0), CupertinoColors.white);
    expect(getBackgroundColor(tester, 1), CupertinoColors.white);
  });

  testWidgets('Golden Test Placeholder Widget', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = Container();
    children[1] = const Placeholder();
    children[2] = Container();

    const int currentValue = 0;

    await tester.pumpWidget(
      RepaintBoundary(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return boilerplate(
              child: SizedBox(
                width: 800.0,
                child: CupertinoSegmentedControl<int>(
                  key: const ValueKey<String>('Segmented Control'),
                  children: children,
                  onValueChanged: (int newValue) {},
                  groupValue: currentValue,
                ),
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
  }, skip: !Platform.isLinux);

  testWidgets('Golden Test Pressed State', (WidgetTester tester) async {
    final Map<int, Widget> children = <int, Widget>{};
    children[0] = const Text('A');
    children[1] = const Text('B');
    children[2] = const Text('C');

    const int currentValue = 0;

    await tester.pumpWidget(
      RepaintBoundary(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return boilerplate(
              child: SizedBox(
                width: 800.0,
                child: CupertinoSegmentedControl<int>(
                  key: const ValueKey<String>('Segmented Control'),
                  children: children,
                  onValueChanged: (int newValue) {},
                  groupValue: currentValue,
                ),
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
  }, skip: !Platform.isLinux);
}
