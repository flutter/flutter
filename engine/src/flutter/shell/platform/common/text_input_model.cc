// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/text_input_model.h"

#include <algorithm>
#include <string>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/string_conversion.h"

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

// Returns the position one character after |pos|, or |limit| if a whole
// character does not fit between the two.
//
// A surrogate pair that straddles |limit| is not stepped over. We can't end
// halfway through, and deleting half a character would produce invalid UTF-8.
//
// A leading surrogate spans two code units only if |text| pairs it with a
// trailing one. An unpaired surrogate is a character of its own, so it is
// stepped over alone rather than swallowing whatever follows it.
size_t NextCharacterBoundary(const std::u16string& text,
                             size_t pos,
                             size_t limit) {
  if (pos == limit) {
    return pos;
  }
  size_t step = IsLeadingSurrogate(text.at(pos)) && pos + 1 < text.length() &&
                        IsTrailingSurrogate(text.at(pos + 1))
                    ? 2
                    : 1;
  return limit - pos < step ? pos : pos + step;
}

// Returns the position one character before |pos|, or |limit| if a whole
// character does not fit between the two.
size_t PreviousCharacterBoundary(const std::u16string& text,
                                 size_t pos,
                                 size_t limit) {
  if (pos == limit) {
    return pos;
  }
  size_t step = IsTrailingSurrogate(text.at(pos - 1)) && pos >= 2 &&
                        IsLeadingSurrogate(text.at(pos - 2))
                    ? 2
                    : 1;
  return pos - limit < step ? pos : pos - step;
}

}  // namespace

TextInputModel::TextInputModel() = default;

TextInputModel::~TextInputModel() = default;

bool TextInputModel::SetText(const std::string& text,
                             const TextRange& selection,
                             const TextRange& composing_range) {
  std::u16string new_text = fml::Utf8ToUtf16(text);
  const TextRange new_text_range(0, new_text.length());
  if (!new_text_range.Contains(selection) ||
      !new_text_range.Contains(composing_range)) {
    return false;
  }

  text_ = std::move(new_text);
  selection_ = selection;
  composing_range_ = composing_range;
  composing_ = !composing_range.collapsed();
  return true;
}

bool TextInputModel::SetSelection(const TextRange& range) {
  if (composing_ && !range.collapsed()) {
    return false;
  }
  if (!editable_range().Contains(range)) {
    return false;
  }
  selection_ = range;
  return true;
}

bool TextInputModel::SetComposingRange(const TextRange& range,
                                       size_t cursor_offset) {
  if (!composing_ || !text_range().Contains(range) ||
      cursor_offset > text_.length() - range.start()) {
    return false;
  }
  composing_range_ = range;
  selection_ = TextRange(range.start() + cursor_offset);
  return true;
}

void TextInputModel::BeginComposing() {
  composing_ = true;
  composing_range_ = TextRange(selection_.start());
}

void TextInputModel::UpdateComposingText(const std::u16string& text,
                                         const TextRange& selection) {
  // Re-clamp current selection and composing range to text.
  FML_DCHECK(text_range().Contains(selection_) &&
             text_range().Contains(composing_range_));
  selection_ = selection_.ClampedTo(text_.length());
  composing_range_ = composing_range_.ClampedTo(text_.length());

  // Preserve selection if we get a no-op update to the composing region.
  if (text.length() == 0 && composing_range_.collapsed()) {
    return;
  }
  const TextRange& rangeToDelete =
      composing_range_.collapsed() ? selection_ : composing_range_;
  text_.replace(rangeToDelete.start(), rangeToDelete.length(), text);
  composing_range_.set_end(composing_range_.start() + text.length());

  // Updated |selection| is supplied by the IME. Clamp to text length.
  const TextRange clamped_selection = selection.ClampedTo(text.length());
  selection_ = TextRange(clamped_selection.start() + composing_range_.start(),
                         clamped_selection.extent() + composing_range_.start());
}

void TextInputModel::UpdateComposingText(const std::u16string& text) {
  UpdateComposingText(text, TextRange(text.length()));
}

void TextInputModel::UpdateComposingText(const std::string& text) {
  UpdateComposingText(fml::Utf8ToUtf16(text));
}

void TextInputModel::CommitComposing() {
  // Preserve selection if no composing text was entered.
  if (composing_range_.collapsed()) {
    return;
  }
  composing_range_ = TextRange(composing_range_.end());
  selection_ = composing_range_;
}

void TextInputModel::EndComposing() {
  composing_ = false;
  composing_range_ = TextRange(0);
}

