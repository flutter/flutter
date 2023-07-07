// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/src/widgets/custom_icon_button.dart';

Widget setupTestWidget(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Material(child: child),
  );
}

void main() {
  testWidgets(
    'onTap gets called when CustomIconButton is tapped',
    (tester) async {
      bool buttonTapped = false;

      await tester.pumpWidget(
        setupTestWidget(
          CustomIconButton(
            icon: Icon(Icons.chevron_left),
            onTap: () {
              buttonTapped = true;
            },
          ),
        ),
      );

      final button = find.byType(CustomIconButton);
      expect(button, findsOneWidget);
      expect(buttonTapped, false);

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(buttonTapped, true);
    },
  );
}
