// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_STRINGS_NULLABLE_STRING16_H_
#define BASE_STRINGS_NULLABLE_STRING16_H_

#include <iosfwd>

#include "base/base_export.h"
#include "base/strings/string16.h"

namespace base {

// This class is a simple wrapper for string16 which also contains a null
// state.  This should be used only where the difference between null and
// empty is meaningful.
class NullableString16 {
 public:
  NullableString16() : is_null_(true) { }
  NullableString16(const string16& string, bool is_null)
      : string_(string), is_null_(is_null) {
  }

  const string16& string() const { return string_; }
  bool is_null() const { return is_null_; }

 private:
  string16 string_;
  bool is_null_;
};

inline bool operator==(const NullableString16& a, const NullableString16& b) {
  return a.is_null() == b.is_null() && a.string() == b.string();
}

inline bool operator!=(const NullableString16& a, const NullableString16& b) {
  return !(a == b);
}

BASE_EXPORT std::ostream& operator<<(std::ostream& out,
                                     const NullableString16& value);

}  // namespace base

#endif  // BASE_STRINGS_NULLABLE_STRING16_H_
