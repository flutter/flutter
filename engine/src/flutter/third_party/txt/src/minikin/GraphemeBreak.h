/*
 * Copyright (C) 2014 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef MINIKIN_GRAPHEME_BREAK_H
#define MINIKIN_GRAPHEME_BREAK_H

#include <stddef.h>
#include <unicode/utf16.h>

namespace minikin {

class GraphemeBreak {
 public:
  // These values must be kept in sync with CURSOR_AFTER etc in Paint.java
  enum MoveOpt {
    AFTER = 0,
    AT_OR_AFTER = 1,
    BEFORE = 2,
    AT_OR_BEFORE = 3,
    AT = 4
  };

  // Determine whether the given offset is a grapheme break.
  // This implementation generally follows Unicode's UTR #29 extended
  // grapheme break, with various tweaks.
  static bool isGraphemeBreak(const float* advances,
                              const uint16_t* buf,
                              size_t start,
                              size_t count,
                              size_t offset);

  // Matches Android's Java API. Note, return (size_t)-1 for AT to
  // signal non-break because unsigned return type.
  static size_t getTextRunCursor(const float* advances,
                                 const uint16_t* buf,
                                 size_t start,
                                 size_t count,
                                 size_t offset,
                                 MoveOpt opt);
};

}  // namespace minikin

#endif  // MINIKIN_GRAPHEME_BREAK_H
