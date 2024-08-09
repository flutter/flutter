// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debugCheckSplash control test', (WidgetTester tester) async {
    await tester.pumpWidget(const Center(child: Chip(label: Text('label'))));
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    final FlutterError error = exception as FlutterError;
    expect(error.diagnostics.length, 5);
    expect(error.diagnostics[2].level, DiagnosticLevel.hint);
    expect(
      error.diagnostics[2].toStringDeep(),
      equalsIgnoringHashCodes(
        'A SplashController can be provided by an ancestor SplashBox;\n'
        'alternatively, there are several viable options from the Material\n'
        'libary, including Material, Card, Dialog, Drawer, and Scaffold.\n',
      ),
    );
    expect(error.diagnostics[3], isA<DiagnosticsProperty<Element>>());
    expect(error.diagnostics[4], isA<DiagnosticsBlock>());
    expect(
      error.toStringDeep(), startsWith(
      'FlutterError\n'
      '   No SplashController found.\n'
      '   Chip widgets use a SplashController to show Splash effects, and\n'
      '   no SplashController ancestor was found within the closest\n'
      '   LookupBoundary.\n'
      '   A SplashController can be provided by an ancestor SplashBox;\n'
      '   alternatively, there are several viable options from the Material\n'
      '   libary, including Material, Card, Dialog, Drawer, and Scaffold.\n'
      '   The specific widget that could not find a SplashController\n'
      '   ancestor was:\n'
      '     Chip\n'
      '   The ancestors of this widget were:\n'
      '     Center\n'
    ));
  });

  testWidgets('debugCheckHasMaterialLocalizations control test', (WidgetTester tester) async {
    await tester.pumpWidget(const Center(child: BackButton()));
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    final FlutterError error = exception as FlutterError;
    expect(error.diagnostics.length, 6);
    expect(error.diagnostics[3].level, DiagnosticLevel.hint);
    expect(
      error.diagnostics[3].toStringDeep(),
      equalsIgnoringHashCodes(
        'To introduce a MaterialLocalizations, either use a MaterialApp at\n'
        'the root of your application to include them automatically, or\n'
        'add a Localization widget with a MaterialLocalizations delegate.\n',
      ),
    );
    expect(error.diagnostics[4], isA<DiagnosticsProperty<Element>>());
    expect(error.diagnostics[5], isA<DiagnosticsBlock>());
    expect(
      error.toStringDeep(), startsWith(
      'FlutterError\n'
      '   No MaterialLocalizations found.\n'
      '   BackButton widgets require MaterialLocalizations to be provided\n'
      '   by a Localizations widget ancestor.\n'
      '   The material library uses Localizations to generate messages,\n'
      '   labels, and abbreviations.\n'
      '   To introduce a MaterialLocalizations, either use a MaterialApp at\n'
      '   the root of your application to include them automatically, or\n'
      '   add a Localization widget with a MaterialLocalizations delegate.\n'
      '   The specific widget that could not find a MaterialLocalizations\n'
      '   ancestor was:\n'
      '     BackButton\n'
      '   The ancestors of this widget were:\n'
      '     Center\n'
      // End of ancestor chain omitted, not relevant for test.
    ));
  });

  testWidgets('debugCheckHasScaffold control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            },
          ),
        ),
        home: Builder(
          builder: (BuildContext context) {
            showBottomSheet(
              context: context,
              builder: (BuildContext context) => Container(),
            );
            return Container();
          },
        ),
      ),
    );
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    final FlutterError error = exception as FlutterError;
    expect(error.diagnostics.length, 5);
    expect(error.diagnostics[2], isA<DiagnosticsProperty<Element>>());
    expect(error.diagnostics[3], isA<DiagnosticsBlock>());
    expect(error.diagnostics[4].level, DiagnosticLevel.hint);
    expect(
      error.diagnostics[4].toStringDeep(),
      equalsIgnoringHashCodes(
        'Typically, the Scaffold widget is introduced by the MaterialApp\n'
        'or WidgetsApp widget at the top of your application widget tree.\n',
      ),
    );
    expect(error.toStringDeep(), startsWith(
      'FlutterError\n'
      '   No Scaffold widget found.\n'
      '   Builder widgets require a Scaffold widget ancestor.\n'
      '   The specific widget that could not find a Scaffold ancestor was:\n'
      '     Builder\n'
      '   The ancestors of this widget were:\n'
      '     Semantics\n'
      '     Builder\n'
    ));
    expect(error.toStringDeep(), endsWith(
      '     [root]\n'
      '   Typically, the Scaffold widget is introduced by the MaterialApp\n'
      '   or WidgetsApp widget at the top of your application widget tree.\n'
    ));
  });

  testWidgets('debugCheckHasScaffoldMessenger control test', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    final SnackBar snackBar = SnackBar(
      content: const Text('Snack'),
      action: SnackBarAction(label: 'Test', onPressed: () {}),
    );
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ScaffoldMessenger(
        key: scaffoldMessengerKey,
        child: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              key: scaffoldKey,
              body: Container(),
            );
          },
        ),
      ),
    ));
    final List<dynamic> exceptions = <dynamic>[];
    final FlutterExceptionHandler? oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      exceptions.add(details.exception);
    };
    // ScaffoldMessenger shows SnackBar.
    scaffoldMessengerKey.currentState!.showSnackBar(snackBar);
    await tester.pumpAndSettle();

    // Pump widget to rebuild without ScaffoldMessenger
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        key: scaffoldKey,
        body: Container(),
      ),
    ));
    // Tap SnackBarAction to dismiss.
    // The SnackBarAction should assert we still have an ancestor
    // ScaffoldMessenger in order to dismiss the SnackBar from the
    // Scaffold.
    await tester.tap(find.text('Test'));
    FlutterError.onError = oldHandler;

    expect(exceptions.length, 1);
    // ignore: avoid_dynamic_calls
    expect(exceptions.single.runtimeType, FlutterError);
    final FlutterError error = exceptions.first as FlutterError;
    expect(error.diagnostics.length, 5);
    expect(error.diagnostics[2], isA<DiagnosticsProperty<Element>>());
    expect(error.diagnostics[3], isA<DiagnosticsBlock>());
    expect(error.diagnostics[4].level, DiagnosticLevel.hint);
    expect(
      error.diagnostics[4].toStringDeep(),
      equalsIgnoringHashCodes(
        'Typically, the ScaffoldMessenger widget is introduced by the\n'
        'MaterialApp at the top of your application widget tree.\n',
      ),
    );
    expect(error.toStringDeep(), startsWith(
      'FlutterError\n'
      '   No ScaffoldMessenger widget found.\n'
      '   SnackBarAction widgets require a ScaffoldMessenger widget\n'
      '   ancestor.\n'
      '   The specific widget that could not find a ScaffoldMessenger\n'
      '   ancestor was:\n'
      '     SnackBarAction\n'
      '   The ancestors of this widget were:\n'
      '     TextButtonTheme\n'
      '     Padding\n'
      '     Row\n'
    ));
    expect(error.toStringDeep(), endsWith(
      '     [root]\n'
      '   Typically, the ScaffoldMessenger widget is introduced by the\n'
      '   MaterialApp at the top of your application widget tree.\n'
    ));
  });
}
