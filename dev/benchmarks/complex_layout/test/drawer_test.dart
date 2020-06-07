// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:complex_layout/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// A workaround to get Radio<bool> type.
// See https://github.com/dart-lang/language/issues/1010
Type typeOf<T> () => T;

void main() {
  testWidgets(
    'GalleryDrawer updates UI after user action',
    (WidgetTester tester) async {
      await tester.pumpWidget(ComplexLayoutApp());
      await tester.pump();
      expect(find.text('Advanced Layout'), findsOneWidget);

      // 'Open navigation menu' is the default value of openAppDrawerTooltip
      await tester.tap(find.byTooltip('Open navigation menu'));
      // Note that here tester.pump([some duration]) doesn't work, due
      // to the animation of the drawer showing up.
      await tester.pumpAndSettle();

      final Finder darkRadio = find.descendant(
        of: find.ancestor(
          of: find.text('Dark'),
          matching: find.byType(ListTile),
        ),
        matching: find.byType(typeOf<Radio<bool>>()),
      );
      expect(darkRadio, findsOneWidget);
      expect(tester.widget<Radio<bool>>(darkRadio).groupValue, true);
      await tester.tap(darkRadio);
      await tester.pumpAndSettle();
      expect(tester.widget<Radio<bool>>(darkRadio).groupValue, false);
    },
  );
}
