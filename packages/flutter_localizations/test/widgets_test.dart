// Copyright 2017 The Chromium Authors. All rights reserved.rint
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
  bool isSupported(Locale locale) => true;

  @override
  Future<TestLocalizations> load(Locale locale) => TestLocalizations.loadSync(locale, prefix);

  @override
  bool shouldReload(SyncTestLocalizationsDelegate old) {
    shouldReloadValues.add(prefix != old.prefix);
    return prefix != old.prefix;
  }

  @override
  String toString() => '$runtimeType($prefix)';
}

class AsyncTestLocalizationsDelegate extends LocalizationsDelegate<TestLocalizations> {
  AsyncTestLocalizationsDelegate([this.prefix]);

  final String prefix; // Changing this value triggers a rebuild
  final List<bool> shouldReloadValues = <bool>[];

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<TestLocalizations> load(Locale locale) => TestLocalizations.loadAsync(locale, prefix);

  @override
  bool shouldReload(AsyncTestLocalizationsDelegate old) {
    shouldReloadValues.add(prefix != old.prefix);
    return prefix != old.prefix;
  }

  @override
  String toString() => '$runtimeType($prefix)';
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
  bool isSupported(Locale locale) => true;

  @override
  bool shouldReload(SyncMoreLocalizationsDelegate old) => false;
}

class AsyncMoreLocalizationsDelegate extends LocalizationsDelegate<MoreLocalizations> {
  @override
  Future<MoreLocalizations> load(Locale locale) => MoreLocalizations.loadAsync(locale);

  @override
  bool isSupported(Locale locale) => true;

  @override
  bool shouldReload(AsyncMoreLocalizationsDelegate old) => false;
}

class OnlyRTLDefaultWidgetsLocalizations extends DefaultWidgetsLocalizations {
  @override
  TextDirection get textDirection => TextDirection.rtl;
}

class OnlyRTLDefaultWidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const OnlyRTLDefaultWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    return new SynchronousFuture<WidgetsLocalizations>(new OnlyRTLDefaultWidgetsLocalizations());
  }

  @override
  bool shouldReload(OnlyRTLDefaultWidgetsLocalizationsDelegate old) => false;
}

Widget buildFrame({
  Locale locale,
  Iterable<LocalizationsDelegate<dynamic>> delegates,
  WidgetBuilder buildContent,
  LocaleResolutionCallback localeResolutionCallback,
  List<Locale> supportedLocales: const <Locale>[
    const Locale('en', 'US'),
    const Locale('en', 'GB'),
  ],
}) {
  return new WidgetsApp(
    color: const Color(0xFFFFFFFF),
    locale: locale,
    localizationsDelegates: delegates,
    localeResolutionCallback: localeResolutionCallback,
    supportedLocales: supportedLocales,
    onGenerateRoute: (RouteSettings settings) {
      return new PageRouteBuilder<Null>(
        pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
          return buildContent(context);
        }
      );
    },
  );
}

class SyncLoadTest extends StatefulWidget {
  const SyncLoadTest();

  @override
  SyncLoadTestState createState() => new SyncLoadTestState();
}

class SyncLoadTestState extends State<SyncLoadTest> {
  @override
  Widget build(BuildContext context) {
    return new Text(
      TestLocalizations.of(context).message,
      textDirection: TextDirection.rtl,
    );
  }
}