bool TextInputModel::DeleteSelected() {
  if (selection_.collapsed()) {
    return false;
  }
  size_t start = selection_.start();
  text_.erase(start, selection_.length());
  selection_ = TextRange(start);
  if (composing_) {
    // This occurs only immediately after composing has begun with a selection.
    composing_range_ = selection_;
  }
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
  if (composing_) {
    // Delete the current composing text, set the cursor to composing start.
    text_.erase(composing_range_.start(), composing_range_.length());
    selection_ = TextRange(composing_range_.start());
    composing_range_.set_end(composing_range_.start() + text.length());
  }
  size_t position = selection_.position();
  text_.insert(position, text);
  selection_ = TextRange(position + text.length());
}

void TextInputModel::AddText(const std::string& text) {
  AddText(fml::Utf8ToUtf16(text));
}

bool TextInputModel::Backspace() {
  if (DeleteSelected()) {
    return true;
  }
  // There is no selection. Delete the preceding character.
  size_t position = std::clamp(selection_.position(), editable_range().start(),
                               editable_range().end());
  size_t start =
      PreviousCharacterBoundary(text_, position, editable_range().start());
  if (start == position) {
    return false;
  }
  size_t count = position - start;
  text_.erase(start, count);
  selection_ = TextRange(start);
  if (composing_) {
    composing_range_.set_end(composing_range_.end() - count);
  }
  return true;
}

bool TextInputModel::Delete() {
  if (DeleteSelected()) {
    return true;
  }
  // There is no selection. Delete the following character.
  size_t position = std::clamp(selection_.position(), editable_range().start(),
                               editable_range().end());
  size_t end = NextCharacterBoundary(text_, position, editable_range().end());
  if (end == position) {
    return false;
  }
  size_t count = end - position;
  text_.erase(position, count);
  if (composing_) {
    composing_range_.set_end(composing_range_.end() - count);
  }
  return true;
}

bool TextInputModel::DeleteSurrounding(int offset_from_cursor, int count) {
  size_t min_pos = editable_range().start();
  size_t max_pos = editable_range().end();
  size_t start = std::clamp(selection_.extent(), min_pos, max_pos);
  if (offset_from_cursor < 0) {
    for (int i = 0; i < -offset_from_cursor; i++) {
      size_t previous = PreviousCharacterBoundary(text_, start, min_pos);
      // We hit the start of the editable range. Delete only the characters it
      // covered.
      if (previous == start) {
        count = i;
        break;
      }
      start = previous;
    }
  } else {
    for (int i = 0; i < offset_from_cursor; i++) {
      size_t next = NextCharacterBoundary(text_, start, max_pos);
      if (next == start) {
        break;
      }
      start = next;
    }
  }

  auto end = start;
  for (int i = 0; i < count; i++) {
    size_t next = NextCharacterBoundary(text_, end, max_pos);
    if (next == end) {
      break;
    }
    end = next;
  }

  if (start == end) {
    return false;
  }

  auto deleted_length = end - start;
  text_.erase(start, deleted_length);

  // Cursor moves only if deleted area is before it.
  selection_ = TextRange(offset_from_cursor <= 0 ? start : selection_.start());

  // Adjust composing range.
  if (composing_) {
    composing_range_.set_end(composing_range_.end() - deleted_length);
  }
  return true;
}

bool TextInputModel::MoveCursorToBeginning() {
  size_t min_pos = editable_range().start();
  if (selection_.collapsed() && selection_.position() == min_pos) {
    return false;
  }
  selection_ = TextRange(min_pos);
  return true;
}

bool TextInputModel::MoveCursorToEnd() {
  size_t max_pos = editable_range().end();
  if (selection_.collapsed() && selection_.position() == max_pos) {
    return false;
  }
  selection_ = TextRange(max_pos);
  return true;
}

bool TextInputModel::SelectToBeginning() {
  size_t min_pos = editable_range().start();
  if (selection_.collapsed() && selection_.position() == min_pos) {
    return false;
  }
  selection_ = TextRange(selection_.base(), min_pos);
  return true;
}

bool TextInputModel::SelectToEnd() {
  size_t max_pos = editable_range().end();
  if (selection_.collapsed() && selection_.position() == max_pos) {
    return false;
  }
  selection_ = TextRange(selection_.base(), max_pos);
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
  if (position != editable_range().end()) {
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
  if (position != editable_range().start()) {
    int count = IsTrailingSurrogate(text_.at(position - 1)) ? 2 : 1;
    selection_ = TextRange(position - count);
    return true;
  }
  return false;
}

std::string TextInputModel::GetText() const {
  return fml::Utf16ToUtf8(text_);
}

int TextInputModel::GetCursorOffset() const {
  // Measure the length of the current text up to the selection extent.
  // There is probably a much more efficient way of doing this.
  auto leading_text = text_.substr(0, selection_.extent());
  return fml::Utf16ToUtf8(leading_text).size();
}

}  // namespace flutter
