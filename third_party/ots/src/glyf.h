// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_GLYF_H_
#define OTS_GLYF_H_

#include <new>
#include <utility>
#include <vector>

#include "ots.h"

namespace ots {

struct OpenTypeGLYF {
  std::vector<std::pair<const uint8_t*, size_t> > iov;
};

}  // namespace ots

#endif  // OTS_GLYF_H_
