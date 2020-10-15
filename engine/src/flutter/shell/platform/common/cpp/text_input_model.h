// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_CPP_TEXT_INPUT_MODEL_H_
#define FLUTTER_SHELL_PLATFORM_CPP_TEXT_INPUT_MODEL_H_

#include <memory>
#include <string>

#include "flutter/shell/platform/common/cpp/text_range.h"

namespace flutter {

// Handles underlying text input state, using a simple ASCII model.
//
// Ignores special states like "insert mode" for now.
class TextInputModel {
 public:
  TextInputModel();
  virtual ~TextInputModel();

  // Sets the text.
  //
  // Resets the selection base and extent.
  void SetText(const std::string& text);

  // Attempts to set the text selection.
  //
  // Returns false if the selection is not within the bounds of the text.
  bool SetSelection(const TextRange& range);

  // Adds a Unicode code point.
  //
  // Either appends after the cursor (when selection base and extent are the
  // same), or deletes the selected text, replacing it with the given
  // code point.
  void AddCodePoint(char32_t c);

  // Adds UTF-16 text.
  //
  // Either appends after the cursor (when selection base and extent are the
  // same), or deletes the selected text, replacing it with the given text.
  void AddText(const std::u16string& text);

  // Adds UTF-8 text.
  //
  // Either appends after the cursor (when selection base and extent are the
  // same), or deletes the selected text, replacing it with the given text.
  void AddText(const std::string& text);

  // Deletes either the selection, or one character ahead of the cursor.
  //
  // Deleting one character ahead of the cursor occurs when the selection base
  // and extent are the same.
  //
  // Returns true if any deletion actually occurred.
  bool Delete();

  // Deletes text near the cursor.
  //
  // A section is made starting at @offset code points past the cursor (negative
  // values go before the cursor). @count code points are removed. The selection
  // may go outside the bounds of the text and will result in only the part
  // selection that covers the available text being deleted. The existing
  // selection is ignored and removed after this operation.
  //
  // Returns true if any deletion actually occurred.
  bool DeleteSurrounding(int offset_from_cursor, int count);

  // Deletes either the selection, or one character behind the cursor.
  //
  // Deleting one character behind the cursor occurs when the selection base
  // and extent are the same.
  //
  // Returns true if any deletion actually occurred.
  bool Backspace();

  // Attempts to move the cursor backward.
  //
  // Returns true if the cursor could be moved. If a selection is active, moves
  // to the start of the selection.
  bool MoveCursorBack();

  // Attempts to move the cursor forward.
  //
  // Returns true if the cursor could be moved. If a selection is active, moves
  // to the end of the selection.
  bool MoveCursorForward();

  // Attempts to move the cursor to the beginning.
  //
  // Returns true if the cursor could be moved.
  bool MoveCursorToBeginning();

  // Attempts to move the cursor to the back.
  //
  // Returns true if the cursor could be moved.
  bool MoveCursorToEnd();

  // Gets the current text as UTF-8.
  std::string GetText() const;

  // Gets the cursor position as a byte offset in UTF-8 string returned from
  // GetText().
  int GetCursorOffset() const;

  // The current selection.
  TextRange selection() const { return selection_; }

 private:
  // Deletes the current selection, if any.
  //
  // Returns true if any text is deleted. The selection base and extent are
  // reset to the start of the selected range.
  bool DeleteSelected();

  // Returns a range covering the entire text.
  TextRange text_range() const { return TextRange(0, text_.length()); }

  std::u16string text_;
  TextRange selection_ = TextRange(0);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_CPP_TEXT_INPUT_MODEL_H_
