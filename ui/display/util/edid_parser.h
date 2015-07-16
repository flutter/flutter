// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_DISPLAY_UTIL_EDID_PARSER_H_
#define UI_DISPLAY_UTIL_EDID_PARSER_H_

#include <stdint.h>

#include <string>
#include <vector>

#include "ui/display/util/display_util_export.h"

// EDID (Extended Display Identification Data) is a format for monitor
// metadata. This provides a parser for the data.

namespace ui {

// Generates the display id for the pair of |edid| and |index|, and store in
// |display_id_out|. Returns true if the display id is successfully generated,
// or false otherwise.
DISPLAY_UTIL_EXPORT bool GetDisplayIdFromEDID(const std::vector<uint8_t>& edid,
                                              uint8_t index,
                                              int64_t* display_id_out);

// Parses |edid| as EDID data and stores extracted data into |manufacturer_id|
// and |human_readable_name| and returns true. NULL can be passed for unwanted
// output parameters. Some devices (especially internal displays) may not have
// the field for |human_readable_name|, and it will return true in that case.
DISPLAY_UTIL_EXPORT bool ParseOutputDeviceData(
    const std::vector<uint8_t>& edid,
    uint16_t* manufacturer_id,
    std::string* human_readable_name);

DISPLAY_UTIL_EXPORT bool ParseOutputOverscanFlag(
    const std::vector<uint8_t>& edid,
    bool* flag);

}  // namespace ui

#endif // UI_DISPLAY_UTIL_EDID_PARSER_H_
