// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gdef.h"

#include <limits>
#include <vector>

#include "gpos.h"
#include "gsub.h"
#include "layout.h"
#include "maxp.h"

// GDEF - The Glyph Definition Table
// http://www.microsoft.com/typography/otspec/gdef.htm

#define TABLE_NAME "GDEF"

namespace {

// The maximum class value in class definition tables.
const uint16_t kMaxClassDefValue = 0xFFFF;
// The maximum class value in the glyph class definision table.
const uint16_t kMaxGlyphClassDefValue = 4;
// The maximum format number of caret value tables.
// We don't support format 3 for now. See the comment in
// ParseLigCaretListTable() for the reason.
const uint16_t kMaxCaretValueFormat = 2;

bool ParseGlyphClassDefTable(ots::OpenTypeFile *file, const uint8_t *data,
                             size_t length, const uint16_t num_glyphs) {
  return ots::ParseClassDefTable(file, data, length, num_glyphs,
                                 kMaxGlyphClassDefValue);
}

bool ParseAttachListTable(ots::OpenTypeFile *file, const uint8_t *data,
                          size_t length, const uint16_t num_glyphs) {
  ots::Buffer subtable(data, length);

  uint16_t offset_coverage = 0;
  uint16_t glyph_count = 0;
  if (!subtable.ReadU16(&offset_coverage) ||
      !subtable.ReadU16(&glyph_count)) {
    return OTS_FAILURE_MSG("Failed to read gdef header");
  }
  const unsigned attach_points_end =
      2 * static_cast<unsigned>(glyph_count) + 4;
  if (attach_points_end > std::numeric_limits<uint16_t>::max()) {
    return OTS_FAILURE_MSG("Bad glyph count in gdef");
  }
  if (offset_coverage == 0 || offset_coverage >= length ||
      offset_coverage < attach_points_end) {
    return OTS_FAILURE_MSG("Bad coverage offset %d", offset_coverage);
  }
  if (glyph_count > num_glyphs) {
    return OTS_FAILURE_MSG("Bad glyph count %u", glyph_count);
  }

  std::vector<uint16_t> attach_points;
  attach_points.resize(glyph_count);
  for (unsigned i = 0; i < glyph_count; ++i) {
    if (!subtable.ReadU16(&attach_points[i])) {
      return OTS_FAILURE_MSG("Can't read attachment point %d", i);
    }
    if (attach_points[i] >= length ||
        attach_points[i] < attach_points_end) {
      return OTS_FAILURE_MSG("Bad attachment point %d of %d", i, attach_points[i]);
    }
  }

  // Parse coverage table
  if (!ots::ParseCoverageTable(file, data + offset_coverage,
                               length - offset_coverage, num_glyphs)) {
    return OTS_FAILURE_MSG("Bad coverage table");
  }

  // Parse attach point table
  for (unsigned i = 0; i < attach_points.size(); ++i) {
    subtable.set_offset(attach_points[i]);
    uint16_t point_count = 0;
    if (!subtable.ReadU16(&point_count)) {
      return OTS_FAILURE_MSG("Can't read point count %d", i);
    }
    if (point_count == 0) {
      return OTS_FAILURE_MSG("zero point count %d", i);
    }
    uint16_t last_point_index = 0;
    uint16_t point_index = 0;
    for (unsigned j = 0; j < point_count; ++j) {
      if (!subtable.ReadU16(&point_index)) {
        return OTS_FAILURE_MSG("Can't read point index %d in point %d", j, i);
      }
      // Contour point indeces are in increasing numerical order
      if (last_point_index != 0 && last_point_index >= point_index) {
        return OTS_FAILURE_MSG("bad contour indeces: %u >= %u",
                    last_point_index, point_index);
      }
      last_point_index = point_index;
    }
  }
  return true;
}

bool ParseLigCaretListTable(ots::OpenTypeFile *file, const uint8_t *data,
                            size_t length, const uint16_t num_glyphs) {
  ots::Buffer subtable(data, length);
  uint16_t offset_coverage = 0;
  uint16_t lig_glyph_count = 0;
  if (!subtable.ReadU16(&offset_coverage) ||
      !subtable.ReadU16(&lig_glyph_count)) {
    return OTS_FAILURE_MSG("Can't read caret structure");
  }
  const unsigned lig_glyphs_end =
      2 * static_cast<unsigned>(lig_glyph_count) + 4;
  if (lig_glyphs_end > std::numeric_limits<uint16_t>::max()) {
    return OTS_FAILURE_MSG("Bad caret structure");
  }
  if (offset_coverage == 0 || offset_coverage >= length ||
      offset_coverage < lig_glyphs_end) {
    return OTS_FAILURE_MSG("Bad caret coverate offset %d", offset_coverage);
  }
  if (lig_glyph_count > num_glyphs) {
    return OTS_FAILURE_MSG("bad ligature glyph count: %u", lig_glyph_count);
  }

  std::vector<uint16_t> lig_glyphs;
  lig_glyphs.resize(lig_glyph_count);
  for (unsigned i = 0; i < lig_glyph_count; ++i) {
    if (!subtable.ReadU16(&lig_glyphs[i])) {
      return OTS_FAILURE_MSG("Can't read ligature glyph location %d", i);
    }
    if (lig_glyphs[i] >= length || lig_glyphs[i] < lig_glyphs_end) {
      return OTS_FAILURE_MSG("Bad ligature glyph location %d in glyph %d", lig_glyphs[i], i);
    }
  }

  // Parse coverage table
  if (!ots::ParseCoverageTable(file, data + offset_coverage,
                               length - offset_coverage, num_glyphs)) {
    return OTS_FAILURE_MSG("Can't parse caret coverage table");
  }

  // Parse ligature glyph table
  for (unsigned i = 0; i < lig_glyphs.size(); ++i) {
    subtable.set_offset(lig_glyphs[i]);
    uint16_t caret_count = 0;
    if (!subtable.ReadU16(&caret_count)) {
      return OTS_FAILURE_MSG("Can't read caret count for glyph %d", i);
    }
    if (caret_count == 0) {
      return OTS_FAILURE_MSG("bad caret value count: %u", caret_count);
    }

    std::vector<uint16_t> caret_value_offsets;
    caret_value_offsets.resize(caret_count);
    unsigned caret_value_offsets_end = 2 * static_cast<unsigned>(caret_count) + 2;
    for (unsigned j = 0; j < caret_count; ++j) {
      if (!subtable.ReadU16(&caret_value_offsets[j])) {
        return OTS_FAILURE_MSG("Can't read caret offset %d for glyph %d", j, i);
      }
      if (caret_value_offsets[j] >= length || caret_value_offsets[j] < caret_value_offsets_end) {
        return OTS_FAILURE_MSG("Bad caret offset %d for caret %d glyph %d", caret_value_offsets[j], j, i);
      }
    }

    // Parse caret values table
    for (unsigned j = 0; j < caret_count; ++j) {
      subtable.set_offset(lig_glyphs[i] + caret_value_offsets[j]);
      uint16_t caret_format = 0;
      if (!subtable.ReadU16(&caret_format)) {
        return OTS_FAILURE_MSG("Can't read caret values table %d in glyph %d", j, i);
      }
      // TODO(bashi): We only support caret value format 1 and 2 for now
      // because there are no fonts which contain caret value format 3
      // as far as we investigated.
      if (caret_format == 0 || caret_format > kMaxCaretValueFormat) {
        return OTS_FAILURE_MSG("bad caret value format: %u", caret_format);
      }
      // CaretValueFormats contain a 2-byte field which could be
      // arbitrary value.
      if (!subtable.Skip(2)) {
        return OTS_FAILURE_MSG("Bad caret value table structure %d in glyph %d", j, i);
      }
    }
  }
  return true;
}

bool ParseMarkAttachClassDefTable(ots::OpenTypeFile *file, const uint8_t *data,
                                  size_t length, const uint16_t num_glyphs) {
  return ots::ParseClassDefTable(file, data, length, num_glyphs, kMaxClassDefValue);
}

bool ParseMarkGlyphSetsDefTable(ots::OpenTypeFile *file, const uint8_t *data,
                                size_t length, const uint16_t num_glyphs) {
  ots::Buffer subtable(data, length);
  uint16_t format = 0;
  uint16_t mark_set_count = 0;
  if (!subtable.ReadU16(&format) ||
      !subtable.ReadU16(&mark_set_count)) {
    return OTS_FAILURE_MSG("Can' read mark glyph table structure");
  }
  if (format != 1) {
    return OTS_FAILURE_MSG("bad mark glyph set table format: %u", format);
  }

  const unsigned mark_sets_end = 2 * static_cast<unsigned>(mark_set_count) + 4;
  if (mark_sets_end > std::numeric_limits<uint16_t>::max()) {
    return OTS_FAILURE_MSG("Bad mark_set %d", mark_sets_end);
  }
  for (unsigned i = 0; i < mark_set_count; ++i) {
    uint32_t offset_coverage = 0;
    if (!subtable.ReadU32(&offset_coverage)) {
      return OTS_FAILURE_MSG("Can't read covrage location for mark set %d", i);
    }
    if (offset_coverage >= length ||
        offset_coverage < mark_sets_end) {
      return OTS_FAILURE_MSG("Bad coverage location %d for mark set %d", offset_coverage, i);
    }
    if (!ots::ParseCoverageTable(file, data + offset_coverage,
                                 length - offset_coverage, num_glyphs)) {
      return OTS_FAILURE_MSG("Failed to parse coverage table for mark set %d", i);
    }
  }
  file->gdef->num_mark_glyph_sets = mark_set_count;
  return true;
}

}  // namespace

