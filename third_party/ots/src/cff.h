// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_CFF_H_
#define OTS_CFF_H_

#include "ots.h"

#include <map>
#include <string>
#include <vector>

namespace ots {

struct CFFIndex {
  CFFIndex()
      : count(0), off_size(0), offset_to_next(0) {}
  uint16_t count;
  uint8_t off_size;
  std::vector<uint32_t> offsets;
  uint32_t offset_to_next;
};

struct OpenTypeCFF {
  const uint8_t *data;
  size_t length;
  // Name INDEX. This name is used in name.cc as a postscript font name.
  std::string name;

  // The number of fonts the file has.
  size_t font_dict_length;
  // A map from glyph # to font #.
  std::map<uint16_t, uint8_t> fd_select;

  // A list of char strings.
  std::vector<CFFIndex *> char_strings_array;
  // A list of Local Subrs associated with FDArrays. Can be empty.
  std::vector<CFFIndex *> local_subrs_per_font;
  // A Local Subrs associated with Top DICT. Can be NULL.
  CFFIndex *local_subrs;
};

}  // namespace ots

#endif  // OTS_CFF_H_
