// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildFrame({
  Locale locale,
  WidgetBuilder buildContent,
}) {
  return new MaterialApp(
    color: const Color(0xFFFFFFFF),
    locale: locale,
    onGenerateRoute: (RouteSettings settings) {
      return new MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return buildContent(context);
        }
      );
    },
  );
}

void main() {
  testWidgets('sanity check', (WidgetTester tester) async {
    final Key textKey = new UniqueKey();

    await tester.pumpWidget(
      buildFrame(
        buildContent: (BuildContext context) {
          return new Text(
            MaterialLocalizations.of(context).backButtonTooltip,
            key: textKey,
          );
        }
      )
    );

    expect(tester.widget<Text>(find.byKey(textKey)).data, 'Back');

    // Spanish Bolivia locale, falls back to just 'es'
    await tester.binding.setLocale('es', 'bo');
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(textKey)).data, 'Espalda');

    // Unrecognized locale falls back to 'en'
    await tester.binding.setLocale('foo', 'bar');
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(textKey)).data, 'Back');
  });

  testWidgets('translations exist for all materia/i18n languages', (WidgetTester tester) async {
    final List<String> languages = <String>[
      'ar', // Arabic
      'de', // German
      'en', // English
      'es', // Spanish
      'fa', // Farsi (Persian)
      'fr', // French
      'he', // Hebrew
      'it', // Italian
      'ja', // Japanese
      'ps', // Pashto
      'pt', // Portugese
      'ru', // Russian
      'sd', // Sindhi
      'ur', // Urdu
      'zh', // Chinese (simplified)
    ];

    for (String language in languages) {
      final Locale locale = new Locale(language, '');
      final MaterialLocalizations localizations = new DefaultMaterialLocalizations(locale);
      expect(localizations.openAppDrawerTooltip, isNotNull);
      expect(localizations.backButtonTooltip, isNotNull);
      expect(localizations.closeButtonTooltip, isNotNull);
      expect(localizations.nextMonthTooltip, isNotNull);
      expect(localizations.previousMonthTooltip, isNotNull);
      expect(localizations.licensesPageTitle, isNotNull);
      expect(localizations.cancelButtonLabel, isNotNull);
      expect(localizations.closeButtonLabel, isNotNull);
      expect(localizations.continueButtonLabel, isNotNull);
      expect(localizations.copyButtonLabel, isNotNull);
      expect(localizations.cutButtonLabel, isNotNull);
      expect(localizations.okButtonLabel, isNotNull);
      expect(localizations.pasteButtonLabel, isNotNull);
      expect(localizations.selectAllButtonLabel, isNotNull);
      expect(localizations.viewLicensesButtonLabel, isNotNull);
    }
  });
}
