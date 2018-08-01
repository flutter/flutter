// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Nested Localizations', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp( // Creates the outer Localizations widget.
      home: new ListView(
        children: <Widget>[
          const LocalizationTracker(key: const ValueKey<String>('outer')),
          new Localizations(
            locale: const Locale('zh', 'CN'),
            delegates: GlobalMaterialLocalizations.delegates,
            child: const LocalizationTracker(key: const ValueKey<String>('inner')),
          ),
        ],
      ),
    ));

    final LocalizationTrackerState outerTracker = tester.state(find.byKey(const ValueKey<String>('outer'), skipOffstage: false));
    expect(outerTracker.captionFontSize, 12.0);
    final LocalizationTrackerState innerTracker = tester.state(find.byKey(const ValueKey<String>('inner'), skipOffstage: false));
    expect(innerTracker.captionFontSize, 13.0);
  });

  testWidgets('Localizations is compatible with ChangeNotifier.dispose() called during didChangeDependencies', (WidgetTester tester) async {
    // PageView calls ScrollPosition.dispose() during didChangeDependencies.
    await tester.pumpWidget(
      new MaterialApp(
        supportedLocales: const <Locale>[
          const Locale('en', 'US'),
          const Locale('es', 'ES'),
        ],
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          new _DummyLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
        ],
        home: new PageView(),
      )
    );

    await tester.binding.setLocale('es', 'US');
    await tester.pump();
    await tester.pumpWidget(new Container());
  });

  testWidgets('Locale without coutryCode', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/pull/16782
    await tester.pumpWidget(
      new MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[
          const Locale('es', 'ES'),
          const Locale('zh'),
        ],
        home: new Container(),
      )
    );

    await tester.binding.setLocale('zh', null);
    await tester.pump();
    await tester.binding.setLocale('es', 'US');
    await tester.pump();

  });
}

/// A localizations delegate that does not contain any useful data, and is only
/// used to trigger didChangeDependencies upon locale change.
class _DummyLocalizationsDelegate extends LocalizationsDelegate<DummyLocalizations> {
  @override
  Future<DummyLocalizations> load(Locale locale) async => new DummyLocalizations();

  @override
  bool isSupported(Locale locale) => true;

  @override
  bool shouldReload(_DummyLocalizationsDelegate old) => true;
}

class DummyLocalizations {}

class LocalizationTracker extends StatefulWidget {
  const LocalizationTracker({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new LocalizationTrackerState();
}

class LocalizationTrackerState extends State<LocalizationTracker> {
  double captionFontSize;

  @override
  Widget build(BuildContext context) {
    captionFontSize = Theme.of(context).textTheme.caption.fontSize;
    return new Container();
  }
}
