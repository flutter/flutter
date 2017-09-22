// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('$MaterialLocalizations localizes text inside the tree', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      home: new ListView(
        children: <Widget>[
          new LocalizationTracker(key: const ValueKey<String>('outer')),
          new Localizations(
            locale: const Locale('zh', 'CN'),
            delegates: <LocalizationsDelegate<dynamic>>[
              new _MaterialLocalizationsDelegate(
                new DefaultMaterialLocalizations(const Locale('zh', 'CN')),
              ),
              const DefaultWidgetsLocalizationsDelegate(),
            ],
            child: new LocalizationTracker(key: const ValueKey<String>('inner')),
          ),
        ],
      ),
    ));

    final LocalizationTrackerState outerTracker = tester.state(find.byKey(const ValueKey<String>('outer')));
    expect(outerTracker.captionFontSize, 12.0);
    final LocalizationTrackerState innerTracker = tester.state(find.byKey(const ValueKey<String>('inner')));
    expect(innerTracker.captionFontSize, 13.0);
  });
}

class LocalizationTracker extends StatefulWidget {
  LocalizationTracker({Key key}) : super(key: key);

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

// Same as _MaterialLocalizationsDelegate in widgets/app.dart
class _MaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialLocalizationsDelegate(this.localizations);

  final MaterialLocalizations localizations;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return new SynchronousFuture<MaterialLocalizations>(localizations);
  }

  @override
  bool shouldReload(_MaterialLocalizationsDelegate old) => false;
}

// Same as _WidgetsLocalizationsDelegate in widgets/app.dart
class DefaultWidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const DefaultWidgetsLocalizationsDelegate();

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    return new SynchronousFuture<WidgetsLocalizations>(new DefaultWidgetsLocalizations(locale));
  }

  @override
  bool shouldReload(DefaultWidgetsLocalizationsDelegate old) => false;
}
