// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

Color? tryParseColor(String? input) {
  if (input == null) return null;

  try {
    return parseCssHexColor(input);
  } catch (e) {
    return null;
  }
}

/// Parses a 3 or 6 digit CSS Hex Color into a dart:ui Color.
Color parseCssHexColor(String input) {
  // Remove any leading # (and the escaped version to be lenient)
  input = input.replaceAll('#', '').replaceAll('%23', '');

  // Handle 3/4-digit hex codes (eg. #123 == #112233)
  if (input.length == 3 || input.length == 4) {
    input = input.split('').map((c) => '$c$c').join();
  }

  // Pad alpha with FF.
  if (input.length == 6) {
    input = '${input}ff';
  }

  // In CSS, alpha is in the lowest bits, but for Flutter's value, it's in the
  // highest bits, so move the alpha from the end to the start before parsing.
  if (input.length == 8) {
    input = '${input.substring(6)}${input.substring(0, 6)}';
  }
  final value = int.parse(input, radix: 16);

  return Color(value);
}

/// Utility extension methods to the [Color] class.
extension ColorExtension on Color {
  /// Return a slightly darker color than the current color.
  Color darken([double percent = 0.05]) {
    assert(0.0 <= percent && percent <= 1.0);
    percent = 1.0 - percent;

    final c = this;
    return Color.from(
      alpha: c.a,
      red: c.r * percent,
      green: c.g * percent,
      blue: c.b * percent,
    );
  }

  /// Return a slightly brighter color than the current color.
  Color brighten([double percent = 0.05]) {
    assert(0.0 <= percent && percent <= 1.0);

    final c = this;
    return Color.from(
      alpha: c.a,
      red: c.r + ((1.0 - c.r) * percent),
      green: c.g + ((1.0 - c.g) * percent),
      blue: c.b + ((1.0 - c.b) * percent),
    );
  }
}
