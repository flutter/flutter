// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/paths.h"

#include <windows.h>

#include "lib/fxl/files/path.h"

namespace fml {
namespace paths {

std::pair<bool, std::string> GetExecutableDirectoryPath() {
  HMODULE module = GetModuleHandle(NULL);
  if (module == NULL) {
    return {false, ""};
  }
  char path[MAX_PATH];
  DWORD read_size = GetModuleFileNameA(module, path, MAX_PATH);
  if (read_size == 0 || read_size == MAX_PATH) {
    return {false, ""};
  }
  return {true, files::GetDirectoryName(std::string{path, read_size})};
}

}  // namespace paths
}  // namespace fml
