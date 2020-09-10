// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui' show window;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';
import 'feedback_tester.dart';

Finder findRenderChipElement() {
  return find.byElementPredicate((Element e) => '${e.runtimeType}' == '_RenderChipElement');
}

RenderBox getMaterialBox(WidgetTester tester) {
  return tester.firstRenderObject<RenderBox>(
    find.descendant(
      of: find.byType(RawChip),
      matching: find.byType(CustomPaint),
    ),
  );
}

Material getMaterial(WidgetTester tester) {
  return tester.widget<Material>(
    find.descendant(
      of: find.byType(RawChip),
      matching: find.byType(Material),
    ),
  );
}

IconThemeData getIconData(WidgetTester tester) {
  final IconTheme iconTheme = tester.firstWidget(
    find.descendant(
      of: find.byType(RawChip),
      matching: find.byType(IconTheme),
    ),
  );
  return iconTheme.data;
}

DefaultTextStyle getLabelStyle(WidgetTester tester) {
  return tester.widget(
    find.descendant(
      of: find.byType(RawChip),
      matching: find.byType(DefaultTextStyle),
    ).last,
  );
}

dynamic getRenderChip(WidgetTester tester) {
  if (!tester.any(findRenderChipElement())) {
    return null;
  }
  final Element element = tester.element(findRenderChipElement());
  return element.renderObject;
}

double getSelectProgress(WidgetTester tester) => getRenderChip(tester)?.checkmarkAnimation?.value as double;
double getAvatarDrawerProgress(WidgetTester tester) => getRenderChip(tester)?.avatarDrawerAnimation?.value as double;
double getDeleteDrawerProgress(WidgetTester tester) => getRenderChip(tester)?.deleteDrawerAnimation?.value as double;
double getEnableProgress(WidgetTester tester) => getRenderChip(tester)?.enableAnimation?.value as double;

/// Adds the basic requirements for a Chip.
Widget _wrapForChip({
  Widget child,
  TextDirection textDirection = TextDirection.ltr,
  double textScaleFactor = 1.0,
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window).copyWith(textScaleFactor: textScaleFactor),
        child: Material(child: child),
      ),
    ),
  );
}

/// Tests that a [Chip] that has its size constrained by its parent is
/// further constraining the size of its child, the label widget.
/// Optionally, adding an avatar or delete icon to the chip should not
/// cause the chip or label to exceed its constrained height.
Future<void> _testConstrainedLabel(
  WidgetTester tester, {
  CircleAvatar avatar,
  VoidCallback onDeleted,
}) async {
  const double labelWidth = 100.0;
  const double labelHeight = 50.0;
  const double chipParentWidth = 75.0;
  const double chipParentHeight = 25.0;
  final Key labelKey = UniqueKey();

  await tester.pumpWidget(
    _wrapForChip(
      child: Center(
        child: Container(
          width: chipParentWidth,
          height: chipParentHeight,
          child: Chip(
            avatar: avatar,
            label: Container(
              key: labelKey,
              width: labelWidth,
              height: labelHeight,
            ),
            onDeleted: onDeleted,
          ),
        ),
      ),
    ),
  );

  final Size labelSize = tester.getSize(find.byKey(labelKey));
  expect(labelSize.width, lessThan(chipParentWidth));
  expect(labelSize.height, lessThanOrEqualTo(chipParentHeight));

  final Size chipSize = tester.getSize(find.byType(Chip));
  expect(chipSize.width, chipParentWidth);
  expect(chipSize.height, chipParentHeight);
}

Widget _selectedInputChip({ Color checkmarkColor }) {
  return InputChip(
    label: const Text('InputChip'),
    selected: true,
    showCheckmark: true,
    checkmarkColor: checkmarkColor,
  );
}

Widget _selectedFilterChip({ Color checkmarkColor }) {
  return FilterChip(
    label: const Text('InputChip'),
    selected: true,
    showCheckmark: true,
    checkmarkColor: checkmarkColor,
    onSelected: (bool _) { },
  );
}

Future<void> _pumpCheckmarkChip(
  WidgetTester tester, {
  @required Widget chip,
  Color themeColor,
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    _wrapForChip(
      brightness: brightness,
      child: Builder(
        builder: (BuildContext context) {
          final ChipThemeData chipTheme = ChipTheme.of(context);
          return ChipTheme(
            data: themeColor == null ? chipTheme : chipTheme.copyWith(
              checkmarkColor: themeColor,
            ),
            child: chip,
          );
        },
      ),
    ),
  );
}

void _expectCheckmarkColor(Finder finder, Color color) {
  expect(
    finder,
    paints
      // The first path that is painted is the selection overlay. We do not care
      // how it is painted but it has to be added it to this pattern so that the
      // check mark can be checked next.
      ..path()
      // The second path that is painted is the check mark.
      ..path(color: color),
  );
}

Widget _chipWithOptionalDeleteButton({
  UniqueKey deleteButtonKey,
  UniqueKey labelKey,
  bool deletable,
  TextDirection textDirection = TextDirection.ltr,
}){
  return _wrapForChip(
    textDirection: textDirection,
    child: Wrap(
      children: <Widget>[
        RawChip(
          onPressed: () {},
          onDeleted: deletable ? () {} : null,
          deleteIcon: Icon(Icons.close, key: deleteButtonKey),
          label: Text(
            deletable
              ? 'Chip with Delete Button'
              : 'Chip without Delete Button',
            key: labelKey,
          ),
        ),
      ],
    ),
  );
}

bool offsetsAreClose(Offset a, Offset b) => (a - b).distance < 1.0;
bool radiiAreClose(double a, double b) => (a - b).abs() < 1.0;

