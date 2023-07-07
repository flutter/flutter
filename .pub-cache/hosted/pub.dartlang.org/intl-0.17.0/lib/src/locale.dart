// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'locale/locale_implementation.dart';
import 'locale/locale_parser.dart' show LocaleParser;

/// A representation of a [Unicode Locale
/// Identifier](https://www.unicode.org/reports/tr35/#Unicode_locale_identifier).
///
/// To create Locale instances, consider using:
/// * [fromSubtags] for language, script and region,
/// * [parse] for Unicode Locale Identifier strings (throws exceptions on
///   failure),
/// * [tryParse] for Unicode Locale Identifier strings (returns null on
///   failure).
abstract class Locale {
  /// Constructs a Locale instance that consists of only language, script and
  /// region subtags.
  ///
  /// Throws a [FormatException] if any subtag is syntactically invalid.
  static Locale fromSubtags(
          {required String languageCode,
          String? scriptCode,
          String? countryCode}) =>
      LocaleImplementation.fromSubtags(
          languageCode: languageCode,
          scriptCode: scriptCode,
          countryCode: countryCode);

  /// Parses [Unicode Locale Identifiers][localeIds] to produce [Locale]
  /// instances.
  ///
  /// [localeIds]:
  /// https://www.unicode.org/reports/tr35/#Unicode_locale_identifier
  ///
  /// Throws a [FormatException] if [localeIdentifier] is syntactically invalid.
  static Locale parse(String localeIdentifier) {
    ArgumentError.checkNotNull(localeIdentifier);
    var parser = LocaleParser(localeIdentifier);
    var locale = parser.toLocale();
    if (locale == null) {
      throw FormatException('Locale "$localeIdentifier": '
          '${parser.problems.join("; ")}.');
    }
    return locale;
  }

  /// Parses [Unicode Locale Identifiers][localeIds] to produce [Locale]
  /// instances.
  ///
  /// [localeIds]:
  /// https://www.unicode.org/reports/tr35/#Unicode_locale_identifier
  ///
  /// Returns `null` if [localeIdentifier] is syntactically invalid.
  static Locale? tryParse(String localeIdentifier) {
    ArgumentError.checkNotNull(localeIdentifier);
    var parser = LocaleParser(localeIdentifier);
    return parser.toLocale();
  }

  /// The language subtag of the Locale Identifier.
  ///
  /// It is syntactically valid, normalized (has correct case) and canonical
  /// (deprecated tags have been replaced), but not necessarily valid (the
  /// language might not exist) because the list of valid languages changes with
  /// time.
  String get languageCode;

  /// The script subtag of the Locale Identifier, null if absent.
  ///
  /// It is syntactically valid and normalized (has correct case), but not
  /// necessarily valid (the script might not exist) because the list of valid
  /// scripts changes with time.
  String? get scriptCode;

  /// The region subtag of the Locale Identifier, null if absent.
  ///
  /// It is syntactically valid, normalized (has correct case) and canonical
  /// (deprecated tags have been replaced), but not necessarily valid (the
  /// region might not exist) because the list of valid regions changes with
  /// time.
  String? get countryCode;

  /// Iterable of variant subtags.
  ///
  /// They are syntactically valid, normalized (have correct case) and sorted
  /// alphabetically, but not necessarily valid (variants might not exist)
  /// because the list of variants changes with time.
  Iterable<String> get variants;

  /// Returns the canonical [Unicode BCP47 Locale
  /// Identifier](http://www.unicode.org/reports/tr35/#BCP_47_Conformance) for
  /// this locale.
  String toLanguageTag();

  /// Returns the canonical [Unicode BCP47 Locale
  /// Identifier](http://www.unicode.org/reports/tr35/#BCP_47_Conformance) for
  /// this locale.
  @override
  String toString() => toLanguageTag();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Locale && toLanguageTag() == other.toLanguageTag();
  }

  @override
  int get hashCode {
    return toLanguageTag().hashCode;
  }
}
