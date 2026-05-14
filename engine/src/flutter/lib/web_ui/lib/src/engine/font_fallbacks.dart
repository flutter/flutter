// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';

abstract class FallbackFontRegistry {
  Future<bool> loadFallbackFont(String familyName, Uint8List bytes);
  void updateFallbackFontFamilies(List<String> families);
}

/// Global static font fallback data.
class FontFallbackManager {
  factory FontFallbackManager(FallbackFontRegistry registry) =>
      FontFallbackManager._(registry, getFallbackFontList());

  FontFallbackManager._(this._registry, this._fallbackFonts);

  final FallbackFontRegistry _registry;

  final List<NotoFont> _fallbackFonts;

  // By default, we use the system language to determine the user's preferred
  // language. This can be overridden through [debugUserPreferredLanguage] for testing.
  String _language = domWindow.navigator.language;

  String get preferredLanguage => _language;

  @visibleForTesting
  set debugUserPreferredLanguage(String value) {
    _language = value;
  }

  @visibleForTesting
  void Function(String family)? debugOnLoadFontFamily;

  final List<String> globalFontFallbacks = <String>['Roboto'];

  void registerFallbackFont(String family) {
    debugOnLoadFontFamily?.call(family);
    // Insert emoji font before all other fallback fonts so we use the emoji
    // whenever it's available.
    if (family.startsWith('Noto Color Emoji') || family == 'Noto Emoji') {
      if (globalFontFallbacks.first == 'Roboto') {
        globalFontFallbacks.insert(1, family);
      } else {
        globalFontFallbacks.insert(0, family);
      }
    } else {
      globalFontFallbacks.add(family);
    }
  }

  void updateFallbackFontFamilies() {
    _registry.updateFallbackFontFamilies(globalFontFallbacks);
  }

  late final List<FallbackFontComponent> fontComponents = _decodeFontComponents(encodedFontSets);

  late final _UnicodePropertyLookup<FallbackFontComponent> codePointToComponents =
      _UnicodePropertyLookup<FallbackFontComponent>.fromPackedData(
        encodedFontSetRanges,
        fontComponents,
      );

  List<FallbackFontComponent> _decodeFontComponents(String data) {
    return <FallbackFontComponent>[
      for (final String componentData in data.split(','))
        FallbackFontComponent(_decodeFontSet(componentData)),
    ];
  }

  List<NotoFont> _decodeFontSet(String data) {
    final result = <NotoFont>[];
    var previousIndex = -1;
    var prefix = 0;
    for (var i = 0; i < data.length; i++) {
      final int code = data.codeUnitAt(i);

      if (kFontIndexDigit0 <= code && code < kFontIndexDigit0 + kFontIndexRadix) {
        final int delta = prefix * kFontIndexRadix + (code - kFontIndexDigit0);
        final int index = previousIndex + delta + 1;
        result.add(_fallbackFonts[index]);
        previousIndex = index;
        prefix = 0;
      } else if (kPrefixDigit0 <= code && code < kPrefixDigit0 + kPrefixRadix) {
        prefix = prefix * kPrefixRadix + (code - kPrefixDigit0);
      } else {
        throw StateError('Unreachable');
      }
    }
    return result;
  }
}

/// A lookup structure from code point to a property type [P].
class _UnicodePropertyLookup<P> {
  _UnicodePropertyLookup._(this._boundaries, this._values);

  factory _UnicodePropertyLookup.fromPackedData(String packedData, List<P> propertyEnumValues) {
    final boundaries = <int>[];
    final values = <P>[];

    var start = 0;
    var prefix = 0;
    var size = 1;

    for (var i = 0; i < packedData.length; i++) {
      final int code = packedData.codeUnitAt(i);
      if (kRangeValueDigit0 <= code && code < kRangeValueDigit0 + kRangeValueRadix) {
        final int index = prefix * kRangeValueRadix + (code - kRangeValueDigit0);
        final P value = propertyEnumValues[index];
        start += size;
        boundaries.add(start);
        values.add(value);
        prefix = 0;
        size = 1;
      } else if (kRangeSizeDigit0 <= code && code < kRangeSizeDigit0 + kRangeSizeRadix) {
        size = prefix * kRangeSizeRadix + (code - kRangeSizeDigit0) + 2;
        prefix = 0;
      } else if (kPrefixDigit0 <= code && code < kPrefixDigit0 + kPrefixRadix) {
        prefix = prefix * kPrefixRadix + (code - kPrefixDigit0);
      } else {
        throw StateError('Unreachable');
      }
    }
    if (start != kMaxCodePoint + 1) {
      throw StateError('Bad map size: $start');
    }

    return _UnicodePropertyLookup<P>._(boundaries, values);
  }

  /// There are two parallel lists - one of boundaries between adjacent unicode
  /// ranges and second of the values for the ranges.
  ///
  /// `_boundaries[i]` is the open-interval end of the `i`th range and the start
  /// of the `i+1`th range. The implicit start of the 0th range is zero.
  ///
  /// `_values[i]` is the value for the range [`_boundaries[i-1]`, `_boundaries[i]`).
  /// Default values are stored as explicit ranges.
  ///
  /// Example: the unicode range properies `[10-50]=>A`, `[100]=>B`, with
  /// default value `X` would be represented as:
  ///
  ///     boundaries:  [10, 51, 100, 101, 1114112]
  ///     values:      [ X,  A,   X,   B,       X]
  ///
  final List<int> _boundaries;
  final List<P> _values;

  int get length => _boundaries.length;

  P lookup(int value) {
    assert(0 <= value && value <= kMaxCodePoint);
    assert(_boundaries.last == kMaxCodePoint + 1);
    int start = 0, end = _boundaries.length;
    while (true) {
      if (start == end) {
        return _values[start];
      }
      final int mid = start + (end - start) ~/ 2;
      if (value >= _boundaries[mid]) {
        start = mid + 1;
      } else {
        end = mid;
      }
    }
  }

  /// Iterate over the ranges, calling [action] with the start and end
  /// (inclusive) code points and value.
  void forEachRange(void Function(int start, int end, P value) action) {
    var start = 0;
    for (var i = 0; i < _boundaries.length; i++) {
      final int end = _boundaries[i];
      final P value = _values[i];
      action(start, end - 1, value);
      start = end;
    }
  }
}
