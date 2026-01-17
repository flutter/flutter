import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/date_picker/show_date_picker.2.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders selected date text according to formatType and separator (input mode)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: example.DatePickerSample()));

    expect(find.text('No date selected'), findsOneWidget);

    // Open date picker.
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    final Finder textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    // Enter date: 30/07/2021.
    await tester.enterText(textField, '30072021');
    await tester.pump();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('30.07.2021'), findsOneWidget);

    // Change format to monthDayYear.
    await tester.tap(find.byType(DropdownButtonFormField<example.DateInputFormat>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('mm/dd/yyyy').last);
    await tester.pumpAndSettle();

    expect(find.text('07.30.2021'), findsOneWidget);

    // Change separator to dash.
    await tester.tap(find.byType(DropdownButtonFormField<example.DateSeparator>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('-').last);
    await tester.pumpAndSettle();

    expect(find.text('07-30-2021'), findsOneWidget);

    // Change format to yearMonthDay.
    await tester.tap(find.byType(DropdownButtonFormField<example.DateInputFormat>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('yyyy/mm/dd').last);
    await tester.pumpAndSettle();

    expect(find.text('2021-07-30'), findsOneWidget);
  });
}
