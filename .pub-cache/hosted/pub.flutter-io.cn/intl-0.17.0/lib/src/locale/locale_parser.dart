// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'locale_deprecations.dart';
import 'locale_extensions.dart';
import 'locale_implementation.dart';

/// A parser for [Unicode Locale
/// Identifiers](https://www.unicode.org/reports/tr35/#Unicode_locale_identifier).
class LocaleParser {
  /// Language subtag of Unicode Language Identifier.
  String _languageCode = 'und';

  /// Script subtag of Unicode Language Identifier.
  String? _scriptCode;

  /// Region subtag of Unicode Language Identifier.
  String? _countryCode;

  /// Variant subtags of Unicode Language Identifier.
  List<String>? _variants;

  /// Unicode Locale Extensions, also known as "U Extension".
  Map<String, String>? _uExtensions;

  /// Transformed Extensions, also known as "T Extension".
  Map<String, String>? _tExtensions;

  /// Private-Use Extensions.
  String? _xExtensions;

  /// Other Extensions.
  Map<String, String>? _otherExtensions;

  /// List of problems with the localeId the parser tried to parse.
  ///
  /// An empty list indicates problem-free parsing.
  final List<String> problems = <String>[];

  /// Produces a Locale instance for the parser's current state.
  ///
  /// Returns null if the Locale would be syntactically invalid.
  LocaleImplementation? toLocale() {
    if (problems.isNotEmpty) return null;
    LocaleExtensions? extensions;
    if (_uExtensions != null ||
        _tExtensions != null ||
        _otherExtensions != null ||
        _xExtensions != null) {
      extensions = LocaleExtensions(
          _uExtensions, _tExtensions, _otherExtensions, _xExtensions);
    }
    return LocaleImplementation.unsafe(
      _languageCode,
      scriptCode: _scriptCode,
      countryCode: _countryCode,
      variants: _variants,
      extensions: extensions,
    );
  }

  /// Subtags of the Locale Identifier, as split by [separators].
  late List<String> _subtags;

  /// RegExp that matches Unicode Locale Identifier subtag separators.
  static final separators = RegExp('[-_]');

  /// Last accepted subtag.
  String _accepted = '';

  /// Last accepted list of subtags (for variants).
  List<String>? _acceptedList;

  /// Current subtag pending acceptance.
  String _current = '';

  /// Index of the current subtag.
  int _currentIndex = 0;

  /// Advance to the next subtag (see [current] and [accepted]).
  void advance() {
    _accepted = _current;
    _currentIndex++;
    if (_currentIndex < _subtags.length) {
      _current = _subtags[_currentIndex];
    } else {
      // Guarded by `atEnd`.
    }
  }

  /// Returns true if all subtags have been parsed.
  bool atEnd() {
    return _currentIndex >= _subtags.length;
  }

  /// Parses [Unicode CLDR Locale
  /// Identifiers](https://www.unicode.org/reports/tr35/#Identifiers).
  ///
  /// This method does not parse all BCP 47 tags. See [BCP 47
  /// Conformance](https://www.unicode.org/reports/tr35/#BCP_47_Conformance) for
  /// details.
  ///
  /// localeId may not be null.
  ///
  /// Parsing failed if there are any entries in [problems].
  LocaleParser(String localeId) {
    ArgumentError.notNull(localeId);

    // Calling toLowerCase unconditionally should be efficient if
    // string_patch.dart is in use:
    // https://github.com/dart-lang/sdk/blob/cabaa78cc57d08bcfcd75bfe99a42c19ed497d26/runtime/lib/string_patch.dart#L1178
    localeId = localeId.toLowerCase();
    if (localeId == 'root') {
      return;
    }

    _subtags = localeId.split(separators);
    _current = _subtags[0];

    var scriptFound = false;
    if (acceptLanguage()) {
      _languageCode = replaceDeprecatedLanguageSubtag(_accepted);
      scriptFound = acceptScript();
    } else {
      scriptFound = acceptScript();
      if (!scriptFound) {
        problems.add('bad language/script');
      }
    }
    if (scriptFound) {
      _scriptCode = toCapCase(_accepted);
    }
    if (acceptRegion()) {
      _countryCode = replaceDeprecatedRegionSubtag(_accepted.toUpperCase());
    }
    acceptVariants();
    _variants = _acceptedList;

    processExtensions();

    if (!atEnd()) {
      problems.add('bad subtag "$_current"');
    }
  }

