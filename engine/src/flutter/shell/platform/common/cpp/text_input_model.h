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
  TextInputModel(const std::string& input_type,
                 const std::string& input_action);
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

  // Adds a UTF-16 text.
  //
  // Either appends after the cursor (when selection base and extent are the
  // same), or deletes the selected text, replacing it with the given text.
  void AddText(const std::u16string& text);

  // Deletes either the selection, or one character ahead of the cursor.
  //
  // Deleting one character ahead of the cursor occurs when the selection base
  // and extent are the same.
  //
  // Returns true if any deletion actually occurred.
  bool Delete();

  // Deletes either the selection, or one character behind the cursor.
  //
  // Deleting one character behind the cursor occurs when the selection base
  // and extent are the same.
  //
  // Returns true if any deletion actually occurred.
  bool Backspace();

  // Attempts to move the cursor backward.
  //
  // Returns true if the cursor could be moved. Changes base and extent to be
  // equal to either the extent (if extent is at the end of the string), or
  // for extent to be equal to
  bool MoveCursorBack();

  // Attempts to move the cursor forward.
  //
  // Returns true if the cursor could be moved.
  bool MoveCursorForward();

  // Attempts to move the cursor to the beginning.
  //
  // Returns true if the cursor could be moved.
  void MoveCursorToBeginning();

  // Attempts to move the cursor to the back.
  //
  // Returns true if the cursor could be moved.
  void MoveCursorToEnd();

  // Get the current text
  std::string GetText() const;

  // The position of the cursor
  int selection_base() const {
    return static_cast<int>(selection_base_ - text_.begin());
  }

  // The end of the selection
  int selection_extent() const {
    return static_cast<int>(selection_extent_ - text_.begin());
  }

  // Keyboard type of the client. See available options:
  // https://docs.flutter.io/flutter/services/TextInputType-class.html
  std::string input_type() const { return input_type_; }

  // An action requested by the user on the input client. See available options:
  // https://docs.flutter.io/flutter/services/TextInputAction-class.html
  std::string input_action() const { return input_action_; }

 private:
  void DeleteSelected();

  std::u16string text_;
  std::string input_type_;
  std::string input_action_;
  std::u16string::iterator selection_base_;
  std::u16string::iterator selection_extent_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_CPP_TEXT_INPUT_MODEL_H_
