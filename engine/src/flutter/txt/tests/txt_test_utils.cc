// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "txt_test_utils.h"

namespace txt {

static std::string gFontDir;

const std::string& GetFontDir() {
  return gFontDir;
}

void SetFontDir(const std::string& dir) {
  gFontDir = dir;
}

}  // namespace txt
