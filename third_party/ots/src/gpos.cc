// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpos.h"

#include <limits>
#include <vector>

#include "layout.h"
#include "maxp.h"

// GPOS - The Glyph Positioning Table
// http://www.microsoft.com/typography/otspec/gpos.htm

#define TABLE_NAME "GPOS"

namespace {

enum GPOS_TYPE {
  GPOS_TYPE_SINGLE_ADJUSTMENT = 1,
  GPOS_TYPE_PAIR_ADJUSTMENT = 2,
  GPOS_TYPE_CURSIVE_ATTACHMENT = 3,
  GPOS_TYPE_MARK_TO_BASE_ATTACHMENT = 4,
  GPOS_TYPE_MARK_TO_LIGATURE_ATTACHMENT = 5,
  GPOS_TYPE_MARK_TO_MARK_ATTACHMENT = 6,
  GPOS_TYPE_CONTEXT_POSITIONING = 7,
  GPOS_TYPE_CHAINED_CONTEXT_POSITIONING = 8,
  GPOS_TYPE_EXTENSION_POSITIONING = 9,
  GPOS_TYPE_RESERVED = 10
};

// The size of gpos header.
const unsigned kGposHeaderSize = 10;
// The maximum format number for anchor tables.
const uint16_t kMaxAnchorFormat = 3;
// The maximum number of class value.
const uint16_t kMaxClassDefValue = 0xFFFF;

// Lookup type parsers.
bool ParseSingleAdjustment(const ots::OpenTypeFile *file,
                           const uint8_t *data, const size_t length);
bool ParsePairAdjustment(const ots::OpenTypeFile *file,
                         const uint8_t *data, const size_t length);
bool ParseCursiveAttachment(const ots::OpenTypeFile *file,
                            const uint8_t *data, const size_t length);
bool ParseMarkToBaseAttachment(const ots::OpenTypeFile *file,
                               const uint8_t *data, const size_t length);
bool ParseMarkToLigatureAttachment(const ots::OpenTypeFile *file,
                                   const uint8_t *data, const size_t length);
bool ParseMarkToMarkAttachment(const ots::OpenTypeFile *file,
                               const uint8_t *data, const size_t length);
bool ParseContextPositioning(const ots::OpenTypeFile *file,
                             const uint8_t *data, const size_t length);
bool ParseChainedContextPositioning(const ots::OpenTypeFile *file,
                                    const uint8_t *data, const size_t length);
bool ParseExtensionPositioning(const ots::OpenTypeFile *file,
                               const uint8_t *data, const size_t length);

const ots::LookupSubtableParser::TypeParser kGposTypeParsers[] = {
  {GPOS_TYPE_SINGLE_ADJUSTMENT, ParseSingleAdjustment},
  {GPOS_TYPE_PAIR_ADJUSTMENT, ParsePairAdjustment},
  {GPOS_TYPE_CURSIVE_ATTACHMENT, ParseCursiveAttachment},
  {GPOS_TYPE_MARK_TO_BASE_ATTACHMENT, ParseMarkToBaseAttachment},
  {GPOS_TYPE_MARK_TO_LIGATURE_ATTACHMENT, ParseMarkToLigatureAttachment},
  {GPOS_TYPE_MARK_TO_MARK_ATTACHMENT, ParseMarkToMarkAttachment},
  {GPOS_TYPE_CONTEXT_POSITIONING, ParseContextPositioning},
  {GPOS_TYPE_CHAINED_CONTEXT_POSITIONING, ParseChainedContextPositioning},
  {GPOS_TYPE_EXTENSION_POSITIONING, ParseExtensionPositioning}
};

const ots::LookupSubtableParser kGposLookupSubtableParser = {
  arraysize(kGposTypeParsers),
  GPOS_TYPE_EXTENSION_POSITIONING, kGposTypeParsers
};

// Shared Tables: ValueRecord, Anchor Table, and MarkArray

bool ParseValueRecord(const ots::OpenTypeFile *file,
                      ots::Buffer* subtable, const uint8_t *data,
                      const size_t length, const uint16_t value_format) {
  // Check existence of adjustment fields.
  for (unsigned i = 0; i < 4; ++i) {
    if ((value_format >> i) & 0x1) {
      // Just read the field since these fileds could take an arbitrary values.
      if (!subtable->Skip(2)) {
        return OTS_FAILURE_MSG("Failed to read value reacord component");
      }
    }
  }

  // Check existence of offsets to device table.
  for (unsigned i = 0; i < 4; ++i) {
    if ((value_format >> (i + 4)) & 0x1) {
      uint16_t offset = 0;
      if (!subtable->ReadU16(&offset)) {
        return OTS_FAILURE_MSG("Failed to read value record offset");
      }
      if (offset) {
        // TODO(bashi): Is it possible that device tables locate before
        // this record? No fonts contain such offset AKAIF.
        if (offset >= length) {
          return OTS_FAILURE_MSG("Value record offset too high %d >= %ld", offset, length);
        }
        if (!ots::ParseDeviceTable(file, data + offset, length - offset)) {
          return OTS_FAILURE_MSG("Failed to parse device table in value record");
        }
      }
    }
  }
  return true;
}

bool ParseAnchorTable(const ots::OpenTypeFile *file,
                      const uint8_t *data, const size_t length) {
  ots::Buffer subtable(data, length);

  uint16_t format = 0;
  // Read format and skip 2 2-byte fields that could be arbitrary values.
  if (!subtable.ReadU16(&format) ||
      !subtable.Skip(4)) {
    return OTS_FAILURE_MSG("Faled to read anchor table");
  }

  if (format == 0 || format > kMaxAnchorFormat) {
    return OTS_FAILURE_MSG("Bad Anchor table format %d", format);
  }

  // Format 2 and 3 has additional fields.
  if (format == 2) {
    // Format 2 provides an index to a glyph contour point, which will take
    // arbitrary value.
    uint16_t anchor_point = 0;
    if (!subtable.ReadU16(&anchor_point)) {
      return OTS_FAILURE_MSG("Failed to read anchor point in format 2 Anchor Table");
    }
  } else if (format == 3) {
    uint16_t offset_x_device = 0;
    uint16_t offset_y_device = 0;
    if (!subtable.ReadU16(&offset_x_device) ||
        !subtable.ReadU16(&offset_y_device)) {
      return OTS_FAILURE_MSG("Failed to read device table offsets in format 3 anchor table");
    }
    const unsigned format_end = static_cast<unsigned>(10);
    if (offset_x_device) {
      if (offset_x_device < format_end || offset_x_device >= length) {
        return OTS_FAILURE_MSG("Bad x device table offset %d", offset_x_device);
      }
      if (!ots::ParseDeviceTable(file, data + offset_x_device,
                                 length - offset_x_device)) {
        return OTS_FAILURE_MSG("Failed to parse device table in anchor table");
      }
    }
    if (offset_y_device) {
      if (offset_y_device < format_end || offset_y_device >= length) {
        return OTS_FAILURE_MSG("Bad y device table offset %d", offset_y_device);
      }
      if (!ots::ParseDeviceTable(file, data + offset_y_device,
                                 length - offset_y_device)) {
        return OTS_FAILURE_MSG("Failed to parse device table in anchor table");
      }
    }
  }
  return true;
}

bool ParseMarkArrayTable(const ots::OpenTypeFile *file,
                         const uint8_t *data, const size_t length,
                         const uint16_t class_count) {
  ots::Buffer subtable(data, length);

  uint16_t mark_count = 0;
  if (!subtable.ReadU16(&mark_count)) {
    return OTS_FAILURE_MSG("Can't read mark table length");
  }

  // MarkRecord consists of 4-bytes.
  const unsigned mark_records_end = 4 * static_cast<unsigned>(mark_count) + 2;
  if (mark_records_end > std::numeric_limits<uint16_t>::max()) {
    return OTS_FAILURE_MSG("Bad mark table length");
  }
  for (unsigned i = 0; i < mark_count; ++i) {
    uint16_t class_value = 0;
    uint16_t offset_mark_anchor = 0;
    if (!subtable.ReadU16(&class_value) ||
        !subtable.ReadU16(&offset_mark_anchor)) {
      return OTS_FAILURE_MSG("Can't read mark table %d", i);
    }
    // |class_value| may take arbitrary values including 0 here so we don't
    // check the value.
    if (offset_mark_anchor < mark_records_end ||
        offset_mark_anchor >= length) {
      return OTS_FAILURE_MSG("Bad mark anchor offset %d for mark table %d", offset_mark_anchor, i);
    }
    if (!ParseAnchorTable(file, data + offset_mark_anchor,
                          length - offset_mark_anchor)) {
      return OTS_FAILURE_MSG("Faled to parse anchor table for mark table %d", i);
    }
  }

  return true;
}

// Lookup Type 1:
// Single Adjustment Positioning Subtable
bool ParseSingleAdjustment(const ots::OpenTypeFile *file, const uint8_t *data,
                           const size_t length) {
  ots::Buffer subtable(data, length);

  uint16_t format = 0;
  uint16_t offset_coverage = 0;
  uint16_t value_format = 0;
  if (!subtable.ReadU16(&format) ||
      !subtable.ReadU16(&offset_coverage) ||
      !subtable.ReadU16(&value_format)) {
    return OTS_FAILURE_MSG("Can't read single adjustment information");
  }

  if (format == 1) {
    // Format 1 exactly one value record.
    if (!ParseValueRecord(file, &subtable, data, length, value_format)) {
      return OTS_FAILURE_MSG("Failed to parse format 1 single adjustment table");
    }
  } else if (format == 2) {
    uint16_t value_count = 0;
    if (!subtable.ReadU16(&value_count)) {
      return OTS_FAILURE_MSG("Failed to parse format 2 single adjustment table");
    }
    for (unsigned i = 0; i < value_count; ++i) {
      if (!ParseValueRecord(file, &subtable, data, length, value_format)) {
        return OTS_FAILURE_MSG("Failed to parse value record %d in format 2 single adjustment table", i);
      }
    }
  } else {
    return OTS_FAILURE_MSG("Bad format %d in single adjustment table", format);
  }

  if (offset_coverage < subtable.offset() || offset_coverage >= length) {
    return OTS_FAILURE_MSG("Bad coverage offset %d in single adjustment table", offset_coverage);
  }

  if (!ots::ParseCoverageTable(file, data + offset_coverage,
                               length - offset_coverage,
                               file->maxp->num_glyphs)) {
    return OTS_FAILURE_MSG("Failed to parse coverage table in single adjustment table");
  }

  return true;
}

bool ParsePairSetTable(const ots::OpenTypeFile *file,
                       const uint8_t *data, const size_t length,
                       const uint16_t value_format1,
                       const uint16_t value_format2,
                       const uint16_t num_glyphs) {
  ots::Buffer subtable(data, length);

  uint16_t value_count = 0;
  if (!subtable.ReadU16(&value_count)) {
    return OTS_FAILURE_MSG("Failed to read pair set table structure");
  }
  for (unsigned i = 0; i < value_count; ++i) {
    // Check pair value record.
    uint16_t glyph_id = 0;
    if (!subtable.ReadU16(&glyph_id)) {
      return OTS_FAILURE_MSG("Failed to read glyph in pair value record %d", i);
    }
    if (glyph_id >= num_glyphs) {
      return OTS_FAILURE_MSG("glyph id %d too high >= %d", glyph_id, num_glyphs);
    }
    if (!ParseValueRecord(file, &subtable, data, length, value_format1)) {
      return OTS_FAILURE_MSG("Failed to parse value record in format 1 pair set table");
    }
    if (!ParseValueRecord(file, &subtable, data, length, value_format2)) {
      return OTS_FAILURE_MSG("Failed to parse value record in format 2 pair set table");
    }
  }
  return true;
}

bool ParsePairPosFormat1(const ots::OpenTypeFile *file,
                         const uint8_t *data, const size_t length,
                         const uint16_t value_format1,
                         const uint16_t value_format2,
                         const uint16_t num_glyphs) {
  ots::Buffer subtable(data, length);

  // Skip 8 bytes that are already read before.
  if (!subtable.Skip(8)) {
    return OTS_FAILURE_MSG("Failed to read pair pos table structure");
  }

  uint16_t pair_set_count = 0;
  if (!subtable.ReadU16(&pair_set_count)) {
    return OTS_FAILURE_MSG("Failed to read pair pos set count");
  }

  const unsigned pair_pos_end = 2 * static_cast<unsigned>(pair_set_count) + 10;
  if (pair_pos_end > std::numeric_limits<uint16_t>::max()) {
    return OTS_FAILURE_MSG("Bad pair set length %d", pair_pos_end);
  }
  for (unsigned i = 0; i < pair_set_count; ++i) {
    uint16_t pair_set_offset = 0;
    if (!subtable.ReadU16(&pair_set_offset)) {
      return OTS_FAILURE_MSG("Failed to read pair set offset for pair set %d", i);
    }
    if (pair_set_offset < pair_pos_end || pair_set_offset >= length) {
      return OTS_FAILURE_MSG("Bad pair set offset %d for pair set %d", pair_set_offset, i);
    }
    // Check pair set tables
    if (!ParsePairSetTable(file, data + pair_set_offset, length - pair_set_offset,
                           value_format1, value_format2,
                           num_glyphs)) {
      return OTS_FAILURE_MSG("Failed to parse pair set table %d", i);
    }
  }

  return true;
}

bool ParsePairPosFormat2(const ots::OpenTypeFile *file,
                         const uint8_t *data, const size_t length,
                         const uint16_t value_format1,
                         const uint16_t value_format2,
                         const uint16_t num_glyphs) {
  ots::Buffer subtable(data, length);

  // Skip 8 bytes that are already read before.
  if (!subtable.Skip(8)) {
    return OTS_FAILURE_MSG("Failed to read pair pos format 2 structure");
  }

  uint16_t offset_class_def1 = 0;
  uint16_t offset_class_def2 = 0;
  uint16_t class1_count = 0;
  uint16_t class2_count = 0;
  if (!subtable.ReadU16(&offset_class_def1) ||
      !subtable.ReadU16(&offset_class_def2) ||
      !subtable.ReadU16(&class1_count) ||
      !subtable.ReadU16(&class2_count)) {
    return OTS_FAILURE_MSG("Failed to read pair pos format 2 data");
  }

  // Check class 1 records.
  for (unsigned i = 0; i < class1_count; ++i) {
    // Check class 2 records.
    for (unsigned j = 0; j < class2_count; ++j) {
      if (value_format1 && !ParseValueRecord(file, &subtable, data, length,
                                             value_format1)) {
        return OTS_FAILURE_MSG("Failed to parse value record 1 %d and %d", j, i);
      }
      if (value_format2 && !ParseValueRecord(file, &subtable, data, length,
                                             value_format2)) {
        return OTS_FAILURE_MSG("Falied to parse value record 2 %d and %d", j, i);
      }
    }
  }

  // Check class definition tables.
  if (offset_class_def1 < subtable.offset() || offset_class_def1 >= length ||
      offset_class_def2 < subtable.offset() || offset_class_def2 >= length) {
    return OTS_FAILURE_MSG("Bad class definition table offsets %d or %d", offset_class_def1, offset_class_def2);
  }
  if (!ots::ParseClassDefTable(file, data + offset_class_def1,
                               length - offset_class_def1,
                               num_glyphs, kMaxClassDefValue)) {
    return OTS_FAILURE_MSG("Failed to parse class definition table 1");
  }
  if (!ots::ParseClassDefTable(file, data + offset_class_def2,
                               length - offset_class_def2,
                               num_glyphs, kMaxClassDefValue)) {
    return OTS_FAILURE_MSG("Failed to parse class definition table 2");
  }

  return true;
}

// Lookup Type 2:
// Pair Adjustment Positioning Subtable
bool ParsePairAdjustment(const ots::OpenTypeFile *file, const uint8_t *data,
                         const size_t length) {
  ots::Buffer subtable(data, length);

  uint16_t format = 0;
  uint16_t offset_coverage = 0;
  uint16_t value_format1 = 0;
  uint16_t value_format2 = 0;
  if (!subtable.ReadU16(&format) ||
      !subtable.ReadU16(&offset_coverage) ||
      !subtable.ReadU16(&value_format1) ||
      !subtable.ReadU16(&value_format2)) {
    return OTS_FAILURE_MSG("Failed to read pair adjustment structure");
  }

  if (format == 1) {
    if (!ParsePairPosFormat1(file, data, length, value_format1, value_format2,
                             file->maxp->num_glyphs)) {
      return OTS_FAILURE_MSG("Failed to parse pair pos format 1");
    }
  } else if (format == 2) {
    if (!ParsePairPosFormat2(file, data, length, value_format1, value_format2,
                             file->maxp->num_glyphs)) {
      return OTS_FAILURE_MSG("Failed to parse pair format 2");
    }
  } else {
    return OTS_FAILURE_MSG("Bad pos pair format %d", format);
  }

  if (offset_coverage < subtable.offset() || offset_coverage >= length) {
    return OTS_FAILURE_MSG("Bad pair pos offset coverage %d", offset_coverage);
  }
  if (!ots::ParseCoverageTable(file, data + offset_coverage,
                               length - offset_coverage,
                               file->maxp->num_glyphs)) {
    return OTS_FAILURE_MSG("Failed to parse coverage table");
  }

  return true;
}

// Lookup Type 3
// Cursive Attachment Positioning Subtable
bool ParseCursiveAttachment(const ots::OpenTypeFile *file, const uint8_t *data,
                            const size_t length) {
  ots::Buffer subtable(data, length);

  uint16_t format = 0;
  uint16_t offset_coverage = 0;
  uint16_t entry_exit_count = 0;
  if (!subtable.ReadU16(&format) ||
      !subtable.ReadU16(&offset_coverage) ||
      !subtable.ReadU16(&entry_exit_count)) {
    return OTS_FAILURE_MSG("Failed to read cursive attachment structure");
  }

  if (format != 1) {
    return OTS_FAILURE_MSG("Bad cursive attachment format %d", format);
  }

  // Check entry exit records.
  const unsigned entry_exit_records_end =
      2 * static_cast<unsigned>(entry_exit_count) + 6;
  if (entry_exit_records_end > std::numeric_limits<uint16_t>::max()) {
    return OTS_FAILURE_MSG("Bad entry exit record end %d", entry_exit_records_end);
  }
  for (unsigned i = 0; i < entry_exit_count; ++i) {
    uint16_t offset_entry_anchor = 0;
    uint16_t offset_exit_anchor = 0;
    if (!subtable.ReadU16(&offset_entry_anchor) ||
        !subtable.ReadU16(&offset_exit_anchor)) {
      return OTS_FAILURE_MSG("Can't read entry exit record %d", i);
    }
    // These offsets could be NULL.
    if (offset_entry_anchor) {
      if (offset_entry_anchor < entry_exit_records_end ||
          offset_entry_anchor >= length) {
        return OTS_FAILURE_MSG("Bad entry anchor offset %d in entry exit record %d", offset_entry_anchor, i);
      }
      if (!ParseAnchorTable(file, data + offset_entry_anchor,
                            length - offset_entry_anchor)) {
        return OTS_FAILURE_MSG("Failed to parse entry anchor table in entry exit record %d", i);
      }
    }
    if (offset_exit_anchor) {
      if (offset_exit_anchor < entry_exit_records_end ||
         offset_exit_anchor >= length) {
        return OTS_FAILURE_MSG("Bad exit anchor offset %d in entry exit record %d", offset_exit_anchor, i);
      }
      if (!ParseAnchorTable(file, data + offset_exit_anchor,
                            length - offset_exit_anchor)) {
        return OTS_FAILURE_MSG("Failed to parse exit anchor table in entry exit record %d", i);
      }
    }
  }

  if (offset_coverage < subtable.offset() || offset_coverage >= length) {
    return OTS_FAILURE_MSG("Bad coverage offset in cursive attachment %d", offset_coverage);
  }
  if (!ots::ParseCoverageTable(file, data + offset_coverage,
                               length - offset_coverage,
                               file->maxp->num_glyphs)) {
    return OTS_FAILURE_MSG("Failed to parse coverage table in cursive attachment");
  }

  return true;
}

bool ParseAnchorArrayTable(const ots::OpenTypeFile *file,
                           const uint8_t *data, const size_t length,
                           const uint16_t class_count) {
  ots::Buffer subtable(data, length);

  uint16_t record_count = 0;
  if (!subtable.ReadU16(&record_count)) {
    return OTS_FAILURE_MSG("Can't read anchor array length");
  }

  const unsigned anchor_array_end = 2 * static_cast<unsigned>(record_count) *
      static_cast<unsigned>(class_count) + 2;
  if (anchor_array_end > std::numeric_limits<uint16_t>::max()) {
    return OTS_FAILURE_MSG("Bad end of anchor array %d", anchor_array_end);
  }
  for (unsigned i = 0; i < record_count; ++i) {
    for (unsigned j = 0; j < class_count; ++j) {
      uint16_t offset_record = 0;
      if (!subtable.ReadU16(&offset_record)) {
        return OTS_FAILURE_MSG("Can't read anchor array record offset for class %d and record %d", j, i);
      }
      // |offset_record| could be NULL.
      if (offset_record) {
        if (offset_record < anchor_array_end || offset_record >= length) {
          return OTS_FAILURE_MSG("Bad record offset %d in class %d, record %d", offset_record, j, i);
        }
        if (!ParseAnchorTable(file, data + offset_record,
                              length - offset_record)) {
          return OTS_FAILURE_MSG("Failed to parse anchor table for class %d, record %d", j, i);
        }
      }
    }
  }
  return true;
}

bool ParseLigatureArrayTable(const ots::OpenTypeFile *file,
                             const uint8_t *data, const size_t length,
                             const uint16_t class_count) {
  ots::Buffer subtable(data, length);

  uint16_t ligature_count = 0;
  if (!subtable.ReadU16(&ligature_count)) {
    return OTS_FAILURE_MSG("Failed to read ligature count");
  }
  for (unsigned i = 0; i < ligature_count; ++i) {
    uint16_t offset_ligature_attach = 0;
    if (!subtable.ReadU16(&offset_ligature_attach)) {
      return OTS_FAILURE_MSG("Can't read ligature offset %d", i);
    }
    if (offset_ligature_attach < 2 || offset_ligature_attach >= length) {
      return OTS_FAILURE_MSG("Bad ligature attachment offset %d in ligature %d", offset_ligature_attach, i);
    }
    if (!ParseAnchorArrayTable(file, data + offset_ligature_attach,
                               length - offset_ligature_attach, class_count)) {
      return OTS_FAILURE_MSG("Failed to parse anchor table for ligature %d", i);
    }
  }
  return true;
}

// Common parser for Lookup Type 4, 5 and 6.
bool ParseMarkToAttachmentSubtables(const ots::OpenTypeFile *file,
                                    const uint8_t *data, const size_t length,
                                    const GPOS_TYPE type) {
  ots::Buffer subtable(data, length);

  uint16_t format = 0;
  uint16_t offset_coverage1 = 0;
  uint16_t offset_coverage2 = 0;
  uint16_t class_count = 0;
  uint16_t offset_mark_array = 0;
  uint16_t offset_type_specific_array = 0;
  if (!subtable.ReadU16(&format) ||
      !subtable.ReadU16(&offset_coverage1) ||
      !subtable.ReadU16(&offset_coverage2) ||
      !subtable.ReadU16(&class_count) ||
      !subtable.ReadU16(&offset_mark_array) ||
      !subtable.ReadU16(&offset_type_specific_array)) {
    return OTS_FAILURE_MSG("Failed to read mark attachment subtable header");
  }

  if (format != 1) {
    return OTS_FAILURE_MSG("bad mark attachment subtable format %d", format);
  }

  const unsigned header_end = static_cast<unsigned>(subtable.offset());
  if (header_end > std::numeric_limits<uint16_t>::max()) {
    return OTS_FAILURE_MSG("Bad mark attachment subtable size ending at %d", header_end);
  }
  if (offset_coverage1 < header_end || offset_coverage1 >= length) {
    return OTS_FAILURE_MSG("Bad coverage 1 offset %d", offset_coverage1);
  }
  if (!ots::ParseCoverageTable(file, data + offset_coverage1,
                               length - offset_coverage1,
                               file->maxp->num_glyphs)) {
    return OTS_FAILURE_MSG("Failed to parse converge 1 table");
  }
  if (offset_coverage2 < header_end || offset_coverage2 >= length) {
    return OTS_FAILURE_MSG("Bad coverage 2 offset %d", offset_coverage2);
  }
  if (!ots::ParseCoverageTable(file, data + offset_coverage2,
                               length - offset_coverage2,
                               file->maxp->num_glyphs)) {
    return OTS_FAILURE_MSG("Failed to parse coverage table 2");
  }

  if (offset_mark_array < header_end || offset_mark_array >= length) {
    return OTS_FAILURE_MSG("Bad mark array offset %d", offset_mark_array);
  }
  if (!ParseMarkArrayTable(file, data + offset_mark_array,
                           length - offset_mark_array, class_count)) {
    return OTS_FAILURE_MSG("Failed to parse mark array");
  }

  if (offset_type_specific_array < header_end ||
      offset_type_specific_array >= length) {
    return OTS_FAILURE_MSG("Bad type specific array offset %d", offset_type_specific_array);
  }
  if (type == GPOS_TYPE_MARK_TO_BASE_ATTACHMENT ||
      type == GPOS_TYPE_MARK_TO_MARK_ATTACHMENT) {
    if (!ParseAnchorArrayTable(file, data + offset_type_specific_array,
                               length - offset_type_specific_array,
                               class_count)) {
      return OTS_FAILURE_MSG("Failed to parse anchor array");
    }
  } else if (type == GPOS_TYPE_MARK_TO_LIGATURE_ATTACHMENT) {
    if (!ParseLigatureArrayTable(file, data + offset_type_specific_array,
                                 length - offset_type_specific_array,
                                 class_count)) {
      return OTS_FAILURE_MSG("Failed to parse ligature array");
    }
  } else {
    return OTS_FAILURE_MSG("Bad attachment type %d", type);
  }

  return true;
}

// Lookup Type 4:
// MarkToBase Attachment Positioning Subtable
bool ParseMarkToBaseAttachment(const ots::OpenTypeFile *file,
                               const uint8_t *data, const size_t length) {
  return ParseMarkToAttachmentSubtables(file, data, length,
                                        GPOS_TYPE_MARK_TO_BASE_ATTACHMENT);
}

// Lookup Type 5:
// MarkToLigature Attachment Positioning Subtable
bool ParseMarkToLigatureAttachment(const ots::OpenTypeFile *file,
                                   const uint8_t *data, const size_t length) {
  return ParseMarkToAttachmentSubtables(file, data, length,
                                        GPOS_TYPE_MARK_TO_LIGATURE_ATTACHMENT);
}

// Lookup Type 6:
// MarkToMark Attachment Positioning Subtable
bool ParseMarkToMarkAttachment(const ots::OpenTypeFile *file,
                               const uint8_t *data, const size_t length) {
  return ParseMarkToAttachmentSubtables(file, data, length,
                                        GPOS_TYPE_MARK_TO_MARK_ATTACHMENT);
}

// Lookup Type 7:
// Contextual Positioning Subtables
bool ParseContextPositioning(const ots::OpenTypeFile *file,
                             const uint8_t *data, const size_t length) {
  return ots::ParseContextSubtable(file, data, length, file->maxp->num_glyphs,
                                   file->gpos->num_lookups);
}

// Lookup Type 8:
// Chaining Contexual Positioning Subtable
bool ParseChainedContextPositioning(const ots::OpenTypeFile *file,
                                    const uint8_t *data, const size_t length) {
  return ots::ParseChainingContextSubtable(file, data, length,
                                           file->maxp->num_glyphs,
                                           file->gpos->num_lookups);
}

// Lookup Type 9:
// Extension Positioning
bool ParseExtensionPositioning(const ots::OpenTypeFile *file,
                               const uint8_t *data, const size_t length) {
  return ots::ParseExtensionSubtable(file, data, length,
                                     &kGposLookupSubtableParser);
}

}  // namespace

