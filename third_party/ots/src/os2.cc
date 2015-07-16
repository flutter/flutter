// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    return OTS_FAILURE_MSG("Failed toi read basic os2 elements");
  }

  if (os2->version > 4) {
    return OTS_FAILURE_MSG("os2 version too high %d", os2->version);
  }

  // Some linux fonts (e.g., Kedage-t.ttf and LucidaSansDemiOblique.ttf) have
  // weird weight/width classes. Overwrite them with FW_NORMAL/1/9.
  if (os2->weight_class < 100 ||
      os2->weight_class > 900 ||
      os2->weight_class % 100) {
    OTS_WARNING("bad weight: %u", os2->weight_class);
    os2->weight_class = 400;  // FW_NORMAL
  }
  if (os2->width_class < 1) {
    OTS_WARNING("bad width: %u", os2->width_class);
    os2->width_class = 1;
  } else if (os2->width_class > 9) {
    OTS_WARNING("bad width: %u", os2->width_class);
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

  if (os2->subscript_x_size < 0) {
    OTS_WARNING("bad subscript_x_size: %d", os2->subscript_x_size);
    os2->subscript_x_size = 0;
  }
  if (os2->subscript_y_size < 0) {
    OTS_WARNING("bad subscript_y_size: %d", os2->subscript_y_size);
    os2->subscript_y_size = 0;
  }
  if (os2->superscript_x_size < 0) {
    OTS_WARNING("bad superscript_x_size: %d", os2->superscript_x_size);
    os2->superscript_x_size = 0;
  }
  if (os2->superscript_y_size < 0) {
    OTS_WARNING("bad superscript_y_size: %d", os2->superscript_y_size);
    os2->superscript_y_size = 0;
  }
  if (os2->strikeout_size < 0) {
    OTS_WARNING("bad strikeout_size: %d", os2->strikeout_size);
    os2->strikeout_size = 0;
  }

  for (unsigned i = 0; i < 10; ++i) {
    if (!table.ReadU8(&os2->panose[i])) {
      return OTS_FAILURE_MSG("Failed to read panose in os2 table");
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
    return OTS_FAILURE_MSG("Failed to read more basic os2 fields");
  }

  // If bit 6 is set, then bits 0 and 5 must be clear.
  if (os2->selection & 0x40) {
    os2->selection &= 0xffdeu;
  }

  // the settings of bits 0 and 1 must be reflected in the macStyle bits
  // in the 'head' table.
  if (!file->head) {
    return OTS_FAILURE_MSG("Head table missing from font as needed by os2 table");
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
    return OTS_FAILURE_MSG("OS2 version %d incompatible with selection %d", os2->version, os2->selection);
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
    return OTS_FAILURE_MSG("Failed to read os2 version 2 information");
  }

  if (os2->x_height < 0) {
    OTS_WARNING("bad x_height: %d", os2->x_height);
    os2->x_height = 0;
  }
  if (os2->cap_height < 0) {
    OTS_WARNING("bad cap_height: %d", os2->cap_height);
    os2->cap_height = 0;
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
    return OTS_FAILURE_MSG("Failed to write os2 version 1 information");
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
    return OTS_FAILURE_MSG("Failed to write os2 version 2 information");
  }

  return true;
}

void ots_os2_free(OpenTypeFile *file) {
  delete file->os2;
}

}  // namespace ots

#undef TABLE_NAME
