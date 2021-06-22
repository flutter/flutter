// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/base/strings.h"

#include <cstdarg>

namespace impeller {

IMPELLER_PRINTF_FORMAT(1, 2)
std::string SPrintF(const char* format, ...) {
  va_list list;
  va_start(list, format);
  char buffer[64] = {0};
  ::vsnprintf(buffer, sizeof(buffer), format, list);
  va_end(list);
  return buffer;
}

}  // namespace impeller
