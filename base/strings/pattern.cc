// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/strings/pattern.h"

#include "base/third_party/icu/icu_utf.h"

namespace base {

namespace {

static bool IsWildcard(base_icu::UChar32 character) {
  return character == '*' || character == '?';
}

// Move the strings pointers to the point where they start to differ.
template <typename CHAR, typename NEXT>
static void EatSameChars(const CHAR** pattern, const CHAR* pattern_end,
                         const CHAR** string, const CHAR* string_end,
                         NEXT next) {
  const CHAR* escape = NULL;
  while (*pattern != pattern_end && *string != string_end) {
    if (!escape && IsWildcard(**pattern)) {
      // We don't want to match wildcard here, except if it's escaped.
      return;
    }

    // Check if the escapement char is found. If so, skip it and move to the
    // next character.
    if (!escape && **pattern == '\\') {
      escape = *pattern;
      next(pattern, pattern_end);
      continue;
    }

    // Check if the chars match, if so, increment the ptrs.
    const CHAR* pattern_next = *pattern;
    const CHAR* string_next = *string;
    base_icu::UChar32 pattern_char = next(&pattern_next, pattern_end);
    if (pattern_char == next(&string_next, string_end) &&
        pattern_char != CBU_SENTINEL) {
      *pattern = pattern_next;
      *string = string_next;
    } else {
      // Uh oh, it did not match, we are done. If the last char was an
      // escapement, that means that it was an error to advance the ptr here,
      // let's put it back where it was. This also mean that the MatchPattern
      // function will return false because if we can't match an escape char
      // here, then no one will.
      if (escape) {
        *pattern = escape;
      }
      return;
    }

    escape = NULL;
  }
}

template <typename CHAR, typename NEXT>
static void EatWildcard(const CHAR** pattern, const CHAR* end, NEXT next) {
  while (*pattern != end) {
    if (!IsWildcard(**pattern))
      return;
    next(pattern, end);
  }
}

template <typename CHAR, typename NEXT>
static bool MatchPatternT(const CHAR* eval, const CHAR* eval_end,
                          const CHAR* pattern, const CHAR* pattern_end,
                          int depth,
                          NEXT next) {
  const int kMaxDepth = 16;
  if (depth > kMaxDepth)
    return false;

  // Eat all the matching chars.
  EatSameChars(&pattern, pattern_end, &eval, eval_end, next);

  // If the string is empty, then the pattern must be empty too, or contains
  // only wildcards.
  if (eval == eval_end) {
    EatWildcard(&pattern, pattern_end, next);
    return pattern == pattern_end;
  }

  // Pattern is empty but not string, this is not a match.
  if (pattern == pattern_end)
    return false;

  // If this is a question mark, then we need to compare the rest with
  // the current string or the string with one character eaten.
  const CHAR* next_pattern = pattern;
  next(&next_pattern, pattern_end);
  if (pattern[0] == '?') {
    if (MatchPatternT(eval, eval_end, next_pattern, pattern_end,
                      depth + 1, next))
      return true;
    const CHAR* next_eval = eval;
    next(&next_eval, eval_end);
    if (MatchPatternT(next_eval, eval_end, next_pattern, pattern_end,
                      depth + 1, next))
      return true;
  }

  // This is a *, try to match all the possible substrings with the remainder
  // of the pattern.
  if (pattern[0] == '*') {
    // Collapse duplicate wild cards (********** into *) so that the
    // method does not recurse unnecessarily. http://crbug.com/52839
    EatWildcard(&next_pattern, pattern_end, next);

    while (eval != eval_end) {
      if (MatchPatternT(eval, eval_end, next_pattern, pattern_end,
                        depth + 1, next))
        return true;
      eval++;
    }

    // We reached the end of the string, let see if the pattern contains only
    // wildcards.
    if (eval == eval_end) {
      EatWildcard(&pattern, pattern_end, next);
      if (pattern != pattern_end)
        return false;
      return true;
    }
  }

  return false;
}

struct NextCharUTF8 {
  base_icu::UChar32 operator()(const char** p, const char* end) {
    base_icu::UChar32 c;
    int offset = 0;
    CBU8_NEXT(*p, offset, end - *p, c);
    *p += offset;
    return c;
  }
};

struct NextCharUTF16 {
  base_icu::UChar32 operator()(const char16** p, const char16* end) {
    base_icu::UChar32 c;
    int offset = 0;
    CBU16_NEXT(*p, offset, end - *p, c);
    *p += offset;
    return c;
  }
};

}  // namespace

bool MatchPattern(const StringPiece& eval, const StringPiece& pattern) {
  return MatchPatternT(eval.data(), eval.data() + eval.size(),
                       pattern.data(), pattern.data() + pattern.size(),
                       0, NextCharUTF8());
}

bool MatchPattern(const StringPiece16& eval, const StringPiece16& pattern) {
  return MatchPatternT(eval.data(), eval.data() + eval.size(),
                       pattern.data(), pattern.data() + pattern.size(),
                       0, NextCharUTF16());
}

}  // namespace base
