// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  testWidgets('ActionChip can be tapped', (WidgetTester tester) async {
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
  });

  void checkChipMaterialClipBehavior(WidgetTester tester, Clip clipBehavior) {
    final Iterable<Material> materials = tester.widgetList<Material>(find.byType(Material));
    expect(materials.length, 2);
    expect(materials.last.clipBehavior, clipBehavior);
  }

  testWidgets('ActionChip clipBehavior properly passes through to the Material', (WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(_wrapForChip(child: ActionChip(label: label, onPressed: () { })));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(_wrapForChip(child: ActionChip(label: label, clipBehavior: Clip.antiAlias, onPressed: () { })));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });
}
