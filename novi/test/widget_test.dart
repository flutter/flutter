import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:novi/main.dart';
import 'package:novi/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await loadSavedThemeMode();
  });

  testWidgets('Muestra pantalla de inicio de sesión', (WidgetTester tester) async {
    await tester.pumpWidget(const NoviApp());

    expect(find.text('Novi'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
