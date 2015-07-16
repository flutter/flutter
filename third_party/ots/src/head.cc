// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "head.h"

#include <cstring>

// head - Font Header
// http://www.microsoft.com/typography/otspec/head.htm

#define TABLE_NAME "head"

namespace ots {

bool ots_head_parse(OpenTypeFile *file, const uint8_t *data, size_t length) {
  Buffer table(data, length);
  file->head = new OpenTypeHEAD;

  uint32_t version = 0;
  if (!table.ReadU32(&version) ||
      !table.ReadU32(&file->head->revision)) {
    return OTS_FAILURE_MSG("Failed to read head header");
  }

  if (version >> 16 != 1) {
    return OTS_FAILURE_MSG("Bad head table version of %d", version);
  }

  // Skip the checksum adjustment
  if (!table.Skip(4)) {
    return OTS_FAILURE_MSG("Failed to read checksum");
  }

  uint32_t magic;
  if (!table.ReadTag(&magic) ||
      std::memcmp(&magic, "\x5F\x0F\x3C\xF5", 4)) {
    return OTS_FAILURE_MSG("Failed to read font magic number");
  }

  if (!table.ReadU16(&file->head->flags)) {
    return OTS_FAILURE_MSG("Failed to read head flags");
  }

  // We allow bits 0..4, 11..13
  file->head->flags &= 0x381f;

  if (!table.ReadU16(&file->head->ppem)) {
    return OTS_FAILURE_MSG("Failed to read pixels per em");
  }

  // ppem must be in range
  if (file->head->ppem < 16 ||
      file->head->ppem > 16384) {
    return OTS_FAILURE_MSG("Bad ppm of %d", file->head->ppem);
  }

  // ppem must be a power of two
#if 0
  // We don't call ots_failure() for now since lots of TrueType fonts are
  // not following this rule. Putting OTS_WARNING here is too noisy.
  if ((file->head->ppem - 1) & file->head->ppem) {
    return OTS_FAILURE_MSG("ppm not a power of two: %d", file->head->ppem);
  }
#endif

  if (!table.ReadR64(&file->head->created) ||
      !table.ReadR64(&file->head->modified)) {
    return OTS_FAILURE_MSG("Can't read font dates");
  }

  if (!table.ReadS16(&file->head->xmin) ||
      !table.ReadS16(&file->head->ymin) ||
      !table.ReadS16(&file->head->xmax) ||
      !table.ReadS16(&file->head->ymax)) {
    return OTS_FAILURE_MSG("Failed to read font bounding box");
  }

  if (file->head->xmin > file->head->xmax) {
    return OTS_FAILURE_MSG("Bad x dimension in the font bounding box (%d, %d)", file->head->xmin, file->head->xmax);
  }
  if (file->head->ymin > file->head->ymax) {
    return OTS_FAILURE_MSG("Bad y dimension in the font bounding box (%d, %d)", file->head->ymin, file->head->ymax);
  }

  if (!table.ReadU16(&file->head->mac_style)) {
    return OTS_FAILURE_MSG("Failed to read font style");
  }

  // We allow bits 0..6
  file->head->mac_style &= 0x7f;

  if (!table.ReadU16(&file->head->min_ppem)) {
    return OTS_FAILURE_MSG("Failed to read font minimum ppm");
  }

  // We don't care about the font direction hint
  if (!table.Skip(2)) {
    return OTS_FAILURE_MSG("Failed to skip font direction hint");
  }

  if (!table.ReadS16(&file->head->index_to_loc_format)) {
    return OTS_FAILURE_MSG("Failed to read index to loc format");
  }
  if (file->head->index_to_loc_format < 0 ||
      file->head->index_to_loc_format > 1) {
    return OTS_FAILURE_MSG("Bad index to loc format %d", file->head->index_to_loc_format);
  }

  int16_t glyph_data_format;
  if (!table.ReadS16(&glyph_data_format) ||
      glyph_data_format) {
    return OTS_FAILURE_MSG("Failed to read glyph data format");
  }

  return true;
}

bool ots_head_should_serialise(OpenTypeFile *file) {
  return file->head != NULL;
}

bool ots_head_serialise(OTSStream *out, OpenTypeFile *file) {
  if (!out->WriteU32(0x00010000) ||
      !out->WriteU32(file->head->revision) ||
      !out->WriteU32(0) ||  // check sum not filled in yet
      !out->WriteU32(0x5F0F3CF5) ||
      !out->WriteU16(file->head->flags) ||
      !out->WriteU16(file->head->ppem) ||
      !out->WriteR64(file->head->created) ||
      !out->WriteR64(file->head->modified) ||
      !out->WriteS16(file->head->xmin) ||
      !out->WriteS16(file->head->ymin) ||
      !out->WriteS16(file->head->xmax) ||
      !out->WriteS16(file->head->ymax) ||
      !out->WriteU16(file->head->mac_style) ||
      !out->WriteU16(file->head->min_ppem) ||
      !out->WriteS16(2) ||
      !out->WriteS16(file->head->index_to_loc_format) ||
      !out->WriteS16(0)) {
    return OTS_FAILURE_MSG("Failed to write head table");
  }

  return true;
}

void ots_head_free(OpenTypeFile *file) {
  delete file->head;
}

}  // namespace

#undef TABLE_NAME
