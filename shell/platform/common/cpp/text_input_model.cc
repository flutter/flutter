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
  selection_ = TextRange(0);
}

bool TextInputModel::SetSelection(size_t base, size_t extent) {
  size_t max_pos = text_.length();
  if (base > max_pos || extent > max_pos) {
    return false;
  }
  selection_ = TextRange(base, extent);
  return true;
}

bool TextInputModel::DeleteSelected() {
  if (selection_.collapsed()) {
    return false;
  }
  text_.erase(selection_.start(), selection_.length());
  selection_ = TextRange(selection_.start());
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
  size_t position = selection_.position();
  text_.insert(position, text);
  selection_ = TextRange(position + text.length());
}

void TextInputModel::AddText(const std::string& text) {
  std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>
      utf16_converter;
  AddText(utf16_converter.from_bytes(text));
}

bool TextInputModel::Backspace() {
  if (DeleteSelected()) {
    return true;
  }
  // If there's no selection, delete the preceding codepoint.
  size_t position = selection_.position();
  if (position != 0) {
    int count = IsTrailingSurrogate(text_.at(position - 1)) ? 2 : 1;
    text_.erase(position - count, count);
    selection_ = TextRange(position - count);
    return true;
  }
  return false;
}

bool TextInputModel::Delete() {
  if (DeleteSelected()) {
    return true;
  }
  // If there's no selection, delete the preceding codepoint.
  size_t position = selection_.position();
  if (position != text_.length()) {
    int count = IsLeadingSurrogate(text_.at(position)) ? 2 : 1;
    text_.erase(position, count);
    return true;
  }
  return false;
}

bool TextInputModel::DeleteSurrounding(int offset_from_cursor, int count) {
  size_t start = selection_.extent();
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
  selection_ = TextRange(offset_from_cursor <= 0 ? start : selection_.start());

  return true;
}

bool TextInputModel::MoveCursorToBeginning() {
  if (selection_.collapsed() && selection_.position() == 0)
    return false;
  selection_ = TextRange(0);
  return true;
}

bool TextInputModel::MoveCursorToEnd() {
  size_t max_pos = text_.length();
  if (selection_.collapsed() && selection_.position() == max_pos)
    return false;
  selection_ = TextRange(max_pos);
  return true;
}

bool TextInputModel::MoveCursorForward() {
  // If there's a selection, move to the end of the selection.
  if (!selection_.collapsed()) {
    selection_ = TextRange(selection_.end());
    return true;
  }
  // Otherwise, move the cursor forward.
  size_t position = selection_.position();
  if (position != text_.length()) {
    int count = IsLeadingSurrogate(text_.at(position)) ? 2 : 1;
    selection_ = TextRange(position + count);
    return true;
  }
  return false;
}

bool TextInputModel::MoveCursorBack() {
  // If there's a selection, move to the beginning of the selection.
  if (!selection_.collapsed()) {
    selection_ = TextRange(selection_.start());
    return true;
  }
  // Otherwise, move the cursor backward.
  size_t position = selection_.position();
  if (position != 0) {
    int count = IsTrailingSurrogate(text_.at(position - 1)) ? 2 : 1;
    selection_ = TextRange(position - count);
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
  // Measure the length of the current text up to the selection extent.
  // There is probably a much more efficient way of doing this.
  auto leading_text = text_.substr(0, selection_.extent());
  std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>
      utf8_converter;
  return utf8_converter.to_bytes(leading_text).size();
}

}  // namespace flutter
