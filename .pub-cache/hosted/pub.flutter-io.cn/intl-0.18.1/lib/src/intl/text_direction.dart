// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

/// Represents directionality of text.
///
/// In most cases, it is preferable to use bidi_formatter.dart, which provides
/// bidi functionality in the given directional context, instead of using
/// bidi_utils.dart directly.
class TextDirection {
  static const LTR = TextDirection._('LTR', 'ltr');
  static const RTL = TextDirection._('RTL', 'rtl');
  // If the directionality of the text cannot be determined and we are not using
  // the context direction (or if the context direction is unknown), then the
  // text falls back on the more common ltr direction.
  static const UNKNOWN = TextDirection._('UNKNOWN', 'ltr');

  /// Textual representation of the directionality constant. One of
  /// 'LTR', 'RTL', or 'UNKNOWN'.
  final String value;

  /// Textual representation of the directionality when used in span tag.
  final String spanText;

  const TextDirection._(this.value, this.spanText);

  /// Returns true if [otherDirection] is known to be different from this
  /// direction.
  bool isDirectionChange(TextDirection otherDirection) =>
      otherDirection != TextDirection.UNKNOWN && this != otherDirection;
}
