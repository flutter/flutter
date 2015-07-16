// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/i18n/char_iterator.h"

#include "third_party/icu/source/common/unicode/utf8.h"
#include "third_party/icu/source/common/unicode/utf16.h"

namespace base {
namespace i18n {

UTF8CharIterator::UTF8CharIterator(const std::string* str)
    : str_(reinterpret_cast<const uint8_t*>(str->data())),
      len_(str->size()),
      array_pos_(0),
      next_pos_(0),
      char_pos_(0),
      char_(0) {
  if (len_)
    U8_NEXT(str_, next_pos_, len_, char_);
}

UTF8CharIterator::~UTF8CharIterator() {
}

bool UTF8CharIterator::Advance() {
  if (array_pos_ >= len_)
    return false;

  array_pos_ = next_pos_;
  char_pos_++;
  if (next_pos_ < len_)
    U8_NEXT(str_, next_pos_, len_, char_);

  return true;
}

UTF16CharIterator::UTF16CharIterator(const string16* str)
    : str_(reinterpret_cast<const char16*>(str->data())),
      len_(str->size()),
      array_pos_(0),
      next_pos_(0),
      char_pos_(0),
      char_(0) {
  if (len_)
    ReadChar();
}

UTF16CharIterator::UTF16CharIterator(const char16* str, size_t str_len)
    : str_(str),
      len_(str_len),
      array_pos_(0),
      next_pos_(0),
      char_pos_(0),
      char_(0) {
  if (len_)
    ReadChar();
}

UTF16CharIterator::~UTF16CharIterator() {
}

bool UTF16CharIterator::Advance() {
  if (array_pos_ >= len_)
    return false;

  array_pos_ = next_pos_;
  char_pos_++;
  if (next_pos_ < len_)
    ReadChar();

  return true;
}

void UTF16CharIterator::ReadChar() {
  // This is actually a huge macro, so is worth having in a separate function.
  U16_NEXT(str_, next_pos_, len_, char_);
}

}  // namespace i18n
}  // namespace base
