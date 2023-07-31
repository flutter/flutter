// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for the MessageFormat class.
//
// Currently, these tests are the ones directly ported from Closure.

import 'package:intl/message_format.dart';
import 'package:test/test.dart';

void main() {
  test('testEmptyPattern', () {
    var fmt = MessageFormat('');
    expect(fmt.format({}), '');
  });

  test('testMissingLeftCurlyBrace', () {
    expect(() {
      var fmt = MessageFormat('\'\'{}}');
      fmt.format({});
    }, throwsA(predicate((e) {
      return e is AssertionError && e.message == 'No matching { for }.';
    })));
  });

  test('testTooManyLeftCurlyBraces', () {
    expect(() {
      var fmt = MessageFormat('{} {');
      fmt.format({});
    }, throwsA(predicate((e) {
      return e is AssertionError &&
          e.message == 'There are mismatched { or } in the pattern.';
    })));
  });

  test('testSimpleReplacement', () {
    var fmt = MessageFormat('New York in {SEASON} is nice.');
    expect(fmt.format({'SEASON': 'the Summer'}),
        'New York in the Summer is nice.');
  });

  test('testSimpleSelect', () {
    var fmt = MessageFormat('{GENDER, select,'
        'male {His}'
        'female {Her}'
        'other {Its}}'
        ' bicycle is {GENDER, select, male {blue} female {red} other {green}}.');

    expect(fmt.format({'GENDER': 'male'}), 'His bicycle is blue.');
    expect(fmt.format({'GENDER': 'female'}), 'Her bicycle is red.');
    expect(fmt.format({'GENDER': 'other'}), 'Its bicycle is green.');
    expect(fmt.format({'GENDER': 'whatever'}), 'Its bicycle is green.');
  });

  test('testSimplePlural', () {
    var fmt = MessageFormat('I see {NUM_PEOPLE, plural, offset:1 '
        '=0 {no one at all in {PLACE}.} '
        '=1 {{PERSON} in {PLACE}.} '
        'one {{PERSON} and one other person in {PLACE}.} '
        'other {{PERSON} and # other people in {PLACE}.}}');

    expect(fmt.format({'NUM_PEOPLE': 0, 'PLACE': 'Belgrade'}),
        'I see no one at all in Belgrade.');
    expect(fmt.format({'NUM_PEOPLE': 1, 'PERSON': 'Markus', 'PLACE': 'Berlin'}),
        'I see Markus in Berlin.');
    expect(fmt.format({'NUM_PEOPLE': 2, 'PERSON': 'Mark', 'PLACE': 'Athens'}),
        'I see Mark and one other person in Athens.');
    expect(
        fmt.format({'NUM_PEOPLE': 100, 'PERSON': 'Cibu', 'PLACE': 'the cubes'}),
        'I see Cibu and 99 other people in the cubes.');
  });

  test('testSimplePluralNoOffset', () {
    var fmt = MessageFormat('I see {NUM_PEOPLE, plural, '
        '=0 {no one at all} '
        '=1 {{PERSON}} '
        'one {{PERSON} and one other person} '
        'other {{PERSON} and # other people}} in {PLACE}.');

    expect(fmt.format({'NUM_PEOPLE': 0, 'PLACE': 'Belgrade'}),
        'I see no one at all in Belgrade.');
    expect(fmt.format({'NUM_PEOPLE': 1, 'PERSON': 'Markus', 'PLACE': 'Berlin'}),
        'I see Markus in Berlin.');
    expect(fmt.format({'NUM_PEOPLE': 2, 'PERSON': 'Mark', 'PLACE': 'Athens'}),
        'I see Mark and 2 other people in Athens.');
    expect(
        fmt.format({'NUM_PEOPLE': 100, 'PERSON': 'Cibu', 'PLACE': 'the cubes'}),
        'I see Cibu and 100 other people in the cubes.');
  });

  test('testSelectNestedInPlural', () {
    var fmt = MessageFormat('{CIRCLES, plural, '
        'one {{GENDER, select, '
        '  female {{WHO} added you to her circle} '
        '  other  {{WHO} added you to his circle}}} '
        'other {{GENDER, select, '
        '  female {{WHO} added you to her # circles} '
        '  other  {{WHO} added you to his # circles}}}}');

    expect(fmt.format({'GENDER': 'female', 'WHO': 'Jelena', 'CIRCLES': 1}),
        'Jelena added you to her circle');
    expect(fmt.format({'GENDER': 'male', 'WHO': 'Milan', 'CIRCLES': 1234}),
        'Milan added you to his 1,234 circles');
  });

  test('testPluralNestedInSelect', () {
    // Added offset just for testing purposes. It doesn't make sense
    // to have it otherwise.
    var fmt = MessageFormat('{GENDER, select, '
        'female {{NUM_GROUPS, plural, '
        '  one {{WHO} added you to her group} '
        '  other {{WHO} added you to her # groups}}} '
        'other {{NUM_GROUPS, plural, offset:1'
        '  one {{WHO} added you to his group} '
        '  other {{WHO} added you to his # groups}}}}');

    expect(fmt.format({'GENDER': 'female', 'WHO': 'Jelena', 'NUM_GROUPS': 1}),
        'Jelena added you to her group');
    expect(fmt.format({'GENDER': 'male', 'WHO': 'Milan', 'NUM_GROUPS': 1234}),
        'Milan added you to his 1,233 groups');
  });

  test('testLiteralOpenCurlyBrace', () {
    var fmt = MessageFormat(
        "Anna's house has '{0} and # in the roof' and {NUM_COWS} cows.");
    expect(fmt.format({'NUM_COWS': '5'}),
        "Anna's house has {0} and # in the roof and 5 cows.");
  });

  test('testLiteralClosedCurlyBrace', () {
    var fmt = MessageFormat(
        'Anna\'s house has \'{\'0\'} and # in the roof\' and {NUM_COWS} cows.');
    expect(fmt.format({'NUM_COWS': '5'}),
        'Anna\'s house has {0} and # in the roof and 5 cows.');
    // Regression for Closure implementation bug: b/34764827
    expect(fmt.format({'NUM_COWS': '8'}),
        'Anna\'s house has {0} and # in the roof and 8 cows.');
  });

  test('testLiteralPoundSign', () {
    var fmt = MessageFormat(
        "Anna's house has '{0}' and '# in the roof' and {NUM_COWS} cows.");
    expect(fmt.format({'NUM_COWS': '5'}),
        "Anna's house has {0} and # in the roof and 5 cows.");
    // Regression for: b/34764827
    expect(fmt.format({'NUM_COWS': '10'}),
        'Anna\'s house has {0} and # in the roof and 10 cows.');
  });

  test('testNoLiteralsForSingleQuotes', () {
    var fmt = MessageFormat("Anna's house 'has {NUM_COWS} cows'.");
    expect(fmt.format({'NUM_COWS': '5'}), "Anna's house 'has 5 cows'.");
  });

  test('testConsecutiveSingleQuotesAreReplacedWithOneSingleQuote', () {
    var fmt = MessageFormat("Anna''s house a'{''''b'");
    expect(fmt.format({}), "Anna's house a{''b");
  });

  test('testConsecutiveSingleQuotesBeforeSpecialCharDontCreateLiteral', () {
    var fmt = MessageFormat("a''{NUM_COWS}'b");
    expect(fmt.format({'NUM_COWS': '5'}), "a'5'b");
  });

  test('testSerbianSimpleSelect', () {
    var fmt = MessageFormat(
        '{GENDER, select, female {Njen} other {Njegov}} bicikl je '
        '{GENDER, select, female {crven} other {plav}}.',
        locale: 'sr');

    expect(fmt.format({'GENDER': 'male'}), 'Njegov bicikl je plav.');
    expect(fmt.format({'GENDER': 'female'}), 'Njen bicikl je crven.');
  });

  test('testSerbianSimplePlural', () {
    var fmt = MessageFormat(
        'Ja {NUM_PEOPLE, plural, offset:1 '
        '  =0 {ne vidim nikoga} '
        '  =1 {vidim {PERSON}} '
        '  one {vidim {PERSON} i jos # osobu} '
        '  few {vidim {PERSON} i jos # osobe} '
        '  many {vidim {PERSON} i jos # osoba} '
        '  other {vidim {PERSON} i jos # osoba}} '
        'u {PLACE}.',
        locale: 'sr');

    expect(fmt.format({'NUM_PEOPLE': 0, 'PLACE': 'Beogradu'}),
        'Ja ne vidim nikoga u Beogradu.');
    expect(
        fmt.format({'NUM_PEOPLE': 1, 'PERSON': 'Markusa', 'PLACE': 'Berlinu'}),
        'Ja vidim Markusa u Berlinu.');
    expect(fmt.format({'NUM_PEOPLE': 2, 'PERSON': 'Marka', 'PLACE': 'Atini'}),
        'Ja vidim Marka i jos 1 osobu u Atini.');
    expect(fmt.format({'NUM_PEOPLE': 4, 'PERSON': 'Petra', 'PLACE': 'muzeju'}),
        'Ja vidim Petra i jos 3 osobe u muzeju.');
    expect(
        fmt.format({'NUM_PEOPLE': 100, 'PERSON': 'Cibua', 'PLACE': 'bazenu'}),
        'Ja vidim Cibua i jos 99 osoba u bazenu.');
  });

  test('testSerbianSimplePluralNoOffset', () {
    var fmt = MessageFormat(
        'Ja {NUM_PEOPLE, plural, '
        '  =0 {ne vidim nikoga} '
        '  =1 {vidim {PERSON}} '
        '  one {vidim {PERSON} i jos # osobu} '
        '  few {vidim {PERSON} i jos # osobe} '
        '  many {vidim {PERSON} i jos # osoba} '
        '  other {vidim {PERSON} i jos # osoba}} '
        'u {PLACE}.',
        locale: 'sr');

    expect(fmt.format({'NUM_PEOPLE': 0, 'PLACE': 'Beogradu'}),
        'Ja ne vidim nikoga u Beogradu.');
    expect(
        fmt.format({'NUM_PEOPLE': 1, 'PERSON': 'Markusa', 'PLACE': 'Berlinu'}),
        'Ja vidim Markusa u Berlinu.');
    expect(fmt.format({'NUM_PEOPLE': 21, 'PERSON': 'Marka', 'PLACE': 'Atini'}),
        'Ja vidim Marka i jos 21 osobu u Atini.');
    expect(fmt.format({'NUM_PEOPLE': 3, 'PERSON': 'Petra', 'PLACE': 'muzeju'}),
        'Ja vidim Petra i jos 3 osobe u muzeju.');
    expect(
        fmt.format({'NUM_PEOPLE': 100, 'PERSON': 'Cibua', 'PLACE': 'bazenu'}),
        'Ja vidim Cibua i jos 100 osoba u bazenu.');
  });

  test('testSerbianSelectNestedInPlural', () {
    var fmt = MessageFormat(
        '{CIRCLES, plural, '
        '  one {{GENDER, select, '
        '    female {{WHO} vas je dodala u njen # kruzok} '
        '    other  {{WHO} vas je dodao u njegov # kruzok}}} '
        '  few {{GENDER, select, '
        '    female {{WHO} vas je dodala u njena # kruzoka} '
        '    other  {{WHO} vas je dodao u njegova # kruzoka}}} '
        '  many {{GENDER, select, '
        '    female {{WHO} vas je dodala u njenih # kruzoka} '
        '    other  {{WHO} vas je dodao u njegovih # kruzoka}}} '
        '  other {{GENDER, select, '
        '    female {{WHO} vas je dodala u njenih # kruzoka} '
        '    other  {{WHO} vas je dodao u njegovih # kruzoka}}}}',
        locale: 'hr');

    expect(fmt.format({'GENDER': 'female', 'WHO': 'Jelena', 'CIRCLES': 21}),
        'Jelena vas je dodala u njen 21 kruzok');
    expect(fmt.format({'GENDER': 'female', 'WHO': 'Jelena', 'CIRCLES': 3}),
        'Jelena vas je dodala u njena 3 kruzoka');
    expect(fmt.format({'GENDER': 'female', 'WHO': 'Jelena', 'CIRCLES': 5}),
        'Jelena vas je dodala u njenih 5 kruzoka');
    expect(fmt.format({'GENDER': 'male', 'WHO': 'Milan', 'CIRCLES': 1235}),
        'Milan vas je dodao u njegovih 1.235 kruzoka');
  });

  test('testFallbackToOtherOptionInPlurals', () {
    // Use Arabic plural rules since they have all six cases.
    // Only locale and numbers matter, the actual language of the message
    // does not.
    var fmt =
        MessageFormat('{NUM_MINUTES, plural, other {# minutes}}', locale: 'ar');

    // These numbers exercise all cases for the arabic plural rules.
    expect(fmt.format({'NUM_MINUTES': 0}), '0 minutes');
    expect(fmt.format({'NUM_MINUTES': 1}), '1 minutes');
    expect(fmt.format({'NUM_MINUTES': 2}), '2 minutes');
    expect(fmt.format({'NUM_MINUTES': 3}), '3 minutes');
    expect(fmt.format({'NUM_MINUTES': 11}), '11 minutes');
    expect(fmt.format({'NUM_MINUTES': 1.5}), '1.5 minutes');
  });

  test('testPoundShowsNumberMinusOffsetInAllCases', () {
    var fmt = MessageFormat(
        '{SOME_NUM, plural, offset:1 =0 {#} =1 {#} =2 {#} one {#} other {#}}');

    expect(fmt.format({'SOME_NUM': '0'}), '-1');
    expect(fmt.format({'SOME_NUM': '1'}), '0');
    expect(fmt.format({'SOME_NUM': '2'}), '1');
    expect(fmt.format({'SOME_NUM': '21'}), '20');
  });

  test('testSpecialCharactersInParamaterDontChangeFormat', () {
    var fmt = MessageFormat('{SOME_NUM, plural, other {# {GROUP}}}');

    // Test pound sign.
    expect(fmt.format({'SOME_NUM': '10', 'GROUP': 'group#1'}), '10 group#1');
    // Test other special characters in parameters, like { and }.
    expect(fmt.format({'SOME_NUM': '10', 'GROUP': '} {'}), '10 } {');
  });

  test('testMissingOrInvalidPluralParameter', () {
    var fmt = MessageFormat('{SOME_NUM, plural, other {result}}');

    // Key name doesn't match A != SOME_NUM.
    expect(fmt.format({'A': '10'}), 'Undefined parameter - SOME_NUM');

    // Value is not a number.
    expect(fmt.format({'SOME_NUM': 'Value'}), 'Invalid parameter - SOME_NUM');
  });

  test('testMissingSelectParameter', () {
    var fmt = MessageFormat('{GENDER, select, other {result}}');

    // Key name doesn't match A != GENDER.
    expect(fmt.format({'A': 'female'}), 'Undefined parameter - GENDER');
  });

  test('testMissingSimplePlaceholder', () {
    var fmt = MessageFormat('{result}');

    // Key name doesn't match A != result.
    expect(fmt.format({'A': 'none'}), 'Undefined parameter - result');
  });

  test('testPlural', () {
    var fmt = MessageFormat(
        '{SOME_NUM, plural,'
        '  =0 {none}'
        '  =1 {exactly one}'
        '  one {# one}'
        '  few {# few}'
        '  many {# many}'
        '  other {# other}'
        '}',
        locale: 'ru');

    expect(fmt.format({'SOME_NUM': 0}), 'none');
    expect(fmt.format({'SOME_NUM': 1}), 'exactly one');
    expect(fmt.format({'SOME_NUM': 21}), '21 one');
    expect(fmt.format({'SOME_NUM': 23}), '23 few');
    expect(fmt.format({'SOME_NUM': 17}), '17 many');
    expect(fmt.format({'SOME_NUM': 100}), '100 many');
    expect(fmt.format({'SOME_NUM': 1.4}), '1,4 other');
    expect(fmt.format({'SOME_NUM': '10.0'}), '10 many');
    expect(fmt.format({'SOME_NUM': '100.00'}), '100 many');
  });

  test('testPluralWithIgnorePound', () {
    var fmt = MessageFormat('{SOME_NUM, plural, other {# {GROUP}}}');

    // Test pound sign.
    expect(fmt.formatIgnoringPound({'SOME_NUM': '10', 'GROUP': 'group#1'}),
        '# group#1');
    // Test other special characters in parameters, like { and }.
    expect(
        fmt.formatIgnoringPound({'SOME_NUM': '10', 'GROUP': '} {'}), '# } {');
  });

  test('testSimplePluralWithIgnorePound', () {
    var fmt = MessageFormat('I see {NUM_PEOPLE, plural, offset:1 '
        '=0 {no one at all in {PLACE}.} '
        '=1 {{PERSON} in {PLACE}.} '
        'one {{PERSON} and one other person in {PLACE}.} '
        'other {{PERSON} and # other people in {PLACE}.}}');

    expect(
        fmt.formatIgnoringPound(
            {'NUM_PEOPLE': 100, 'PERSON': 'Cibu', 'PLACE': 'the cubes'}),
        'I see Cibu and # other people in the cubes.');
  });

  test('testRomanianOffsetWithNegativeValue', () {
    var fmt = MessageFormat(
        '{NUM_FLOOR, plural, offset:2 '
        'one {One #}'
        'few {Few #}'
        'other {Other #}}',
        locale: 'ro');

    // Checking that the decision is done after the offset is substracted
    expect(fmt.format({'NUM_FLOOR': -1}), 'Few -3');
    expect(fmt.format({'NUM_FLOOR': 1}), 'One -1');
    expect(fmt.format({'NUM_FLOOR': -3}), 'Few -5');
    expect(fmt.format({'NUM_FLOOR': 3}), 'One 1');
    expect(fmt.format({'NUM_FLOOR': -25}), 'Other -27');
    expect(fmt.format({'NUM_FLOOR': 25}), 'Other 23');
  });

  test('testSimpleOrdinal', () {
    // TOFIX. Ordinal not supported in Dart
    var fmt = MessageFormat('{NUM_FLOOR, selectordinal, '
        'one {Take the elevator to the #st floor.}'
        'two {Take the elevator to the #nd floor.}'
        'few {Take the elevator to the #rd floor.}'
        'other {Take the elevator to the #th floor.}}');

    expect(fmt.format({'NUM_FLOOR': 1}), 'Take the elevator to the 1st floor.');
    expect(fmt.format({'NUM_FLOOR': 2}), 'Take the elevator to the 2nd floor.');
    expect(fmt.format({'NUM_FLOOR': 3}), 'Take the elevator to the 3rd floor.');
    expect(fmt.format({'NUM_FLOOR': 4}), 'Take the elevator to the 4th floor.');
    expect(
        fmt.format({'NUM_FLOOR': 23}), 'Take the elevator to the 23rd floor.');
    // Esoteric example.
    expect(fmt.format({'NUM_FLOOR': 0}), 'Take the elevator to the 0th floor.');
  }, skip: 'Ordinal not supported in Dart');

  test('testOrdinalWithNegativeValue', () {
    // TOFIX. Ordinal not supported in Dart
    var fmt = MessageFormat('{NUM_FLOOR, selectordinal, '
        'one {Take the elevator to the #st floor.}'
        'two {Take the elevator to the #nd floor.}'
        'few {Take the elevator to the #rd floor.}'
        'other {Take the elevator to the #th floor.}}');

    expect(
        fmt.format({'NUM_FLOOR': -1}), 'Take the elevator to the -1st floor.');
    expect(
        fmt.format({'NUM_FLOOR': -2}), 'Take the elevator to the -2nd floor.');
    expect(
        fmt.format({'NUM_FLOOR': -3}), 'Take the elevator to the -3rd floor.');
    expect(
        fmt.format({'NUM_FLOOR': -4}), 'Take the elevator to the -4th floor.');
  }, skip: 'Ordinal not supported in Dart');

  test('testSimpleOrdinalWithIgnorePound', () {
    // TOFIX. Ordinal not supported in Dart
    var fmt = MessageFormat('{NUM_FLOOR, selectordinal, '
        'one {Take the elevator to the #st floor.}'
        'two {Take the elevator to the #nd floor.}'
        'few {Take the elevator to the #rd floor.}'
        'other {Take the elevator to the #th floor.}}');

    expect(fmt.formatIgnoringPound({'NUM_FLOOR': 100}),
        'Take the elevator to the #th floor.');
  });

  test('testMissingOrInvalidOrdinalParameter', () {
    // TOFIX. Ordinal not supported in Dart
    var fmt = MessageFormat('{SOME_NUM, selectordinal, other {result}}');

    // Key name doesn't match A != SOME_NUM.
    expect(
        fmt.format({'A': '10'}), 'Undefined or invalid parameter - SOME_NUM');

    // Value is not a number.
    expect(fmt.format({'SOME_NUM': 'Value'}),
        'Undefined or invalid parameter - SOME_NUM');
  }, skip: 'Ordinal not supported in Dart');
} // end of main
