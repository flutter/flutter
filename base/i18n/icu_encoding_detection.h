// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_I18N_ICU_ENCODING_DETECTION_H_
#define BASE_I18N_ICU_ENCODING_DETECTION_H_

#include <string>
#include <vector>

#include "base/i18n/base_i18n_export.h"

namespace base {

// Detect encoding of |text| and put the name of encoding (as returned by ICU)
// in |encoding|. For ASCII texts |encoding| will be set to an empty string.
// Returns true on success.
BASE_I18N_EXPORT bool DetectEncoding(const std::string& text,
                                     std::string* encoding);

// Detect all possible encodings of |text| and put their names
// (as returned by ICU) in |encodings|. Returns true on success.
// Note: this function may return encodings that may fail to decode |text|,
// the caller is responsible for handling that.
BASE_I18N_EXPORT bool DetectAllEncodings(const std::string& text,
                                         std::vector<std::string>* encodings);

}  // namespace base

#endif  // BASE_I18N_ICU_ENCODING_DETECTION_H_
