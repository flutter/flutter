// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "text_direction_util.h"

#include <unicode/uchar.h>
#include <unicode/utf16.h>

namespace txt {

bool IsStrongLeftToRight(int32_t codepoint) {
  return u_charDirection(codepoint) == U_LEFT_TO_RIGHT;
}

bool IsStrongRightToLeft(int32_t codepoint) {
  return u_charDirection(codepoint) == U_RIGHT_TO_LEFT;
}

bool IsStrongRightToLeftArabic(int32_t codepoint) {
  return u_charDirection(codepoint) == U_RIGHT_TO_LEFT_ARABIC;
}

std::optional<TextDirection> ResolveTextDirectionByContent(
    const std::u16string& text) {
  // Scan the text for the first strong-direction character, mirroring
  // the original ICU "first strong character" rule for paragraph direction
  // detection.
  int32_t i = 0;
  const int32_t length = static_cast<int32_t>(text.size());
  while (i < length) {
    UChar32 cp;
    U16_NEXT(text.data(), i, length, cp);
    if (IsStrongLeftToRight(cp)) {
      return TextDirection::ltr;
    }
    if (IsStrongRightToLeft(cp) || IsStrongRightToLeftArabic(cp)) {
      return TextDirection::rtl;
    }
  }
  // No strong-direction character found (e.g. text is empty or contains
  // only digits / punctuation / neutral marks). The caller is expected to
  // resolve a fallback direction (typically the ambient
  // `Directionality.of(context)`).
  return std::nullopt;
}

}  // namespace txt
