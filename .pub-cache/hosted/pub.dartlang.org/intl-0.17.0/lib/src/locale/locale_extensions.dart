// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Locale extensions as defined for [Unicode Locale
/// Identifiers](http://www.unicode.org/reports/tr35/#Unicode_locale_identifier).
///
/// These extensions cover Locale information that aren't captured by the
/// language, script, region and variants subtags of the Unicode Language
/// Identifier. Please see the Unicode Technical Standard linked above.
class LocaleExtensions {
  /// Constructor.
  ///
  /// Keys in each of the maps passed to this contructor must be syntactically
  /// valid extension keys, and must already be normalized (correct case).
  LocaleExtensions(
      Map<String, String>? uExtensions,
      Map<String, String>? tExtensions,
      Map<String, String>? otherExtensions,
      this._xExtensions)
      : _uExtensions = _sortedUnmodifiable(uExtensions),
        _tExtensions = _sortedUnmodifiable(tExtensions),
        _otherExtensions = _sortedUnmodifiable(otherExtensions) {
    // Debug-mode asserts to ensure all parameters are normalized and UTS #35
    // compliant.
    assert(
        uExtensions == null ||
            uExtensions.entries.every((e) {
              if (!_uExtensionsValidKeysRE.hasMatch(e.key)) return false;
              // TODO(hugovdm) reconsider this representation: "true" values are
              // suppressed in canonical Unicode BCP47 Locale Identifiers, but
              // we may choose to represent them as "true" in memory.
              if (e.value == '' && e.key != '') return true;
              if (!_uExtensionsValidValuesRE.hasMatch(e.value)) return false;
              return true;
            }),
        'uExtensions keys must match '
        'RegExp/${_uExtensionsValidKeysRE.pattern}/. '
        'uExtensions values must match '
        'RegExp/${_uExtensionsValidValuesRE.pattern}/. '
        'uExtensions.entries: ${uExtensions.entries}.');
    assert(
        tExtensions == null ||
            tExtensions.entries.every((e) {
              if (!_tExtensionsValidKeysRE.hasMatch(e.key)) return false;
              if (e.key == '') {
                if (!_validTlangRE.hasMatch(e.value)) return false;
              } else {
                if (!_tExtensionsValidValuesRE.hasMatch(e.value)) return false;
              }
              return true;
            }),
        'tExtensions keys must match '
        'RegExp/${_tExtensionsValidKeysRE.pattern}/. '
        'tExtensions values other than tlang must match '
        'RegExp/${_tExtensionsValidValuesRE.pattern}/. '
        'Entries: ${tExtensions.entries}.');
    assert(
        otherExtensions == null ||
            otherExtensions.entries.every((e) {
              if (!_otherExtensionsValidKeysRE.hasMatch(e.key)) return false;
              if (!_otherExtensionsValidValuesRE.hasMatch(e.value)) {
                return false;
              }
              return true;
            }),
        'otherExtensions keys must match '
        'RegExp/${_otherExtensionsValidKeysRE.pattern}. '
        'otherExtensions values must match '
        'RegExp/${_otherExtensionsValidValuesRE.pattern}. '
        'Entries: ${otherExtensions.entries}.');
    assert(
        _xExtensions == null || _validXExtensionsRE.hasMatch(_xExtensions!),
        '_xExtensions must match RegExp/${_validXExtensionsRE.pattern}/ '
        'but is "$_xExtensions".');
  }

  /// For debug/assert-use only! Matches keys considered valid for
  /// [_uExtensions], does not imply keys are valid as per Unicode LDML spec!
  //
  // Must be static to get tree-shaken away in production code.
  static final _uExtensionsValidKeysRE = RegExp(r'^$|^[a-z\d][a-z]$');

  /// For debug/assert-use only! Matches values considered valid for
  /// [_uExtensions], does not imply values are valid as per Unicode LDML spec!
  //
  // Must be static to get tree-shaken away in production code.
  static final _uExtensionsValidValuesRE =
      RegExp(r'^[a-z\d]{3,8}([-][a-z\d]{3,8})*$');

  /// For debug/assert-use only! Matches keys considered valid for
  /// [_tExtensions], does not imply keys are valid as per Unicode LDML spec!
  //
  // Must be static to get tree-shaken away in production code.
  static final _tExtensionsValidKeysRE = RegExp(r'^$|^[a-z]\d$');

  /// For debug/assert-use only! With the exception of `tlang`, matches values
  /// considered valid for [_tExtensions], does not imply values are valid as
  /// per Unicode LDML spec!
  //
  // Must be static to get tree-shaken away in production code.
  static final _tExtensionsValidValuesRE =
      RegExp(r'^[a-z\d]{3,8}([-][a-z\d]{3,8})*$');

