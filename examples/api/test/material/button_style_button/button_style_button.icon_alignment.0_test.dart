// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/button_style_button/button_style_button.icon_alignment.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ButtonStyleButton iconAlignment Example Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ButtonStyleButtonIconAlignmentExampleApp(),
    );

    expect(find.widgetWithText(AppBar, 'ButtonStyleButton iconAlignment Sample'), findsOneWidget);
    expect(find.text('ElevatedButton.icon'), findsOneWidget);
    expect(find.text('FilledButton.icon'), findsOneWidget);
    expect(find.text('FilledButton.tonalIcon'), findsOneWidget);
    expect(find.text('OutlinedButton.icon'), findsOneWidget);
    expect(find.text('TextButton.icon'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNWidgets(5));

    final Finder iconAlignmentStartCc = find.widgetWithText(ChoiceChip, 'IconAlignment.start');
    final Finder iconAlignmentEndCc = find.widgetWithText(ChoiceChip, 'IconAlignment.end');
    await tester.tap(iconAlignmentStartCc);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(iconAlignmentStartCc).selected, isTrue);
    expect(tester.widget<ChoiceChip>(iconAlignmentEndCc).selected, isFalse);
    await tester.tap(iconAlignmentEndCc);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(iconAlignmentStartCc).selected, isFalse);
    expect(tester.widget<ChoiceChip>(iconAlignmentEndCc).selected, isTrue);

    final Finder textDirectionLtrCc = find.widgetWithText(ChoiceChip, 'TextDirection.ltr');
    final Finder textDirectionRtlCc = find.widgetWithText(ChoiceChip, 'TextDirection.rtl');
    await tester.tap(textDirectionLtrCc);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(textDirectionLtrCc).selected, isTrue);
    expect(tester.widget<ChoiceChip>(textDirectionRtlCc).selected, isFalse);
    await tester.tap(textDirectionRtlCc);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(textDirectionLtrCc).selected, isFalse);
    expect(tester.widget<ChoiceChip>(textDirectionRtlCc).selected, isTrue);

    // IconAlignment.start & TextDirection.ltr
    await tester.tap(iconAlignmentStartCc);
    await tester.pumpAndSettle();
    await tester.tap(textDirectionLtrCc);
    await tester.pumpAndSettle();
    expect(
      tester.widget<ElevatedButton>(
        find.byKey(const Key('ElevatedButton.icon')),
      ).iconAlignment,
      IconAlignment.start,
    );
    expect(
      tester.widget<FilledButton>(
        find.byKey(const Key('FilledButton.icon')),
      ).iconAlignment,
      IconAlignment.start,
    );
    expect(
      tester.widget<FilledButton>(
        find.byKey(const Key('FilledButton.tonalIcon')),
      ).iconAlignment,
      IconAlignment.start,
    );
    expect(
      tester.widget<OutlinedButton>(
        find.byKey(const Key('OutlinedButton.icon')),
      ).iconAlignment,
      IconAlignment.start,
    );
    expect(
      tester.widget<TextButton>(
        find.byKey(const Key('TextButton.icon')),
      ).iconAlignment,
      IconAlignment.start,
    );
    expect(
      tester.widget<Directionality>(
        find.byKey(const Key('Directionality')),
      ).textDirection,
      TextDirection.ltr,
    );

    // IconAlignment.end & TextDirection.ltr
    await tester.tap(iconAlignmentEndCc);
    await tester.pumpAndSettle();
    await tester.tap(textDirectionLtrCc);
    await tester.pumpAndSettle();
    expect(
      tester.widget<ElevatedButton>(
        find.byKey(const Key('ElevatedButton.icon')),
      ).iconAlignment,
      IconAlignment.end,
    );
    expect(
      tester.widget<FilledButton>(
        find.byKey(const Key('FilledButton.icon')),
      ).iconAlignment,
      IconAlignment.end,
    );
    // expect(
    //   tester.widget<FilledButton>(
    //     find.byKey(const Key('FilledButton.tonalIcon')),
    //   ).iconAlignment,
    //   IconAlignment.end,
    // );
    expect(
      tester.widget<OutlinedButton>(
        find.byKey(const Key('OutlinedButton.icon')),
      ).iconAlignment,
      IconAlignment.end,
    );
    expect(
      tester.widget<TextButton>(
        find.byKey(const Key('TextButton.icon')),
      ).iconAlignment,
      IconAlignment.end,
    );
    expect(
      tester.widget<Directionality>(
        find.byKey(const Key('Directionality')),
      ).textDirection,
      TextDirection.ltr,
    );

    // IconAlignment.start & TextDirection.rtl
    await tester.tap(iconAlignmentStartCc);
    await tester.pumpAndSettle();
    await tester.tap(textDirectionRtlCc);
    await tester.pumpAndSettle();
    expect(
      tester.widget<ElevatedButton>(
        find.byKey(const Key('ElevatedButton.icon')),
      ).iconAlignment,
      IconAlignment.start,
    );
    expect(
      tester.widget<FilledButton>(
        find.byKey(const Key('FilledButton.icon')),
      ).iconAlignment,
      IconAlignment.start,
    );
    expect(
      tester.widget<FilledButton>(
        find.byKey(const Key('FilledButton.tonalIcon')),
      ).iconAlignment,
      IconAlignment.start,
    );
    expect(
      tester.widget<OutlinedButton>(
        find.byKey(const Key('OutlinedButton.icon')),
      ).iconAlignment,
      IconAlignment.start,
    );
    expect(
      tester.widget<TextButton>(
        find.byKey(const Key('TextButton.icon')),
      ).iconAlignment,
      IconAlignment.start,
    );
    expect(
      tester.widget<Directionality>(
        find.byKey(const Key('Directionality')),
      ).textDirection,
      TextDirection.rtl,
    );

    // IconAlignment.end & TextDirection.rtl
    await tester.tap(iconAlignmentEndCc);
    await tester.pumpAndSettle();
    await tester.tap(textDirectionRtlCc);
    await tester.pumpAndSettle();
    expect(
      tester.widget<ElevatedButton>(
        find.byKey(const Key('ElevatedButton.icon')),
      ).iconAlignment,
      IconAlignment.end,
    );
    expect(
      tester.widget<FilledButton>(
        find.byKey(const Key('FilledButton.icon')),
      ).iconAlignment,
      IconAlignment.end,
    );
    // expect(
    //   tester.widget<FilledButton>(
    //     find.byKey(const Key('FilledButton.tonalIcon')),
    //   ).iconAlignment,
    //   IconAlignment.end,
    // );
    expect(
      tester.widget<OutlinedButton>(
        find.byKey(const Key('OutlinedButton.icon')),
      ).iconAlignment,
      IconAlignment.end,
    );
    expect(
      tester.widget<TextButton>(
        find.byKey(const Key('TextButton.icon')),
      ).iconAlignment,
      IconAlignment.end,
    );
    expect(
      tester.widget<Directionality>(
        find.byKey(const Key('Directionality')),
      ).textDirection,
      TextDirection.rtl,
    );
  });
}
