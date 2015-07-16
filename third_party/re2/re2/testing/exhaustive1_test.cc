// Copyright 2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Exhaustive testing of regular expression matching.

#include "util/test.h"
#include "re2/testing/exhaustive_tester.h"

DECLARE_string(regexp_engines);

namespace re2 {

// Test simple repetition operators
TEST(Repetition, Simple) {
  vector<string> ops = Split(" ",
    "%s{0} %s{0,} %s{1} %s{1,} %s{0,1} %s{0,2} "
    "%s{1,2} %s{2} %s{2,} %s{3,4} %s{4,5} "
    "%s* %s+ %s? %s*? %s+? %s??");
  ExhaustiveTest(3, 2, Explode("abc."), ops,
                 6, Explode("ab"), "(?:%s)", "");
  ExhaustiveTest(3, 2, Explode("abc."), ops,
                 40, Explode("a"), "(?:%s)", "");
}

// Test capturing parens -- (a) -- inside repetition operators
TEST(Repetition, Capturing) {
  vector<string> ops = Split(" ",
    "%s{0} %s{0,} %s{1} %s{1,} %s{0,1} %s{0,2} "
    "%s{1,2} %s{2} %s{2,} %s{3,4} %s{4,5} "
    "%s* %s+ %s? %s*? %s+? %s??");
  ExhaustiveTest(3, 2, Split(" ", "a (a) b"), ops,
                 7, Explode("ab"), "(?:%s)", "");

  // This would be a great test, but it runs forever when PCRE is enabled.
  if (strstr("PCRE", FLAGS_regexp_engines.c_str()) == NULL)
    ExhaustiveTest(4, 3, Split(" ", "a (a)"), ops,
                   100, Explode("a"), "(?:%s)", "");
}

}  // namespace re2