  /// For debug/assert-use only! Matches keys considered valid for
  /// [_otherExtensions], does not imply keys are valid as per Unicode LDML
  /// spec!
  //
  // Must be static to get tree-shaken away in production code.
  static final _otherExtensionsValidKeysRE = RegExp(r'^[a-svwyz]$');

  /// For debug/assert-use only! Matches values considered valid for
  /// [_otherExtensions], does not imply values are valid as per Unicode LDML
  /// spec!
  //
  // Must be static to get tree-shaken away in production code.
  static final _otherExtensionsValidValuesRE =
      RegExp(r'^[a-z\d]{2,8}([-][a-z\d]{2,8})*$');

  /// For debug/assert-use only! Matches values valid for [_xExtensions].
  //
  // Must be static to get tree-shaken away in production code.
  static final _validXExtensionsRE =
      RegExp(r'^[a-z\d]{1,8}([-][a-z\d]{1,8})*$');

  /// For debug/assert-use only! Matches values valid for tlang.
  //
  // Must be static to get tree-shaken away in production code.
  static final _validTlangRE = RegExp(
      // Full string match start
      r'^'

      // Language is required in a tlang identifier.
      r'([a-z]{2,3}|[a-z]{5,8})' // Language

      // Optional script
      r'(-[a-z]{4})?'

      // Optional region
      r'(-[a-z]{2}|-\d{3})?'

      // Any number of variant subtags
      r'(-([a-z\d]{5,8}|\d[a-z\d]{3}))*'

      // Full string match end
      r'$');

  /// `-u-` extension, with keys in sorted order. Attributes are stored under
  /// the zero-length string as key. Keywords (consisting of `key` and `type`)
  /// are stored under normalized (lowercased) `key`. See
  /// http://www.unicode.org/reports/tr35/#unicode_locale_extensions for
  /// details.
  final Map<String, String> _uExtensions;

  /// `-t-` extension, with keys in sorted order. tlang attributes are stored
  /// under the zero-length string as key. See
  /// http://www.unicode.org/reports/tr35/#transformed_extensions for
  /// details.
  final Map<String, String> _tExtensions;

  /// Other extensions, with keys in sorted order. See
  /// http://www.unicode.org/reports/tr35/#other_extensions for details.
  final Map<String, String> _otherExtensions;

  /// -x- extension values. See
  /// http://www.unicode.org/reports/tr35/#pu_extensions for details.
  final String? _xExtensions;

  /// List of subtags in the [Unicode Locale
  /// Identifier](https://www.unicode.org/reports/tr35/#Unicode_locale_identifier)
  /// extensions, including private use extensions.
  ///
  /// This covers everything after the unicode_language_id. If there are no
  /// extensions (i.e. the Locale Identifier has only language, script, region
  /// and/or variants), this will be an empty list.
  ///
  /// These subtags are sorted and normalized, ready for joining with a
  /// unicode_language_id and '-' as delimiter to provide a UTS #35 compliant
  /// normalized Locale Identifier.
  List<String> get subtags {
    final result = <String>[];
    final resultVWYZ = <String>[];

    _otherExtensions.forEach((singleton, value) {
      final letter = (singleton.codeUnitAt(0) - 0x61) & 0xFFFF;
      // 't', 'u' and 'x' are handled by other members.
      assert(letter < 26 && letter != 19 && letter != 20 && letter != 23);
      if (letter < 19) {
        result.addAll([singleton, value]);
      } else {
        resultVWYZ.addAll([singleton, value]);
      }
    });
    if (_tExtensions.isNotEmpty) {
      result.add('t');
      _tExtensions.forEach((key, value) {
        if (key != '') result.add(key);
        result.add(value);
      });
    }
    if (_uExtensions.isNotEmpty) {
      result.add('u');
      _uExtensions.forEach((key, value) {
        if (key != '') result.add(key);
        if (value != '') result.add(value);
      });
    }

    if (resultVWYZ.isNotEmpty) {
      result.addAll(resultVWYZ);
    }
    if (_xExtensions != null) {
      result.add('x-$_xExtensions');
    }
    return result;
  }
}

/// Creates an unmodifiable and sorted version of `unsorted`.
Map<String, String> _sortedUnmodifiable(Map<String, String>? unsorted) {
  if (unsorted == null) {
    return const {};
  }
  var map = <String, String>{};
  for (var key in unsorted.keys.toList()..sort()) {
    map[key] = unsorted[key]!;
  }
  return Map.unmodifiable(map);
}
