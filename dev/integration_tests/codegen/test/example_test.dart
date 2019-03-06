import 'package:codegen/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('can reference generated code', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: GeneratedWidget()));

    expect(find.text('Thanks for using PourOverSupremeFiesta by Coffee by Flutter Inc.'), findsOneWidget);
  });
}
