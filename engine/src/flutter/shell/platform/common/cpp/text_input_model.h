// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_CPP_TEXT_INPUT_MODEL_H_
#define FLUTTER_SHELL_PLATFORM_CPP_TEXT_INPUT_MODEL_H_

#include <memory>
#include <string>

namespace flutter {
// Handles underlying text input state, using a simple ASCII model.
//
// Ignores special states like "insert mode" for now.
class TextInputModel {
 public:
  TextInputModel();
  virtual ~TextInputModel();

  // Attempts to set the text state.
  //
  // Returns false if the state is not valid (base or extent are out of
  // bounds, or base is less than extent).
  bool SetEditingState(size_t selection_base,
                       size_t selection_extent,
                       const std::string& text);

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

  // The position where the selection starts.
  int selection_base() const {
    return static_cast<int>(selection_base_ - text_.begin());
  }

  // The position of the cursor.
  int selection_extent() const {
    return static_cast<int>(selection_extent_ - text_.begin());
  }

 private:
  void DeleteSelected();

  std::u16string text_;
  std::u16string::iterator selection_base_;
  std::u16string::iterator selection_extent_;

  // Returns the left hand side of the selection.
  std::u16string::iterator selection_start() {
    return selection_base_ < selection_extent_ ? selection_base_
                                               : selection_extent_;
  }

  // Returns the right hand side of the selection.
  std::u16string::iterator selection_end() {
    return selection_base_ > selection_extent_ ? selection_base_
                                               : selection_extent_;
  }
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_CPP_TEXT_INPUT_MODEL_H_