#define DROP_THIS_TABLE(msg_) \
  do { \
    OTS_FAILURE_MSG(msg_ ", table discarded"); \
    file->gpos->data = 0; \
    file->gpos->length = 0; \
  } while (0)

namespace ots {

// As far as I checked, following fonts contain invalid GPOS table and
// OTS will drop their GPOS table.
//
// # invalid delta format in device table
// samanata.ttf
//
// # bad size range in device table
// Sarai_07.ttf
//
// # bad offset to PairSetTable
// chandas1-2.ttf
//
// # bad offset to FeatureTable
// glrso12.ttf
// gllr12.ttf
// glbo12.ttf
// glb12.ttf
// glro12.ttf
// glbso12.ttf
// glrc12.ttf
// glrsc12.ttf
// glbs12.ttf
// glrs12.ttf
// glr12.ttf
//
// # ScriptRecords aren't sorted by tag
// Garogier_unhinted.otf
//
// # bad start coverage index in CoverageFormat2
// AndBasR.ttf
// CharisSILB.ttf
// CharisSILBI.ttf
// CharisSILI.ttf
// CharisSILR.ttf
// DoulosSILR.ttf
// GenBasBI.ttf
// GenBasI.ttf
// GenBkBasI.ttf
// GenBkBasB.ttf
// GenBkBasR.ttf
// Padauk-Bold.ttf
// Padauk.ttf
//
// # Contour point indexes aren't sorted
// Arial Unicode.ttf

bool ots_gpos_parse(OpenTypeFile *file, const uint8_t *data, size_t length) {
  // Parsing GPOS table requires num_glyphs which is contained in maxp table.
  if (!file->maxp) {
    return OTS_FAILURE_MSG("missing maxp table needed in GPOS");
  }

  Buffer table(data, length);

  OpenTypeGPOS *gpos = new OpenTypeGPOS;
  file->gpos = gpos;

  uint32_t version = 0;
  uint16_t offset_script_list = 0;
  uint16_t offset_feature_list = 0;
  uint16_t offset_lookup_list = 0;
  if (!table.ReadU32(&version) ||
      !table.ReadU16(&offset_script_list) ||
      !table.ReadU16(&offset_feature_list) ||
      !table.ReadU16(&offset_lookup_list)) {
    DROP_THIS_TABLE("Incomplete table");
    return true;
  }

  if (version != 0x00010000) {
    DROP_THIS_TABLE("Bad version");
    return true;
  }

  if (offset_lookup_list) {
    if (offset_lookup_list < kGposHeaderSize || offset_lookup_list >= length) {
      DROP_THIS_TABLE("Bad lookup list offset in table header");
      return true;
    }

    if (!ParseLookupListTable(file, data + offset_lookup_list,
                              length - offset_lookup_list,
                              &kGposLookupSubtableParser,
                              &gpos->num_lookups)) {
      DROP_THIS_TABLE("Failed to parse lookup list table");
      return true;
    }
  }

  uint16_t num_features = 0;
  if (offset_feature_list) {
    if (offset_feature_list < kGposHeaderSize || offset_feature_list >= length) {
      DROP_THIS_TABLE("Bad feature list offset in table header");
      return true;
    }

    if (!ParseFeatureListTable(file, data + offset_feature_list,
                               length - offset_feature_list, gpos->num_lookups,
                               &num_features)) {
      DROP_THIS_TABLE("Failed to parse feature list table");
      return true;
    }
  }

  if (offset_script_list) {
    if (offset_script_list < kGposHeaderSize || offset_script_list >= length) {
      DROP_THIS_TABLE("Bad script list offset in table header");
      return true;
    }

    if (!ParseScriptListTable(file, data + offset_script_list,
                              length - offset_script_list, num_features)) {
      DROP_THIS_TABLE("Failed to parse script list table");
      return true;
    }
  }

  gpos->data = data;
  gpos->length = length;
  return true;
}

bool ots_gpos_should_serialise(OpenTypeFile *file) {
  return file->gpos != NULL && file->gpos->data != NULL;
}

bool ots_gpos_serialise(OTSStream *out, OpenTypeFile *file) {
  if (!out->Write(file->gpos->data, file->gpos->length)) {
    return OTS_FAILURE_MSG("Failed to write GPOS table");
  }

  return true;
}

void ots_gpos_free(OpenTypeFile *file) {
  delete file->gpos;
}

}  // namespace ots

#undef TABLE_NAME
#undef DROP_THIS_TABLE
