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

import 'package:material_color_utilities/hct/cam16.dart';
import 'package:material_color_utilities/palettes/tonal_palette.dart';

/// An intermediate concept between the key color for a UI theme, and a full
/// color scheme. 5 tonal palettes are generated, all except one use the same
/// hue as the key color, and all vary in chroma.
class CorePalette {
  /// The number of generated tonal palettes.
  static const size = 5;

  final TonalPalette primary;
  final TonalPalette secondary;
  final TonalPalette tertiary;
  final TonalPalette neutral;
  final TonalPalette neutralVariant;
  final TonalPalette error = TonalPalette.of(25, 84);

  /// Create a [CorePalette] from a source ARGB color.
  static CorePalette of(int argb) {
    final cam = Cam16.fromInt(argb);
    return CorePalette._(cam.hue, cam.chroma);
  }

  CorePalette._(double hue, double chroma)
      : primary = TonalPalette.of(hue, math.max(48, chroma)),
        secondary = TonalPalette.of(hue, 16),
        tertiary = TonalPalette.of(hue + 60, 24),
        neutral = TonalPalette.of(hue, 4),
        neutralVariant = TonalPalette.of(hue, 8);

  /// Create a [CorePalette] from a fixed-size list of ARGB color ints
  /// representing concatenated tonal palettes.
  ///
  /// Inverse of [asList].
  CorePalette.fromList(List<int> colors)
      : assert(colors.length == size * TonalPalette.commonSize),
        primary = TonalPalette.fromList(
            _getPartition(colors, 0, TonalPalette.commonSize)),
        secondary = TonalPalette.fromList(
            _getPartition(colors, 1, TonalPalette.commonSize)),
        tertiary = TonalPalette.fromList(
            _getPartition(colors, 2, TonalPalette.commonSize)),
        neutral = TonalPalette.fromList(
            _getPartition(colors, 3, TonalPalette.commonSize)),
        neutralVariant = TonalPalette.fromList(
            _getPartition(colors, 4, TonalPalette.commonSize));

  /// Returns a list of ARGB color [int]s from concatenated tonal palettes.
  ///
  /// Inverse of [CorePalette.fromList].
  List<int> asList() => [
        ...primary.asList,
        ...secondary.asList,
        ...tertiary.asList,
        ...neutral.asList,
        ...neutralVariant.asList,
      ];

  @override
  bool operator ==(Object other) =>
      other is CorePalette &&
      primary == other.primary &&
      secondary == other.secondary &&
      tertiary == other.tertiary &&
      neutral == other.neutral &&
      neutralVariant == other.neutralVariant &&
      error == other.error;

  @override
  int get hashCode => Object.hash(
        primary,
        secondary,
        tertiary,
        neutral,
        neutralVariant,
        error,
      );

  @override
  String toString() {
    return 'primary: $primary\n'
        'secondary: $secondary\n'
        'tertiary: $tertiary\n'
        'neutral: $neutral\n'
        'neutralVariant: $neutralVariant\n'
        'error: $error\n';
  }
}

// Returns a partition from a list.
//
// For example, given a list with 2 partitions of size 3.
// range = [1, 2, 3, 4, 5, 6];
//
// range.getPartition(0, 3) // [1, 2, 3]
// range.getPartition(1, 3) // [4, 5, 6]
List<int> _getPartition(
    List<int> list, int partitionNumber, int partitionSize) {
  return list.sublist(
    partitionNumber * partitionSize,
    (partitionNumber + 1) * partitionSize,
  );
}
