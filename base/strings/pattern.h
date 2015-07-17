// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_STRINGS_PATTERN_H_
#define BASE_STRINGS_PATTERN_H_

#include "base/base_export.h"
#include "base/strings/string_piece.h"

namespace base {

// Returns true if the string passed in matches the pattern. The pattern
// string can contain wildcards like * and ?
//
// The backslash character (\) is an escape character for * and ?
// We limit the patterns to having a max of 16 * or ? characters.
// ? matches 0 or 1 character, while * matches 0 or more characters.
BASE_EXPORT bool MatchPattern(const StringPiece& string,
                              const StringPiece& pattern);
BASE_EXPORT bool MatchPattern(const StringPiece16& string,
                              const StringPiece16& pattern);

}  // namespace base

#endif  // BASE_STRINGS_PATTERN_H_
