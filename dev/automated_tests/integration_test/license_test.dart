// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can show the license page', (WidgetTester tester) async {
    await tester.pumpWidget(const TestApp());
    await tester.pump();

    final Finder button = find.byType(TextButton);

    await tester.tap(button);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      // Dart should very definitely be in the licenses list.
      find.text('dart'),
      100,
      maxScrolls: 200,
    );

    expect(find.text('dart'), findsOneWidget);
  });
}

class TestApp extends StatelessWidget {
  const TestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ShowLicenseButton(),
    );
  }
}

class ShowLicenseButton extends StatelessWidget {
  const ShowLicenseButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => showLicensePage(context: context),
      child: const Text(
        'Show licenses',
        key: Key('show-licenses'),
      ),
    );
  }
}