#define DROP_THIS_TABLE(msg_) \
  do { \
    OTS_FAILURE_MSG(msg_ ", table discarded"); \
    file->gdef->data = 0; \
    file->gdef->length = 0; \
  } while (0)

namespace ots {

bool ots_gdef_parse(OpenTypeFile *file, const uint8_t *data, size_t length) {
  // Grab the number of glyphs in the file from the maxp table to check
  // GlyphIDs in GDEF table.
  if (!file->maxp) {
    return OTS_FAILURE_MSG("No maxp table in font, needed by GDEF");
  }
  const uint16_t num_glyphs = file->maxp->num_glyphs;

  Buffer table(data, length);

  OpenTypeGDEF *gdef = new OpenTypeGDEF;
  file->gdef = gdef;

  uint32_t version = 0;
  if (!table.ReadU32(&version)) {
    DROP_THIS_TABLE("Incomplete table");
    return true;
  }
  if (version < 0x00010000 || version == 0x00010001) {
    DROP_THIS_TABLE("Bad version");
    return true;
  }

  if (version >= 0x00010002) {
    gdef->version_2 = true;
  }

  uint16_t offset_glyph_class_def = 0;
  uint16_t offset_attach_list = 0;
  uint16_t offset_lig_caret_list = 0;
  uint16_t offset_mark_attach_class_def = 0;
  if (!table.ReadU16(&offset_glyph_class_def) ||
      !table.ReadU16(&offset_attach_list) ||
      !table.ReadU16(&offset_lig_caret_list) ||
      !table.ReadU16(&offset_mark_attach_class_def)) {
    DROP_THIS_TABLE("Incomplete table");
    return true;
  }
  uint16_t offset_mark_glyph_sets_def = 0;
  if (gdef->version_2) {
    if (!table.ReadU16(&offset_mark_glyph_sets_def)) {
      DROP_THIS_TABLE("Incomplete table");
      return true;
    }
  }

  unsigned gdef_header_end = 4 + 4 * 2;
  if (gdef->version_2)
    gdef_header_end += 2;

  // Parse subtables
  if (offset_glyph_class_def) {
    if (offset_glyph_class_def >= length ||
        offset_glyph_class_def < gdef_header_end) {
      DROP_THIS_TABLE("Invalid offset to glyph classes");
      return true;
    }
    if (!ParseGlyphClassDefTable(file, data + offset_glyph_class_def,
                                 length - offset_glyph_class_def,
                                 num_glyphs)) {
      DROP_THIS_TABLE("Invalid glyph classes");
      return true;
    }
    gdef->has_glyph_class_def = true;
  }

  if (offset_attach_list) {
    if (offset_attach_list >= length ||
        offset_attach_list < gdef_header_end) {
      DROP_THIS_TABLE("Invalid offset to attachment list");
      return true;
    }
    if (!ParseAttachListTable(file, data + offset_attach_list,
                              length - offset_attach_list,
                              num_glyphs)) {
      DROP_THIS_TABLE("Invalid attachment list");
      return true;
    }
  }

  if (offset_lig_caret_list) {
    if (offset_lig_caret_list >= length ||
        offset_lig_caret_list < gdef_header_end) {
      DROP_THIS_TABLE("Invalid offset to ligature caret list");
      return true;
    }
    if (!ParseLigCaretListTable(file, data + offset_lig_caret_list,
                              length - offset_lig_caret_list,
                              num_glyphs)) {
      DROP_THIS_TABLE("Invalid ligature caret list");
      return true;
    }
  }

  if (offset_mark_attach_class_def) {
    if (offset_mark_attach_class_def >= length ||
        offset_mark_attach_class_def < gdef_header_end) {
      return OTS_FAILURE_MSG("Invalid offset to mark attachment list");
    }
    if (!ParseMarkAttachClassDefTable(file,
                                      data + offset_mark_attach_class_def,
                                      length - offset_mark_attach_class_def,
                                      num_glyphs)) {
      DROP_THIS_TABLE("Invalid mark attachment list");
      return true;
    }
    gdef->has_mark_attachment_class_def = true;
  }

  if (offset_mark_glyph_sets_def) {
    if (offset_mark_glyph_sets_def >= length ||
        offset_mark_glyph_sets_def < gdef_header_end) {
      return OTS_FAILURE_MSG("invalid offset to mark glyph sets");
    }
    if (!ParseMarkGlyphSetsDefTable(file,
                                    data + offset_mark_glyph_sets_def,
                                    length - offset_mark_glyph_sets_def,
                                    num_glyphs)) {
      DROP_THIS_TABLE("Invalid mark glyph sets");
      return true;
    }
    gdef->has_mark_glyph_sets_def = true;
  }
  gdef->data = data;
  gdef->length = length;
  return true;
}

bool ots_gdef_should_serialise(OpenTypeFile *file) {
  return file->gdef != NULL && file->gdef->data != NULL;
}

bool ots_gdef_serialise(OTSStream *out, OpenTypeFile *file) {
  if (!out->Write(file->gdef->data, file->gdef->length)) {
    return OTS_FAILURE_MSG("Failed to write GDEF table");
  }

  return true;
}

void ots_gdef_free(OpenTypeFile *file) {
  delete file->gdef;
}

}  // namespace ots

#undef TABLE_NAME
#undef DROP_THIS_TABLE
