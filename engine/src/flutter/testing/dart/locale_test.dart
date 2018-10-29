// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:test/test.dart';

void main() {
  test('Locale', () {
    final Null $null = null;
    expect(const Locale('en').toString(), 'en');
    expect(const Locale('en'), new Locale('en', $null));
    expect(const Locale('en').hashCode, new Locale('en', $null).hashCode);
    expect(const Locale('en', 'US').toString(), 'en_US');
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

    expect(Locale.fromSubtags(languageCode: 'es', countryCode: '419').toString(), 'es_419');
    expect(Locale.fromSubtags(languageCode: 'es', countryCode: '419').languageCode, 'es');
    expect(Locale.fromSubtags(languageCode: 'es', countryCode: '419').countryCode, '419');

    expect(Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN').toString(), 'zh_Hans_CN');
  });

  test('Locale equality', () {
    expect(Locale.fromSubtags(languageCode: 'en'),
           isNot(Locale.fromSubtags(languageCode: 'en', scriptCode: 'Latn')));
    expect(Locale.fromSubtags(languageCode: 'en').hashCode,
           isNot(Locale.fromSubtags(languageCode: 'en', scriptCode: 'Latn').hashCode));
  });
}
