import 'dart:convert';

import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('passing test 1', (WidgetTester tester) async {
    expect(true, true);
  });

  testWidgets('passing test 2', (WidgetTester tester) async {
    expect(true, true);
  });

  tearDownAll(() {
    print(
        'IntegrationTestWidgetsFlutterBinding test results: ${jsonEncode(binding.results)}');
  });
}
