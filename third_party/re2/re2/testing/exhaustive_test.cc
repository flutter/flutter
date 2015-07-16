// Copyright 2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Exhaustive testing of regular expression matching.

#include "util/test.h"
#include "re2/testing/exhaustive_tester.h"

namespace re2 {

DECLARE_string(regexp_engines);

// Test very simple expressions.
TEST(EgrepLiterals, Lowercase) {
  EgrepTest(3, 2, "abc.", 3, "abc", "");
}

// Test mixed-case expressions.
TEST(EgrepLiterals, MixedCase) {
  EgrepTest(3, 2, "AaBb.", 2, "AaBb", "");
}

// Test mixed-case in case-insensitive mode.
TEST(EgrepLiterals, FoldCase) {
  // The punctuation characters surround A-Z and a-z
  // in the ASCII table.  This looks for bugs in the
  // bytemap range code in the DFA.
  EgrepTest(3, 2, "abAB.", 2, "aBc@_~", "(?i:%s)");
}

// Test very simple expressions.
TEST(EgrepLiterals, UTF8) {
  EgrepTest(3, 2, "ab.", 4, "a\xE2\x98\xBA", "");
}

}  // namespace re2