// Ripple pattern matches if there exists at least one ripple
// with the [expectedCenter] and [expectedRadius].
// This ensures the existence of a ripple.
PaintPattern ripplePattern(Offset expectedCenter, double expectedRadius) {
  return paints
    ..something((Symbol method, List<dynamic> arguments) {
        if (method != #drawCircle)
          return false;
        final Offset center = arguments[0] as Offset;
        final double radius = arguments[1] as double;
        return offsetsAreClose(center, expectedCenter) && radiiAreClose(radius, expectedRadius);
      }
    );
}

// Unique ripple pattern matches if there does not exist ripples
// other than ones with the [expectedCenter] and [expectedRadius].
// This ensures the nonexistence of two different ripples.
PaintPattern uniqueRipplePattern(Offset expectedCenter, double expectedRadius) {
  return paints
    ..everything((Symbol method, List<dynamic> arguments) {
        if (method != #drawCircle)
          return true;
        final Offset center = arguments[0] as Offset;
        final double radius = arguments[1] as double;
        if (offsetsAreClose(center, expectedCenter) && radiiAreClose(radius, expectedRadius))
          return true;
        throw '''
              Expected: center == $expectedCenter, radius == $expectedRadius
              Found: center == $center radius == $radius''';
      }
    );
}

// Finds any container of a tooltip.
Finder findTooltipContainer(String tooltipText) {
  return find.ancestor(
    of: find.text(tooltipText),
    matching: find.byType(Container),
  );
}

void main() {
  testWidgets('Chip control test', (WidgetTester tester) async {
    final FeedbackTester feedback = FeedbackTester();
    final List<String> deletedChipLabels = <String>[];
    await tester.pumpWidget(
      _wrapForChip(
        child: Column(
          children: <Widget>[
            Chip(
              avatar: const CircleAvatar(child: Text('A')),
              label: const Text('Chip A'),
              onDeleted: () {
                deletedChipLabels.add('A');
              },
              deleteButtonTooltipMessage: 'Delete chip A',
            ),
            Chip(
              avatar: const CircleAvatar(child: Text('B')),
              label: const Text('Chip B'),
              onDeleted: () {
                deletedChipLabels.add('B');
              },
              deleteButtonTooltipMessage: 'Delete chip B',
            ),
          ],
        ),
      ),
    );

    expect(tester.widget(find.byTooltip('Delete chip A')), isNotNull);
    expect(tester.widget(find.byTooltip('Delete chip B')), isNotNull);

    expect(feedback.clickSoundCount, 0);

    expect(deletedChipLabels, isEmpty);
    await tester.tap(find.byTooltip('Delete chip A'));
    expect(deletedChipLabels, equals(<String>['A']));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(feedback.clickSoundCount, 1);

    await tester.tap(find.byTooltip('Delete chip B'));
    expect(deletedChipLabels, equals(<String>['A', 'B']));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(feedback.clickSoundCount, 2);

    feedback.dispose();
  });

  testWidgets(
    'Chip does not constrain size of label widget if it does not exceed '
    'the available space',
    (WidgetTester tester) async {
      const double labelWidth = 50.0;
      const double labelHeight = 30.0;
      final Key labelKey = UniqueKey();

      await tester.pumpWidget(
        _wrapForChip(
          child: Center(
            child: Container(
              width: 500.0,
              height: 500.0,
              child: Column(
                children: <Widget>[
                  Chip(
                    label: Container(
                      key: labelKey,
                      width: labelWidth,
                      height: labelHeight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final Size labelSize = tester.getSize(find.byKey(labelKey));
      expect(labelSize.width, labelWidth);
      expect(labelSize.height, labelHeight);
    },
  );

  testWidgets(
    'Chip constrains the size of the label widget when it exceeds the '
    'available space',
    (WidgetTester tester) async {
      await _testConstrainedLabel(tester);
    },
  );

  testWidgets(
    'Chip constrains the size of the label widget when it exceeds the '
    'available space and the avatar is present',
    (WidgetTester tester) async {
      await _testConstrainedLabel(
        tester,
        avatar: const CircleAvatar(child: Text('A')),
      );
    },
  );

  testWidgets(
    'Chip constrains the size of the label widget when it exceeds the '
    'available space and the delete icon is present',
    (WidgetTester tester) async {
      await _testConstrainedLabel(
        tester,
        onDeleted: () { },
      );
    },
  );

  testWidgets(
    'Chip constrains the size of the label widget when it exceeds the '
    'available space and both avatar and delete icons are present',
    (WidgetTester tester) async {
      await _testConstrainedLabel(
        tester,
        avatar: const CircleAvatar(child: Text('A')),
        onDeleted: () { },
      );
    },
  );

  testWidgets(
    'Chip constrains the avatar, label, and delete icons to the bounds of '
    'the chip when it exceeds the available space',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/11523
      Widget chipBuilder (String text, {Widget avatar, VoidCallback onDeleted}) {
        return MaterialApp(
          home: Scaffold(
            body: Container(
              width: 150,
              child: Column(
                children: <Widget>[
                  Chip(
                    avatar: avatar,
                    label: Text(text),
                    onDeleted: onDeleted,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      void chipRectContains(Rect chipRect, Rect rect) {
        expect(chipRect.contains(rect.topLeft), true);
        expect(chipRect.contains(rect.topRight), true);
        expect(chipRect.contains(rect.bottomLeft), true);
        expect(chipRect.contains(rect.bottomRight), true);
      }

      Rect chipRect;
      Rect avatarRect;
      Rect labelRect;
      Rect deleteIconRect;
      const String text = 'Very long text that will be clipped';

      await tester.pumpWidget(chipBuilder(text));

      chipRect = tester.getRect(find.byType(Chip));
      labelRect = tester.getRect(find.text(text));
      chipRectContains(chipRect, labelRect);

      await tester.pumpWidget(chipBuilder(
        text,
        avatar: const CircleAvatar(child: Text('A')),
      ));
      await tester.pumpAndSettle();

      chipRect = tester.getRect(find.byType(Chip));
      avatarRect = tester.getRect(find.byType(CircleAvatar));
      chipRectContains(chipRect, avatarRect);

      labelRect = tester.getRect(find.text(text));
      chipRectContains(chipRect, labelRect);

      await tester.pumpWidget(chipBuilder(
        text,
        avatar: const CircleAvatar(child: Text('A')),
        onDeleted: () {},
      ));
      await tester.pumpAndSettle();

      chipRect = tester.getRect(find.byType(Chip));
      avatarRect = tester.getRect(find.byType(CircleAvatar));
      chipRectContains(chipRect, avatarRect);

      labelRect = tester.getRect(find.text(text));
      chipRectContains(chipRect, labelRect);

      deleteIconRect = tester.getRect(find.byIcon(Icons.cancel));
      chipRectContains(chipRect, deleteIconRect);
    },
  );

  testWidgets('Chip in row works ok', (WidgetTester tester) async {
    const TextStyle style = TextStyle(fontFamily: 'Ahem', fontSize: 10.0);
    await tester.pumpWidget(
      _wrapForChip(
        child: Row(
          children: const <Widget>[
            Chip(label: Text('Test'), labelStyle: style),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(Text)), const Size(40.0, 10.0));
    expect(tester.getSize(find.byType(Chip)), const Size(64.0, 48.0));
    await tester.pumpWidget(
      _wrapForChip(
        child: Row(
          children: const <Widget>[
            Flexible(child: Chip(label: Text('Test'), labelStyle: style)),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(Text)), const Size(40.0, 10.0));
    expect(tester.getSize(find.byType(Chip)), const Size(64.0, 48.0));
    await tester.pumpWidget(
      _wrapForChip(
        child: Row(
          children: const <Widget>[
            Expanded(child: Chip(label: Text('Test'), labelStyle: style)),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(Text)), const Size(40.0, 10.0));
    expect(tester.getSize(find.byType(Chip)), const Size(800.0, 48.0));
  });

  testWidgets('Chip elements are ordered horizontally for locale', (WidgetTester tester) async {
    final UniqueKey iconKey = UniqueKey();
    final Widget test = Overlay(
      initialEntries: <OverlayEntry>[
        OverlayEntry(
          builder: (BuildContext context) {
            return Material(
              child: Chip(
                deleteIcon: Icon(Icons.delete, key: iconKey),
                onDeleted: () { },
                label: const Text('ABC'),
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      _wrapForChip(
        child: test,
        textDirection: TextDirection.rtl,
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(tester.getCenter(find.text('ABC')).dx, greaterThan(tester.getCenter(find.byKey(iconKey)).dx));
    await tester.pumpWidget(
      _wrapForChip(
        textDirection: TextDirection.ltr,
        child: test,
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(tester.getCenter(find.text('ABC')).dx, lessThan(tester.getCenter(find.byKey(iconKey)).dx));
  });

  testWidgets('Chip responds to textScaleFactor', (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrapForChip(
        child: Column(
          children: const <Widget>[
            Chip(
              avatar: CircleAvatar(child: Text('A')),
              label: Text('Chip A'),
            ),
            Chip(
              avatar: CircleAvatar(child: Text('B')),
              label: Text('Chip B'),
            ),
          ],
        ),
      ),
    );

    // TODO(gspencer): Update this test when the font metric bug is fixed to remove the anyOfs.
    // https://github.com/flutter/flutter/issues/12357
    expect(
      tester.getSize(find.text('Chip A')),
      anyOf(const Size(84.0, 14.0), const Size(83.0, 14.0)),
    );
    expect(
      tester.getSize(find.text('Chip B')),
      anyOf(const Size(84.0, 14.0), const Size(83.0, 14.0)),
    );
    expect(tester.getSize(find.byType(Chip).first), anyOf(const Size(132.0, 48.0), const Size(131.0, 48.0)));
    expect(tester.getSize(find.byType(Chip).last), anyOf(const Size(132.0, 48.0), const Size(131.0, 48.0)));

    await tester.pumpWidget(
      _wrapForChip(
        textScaleFactor: 3.0,
        child: Column(
          children: const <Widget>[
            Chip(
              avatar: CircleAvatar(child: Text('A')),
              label: Text('Chip A'),
            ),
            Chip(
              avatar: CircleAvatar(child: Text('B')),
              label: Text('Chip B'),
            ),
          ],
        ),
      ),
    );

    // TODO(gspencer): Update this test when the font metric bug is fixed to remove the anyOfs.
    // https://github.com/flutter/flutter/issues/12357
    expect(tester.getSize(find.text('Chip A')), anyOf(const Size(252.0, 42.0), const Size(251.0, 42.0)));
    expect(tester.getSize(find.text('Chip B')), anyOf(const Size(252.0, 42.0), const Size(251.0, 42.0)));
    expect(tester.getSize(find.byType(Chip).first).width, anyOf(310.0, 311.0));
    expect(tester.getSize(find.byType(Chip).first).height, equals(50.0));
    expect(tester.getSize(find.byType(Chip).last).width, anyOf(310.0, 311.0));
    expect(tester.getSize(find.byType(Chip).last).height, equals(50.0));

    // Check that individual text scales are taken into account.
    await tester.pumpWidget(
      _wrapForChip(
        child: Column(
          children: const <Widget>[
            Chip(
              avatar: CircleAvatar(child: Text('A')),
              label: Text('Chip A', textScaleFactor: 3.0),
            ),
            Chip(
              avatar: CircleAvatar(child: Text('B')),
              label: Text('Chip B'),
            ),
          ],
        ),
      ),
    );

    // TODO(gspencer): Update this test when the font metric bug is fixed to remove the anyOfs.
    // https://github.com/flutter/flutter/issues/12357
    expect(tester.getSize(find.text('Chip A')), anyOf(const Size(252.0, 42.0), const Size(251.0, 42.0)));
    expect(tester.getSize(find.text('Chip B')), anyOf(const Size(84.0, 14.0), const Size(83.0, 14.0)));
    expect(tester.getSize(find.byType(Chip).first).width, anyOf(318.0, 319.0));
    expect(tester.getSize(find.byType(Chip).first).height, equals(50.0));
    expect(tester.getSize(find.byType(Chip).last), anyOf(const Size(132.0, 48.0), const Size(131.0, 48.0)));
  });

  testWidgets('Labels can be non-text widgets', (WidgetTester tester) async {
    final Key keyA = GlobalKey();
    final Key keyB = GlobalKey();
    await tester.pumpWidget(
      _wrapForChip(
        child: Column(
          children: <Widget>[
            Chip(
              avatar: const CircleAvatar(child: Text('A')),
              label: Text('Chip A', key: keyA),
            ),
            Chip(
              avatar: const CircleAvatar(child: Text('B')),
              label: Container(key: keyB, width: 10.0, height: 10.0),
            ),
          ],
        ),
      ),
    );

    // TODO(gspencer): Update this test when the font metric bug is fixed to remove the anyOfs.
    // https://github.com/flutter/flutter/issues/12357
    expect(
      tester.getSize(find.byKey(keyA)),
      anyOf(const Size(84.0, 14.0), const Size(83.0, 14.0)),
    );
    expect(tester.getSize(find.byKey(keyB)), const Size(10.0, 10.0));
    expect(
      tester.getSize(find.byType(Chip).first),
      anyOf(const Size(132.0, 48.0), const Size(131.0, 48.0)),
    );
    expect(tester.getSize(find.byType(Chip).last), const Size(58.0, 48.0));
  });

  testWidgets('Avatars can be non-circle avatar widgets', (WidgetTester tester) async {
    final Key keyA = GlobalKey();
    await tester.pumpWidget(
      _wrapForChip(
        child: Column(
          children: <Widget>[
            Chip(
              avatar: Container(key: keyA, width: 20.0, height: 20.0),
              label: const Text('Chip A'),
            ),
          ],
        ),
      ),
    );

    expect(tester.getSize(find.byKey(keyA)), equals(const Size(20.0, 20.0)));
  });

  testWidgets('Delete icons can be non-icon widgets', (WidgetTester tester) async {
    final Key keyA = GlobalKey();
    await tester.pumpWidget(
      _wrapForChip(
        child: Column(
          children: <Widget>[
            Chip(
              deleteIcon: Container(key: keyA, width: 20.0, height: 20.0),
              label: const Text('Chip A'),
              onDeleted: () { },
            ),
          ],
        ),
      ),
    );

    expect(tester.getSize(find.byKey(keyA)), equals(const Size(20.0, 20.0)));
  });

  testWidgets('Chip padding - LTR', (WidgetTester tester) async {
    final GlobalKey keyA = GlobalKey();
    final GlobalKey keyB = GlobalKey();
    await tester.pumpWidget(
      _wrapForChip(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Material(
                  child: Center(
                    child: Chip(
                      avatar: Placeholder(key: keyA),
                      label: Container(
                        key: keyB,
                        width: 40.0,
                        height: 40.0,
                      ),
                      onDeleted: () { },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    expect(tester.getTopLeft(find.byKey(keyA)), const Offset(332.0, 280.0));
    expect(tester.getBottomRight(find.byKey(keyA)), const Offset(372.0, 320.0));
    expect(tester.getTopLeft(find.byKey(keyB)), const Offset(380.0, 280.0));
    expect(tester.getBottomRight(find.byKey(keyB)), const Offset(420.0, 320.0));
    expect(tester.getTopLeft(find.byType(Icon)), const Offset(439.0, 291.0));
    expect(tester.getBottomRight(find.byType(Icon)), const Offset(457.0, 309.0));
  });

  testWidgets('Chip padding - RTL', (WidgetTester tester) async {
    final GlobalKey keyA = GlobalKey();
    final GlobalKey keyB = GlobalKey();
    await tester.pumpWidget(
      _wrapForChip(
        textDirection: TextDirection.rtl,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Material(
                  child: Center(
                    child: Chip(
                      avatar: Placeholder(key: keyA),
                      label: Container(
                        key: keyB,
                        width: 40.0,
                        height: 40.0,
                      ),
                      onDeleted: () { },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(keyA)), const Offset(428.0, 280.0));
    expect(tester.getBottomRight(find.byKey(keyA)), const Offset(468.0, 320.0));
    expect(tester.getTopLeft(find.byKey(keyB)), const Offset(380.0, 280.0));
    expect(tester.getBottomRight(find.byKey(keyB)), const Offset(420.0, 320.0));
    expect(tester.getTopLeft(find.byType(Icon)), const Offset(343.0, 291.0));
    expect(tester.getBottomRight(find.byType(Icon)), const Offset(361.0, 309.0));
  });

  testWidgets('Avatar drawer works as expected on RawChip', (WidgetTester tester) async {
    final GlobalKey labelKey = GlobalKey();
    Future<void> pushChip({ Widget avatar }) async {
      return tester.pumpWidget(
        _wrapForChip(
          child: Wrap(
            children: <Widget>[
              RawChip(
                avatar: avatar,
                label: Text('Chip', key: labelKey),
                shape: const StadiumBorder(),
              ),
            ],
          ),
        ),
      );
    }

    // No avatar
    await pushChip();
    expect(tester.getSize(find.byType(RawChip)), equals(const Size(80.0, 48.0)));
    final GlobalKey avatarKey = GlobalKey();

    // Add an avatar
    await pushChip(
      avatar: Container(
        key: avatarKey,
        color: const Color(0xff000000),
        width: 40.0,
        height: 40.0,
      ),
    );
    // Avatar drawer should start out closed.
    expect(tester.getSize(find.byType(RawChip)), equals(const Size(80.0, 48.0)));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)), equals(const Offset(-20.0, 12.0)));
    expect(tester.getTopLeft(find.byKey(labelKey)), equals(const Offset(12.0, 17.0)));

    await tester.pump(const Duration(milliseconds: 20));
    // Avatar drawer should start expanding.
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(81.2, epsilon: 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, moreOrLessEquals(-18.8, epsilon: 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, moreOrLessEquals(13.2, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(86.7, epsilon: 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, moreOrLessEquals(-13.3, epsilon: 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, moreOrLessEquals(18.6, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(94.7, epsilon: 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, moreOrLessEquals(-5.3, epsilon: 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, moreOrLessEquals(26.7, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(99.5, epsilon: 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, moreOrLessEquals(-0.5, epsilon: 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, moreOrLessEquals(31.5, epsilon: 0.1));

    // Wait for being done with animation, and make sure it didn't change
    // height.
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(tester.getSize(find.byType(RawChip)), equals(const Size(104.0, 48.0)));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)), equals(const Offset(4.0, 12.0)));
    expect(tester.getTopLeft(find.byKey(labelKey)), equals(const Offset(36.0, 17.0)));

    // Remove the avatar again
    await pushChip();
    // Avatar drawer should start out open.
    expect(tester.getSize(find.byType(RawChip)), equals(const Size(104.0, 48.0)));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)), equals(const Offset(4.0, 12.0)));
    expect(tester.getTopLeft(find.byKey(labelKey)), equals(const Offset(36.0, 17.0)));

    await tester.pump(const Duration(milliseconds: 20));
    // Avatar drawer should start contracting.
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(102.9, epsilon: 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, moreOrLessEquals(2.9, epsilon: 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, moreOrLessEquals(34.9, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(98.0, epsilon: 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, moreOrLessEquals(-2.0, epsilon: 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, moreOrLessEquals(30.0, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(84.1, epsilon: 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, moreOrLessEquals(-15.9, epsilon: 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, moreOrLessEquals(16.1, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(80.0, epsilon: 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, moreOrLessEquals(-20.0, epsilon: 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, moreOrLessEquals(12.0, epsilon: 0.1));

    // Wait for being done with animation, make sure it didn't change
    // height, and make sure that the avatar is no longer drawn.
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(tester.getSize(find.byType(RawChip)), equals(const Size(80.0, 48.0)));
    expect(tester.getTopLeft(find.byKey(labelKey)), equals(const Offset(12.0, 17.0)));
    expect(find.byKey(avatarKey), findsNothing);
  });

  testWidgets('Delete button drawer works as expected on RawChip', (WidgetTester tester) async {
    final UniqueKey labelKey = UniqueKey();
    final UniqueKey deleteButtonKey = UniqueKey();
    bool wasDeleted = false;
    Future<void> pushChip({ bool deletable = false }) async {
      return tester.pumpWidget(
        _wrapForChip(
          child: Wrap(
            children: <Widget>[
              StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                return RawChip(
                  onDeleted: deletable
                    ? () {
                        setState(() {
                          wasDeleted = true;
                        });
                      }
                    : null,
                  deleteIcon: Container(width: 40.0, height: 40.0, key: deleteButtonKey),
                  label: Text('Chip', key: labelKey),
                  shape: const StadiumBorder(),
                );
              }),
            ],
          ),
        ),
      );
    }

    // No delete button
    await pushChip();
    expect(tester.getSize(find.byType(RawChip)), equals(const Size(80.0, 48.0)));

    // Add a delete button
    await pushChip(deletable: true);
    // Delete button drawer should start out closed.
    expect(tester.getSize(find.byType(RawChip)), equals(const Size(80.0, 48.0)));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)), equals(const Offset(52.0, 12.0)));
    expect(tester.getTopLeft(find.byKey(labelKey)), equals(const Offset(12.0, 17.0)));

    await tester.pump(const Duration(milliseconds: 20));
    // Delete button drawer should start expanding.
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(81.2, epsilon: 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, moreOrLessEquals(53.2, epsilon: 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)), equals(const Offset(12.0, 17.0)));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(86.7, epsilon: 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, moreOrLessEquals(58.7, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(94.7, epsilon: 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, moreOrLessEquals(66.7, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(99.5, epsilon: 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, moreOrLessEquals(71.5, epsilon: 0.1));

    // Wait for being done with animation, and make sure it didn't change
    // height.
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(tester.getSize(find.byType(RawChip)), equals(const Size(104.0, 48.0)));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)), equals(const Offset(76.0, 12.0)));
    expect(tester.getTopLeft(find.byKey(labelKey)), equals(const Offset(12.0, 17.0)));

    // Test the tap work for the delete button, but not the rest of the chip.
    expect(wasDeleted, isFalse);
    await tester.tap(find.byKey(labelKey));
    expect(wasDeleted, isFalse);
    await tester.tap(find.byKey(deleteButtonKey));
    expect(wasDeleted, isTrue);

    // Remove the delete button again
    await pushChip();
    // Delete button drawer should start out open.
    expect(tester.getSize(find.byType(RawChip)), equals(const Size(104.0, 48.0)));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)), equals(const Offset(76.0, 12.0)));
    expect(tester.getTopLeft(find.byKey(labelKey)), equals(const Offset(12.0, 17.0)));

    await tester.pump(const Duration(milliseconds: 20));
    // Delete button drawer should start contracting.
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(103.8, epsilon: 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, moreOrLessEquals(75.8, epsilon: 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)), equals(const Offset(12.0, 17.0)));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(102.9, epsilon: 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, moreOrLessEquals(74.9, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(101.0, epsilon: 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, moreOrLessEquals(73.0, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, moreOrLessEquals(97.5, epsilon: 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, moreOrLessEquals(69.5, epsilon: 0.1));

    // Wait for being done with animation, make sure it didn't change
    // height, and make sure that the delete button is no longer drawn.
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(tester.getSize(find.byType(RawChip)), equals(const Size(80.0, 48.0)));
    expect(tester.getTopLeft(find.byKey(labelKey)), equals(const Offset(12.0, 17.0)));
    expect(find.byKey(deleteButtonKey), findsNothing);
  });

  testWidgets('Chip creates centered, unique ripple when label is tapped', (WidgetTester tester) async {
    // Creates a chip with a delete button.
    final UniqueKey labelKey = UniqueKey();
    final UniqueKey deleteButtonKey = UniqueKey();

    await tester.pumpWidget(
      _chipWithOptionalDeleteButton(
        labelKey: labelKey,
        deleteButtonKey: deleteButtonKey,
        deletable: true,
      ),
    );

    final RenderBox box = getMaterialBox(tester);

    // Taps at a location close to the center of the label.
    final Offset centerOfLabel = tester.getCenter(find.byKey(labelKey));
    final Offset tapLocationOfLabel = centerOfLabel + const Offset(-10, -10);
    final TestGesture gesture = await tester.startGesture(tapLocationOfLabel);
    await tester.pump();

    // Waits for 100 ms.
    await tester.pump(const Duration(milliseconds: 100));

    // There should be exactly one ink-creating widget.
    expect(find.byType(InkWell), findsOneWidget);
    expect(find.byType(InkResponse), findsNothing);

    // There should be one unique, centered ink ripple.
    expect(box, ripplePattern(const Offset(163.0, 6.0), 20.9));
    expect(box, uniqueRipplePattern(const Offset(163.0, 6.0), 20.9));

    // There should be no tooltip.
    expect(findTooltipContainer('Delete'), findsNothing);

    // Waits for 100 ms again.
    await tester.pump(const Duration(milliseconds: 100));

    // The ripple should grow, with the same center.
    expect(box, ripplePattern(const Offset(163.0, 6.0), 41.8));
    expect(box, uniqueRipplePattern(const Offset(163.0, 6.0), 41.8));

    // There should be no tooltip.
    expect(findTooltipContainer('Delete'), findsNothing);

    // Waits for a very long time.
    await tester.pumpAndSettle();

    // There should still be no tooltip.
    expect(findTooltipContainer('Delete'), findsNothing);

    await gesture.up();
  });

  testWidgets('Delete button creates non-centered, unique ripple when tapped', (WidgetTester tester) async {
    // Creates a chip with a delete button.
    final UniqueKey labelKey = UniqueKey();
    final UniqueKey deleteButtonKey = UniqueKey();

    await tester.pumpWidget(
      _chipWithOptionalDeleteButton(
        labelKey: labelKey,
        deleteButtonKey: deleteButtonKey,
        deletable: true,
      ),
    );

    final RenderBox box = getMaterialBox(tester);

    // Taps at a location close to the center of the delete icon.
    final Offset centerOfDeleteButton = tester.getCenter(find.byKey(deleteButtonKey));
    final Offset tapLocationOfDeleteButton = centerOfDeleteButton + const Offset(-10, -10);
    final TestGesture gesture = await tester.startGesture(tapLocationOfDeleteButton);
    await tester.pump();

    // Waits for 200 ms.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // There should be exactly one ink-creating widget.
    expect(find.byType(InkWell), findsOneWidget);
    expect(find.byType(InkResponse), findsNothing);

    // There should be one unique ink ripple.
    expect(box, ripplePattern(const Offset(3.0, 3.0), 3.5));
    expect(box, uniqueRipplePattern(const Offset(3.0, 3.0), 3.5));

    // There should be no tooltip.
    expect(findTooltipContainer('Delete'), findsNothing);

    // Waits for 200 ms again.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // The ripple should grow, but the center should move,
    // Towards the center of the delete icon.
    expect(box, ripplePattern(const Offset(5.0, 5.0), 10.5));
    expect(box, uniqueRipplePattern(const Offset(5.0, 5.0), 10.5));

    // There should be no tooltip.
    expect(findTooltipContainer('Delete'), findsNothing);

    // Waits for a very long time.
    // This is pressing and holding the delete button.
    await tester.pumpAndSettle();

    // There should be a tooltip.
    expect(findTooltipContainer('Delete'), findsOneWidget);

    await gesture.up();
  });

  testWidgets('RTL delete button responds to tap on the left of the chip', (WidgetTester tester) async {
    // Creates an RTL chip with a delete button.
    final UniqueKey labelKey = UniqueKey();
    final UniqueKey deleteButtonKey = UniqueKey();

    await tester.pumpWidget(
      _chipWithOptionalDeleteButton(
        labelKey: labelKey,
        deleteButtonKey: deleteButtonKey,
        deletable: true,
        textDirection: TextDirection.rtl,
      ),
    );

    // Taps at a location close to the center of the delete icon,
    // Which is on the left side of the chip.
    final Offset topLeftOfInkWell = tester.getTopLeft(find.byType(InkWell));
    final Offset tapLocation = topLeftOfInkWell + const Offset(8, 8);
    final TestGesture gesture = await tester.startGesture(tapLocation);
    await tester.pump();

    await tester.pumpAndSettle();

    // The existence of a 'Delete' tooltip indicates the delete icon is tapped,
    // Instead of the label.
    expect(findTooltipContainer('Delete'), findsOneWidget);

    await gesture.up();
  });

  testWidgets('Chip without delete button creates correct ripple', (WidgetTester tester) async {
    // Creates a chip with a delete button.
    final UniqueKey labelKey = UniqueKey();

    await tester.pumpWidget(
      _chipWithOptionalDeleteButton(
        labelKey: labelKey,
        deletable: false,
      ),
    );

    final RenderBox box = getMaterialBox(tester);

    // Taps at a location close to the bottom-right corner of the chip.
    final Offset bottomRightOfInkWell = tester.getBottomRight(find.byType(InkWell));
    final Offset tapLocation = bottomRightOfInkWell + const Offset(-10, -10);
    final TestGesture gesture = await tester.startGesture(tapLocation);
    await tester.pump();

    // Waits for 100 ms.
    await tester.pump(const Duration(milliseconds: 100));

    // There should be exactly one ink-creating widget.
    expect(find.byType(InkWell), findsOneWidget);
    expect(find.byType(InkResponse), findsNothing);

    // There should be one unique, centered ink ripple.
    expect(box, ripplePattern(const Offset(378.0, 22.0), 37.9));
    expect(box, uniqueRipplePattern(const Offset(378.0, 22.0), 37.9));

    // There should be no tooltip.
    expect(findTooltipContainer('Delete'), findsNothing);

    // Waits for 100 ms again.
    await tester.pump(const Duration(milliseconds: 100));

    // The ripple should grow, with the same center.
    // This indicates that the tap is not on a delete icon.
    expect(box, ripplePattern(const Offset(378.0, 22.0), 75.8));
    expect(box, uniqueRipplePattern(const Offset(378.0, 22.0), 75.8));

    // There should be no tooltip.
    expect(findTooltipContainer('Delete'), findsNothing);

    // Waits for a very long time.
    await tester.pumpAndSettle();

    // There should still be no tooltip.
    // This indicates that the tap is not on a delete icon.
    expect(findTooltipContainer('Delete'), findsNothing);

    await gesture.up();
  });

  testWidgets('Selection with avatar works as expected on RawChip', (WidgetTester tester) async {
    bool selected = false;
    final UniqueKey labelKey = UniqueKey();
    Future<void> pushChip({ Widget avatar, bool selectable = false }) async {
      return tester.pumpWidget(
        _wrapForChip(
          child: Wrap(
            children: <Widget>[
              StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                return RawChip(
                  avatar: avatar,
                  onSelected: selectable != null
                    ? (bool value) {
                        setState(() {
                          selected = value;
                        });
                      }
                    : null,
                  selected: selected,
                  label: Text('Chip', key: labelKey),
                  shape: const StadiumBorder(),
                  showCheckmark: true,
                  tapEnabled: true,
                  isEnabled: true,
                );
              }),
            ],
          ),
        ),
      );
    }

    // With avatar, but not selectable.
    final UniqueKey avatarKey = UniqueKey();
    await pushChip(
      avatar: Container(width: 40.0, height: 40.0, key: avatarKey),
    );
    expect(tester.getSize(find.byType(RawChip)), equals(const Size(104.0, 48.0)));

    // Turn on selection.
    await pushChip(
      avatar: Container(width: 40.0, height: 40.0, key: avatarKey),
      selectable: true,
    );
    await tester.pumpAndSettle();

    // Simulate a tap on the label to select the chip.
    await tester.tap(find.byKey(labelKey));
    expect(selected, equals(true));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(getSelectProgress(tester), moreOrLessEquals(0.002, epsilon: 0.01));
    expect(getAvatarDrawerProgress(tester), equals(1.0));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 50));
    expect(getSelectProgress(tester), moreOrLessEquals(0.54, epsilon: 0.01));
    expect(getAvatarDrawerProgress(tester), equals(1.0));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(getSelectProgress(tester), equals(1.0));
    expect(getAvatarDrawerProgress(tester), equals(1.0));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pumpAndSettle();
    // Simulate another tap on the label to deselect the chip.
    await tester.tap(find.byKey(labelKey));
    expect(selected, equals(false));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(getSelectProgress(tester), moreOrLessEquals(0.875, epsilon: 0.01));
    expect(getAvatarDrawerProgress(tester), equals(1.0));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 20));
    expect(getSelectProgress(tester), moreOrLessEquals(0.13, epsilon: 0.01));
    expect(getAvatarDrawerProgress(tester), equals(1.0));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(getSelectProgress(tester), equals(0.0));
    expect(getAvatarDrawerProgress(tester), equals(1.0));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
  });

  testWidgets('Selection without avatar works as expected on RawChip', (WidgetTester tester) async {
    bool selected = false;
    final UniqueKey labelKey = UniqueKey();
    Future<void> pushChip({ bool selectable = false }) async {
      return tester.pumpWidget(
        _wrapForChip(
          child: Wrap(
            children: <Widget>[
              StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                return RawChip(
                  onSelected: selectable != null
                    ? (bool value) {
                        setState(() {
                          selected = value;
                        });
                      }
                    : null,
                  selected: selected,
                  label: Text('Chip', key: labelKey),
                  shape: const StadiumBorder(),
                  showCheckmark: true,
                  tapEnabled: true,
                  isEnabled: true,
                );
              }),
            ],
          ),
        ),
      );
    }

    // Without avatar, but not selectable.
    await pushChip();
    expect(tester.getSize(find.byType(RawChip)), equals(const Size(80.0, 48.0)));

    // Turn on selection.
    await pushChip(selectable: true);
    await tester.pumpAndSettle();

    // Simulate a tap on the label to select the chip.
    await tester.tap(find.byKey(labelKey));
    expect(selected, equals(true));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(getSelectProgress(tester), moreOrLessEquals(0.002, epsilon: 0.01));
    expect(getAvatarDrawerProgress(tester), moreOrLessEquals(0.459, epsilon: 0.01));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 50));
    expect(getSelectProgress(tester), moreOrLessEquals(0.54, epsilon: 0.01));
    expect(getAvatarDrawerProgress(tester), moreOrLessEquals(0.92, epsilon: 0.01));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(getSelectProgress(tester), equals(1.0));
    expect(getAvatarDrawerProgress(tester), equals(1.0));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pumpAndSettle();
    // Simulate another tap on the label to deselect the chip.
    await tester.tap(find.byKey(labelKey));
    expect(selected, equals(false));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(getSelectProgress(tester), moreOrLessEquals(0.875, epsilon: 0.01));
    expect(getAvatarDrawerProgress(tester), moreOrLessEquals(0.96, epsilon: 0.01));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 20));
    expect(getSelectProgress(tester), moreOrLessEquals(0.13, epsilon: 0.01));
    expect(getAvatarDrawerProgress(tester), moreOrLessEquals(0.75, epsilon: 0.01));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(getSelectProgress(tester), equals(0.0));
    expect(getAvatarDrawerProgress(tester), equals(0.0));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
  });

  testWidgets('Activation works as expected on RawChip', (WidgetTester tester) async {
    bool selected = false;
    final UniqueKey labelKey = UniqueKey();
    Future<void> pushChip({ Widget avatar, bool selectable = false }) async {
      return tester.pumpWidget(
        _wrapForChip(
          child: Wrap(
            children: <Widget>[
              StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                return RawChip(
                  avatar: avatar,
                  onSelected: selectable != null
                    ? (bool value) {
                        setState(() {
                          selected = value;
                        });
                      }
                    : null,
                  selected: selected,
                  label: Text('Chip', key: labelKey),
                  shape: const StadiumBorder(),
                  showCheckmark: false,
                  tapEnabled: true,
                  isEnabled: true,
                );
              }),
            ],
          ),
        ),
      );
    }

    final UniqueKey avatarKey = UniqueKey();
    await pushChip(
      avatar: Container(width: 40.0, height: 40.0, key: avatarKey),
      selectable: true,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(labelKey));
    expect(selected, equals(true));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(getSelectProgress(tester), moreOrLessEquals(0.002, epsilon: 0.01));
    expect(getAvatarDrawerProgress(tester), equals(1.0));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 50));
    expect(getSelectProgress(tester), moreOrLessEquals(0.54, epsilon: 0.01));
    expect(getAvatarDrawerProgress(tester), equals(1.0));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(getSelectProgress(tester), equals(1.0));
    expect(getAvatarDrawerProgress(tester), equals(1.0));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pumpAndSettle();
  });

  testWidgets('Chip uses ThemeData chip theme if present', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.red,
    );
    final ChipThemeData chipTheme = theme.chipTheme;

    Widget buildChip(ChipThemeData data) {
      return _wrapForChip(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: theme,
          child: const InputChip(
            label: Text('Label'),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildChip(chipTheme));

    final RenderBox materialBox = tester.firstRenderObject<RenderBox>(
      find.descendant(
        of: find.byType(RawChip),
        matching: find.byType(CustomPaint),
      ),
    );

    expect(materialBox, paints..path(color: chipTheme.disabledColor));
  });

  testWidgets('Chip size is configurable by ThemeData.materialTapTargetSize', (WidgetTester tester) async {
    final Key key1 = UniqueKey();
    await tester.pumpWidget(
      _wrapForChip(
        child: Theme(
          data: ThemeData(materialTapTargetSize: MaterialTapTargetSize.padded),
          child: Center(
            child: RawChip(
              key: key1,
              label: const Text('test'),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key1)), const Size(80.0, 48.0));

    final Key key2 = UniqueKey();
    await tester.pumpWidget(
      _wrapForChip(
        child: Theme(
          data: ThemeData(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: Center(
            child: RawChip(
              key: key2,
              label: const Text('test'),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key2)), const Size(80.0, 32.0));
  });

  testWidgets('Chip uses the right theme colors for the right components', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
    );
    final ChipThemeData defaultChipTheme = themeData.chipTheme;
    bool value = false;
    Widget buildApp({
      ChipThemeData chipTheme,
      Widget avatar,
      Widget deleteIcon,
      bool isSelectable = true,
      bool isPressable = false,
      bool isDeletable = true,
      bool showCheckmark = true,
    }) {
      chipTheme ??= defaultChipTheme;
      return _wrapForChip(
        child: Theme(
          data: themeData,
          child: ChipTheme(
            data: chipTheme,
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return RawChip(
                showCheckmark: showCheckmark,
                onDeleted: isDeletable ? () { } : null,
                tapEnabled: true,
                avatar: avatar,
                deleteIcon: deleteIcon,
                isEnabled: isSelectable || isPressable,
                shape: chipTheme.shape,
                selected: isSelectable && value,
                label: Text('$value'),
                onSelected: isSelectable
                  ? (bool newValue) {
                      setState(() {
                        value = newValue;
                      });
                    }
                  : null,
                onPressed: isPressable
                  ? () {
                      setState(() {
                        value = true;
                      });
                    }
                  : null,
              );
            }),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());

    RenderBox materialBox = getMaterialBox(tester);
    IconThemeData iconData = getIconData(tester);
    DefaultTextStyle labelStyle = getLabelStyle(tester);

    // Check default theme for enabled widget.
    expect(materialBox, paints..path(color: defaultChipTheme.backgroundColor));
    expect(iconData.color, equals(const Color(0xde000000)));
    expect(labelStyle.style.color, equals(Colors.black.withAlpha(0xde)));
    await tester.tap(find.byType(RawChip));
    await tester.pumpAndSettle();
    materialBox = getMaterialBox(tester);
    expect(materialBox, paints..path(color: defaultChipTheme.selectedColor));
    await tester.tap(find.byType(RawChip));
    await tester.pumpAndSettle();

    // Check default theme with disabled widget.
    await tester.pumpWidget(buildApp(isSelectable: false, isPressable: false, isDeletable: true));
    await tester.pumpAndSettle();
    materialBox = getMaterialBox(tester);
    labelStyle = getLabelStyle(tester);
    expect(materialBox, paints..path(color: defaultChipTheme.disabledColor));
    expect(labelStyle.style.color, equals(Colors.black.withAlpha(0xde)));

    // Apply a custom theme.
    const Color customColor1 = Color(0xcafefeed);
    const Color customColor2 = Color(0xdeadbeef);
    const Color customColor3 = Color(0xbeefcafe);
    const Color customColor4 = Color(0xaddedabe);
    final ChipThemeData customTheme = defaultChipTheme.copyWith(
      brightness: Brightness.dark,
      backgroundColor: customColor1,
      disabledColor: customColor2,
      selectedColor: customColor3,
      deleteIconColor: customColor4,
    );
    await tester.pumpWidget(buildApp(chipTheme: customTheme));
    await tester.pumpAndSettle();
    materialBox = getMaterialBox(tester);
    iconData = getIconData(tester);
    labelStyle = getLabelStyle(tester);

    // Check custom theme for enabled widget.
    expect(materialBox, paints..path(color: customTheme.backgroundColor));
    expect(iconData.color, equals(customTheme.deleteIconColor));
    expect(labelStyle.style.color, equals(Colors.black.withAlpha(0xde)));
    await tester.tap(find.byType(RawChip));
    await tester.pumpAndSettle();
    materialBox = getMaterialBox(tester);
    expect(materialBox, paints..path(color: customTheme.selectedColor));
    await tester.tap(find.byType(RawChip));
    await tester.pumpAndSettle();

    // Check custom theme with disabled widget.
    await tester.pumpWidget(buildApp(
      chipTheme: customTheme,
      isSelectable: false,
      isPressable: false,
      isDeletable: true,
    ));
    await tester.pumpAndSettle();
    materialBox = getMaterialBox(tester);
    labelStyle = getLabelStyle(tester);
    expect(materialBox, paints..path(color: customTheme.disabledColor));
    expect(labelStyle.style.color, equals(Colors.black.withAlpha(0xde)));
  });

  group('Chip semantics', () {
    testWidgets('label only', (WidgetTester tester) async {
      final SemanticsTester semanticsTester = SemanticsTester(tester);

      await tester.pumpWidget(const MaterialApp(
        home: Material(
          child: RawChip(
            label: Text('test'),
          ),
        ),
      ));

      expect(semanticsTester, hasSemantics(
          TestSemantics.root(
            children: <TestSemantics>[
              TestSemantics(
                textDirection: TextDirection.ltr,
                children: <TestSemantics>[
                  TestSemantics(
                    children: <TestSemantics>[
                      TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                        children: <TestSemantics>[
                          TestSemantics(
                            label: 'test',
                            textDirection: TextDirection.ltr,
                            flags: <SemanticsFlag>[
                              SemanticsFlag.hasEnabledState,
                              SemanticsFlag.isButton,
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ), ignoreTransform: true, ignoreId: true, ignoreRect: true));
      semanticsTester.dispose();
    });

    testWidgets('delete', (WidgetTester tester) async {
      final SemanticsTester semanticsTester = SemanticsTester(tester);

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: RawChip(
            label: const Text('test'),
            onDeleted: () { },
          ),
        ),
      ));

      expect(semanticsTester, hasSemantics(
          TestSemantics.root(
            children: <TestSemantics>[
              TestSemantics(
                textDirection: TextDirection.ltr,
                children: <TestSemantics>[
                  TestSemantics(
                    children: <TestSemantics>[
                      TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                        children: <TestSemantics>[
                          TestSemantics(
                            label: 'test',
                            textDirection: TextDirection.ltr,
                            flags: <SemanticsFlag>[
                              SemanticsFlag.hasEnabledState,
                              SemanticsFlag.isButton,
                            ],
                            children: <TestSemantics>[
                              TestSemantics(
                                label: 'Delete',
                                actions: <SemanticsAction>[SemanticsAction.tap],
                                textDirection: TextDirection.ltr,
                                flags: <SemanticsFlag>[
                                  SemanticsFlag.isButton,
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ), ignoreTransform: true, ignoreId: true, ignoreRect: true));
      semanticsTester.dispose();
    });

    testWidgets('with onPressed', (WidgetTester tester) async {
      final SemanticsTester semanticsTester = SemanticsTester(tester);

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: RawChip(
            label: const Text('test'),
            onPressed: () { },
          ),
        ),
      ));

      expect(semanticsTester, hasSemantics(
          TestSemantics.root(
            children: <TestSemantics>[
              TestSemantics(
                textDirection: TextDirection.ltr,
                children: <TestSemantics>[
                  TestSemantics(
                    children: <TestSemantics> [
                      TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                        children: <TestSemantics>[
                          TestSemantics(
                            label: 'test',
                            textDirection: TextDirection.ltr,
                            flags: <SemanticsFlag>[
                              SemanticsFlag.hasEnabledState,
                              SemanticsFlag.isButton,
                              SemanticsFlag.isEnabled,
                              SemanticsFlag.isFocusable,
                            ],
                            actions: <SemanticsAction>[SemanticsAction.tap],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ), ignoreTransform: true, ignoreId: true, ignoreRect: true));

      semanticsTester.dispose();
    });


    testWidgets('with onSelected', (WidgetTester tester) async {
      final SemanticsTester semanticsTester = SemanticsTester(tester);
      bool selected = false;

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: RawChip(
            isEnabled: true,
            label: const Text('test'),
            selected: selected,
            onSelected: (bool value) {
              selected = value;
            },
          ),
        ),
      ));

      expect(semanticsTester, hasSemantics(
          TestSemantics.root(
            children: <TestSemantics>[
              TestSemantics(
                textDirection: TextDirection.ltr,
                children: <TestSemantics>[
                  TestSemantics(
                    children: <TestSemantics>[
                      TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                        children: <TestSemantics>[
                          TestSemantics(
                            label: 'test',
                            textDirection: TextDirection.ltr,
                            flags: <SemanticsFlag>[
                              SemanticsFlag.hasEnabledState,
                              SemanticsFlag.isButton,
                              SemanticsFlag.isEnabled,
                              SemanticsFlag.isFocusable,
                            ],
                            actions: <SemanticsAction>[SemanticsAction.tap],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ), ignoreTransform: true, ignoreId: true, ignoreRect: true));

      await tester.tap(find.byType(RawChip));
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: RawChip(
            isEnabled: true,
            label: const Text('test'),
            selected: selected,
            onSelected: (bool value) {
              selected = value;
            },
          ),
        ),
      ));

      expect(selected, true);
      expect(semanticsTester, hasSemantics(
          TestSemantics.root(
            children: <TestSemantics>[
              TestSemantics(
                textDirection: TextDirection.ltr,
                children: <TestSemantics>[
                  TestSemantics(
                    children: <TestSemantics>[
                      TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                        children: <TestSemantics>[
                          TestSemantics(
                            label: 'test',
                            textDirection: TextDirection.ltr,
                            flags: <SemanticsFlag>[
                              SemanticsFlag.hasEnabledState,
                              SemanticsFlag.isButton,
                              SemanticsFlag.isEnabled,
                              SemanticsFlag.isFocusable,
                              SemanticsFlag.isSelected,
                            ],
                            actions: <SemanticsAction>[SemanticsAction.tap],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ), ignoreTransform: true, ignoreId: true, ignoreRect: true));

      semanticsTester.dispose();
    });

    testWidgets('disabled', (WidgetTester tester) async {
      final SemanticsTester semanticsTester = SemanticsTester(tester);

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: RawChip(
            isEnabled: false,
            onPressed: () { },
            label: const Text('test'),
          ),
        ),
      ));

      expect(semanticsTester, hasSemantics(
          TestSemantics.root(
            children: <TestSemantics>[
              TestSemantics(
                textDirection: TextDirection.ltr,
                children: <TestSemantics>[
                  TestSemantics(
                    children: <TestSemantics>[
                      TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                        children: <TestSemantics>[
                          TestSemantics(
                            label: 'test',
                            textDirection: TextDirection.ltr,
                            flags: <SemanticsFlag>[
                              SemanticsFlag.hasEnabledState,
                              SemanticsFlag.isButton,
                            ],
                            actions: <SemanticsAction>[],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ), ignoreTransform: true, ignoreId: true, ignoreRect: true));

      semanticsTester.dispose();
    });

    testWidgets('tapEnabled explicitly false', (WidgetTester tester) async {
      final SemanticsTester semanticsTester = SemanticsTester(tester);

      await tester.pumpWidget(const MaterialApp(
        home: Material(
          child: RawChip(
            tapEnabled: false,
            label: Text('test'),
          ),
        ),
      ));

      expect(semanticsTester, hasSemantics(
          TestSemantics.root(
            children: <TestSemantics>[
              TestSemantics(
                textDirection: TextDirection.ltr,
                children: <TestSemantics>[
                  TestSemantics(
                    children: <TestSemantics>[
                      TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                        children: <TestSemantics>[
                          TestSemantics(
                            label: 'test',
                            textDirection: TextDirection.ltr,
                            flags: <SemanticsFlag>[], // Must not be a button when tapping is disabled.
                            actions: <SemanticsAction>[],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ), ignoreTransform: true, ignoreId: true, ignoreRect: true));

      semanticsTester.dispose();
    });

    testWidgets('enabled when tapEnabled and canTap', (WidgetTester tester) async {
      final SemanticsTester semanticsTester = SemanticsTester(tester);

      // These settings make a Chip which can be tapped, both in general and at this moment.
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: RawChip(
            isEnabled: true,
            tapEnabled: true,
            onPressed: () {},
            label: const Text('test'),
          ),
        ),
      ));

      expect(semanticsTester, hasSemantics(
          TestSemantics.root(
            children: <TestSemantics>[
              TestSemantics(
                textDirection: TextDirection.ltr,
                children: <TestSemantics>[
                  TestSemantics(
                    children: <TestSemantics>[
                      TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                        children: <TestSemantics>[
                          TestSemantics(
                            label: 'test',
                            textDirection: TextDirection.ltr,
                            flags: <SemanticsFlag>[
                              SemanticsFlag.hasEnabledState,
                              SemanticsFlag.isButton,
                              SemanticsFlag.isEnabled,
                              SemanticsFlag.isFocusable,
                            ],
                            actions: <SemanticsAction>[SemanticsAction.tap],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ), ignoreTransform: true, ignoreId: true, ignoreRect: true));

      semanticsTester.dispose();
    });

    testWidgets('disabled when tapEnabled but not canTap', (WidgetTester tester) async {
      final SemanticsTester semanticsTester = SemanticsTester(tester);
        // These settings make a Chip which _could_ be tapped, but not currently (ensures `canTap == false`).
        await tester.pumpWidget(const MaterialApp(
        home: Material(
          child: RawChip(
            isEnabled: true,
            tapEnabled: true,
            label: Text('test'),
          ),
        ),
      ));

      expect(semanticsTester, hasSemantics(
          TestSemantics.root(
            children: <TestSemantics>[
              TestSemantics(
                textDirection: TextDirection.ltr,
                children: <TestSemantics>[
                  TestSemantics(
                    children: <TestSemantics>[
                      TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                        children: <TestSemantics>[
                          TestSemantics(
                            label: 'test',
                            textDirection: TextDirection.ltr,
                            flags: <SemanticsFlag>[
                              SemanticsFlag.hasEnabledState,
                              SemanticsFlag.isButton,
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ), ignoreTransform: true, ignoreId: true, ignoreRect: true));

      semanticsTester.dispose();
    });
  });

  testWidgets('can be tapped outside of chip delete icon', (WidgetTester tester) async {
    bool deleted = false;
    await tester.pumpWidget(
      _wrapForChip(
        child: Row(
          children: <Widget>[
            Chip(
              materialTapTargetSize: MaterialTapTargetSize.padded,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(0.0))),
              avatar: const CircleAvatar(child: Text('A')),
              label: const Text('Chip A'),
              onDeleted: () {
                deleted = true;
              },
              deleteIcon: const Icon(Icons.delete),
            ),
          ],
        ),
      ),
    );

    await tester.tapAt(tester.getTopRight(find.byType(Chip)) - const Offset(2.0, -2.0));
    await tester.pumpAndSettle();
    expect(deleted, true);
  });

  testWidgets('Chips can be tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: ChoiceChip(
            selected: false,
            label: Text('choice chip'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ChoiceChip));
    expect(tester.takeException(), null);

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: RawChip(
            selected: false,
            label: Text('raw chip'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(RawChip));
    expect(tester.takeException(), null);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ActionChip(
            onPressed: () { },
            label: const Text('action chip'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ActionChip));
    expect(tester.takeException(), null);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FilterChip(
            onSelected: (bool valueChanged) { },
            selected: false,
            label: const Text('filter chip'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FilterChip));
    expect(tester.takeException(), null);

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: InputChip(
            selected: false,
            label: Text('input chip'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InputChip));
    expect(tester.takeException(), null);
  });

  testWidgets('Chip elevation and shadow color work correctly', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.red,
    );

    final ChipThemeData chipTheme = theme.chipTheme;

    InputChip inputChip = const InputChip(label: Text('Label'));

    Widget buildChip(ChipThemeData data) {
      return _wrapForChip(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: theme,
          child: inputChip,
        ),
      );
    }

    await tester.pumpWidget(buildChip(chipTheme));
    Material material = getMaterial(tester);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, Colors.black);

    inputChip = const InputChip(
      label: Text('Label'),
      elevation: 4.0,
      shadowColor: Colors.green,
      selectedShadowColor: Colors.blue,
    );

    await tester.pumpWidget(buildChip(chipTheme));
    await tester.pumpAndSettle();
    material = getMaterial(tester);
    expect(material.elevation, 4.0);
    expect(material.shadowColor, Colors.green);

    inputChip = const InputChip(
      label: Text('Label'),
      selected: true,
      shadowColor: Colors.green,
      selectedShadowColor: Colors.blue,
    );

    await tester.pumpWidget(buildChip(chipTheme));
    await tester.pumpAndSettle();
    material = getMaterial(tester);
    expect(material.shadowColor, Colors.blue);
  });

  testWidgets('can be tapped outside of chip body', (WidgetTester tester) async {
    bool pressed = false;
    await tester.pumpWidget(
      _wrapForChip(
        child: Row(
          children: <Widget>[
            InputChip(
              materialTapTargetSize: MaterialTapTargetSize.padded,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(0.0))),
              avatar: const CircleAvatar(child: Text('A')),
              label: const Text('Chip A'),
              onPressed: () {
                pressed = true;
              },
            ),
          ],
        ),
      ),
    );

    await tester.tapAt(tester.getRect(find.byType(InputChip)).topCenter);
    await tester.pumpAndSettle();
    expect(pressed, true);
  });

  testWidgets('is hitTestable', (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrapForChip(
        child: InputChip(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(0.0))),
          avatar: const CircleAvatar(child: Text('A')),
          label: const Text('Chip A'),
          onPressed: () { },
        ),
      ),
    );

    expect(find.byType(InputChip).hitTestable(at: Alignment.center), findsOneWidget);
  });

  void checkChipMaterialClipBehavior(WidgetTester tester, Clip clipBehavior) {
    final Iterable<Material> materials = tester.widgetList<Material>(find.byType(Material));
    expect(materials.length, 2);
    expect(materials.last.clipBehavior, clipBehavior);
  }

  testWidgets('Chip clipBehavior properly passes through to the Material', (WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(_wrapForChip(child: const Chip(label: label)));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(_wrapForChip(child: const Chip(label: label, clipBehavior: Clip.antiAlias)));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });

  testWidgets('ChoiceChip clipBehavior properly passes through to the Material', (WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(_wrapForChip(child: const ChoiceChip(label: label, selected: false)));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(_wrapForChip(child: const ChoiceChip(label: label, selected: false, clipBehavior: Clip.antiAlias)));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });

  testWidgets('FilterChip clipBehavior properly passes through to the Material', (WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(_wrapForChip(child: FilterChip(label: label, onSelected: (bool b) { },)));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(_wrapForChip(child: FilterChip(label: label, onSelected: (bool b) { }, clipBehavior: Clip.antiAlias)));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });

  testWidgets('ActionChip clipBehavior properly passes through to the Material', (WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(_wrapForChip(child: ActionChip(label: label, onPressed: () { },)));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(_wrapForChip(child: ActionChip(label: label, clipBehavior: Clip.antiAlias, onPressed: () { })));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });

  testWidgets('InputChip clipBehavior properly passes through to the Material', (WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(_wrapForChip(child: const InputChip(label: label)));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(_wrapForChip(child: const InputChip(label: label, clipBehavior: Clip.antiAlias)));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });

  testWidgets('selected chip and avatar draw darkened layer within avatar circle', (WidgetTester tester) async {
    await tester.pumpWidget(_wrapForChip(child: const FilterChip(
      avatar: CircleAvatar(child: Text('t')),
      label: Text('test'),
      selected: true,
      onSelected: null,
    )));
    final RenderBox rawChip = tester.firstRenderObject<RenderBox>(
      find.descendant(
        of: find.byType(RawChip),
        matching: find.byWidgetPredicate((Widget widget) {
          return widget.runtimeType.toString() == '_ChipRenderWidget';
        }),
      ),
    );
    const Color selectScrimColor = Color(0x60191919);
    expect(rawChip, paints..path(color: selectScrimColor, includes: <Offset>[
      const Offset(10, 10),
    ], excludes: <Offset>[
      const Offset(4, 4),
    ]));
  });

  testWidgets('Chips should use InkWell instead of InkResponse.', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/28646
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ActionChip(
            onPressed: () { },
            label: const Text('action chip'),
          ),
        ),
      ),
    );
    expect(find.byType(InkWell), findsOneWidget);
  });

  testWidgets('RawChip.selected can not be null', (WidgetTester tester) async {
    expect(() async {
      MaterialApp(
        home: Material(
          child: RawChip(
            onPressed: () { },
            selected: null,
            label: const Text('Chip'),
          ),
        ),
      );
    }, throwsAssertionError);
  });

  testWidgets('Chip uses stateful color for text color in different states', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    const Color pressedColor = Color(0x00000001);
    const Color hoverColor = Color(0x00000002);
    const Color focusedColor = Color(0x00000003);
    const Color defaultColor = Color(0x00000004);
    const Color selectedColor = Color(0x00000005);
    const Color disabledColor = Color(0x00000006);

    Color getTextColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled))
        return disabledColor;

      if (states.contains(MaterialState.pressed))
        return pressedColor;

      if (states.contains(MaterialState.hovered))
        return hoverColor;

      if (states.contains(MaterialState.focused))
        return focusedColor;

      if (states.contains(MaterialState.selected))
        return selectedColor;

      return defaultColor;
    }

    Widget chipWidget({ bool enabled = true, bool selected = false }) {
      return MaterialApp(
        home: Scaffold(
          body: Focus(
            focusNode: focusNode,
            child: ChoiceChip(
              label: const Text('Chip'),
              selected: selected,
              onSelected: enabled ? (_) {} : null,
              labelStyle: TextStyle(color: MaterialStateColor.resolveWith(getTextColor)),
            ),
          ),
        ),
      );
    }
    Color textColor() {
      return tester.renderObject<RenderParagraph>(find.text('Chip')).text.style.color;
    }

    // Default, not disabled.
    await tester.pumpWidget(chipWidget());
    expect(textColor(), equals(defaultColor));

    // Selected.
    await tester.pumpWidget(chipWidget(selected: true));
    expect(textColor(), selectedColor);

    // Focused.
    final FocusNode chipFocusNode = focusNode.children.first;
    chipFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(textColor(), focusedColor);

    // Hovered.
    final Offset center = tester.getCenter(find.byType(ChoiceChip));
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    expect(textColor(), hoverColor);

    // Pressed.
    await gesture.down(center);
    await tester.pumpAndSettle();
    expect(textColor(), pressedColor);

    // Disabled.
    await tester.pumpWidget(chipWidget(enabled: false));
    await tester.pumpAndSettle();
    expect(textColor(), disabledColor);

    // Teardown.
    await gesture.removePointer();
  });

  testWidgets('loses focus when disabled', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'InputChip');
    await tester.pumpWidget(
      _wrapForChip(
        child: InputChip(
          focusNode: focusNode,
          autofocus: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(0.0))),
          avatar: const CircleAvatar(child: Text('A')),
          label: const Text('Chip A'),
          onPressed: () { },
        ),
      ),
    );
    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.pumpWidget(
      _wrapForChip(
        child: InputChip(
          focusNode: focusNode,
          autofocus: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(0.0))),
          avatar: const CircleAvatar(child: Text('A')),
          label: const Text('Chip A'),
          onPressed: null,
        ),
      ),
    );
    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isFalse);
  });

  testWidgets('cannot be traversed to when disabled', (WidgetTester tester) async {
    final FocusNode focusNode1 = FocusNode(debugLabel: 'InputChip 1');
    final FocusNode focusNode2 = FocusNode(debugLabel: 'InputChip 2');
    await tester.pumpWidget(
      _wrapForChip(
        child: Column(
          children: <Widget>[
            InputChip(
              focusNode: focusNode1,
              autofocus: true,
              label: const Text('Chip A'),
              onPressed: () { },
            ),
            InputChip(
              focusNode: focusNode2,
              autofocus: true,
              label: const Text('Chip B'),
              onPressed: null,
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(focusNode1.hasPrimaryFocus, isTrue);
    expect(focusNode2.hasPrimaryFocus, isFalse);

    expect(focusNode1.nextFocus(), isTrue);

    await tester.pump();
    expect(focusNode1.hasPrimaryFocus, isTrue);
    expect(focusNode2.hasPrimaryFocus, isFalse);
  });

  testWidgets('Chip responds to density changes.', (WidgetTester tester) async {
    const Key key = Key('test');
    const Key textKey = Key('test text');
    const Key iconKey = Key('test icon');
    const Key avatarKey = Key('test avatar');
    Future<void> buildTest(VisualDensity visualDensity) async {
      return await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: Column(
                children: <Widget>[
                  InputChip(
                    visualDensity: visualDensity,
                    key: key,
                    onPressed: () {},
                    onDeleted: () {},
                    label: const Text('Test', key: textKey),
                    deleteIcon: const Icon(Icons.delete, key: iconKey),
                    avatar: const Icon(Icons.play_arrow, key: avatarKey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // The Chips only change in size vertically in response to density, so
    // horizontal changes aren't expected.
    await buildTest(VisualDensity.standard);
    Rect box = tester.getRect(find.byKey(key));
    Rect textBox = tester.getRect(find.byKey(textKey));
    Rect iconBox = tester.getRect(find.byKey(iconKey));
    Rect avatarBox = tester.getRect(find.byKey(avatarKey));
    expect(box.size, equals(const Size(128, 32.0 + 16.0)));
    expect(textBox.size, equals(const Size(56, 14)));
    expect(iconBox.size, equals(const Size(24, 24)));
    expect(avatarBox.size, equals(const Size(24, 24)));
    expect(textBox.top, equals(17));
    expect(box.bottom - textBox.bottom, equals(17));
    expect(textBox.left, equals(372));
    expect(box.right - textBox.right, equals(36));

    // Try decreasing density (with higher density numbers).
    await buildTest(const VisualDensity(horizontal: 3.0, vertical: 3.0));
    box = tester.getRect(find.byKey(key));
    textBox = tester.getRect(find.byKey(textKey));
    iconBox = tester.getRect(find.byKey(iconKey));
    avatarBox = tester.getRect(find.byKey(avatarKey));
    expect(box.size, equals(const Size(128, 60)));
    expect(textBox.size, equals(const Size(56, 14)));
    expect(iconBox.size, equals(const Size(24, 24)));
    expect(avatarBox.size, equals(const Size(24, 24)));
    expect(textBox.top, equals(23));
    expect(box.bottom - textBox.bottom, equals(23));
    expect(textBox.left, equals(372));
    expect(box.right - textBox.right, equals(36));

    // Try increasing density (with lower density numbers).
    await buildTest(const VisualDensity(horizontal: -3.0, vertical: -3.0));
    box = tester.getRect(find.byKey(key));
    textBox = tester.getRect(find.byKey(textKey));
    iconBox = tester.getRect(find.byKey(iconKey));
    avatarBox = tester.getRect(find.byKey(avatarKey));
    expect(box.size, equals(const Size(128, 36)));
    expect(textBox.size, equals(const Size(56, 14)));
    expect(iconBox.size, equals(const Size(24, 24)));
    expect(avatarBox.size, equals(const Size(24, 24)));
    expect(textBox.top, equals(11));
    expect(box.bottom - textBox.bottom, equals(11));
    expect(textBox.left, equals(372));
    expect(box.right - textBox.right, equals(36));

    // Now test that horizontal and vertical are wired correctly. Negating the
    // horizontal should have no change over what's above.
    await buildTest(const VisualDensity(horizontal: 3.0, vertical: -3.0));
    await tester.pumpAndSettle();
    box = tester.getRect(find.byKey(key));
    textBox = tester.getRect(find.byKey(textKey));
    iconBox = tester.getRect(find.byKey(iconKey));
    avatarBox = tester.getRect(find.byKey(avatarKey));
    expect(box.size, equals(const Size(128, 36)));
    expect(textBox.size, equals(const Size(56, 14)));
    expect(iconBox.size, equals(const Size(24, 24)));
    expect(avatarBox.size, equals(const Size(24, 24)));
    expect(textBox.top, equals(11));
    expect(box.bottom - textBox.bottom, equals(11));
    expect(textBox.left, equals(372));
    expect(box.right - textBox.right, equals(36));

    // Make sure the "Comfortable" setting is the spec'd size
    await buildTest(VisualDensity.comfortable);
    await tester.pumpAndSettle();
    box = tester.getRect(find.byKey(key));
    expect(box.size, equals(const Size(128, 28.0 + 16.0)));

    // Make sure the "Compact" setting is the spec'd size
    await buildTest(VisualDensity.compact);
    await tester.pumpAndSettle();
    box = tester.getRect(find.byKey(key));
    expect(box.size, equals(const Size(128, 24.0 + 16.0)));
  });

  testWidgets('Input chip check mark color is determined by platform brightness when light', (WidgetTester tester) async {
    await _pumpCheckmarkChip(
      tester,
      chip: _selectedInputChip(),
      brightness: Brightness.light,
    );

    _expectCheckmarkColor(
      find.byType(InputChip),
      Colors.black.withAlpha(0xde),
    );
  });

  testWidgets('Filter chip check mark color is determined by platform brightness when light', (WidgetTester tester) async {
    await _pumpCheckmarkChip(
      tester,
      chip: _selectedFilterChip(),
      brightness: Brightness.light,
    );

    _expectCheckmarkColor(
      find.byType(FilterChip),
      Colors.black.withAlpha(0xde),
    );
  });

  testWidgets('Input chip check mark color is determined by platform brightness when dark', (WidgetTester tester) async {
    await _pumpCheckmarkChip(
      tester,
      chip: _selectedInputChip(),
      brightness: Brightness.dark,
    );

    _expectCheckmarkColor(
      find.byType(InputChip),
      Colors.white.withAlpha(0xde),
    );
  });

  testWidgets('Filter chip check mark color is determined by platform brightness when dark', (WidgetTester tester) async {
    await _pumpCheckmarkChip(
      tester,
      chip: _selectedFilterChip(),
      brightness: Brightness.dark,
    );

    _expectCheckmarkColor(
      find.byType(FilterChip),
      Colors.white.withAlpha(0xde),
    );
  });

  testWidgets('Input chip check mark color can be set by the chip theme', (WidgetTester tester) async {
    await _pumpCheckmarkChip(
      tester,
      chip: _selectedInputChip(),
      themeColor: const Color(0xff00ff00),
    );

    _expectCheckmarkColor(
      find.byType(InputChip),
      const Color(0xff00ff00),
    );
  });

  testWidgets('Filter chip check mark color can be set by the chip theme', (WidgetTester tester) async {
    await _pumpCheckmarkChip(
      tester,
      chip: _selectedFilterChip(),
      themeColor: const Color(0xff00ff00),
    );

    _expectCheckmarkColor(
      find.byType(FilterChip),
      const Color(0xff00ff00),
    );
  });

  testWidgets('Input chip check mark color can be set by the chip constructor', (WidgetTester tester) async {
    await _pumpCheckmarkChip(
      tester,
      chip: _selectedInputChip(checkmarkColor: const Color(0xff00ff00)),
    );

    _expectCheckmarkColor(
      find.byType(InputChip),
      const Color(0xff00ff00),
    );
  });

  testWidgets('Filter chip check mark color can be set by the chip constructor', (WidgetTester tester) async {
    await _pumpCheckmarkChip(
      tester,
      chip: _selectedFilterChip(checkmarkColor: const Color(0xff00ff00)),
    );

    _expectCheckmarkColor(
      find.byType(FilterChip),
      const Color(0xff00ff00),
    );
  });

  testWidgets('Input chip check mark color is set by chip constructor even when a theme color is specified', (WidgetTester tester) async {
    await _pumpCheckmarkChip(
      tester,
      chip: _selectedInputChip(checkmarkColor: const Color(0xffff0000)),
      themeColor: const Color(0xff00ff00),
    );

    _expectCheckmarkColor(
      find.byType(InputChip),
      const Color(0xffff0000),
    );
  });

  testWidgets('Filter chip check mark color is set by chip constructor even when a theme color is specified', (WidgetTester tester) async {
    await _pumpCheckmarkChip(
      tester,
      chip: _selectedFilterChip(checkmarkColor: const Color(0xffff0000)),
      themeColor: const Color(0xff00ff00),
    );

    _expectCheckmarkColor(
      find.byType(FilterChip),
      const Color(0xffff0000),
    );
  });
}
