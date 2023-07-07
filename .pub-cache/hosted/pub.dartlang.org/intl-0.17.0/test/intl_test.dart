// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library intl_test;

import 'package:intl/intl.dart';
import 'package:test/test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  test("Locale setting doesn't verify the core locale", () {
    var de = Intl('de_DE');
    expect(de.locale, equals('de_DE'));
  });

  test('DateFormat creation does verify the locale', () {
    // TODO(alanknight): We need to make the locale verification be on a per
    // usage basis rather than once for the entire Intl object. The set of
    // locales covered for messages may be different from that for date
    // formatting.
    initializeDateFormatting('de_DE', null).then((_) {
      var de = Intl('de_DE');
      var format = de.date().add_d();
      expect(format.locale, equals('de'));
    });
  });

  test('Canonicalizing locales', () {
    expect(Intl.canonicalizedLocale('en-us'), 'en_US');
    expect(Intl.canonicalizedLocale('en_us'), 'en_US');
    expect(Intl.canonicalizedLocale('en_US'), 'en_US');
    expect(Intl.canonicalizedLocale('xx-yyy'), 'xx_YYY');
    expect(Intl.canonicalizedLocale('xx_YYY'), 'xx_YYY');
    expect(Intl.canonicalizedLocale('C'), 'en_ISO');
  });

  test('Verifying locale fallback for numbers', () {
    expect(Intl.verifiedLocale('en-us', NumberFormat.localeExists), 'en_US');
    expect(Intl.verifiedLocale('en_us', NumberFormat.localeExists), 'en_US');
    expect(Intl.verifiedLocale('es-419', NumberFormat.localeExists), 'es_419');
    expect(Intl.verifiedLocale('en-ZZ', NumberFormat.localeExists), 'en');
    expect(Intl.verifiedLocale('es-999', NumberFormat.localeExists), 'es');

    void checkAsNumberDefault(String locale, String expected) {
      var oldDefault = Intl.defaultLocale;
      Intl.defaultLocale = locale;
      var format = NumberFormat();
      expect(format.locale, expected);
      Intl.defaultLocale = oldDefault;
    }

    checkAsNumberDefault('en-us', 'en_US');
    checkAsNumberDefault('en_us', 'en_US');
    checkAsNumberDefault('es-419', 'es_419');
    checkAsNumberDefault('en-ZZ', 'en');
    checkAsNumberDefault('es-999', 'es');
  });

  test('Verifying locale fallback for dates', () {
    expect(Intl.verifiedLocale('en-us', DateFormat.localeExists), 'en_US');
    expect(Intl.verifiedLocale('en_us', DateFormat.localeExists), 'en_US');
    expect(Intl.verifiedLocale('es-419', DateFormat.localeExists), 'es_419');
    expect(Intl.verifiedLocale('en-ZZ', DateFormat.localeExists), 'en');
    expect(Intl.verifiedLocale('es-999', DateFormat.localeExists), 'es');

    void checkAsDateDefault(String locale, String expected) {
      var oldDefault = Intl.defaultLocale;
      Intl.defaultLocale = locale;
      var format = DateFormat();
      expect(format.locale, expected);
      Intl.defaultLocale = oldDefault;
    }

    checkAsDateDefault('en-us', 'en_US');
    checkAsDateDefault('en_us', 'en_US');
    checkAsDateDefault('es-419', 'es_419');
    checkAsDateDefault('en-ZZ', 'en');
    checkAsDateDefault('es-999', 'es');
  });

  test('toBeginningOfSentenceCase', () {
    expect(toBeginningOfSentenceCase(null), null);
    expect(toBeginningOfSentenceCase(''), '');
    expect(toBeginningOfSentenceCase('A'), 'A');
    expect(toBeginningOfSentenceCase('a'), 'A');
    expect(toBeginningOfSentenceCase('abc'), 'Abc');
    expect(toBeginningOfSentenceCase('[a]'), '[a]');
    expect(toBeginningOfSentenceCase('ABc'), 'ABc');
    expect(toBeginningOfSentenceCase('ı'), 'I');
    expect(toBeginningOfSentenceCase('i'), 'I');
    expect(toBeginningOfSentenceCase('i', 'tr'), '\u0130');
  });
}
