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
  // While in composing mode, the selection is restricted to the composing
  // range; otherwise, it is restricted to the length of the text.
  bool SetSelection(const TextRange& range);

  // Attempts to set the composing range.
  //
  // Returns false if the range or offset are out of range for the text, or if
  // the offset is outside the composing range.
  bool SetComposingRange(const TextRange& range, size_t cursor_offset);

  // Begins IME composing mode.
  //
  // Resets the composing base and extent to the selection start. The existing
  // selection is preserved in case composing is aborted with no changes. Until
  // |EndComposing| is called, any further changes to selection base and extent
  // are restricted to the composing range.
  void BeginComposing();

  // Replaces the composing range with new text.
  //
  // If a selection of non-zero length exists, it is deleted if the composing
  // text is non-empty. The composing range is adjusted to the length of
  // |composing_text| and the selection base and offset are set to the end of
  // the composing range.
  void UpdateComposingText(const std::string& composing_text);

  // Commits composing range to the string.
  //
  // Causes the composing base and extent to be collapsed to the end of the
  // range.
  void CommitComposing();

  // Ends IME composing mode.
  //
  // Collapses the composing base and offset to 0.
  void EndComposing();

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
  // and extent are the same. When composing is active, deletions are
  // restricted to text between the composing base and extent.
  //
  // Returns true if any deletion actually occurred.
  bool Delete();

  // Deletes text near the cursor.
  //
  // A section is made starting at |offset_from_cursor| code points past the
  // cursor (negative values go before the cursor). |count| code points are
  // removed. The selection may go outside the bounds of the available text and
  // will result in only the part selection that covers the available text
  // being deleted. The existing selection is ignored and removed after this
  // operation. When composing is active, deletions are restricted to the
  // composing range.
  //
  // Returns true if any deletion actually occurred.
  bool DeleteSurrounding(int offset_from_cursor, int count);

  // Deletes either the selection, or one character behind the cursor.
  //
  // Deleting one character behind the cursor occurs when the selection base
  // and extent are the same. When composing is active, deletions are
  // restricted to the text between the composing base and extent.
  //
  // Returns true if any deletion actually occurred.
  bool Backspace();

  // Attempts to move the cursor backward.
  //
  // Returns true if the cursor could be moved. If a selection is active, moves
  // to the start of the selection. If composing is active, motion is
  // restricted to the composing range.
  bool MoveCursorBack();

  // Attempts to move the cursor forward.
  //
  // Returns true if the cursor could be moved. If a selection is active, moves
  // to the end of the selection. If composing is active, motion is restricted
  // to the composing range.
  bool MoveCursorForward();

  // Attempts to move the cursor to the beginning.
  //
  // If composing is active, the cursor is moved to the beginning of the
  // composing range; otherwise, it is moved to the beginning of the text. If
  // composing is active, motion is restricted to the composing range.
  //
  // Returns true if the cursor could be moved.
  bool MoveCursorToBeginning();

  // Attempts to move the cursor to the end.
  //
  // If composing is active, the cursor is moved to the end of the composing
  // range; otherwise, it is moved to the end of the text. If composing is
  // active, motion is restricted to the composing range.
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

  // The composing range.
  //
  // If not in composing mode, returns a collapsed range at position 0.
  TextRange composing_range() const { return composing_range_; }

  // Whether multi-step input composing mode is active.
  bool composing() const { return composing_; }

 private:
  // Deletes the current selection, if any.
  //
  // Returns true if any text is deleted. The selection base and extent are
  // reset to the start of the selected range.
  bool DeleteSelected();

  // Returns the currently editable text range.
  //
  // In composing mode, returns the composing range; otherwise, returns a range
  // covering the entire text.
  TextRange editable_range() const {
    return composing_ ? composing_range_ : text_range();
  }

  // Returns a range covering the entire text.
  TextRange text_range() const { return TextRange(0, text_.length()); }

  std::u16string text_;
  TextRange selection_ = TextRange(0);
  TextRange composing_range_ = TextRange(0);
  bool composing_ = false;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_CPP_TEXT_INPUT_MODEL_H_
