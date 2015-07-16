// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "maxp.h"

// maxp - Maximum Profile
// http://www.microsoft.com/typography/otspec/maxp.htm

#define TABLE_NAME "maxp"

namespace ots {

bool ots_maxp_parse(OpenTypeFile *file, const uint8_t *data, size_t length) {
  Buffer table(data, length);

  OpenTypeMAXP *maxp = new OpenTypeMAXP;
  file->maxp = maxp;

  uint32_t version = 0;
  if (!table.ReadU32(&version)) {
    return OTS_FAILURE_MSG("Failed to read version of maxp table");
  }

  if (version >> 16 > 1) {
    return OTS_FAILURE_MSG("Bad maxp version %d", version);
  }

  if (!table.ReadU16(&maxp->num_glyphs)) {
    return OTS_FAILURE_MSG("Failed to read number of glyphs from maxp table");
  }

  if (!maxp->num_glyphs) {
    return OTS_FAILURE_MSG("Bad number of glyphs 0 in maxp table");
  }

  if (version >> 16 == 1) {
    maxp->version_1 = true;
    if (!table.ReadU16(&maxp->max_points) ||
        !table.ReadU16(&maxp->max_contours) ||
        !table.ReadU16(&maxp->max_c_points) ||
        !table.ReadU16(&maxp->max_c_contours) ||
        !table.ReadU16(&maxp->max_zones) ||
        !table.ReadU16(&maxp->max_t_points) ||
        !table.ReadU16(&maxp->max_storage) ||
        !table.ReadU16(&maxp->max_fdefs) ||
        !table.ReadU16(&maxp->max_idefs) ||
        !table.ReadU16(&maxp->max_stack) ||
        !table.ReadU16(&maxp->max_size_glyf_instructions) ||
        !table.ReadU16(&maxp->max_c_components) ||
        !table.ReadU16(&maxp->max_c_depth)) {
      return OTS_FAILURE_MSG("Failed to read maxp table");
    }

    if (maxp->max_zones == 0) {
      // workaround for ipa*.ttf Japanese fonts.
      OTS_WARNING("bad max_zones: %u", maxp->max_zones);
      maxp->max_zones = 1;
    } else if (maxp->max_zones == 3) {
      // workaround for Ecolier-*.ttf fonts.
      OTS_WARNING("bad max_zones: %u", maxp->max_zones);
      maxp->max_zones = 2;
    }

    if ((maxp->max_zones != 1) && (maxp->max_zones != 2)) {
      return OTS_FAILURE_MSG("Bad max zones %d in maxp", maxp->max_zones);
    }
  } else {
    maxp->version_1 = false;
  }

  return true;
}

bool ots_maxp_should_serialise(OpenTypeFile *file) {
  return file->maxp != NULL;
}

bool ots_maxp_serialise(OTSStream *out, OpenTypeFile *file) {
  const OpenTypeMAXP *maxp = file->maxp;

  if (!out->WriteU32(maxp->version_1 ? 0x00010000 : 0x00005000) ||
      !out->WriteU16(maxp->num_glyphs)) {
    return OTS_FAILURE_MSG("Failed to write maxp version or number of glyphs");
  }

  if (!maxp->version_1) return true;

  if (!out->WriteU16(maxp->max_points) ||
      !out->WriteU16(maxp->max_contours) ||
      !out->WriteU16(maxp->max_c_points) ||
      !out->WriteU16(maxp->max_c_contours)) {
    return OTS_FAILURE_MSG("Failed to write maxp");
  }

  if (!out->WriteU16(maxp->max_zones) ||
      !out->WriteU16(maxp->max_t_points) ||
      !out->WriteU16(maxp->max_storage) ||
      !out->WriteU16(maxp->max_fdefs) ||
      !out->WriteU16(maxp->max_idefs) ||
      !out->WriteU16(maxp->max_stack) ||
      !out->WriteU16(maxp->max_size_glyf_instructions)) {
    return OTS_FAILURE_MSG("Failed to write more maxp");
  }

  if (!out->WriteU16(maxp->max_c_components) ||
      !out->WriteU16(maxp->max_c_depth)) {
    return OTS_FAILURE_MSG("Failed to write yet more maxp");
  }

  return true;
}

void ots_maxp_free(OpenTypeFile *file) {
  delete file->maxp;
}

}  // namespace ots

#undef TABLE_NAME
