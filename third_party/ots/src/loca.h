// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_LOCA_H_
#define OTS_LOCA_H_

#include <vector>

#include "ots.h"

namespace ots {

struct OpenTypeLOCA {
  std::vector<uint32_t> offsets;
};

}  // namespace ots

#endif  // OTS_LOCA_H_
