// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_NAME_H_
#define OTS_NAME_H_

#include <new>
#include <string>
#include <utility>
#include <vector>

#include "ots.h"

namespace ots {

struct NameRecord {
  NameRecord() {
  }

  NameRecord(uint16_t platformID, uint16_t encodingID,
             uint16_t languageID, uint16_t nameID)
    : platform_id(platformID),
      encoding_id(encodingID),
      language_id(languageID),
      name_id(nameID) {
  }

  uint16_t platform_id;
  uint16_t encoding_id;
  uint16_t language_id;
  uint16_t name_id;
  std::string text;

  bool operator<(const NameRecord& rhs) const {
    if (platform_id < rhs.platform_id) return true;
    if (platform_id > rhs.platform_id) return false;
    if (encoding_id < rhs.encoding_id) return true;
    if (encoding_id > rhs.encoding_id) return false;
    if (language_id < rhs.language_id) return true;
    if (language_id > rhs.language_id) return false;
    return name_id < rhs.name_id;
  }
};

struct OpenTypeNAME {
  std::vector<NameRecord> names;
  std::vector<std::string> lang_tags;
};

}  // namespace ots

#endif  // OTS_NAME_H_
