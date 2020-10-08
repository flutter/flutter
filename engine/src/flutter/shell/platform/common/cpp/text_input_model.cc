// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// FLUTTER_NOLINT

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

TextInputModel::TextInputModel() = default;

TextInputModel::~TextInputModel() = default;

void TextInputModel::SetText(const std::string& text) {
  std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>
      utf16_converter;
  text_ = utf16_converter.from_bytes(text);
  selection_base_ = 0;
  selection_extent_ = 0;
}

bool TextInputModel::SetSelection(size_t base, size_t extent) {
  auto max_pos = text_.length();
  if (base > max_pos || extent > max_pos) {
    return false;
  }
  selection_base_ = base;
  selection_extent_ = extent;
  return true;
}

bool TextInputModel::DeleteSelected() {
  if (selection_base_ == selection_extent_) {
    return false;
  }
  text_.erase(selection_start(), selection_end() - selection_start());
  selection_base_ = selection_start();
  selection_extent_ = selection_base_;
  return true;
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
  DeleteSelected();
  text_.insert(selection_extent_, text);
  selection_extent_ += text.length();
  selection_base_ = selection_extent_;
}

void TextInputModel::AddText(const std::string& text) {
  std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>
      utf16_converter;
  AddText(utf16_converter.from_bytes(text));
}

bool TextInputModel::Backspace() {
  // If there's a selection, delete it.
  if (DeleteSelected()) {
    return true;
  }
  // There's no selection; delete the preceding codepoint.
  if (selection_base_ != 0) {
    int count = IsTrailingSurrogate(text_.at(selection_base_ - 1)) ? 2 : 1;
    text_.erase(selection_base_ - count, count);
    selection_base_ -= count;
    selection_extent_ = selection_base_;
    return true;
  }
  return false;
}

bool TextInputModel::Delete() {
  // If there's a selection, delete it.
  if (DeleteSelected()) {
    return true;
  }
  // There's no selection; delete the following codepoint.
  if (selection_base_ != text_.length()) {
    int count = IsLeadingSurrogate(text_.at(selection_base_)) ? 2 : 1;
    text_.erase(selection_base_, count);
    selection_extent_ = selection_base_;
    return true;
  }
  return false;
}

bool TextInputModel::DeleteSurrounding(int offset_from_cursor, int count) {
  auto start = selection_extent_;
  if (offset_from_cursor < 0) {
    for (int i = 0; i < -offset_from_cursor; i++) {
      // If requested start is before the available text then reduce the
      // number of characters to delete.
      if (start == 0) {
        count = i;
        break;
      }
      start -= IsTrailingSurrogate(text_.at(start - 1)) ? 2 : 1;
    }
  } else {
    for (int i = 0; i < offset_from_cursor && start != text_.length(); i++) {
      start += IsLeadingSurrogate(text_.at(start)) ? 2 : 1;
    }
  }

  auto end = start;
  for (int i = 0; i < count && end != text_.length(); i++) {
    end += IsLeadingSurrogate(text_.at(start)) ? 2 : 1;
  }

  if (start == end) {
    return false;
  }

  text_.erase(start, end - start);

  // Cursor moves only if deleted area is before it.
  if (offset_from_cursor <= 0) {
    selection_base_ = start;
  }

  // Clear selection.
  selection_extent_ = selection_base_;

  return true;
}

bool TextInputModel::MoveCursorToBeginning() {
  if (selection_base_ == 0 && selection_extent_ == 0)
    return false;

  selection_base_ = 0;
  selection_extent_ = 0;
  return true;
}

bool TextInputModel::MoveCursorToEnd() {
  auto max_pos = text_.length();
  if (selection_base_ == max_pos && selection_extent_ == max_pos)
    return false;

  selection_base_ = max_pos;
  selection_extent_ = max_pos;
  return true;
}

bool TextInputModel::MoveCursorForward() {
  // If about to move set to the end of the highlight (when not selecting).
  if (selection_base_ != selection_extent_) {
    selection_base_ = selection_end();
    selection_extent_ = selection_base_;
    return true;
  }
  // If not at the end, move the extent forward.
  if (selection_extent_ != text_.length()) {
    int count = IsLeadingSurrogate(text_.at(selection_base_)) ? 2 : 1;
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
    selection_base_ = selection_start();
    selection_extent_ = selection_base_;
    return true;
  }
  // If not at the start, move the beginning backward.
  if (selection_base_ != 0) {
    int count = IsTrailingSurrogate(text_.at(selection_base_ - 1)) ? 2 : 1;
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

int TextInputModel::GetCursorOffset() const {
  // Measure the length of the current text up to the cursor.
  // There is probably a much more efficient way of doing this.
  auto leading_text = text_.substr(0, selection_extent_);
  std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>
      utf8_converter;
  return utf8_converter.to_bytes(leading_text).size();
}

}  // namespace flutter
