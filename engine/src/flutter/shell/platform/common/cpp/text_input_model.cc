// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/cpp/text_input_model.h"

#include <algorithm>
#include <codecvt>
#include <locale>

#if defined(_MSC_VER)
// TODO(naifu): This temporary code is to solve link error.(VS2015/2017)
// https://social.msdn.microsoft.com/Forums/vstudio/en-US/8f40dcd8-c67f-4eba-9134-a19b9178e481/vs-2015-rc-linker-stdcodecvt-error
std::locale::id std::codecvt<char16_t, char, _Mbstatet>::id;
#endif  // defined(_MSC_VER)

namespace flutter {

namespace {

// Returns true if |code_point| is a leading surrogate of a surrogate pair.
bool IsLeadingSurrogate(char32_t code_point) {
  return (code_point & 0xFFFFFC00) == 0xD800;
}
// Returns true if |code_point| is a trailing surrogate of a surrogate pair.
bool IsTrailingSurrogate(char32_t code_point) {
  return (code_point & 0xFFFFFC00) == 0xDC00;
}

}  // namespace

TextInputModel::TextInputModel(const std::string& input_type,
                               const std::string& input_action)
    : input_type_(input_type),
      input_action_(input_action),
      selection_base_(text_.begin()),
      selection_extent_(text_.begin()) {}

TextInputModel::~TextInputModel() = default;

bool TextInputModel::SetEditingState(size_t selection_base,
                                     size_t selection_extent,
                                     const std::string& text) {
  if (selection_base > selection_extent) {
    return false;
  }
  // Only checks extent since it is implicitly greater-than-or-equal-to base.
  if (selection_extent > text.size()) {
    return false;
  }
  std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>
      utf16_converter;
  text_ = utf16_converter.from_bytes(text);
  selection_base_ = text_.begin() + selection_base;
  selection_extent_ = text_.begin() + selection_extent;
  return true;
}

void TextInputModel::DeleteSelected() {
  selection_base_ = text_.erase(selection_base_, selection_extent_);
  // Moves extent back to base, so that it is a single cursor placement again.
  selection_extent_ = selection_base_;
}

void TextInputModel::AddCodePoint(char32_t c) {
  if (c <= 0xFFFF) {
    AddText(std::u16string({static_cast<char16_t>(c)}));
  } else {
    char32_t to_decompose = c - 0x10000;
    AddText(std::u16string({
        // High surrogate.
        static_cast<char16_t>((to_decompose >> 10) + 0xd800),
        // Low surrogate.
        static_cast<char16_t>((to_decompose % 0x400) + 0xdc00),
    }));
  }
}

void TextInputModel::AddText(const std::u16string& text) {
  if (selection_base_ != selection_extent_) {
    DeleteSelected();
  }
  selection_extent_ = text_.insert(selection_extent_, text.begin(), text.end());
  selection_extent_ += text.length();
  selection_base_ = selection_extent_;
}

bool TextInputModel::Backspace() {
  if (selection_base_ != selection_extent_) {
    DeleteSelected();
    return true;
  }
  if (selection_base_ != text_.begin()) {
    int count = IsTrailingSurrogate(*(selection_base_ - 1)) ? 2 : 1;
    selection_base_ = text_.erase(selection_base_ - count, selection_base_);
    selection_extent_ = selection_base_;
    return true;
  }
  return false;  // No edits happened.
}

bool TextInputModel::Delete() {
  if (selection_base_ != selection_extent_) {
    DeleteSelected();
    return true;
  }
  if (selection_base_ != text_.end()) {
    int count = IsLeadingSurrogate(*selection_base_) ? 2 : 1;
    selection_base_ = text_.erase(selection_base_, selection_base_ + count);
    selection_extent_ = selection_base_;
    return true;
  }
  return false;
}

void TextInputModel::MoveCursorToBeginning() {
  selection_base_ = text_.begin();
  selection_extent_ = text_.begin();
}

void TextInputModel::MoveCursorToEnd() {
  selection_base_ = text_.end();
  selection_extent_ = text_.end();
}

bool TextInputModel::MoveCursorForward() {
  // If about to move set to the end of the highlight (when not selecting).
  if (selection_base_ != selection_extent_) {
    selection_base_ = selection_extent_;
    return true;
  }
  // If not at the end, move the extent forward.
  if (selection_extent_ != text_.end()) {
    int count = IsLeadingSurrogate(*selection_base_) ? 2 : 1;
    selection_base_ += count;
    selection_extent_ = selection_base_;
    return true;
  }
  return false;
}

bool TextInputModel::MoveCursorBack() {
  // If about to move set to the beginning of the highlight
  // (when not selecting).
  if (selection_base_ != selection_extent_) {
    selection_extent_ = selection_base_;
    return true;
  }
  // If not at the start, move the beginning backward.
  if (selection_base_ != text_.begin()) {
    int count = IsTrailingSurrogate(*(selection_base_ - 1)) ? 2 : 1;
    selection_base_ -= count;
    selection_extent_ = selection_base_;
    return true;
  }
  return false;
}

std::string TextInputModel::GetText() const {
  std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>
      utf8_converter;
  return utf8_converter.to_bytes(text_);
}

}  // namespace flutter
