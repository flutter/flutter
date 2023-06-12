// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests for the Locale class.
///
/// Currently, the primary intention of these tests is to exercise and
/// demonstrate the API: full test coverage is a non-goal for the prototype.
///
/// For production code, use of ICU would influence what needs and doesn't need
/// to be tested.

import 'package:test/test.dart';
import 'package:intl/locale.dart';

import 'locale_test_data.dart';

void main() {
  group('Construction and properties:', () {
    // Simple with normalization:
    testFromSubtags('Zh', null, null, 'zh', null, null, 'zh');
    testFromSubtags('zH', null, 'cn', 'zh', null, 'CN', 'zh-CN');
    testFromSubtags('ZH', null, 'Cn', 'zh', null, 'CN', 'zh-CN');
    testFromSubtags('zh', null, 'cN', 'zh', null, 'CN', 'zh-CN');
    testFromSubtags('zh', 'hans', null, 'zh', 'Hans', null, 'zh-Hans');
    testFromSubtags('ZH', 'HANS', 'CN', 'zh', 'Hans', 'CN', 'zh-Hans-CN');

    // Region codes can be three digits.
    testFromSubtags('es', null, '419', 'es', null, '419', 'es-419');

    // While language is usually 2 characters, it can also be 3.
    testFromSubtags('CKB', 'arab', null, 'ckb', 'Arab', null, 'ckb-Arab');

    // With canonicalization:
    testFromSubtags('Iw', null, null, 'he', null, null, 'he');
    testFromSubtags('iW', null, null, 'he', null, null, 'he');
    testFromSubtags('My', null, 'Bu', 'my', null, 'MM', 'my-MM');
  });

  group('Locale.fromSubtags() FormatExceptions:', () {
    void testExceptionForSubtags(
        String language, String? script, String? region) {
      test('fromSubtags: "$language / $script / $region"', () {
        expect(
            () => Locale.fromSubtags(
                languageCode: language,
                scriptCode: script,
                countryCode: region),
            throwsFormatException);
      });
    }

    testExceptionForSubtags('a', null, null);
    testExceptionForSubtags('en', 'ZA', null);
    testExceptionForSubtags('en', null, 'Latn');
  });

  group('Locale normalization matching ICU.', () {
    localeParsingTestData.forEach((unnormalized, normalized) {
      test('Locale normalization: $unnormalized -> $normalized', () {
        expect(Locale.parse(unnormalized).toLanguageTag(), normalized);
      });
    });
  });

  group('Unicode LDML Locale Identifier support', () {
    // 'root' is a valid Unicode Locale Identifier, but should be taken as
    // 'und'[1]. ICU's toLanguageTag still returns 'root'.
    // [1]:
    // http://unicode.org/reports/tr35/#Unicode_Locale_Identifier_CLDR_to_BCP_47
    testParse('root', 'und', null, null, [], 'und');
    testParse('Root', 'und', null, null, [], 'und');
    testParse('ROOT', 'und', null, null, [], 'und');

    // We support underscores, whereas ICU's `forLanguageTag` does
    // not.
    testParse('CKB_arab', 'ckb', 'Arab', null, [], 'ckb-Arab');
    testParse('My_Bu', 'my', null, 'MM', [], 'my-MM');

    // Normalises tags, sorts subtags alphabetically, including variants[1]:
    // ICU is currently not sorting variants.
    // [1]: http://unicode.org/reports/tr35/#Unicode_locale_identifier
    testParse('en-scouse-fonipa', 'en', null, null, ['fonipa', 'scouse'],
        'en-fonipa-scouse');

    // Normalises tags, sorts subtags alphabetically and suppresses unneeded
    // "true" in u extension (ICU is currently not dropping -true):
    // http://unicode.org/reports/tr35/#u_Extension
    testParse('en-u-Foo-bar-nu-thai-ca-buddhist-kk-true', 'en', null, null, [],
        'en-u-bar-foo-ca-buddhist-kk-nu-thai');

    // The specification does permit empty extensions for extensions other than
    // u- and t-.
    testParse('en-a', 'en', null, null, [], 'en');
    testParse('en-x', 'en', null, null, [], 'en');
    testParse('en-z', 'en', null, null, [], 'en');

    // Normalization of `tlang` - ICU still returns -t-iw-bu.
    testParse('en-t-iw-Bu', 'en', null, null, [], 'en-t-he-mm');

    test('en-u-ca is equivalent to en-u-ca-true', () {
      expect(Locale.parse('en-u-ca').toLanguageTag(),
          Locale.parse('en-u-ca-true').toLanguageTag());
    });
  });

  // Normalization: sorting of extension subtags:
  testParse('en-z-abc-001-foo-fii-bar-u-cu-usd-co-phonebk', 'en', null, null,
      [], 'en-u-co-phonebk-cu-usd-z-abc-001-foo-fii-bar');

  group('Locale.parse() throws FormatException:', () {
    void testExceptionForId(String x) {
      test('"$x"', () {
        expect(() => Locale.parse(x), throwsFormatException);
      });
    }

    for (var badLocaleIdentifier in invalidLocales) {
      testExceptionForId(badLocaleIdentifier);
    }

    // ICU permits '', taking it as 'und', but it is not a valid Unicode Locale
    // Identifier: We reject it.
    testExceptionForId('');

    // abcd-Latn throws exceptions in our Dart implementation, whereas
    // ECMAScript's Intl.Locale permits it. This is because the BCP47 spec
    // still allows for the possible addition of 4-character languages in
    // the future, whereas the Unicode Locale Identifiers spec bans it
    // outright.
    testExceptionForId('abcd-Latn');

    // ICU permits 'root-Latn' since it conforms to pure BCP47, but it is an
    // invalid Unicode BCP47 Locale Identifier.
    testExceptionForId('root-Latn');

    // ICU permits empty tkeys.
    testExceptionForId('en-t-a0');

    // ICU permits duplicate tkeys, returning the content of -t- verbatim.
    testExceptionForId('en-t-a0-one-a0-two');

    // ICU permits duplicate keys, in this case dropping -ca-buddhist.
    testExceptionForId('en-u-ca-islamic-ca-buddhist');
  });

  group('Locale.tryParse() returns null:', () {
    for (var badLocaleIdentifier in invalidLocales) {
      test('"$badLocaleIdentifier"', () {
        expect(Locale.tryParse(badLocaleIdentifier), isNull);
      });
    }
  });

  // TODO: determine appropriate behaviour for the following examples.

  // // 'mo' is deprecated, and is a tag that ought to be replaced by *two*
  // // subtags (ro-MD), although Chrome Unstable also doesn't presently do
  // // that (replaces it by 'ro' only).
  // // TODO: check up on the Chrome implementation.
  // testParse('mo', 'ro', null, 'MD', [], 'ro-MD');

  // // Script deprecation.
  // testParse('en-Qaai', 'en', 'Zinh', null, [], 'en-Zinh');

  // // Variant deprecation.
  // testParse('sv-aaland', 'sv', null, 'AX', [], 'sv-AX');

  // // Variant deprecation.
  // testParse('en-heploc', 'en', null, null, ['alalc97'], 'en-alalc97');

  // // Variant deprecation.
  // testParse('en-polytoni', 'en', null, null, ['polyton'], 'en-polyton');

  test('Locale cannot be modified via the variants field', () {
    var l = Locale.parse('en-scotland');
    var v = l.variants as List<String>;
    var good = false;
    try {
      v.add('basiceng');
    } on Error {
      good = true;
    }
    expect(l.toLanguageTag(), 'en-scotland');
    expect(good, isTrue);
  });

  test('operator== and hashCode', () {
    Locale l1, l2;

    l1 = Locale.parse('en-Shaw-ZA');
    l2 = Locale.fromSubtags(
        languageCode: 'en', scriptCode: 'Shaw', countryCode: 'ZA');
    expect(l1, l2);
    expect(l1.hashCode, l2.hashCode);

    l1 = Locale.parse('en');
    l2 = Locale.fromSubtags(
        languageCode: 'en', scriptCode: null, countryCode: null);
    expect(l1, l2);
    expect(l1.hashCode, l2.hashCode);
  });
}

void testFromSubtags(
    String language,
    String? script,
    String? region,
    String? expectedLanguage,
    String? expectedScript,
    String? expectedRegion,
    String? expectedTag) {
  test('Locale.fromSubtags(...) with $language, $script, $region', () {
    var l = Locale.fromSubtags(
        languageCode: language, scriptCode: script, countryCode: region);
    expect(l.languageCode, expectedLanguage);
    expect(l.scriptCode, expectedScript);
    expect(l.countryCode, expectedRegion);
    expect(l.toLanguageTag(), expectedTag);
    expect(l.toString(), expectedTag);
  });
}

void testParse(
    String bcp47Tag,
    String expectedLanguage,
    String? expectedScript,
    String? expectedRegion,
    Iterable<String> expectedVariants,
    String? expectedTag) {
  test('Locale.parse("$bcp47Tag");', () {
    var l = Locale.parse(bcp47Tag);
    expect(l.languageCode, expectedLanguage);
    expect(l.scriptCode, expectedScript);
    expect(l.countryCode, expectedRegion);
    expect(l.toLanguageTag(), expectedTag);
    expect(l.variants, orderedEquals(expectedVariants));
  });
}
