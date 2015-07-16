// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vdmx.h"

// VDMX - Vertical Device Metrics
// http://www.microsoft.com/typography/otspec/vdmx.htm

#define TABLE_NAME "VDMX"

#define DROP_THIS_TABLE(...) \
  do { \
    OTS_FAILURE_MSG_(file, TABLE_NAME ": " __VA_ARGS__); \
    OTS_FAILURE_MSG("Table discarded"); \
    delete file->vdmx; \
    file->vdmx = 0; \
  } while (0)

namespace ots {

bool ots_vdmx_parse(OpenTypeFile *file, const uint8_t *data, size_t length) {
  Buffer table(data, length);
  file->vdmx = new OpenTypeVDMX;
  OpenTypeVDMX * const vdmx = file->vdmx;

  if (!table.ReadU16(&vdmx->version) ||
      !table.ReadU16(&vdmx->num_recs) ||
      !table.ReadU16(&vdmx->num_ratios)) {
    return OTS_FAILURE_MSG("Failed to read table header");
  }

  if (vdmx->version > 1) {
    DROP_THIS_TABLE("bad version: %u", vdmx->version);
    return true;  // continue transcoding
  }

  vdmx->rat_ranges.reserve(vdmx->num_ratios);
  for (unsigned i = 0; i < vdmx->num_ratios; ++i) {
    OpenTypeVDMXRatioRecord rec;

    if (!table.ReadU8(&rec.charset) ||
        !table.ReadU8(&rec.x_ratio) ||
        !table.ReadU8(&rec.y_start_ratio) ||
        !table.ReadU8(&rec.y_end_ratio)) {
      return OTS_FAILURE_MSG("Failed to read ratio header %d", i);
    }

    if (rec.charset > 1) {
      DROP_THIS_TABLE("bad charset: %u", rec.charset);
      return true;
    }

    if (rec.y_start_ratio > rec.y_end_ratio) {
      DROP_THIS_TABLE("bad y ratio");
      return true;
    }

    // All values set to zero signal the default grouping to use;
    // if present, this must be the last Ratio group in the table.
    if ((i < vdmx->num_ratios - 1u) &&
        (rec.x_ratio == 0) &&
        (rec.y_start_ratio == 0) &&
        (rec.y_end_ratio == 0)) {
      // workaround for fonts which have 2 or more {0, 0, 0} terminators.
      DROP_THIS_TABLE("superfluous terminator found");
      return true;
    }

    vdmx->rat_ranges.push_back(rec);
  }

  vdmx->offsets.reserve(vdmx->num_ratios);
  const size_t current_offset = table.offset();
  // current_offset is less than (2 bytes * 3) + (4 bytes * USHRT_MAX) = 256k.
  for (unsigned i = 0; i < vdmx->num_ratios; ++i) {
    uint16_t offset;
    if (!table.ReadU16(&offset)) {
      return OTS_FAILURE_MSG("Failed to read ratio offset %d", i);
    }
    if (current_offset + offset >= length) {  // thus doesn't overflow.
      return OTS_FAILURE_MSG("Bad ratio offset %d for ration %d", offset, i);
    }

    vdmx->offsets.push_back(offset);
  }

  vdmx->groups.reserve(vdmx->num_recs);
  for (unsigned i = 0; i < vdmx->num_recs; ++i) {
    OpenTypeVDMXGroup group;
    if (!table.ReadU16(&group.recs) ||
        !table.ReadU8(&group.startsz) ||
        !table.ReadU8(&group.endsz)) {
      return OTS_FAILURE_MSG("Failed to read record header %d", i);
    }
    group.entries.reserve(group.recs);
    for (unsigned j = 0; j < group.recs; ++j) {
      OpenTypeVDMXVTable vt;
      if (!table.ReadU16(&vt.y_pel_height) ||
          !table.ReadS16(&vt.y_max) ||
          !table.ReadS16(&vt.y_min)) {
        return OTS_FAILURE_MSG("Failed to read reacord %d group %d", i, j);
      }
      if (vt.y_max < vt.y_min) {
        DROP_THIS_TABLE("bad y min/max");
        return true;
      }

      // This table must appear in sorted order (sorted by yPelHeight),
      // but need not be continuous.
      if ((j != 0) && (group.entries[j - 1].y_pel_height >= vt.y_pel_height)) {
        DROP_THIS_TABLE("the table is not sorted");
        return true;
      }

      group.entries.push_back(vt);
    }
    vdmx->groups.push_back(group);
  }

  return true;
}

bool ots_vdmx_should_serialise(OpenTypeFile *file) {
  if (!file->glyf) return false;  // this table is not for CFF fonts.
  return file->vdmx != NULL;
}

bool ots_vdmx_serialise(OTSStream *out, OpenTypeFile *file) {
  OpenTypeVDMX * const vdmx = file->vdmx;

  if (!out->WriteU16(vdmx->version) ||
      !out->WriteU16(vdmx->num_recs) ||
      !out->WriteU16(vdmx->num_ratios)) {
    return OTS_FAILURE_MSG("Failed to write table header");
  }

  for (unsigned i = 0; i < vdmx->rat_ranges.size(); ++i) {
    const OpenTypeVDMXRatioRecord& rec = vdmx->rat_ranges[i];
    if (!out->Write(&rec.charset, 1) ||
        !out->Write(&rec.x_ratio, 1) ||
        !out->Write(&rec.y_start_ratio, 1) ||
        !out->Write(&rec.y_end_ratio, 1)) {
      return OTS_FAILURE_MSG("Failed to write ratio %d", i);
    }
  }

  for (unsigned i = 0; i < vdmx->offsets.size(); ++i) {
    if (!out->WriteU16(vdmx->offsets[i])) {
      return OTS_FAILURE_MSG("Failed to write ratio offset %d", i);
    }
  }

  for (unsigned i = 0; i < vdmx->groups.size(); ++i) {
    const OpenTypeVDMXGroup& group = vdmx->groups[i];
    if (!out->WriteU16(group.recs) ||
        !out->Write(&group.startsz, 1) ||
        !out->Write(&group.endsz, 1)) {
      return OTS_FAILURE_MSG("Failed to write group %d", i);
    }
    for (unsigned j = 0; j < group.entries.size(); ++j) {
      const OpenTypeVDMXVTable& vt = group.entries[j];
      if (!out->WriteU16(vt.y_pel_height) ||
          !out->WriteS16(vt.y_max) ||
          !out->WriteS16(vt.y_min)) {
        return OTS_FAILURE_MSG("Failed to write group %d entry %d", i, j);
      }
    }
  }

  return true;
}

void ots_vdmx_free(OpenTypeFile *file) {
  delete file->vdmx;
}

}  // namespace ots

#undef TABLE_NAME
#undef DROP_THIS_TABLE
