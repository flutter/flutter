// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TXT_SRC_TXT_TEXT_DIRECTION_UTIL_H_
#define FLUTTER_TXT_SRC_TXT_TEXT_DIRECTION_UTIL_H_

#include <optional>
#include <string>

#include "paragraph_style.h"

namespace txt {

// Returns true if the given unicode code point has a strong left-to-right
// direction (e.g. Latin letters, Han characters that are treated as LTR by
// ICU's `u_charDirection`).
bool IsStrongLeftToRight(int32_t codepoint);

// Returns true if the given unicode code point has a strong right-to-left
// direction (e.g. Hebrew letters).
bool IsStrongRightToLeft(int32_t codepoint);

// Returns true if the given unicode code point has a strong right-to-left
// Arabic direction (e.g. Arabic letters, Arabic-Indic digits).
bool IsStrongRightToLeftArabic(int32_t codepoint);

// Resolves the text direction of the given UTF-16 text by scanning for the
// first strong-direction character. If the text is empty or contains no
// strong-direction characters, returns `std::nullopt` so the caller can fall
// back to the system / ambient direction.
std::optional<TextDirection> ResolveTextDirectionByContent(
    const std::u16string& text);

}  // namespace txt

#endif  // FLUTTER_TXT_SRC_TXT_TEXT_DIRECTION_UTIL_H_
