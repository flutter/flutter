// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math' as math;

import 'package:material_color_utilities/hct/hct.dart';

/// A convenience class for retrieving colors that are constant in hue and
/// chroma, but vary in tone.
///
/// This class can be instantiated in two ways:
/// 1. [of] From hue and chroma. (preferred)
/// 2. [fromList] From a fixed-size ([TonalPalette.commonSize]) list of ints
/// representing ARBG colors. Correctness (constant hue and chroma) of the input
/// is not enforced. [get] will only return the input colors, corresponding to
/// [commonTones].
class TonalPalette {
  /// Commonly-used tone values.
  static const List<int> commonTones = [
    0,
    10,
    20,
    30,
    40,
    50,
    60,
    70,
    80,
    90,
    95,
    99,
    100,
  ];

  static final commonSize = commonTones.length;

  final double? _hue;
  final double? _chroma;
  final Map<int, int> _cache;

  TonalPalette._fromHueAndChroma(double hue, double chroma)
      : _cache = {},
        _hue = hue,
        _chroma = chroma;

  TonalPalette._fromCache(Map<int, int> cache)
      : _cache = cache,
        _hue = null,
        _chroma = null;

  /// Create colors using [hue] and [chroma].
  static TonalPalette of(double hue, double chroma) {
    return TonalPalette._fromHueAndChroma(hue, chroma);
  }

  /// Create colors from a fixed-size list of ARGB color ints.
  ///
  /// Inverse of [TonalPalette.asList].
  static TonalPalette fromList(List<int> colors) {
    assert(colors.length == commonSize);
    var cache = <int, int>{};
    commonTones.asMap().forEach(
        (int index, int toneValue) => cache[toneValue] = colors[index]);
    return TonalPalette._fromCache(cache);
  }

  /// Returns a fixed-size list of ARGB color ints for common tone values.
  ///
  /// Inverse of [fromList].
  List<int> get asList => commonTones.map((int tone) => get(tone)).toList();

  /// Returns the ARGB representation of an HCT color.
  ///
  /// If the class was instantiated from [_hue] and [_chroma], will return the
  /// color with corresponding [tone].
  /// If the class was instantiated from a fixed-size list of color ints, [tone]
  /// must be in [commonTones].
  int get(int tone) {
    if (_hue == null || _chroma == null) {
      if (!_cache.containsKey(tone)) {
        throw (ArgumentError.value(
          tone,
          'tone',
          'When a TonalPalette is created with fromList, tone must be one of '
              '$commonTones',
        ));
      } else {
        return _cache[tone]!;
      }
    }
    final chroma = (tone >= 90.0) ? math.min(_chroma!, 40.0) : _chroma!;
    return _cache.putIfAbsent(
        tone, () => Hct.from(_hue!, chroma, tone.toDouble()).toInt());
  }

  @override
  bool operator ==(Object other) {
    if (other is TonalPalette) {
      if (_hue != null && _chroma != null) {
        return _hue == other._hue && _chroma == other._chroma;
      } else {
        return _cache.values.toSet().containsAll(other._cache.values);
      }
    }
    return false;
  }

  @override
  int get hashCode =>
      Object.hash(_hue, _chroma) ^ Object.hashAll(_cache.values);

  @override
  String toString() {
    if (_hue != null && _chroma != null) {
      return 'TonalPalette.of($_hue, $_chroma)';
    } else {
      return 'TonalPalette.fromList($_cache)';
    }
  }
}
