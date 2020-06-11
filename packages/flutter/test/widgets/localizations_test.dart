// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  final TestAutomatedTestWidgetsFlutterBinding binding = TestAutomatedTestWidgetsFlutterBinding();

  testWidgets('Locale is available when Localizations widget stops deferring frames', (WidgetTester tester) async {
    final FakeLocalizationsDelegate delegate = FakeLocalizationsDelegate();
    await tester.pumpWidget(Localizations(
      locale: const Locale('fo'),
      delegates: <LocalizationsDelegate<dynamic>>[
        WidgetsLocalizationsDelegate(),
        delegate,
      ],
      child: const Text('loaded')
    ));
    final dynamic state = tester.state(find.byType(Localizations));
    expect(state.locale, isNull);
    expect(find.text('loaded'), findsNothing);

    Locale locale;
    binding.onAllowFrame = () {
      locale = state.locale as Locale;
    };
    delegate.completer.complete('foo');
    await tester.idle();
    expect(locale, const Locale('fo'));
    await tester.pump();
    expect(find.text('loaded'), findsOneWidget);
  });
}

class FakeLocalizationsDelegate extends LocalizationsDelegate<String> {
  final Completer<String> completer = Completer<String>();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<String> load(Locale locale) => completer.future;

  @override
  bool shouldReload(LocalizationsDelegate<String> old) => false;
}

class TestAutomatedTestWidgetsFlutterBinding extends AutomatedTestWidgetsFlutterBinding {

  VoidCallback onAllowFrame;

  @override
  void allowFirstFrame() {
    if (onAllowFrame != null)
      onAllowFrame();
    super.allowFirstFrame();
  }
}

class WidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) => DefaultWidgetsLocalizations.load(locale);

  @override
  bool shouldReload(WidgetsLocalizationsDelegate old) => false;
}
