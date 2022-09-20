import 'package:flutter/material.dart' as material show Size;
import 'package:flutter/widgets.dart' as widgets show Container, runApp;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macos_window_resize/main.dart' as app show ResizeApp;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('resize window after calling runApp twice, the second with no content',
        timeout: const Timeout(Duration(seconds: 5)),
        (WidgetTester tester) async {
      const app.ResizeApp root = app.ResizeApp();
      widgets.runApp(root);
      widgets.runApp(widgets.Container());

      await tester.pumpAndSettle();

      const material.Size expectedSize = material.Size(100, 100);
      await app.ResizeApp.resize(expectedSize);
    });
  });
}
