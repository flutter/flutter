import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app should display a welcome message', (tester) async {
    expect(find.text('Welcome'), findsOneWidget);
  });
}
