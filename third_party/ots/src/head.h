// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_HEAD_H_
#define OTS_HEAD_H_

#include "ots.h"

namespace ots {

struct OpenTypeHEAD {
  uint32_t revision;
  uint16_t flags;
  uint16_t ppem;
  uint64_t created;
  uint64_t modified;

  int16_t xmin, xmax;
  int16_t ymin, ymax;

  uint16_t mac_style;
  uint16_t min_ppem;
  int16_t index_to_loc_format;
};

}  // namespace ots

#endif  // OTS_HEAD_H_
