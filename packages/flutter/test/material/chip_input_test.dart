// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

/// Adds the basic requirements for a Chip.
Widget _wrapForChip({
  required Widget child,
  TextDirection textDirection = TextDirection.ltr,
  double textScaleFactor = 1.0,
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(textScaleFactor: textScaleFactor),
        child: Material(child: child),
      ),
    ),
  );
}

Widget _selectedInputChip({ Color? checkmarkColor }) {
  return InputChip(
    label: const Text('InputChip'),
    selected: true,
    showCheckmark: true,
    checkmarkColor: checkmarkColor,
  );
}


Future<void> _pumpCheckmarkChip(
  WidgetTester tester, {
  required Widget chip,
  Color? themeColor,
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



void main() {
  testWidgets('InputChip can be tapped', (WidgetTester tester) async {
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

  testWidgets('loses focus when disabled', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'InputChip');
    await tester.pumpWidget(
      _wrapForChip(
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
      _wrapForChip(
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

  testWidgets('Input chip check mark color is determined by platform brightness when light', (WidgetTester tester) async {
    await _pumpCheckmarkChip(
      tester,
      chip: _selectedInputChip(),
    );

    _expectCheckmarkColor(
      find.byType(InputChip),
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

  void checkChipMaterialClipBehavior(WidgetTester tester, Clip clipBehavior) {
    final Iterable<Material> materials = tester.widgetList<Material>(find.byType(Material));
    expect(materials.length, 2);
    expect(materials.last.clipBehavior, clipBehavior);
  }

  testWidgets('InputChip clipBehavior properly passes through to the Material', (WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(_wrapForChip(child: const InputChip(label: label)));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(_wrapForChip(child: const InputChip(label: label, clipBehavior: Clip.antiAlias)));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });
}
