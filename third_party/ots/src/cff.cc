// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "cff.h"

#include <cstring>
#include <utility>
#include <vector>

#include "maxp.h"
#include "cff_type2_charstring.h"

// CFF - PostScript font program (Compact Font Format) table
// http://www.microsoft.com/typography/otspec/cff.htm
// http://www.microsoft.com/typography/otspec/cffspec.htm

#define TABLE_NAME "CFF"

namespace {

enum DICT_OPERAND_TYPE {
  DICT_OPERAND_INTEGER,
  DICT_OPERAND_REAL,
  DICT_OPERATOR,
};

enum DICT_DATA_TYPE {
  DICT_DATA_TOPLEVEL,
  DICT_DATA_FDARRAY,
};

enum FONT_FORMAT {
  FORMAT_UNKNOWN,
  FORMAT_CID_KEYED,
  FORMAT_OTHER,  // Including synthetic fonts
};

// see Appendix. A
const size_t kNStdString = 390;

bool ReadOffset(ots::Buffer *table, uint8_t off_size, uint32_t *offset) {
  if (off_size > 4) {
    return OTS_FAILURE();
  }

  uint32_t tmp32 = 0;
  for (unsigned i = 0; i < off_size; ++i) {
    uint8_t tmp8 = 0;
    if (!table->ReadU8(&tmp8)) {
      return OTS_FAILURE();
    }
    tmp32 <<= 8;
    tmp32 += tmp8;
  }
  *offset = tmp32;
  return true;
}

bool ParseIndex(ots::Buffer *table, ots::CFFIndex *index) {
  index->off_size = 0;
  index->offsets.clear();

  if (!table->ReadU16(&(index->count))) {
    return OTS_FAILURE();
  }
  if (index->count == 0) {
    // An empty INDEX.
    index->offset_to_next = table->offset();
    return true;
  }

  if (!table->ReadU8(&(index->off_size))) {
    return OTS_FAILURE();
  }
  if ((index->off_size == 0) ||
      (index->off_size > 4)) {
    return OTS_FAILURE();
  }

  const size_t array_size = (index->count + 1) * index->off_size;
  // less than ((64k + 1) * 4), thus does not overflow.
  const size_t object_data_offset = table->offset() + array_size;
  // does not overflow too, since offset() <= 1GB.

  if (object_data_offset >= table->length()) {
    return OTS_FAILURE();
  }

  for (unsigned i = 0; i <= index->count; ++i) {  // '<=' is not a typo.
    uint32_t rel_offset = 0;
    if (!ReadOffset(table, index->off_size, &rel_offset)) {
      return OTS_FAILURE();
    }
    if (rel_offset < 1) {
      return OTS_FAILURE();
    }
    if (i == 0 && rel_offset != 1) {
      return OTS_FAILURE();
    }

    if (rel_offset > table->length()) {
      return OTS_FAILURE();
    }

    // does not underflow.
    if (object_data_offset > table->length() - (rel_offset - 1)) {
      return OTS_FAILURE();
    }

    index->offsets.push_back(
        object_data_offset + (rel_offset - 1));  // less than length(), 1GB.
  }

  for (unsigned i = 1; i < index->offsets.size(); ++i) {
    // We allow consecutive identical offsets here for zero-length strings.
    // See http://crbug.com/69341 for more details.
    if (index->offsets[i] < index->offsets[i - 1]) {
      return OTS_FAILURE();
    }
  }

  index->offset_to_next = index->offsets.back();
  return true;
}

bool ParseNameData(
    ots::Buffer *table, const ots::CFFIndex &index, std::string* out_name) {
  uint8_t name[256] = {0};
  if (index.offsets.size() == 0) {  // just in case.
    return OTS_FAILURE();
  }
  for (unsigned i = 1; i < index.offsets.size(); ++i) {
    const size_t length = index.offsets[i] - index.offsets[i - 1];
    // font names should be no longer than 127 characters.
    if (length > 127) {
      return OTS_FAILURE();
    }

    table->set_offset(index.offsets[i - 1]);
    if (!table->Read(name, length)) {
      return OTS_FAILURE();
    }

    for (size_t j = 0; j < length; ++j) {
      // setting the first byte to NUL is allowed.
      if (j == 0 && name[j] == 0) continue;
      // non-ASCII characters are not recommended (except the first character).
      if (name[j] < 33 || name[j] > 126) {
        return OTS_FAILURE();
      }
      // [, ], ... are not allowed.
      if (std::strchr("[](){}<>/% ", name[j])) {
        return OTS_FAILURE();
      }
    }
  }

  *out_name = reinterpret_cast<char *>(name);
  return true;
}

bool CheckOffset(const std::pair<uint32_t, DICT_OPERAND_TYPE>& operand,
                 size_t table_length) {
  if (operand.second != DICT_OPERAND_INTEGER) {
    return OTS_FAILURE();
  }
  if (operand.first >= table_length) {
    return OTS_FAILURE();
  }
  return true;
}

bool CheckSid(const std::pair<uint32_t, DICT_OPERAND_TYPE>& operand,
              size_t sid_max) {
  if (operand.second != DICT_OPERAND_INTEGER) {
    return OTS_FAILURE();
  }
  if (operand.first > sid_max) {
    return OTS_FAILURE();
  }
  return true;
}

bool ParseDictDataBcd(
    ots::Buffer *table,
    std::vector<std::pair<uint32_t, DICT_OPERAND_TYPE> > *operands) {
  bool read_decimal_point = false;
  bool read_e = false;

  uint8_t nibble = 0;
  size_t count = 0;
  while (true) {
    if (!table->ReadU8(&nibble)) {
      return OTS_FAILURE();
    }
    if ((nibble & 0xf0) == 0xf0) {
      if ((nibble & 0xf) == 0xf) {
        // TODO(yusukes): would be better to store actual double value,
        // rather than the dummy integer.
        operands->push_back(std::make_pair(static_cast<uint32_t>(0),
                                           DICT_OPERAND_REAL));
        return true;
      }
      return OTS_FAILURE();
    }
    if ((nibble & 0x0f) == 0x0f) {
      operands->push_back(std::make_pair(static_cast<uint32_t>(0),
                                         DICT_OPERAND_REAL));
      return true;
    }

    // check number format
    uint8_t nibbles[2];
    nibbles[0] = (nibble & 0xf0) >> 8;
    nibbles[1] = (nibble & 0x0f);
    for (unsigned i = 0; i < 2; ++i) {
      if (nibbles[i] == 0xd) {  // reserved number
        return OTS_FAILURE();
      }
      if ((nibbles[i] == 0xe) &&  // minus
          ((count > 0) || (i > 0))) {
        return OTS_FAILURE();  // minus sign should be the first character.
      }
      if (nibbles[i] == 0xa) {  // decimal point
        if (!read_decimal_point) {
          read_decimal_point = true;
        } else {
          return OTS_FAILURE();  // two or more points.
        }
      }
      if ((nibbles[i] == 0xb) ||  // E+
          (nibbles[i] == 0xc)) {  // E-
        if (!read_e) {
          read_e = true;
        } else {
          return OTS_FAILURE();  // two or more E's.
        }
      }
    }
    ++count;
  }
}

bool ParseDictDataEscapedOperator(
    ots::Buffer *table,
    std::vector<std::pair<uint32_t, DICT_OPERAND_TYPE> > *operands) {
  uint8_t op = 0;
  if (!table->ReadU8(&op)) {
    return OTS_FAILURE();
  }

  if ((op <= 14) ||
      (op >= 17 && op <= 23) ||
      (op >= 30 && op <= 38)) {
    operands->push_back(std::make_pair((12U << 8) + op, DICT_OPERATOR));
    return true;
  }

  // reserved area.
  return OTS_FAILURE();
}

bool ParseDictDataNumber(
    ots::Buffer *table, uint8_t b0,
    std::vector<std::pair<uint32_t, DICT_OPERAND_TYPE> > *operands) {
  uint8_t b1 = 0;
  uint8_t b2 = 0;
  uint8_t b3 = 0;
  uint8_t b4 = 0;

  switch (b0) {
    case 28:  // shortint
      if (!table->ReadU8(&b1) ||
          !table->ReadU8(&b2)) {
        return OTS_FAILURE();
      }
      operands->push_back(std::make_pair(
          static_cast<uint32_t>((b1 << 8) + b2), DICT_OPERAND_INTEGER));
      return true;

    case 29:  // longint
      if (!table->ReadU8(&b1) ||
          !table->ReadU8(&b2) ||
          !table->ReadU8(&b3) ||
          !table->ReadU8(&b4)) {
        return OTS_FAILURE();
      }
      operands->push_back(std::make_pair(
          static_cast<uint32_t>((b1 << 24) + (b2 << 16) + (b3 << 8) + b4),
          DICT_OPERAND_INTEGER));
      return true;

    case 30:  // binary coded decimal
      return ParseDictDataBcd(table, operands);

    default:
      break;
  }

  uint32_t result;
  if (b0 >=32 && b0 <=246) {
    result = b0 - 139;
  } else if (b0 >=247 && b0 <= 250) {
    if (!table->ReadU8(&b1)) {
      return OTS_FAILURE();
    }
    result = (b0 - 247) * 256 + b1 + 108;
  } else if (b0 >= 251 && b0 <= 254) {
    if (!table->ReadU8(&b1)) {
      return OTS_FAILURE();
    }
    result = -(b0 - 251) * 256 + b1 - 108;
  } else {
    return OTS_FAILURE();
  }

  operands->push_back(std::make_pair(result, DICT_OPERAND_INTEGER));
  return true;
}

bool ParseDictDataReadNext(
    ots::Buffer *table,
    std::vector<std::pair<uint32_t, DICT_OPERAND_TYPE> > *operands) {
  uint8_t op = 0;
  if (!table->ReadU8(&op)) {
    return OTS_FAILURE();
  }
  if (op <= 21) {
    if (op == 12) {
      return ParseDictDataEscapedOperator(table, operands);
    }
    operands->push_back(std::make_pair(
        static_cast<uint32_t>(op), DICT_OPERATOR));
    return true;
  } else if (op <= 27 || op == 31 || op == 255) {
    // reserved area.
    return OTS_FAILURE();
  }

  return ParseDictDataNumber(table, op, operands);
}

bool ParsePrivateDictData(
    const uint8_t *data,
    size_t table_length, size_t offset, size_t dict_length,
    DICT_DATA_TYPE type, ots::OpenTypeCFF *out_cff) {
  ots::Buffer table(data + offset, dict_length);
  std::vector<std::pair<uint32_t, DICT_OPERAND_TYPE> > operands;

  // Since a Private DICT for FDArray might not have a Local Subr (e.g. Hiragino
  // Kaku Gothic Std W8), we create an empty Local Subr here to match the size
  // of FDArray the size of |local_subrs_per_font|.
  if (type == DICT_DATA_FDARRAY) {
    out_cff->local_subrs_per_font.push_back(new ots::CFFIndex);
  }

  while (table.offset() < dict_length) {
    if (!ParseDictDataReadNext(&table, &operands)) {
      return OTS_FAILURE();
    }
    if (operands.empty()) {
      return OTS_FAILURE();
    }
    if (operands.size() > 48) {
      // An operator may be preceded by up to a maximum of 48 operands.
      return OTS_FAILURE();
    }
    if (operands.back().second != DICT_OPERATOR) {
      continue;
    }

    // got operator
    const uint32_t op = operands.back().first;
    operands.pop_back();

    switch (op) {
      // array
      case 6:  // BlueValues
      case 7:  // OtherBlues
      case 8:  // FamilyBlues
      case 9:  // FamilyOtherBlues
      case (12U << 8) + 12:  // StemSnapH (delta)
      case (12U << 8) + 13:  // StemSnapV (delta)
        if (operands.empty()) {
          return OTS_FAILURE();
        }
        break;

      // number
      case 10:  // StdHW
      case 11:  // StdVW
      case 20:  // defaultWidthX
      case 21:  // nominalWidthX
      case (12U << 8) + 9:   // BlueScale
      case (12U << 8) + 10:  // BlueShift
      case (12U << 8) + 11:  // BlueFuzz
      case (12U << 8) + 17:  // LanguageGroup
      case (12U << 8) + 18:  // ExpansionFactor
      case (12U << 8) + 19:  // initialRandomSeed
        if (operands.size() != 1) {
          return OTS_FAILURE();
        }
        break;

      // Local Subrs INDEX, offset(self)
      case 19: {
        if (operands.size() != 1) {
          return OTS_FAILURE();
        }
        if (operands.back().second != DICT_OPERAND_INTEGER) {
          return OTS_FAILURE();
        }
        if (operands.back().first >= 1024 * 1024 * 1024) {
          return OTS_FAILURE();
        }
        if (operands.back().first + offset >= table_length) {
          return OTS_FAILURE();
        }
        // parse "16. Local Subrs INDEX"
        ots::Buffer cff_table(data, table_length);
        cff_table.set_offset(operands.back().first + offset);
        ots::CFFIndex *local_subrs_index = NULL;
        if (type == DICT_DATA_FDARRAY) {
          if (out_cff->local_subrs_per_font.empty()) {
            return OTS_FAILURE();  // not reached.
          }
          local_subrs_index = out_cff->local_subrs_per_font.back();
        } else { // type == DICT_DATA_TOPLEVEL
          if (out_cff->local_subrs) {
            return OTS_FAILURE();  // two or more local_subrs?
          }
          local_subrs_index = new ots::CFFIndex;
          out_cff->local_subrs = local_subrs_index;
        }
        if (!ParseIndex(&cff_table, local_subrs_index)) {
          return OTS_FAILURE();
        }
        break;
      }

      // boolean
      case (12U << 8) + 14:  // ForceBold
        if (operands.size() != 1) {
          return OTS_FAILURE();
        }
        if (operands.back().second != DICT_OPERAND_INTEGER) {
          return OTS_FAILURE();
        }
        if (operands.back().first >= 2) {
          return OTS_FAILURE();
        }
        break;

      default:
        return OTS_FAILURE();
    }
    operands.clear();
  }

  return true;
}

bool ParseDictData(const uint8_t *data, size_t table_length,
                   const ots::CFFIndex &index, uint16_t glyphs,
                   size_t sid_max, DICT_DATA_TYPE type,
                   ots::OpenTypeCFF *out_cff) {
  for (unsigned i = 1; i < index.offsets.size(); ++i) {
    if (type == DICT_DATA_TOPLEVEL) {
      out_cff->char_strings_array.push_back(new ots::CFFIndex);
    }
    size_t dict_length = index.offsets[i] - index.offsets[i - 1];
    ots::Buffer table(data + index.offsets[i - 1], dict_length);

    std::vector<std::pair<uint32_t, DICT_OPERAND_TYPE> > operands;

    FONT_FORMAT font_format = FORMAT_UNKNOWN;
    bool have_ros = false;
    uint16_t charstring_glyphs = 0;
    size_t charset_offset = 0;

    while (table.offset() < dict_length) {
      if (!ParseDictDataReadNext(&table, &operands)) {
        return OTS_FAILURE();
      }
      if (operands.empty()) {
        return OTS_FAILURE();
      }
      if (operands.size() > 48) {
        // An operator may be preceded by up to a maximum of 48 operands.
        return OTS_FAILURE();
      }
      if (operands.back().second != DICT_OPERATOR) continue;

      // got operator
      const uint32_t op = operands.back().first;
      operands.pop_back();

      switch (op) {
        // SID
        case 0:   // version
        case 1:   // Notice
        case 2:   // Copyright
        case 3:   // FullName
        case 4:   // FamilyName
        case (12U << 8) + 0:   // Copyright
        case (12U << 8) + 21:  // PostScript
        case (12U << 8) + 22:  // BaseFontName
        case (12U << 8) + 38:  // FontName
          if (operands.size() != 1) {
            return OTS_FAILURE();
          }
          if (!CheckSid(operands.back(), sid_max)) {
            return OTS_FAILURE();
          }
          break;

        // array
        case 5:   // FontBBox
        case 14:  // XUID
        case (12U << 8) + 7:   // FontMatrix
        case (12U << 8) + 23:  // BaseFontBlend (delta)
          if (operands.empty()) {
            return OTS_FAILURE();
          }
          break;

        // number
        case 13:  // UniqueID
        case (12U << 8) + 2:   // ItalicAngle
        case (12U << 8) + 3:   // UnderlinePosition
        case (12U << 8) + 4:   // UnderlineThickness
        case (12U << 8) + 5:   // PaintType
        case (12U << 8) + 8:   // StrokeWidth
        case (12U << 8) + 20:  // SyntheticBase
          if (operands.size() != 1) {
            return OTS_FAILURE();
          }
          break;
        case (12U << 8) + 31:  // CIDFontVersion
        case (12U << 8) + 32:  // CIDFontRevision
        case (12U << 8) + 33:  // CIDFontType
        case (12U << 8) + 34:  // CIDCount
        case (12U << 8) + 35:  // UIDBase
          if (operands.size() != 1) {
            return OTS_FAILURE();
          }
          if (font_format != FORMAT_CID_KEYED) {
            return OTS_FAILURE();
          }
          break;
        case (12U << 8) + 6:   // CharstringType
          if (operands.size() != 1) {
            return OTS_FAILURE();
          }
          if(operands.back().second != DICT_OPERAND_INTEGER) {
            return OTS_FAILURE();
          }
          if (operands.back().first != 2) {
            // We only support the "Type 2 Charstring Format."
            // TODO(yusukes): Support Type 1 format? Is that still in use?
            return OTS_FAILURE();
          }
          break;

        // boolean
        case (12U << 8) + 1:   // isFixedPitch
          if (operands.size() != 1) {
            return OTS_FAILURE();
          }
          if (operands.back().second != DICT_OPERAND_INTEGER) {
            return OTS_FAILURE();
          }
          if (operands.back().first >= 2) {
            return OTS_FAILURE();
          }
          break;

        // offset(0)
        case 15:  // charset
          if (operands.size() != 1) {
            return OTS_FAILURE();
          }
          if (operands.back().first <= 2) {
            // predefined charset, ISOAdobe, Expert or ExpertSubset, is used.
            break;
          }
          if (!CheckOffset(operands.back(), table_length)) {
            return OTS_FAILURE();
          }
          if (charset_offset) {
            return OTS_FAILURE();  // multiple charset tables?
          }
          charset_offset = operands.back().first;
          break;

        case 16: {  // Encoding
          if (operands.size() != 1) {
            return OTS_FAILURE();
          }
          if (operands.back().first <= 1) {
            break;  // predefined encoding, "Standard" or "Expert", is used.
          }
          if (!CheckOffset(operands.back(), table_length)) {
            return OTS_FAILURE();
          }

          // parse sub dictionary INDEX.
          ots::Buffer cff_table(data, table_length);
          cff_table.set_offset(operands.back().first);
          uint8_t format = 0;
          if (!cff_table.ReadU8(&format)) {
            return OTS_FAILURE();
          }
          if (format & 0x80) {
            // supplemental encoding is not supported at the moment.
            return OTS_FAILURE();
          }
          // TODO(yusukes): support & parse supplemental encoding tables.
          break;
        }

        case 17: {  // CharStrings
          if (type != DICT_DATA_TOPLEVEL) {
            return OTS_FAILURE();
          }
          if (operands.size() != 1) {
            return OTS_FAILURE();
          }
          if (!CheckOffset(operands.back(), table_length)) {
            return OTS_FAILURE();
          }
          // parse "14. CharStrings INDEX"
          ots::Buffer cff_table(data, table_length);
          cff_table.set_offset(operands.back().first);
          ots::CFFIndex *charstring_index = out_cff->char_strings_array.back();
          if (!ParseIndex(&cff_table, charstring_index)) {
            return OTS_FAILURE();
          }
          if (charstring_index->count < 2) {
            return OTS_FAILURE();
          }
          if (charstring_glyphs) {
            return OTS_FAILURE();  // multiple charstring tables?
          }
          charstring_glyphs = charstring_index->count;
          if (charstring_glyphs != glyphs) {
            return OTS_FAILURE();  // CFF and maxp have different number of glyphs?
          }
          break;
        }

        case (12U << 8) + 36: {  // FDArray
          if (type != DICT_DATA_TOPLEVEL) {
            return OTS_FAILURE();
          }
          if (operands.size() != 1) {
            return OTS_FAILURE();
          }
          if (!CheckOffset(operands.back(), table_length)) {
            return OTS_FAILURE();
          }

          // parse sub dictionary INDEX.
          ots::Buffer cff_table(data, table_length);
          cff_table.set_offset(operands.back().first);
          ots::CFFIndex sub_dict_index;
          if (!ParseIndex(&cff_table, &sub_dict_index)) {
            return OTS_FAILURE();
          }
          if (!ParseDictData(data, table_length,
                             sub_dict_index,
                             glyphs, sid_max, DICT_DATA_FDARRAY,
                             out_cff)) {
            return OTS_FAILURE();
          }
          if (out_cff->font_dict_length != 0) {
            return OTS_FAILURE();  // two or more FDArray found.
          }
          out_cff->font_dict_length = sub_dict_index.count;
          break;
        }

        case (12U << 8) + 37: {  // FDSelect
          if (type != DICT_DATA_TOPLEVEL) {
            return OTS_FAILURE();
          }
          if (operands.size() != 1) {
            return OTS_FAILURE();
          }
          if (!CheckOffset(operands.back(), table_length)) {
            return OTS_FAILURE();
          }

          // parse FDSelect data structure
          ots::Buffer cff_table(data, table_length);
          cff_table.set_offset(operands.back().first);
          uint8_t format = 0;
          if (!cff_table.ReadU8(&format)) {
            return OTS_FAILURE();
          }
          if (format == 0) {
            for (uint16_t j = 0; j < glyphs; ++j) {
              uint8_t fd_index = 0;
              if (!cff_table.ReadU8(&fd_index)) {
                return OTS_FAILURE();
              }
              (out_cff->fd_select)[j] = fd_index;
            }
          } else if (format == 3) {
            uint16_t n_ranges = 0;
            if (!cff_table.ReadU16(&n_ranges)) {
              return OTS_FAILURE();
            }
            if (n_ranges == 0) {
              return OTS_FAILURE();
            }

            uint16_t last_gid = 0;
            uint8_t fd_index = 0;
            for (unsigned j = 0; j < n_ranges; ++j) {
              uint16_t first = 0;  // GID
              if (!cff_table.ReadU16(&first)) {
                return OTS_FAILURE();
              }

              // Sanity checks.
              if ((j == 0) && (first != 0)) {
                return OTS_FAILURE();
              }
              if ((j != 0) && (last_gid >= first)) {
                return OTS_FAILURE();  // not increasing order.
              }

              // Copy the mapping to |out_cff->fd_select|.
              if (j != 0) {
                for (uint16_t k = last_gid; k < first; ++k) {
                  if (!out_cff->fd_select.insert(
                          std::make_pair(k, fd_index)).second) {
                    return OTS_FAILURE();
                  }
                }
              }

              if (!cff_table.ReadU8(&fd_index)) {
                return OTS_FAILURE();
              }
              last_gid = first;
              // TODO(yusukes): check GID?
            }
            uint16_t sentinel = 0;
            if (!cff_table.ReadU16(&sentinel)) {
              return OTS_FAILURE();
            }
            if (last_gid >= sentinel) {
              return OTS_FAILURE();
            }
            for (uint16_t k = last_gid; k < sentinel; ++k) {
              if (!out_cff->fd_select.insert(
                      std::make_pair(k, fd_index)).second) {
                return OTS_FAILURE();
              }
            }
          } else {
            // unknown format
            return OTS_FAILURE();
          }
          break;
        }

        // Private DICT (2 * number)
        case 18: {
          if (operands.size() != 2) {
            return OTS_FAILURE();
          }
          if (operands.back().second != DICT_OPERAND_INTEGER) {
            return OTS_FAILURE();
          }
          const uint32_t private_offset = operands.back().first;
          operands.pop_back();
          if (operands.back().second != DICT_OPERAND_INTEGER) {
            return OTS_FAILURE();
          }
          const uint32_t private_length = operands.back().first;
          if (private_offset > table_length) {
            return OTS_FAILURE();
          }
          if (private_length >= table_length) {
            return OTS_FAILURE();
          }
          if (private_length + private_offset > table_length) {
            return OTS_FAILURE();
          }
          // parse "15. Private DICT Data"
          if (!ParsePrivateDictData(data, table_length,
                                    private_offset, private_length,
                                    type, out_cff)) {
            return OTS_FAILURE();
          }
          break;
        }

        // ROS
        case (12U << 8) + 30:
          if (font_format != FORMAT_UNKNOWN) {
            return OTS_FAILURE();
          }
          font_format = FORMAT_CID_KEYED;
          if (operands.size() != 3) {
            return OTS_FAILURE();
          }
          // check SIDs
          operands.pop_back();  // ignore the first number.
          if (!CheckSid(operands.back(), sid_max)) {
            return OTS_FAILURE();
          }
          operands.pop_back();
          if (!CheckSid(operands.back(), sid_max)) {
            return OTS_FAILURE();
          }
          if (have_ros) {
            return OTS_FAILURE();  // multiple ROS tables?
          }
          have_ros = true;
          break;

        default:
          return OTS_FAILURE();
      }
      operands.clear();

      if (font_format == FORMAT_UNKNOWN) {
        font_format = FORMAT_OTHER;
      }
    }

    // parse "13. Charsets"
    if (charset_offset) {
      ots::Buffer cff_table(data, table_length);
      cff_table.set_offset(charset_offset);
      uint8_t format = 0;
      if (!cff_table.ReadU8(&format)) {
        return OTS_FAILURE();
      }
      switch (format) {
        case 0:
          for (uint16_t j = 1 /* .notdef is omitted */; j < glyphs; ++j) {
            uint16_t sid = 0;
            if (!cff_table.ReadU16(&sid)) {
              return OTS_FAILURE();
            }
            if (!have_ros && (sid > sid_max)) {
              return OTS_FAILURE();
            }
            // TODO(yusukes): check CIDs when have_ros is true.
          }
          break;

        case 1:
        case 2: {
          uint32_t total = 1;  // .notdef is omitted.
          while (total < glyphs) {
            uint16_t sid = 0;
            if (!cff_table.ReadU16(&sid)) {
              return OTS_FAILURE();
            }
            if (!have_ros && (sid > sid_max)) {
              return OTS_FAILURE();
            }
            // TODO(yusukes): check CIDs when have_ros is true.

            if (format == 1) {
              uint8_t left = 0;
              if (!cff_table.ReadU8(&left)) {
                return OTS_FAILURE();
              }
              total += (left + 1);
            } else {
              uint16_t left = 0;
              if (!cff_table.ReadU16(&left)) {
                return OTS_FAILURE();
              }
              total += (left + 1);
            }
          }
          break;
        }

        default:
          return OTS_FAILURE();
      }
    }
  }
  return true;
}

}  // namespace

