// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'text_editing.dart';

// TODO(justinmc): Document.
/// A read-only interface for accessing information about some editable text.
abstract class TextMetrics {
  TextSelection getLineAtOffset(String text, TextPosition position);

  TextRange getWordBoundary(TextPosition position);

  /// Returns the TextPosition above the given offset into _plainText.
  ///
  /// If the offset is already on the first line, the given offset will be
  /// returned.
  TextPosition getTextPositionAbove(int offset);

  /// Returns the TextPosition below the given offset into _plainText.
  ///
  /// If the offset is already on the last line, the given offset will be
  /// returned.
  TextPosition getTextPositionBelow(int offset);

  /// Returns the TextPosition above or below the given offset.
  TextPosition getTextPositionVertical(int textOffset, double verticalOffset);
}
