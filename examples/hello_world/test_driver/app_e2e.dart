import 'dart:html';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/e2e.dart';
import 'package:hello_world/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  E2EWidgetsFlutterBinding binding =
      E2EWidgetsFlutterBinding.ensureInitialized() as E2EWidgetsFlutterBinding;

  setUpAll(() {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  });

  // Failing tests always halt. They timeout after 12 minutes and fail.
  // It might be because we are using flutter run instead of flutter test.
  // LiveTestWidgets do not have a timeout with flutter run.
  // testWidgets('fail finding widget', (WidgetTester tester) async {
  //   expect(2 + 2, test.equals(5));
  // });

  testWidgets('finding widgets', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Hello, world!'), findsNothing);
    expect(find.text('You have pushed the button this many times:'),
        findsOneWidget);
    expect(find.byKey(Key('input')), findsOneWidget);
  });

  testWidgets('finding semantics on DOM', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    final List<Node> nodeList =
        document.getElementsByTagName('flt-semantics-placeholder');
    expect(nodeList.length, equals(1));
  });

  testWidgets('tap on text field', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.byKey(Key('input')), findsOneWidget);
    await tester.tap(find.byKey(Key('input')));

    final List<Node> nodeList =
    document.getElementsByTagName('input');
    expect(nodeList.length, equals(1));
  });

  // For some reason we need to explicity call complete with flutter for web
  tearDownAll(() {
    binding.allTestsPassed.complete(Future.value(true));
  });
}
