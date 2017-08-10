// Copyright 2017 The Chromium Authors. All rights reserved.rint
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class TestLocalizations {
  TestLocalizations(this.locale);

  final Locale locale;

  static Future<TestLocalizations> loadSync(Locale locale) {
    return new SynchronousFuture<TestLocalizations>(new TestLocalizations(locale));
  }

  static Future<TestLocalizations> loadAsync(Locale locale) {
    return new Future<TestLocalizations>.delayed(const Duration(milliseconds: 100))
      .then((_) => new TestLocalizations(locale));
  }

  static TestLocalizations of(BuildContext context) {
    return Localizations.of<TestLocalizations>(context, TestLocalizations);
  }

  String get message => '$locale';
}

class MoreLocalizations {
  MoreLocalizations(this.locale);

  final Locale locale;

  static Future<MoreLocalizations> loadSync(Locale locale) {
    return new SynchronousFuture<MoreLocalizations>(new MoreLocalizations(locale));
  }

  static Future<MoreLocalizations> loadAsync(Locale locale) {
    return new Future<MoreLocalizations>.delayed(const Duration(milliseconds: 100))
      .then((_) => new MoreLocalizations(locale));
  }

  static MoreLocalizations of(BuildContext context) {
    return Localizations.of<MoreLocalizations>(context, MoreLocalizations);
  }

  String get message => '$locale';
}

Widget buildFrame({
  Locale locale,
  LocalizationsDelegate delegate,
  WidgetBuilder buildContent,
}) {
  return new WidgetsApp(
    color: const Color(0xFFFFFFFF),
    locale: locale,
    localizationsDelegate: delegate,
    onGenerateRoute: (RouteSettings settings) {
      return new PageRouteBuilder<Null>(
        pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
          return buildContent(context);
        }
      );
    },
  );
}

void main() {
  testWidgets('Localizations.localeFor in a WidgetsApp with system locale', (WidgetTester tester) async {
    BuildContext pageContext;

    await tester.pumpWidget(
      buildFrame(
        buildContent: (BuildContext context) {
          pageContext = context;
          return new Text('Hello World');
        }
      )
    );

    await tester.binding.setLocale('en', 'GB');
    await tester.pump();
    expect(Localizations.localeOf(pageContext), const Locale('en', 'GB'));

    await tester.binding.setLocale('en', 'US');
    await tester.pump();
    expect(Localizations.localeOf(pageContext), const Locale('en', 'US'));
  });

  testWidgets('Localizations.localeFor in a WidgetsApp with an explicit locale', (WidgetTester tester) async {
    final Locale locale = const Locale('en', 'US');
    BuildContext pageContext;

    await tester.pumpWidget(
      buildFrame(
        locale: locale,
        buildContent: (BuildContext context) {
          pageContext = context;
          return new Text('Hello World');
        },
      )
    );

    expect(Localizations.localeOf(pageContext), locale);

    await tester.binding.setLocale('en', 'GB');
    await tester.pump();

    // The WidgetApp's explicit locale overrides the system's locale.
    expect(Localizations.localeOf(pageContext), locale);
  });

  testWidgets('Synchronously loaded localizations in a WidgetsApp', (WidgetTester tester) async {
    final LocalizationsDelegate delegate = new DefaultLocalizationsDelegate(
      <Type, LocalizationsLoader>{
        TestLocalizations: TestLocalizations.loadSync,
      }
    );

    BuildContext pageContext;
    await tester.pumpWidget(
      buildFrame(
        delegate: delegate,
        buildContent: (BuildContext context) {
          pageContext = context;
          return new Text(TestLocalizations.of(context).message);
        }
      )
    );

    expect(TestLocalizations.of(pageContext), isNotNull);
    expect(find.text('_'), findsOneWidget); // default test locale is '_'

    await tester.binding.setLocale('en', 'GB');
    await tester.pump();
    expect(find.text('en_GB'), findsOneWidget);

    await tester.binding.setLocale('en', 'US');
    await tester.pump();
    expect(find.text('en_US'), findsOneWidget);
  });

  testWidgets('Asynchronously loaded localizations in a WidgetsApp', (WidgetTester tester) async {
    final LocalizationsDelegate delegate = new DefaultLocalizationsDelegate(
      <Type, LocalizationsLoader>{
        TestLocalizations: TestLocalizations.loadAsync,
      }
    );

    await tester.pumpWidget(
      buildFrame(
        delegate: delegate,
        buildContent: (BuildContext context) {
          return new Text(TestLocalizations.of(context).message);
        }
      )
    );
    await tester.pump(const Duration(milliseconds: 50)); // TestLocalizations.loadAsync() takes 100ms
    expect(find.text('_'), findsNothing); // TestLocalizations hasn't been loaded yet

    await tester.pump(const Duration(milliseconds: 50)); // TestLocalizations.loadAsync() completes
    await tester.pumpAndSettle();
    expect(find.text('_'), findsOneWidget); // default test locale is '_'

    await tester.binding.setLocale('en', 'US');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('en_US'), findsOneWidget);

    await tester.binding.setLocale('en', 'GB');
    await tester.pump(const Duration(milliseconds: 50));
    // TestLocalizations.loadAsync() hasn't completed yet so the old text
    // localization is still displayed
    expect(find.text('en_US'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 50)); // finish the async load
    await tester.pumpAndSettle();
    expect(find.text('en_GB'), findsOneWidget);
  });

  testWidgets('DefaultLocalizationsDelegate factory', (WidgetTester tester) async {
    final LocalizationsDelegate delegate = new DefaultLocalizationsDelegate(
      <Type, LocalizationsLoader>{
        TestLocalizations: TestLocalizations.loadSync,
        MoreLocalizations: MoreLocalizations.loadAsync, // No resources until this completes
      }
    );

    await tester.pumpWidget(
      buildFrame(
        delegate: delegate,
        locale: const Locale('en', 'US'),
        buildContent: (BuildContext context) {
          return new Column(
            children: <Widget>[
              new Text('A: ${TestLocalizations.of(context).message}'),
              new Text('B: ${MoreLocalizations.of(context).message}'),
            ],
          );
        }
      )
    );

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('A: en_US'), findsNothing); // MoreLocalizations.load() hasn't completed yet
    expect(find.text('B: en_US'), findsNothing);

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text('A: en_US'), findsOneWidget);
    expect(find.text('B: en_US'), findsOneWidget);
  });

  testWidgets('Localizations.merged() factory', (WidgetTester tester) async {
    final LocalizationsDelegate delegateA = new DefaultLocalizationsDelegate(
      <Type, LocalizationsLoader>{
        TestLocalizations: TestLocalizations.loadSync,
      }
    );

    final LocalizationsDelegate delegateB = new DefaultLocalizationsDelegate(
      <Type, LocalizationsLoader>{
        MoreLocalizations: MoreLocalizations.loadSync,
      }
    );

    final LocalizationsDelegate mergedAB = new LocalizationsDelegate.merge(
      <LocalizationsDelegate>[
        delegateA,
        delegateB,
      ]
    );

    await tester.pumpWidget(
      buildFrame(
        delegate: mergedAB,
        locale: const Locale('en', 'US'),
        buildContent: (BuildContext context) {
          return new Column(
            children: <Widget>[
              new Text('A: ${TestLocalizations.of(context).message}'),
              new Text('B: ${MoreLocalizations.of(context).message}'),
            ],
          );
        }
      )
    );

    // All localizations were loaded synchonously
    expect(find.text('A: en_US'), findsOneWidget);
    expect(find.text('B: en_US'), findsOneWidget);
  });
}