  /// Consumes all remaining subtags, if syntactically valid.
  ///
  /// If parsing fails, `atEnd()` will be false and/or [problems] will not be
  /// empty.
  void processExtensions() {
    while (acceptSingleton()) {
      var singleton = _accepted;
      if (singleton == 'u') {
        processUExtensions();
      } else if (singleton == 't') {
        processTExtensions();
      } else if (singleton == 'x') {
        processPrivateUseExtensions();
        break;
      } else {
        processOtherExtensions(singleton);
      }
    }
  }

  /// Consumes tags matched by `unicode_locale_extensions` in the specification,
  /// except that the 'u' singleton must already be accepted.
  ///
  /// If parsing fails, `atEnd()` will be false and/or [problems] will not be
  /// empty.
  void processUExtensions() {
    if (_uExtensions != null) {
      problems.add('duplicate "u"');
      return;
    }
    _uExtensions = <String, String>{};
    var empty = true;
    final attributes = <String>[];
    while (acceptLowAlphaNumeric3to8()) {
      attributes.add(_accepted);
    }
    if (attributes.isNotEmpty) {
      empty = false;
      attributes.sort();
      _uExtensions![''] = attributes.join('-');
    }
    // unicode_locale_extensions: collect "(sep keyword)*".
    while (acceptUExtensionKey()) {
      empty = false;
      var key = _accepted;
      final typeParts = <String>[];
      while (acceptLowAlphaNumeric3to8()) {
        typeParts.add(_accepted);
      }
      if (!_uExtensions!.containsKey(key)) {
        if (typeParts.length == 1 && typeParts[0] == 'true') {
          _uExtensions![key] = '';
        } else {
          _uExtensions![key] = typeParts.join('-');
        }
      } else {
        problems.add('duplicate "$key"');
      }
    }
    if (empty) {
      problems.add('empty "u"');
    }
  }

  /// Consumes tags matched by `transformed_extensions` in the specification,
  /// except that the 't' singleton must already be accepted.
  ///
  /// If parsing fails, `atEnd()` will be false and/or [problems] will not be
  /// empty.
  void processTExtensions() {
    if (_tExtensions != null) {
      problems.add('duplicate "t"');
      return;
    }
    _tExtensions = <String, String>{};
    var empty = true;
    final tlang = <String>[];
    if (acceptLanguage()) {
      empty = false;
      tlang.add(replaceDeprecatedLanguageSubtag(_accepted));
      if (acceptScript()) {
        tlang.add(_accepted);
      }
      if (acceptRegion()) {
        tlang.add(replaceDeprecatedRegionSubtag(_accepted.toUpperCase())
            .toLowerCase());
      }
      acceptVariants();
      tlang.addAll(_acceptedList!);
      _tExtensions![''] = tlang.join('-');
    }
    // transformed_extensions: collect "(sep tfield)*".
    while (acceptTExtensionKey()) {
      var tkey = _accepted;
      final tvalueParts = <String>[];
      while (acceptLowAlphaNumeric3to8()) {
        tvalueParts.add(_accepted);
      }
      if (tvalueParts.isNotEmpty) {
        empty = false;
        if (!_tExtensions!.containsKey(tkey)) {
          _tExtensions![tkey] = tvalueParts.join('-');
        } else {
          problems.add('duplicate "$tkey"');
        }
      } else {
        problems.add('empty "$tkey"');
      }
    }
    if (empty) {
      problems.add('empty "t"');
    }
  }

  /// Consumes tags matched by `pu_extensions` in the specification, except that
  /// the 'x' singleton must already be accepted.
  ///
  /// If parsing fails, `atEnd()` will be false and/or [problems] will not be
  /// empty.
  void processPrivateUseExtensions() {
    final values = <String>[];
    while (acceptLowAlphaNumeric1to8()) {
      values.add(_accepted);
    }
    if (values.isNotEmpty) {
      _xExtensions = values.join('-');
    }
  }

