// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

/// Adds the basic requirements for a Chip.
Widget wrapForChip({
  required final Widget child,
  final TextDirection textDirection = TextDirection.ltr,
  final double textScaleFactor = 1.0,
  final Brightness brightness = Brightness.light,
  final bool useMaterial3 = false,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness, useMaterial3: useMaterial3),
    home: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: MediaQueryData(textScaleFactor: textScaleFactor),
        child: Material(child: child),
      ),
    ),
  );
}

Widget selectedInputChip({
  final Color? checkmarkColor,
  final bool enabled = false,
}) {
  return InputChip(
    label: const Text('InputChip'),
    selected: true,
    isEnabled: enabled,
    showCheckmark: true,
    checkmarkColor: checkmarkColor,
  );
}


Future<void> pumpCheckmarkChip(
  final WidgetTester tester, {
  required final Widget chip,
  final Color? themeColor,
  final Brightness brightness = Brightness.light,
  final bool useMaterial3 = false,
}) async {
  await tester.pumpWidget(
    wrapForChip(
      useMaterial3: useMaterial3,
      brightness: brightness,
      child: Builder(
        builder: (final BuildContext context) {
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

void expectCheckmarkColor(final Finder finder, final Color color) {
  expect(
    finder,
    paints
      // Physical model layer path
      ..path()
      // The first layer that is painted is the selection overlay. We do not care
      // how it is painted but it has to be added it to this pattern so that the
      // check mark can be checked next.
      ..rrect()
      // The second layer that is painted is the check mark.
      ..path(color: color),
  );
}

RenderBox getMaterialBox(final WidgetTester tester) {
  return tester.firstRenderObject<RenderBox>(
    find.descendant(
      of: find.byType(InputChip),
      matching: find.byType(CustomPaint),
    ),
  );
}

void checkChipMaterialClipBehavior(final WidgetTester tester, final Clip clipBehavior) {
  final Iterable<Material> materials = tester.widgetList<Material>(find.byType(Material));
  // There should be two Material widgets, first Material is from the "_wrapForChip" and
  // last Material is from the "RawChip".
  expect(materials.length, 2);
  // The last Material from `RawChip` should have the clip behavior.
  expect(materials.last.clipBehavior, clipBehavior);
}

void main() {
  testWidgets('InputChip can be tapped', (final WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: InputChip(
            label: Text('input chip'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InputChip));
    expect(tester.takeException(), null);
  });

  testWidgets('loses focus when disabled', (final WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'InputChip');
    await tester.pumpWidget(
      wrapForChip(
        child: InputChip(
          focusNode: focusNode,
          autofocus: true,
          shape: const RoundedRectangleBorder(),
          avatar: const CircleAvatar(child: Text('A')),
          label: const Text('Chip A'),
          onPressed: () { },
        ),
      ),
    );
    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.pumpWidget(
      wrapForChip(
        child: InputChip(
          focusNode: focusNode,
          autofocus: true,
          shape: const RoundedRectangleBorder(),
          avatar: const CircleAvatar(child: Text('A')),
          label: const Text('Chip A'),
        ),
      ),
    );
    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isFalse);
  });

  testWidgets('cannot be traversed to when disabled', (final WidgetTester tester) async {
    final FocusNode focusNode1 = FocusNode(debugLabel: 'InputChip 1');
    final FocusNode focusNode2 = FocusNode(debugLabel: 'InputChip 2');
    await tester.pumpWidget(
      wrapForChip(
        child: FocusScope(
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
              ),
            ],
          ),
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

  testWidgets('Input chip check mark color is determined by platform brightness when light', (final WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedInputChip(),
    );

    expectCheckmarkColor(
      find.byType(InputChip),
      Colors.black.withAlpha(0xde),
    );
  });

  testWidgets('Input chip check mark color is determined by platform brightness when dark', (final WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedInputChip(),
      brightness: Brightness.dark,
    );

    expectCheckmarkColor(
      find.byType(InputChip),
      Colors.white.withAlpha(0xde),
    );
  });

  testWidgets('Input chip check mark color can be set by the chip theme', (final WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedInputChip(),
      themeColor: const Color(0xff00ff00),
    );

    expectCheckmarkColor(
      find.byType(InputChip),
      const Color(0xff00ff00),
    );
  });

  testWidgets('Input chip check mark color can be set by the chip constructor', (final WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedInputChip(checkmarkColor: const Color(0xff00ff00)),
    );

    expectCheckmarkColor(
      find.byType(InputChip),
      const Color(0xff00ff00),
    );
  });

  testWidgets('Input chip check mark color is set by chip constructor even when a theme color is specified', (final WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedInputChip(checkmarkColor: const Color(0xffff0000)),
      themeColor: const Color(0xff00ff00),
    );

    expectCheckmarkColor(
      find.byType(InputChip),
      const Color(0xffff0000),
    );
  });

  testWidgets('InputChip clipBehavior properly passes through to the Material', (final WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(wrapForChip(child: const InputChip(label: label)));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(wrapForChip(child: const InputChip(label: label, clipBehavior: Clip.antiAlias)));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });

  testWidgets('Input chip has correct selected color when enabled - M3 defaults', (final WidgetTester tester) async {
    final ChipThemeData material3ChipDefaults = ThemeData(useMaterial3: true).chipTheme;
    await pumpCheckmarkChip(
      tester,
      chip: selectedInputChip(enabled: true),
      useMaterial3: true,
    );

    final RenderBox materialBox = getMaterialBox(tester);
    expect(materialBox, paints..rrect(color: material3ChipDefaults.backgroundColor));
  });

  testWidgets('Input chip has correct selected color when disabled - M3 defaults', (final WidgetTester tester) async {
    final ChipThemeData material3ChipDefaults = ThemeData(useMaterial3: true).chipTheme;
    await pumpCheckmarkChip(
      tester,
      chip: selectedInputChip(),
      useMaterial3: true,
    );

    final RenderBox materialBox = getMaterialBox(tester);
    expect(materialBox, paints..path(color: material3ChipDefaults.disabledColor));
  });
}
