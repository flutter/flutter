// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/guid.h"

#include <stdlib.h>

#include <objbase.h>
#include <windows.h>

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversions.h"

namespace base {

std::string GenerateGUID() {
  const int kGUIDSize = 39;

  GUID guid;
  HRESULT guid_result = CoCreateGuid(&guid);
  DCHECK(SUCCEEDED(guid_result));
  if (!SUCCEEDED(guid_result))
    return std::string();

  std::wstring guid_string;
  int result = StringFromGUID2(guid,
                               WriteInto(&guid_string, kGUIDSize), kGUIDSize);
  DCHECK(result == kGUIDSize);
  if (result != kGUIDSize)
    return std::string();

  return WideToUTF8(guid_string.substr(1, guid_string.length() - 2));
}

}  // namespace base
