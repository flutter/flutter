// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/strings/latin1_string_conversions.h"

namespace base {

string16 Latin1OrUTF16ToUTF16(size_t length,
                              const Latin1Char* latin1,
                              const char16* utf16) {
  if (!length)
    return string16();
  if (latin1)
    return string16(latin1, latin1 + length);
  return string16(utf16, utf16 + length);
}

}  // namespace base
