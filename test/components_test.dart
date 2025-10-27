
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing_app/components.dart';

void main() {
  testWidgets('ComponentsPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ComponentsPage()));

    expect(find.text('1 - Card'), findsOneWidget);
    expect(find.text('2 - Container'), findsOneWidget);
    expect(find.text('3 - ListView'), findsOneWidget);
    expect(find.text('4 - GridView'), findsOneWidget);
    expect(find.text('5 - Stack'), findsOneWidget);
    expect(find.text('6 - ConstrainedBox'), findsOneWidget);
    expect(find.text('7 - SingleChildScrollView'), findsOneWidget);
    expect(find.text('8 - Common Buttons'), findsOneWidget);
    expect(find.text('9 - IconButton'), findsOneWidget);
    expect(find.text('10 - SegmentedButton'), findsOneWidget);
    expect(find.text('11 - Badge'), findsOneWidget);
    expect(find.text('12 - AlertDialog'), findsOneWidget);
    expect(find.text('13 - Checkbox'), findsOneWidget);
    expect(find.text('14 - Chip'), findsOneWidget);
    expect(find.text('15 - Menu'), findsOneWidget);
    expect(find.text('16 - Radio'), findsOneWidget);
    expect(find.text('17 - Slider'), findsOneWidget);
    expect(find.text('18 - Switch'), findsOneWidget);
    expect(find.text('19 - TextField'), findsOneWidget);
  });

  testWidgets('Checkbox changes state when tapped', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ComponentsPage()));

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('Switch changes state when tapped', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ComponentsPage()));

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('Radio changes state when tapped', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ComponentsPage()));

    expect(tester.widget<Radio<String>>(find.byType(Radio<String>).first).groupValue, 'A');

    await tester.tap(find.byType(Radio<String>).last);
    await tester.pump();

    expect(tester.widget<Radio<String>>(find.byType(Radio<String>).first).groupValue, 'C');
  });

  testWidgets('Slider changes value when dragged', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ComponentsPage()));

    expect(tester.widget<Slider>(find.byType(Slider)).value, 40);

    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.pump();

    expect(tester.widget<Slider>(find.byType(Slider)).value, greaterThan(40));
  });

  testWidgets('SegmentedButton changes state when tapped', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ComponentsPage()));

    expect(find.widgetWithIcon(SegmentedButton<int>, Icons.looks_one), findsOneWidget);
  });

  testWidgets('TextField updates its value on input', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ComponentsPage()));

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();

    expect(find.text('Você digitou: Hello'), findsOneWidget);
  });

  testWidgets('DropdownButton changes value on selection', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ComponentsPage()));

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pump();

    await tester.tap(find.text('Opção B').last);
    await tester.pump();

    expect(find.text('Opção B'), findsOneWidget);
  });

  testWidgets('AlertDialog shows on button tap', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ComponentsPage()));

    await tester.tap(find.text('Mostrar Alerta'));
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Fechar'));
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
