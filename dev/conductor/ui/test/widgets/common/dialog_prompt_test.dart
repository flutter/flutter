// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/common/dialog_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('The dialog prompt appears upon clicking on a button', (WidgetTester tester) async {
    const String title = 'Are you sure you want to clean up the persistent state file?';
    const String content = 'This will abort a work in progress release.';
    const String leftOption = 'Yes';
    const String rightOption = 'No';

    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Builder(
          builder: (BuildContext context) {
            return Column(
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    dialogPrompt(
                      context: context,
                      title: title,
                      content: content,
                      leftOption: leftOption,
                      rightOption: rightOption,
                    );
                  },
                  child: const Text('Clean'),
                )
              ],
            );
          },
        ),
      ),
    ));

    expect(find.byType(ElevatedButton), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(find.text(title), findsOneWidget);
    expect(find.text(content), findsOneWidget);
    expect(find.text(leftOption), findsOneWidget);
    expect(find.text(rightOption), findsOneWidget);
  });
}
