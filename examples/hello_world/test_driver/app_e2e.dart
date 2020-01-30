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

  // failing tests always halt. Not even timeout.
  // testWidgets('fail finding widget', (WidgetTester tester) async {
  //   expect(2 + 2, test.equals(5));
  // });

  testWidgets('test finding widget', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();


    expect(find.text('Hello, world!'), findsNothing);
    expect(find.text('You have pushed the button this many times:'), findsOneWidget);

    expect(find.byKey(Key('input')), findsOneWidget);

    await tester.tap(find.byKey(Key('input')));
    await tester.pumpAndSettle();

    final List<Node> nodeList = document.getElementsByTagName('flt-semantics-placeholder');
    expect(nodeList.length, equals(1));
  });

  // For some reason we need to explicity call complete with flutter for web
  tearDownAll(() {
    binding.allTestsPassed.complete(Future.value(true));
  });
}
