// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'text_editing.dart';

/// A read-only interface for accessing visual information about the
/// implementing text.
abstract class TextMetrics {
  /// {@template flutter.services.TextMetrics.getLineAtOffset}
  /// Return a [TextSelection] containing the line of the given [TextPosition].
  /// {@endtemplate}
  TextSelection getLineAtOffset(String text, TextPosition position);

  /// {@macro flutter.painting.TextPainter.getWordBoundary}
  TextRange getWordBoundary(TextPosition position);

  /// {@template flutter.services.TextMetrics.getTextPositionAbove}
  /// Returns the TextPosition above the given offset into _plainText.
  ///
  /// If the offset is already on the first line, the given offset will be
  /// returned.
  /// {@endtemplate}
  TextPosition getTextPositionAbove(int offset);

  /// {@template flutter.services.TextMetrics.getTextPositionBelow}
  /// Returns the TextPosition below the given offset into _plainText.
  ///
  /// If the offset is already on the last line, the given offset will be
  /// returned.
  /// {@endtemplate}
  TextPosition getTextPositionBelow(int offset);

  /// {@template flutter.services.TextMetrics.getTextPositionVertical}
  /// Returns the TextPosition above or below the given offset.
  /// {@endtemplate}
  TextPosition getTextPositionVertical(int textOffset, double verticalOffset);
}