  /// Consumes tags matched by `other_extensions` in the specification, except
  /// that the singleton in question must already be accepted and passed as
  /// parameter.
  ///
  /// If parsing fails, `atEnd()` will be false and/or [problems] will not be
  /// empty.
  void processOtherExtensions(String singleton) {
    final values = <String>[];
    while (acceptLowAlphaNumeric2to8()) {
      values.add(_accepted);
    }
    if (values.isEmpty) return;
    if (_otherExtensions == null) {
      _otherExtensions = <String, String>{};
    } else if (_otherExtensions!.containsKey(singleton)) {
      problems.add('duplicate "$singleton"');
      return;
    }
    _otherExtensions![singleton] = values.join('-');
  }

  /// Advances and returns true if current subtag is a language subtag.
  bool acceptLanguage() {
    if (atEnd()) return false;
    if (!_languageRegExp.hasMatch(_current)) return false;
    advance();
    return true;
  }

  static final _languageRegExp = RegExp(r'^[a-z]{2,3}$|^[a-z]{5,8}$');

  /// Advances and returns true if current subtag is a script subtag.
  bool acceptScript() {
    if (atEnd()) return false;
    if (!_scriptRegExp.hasMatch(_current)) return false;
    advance();
    return true;
  }

  static final _scriptRegExp = RegExp(r'^[a-z]{4}$');

  /// Advances and returns true if current subtag is a region subtag.
  bool acceptRegion() {
    if (atEnd()) return false;
    if (!_regionRegExp.hasMatch(_current)) return false;
    advance();
    return true;
  }

  static final _regionRegExp = RegExp(r'^[a-z]{2}$|^\d{3}$');

  /// Advances, collecting subtags in [_acceptedList], as long as the current
  /// subtag is a variant subtag.
  ///
  /// Does not return a boolean: when done, _acceptedList will contain the
  /// collected subtags.
  void acceptVariants() {
    _acceptedList = [];
    while (!atEnd() && _variantRegExp.hasMatch(_current)) {
      _acceptedList!.add(_current);
      advance();
    }
  }

  static final _variantRegExp = RegExp(r'^[a-z\d]{5,8}$|^\d[a-z\d]{3}$');

  /// Advances and returns true if current subtag is a singleton.
  bool acceptSingleton() {
    if (atEnd()) return false;
    if (!_singletonRegExp.hasMatch(_current)) return false;
    advance();
    return true;
  }

  static final _singletonRegExp = RegExp(r'^[a-z]$');

  /// Advances and returns true if current subtag is alphanumeric, with length
  /// ranging from 1 to 8.
  bool acceptLowAlphaNumeric1to8() {
    if (atEnd()) return false;
    if (!_alphaNumeric1to8RegExp.hasMatch(_current)) return false;
    advance();
    return true;
  }

  static final _alphaNumeric1to8RegExp = RegExp(r'^[a-z\d]{1,8}$');

  /// Advances and returns true if current subtag is alphanumeric, with length
  /// ranging from 2 to 8.
  bool acceptLowAlphaNumeric2to8() {
    if (atEnd()) return false;
    if (!_alphaNumeric1to8RegExp.hasMatch(_current) || _current.length < 2) {
      return false;
    }
    advance();
    return true;
  }

  /// Advances and returns true if current subtag is alphanumeric, with length
  /// ranging from 3 to 8.
  bool acceptLowAlphaNumeric3to8() {
    if (atEnd()) return false;
    if (!_alphaNumeric1to8RegExp.hasMatch(_current) || _current.length < 3) {
      return false;
    }
    advance();
    return true;
  }

  /// Advances and returns true if current subtag is a valid U Extension key.
  bool acceptUExtensionKey() {
    if (atEnd()) return false;
    if (!_uExtensionKeyRegExp.hasMatch(_current)) return false;
    advance();
    return true;
  }

  static final _uExtensionKeyRegExp = RegExp(r'^[a-z\d][a-z]$');

  /// Advances and returns true if current subtag is a valid T Extension key
  /// (`tkey` in the specification).
  bool acceptTExtensionKey() {
    if (atEnd()) return false;
    if (!_tExtensionKeyRegExp.hasMatch(_current)) return false;
    advance();
    return true;
  }

  static final _tExtensionKeyRegExp = RegExp(r'^[a-z]\d$');
}
