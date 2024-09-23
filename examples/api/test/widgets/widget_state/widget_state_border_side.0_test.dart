// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/widget_state/widget_state_border_side.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Finder findByBorderColor(Color color) {
    return find.byWidgetPredicate((Widget widget) {
      if (widget is! Material) {
        return false;
      }

      final ShapeBorder? shape = widget.shape;

      if (shape is! OutlinedBorder) {
        return false;
      }

      return shape.side.color == color;
    });
  }

  testWidgets('FilterChip displays the correct border color when selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        const example.WidgetStateBorderSideExampleApp(),
      );

      expect(findByBorderColor(Colors.red), findsOneWidget);
    },
  );

  testWidgets('FilterChip displays the correct border color when not selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        const example.WidgetStateBorderSideExampleApp(),
      );

      await tester.tap(find.byType(FilterChip));
      await tester.pumpAndSettle();

      final ThemeData theme = Theme.of(tester.element(find.byType(FilterChip)));

      // By default FilterChip uses ColorScheme.outlineVariant color for side.
      expect(
        findByBorderColor(theme.colorScheme.outlineVariant),
        findsOneWidget,
      );
    },
  );
}
