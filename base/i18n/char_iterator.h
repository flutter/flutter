// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_I18N_CHAR_ITERATOR_H_
#define BASE_I18N_CHAR_ITERATOR_H_

#include <string>

#include "base/basictypes.h"
#include "base/i18n/base_i18n_export.h"
#include "base/strings/string16.h"

// The CharIterator classes iterate through the characters in UTF8 and
// UTF16 strings.  Example usage:
//
//   UTF8CharIterator iter(&str);
//   while (!iter.end()) {
//     VLOG(1) << iter.get();
//     iter.Advance();
//   }

#if defined(OS_WIN)
typedef unsigned char uint8_t;
#endif

namespace base {
namespace i18n {

class BASE_I18N_EXPORT UTF8CharIterator {
 public:
  // Requires |str| to live as long as the UTF8CharIterator does.
  explicit UTF8CharIterator(const std::string* str);
  ~UTF8CharIterator();

  // Return the starting array index of the current character within the
  // string.
  int32 array_pos() const { return array_pos_; }

  // Return the logical index of the current character, independent of the
  // number of bytes each character takes.
  int32 char_pos() const { return char_pos_; }

  // Return the current char.
  int32 get() const { return char_; }

  // Returns true if we're at the end of the string.
  bool end() const { return array_pos_ == len_; }

  // Advance to the next actual character.  Returns false if we're at the
  // end of the string.
  bool Advance();

 private:
  // The string we're iterating over.
  const uint8_t* str_;

  // The length of the encoded string.
  int32 len_;

  // Array index.
  int32 array_pos_;

  // The next array index.
  int32 next_pos_;

  // Character index.
  int32 char_pos_;

  // The current character.
  int32 char_;

  DISALLOW_COPY_AND_ASSIGN(UTF8CharIterator);
};

class BASE_I18N_EXPORT UTF16CharIterator {
 public:
  // Requires |str| to live as long as the UTF16CharIterator does.
  explicit UTF16CharIterator(const string16* str);
  UTF16CharIterator(const char16* str, size_t str_len);
  ~UTF16CharIterator();

  // Return the starting array index of the current character within the
  // string.
  int32 array_pos() const { return array_pos_; }

  // Return the logical index of the current character, independent of the
  // number of codewords each character takes.
  int32 char_pos() const { return char_pos_; }

  // Return the current char.
  int32 get() const { return char_; }

  // Returns true if we're at the end of the string.
  bool end() const { return array_pos_ == len_; }

  // Advance to the next actual character.  Returns false if we're at the
  // end of the string.
  bool Advance();

 private:
  // Fills in the current character we found and advances to the next
  // character, updating all flags as necessary.
  void ReadChar();

  // The string we're iterating over.
  const char16* str_;

  // The length of the encoded string.
  int32 len_;

  // Array index.
  int32 array_pos_;

  // The next array index.
  int32 next_pos_;

  // Character index.
  int32 char_pos_;

  // The current character.
  int32 char_;

  DISALLOW_COPY_AND_ASSIGN(UTF16CharIterator);
};

}  // namespace i18n
}  // namespace base

#endif  // BASE_I18N_CHAR_ITERATOR_H_
