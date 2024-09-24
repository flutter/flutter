// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/snack_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('snack bar can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, SnackBarUseCase());
    const String snackBarText = 'Awesome Snackbar!';
    expect(find.text(snackBarText), findsNothing);
    await tester.tap(find.text('Show Snackbar'));
    expect(find.text(snackBarText), findsNothing);
    await tester.pump();
    expect(find.text(snackBarText), findsOneWidget);
  });

  testWidgets('snack bar demo page has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, SnackBarUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel('SnackBar Demo');
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });
}
