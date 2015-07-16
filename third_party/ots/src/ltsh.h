// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_LTSH_H_
#define OTS_LTSH_H_

#include <vector>

#include "ots.h"

namespace ots {

struct OpenTypeLTSH {
  uint16_t version;
  std::vector<uint8_t> ypels;
};

}  // namespace ots

#endif  // OTS_LTSH_H_
