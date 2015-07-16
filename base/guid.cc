// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/guid.h"

#include "base/strings/string_util.h"

namespace base {

bool IsValidGUID(const std::string& guid) {
  const size_t kGUIDLength = 36U;
  if (guid.length() != kGUIDLength)
    return false;

  for (size_t i = 0; i < guid.length(); ++i) {
    char current = guid[i];
    if (i == 8 || i == 13 || i == 18 || i == 23) {
      if (current != '-')
        return false;
    } else {
      if (!IsHexDigit(current))
        return false;
    }
  }

  return true;
}

}  // namespace base
