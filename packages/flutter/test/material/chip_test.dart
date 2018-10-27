// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show window;

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
    find
        .descendant(
      of: find.byType(RawChip),
      matching: find.byType(DefaultTextStyle),
    )
        .last,
  );
}

dynamic getRenderChip(WidgetTester tester) {
  if (!tester.any(findRenderChipElement())) {
    return null;
  }
  final Element element = tester.element(findRenderChipElement());
  return element.renderObject;
}

double getSelectProgress(WidgetTester tester) => getRenderChip(tester)?.checkmarkAnimation?.value;
double getAvatarDrawerProgress(WidgetTester tester) => getRenderChip(tester)?.avatarDrawerAnimation?.value;
double getDeleteDrawerProgress(WidgetTester tester) => getRenderChip(tester)?.deleteDrawerAnimation?.value;
double getEnableProgress(WidgetTester tester) => getRenderChip(tester)?.enableAnimation?.value;

/// Adds the basic requirements for a Chip.
Widget _wrapForChip({
  Widget child,
  TextDirection textDirection = TextDirection.ltr,
  double textScaleFactor = 1.0,
}) {
  return MaterialApp(
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
      'the available space', (WidgetTester tester) async {
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
  });

  testWidgets(
      'Chip constrains the size of the label widget when it exceeds the '
      'available space', (WidgetTester tester) async {
    await _testConstrainedLabel(tester);
  });

  testWidgets(
      'Chip constrains the size of the label widget when it exceeds the '
      'available space and the avatar is present', (WidgetTester tester) async {
    await _testConstrainedLabel(
      tester,
      avatar: const CircleAvatar(child: Text('A')),
    );
  });

  testWidgets(
      'Chip constrains the size of the label widget when it exceeds the '
      'available space and the delete icon is present', (WidgetTester tester) async {
    await _testConstrainedLabel(
      tester,
      onDeleted: () {},
    );
  });

  testWidgets(
      'Chip constrains the size of the label widget when it exceeds the '
      'available space and both avatar and delete icons are present', (WidgetTester tester) async {
    await _testConstrainedLabel(
      tester,
      avatar: const CircleAvatar(child: Text('A')),
      onDeleted: () {},
    );
  });

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
    expect(tester.getSize(find.byType(Chip)), const Size(64.0,48.0));
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
                onDeleted: () {},
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
    expect(tester.getSize(find.byType(Chip).first).width, anyOf(318.0, 319.0));
    expect(tester.getSize(find.byType(Chip).first).height, equals(50.0));
    expect(tester.getSize(find.byType(Chip).last).width, anyOf(318.0, 319.0));
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
              onDeleted: () {},
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
                      onDeleted: () {},
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
                      onDeleted: () {},
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
    Future<void> pushChip({Widget avatar}) async {
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
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(81.2, 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, closeTo(-18.8, 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, closeTo(13.2, 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(86.7, 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, closeTo(-13.3, 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, closeTo(18.6, 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(94.7, 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, closeTo(-5.3, 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, closeTo(26.7, 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(99.5, 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, closeTo(-0.5, 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, closeTo(31.5, 0.1));

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
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(102.9, 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, closeTo(2.9, 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, closeTo(34.9, 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(98.0, 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, closeTo(-2.0, 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, closeTo(30.0, 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(84.1, 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, closeTo(-15.9, 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, closeTo(16.1, 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(80.0, 0.1));
    expect(tester.getSize(find.byKey(avatarKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(avatarKey)).dx, closeTo(-20.0, 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)).dx, closeTo(12.0, 0.1));

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
    Future<void> pushChip({bool deletable = false}) async {
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
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(81.2, 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, closeTo(53.2, 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)), equals(const Offset(12.0, 17.0)));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(86.7, 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, closeTo(58.7, 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(94.7, 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, closeTo(66.7, 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(99.5, 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, closeTo(71.5, 0.1));

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
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(103.8, 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, closeTo(75.8, 0.1));
    expect(tester.getTopLeft(find.byKey(labelKey)), equals(const Offset(12.0, 17.0)));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(102.9, 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, closeTo(74.9, 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(101.0, 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, closeTo(73.0, 0.1));

    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.getSize(find.byType(RawChip)).width, closeTo(97.5, 0.1));
    expect(tester.getSize(find.byKey(deleteButtonKey)), equals(const Size(24.0, 24.0)));
    expect(tester.getTopLeft(find.byKey(deleteButtonKey)).dx, closeTo(69.5, 0.1));

    // Wait for being done with animation, make sure it didn't change
    // height, and make sure that the delete button is no longer drawn.
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(tester.getSize(find.byType(RawChip)), equals(const Size(80.0, 48.0)));
    expect(tester.getTopLeft(find.byKey(labelKey)), equals(const Offset(12.0, 17.0)));
    expect(find.byKey(deleteButtonKey), findsNothing);
  });

  testWidgets('Selection with avatar works as expected on RawChip', (WidgetTester tester) async {
    bool selected = false;
    final UniqueKey labelKey = UniqueKey();
    Future<void> pushChip({Widget avatar, bool selectable = false}) async {
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
    expect(getSelectProgress(tester), closeTo(0.002, 0.01));
    expect(getAvatarDrawerProgress(tester), equals(1.0));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 50));
    expect(getSelectProgress(tester), closeTo(0.54, 0.01));
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
    expect(getSelectProgress(tester), closeTo(0.875, 0.01));
    expect(getAvatarDrawerProgress(tester), equals(1.0));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 20));
    expect(getSelectProgress(tester), closeTo(0.13, 0.01));
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
    Future<void> pushChip({bool selectable = false}) async {
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
    expect(getSelectProgress(tester), closeTo(0.002, 0.01));
    expect(getAvatarDrawerProgress(tester), closeTo(0.459, 0.01));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 50));
    expect(getSelectProgress(tester), closeTo(0.54, 0.01));
    expect(getAvatarDrawerProgress(tester), closeTo(0.92, 0.01));
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
    expect(getSelectProgress(tester), closeTo(0.875, 0.01));
    expect(getAvatarDrawerProgress(tester), closeTo(0.96, 0.01));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 20));
    expect(getSelectProgress(tester), closeTo(0.13, 0.01));
    expect(getAvatarDrawerProgress(tester), closeTo(0.75, 0.01));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(getSelectProgress(tester), equals(0.0));
    expect(getAvatarDrawerProgress(tester), equals(0.0));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
  });

  testWidgets('Activation works as expected on RawChip', (WidgetTester tester) async {
    bool selected = false;
    final UniqueKey labelKey = UniqueKey();
    Future<void> pushChip({Widget avatar, bool selectable = false}) async {
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
    expect(getSelectProgress(tester), closeTo(0.002, 0.01));
    expect(getAvatarDrawerProgress(tester), equals(1.0));
    expect(getDeleteDrawerProgress(tester), equals(0.0));
    await tester.pump(const Duration(milliseconds: 50));
    expect(getSelectProgress(tester), closeTo(0.54, 0.01));
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
                onDeleted: isDeletable ? () {} : null,
                tapEnabled: true,
                avatar: avatar,
                deleteIcon: deleteIcon,
                isEnabled: isSelectable || isPressable,
                shape: chipTheme.shape,
                selected: isSelectable ? value : null,
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
                    flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                    children: <TestSemantics>[
                      TestSemantics(
                        label: 'test',
                        textDirection: TextDirection.ltr,
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
            onPressed: () {},
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
                    flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                    children: <TestSemantics>[
                      TestSemantics(
                        label: 'test',
                        textDirection: TextDirection.ltr,
                        flags: <SemanticsFlag>[
                          SemanticsFlag.hasEnabledState,
                          SemanticsFlag.isEnabled,
                        ],
                        actions: <SemanticsAction>[SemanticsAction.tap],
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
                    flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                    children: <TestSemantics>[
                      TestSemantics(
                        label: 'test',
                        textDirection: TextDirection.ltr,
                        flags: <SemanticsFlag>[
                          SemanticsFlag.hasEnabledState,
                          SemanticsFlag.isEnabled,
                        ],
                        actions: <SemanticsAction>[SemanticsAction.tap],
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
                    flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                    children: <TestSemantics>[
                      TestSemantics(
                        label: 'test',
                        textDirection: TextDirection.ltr,
                        flags: <SemanticsFlag>[
                          SemanticsFlag.isSelected,
                          SemanticsFlag.hasEnabledState,
                          SemanticsFlag.isEnabled,
                        ],
                        actions: <SemanticsAction>[SemanticsAction.tap],
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
                    flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                    children: <TestSemantics>[
                      TestSemantics(
                        label: 'test',
                        textDirection: TextDirection.ltr,
                        flags: <SemanticsFlag>[],
                        actions: <SemanticsAction>[],
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
            onPressed: (){},
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
            onSelected: (bool valueChanged){},
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

  testWidgets('Chip elevation works correctly', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.red,
    );

    final ChipThemeData chipTheme = theme.chipTheme;

    InputChip inputChip = const InputChip(label: Text('Label'), pressElevation: 8.0);

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
    expect(inputChip.pressElevation, 8.0);

    inputChip = const InputChip(label: Text('Label'), pressElevation: 12.0);

    await tester.pumpWidget(buildChip(chipTheme));
    await tester.pumpAndSettle();
    expect(inputChip.pressElevation, 12.0);
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
          onPressed: () {},
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
    await tester.pumpWidget(_wrapForChip(child: FilterChip(label: label, onSelected: (bool b){},)));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(_wrapForChip(child: FilterChip(label: label, onSelected: (bool b){}, clipBehavior: Clip.antiAlias)));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });

  testWidgets('ActionChip clipBehavior properly passes through to the Material', (WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(_wrapForChip(child: ActionChip(label: label, onPressed: (){},)));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(_wrapForChip(child: ActionChip(label: label, clipBehavior: Clip.antiAlias, onPressed: (){})));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });

  testWidgets('InputChip clipBehavior properly passes through to the Material', (WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(_wrapForChip(child: const InputChip(label: label)));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(_wrapForChip(child: const InputChip(label: label, clipBehavior: Clip.antiAlias)));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });
}
