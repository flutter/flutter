// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_GSUB_H_
#define OTS_GSUB_H_

#include "ots.h"

namespace ots {

struct OpenTypeGSUB {
  OpenTypeGSUB()
      : num_lookups(0),
        data(NULL),
        length(0) {
  }

  // Number of lookups in GPSUB table
  uint16_t num_lookups;

  const uint8_t *data;
  size_t length;
};

}  // namespace ots

#endif  // OTS_GSUB_H_

