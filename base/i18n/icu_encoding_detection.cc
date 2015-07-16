// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/i18n/icu_encoding_detection.h"

#include <set>

#include "base/strings/string_util.h"
#include "third_party/icu/source/i18n/unicode/ucsdet.h"

namespace base {

bool DetectEncoding(const std::string& text, std::string* encoding) {
  if (IsStringASCII(text)) {
    *encoding = std::string();
    return true;
  }

  UErrorCode status = U_ZERO_ERROR;
  UCharsetDetector* detector = ucsdet_open(&status);
  ucsdet_setText(detector, text.data(), static_cast<int32_t>(text.length()),
                 &status);
  const UCharsetMatch* match = ucsdet_detect(detector, &status);
  if (match == NULL)
    return false;
  const char* detected_encoding = ucsdet_getName(match, &status);
  ucsdet_close(detector);

  if (U_FAILURE(status))
    return false;

  *encoding = detected_encoding;
  return true;
}

bool DetectAllEncodings(const std::string& text,
                        std::vector<std::string>* encodings) {
  UErrorCode status = U_ZERO_ERROR;
  UCharsetDetector* detector = ucsdet_open(&status);
  ucsdet_setText(detector, text.data(), static_cast<int32_t>(text.length()),
                 &status);
  int matches_count = 0;
  const UCharsetMatch** matches = ucsdet_detectAll(detector,
                                                   &matches_count,
                                                   &status);
  if (U_FAILURE(status)) {
    ucsdet_close(detector);
    return false;
  }

  // ICU has some heuristics for encoding detection, such that the more likely
  // encodings should be returned first. However, it doesn't always return
  // all encodings that properly decode |text|, so we'll append more encodings
  // later. To make that efficient, keep track of encodings sniffed in this
  // first phase.
  std::set<std::string> sniffed_encodings;

  encodings->clear();
  for (int i = 0; i < matches_count; i++) {
    UErrorCode get_name_status = U_ZERO_ERROR;
    const char* encoding_name = ucsdet_getName(matches[i], &get_name_status);

    // If we failed to get the encoding's name, ignore the error.
    if (U_FAILURE(get_name_status))
      continue;

    int32_t confidence = ucsdet_getConfidence(matches[i], &get_name_status);

    // We also treat this error as non-fatal.
    if (U_FAILURE(get_name_status))
      continue;

    // A confidence level >= 10 means that the encoding is expected to properly
    // decode the text. Drop all encodings with lower confidence level.
    if (confidence < 10)
      continue;

    encodings->push_back(encoding_name);
    sniffed_encodings.insert(encoding_name);
  }

  // Append all encodings not included earlier, in arbitrary order.
  // TODO(jshin): This shouldn't be necessary, possible ICU bug.
  // See also http://crbug.com/65917.
  UEnumeration* detectable_encodings = ucsdet_getAllDetectableCharsets(detector,
                                                                       &status);
  int detectable_count = uenum_count(detectable_encodings, &status);
  for (int i = 0; i < detectable_count; i++) {
    int name_length;
    const char* name_raw = uenum_next(detectable_encodings,
                                      &name_length,
                                      &status);
    std::string name(name_raw, name_length);
    if (sniffed_encodings.find(name) == sniffed_encodings.end())
      encodings->push_back(name);
  }
  uenum_close(detectable_encodings);

  ucsdet_close(detector);
  return !encodings->empty();
}

}  // namespace base