namespace ots {

bool ots_cff_parse(OpenTypeFile *file, const uint8_t *data, size_t length) {
  Buffer table(data, length);

  file->cff = new OpenTypeCFF;
  file->cff->data = data;
  file->cff->length = length;
  file->cff->font_dict_length = 0;
  file->cff->local_subrs = NULL;

  // parse "6. Header" in the Adobe Compact Font Format Specification
  uint8_t major = 0;
  uint8_t minor = 0;
  uint8_t hdr_size = 0;
  uint8_t off_size = 0;
  if (!table.ReadU8(&major)) {
    return OTS_FAILURE();
  }
  if (!table.ReadU8(&minor)) {
    return OTS_FAILURE();
  }
  if (!table.ReadU8(&hdr_size)) {
    return OTS_FAILURE();
  }
  if (!table.ReadU8(&off_size)) {
    return OTS_FAILURE();
  }
  if ((off_size == 0) || (off_size > 4)) {
    return OTS_FAILURE();
  }

  if ((major != 1) ||
      (minor != 0) ||
      (hdr_size != 4)) {
    return OTS_FAILURE();
  }
  if (hdr_size >= length) {
    return OTS_FAILURE();
  }

  // parse "7. Name INDEX"
  table.set_offset(hdr_size);
  CFFIndex name_index;
  if (!ParseIndex(&table, &name_index)) {
    return OTS_FAILURE();
  }
  if (!ParseNameData(&table, name_index, &(file->cff->name))) {
    return OTS_FAILURE();
  }

  // parse "8. Top DICT INDEX"
  table.set_offset(name_index.offset_to_next);
  CFFIndex top_dict_index;
  if (!ParseIndex(&table, &top_dict_index)) {
    return OTS_FAILURE();
  }
  if (name_index.count != top_dict_index.count) {
    return OTS_FAILURE();
  }

  // parse "10. String INDEX"
  table.set_offset(top_dict_index.offset_to_next);
  CFFIndex string_index;
  if (!ParseIndex(&table, &string_index)) {
    return OTS_FAILURE();
  }
  if (string_index.count >= 65000 - kNStdString) {
    return OTS_FAILURE();
  }

  const uint16_t num_glyphs = file->maxp->num_glyphs;
  const size_t sid_max = string_index.count + kNStdString;
  // string_index.count == 0 is allowed.

  // parse "9. Top DICT Data"
  if (!ParseDictData(data, length, top_dict_index,
                     num_glyphs, sid_max,
                     DICT_DATA_TOPLEVEL, file->cff)) {
    return OTS_FAILURE();
  }

  // parse "16. Global Subrs INDEX"
  table.set_offset(string_index.offset_to_next);
  CFFIndex global_subrs_index;
  if (!ParseIndex(&table, &global_subrs_index)) {
    return OTS_FAILURE();
  }

  // Check if all fd_index in FDSelect are valid.
  std::map<uint16_t, uint8_t>::const_iterator iter;
  std::map<uint16_t, uint8_t>::const_iterator end = file->cff->fd_select.end();
  for (iter = file->cff->fd_select.begin(); iter != end; ++iter) {
    if (iter->second >= file->cff->font_dict_length) {
      return OTS_FAILURE();
    }
  }

  // Check if all charstrings (font hinting code for each glyph) are valid.
  for (size_t i = 0; i < file->cff->char_strings_array.size(); ++i) {
    if (!ValidateType2CharStringIndex(file,
                                      *(file->cff->char_strings_array.at(i)),
                                      global_subrs_index,
                                      file->cff->fd_select,
                                      file->cff->local_subrs_per_font,
                                      file->cff->local_subrs,
                                      &table)) {
      return OTS_FAILURE_MSG("Failed validating charstring set %d", (int) i);
    }
  }

  return true;
}

bool ots_cff_should_serialise(OpenTypeFile *file) {
  return file->cff != NULL;
}

bool ots_cff_serialise(OTSStream *out, OpenTypeFile *file) {
  // TODO(yusukes): would be better to transcode the data,
  //                rather than simple memcpy.
  if (!out->Write(file->cff->data, file->cff->length)) {
    return OTS_FAILURE();
  }
  return true;
}

void ots_cff_free(OpenTypeFile *file) {
  if (file->cff) {
    for (size_t i = 0; i < file->cff->char_strings_array.size(); ++i) {
      delete (file->cff->char_strings_array)[i];
    }
    for (size_t i = 0; i < file->cff->local_subrs_per_font.size(); ++i) {
      delete (file->cff->local_subrs_per_font)[i];
    }
    delete file->cff->local_subrs;
    delete file->cff;
  }
}

}  // namespace ots

#undef TABLE_NAME
