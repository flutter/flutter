// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_GDEF_H_
#define OTS_GDEF_H_

#include "ots.h"

namespace ots {

struct OpenTypeGDEF {
  OpenTypeGDEF()
      : version_2(false),
        has_glyph_class_def(false),
        has_mark_attachment_class_def(false),
        has_mark_glyph_sets_def(false),
        num_mark_glyph_sets(0),
        data(NULL),
        length(0) {
  }

  bool version_2;
  bool has_glyph_class_def;
  bool has_mark_attachment_class_def;
  bool has_mark_glyph_sets_def;
  uint16_t num_mark_glyph_sets;

  const uint8_t *data;
  size_t length;
};

}  // namespace ots

#endif

