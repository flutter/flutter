// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>

#include "os2.h"
#include "head.h"

// OS/2 - OS/2 and Windows Metrics
// http://www.microsoft.com/typography/otspec/os2.htm

#define TABLE_NAME "OS/2"

namespace ots {

bool ots_os2_parse(OpenTypeFile *file, const uint8_t *data, size_t length) {
  Buffer table(data, length);

  OpenTypeOS2 *os2 = new OpenTypeOS2;
  file->os2 = os2;

  if (!table.ReadU16(&os2->version) ||
      !table.ReadS16(&os2->avg_char_width) ||
      !table.ReadU16(&os2->weight_class) ||
      !table.ReadU16(&os2->width_class) ||
      !table.ReadU16(&os2->type) ||
      !table.ReadS16(&os2->subscript_x_size) ||
      !table.ReadS16(&os2->subscript_y_size) ||
      !table.ReadS16(&os2->subscript_x_offset) ||
      !table.ReadS16(&os2->subscript_y_offset) ||
      !table.ReadS16(&os2->superscript_x_size) ||
      !table.ReadS16(&os2->superscript_y_size) ||
      !table.ReadS16(&os2->superscript_x_offset) ||
      !table.ReadS16(&os2->superscript_y_offset) ||
      !table.ReadS16(&os2->strikeout_size) ||
      !table.ReadS16(&os2->strikeout_position) ||
      !table.ReadS16(&os2->family_class)) {
    return OTS_FAILURE_MSG("Error reading basic table elements");
  }

  if (os2->version > 5) {
    return OTS_FAILURE_MSG("Unsupported table version: %u", os2->version);
  }

  // Follow WPF Font Selection Model's advice.
  if (1 <= os2->weight_class && os2->weight_class <= 9) {
    OTS_WARNING("Bad usWeightClass: %u, changing it to: %u", os2->weight_class, os2->weight_class * 100);
    os2->weight_class *= 100;
  }
  // Ditto.
  if (os2->weight_class > 999) {
    OTS_WARNING("Bad usWeightClass: %u, changing it to: %d", os2->weight_class, 999);
    os2->weight_class = 999;
  }

  if (os2->width_class < 1) {
    OTS_WARNING("Bad usWidthClass: %u, changing it to: %d", os2->width_class, 1);
    os2->width_class = 1;
  } else if (os2->width_class > 9) {
    OTS_WARNING("Bad usWidthClass: %u, changing it to: %d", os2->width_class, 9);
    os2->width_class = 9;
  }

  // lowest 3 bits of fsType are exclusive.
  if (os2->type & 0x2) {
    // mask bits 2 & 3.
    os2->type &= 0xfff3u;
  } else if (os2->type & 0x4) {
    // mask bits 1 & 3.
    os2->type &= 0xfff4u;
  } else if (os2->type & 0x8) {
    // mask bits 1 & 2.
    os2->type &= 0xfff9u;
  }

  // mask reserved bits. use only 0..3, 8, 9 bits.
  os2->type &= 0x30f;

#define SET_TO_ZERO(a, b)                                     \
  if (os2->b < 0) {                                           \
    OTS_WARNING("Bad " a ": %d, setting it to zero", os2->b); \
    os2->b = 0;                                               \
  }

  SET_TO_ZERO("ySubscriptXSize", subscript_x_size);
  SET_TO_ZERO("ySubscriptYSize", subscript_y_size);
  SET_TO_ZERO("ySuperscriptXSize", superscript_x_size);
  SET_TO_ZERO("ySuperscriptYSize", superscript_y_size);
  SET_TO_ZERO("yStrikeoutSize", strikeout_size);
#undef SET_TO_ZERO

  static std::string panose_strings[10] = {
    "bFamilyType",
    "bSerifStyle",
    "bWeight",
    "bProportion",
    "bContrast",
    "bStrokeVariation",
    "bArmStyle",
    "bLetterform",
    "bMidline",
    "bXHeight",
  };
  for (unsigned i = 0; i < 10; ++i) {
    if (!table.ReadU8(&os2->panose[i])) {
      return OTS_FAILURE_MSG("Error reading PANOSE %s", panose_strings[i].c_str());
    }
  }

  if (!table.ReadU32(&os2->unicode_range_1) ||
      !table.ReadU32(&os2->unicode_range_2) ||
      !table.ReadU32(&os2->unicode_range_3) ||
      !table.ReadU32(&os2->unicode_range_4) ||
      !table.ReadU32(&os2->vendor_id) ||
      !table.ReadU16(&os2->selection) ||
      !table.ReadU16(&os2->first_char_index) ||
      !table.ReadU16(&os2->last_char_index) ||
      !table.ReadS16(&os2->typo_ascender) ||
      !table.ReadS16(&os2->typo_descender) ||
      !table.ReadS16(&os2->typo_linegap) ||
      !table.ReadU16(&os2->win_ascent) ||
      !table.ReadU16(&os2->win_descent)) {
    return OTS_FAILURE_MSG("Error reading more basic table fields");
  }

  // If bit 6 is set, then bits 0 and 5 must be clear.
  if (os2->selection & 0x40) {
    os2->selection &= 0xffdeu;
  }

  // the settings of bits 0 and 1 must be reflected in the macStyle bits
  // in the 'head' table.
  if (!file->head) {
    return OTS_FAILURE_MSG("Needed head table is missing from the font");
  }
  if ((os2->selection & 0x1) &&
      !(file->head->mac_style & 0x2)) {
    OTS_WARNING("adjusting Mac style (italic)");
    file->head->mac_style |= 0x2;
  }
  if ((os2->selection & 0x2) &&
      !(file->head->mac_style & 0x4)) {
    OTS_WARNING("adjusting Mac style (underscore)");
    file->head->mac_style |= 0x4;
  }

  // While bit 6 on implies that bits 0 and 1 of macStyle are clear,
  // the reverse is not true.
  if ((os2->selection & 0x40) &&
      (file->head->mac_style & 0x3)) {
    OTS_WARNING("adjusting Mac style (regular)");
    file->head->mac_style &= 0xfffcu;
  }

  if ((os2->version < 4) &&
      (os2->selection & 0x300)) {
    // bit 8 and 9 must be unset in OS/2 table versions less than 4.
    return OTS_FAILURE_MSG("Version %d incompatible with selection %d", os2->version, os2->selection);
  }

  // mask reserved bits. use only 0..9 bits.
  os2->selection &= 0x3ff;

  if (os2->first_char_index > os2->last_char_index) {
    return OTS_FAILURE_MSG("first char index %d > last char index %d in os2", os2->first_char_index, os2->last_char_index);
  }
  if (os2->typo_linegap < 0) {
    OTS_WARNING("bad linegap: %d", os2->typo_linegap);
    os2->typo_linegap = 0;
  }

  if (os2->version < 1) {
    // http://www.microsoft.com/typography/otspec/os2ver0.htm
    return true;
  }

  if (length < offsetof(OpenTypeOS2, code_page_range_2)) {
    OTS_WARNING("bad version number: %u", os2->version);
    // Some fonts (e.g., kredit1.ttf and quinquef.ttf) have weird version
    // numbers. Fix them.
    os2->version = 0;
    return true;
  }

  if (!table.ReadU32(&os2->code_page_range_1) ||
      !table.ReadU32(&os2->code_page_range_2)) {
    return OTS_FAILURE_MSG("Failed to read codepage ranges");
  }

  if (os2->version < 2) {
    // http://www.microsoft.com/typography/otspec/os2ver1.htm
    return true;
  }

  if (length < offsetof(OpenTypeOS2, max_context)) {
    OTS_WARNING("bad version number: %u", os2->version);
    // some Japanese fonts (e.g., mona.ttf) have weird version number.
    // fix them.
    os2->version = 1;
    return true;
  }

  if (!table.ReadS16(&os2->x_height) ||
      !table.ReadS16(&os2->cap_height) ||
      !table.ReadU16(&os2->default_char) ||
      !table.ReadU16(&os2->break_char) ||
      !table.ReadU16(&os2->max_context)) {
    return OTS_FAILURE_MSG("Failed to read version 2-specific fields");
  }

  if (os2->x_height < 0) {
    OTS_WARNING("bad x_height: %d", os2->x_height);
    os2->x_height = 0;
  }
  if (os2->cap_height < 0) {
    OTS_WARNING("bad cap_height: %d", os2->cap_height);
    os2->cap_height = 0;
  }

  if (os2->version < 5) {
    // http://www.microsoft.com/typography/otspec/os2ver4.htm
    return true;
  }

  if (!table.ReadU16(&os2->lower_optical_pointsize) ||
      !table.ReadU16(&os2->upper_optical_pointsize)) {
    return OTS_FAILURE_MSG("Failed to read version 5-specific fields");
  }

  if (os2->lower_optical_pointsize > 0xFFFE) {
    OTS_WARNING("'usLowerOpticalPointSize' is bigger than 0xFFFE: %d", os2->lower_optical_pointsize);
    os2->lower_optical_pointsize = 0xFFFE;
  }

  if (os2->upper_optical_pointsize < 2) {
    OTS_WARNING("'usUpperOpticalPointSize' is lower than 2: %d", os2->upper_optical_pointsize);
    os2->upper_optical_pointsize = 2;
  }

  return true;
}

bool ots_os2_should_serialise(OpenTypeFile *file) {
  return file->os2 != NULL;
}

bool ots_os2_serialise(OTSStream *out, OpenTypeFile *file) {
  const OpenTypeOS2 *os2 = file->os2;

  if (!out->WriteU16(os2->version) ||
      !out->WriteS16(os2->avg_char_width) ||
      !out->WriteU16(os2->weight_class) ||
      !out->WriteU16(os2->width_class) ||
      !out->WriteU16(os2->type) ||
      !out->WriteS16(os2->subscript_x_size) ||
      !out->WriteS16(os2->subscript_y_size) ||
      !out->WriteS16(os2->subscript_x_offset) ||
      !out->WriteS16(os2->subscript_y_offset) ||
      !out->WriteS16(os2->superscript_x_size) ||
      !out->WriteS16(os2->superscript_y_size) ||
      !out->WriteS16(os2->superscript_x_offset) ||
      !out->WriteS16(os2->superscript_y_offset) ||
      !out->WriteS16(os2->strikeout_size) ||
      !out->WriteS16(os2->strikeout_position) ||
      !out->WriteS16(os2->family_class)) {
    return OTS_FAILURE_MSG("Failed to write basic OS2 information");
  }

  for (unsigned i = 0; i < 10; ++i) {
    if (!out->Write(&os2->panose[i], 1)) {
      return OTS_FAILURE_MSG("Failed to write os2 panose information");
    }
  }

  if (!out->WriteU32(os2->unicode_range_1) ||
      !out->WriteU32(os2->unicode_range_2) ||
      !out->WriteU32(os2->unicode_range_3) ||
      !out->WriteU32(os2->unicode_range_4) ||
      !out->WriteU32(os2->vendor_id) ||
      !out->WriteU16(os2->selection) ||
      !out->WriteU16(os2->first_char_index) ||
      !out->WriteU16(os2->last_char_index) ||
      !out->WriteS16(os2->typo_ascender) ||
      !out->WriteS16(os2->typo_descender) ||
      !out->WriteS16(os2->typo_linegap) ||
      !out->WriteU16(os2->win_ascent) ||
      !out->WriteU16(os2->win_descent)) {
    return OTS_FAILURE_MSG("Failed to write version 1-specific fields");
  }

  if (os2->version < 1) {
    return true;
  }

  if (!out->WriteU32(os2->code_page_range_1) ||
      !out->WriteU32(os2->code_page_range_2)) {
    return OTS_FAILURE_MSG("Failed to write codepage ranges");
  }

  if (os2->version < 2) {
    return true;
  }

  if (!out->WriteS16(os2->x_height) ||
      !out->WriteS16(os2->cap_height) ||
      !out->WriteU16(os2->default_char) ||
      !out->WriteU16(os2->break_char) ||
      !out->WriteU16(os2->max_context)) {
    return OTS_FAILURE_MSG("Failed to write version 2-specific fields");
  }

  if (os2->version < 5) {
    return true;
  }

  if (!out->WriteU16(os2->lower_optical_pointsize) ||
      !out->WriteU16(os2->upper_optical_pointsize)) {
    return OTS_FAILURE_MSG("Failed to write version 5-specific fields");
  }

  return true;
}

void ots_os2_free(OpenTypeFile *file) {
  delete file->os2;
}

}  // namespace ots

#undef TABLE_NAME
