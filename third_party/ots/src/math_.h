// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_MATH_H_
#define OTS_MATH_H_

#include "ots.h"

namespace ots {

struct OpenTypeMATH {
  OpenTypeMATH()
      : data(NULL),
        length(0) {
  }

  const uint8_t *data;
  size_t length;
};

}  // namespace ots

#endif

