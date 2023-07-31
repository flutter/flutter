// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:intl/src/locale.dart' show Locale;

import 'locale_deprecations.dart';
import 'locale_extensions.dart';

/// The primary implementation of the Locale interface.
class LocaleImplementation extends Locale {
  /// Simple private constructor with asserts to check invariants.
  LocaleImplementation._(this.languageCode, this.scriptCode, this.countryCode,
      this.variants, this._extensions) {
    ArgumentError.notNull(languageCode);
    // Debug-mode asserts to ensure all parameters are normalized and UTS #35
    // compliant.
    assert(
        _normalizedLanguageRE.hasMatch(languageCode),
        'languageCode must match RegExp/${_normalizedLanguageRE.pattern}/ '
        'but is "$languageCode".');
    assert(
        scriptCode == null || _normalizedScriptRE.hasMatch(scriptCode!),
        'scriptCode must match RegExp/${_normalizedScriptRE.pattern}/ '
        'but is "$scriptCode".');
    assert(
        countryCode == null || _normalizedRegionRE.hasMatch(countryCode!),
        'countryCode must match RegExp/${_normalizedRegionRE.pattern}/ '
        'but is "$countryCode".');
    assert(
        variants is List<String> &&
            variants.every(_normalizedVariantRE.hasMatch),
        'each variant must match RegExp/${_normalizedVariantRE.pattern}/ '
        'but variants are "$variants".');
  }

  /// For debug/assert-use only! Matches subtags considered valid for
  /// [languageCode], does not imply subtag is valid as per Unicode LDML spec!
  //
  // Must be static to get tree-shaken away in production code.
  static final _normalizedLanguageRE = RegExp(r'^[a-z]{2,3}$|^[a-z]{5,8}$');

  /// For debug/assert-use only! Matches subtags considered valid for
  /// [scriptCode], does not imply subtag is valid as per Unicode LDML spec!
  //
  // Must be static to get tree-shaken away in production code.
  static final _normalizedScriptRE = RegExp(r'^[A-Z][a-z]{3}$');

  /// For debug/assert-use only! Matches subtags considered valid for
  /// [countryCode], does not imply subtags are valid as per Unicode LDML spec!
  //
  // Must be static to get tree-shaken away in production code.
  static final _normalizedRegionRE = RegExp(r'^[A-Z]{2}$|^\d{3}$');

  /// For debug/assert-use only! Matches subtags considered valid for
  /// [variants], does not imply subtags are valid as per Unicode LDML spec!
  //
  // Must be static to get tree-shaken away in production code.
  static final _normalizedVariantRE = RegExp(r'^[a-z\d]{5,8}$|^\d[a-z\d]{3}$');

  /// Simple factory which assumes parameters are syntactically correct.
  ///
  /// In debug mode, incorrect use may result in an assertion failure. (In
  /// production code, this class makes no promises regarding the consequence of
  /// incorrect use.)
  ///
  /// For public APIs, see [Locale.fromSubtags] and [Locale.parse].
  factory LocaleImplementation.unsafe(
    String languageCode, {
    String? scriptCode,
    String? countryCode,
    Iterable<String>? variants,
    LocaleExtensions? extensions,
  }) {
    variants = (variants != null && variants.isNotEmpty)
        ? List.unmodifiable(variants.toList()..sort())
        : const [];
    return LocaleImplementation._(
        languageCode, scriptCode, countryCode, variants, extensions);
  }

  /// Constructs a Locale instance that consists of only language, region and
  /// country subtags.
  ///
  /// Throws a [FormatException] if any subtag is syntactically invalid.
  static LocaleImplementation fromSubtags(
      {required String languageCode, String? scriptCode, String? countryCode}) {
    return LocaleImplementation._(
        replaceDeprecatedLanguageSubtag(_normalizeLanguageCode(languageCode)),
        scriptCode == null ? null : _normalizeScriptCode(scriptCode),
        countryCode == null
            ? null
            : replaceDeprecatedRegionSubtag(_normalizeCountryCode(countryCode)),
        const [],
        null);
  }

  /// Performs case normalization on `languageCode`.
  ///
  /// Throws a [FormatException] if it is syntactically invalid.
  static String _normalizeLanguageCode(String languageCode) {
    if (!_languageRexExp.hasMatch(languageCode)) {
      throw FormatException('Invalid language "$languageCode"');
    }
    return languageCode.toLowerCase();
  }

  static final _languageRexExp = RegExp(r'^[a-zA-Z]{2,3}$|^[a-zA-Z]{5,8}$');

  /// Performs case normalization on `scriptCode`.
  ///
  /// Throws a [FormatException] if it is syntactically invalid.
  static String _normalizeScriptCode(String scriptCode) {
    if (!_scriptRegExp.hasMatch(scriptCode)) {
      throw FormatException('Invalid script "$scriptCode"');
    }
    return toCapCase(scriptCode);
  }

  static final _scriptRegExp = RegExp(r'^[a-zA-Z]{4}$');

  /// Performs case normalization on `countryCode`.
  ///
  /// Throws a [FormatException] if it is syntactically invalid.
  static String _normalizeCountryCode(String countryCode) {
    if (!_regionRegExp.hasMatch(countryCode)) {
      throw FormatException('Invalid region "$countryCode"');
    }
    return countryCode.toUpperCase();
  }

  static final _regionRegExp = RegExp(r'^[a-zA-Z]{2}$|^\d{3}$');

  /// The language subtag of the Locale Identifier.
  ///
  /// It is syntactically valid, normalized (has correct case) and canonical
  /// (deprecated tags have been replaced), but not necessarily valid (the
  /// language might not exist) because the list of valid languages changes with
  /// time.
  final String languageCode;

  /// The script subtag of the Locale Identifier, null if absent.
  ///
  /// It is syntactically valid, normalized (has correct case) and canonical
  /// (deprecated tags have been replaced), but not necessarily valid (the
  /// script might not exist) because the list of valid scripts changes with
  /// time.
  final String? scriptCode;

  /// The region subtag of the Locale Identifier, null if absent.
  ///
  /// It is syntactically valid, normalized (has correct case) and canonical
  /// (deprecated tags have been replaced), but not necessarily valid (the
  /// region might not exist) because the list of valid regions changes with
  /// time.
  final String? countryCode;

  /// Iterable of variant subtags, zero-length iterable if variants are absent.
  ///
  /// They are syntactically valid, normalized (have correct case) and canonical
  /// (sorted alphabetically and deprecated tags have been replaced) but not
  /// necessarily valid (variants might not exist) because the list of variants
  /// changes with time.
  final Iterable<String> variants;

  /// Locale extensions, null if the locale has no extensions.
  // TODO(hugovdm): Not yet supported: getters for extensions.
  final LocaleExtensions? _extensions;

  /// Cache of the value returned by [toLanguageTag].
  String? _languageTag;

  /// Returns the canonical Unicode BCP47 Locale Identifier for this locale.
  String toLanguageTag() {
    if (_languageTag == null) {
      final out = [languageCode];
      if (scriptCode != null) out.add(scriptCode!);
      if (countryCode != null) out.add(countryCode!);
      out.addAll(variants);
      if (_extensions != null) out.addAll(_extensions!.subtags);
      _languageTag = out.join('-');
    }
    return _languageTag!;
  }
}

/// Returns `input` with first letter capitalized and the rest lowercase.
String toCapCase(String input) =>
    '${input[0].toUpperCase()}${input.substring(1).toLowerCase()}';