void main() {
  testWidgets('Localizations.localeFor in a WidgetsApp with system locale', (WidgetTester tester) async {
    BuildContext pageContext;

    await tester.pumpWidget(
      buildFrame(
        buildContent: (BuildContext context) {
          pageContext = context;
          return const Text('Hello World', textDirection: TextDirection.ltr);
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
    const Locale locale = const Locale('en', 'US');
    BuildContext pageContext;

    await tester.pumpWidget(
      buildFrame(
        locale: locale,
        buildContent: (BuildContext context) {
          pageContext = context;
          return const Text('Hello World');
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
    final List<LocalizationsDelegate<dynamic>> delegates = <LocalizationsDelegate<dynamic>>[
      new SyncTestLocalizationsDelegate(),
      DefaultWidgetsLocalizations.delegate,
    ];

    Future<Null> pumpTest(Locale locale) async {
      await tester.pumpWidget(new Localizations(
        locale: locale,
        delegates: delegates,
        child: const SyncLoadTest(),
      ));
    }

    await pumpTest(const Locale('en', 'US'));
    expect(find.text('en_US'), findsOneWidget);

    await pumpTest(const Locale('en', 'GB'));
    await tester.pump();
    expect(find.text('en_GB'), findsOneWidget);

    await pumpTest(const Locale('en', 'US'));
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
    expect(find.text('en_US'), findsNothing); // TestLocalizations hasn't been loaded yet

    await tester.pump(const Duration(milliseconds: 50)); // TestLocalizations.loadAsync() completes
    await tester.pumpAndSettle();
    expect(find.text('en_US'), findsOneWidget); // default test locale is US english

    await tester.binding.setLocale('en', 'GB');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('en_GB'), findsOneWidget);

    await tester.binding.setLocale('en', 'US');
    await tester.pump(const Duration(milliseconds: 50));
    // TestLocalizations.loadAsync() hasn't completed yet so the old text
    // localization is still displayed
    expect(find.text('en_GB'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 50)); // finish the async load
    await tester.pumpAndSettle();
    expect(find.text('en_US'), findsOneWidget);
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

    // All localizations were loaded synchronously
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

  testWidgets('Multiple Localizations', (WidgetTester tester) async {
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
                  DefaultWidgetsLocalizations.delegate,
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
    expect(originalDelegate.shouldReloadValues, <bool>[]);
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

  testWidgets('Directionality tracks system locale', (WidgetTester tester) async {
    BuildContext pageContext;

    await tester.pumpWidget(
      buildFrame(
        delegates: const <LocalizationsDelegate<dynamic>>[
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[
          const Locale('en', 'GB'),
          const Locale('ar', 'EG'),
        ],
        buildContent: (BuildContext context) {
          pageContext = context;
          return const Text('Hello World');
        }
      )
    );

    await tester.binding.setLocale('en', 'GB');
    await tester.pump();
    expect(Directionality.of(pageContext), TextDirection.ltr);

    await tester.binding.setLocale('ar', 'EG');
    await tester.pump();
    expect(Directionality.of(pageContext), TextDirection.rtl);
  });

  testWidgets('localeResolutionCallback override', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildFrame(
        localeResolutionCallback: (Locale newLocale, Iterable<Locale> supportedLocales) {
          return const Locale('foo', 'BAR');
        },
        buildContent: (BuildContext context) {
          return new Text(Localizations.localeOf(context).toString());
        }
      )
    );

    await tester.pumpAndSettle();
    expect(find.text('foo_BAR'), findsOneWidget);

    await tester.binding.setLocale('en', 'GB');
    await tester.pumpAndSettle();
    expect(find.text('foo_BAR'), findsOneWidget);
  });


  testWidgets('supportedLocales and defaultLocaleChangeHandler', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildFrame(
        supportedLocales: const <Locale>[
          const Locale('zh', 'CN'),
          const Locale('en', 'GB'),
          const Locale('en', 'CA'),
        ],
        buildContent: (BuildContext context) {
          return new Text(Localizations.localeOf(context).toString());
        }
      )
    );

    // Startup time. Default test locale is const Locale('', ''), so
    // no supported matches. Use the first locale.
    await tester.pumpAndSettle();
    expect(find.text('zh_CN'), findsOneWidget);

    // defaultLocaleChangedHandler prefers exact supported locale match
    await tester.binding.setLocale('en', 'CA');
    await tester.pumpAndSettle();
    expect(find.text('en_CA'), findsOneWidget);

    // defaultLocaleChangedHandler chooses 1st matching supported locale.languageCode
    await tester.binding.setLocale('en', 'US');
    await tester.pumpAndSettle();
    expect(find.text('en_GB'), findsOneWidget);

    // defaultLocaleChangedHandler: no matching supported locale, so use the 1st one
    await tester.binding.setLocale('da', 'DA');
    await tester.pumpAndSettle();
    expect(find.text('zh_CN'), findsOneWidget);
  });

  testWidgets('Localizations.override widget tracks parent\'s locale and delegates', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildFrame(
        // Accept whatever locale we're given
        localeResolutionCallback: (Locale locale, Iterable<Locale> supportedLocales) => locale,
        delegates: const <LocalizationsDelegate<dynamic>>[
          GlobalWidgetsLocalizations.delegate,
        ],
        buildContent: (BuildContext context) {
          return new Localizations.override(
            context: context,
            child: new Builder(
              builder: (BuildContext context) {
                final Locale locale = Localizations.localeOf(context);
                final TextDirection direction = WidgetsLocalizations.of(context).textDirection;
                return new Text('$locale $direction');
              },
            ),
          );
        }
      )
    );

    // Initial WidgetTester locale is new Locale('', '')
    await tester.pumpAndSettle();
    expect(find.text('_ TextDirection.ltr'), findsOneWidget);

    await tester.binding.setLocale('en', 'CA');
    await tester.pumpAndSettle();
    expect(find.text('en_CA TextDirection.ltr'), findsOneWidget);

    await tester.binding.setLocale('ar', 'EG');
    await tester.pumpAndSettle();
    expect(find.text('ar_EG TextDirection.rtl'), findsOneWidget);

    await tester.binding.setLocale('da', 'DA');
    await tester.pumpAndSettle();
    expect(find.text('da_DA TextDirection.ltr'), findsOneWidget);
  });

  testWidgets('Localizations.override widget overrides parent\'s DefaultWidgetLocalizations', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildFrame(
        // Accept whatever locale we're given
        localeResolutionCallback: (Locale locale, Iterable<Locale> supportedLocales) => locale,
        buildContent: (BuildContext context) {
          return new Localizations.override(
            context: context,
            delegates: const <OnlyRTLDefaultWidgetsLocalizationsDelegate>[
              // Override: no matter what the locale, textDirection is always RTL.
              const OnlyRTLDefaultWidgetsLocalizationsDelegate(),
            ],
            child: new Builder(
              builder: (BuildContext context) {
                final Locale locale = Localizations.localeOf(context);
                final TextDirection direction = WidgetsLocalizations.of(context).textDirection;
                return new Text('$locale $direction');
              },
            ),
          );
        }
      )
    );

    // Initial WidgetTester locale is new Locale('', '')
    await tester.pumpAndSettle();
    expect(find.text('_ TextDirection.rtl'), findsOneWidget);

    await tester.binding.setLocale('en', 'CA');
    await tester.pumpAndSettle();
    expect(find.text('en_CA TextDirection.rtl'), findsOneWidget);

    await tester.binding.setLocale('ar', 'EG');
    await tester.pumpAndSettle();
    expect(find.text('ar_EG TextDirection.rtl'), findsOneWidget);

    await tester.binding.setLocale('da', 'DA');
    await tester.pumpAndSettle();
    expect(find.text('da_DA TextDirection.rtl'), findsOneWidget);
  });

  testWidgets('WidgetsApp overrides DefaultWidgetLocalizations', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildFrame(
        // Accept whatever locale we're given
        localeResolutionCallback: (Locale locale, Iterable<Locale> supportedLocales) => locale,
        delegates: <OnlyRTLDefaultWidgetsLocalizationsDelegate>[
          const OnlyRTLDefaultWidgetsLocalizationsDelegate(),
        ],
        buildContent: (BuildContext context) {
          final Locale locale = Localizations.localeOf(context);
          final TextDirection direction = WidgetsLocalizations.of(context).textDirection;
          return new Text('$locale $direction');
        }
      )
    );

    // Initial WidgetTester locale is new Locale('', '')
    await tester.pumpAndSettle();
    expect(find.text('_ TextDirection.rtl'), findsOneWidget);

    await tester.binding.setLocale('en', 'CA');
    await tester.pumpAndSettle();
    expect(find.text('en_CA TextDirection.rtl'), findsOneWidget);

    await tester.binding.setLocale('ar', 'EG');
    await tester.pumpAndSettle();
    expect(find.text('ar_EG TextDirection.rtl'), findsOneWidget);

    await tester.binding.setLocale('da', 'DA');
    await tester.pumpAndSettle();
    expect(find.text('da_DA TextDirection.rtl'), findsOneWidget);
  });

}
