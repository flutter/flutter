// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('Locale', () {
    expect(const Locale('en').toString(), 'en');
    expect(const Locale('en'), const Locale('en'));
    expect(const Locale('en').hashCode, const Locale('en').hashCode);
    expect(const Locale('en'), isNot(const Locale('en', '')));
    // TODO(het): This fails on web because "".hashCode == null.hashCode == 0
    //expect(const Locale('en').hashCode, isNot(const Locale('en', '').hashCode));
    expect(const Locale('en', 'US').toString(), 'en_US');
    expect(const Locale('en', '').toString(), 'en');
    expect(const Locale('iw').toString(), 'he');
    expect(const Locale('iw', 'DD').toString(), 'he_DE');
    expect(const Locale('iw', 'DD'), const Locale('he', 'DE'));
  });

  test('Locale.fromSubtags', () {
    expect(const Locale.fromSubtags().languageCode, 'und');
    expect(const Locale.fromSubtags().scriptCode, null);
    expect(const Locale.fromSubtags().countryCode, null);

    expect(const Locale.fromSubtags(languageCode: 'en').toString(), 'en');
    expect(const Locale.fromSubtags(languageCode: 'en').languageCode, 'en');
    expect(const Locale.fromSubtags(scriptCode: 'Latn').toString(), 'und_Latn');
    expect(const Locale.fromSubtags(scriptCode: 'Latn').scriptCode, 'Latn');
    expect(const Locale.fromSubtags(countryCode: 'US').toString(), 'und_US');
    expect(const Locale.fromSubtags(countryCode: 'US').countryCode, 'US');

    expect(const Locale.fromSubtags(languageCode: 'es', countryCode: '419').toString(), 'es_419');
    expect(const Locale.fromSubtags(languageCode: 'es', countryCode: '419').languageCode, 'es');
    expect(const Locale.fromSubtags(languageCode: 'es', countryCode: '419').countryCode, '419');

    expect(
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'CN',
      ).toString(),
      'zh_Hans_CN',
    );
  });

  test('Locale equality', () {
    expect(
      const Locale.fromSubtags(languageCode: 'en'),
      isNot(const Locale.fromSubtags(languageCode: 'en', scriptCode: 'Latn')),
    );
    expect(
      const Locale.fromSubtags(languageCode: 'en').hashCode,
      isNot(const Locale.fromSubtags(languageCode: 'en', scriptCode: 'Latn').hashCode),
    );
  });

  test('DomLocale', () {
    final locale1 = DomLocale('uk-UA');

    expect(locale1.language, 'uk');
    expect(locale1.script, isNull);
    expect(locale1.region, 'UA');
    expect(locale1.calendar, isNull);
    expect(locale1.caseFirst, isNull);
    expect(locale1.collation, isNull);
    expect(locale1.hourCycle, isNull);
    expect(locale1.numberingSystem, isNull);
    expect(locale1.numeric, false);

    final locale2 = DomLocale('en-Latn-US');

    expect(locale2.language, 'en');
    expect(locale2.script, 'Latn');
    expect(locale2.region, 'US');
    expect(locale2.calendar, isNull);
    expect(locale2.caseFirst, isNull);
    expect(locale2.collation, isNull);
    expect(locale2.hourCycle, isNull);
    expect(locale2.numberingSystem, isNull);
    expect(locale2.numeric, false);

    final locale3 = DomLocale('de-Latn-DE-u-ca-gregory-kf-upper-co-dict-hc-h24-nu-latn-kn-true');

    expect(locale3.language, 'de');
    expect(locale3.script, 'Latn');
    expect(locale3.region, 'DE');
    expect(locale3.calendar, 'gregory');
    expect(locale3.caseFirst, 'upper');
    expect(locale3.collation, 'dict');
    expect(locale3.hourCycle, 'h24');
    expect(locale3.numberingSystem, 'latn');
    expect(locale3.numeric, isTrue);

    final locale4 = DomLocale(
      'th',
      DomLocaleOptions(
        script: 'Thai',
        region: 'TH',
        calendar: 'buddhist',
        caseFirst: 'lower',
        collation: 'dict',
        hourCycle: 'h12',
        numberingSystem: 'thai',
        numeric: true,
      ),
    );

    expect(locale4.language, 'th');
    expect(locale4.script, 'Thai');
    expect(locale4.region, 'TH');
    expect(locale4.calendar, 'buddhist');
    expect(locale4.caseFirst, 'lower');
    expect(locale4.collation, 'dict');
    expect(locale4.hourCycle, 'h12');
    expect(locale4.numberingSystem, 'thai');
    expect(locale4.numeric, true);
  });
}
