// Copyright 2017 The Chromium Authors. All rights reserved.rint
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class TestLocalizations {
  TestLocalizations(this.locale, this.prefix);

  final Locale locale;
  final String prefix;

  static Future<TestLocalizations> loadSync(Locale locale, String prefix) {
    return new SynchronousFuture<TestLocalizations>(new TestLocalizations(locale, prefix));
  }

  static Future<TestLocalizations> loadAsync(Locale locale, String prefix) {
    return new Future<TestLocalizations>.delayed(const Duration(milliseconds: 100))
      .then((_) => new TestLocalizations(locale, prefix));
  }

  static TestLocalizations of(BuildContext context) {
    return Localizations.of<TestLocalizations>(context, TestLocalizations);
  }

  String get message => '${prefix ?? ""}$locale';
}

class SyncTestLocalizationsDelegate extends LocalizationsDelegate<TestLocalizations> {
  SyncTestLocalizationsDelegate([this.prefix]);

  final String prefix; // Changing this value triggers a rebuild
  final List<bool> shouldReloadValues = <bool>[];

  @override
  Future<TestLocalizations> load(Locale locale) => TestLocalizations.loadSync(locale, prefix);

  @override
  bool shouldReload(SyncTestLocalizationsDelegate old) {
    shouldReloadValues.add(prefix != old.prefix);
    return prefix != old.prefix;
  }
}

class AsyncTestLocalizationsDelegate extends LocalizationsDelegate<TestLocalizations> {
  AsyncTestLocalizationsDelegate([this.prefix]);

  final String prefix; // Changing this value triggers a rebuild
  final List<bool> shouldReloadValues = <bool>[];

  @override
  Future<TestLocalizations> load(Locale locale) => TestLocalizations.loadAsync(locale, prefix);

  @override
  bool shouldReload(AsyncTestLocalizationsDelegate old) {
    shouldReloadValues.add(prefix != old.prefix);
    return prefix != old.prefix;
  }
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

class SyncMoreLocalizationsDelegate extends LocalizationsDelegate<MoreLocalizations> {
  @override
  Future<MoreLocalizations> load(Locale locale) => MoreLocalizations.loadSync(locale);

  @override
  bool shouldReload(SyncMoreLocalizationsDelegate old) => false;
}

class AsyncMoreLocalizationsDelegate extends LocalizationsDelegate<MoreLocalizations> {
  @override
  Future<MoreLocalizations> load(Locale locale) => MoreLocalizations.loadAsync(locale);

  @override
  bool shouldReload(AsyncMoreLocalizationsDelegate old) => false;
}

Widget buildFrame({
  Locale locale,
  Iterable<LocalizationsDelegate<dynamic>> delegates,
  WidgetBuilder buildContent,
}) {
  return new WidgetsApp(
    color: const Color(0xFFFFFFFF),
    locale: locale,
    localizationsDelegates: delegates,
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
    BuildContext pageContext;
    await tester.pumpWidget(
      buildFrame(
        delegates: <LocalizationsDelegate<dynamic>>[
          new SyncTestLocalizationsDelegate()
        ],
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
    await tester.pumpWidget(
      buildFrame(
        delegates: <LocalizationsDelegate<dynamic>>[
          new AsyncTestLocalizationsDelegate(),
        ],
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

  testWidgets('Localizations with multiple sync delegates', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildFrame(
        delegates: <LocalizationsDelegate<dynamic>>[
          new SyncTestLocalizationsDelegate(),
          new SyncMoreLocalizationsDelegate(),
        ],
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

  testWidgets('Localizations with multiple delegates', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildFrame(
        delegates: <LocalizationsDelegate<dynamic>>[
          new SyncTestLocalizationsDelegate(),
          new AsyncMoreLocalizationsDelegate(), // No resources until this completes
        ],
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

  testWidgets('Muliple Localizations', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildFrame(
        delegates: <LocalizationsDelegate<dynamic>>[
          new SyncTestLocalizationsDelegate(),
        ],
        locale: const Locale('en', 'US'),
        buildContent: (BuildContext context) {
          return new Column(
            children: <Widget>[
              new Text('A: ${TestLocalizations.of(context).message}'),
              new Localizations(
                locale: const Locale('en', 'GB'),
                delegates: <LocalizationsDelegate<dynamic>>[
                  new SyncTestLocalizationsDelegate(),
                ],
                // Create a new context within the en_GB Localization
                child: new Builder(
                  builder: (BuildContext context) {
                    return new Text('B: ${TestLocalizations.of(context).message}');
                  },
                ),
              ),
            ],
          );
        }
      )
    );

    expect(find.text('A: en_US'), findsOneWidget);
    expect(find.text('B: en_GB'), findsOneWidget);
  });

  // If both the locale and the length and type of a Localizations delegate list
  // stays the same BUT one of its delegate.shouldReload() methods returns true,
  // then the dependent widgets should rebuild.
  testWidgets('Localizations sync delegate shouldReload returns true', (WidgetTester tester) async {
    final SyncTestLocalizationsDelegate originalDelegate = new SyncTestLocalizationsDelegate();
    await tester.pumpWidget(
      buildFrame(
        delegates: <LocalizationsDelegate<dynamic>>[
          originalDelegate,
          new SyncMoreLocalizationsDelegate(),
        ],
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

    await tester.pumpAndSettle();
    expect(find.text('A: en_US'), findsOneWidget);
    expect(find.text('B: en_US'), findsOneWidget);
    expect(originalDelegate.shouldReloadValues, <bool>[]);


    final SyncTestLocalizationsDelegate modifiedDelegate = new SyncTestLocalizationsDelegate('---');
    await tester.pumpWidget(
      buildFrame(
        delegates: <LocalizationsDelegate<dynamic>>[
          modifiedDelegate,
          new SyncMoreLocalizationsDelegate(),
        ],
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

    await tester.pumpAndSettle();
    expect(find.text('A: ---en_US'), findsOneWidget);
    expect(find.text('B: en_US'), findsOneWidget);
    expect(modifiedDelegate.shouldReloadValues, <bool>[true]);
  });

  testWidgets('Localizations async delegate shouldReload returns true', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildFrame(
        delegates: <LocalizationsDelegate<dynamic>>[
          new AsyncTestLocalizationsDelegate(),
          new AsyncMoreLocalizationsDelegate(),
        ],
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

    await tester.pumpAndSettle();
    expect(find.text('A: en_US'), findsOneWidget);
    expect(find.text('B: en_US'), findsOneWidget);

    final AsyncTestLocalizationsDelegate modifiedDelegate = new AsyncTestLocalizationsDelegate('---');
    await tester.pumpWidget(
      buildFrame(
        delegates: <LocalizationsDelegate<dynamic>>[
          modifiedDelegate,
          new AsyncMoreLocalizationsDelegate(),
        ],
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

    await tester.pumpAndSettle();
    expect(find.text('A: ---en_US'), findsOneWidget);
    expect(find.text('B: en_US'), findsOneWidget);
    expect(modifiedDelegate.shouldReloadValues, <bool>[true]);
  });

}
