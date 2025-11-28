// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestAutomatedTestWidgetsFlutterBinding();

  testWidgets('English translations exist for all WidgetsLocalizations properties', (
    WidgetTester tester,
  ) async {
    const WidgetsLocalizations localizations = DefaultWidgetsLocalizations();

    expect(localizations.reorderItemUp, isNotNull);
    expect(localizations.reorderItemDown, isNotNull);
    expect(localizations.reorderItemLeft, isNotNull);
    expect(localizations.reorderItemRight, isNotNull);
    expect(localizations.reorderItemToEnd, isNotNull);
    expect(localizations.reorderItemToStart, isNotNull);
    expect(localizations.searchResultsFound, isNotNull);
    expect(localizations.noResultsFound, isNotNull);
    expect(localizations.copyButtonLabel, isNotNull);
    expect(localizations.cutButtonLabel, isNotNull);
    expect(localizations.pasteButtonLabel, isNotNull);
    expect(localizations.selectAllButtonLabel, isNotNull);
    expect(localizations.lookUpButtonLabel, isNotNull);
    expect(localizations.searchWebButtonLabel, isNotNull);
    expect(localizations.shareButtonLabel, isNotNull);
  });

  testWidgets('Locale is available when Localizations widget stops deferring frames', (
    WidgetTester tester,
  ) async {
    final delegate = FakeLocalizationsDelegate();
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('fo'),
        delegates: <LocalizationsDelegate<dynamic>>[WidgetsLocalizationsDelegate(), delegate],
        child: const Text('loaded'),
      ),
    );
    final dynamic state = tester.state(find.byType(Localizations));
    // ignore: avoid_dynamic_calls
    expect(state!.locale, isNull);
    expect(find.text('loaded'), findsNothing);

    late Locale locale;
    binding.onAllowFrame = () {
      // ignore: avoid_dynamic_calls
      locale = state.locale as Locale;
    };
    delegate.completer.complete('foo');
    await tester.idle();
    expect(locale, const Locale('fo'));
    await tester.pump();
    expect(find.text('loaded'), findsOneWidget);
  });

  testWidgets('Locale is sent to engine if this is a top level Localizations', (
    WidgetTester tester,
  ) async {
    final delegate = FakeLocalizationsDelegate();
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('fo'),
        isApplicationLevel: true,
        delegates: <LocalizationsDelegate<dynamic>>[WidgetsLocalizationsDelegate(), delegate],
        child: const Text('loaded'),
      ),
    );
    delegate.completer.complete('foo');
    await tester.idle();
    await tester.pump();
    expect(tester.binding.platformDispatcher.applicationLocale, const Locale('fo'));
  });

  testWidgets('Localizations.localeOf throws when no localizations exist', (
    WidgetTester tester,
  ) async {
    final GlobalKey contextKey = GlobalKey(debugLabel: 'Test Key');
    await tester.pumpWidget(Container(key: contextKey));

    expect(
      () => Localizations.localeOf(contextKey.currentContext!),
      throwsA(
        isAssertionError.having(
          (AssertionError e) => e.message,
          'message',
          contains('does not include a Localizations ancestor'),
        ),
      ),
    );
  });

  testWidgets('Localizations.maybeLocaleOf returns null when no localizations exist', (
    WidgetTester tester,
  ) async {
    final GlobalKey contextKey = GlobalKey(debugLabel: 'Test Key');
    await tester.pumpWidget(Container(key: contextKey));

    expect(Localizations.maybeLocaleOf(contextKey.currentContext!), isNull);
  });

  testWidgets('LocalizationsResolver.update notifies listeners when supportedLocales changes', (
    WidgetTester tester,
  ) async {
    final resolver = LocalizationsResolver(supportedLocales: <Locale>[const Locale('en')]);

    var notified = false;
    resolver.addListener(() {
      notified = true;
    });

    resolver.update(
      locale: null,
      localeListResolutionCallback: null,
      localeResolutionCallback: null,
      localizationsDelegates: null,
      supportedLocales: <Locale>[const Locale('de')],
    );

    expect(notified, isTrue);
    resolver.dispose();
  });

  testWidgets('LocalizationsResolver.update does not notify when resolved locale unchanged', (
    WidgetTester tester,
  ) async {
    final resolver = LocalizationsResolver(
      supportedLocales: <Locale>[const Locale('en'), const Locale('de')],
    );

    var notified = false;
    resolver.addListener(() {
      notified = true;
    });

    // Update with the same effective supportedLocales shouldn't change resolved locale.
    resolver.update(
      locale: null,
      localeListResolutionCallback: null,
      localeResolutionCallback: null,
      localizationsDelegates: null,
      supportedLocales: <Locale>[const Locale('en'), const Locale('de')],
    );

    expect(notified, isFalse);
    resolver.dispose();
  });

  group('Semantics', () {
    testWidgets('set locale semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('fo'),
          delegates: <LocalizationsDelegate<dynamic>>[WidgetsLocalizationsDelegate()],
          child: Semantics(
            container: true,
            label: '1',
            explicitChildNodes: true,
            child: Column(
              children: <Widget>[
                const Text('2'),
                Localizations(
                  locale: const Locale('zh'),
                  delegates: <LocalizationsDelegate<dynamic>>[WidgetsLocalizationsDelegate()],
                  child: const Text('3'),
                ),
              ],
            ),
          ),
        ),
      );
      final SemanticsNode node1 = tester.getSemantics(find.bySemanticsLabel('1'));
      expect(node1.getSemanticsData().locale, const Locale('fo'));

      final SemanticsNode node2 = tester.getSemantics(find.bySemanticsLabel('2'));
      expect(node2.getSemanticsData().locale, const Locale('fo'));

      final SemanticsNode node3 = tester.getSemantics(find.bySemanticsLabel('3'));
      expect(node3.getSemanticsData().locale, const Locale('zh'));
    });

    testWidgets('application level does not set semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('fo'),
          isApplicationLevel: true,
          delegates: <LocalizationsDelegate<dynamic>>[WidgetsLocalizationsDelegate()],
          child: Semantics(
            container: true,
            label: '1',
            explicitChildNodes: true,
            child: const Column(children: <Widget>[Text('2'), Text('3')]),
          ),
        ),
      );
      final SemanticsNode node1 = tester.getSemantics(find.bySemanticsLabel('1'));
      expect(node1.getSemanticsData().locale, isNull);

      final SemanticsNode node2 = tester.getSemantics(find.bySemanticsLabel('2'));
      expect(node2.getSemanticsData().locale, isNull);

      final SemanticsNode node3 = tester.getSemantics(find.bySemanticsLabel('3'));
      expect(node3.getSemanticsData().locale, isNull);
    });
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
  VoidCallback? onAllowFrame;

  @override
  void allowFirstFrame() {
    onAllowFrame?.call();
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
