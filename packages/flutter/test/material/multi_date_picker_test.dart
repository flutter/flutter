import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  group
    ('CalendarMultiDatePicker', () {
// Tests for the standalone CalendarMultiDatePicker class
    testWidgets('Updates to initialDate parameter is reflected in the state', (
        WidgetTester tester) async {
      final Key pickerKey = UniqueKey();
      final DateTime initialDate = DateTime(2020, 1, 21);
      final DateTime updatedDate = DateTime(1976, 2, 23);
      const Color selectedColor = Color(0xff2196f3); // default primary color

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: CalendarMultiDatePicker(
            key: pickerKey,
            initialDate: initialDate,
            firstDate: DateTime(1970, 1, 1),
            lastDate: DateTime(2099, 31, 12),
            maxDateSelect: 3,
            onDateListChanged: (DateTime value) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

// Month should show as January 2020
      expect(find.text('January 2020'), findsOneWidget);
// Selected date should be painted with a colored circle
      expect(
          Material.of(tester.element(find.text('21'))),
          paints..circle(color: selectedColor, style: PaintingStyle.fill)
      );

// Change to the updated initialDate
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: CalendarMultiDatePicker(
            key: pickerKey,
            initialDate: updatedDate,
            firstDate: DateTime(1970, 1, 1),
            lastDate: DateTime(2099, 31, 12),
            maxDateSelect: 3,
            onDateListChanged: (DateTime value) {},
          ),
        ),
      ));
// Wait for the page scroll animation to finish
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

// Month should show as February 1976
      expect(find.text('January 2020'), findsNothing);
      expect(find.text('February 1976'), findsOneWidget);
// Selected date should be painted with a colored circle
      expect(
          Material.of(tester.element(find.text('23'))),
          paints..circle(color: selectedColor, style: PaintingStyle.fill)
      );
    });
  });
}