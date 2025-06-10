// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/widget_previews.dart';

PreviewLocalizationsData myLocalizations() {
  return PreviewLocalizationsData(
    locale: Locale('en'),
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [
      Locale('en'), // English
      Locale('es'), // Spanish
    ],
    localeListResolutionCallback:
        (List<Locale>? locales, Iterable<Locale> supportedLocales) => null,
    localeResolutionCallback:
        (Locale? locale, Iterable<Locale> supportedLocales) => null,
  );
}

void main() {
  runApp(
    const DecoratedBox(
      decoration: BoxDecoration(color: Colors.white),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.ltr,
          children: <Widget>[
            FlutterLogo(size: 48),
            Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'This app is only meant to be run under the Flutter debugger',
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
