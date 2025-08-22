// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_text.h"

#include <memory>

namespace flutter {

bool DlText::operator==(const DlText& other) const {
  return GetTextBlob() == other.GetTextBlob() &&
         GetTextFrame() == other.GetTextFrame();
}

}  // namespace flutter
