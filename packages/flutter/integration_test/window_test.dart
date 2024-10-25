import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void startApp() => runWidget(
        MultiWindowApp(initialWindows: <Future<Window> Function(BuildContext)>[
      (BuildContext context) => createRegular(
          context: context,
          size: const Size(800, 600),
          builder: (BuildContext context) {
            return const MaterialApp(home: MyApp());
          })
    ]));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: Text('Platform: ${Platform.operatingSystem}\n'),
      ),
    );
  }
}

/// [IntegrationTestWidgetsFlutterBinding] extends [TestWidgetsFlutterBinding]
/// under the hood. By default, [TestWidgetsFlutterBinding] displays two
/// messages: one before the test and one after the test. While this is fine
/// in the case that the user is testing with [runApp], it causes obscure
/// failures when used alongside [runWidget] in a multi-window context.
/// Specifically, the test code assumes that an implicit view exists, even
/// though the application does not initialize one. This causes strange
/// failures, such as the default matrix of the tests to have values which
/// include infinity. For these reasons, we disable pre- and post- test messages
/// when running tests with [runWidget].
class _RunWidgetIntegrationTestWidgetsFlutterBinding
    extends IntegrationTestWidgetsFlutterBinding {
  static _RunWidgetIntegrationTestWidgetsFlutterBinding? _instance;

  static _RunWidgetIntegrationTestWidgetsFlutterBinding ensureInitialized() {
    _instance ??= _RunWidgetIntegrationTestWidgetsFlutterBinding();
    return _instance!;
  }

  @override
  bool get showPreTestMessage => false;

  @override
  bool get showPostTestMessage => false;
}

void main() {
  _RunWidgetIntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test whether or not createWindow will throw on this platform',
      (WidgetTester tester) async {
    startApp();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
  });
}
