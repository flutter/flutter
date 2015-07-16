// Copyright 2006 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Test simplify.cc.

#include <string>
#include <vector>
#include "util/test.h"
#include "re2/regexp.h"

namespace re2 {

struct Test {
  const char* regexp;
  const char* simplified;
};

static Test tests[] = {
  // Already-simple constructs
  { "a", "a" },
  { "ab", "ab" },
  { "a|b", "[a-b]" },
  { "ab|cd", "ab|cd" },
  { "(ab)*", "(ab)*" },
  { "(ab)+", "(ab)+" },
  { "(ab)?", "(ab)?" },
  { ".", "." },
  { "^", "^" },
  { "$", "$" },
  { "[ac]", "[ac]" },
  { "[^ac]", "[^ac]" },

  // Posix character classes
  { "[[:alnum:]]", "[0-9A-Za-z]" },
  { "[[:alpha:]]", "[A-Za-z]" },
  { "[[:blank:]]", "[\\t ]" },
  { "[[:cntrl:]]", "[\\x00-\\x1f\\x7f]" },
  { "[[:digit:]]", "[0-9]" },
  { "[[:graph:]]", "[!-~]" },
  { "[[:lower:]]", "[a-z]" },
  { "[[:print:]]", "[ -~]" },
  { "[[:punct:]]", "[!-/:-@\\[-`{-~]" },
  { "[[:space:]]" , "[\\t-\\r ]" },
  { "[[:upper:]]", "[A-Z]" },
  { "[[:xdigit:]]", "[0-9A-Fa-f]" },

  // Perl character classes
  { "\\d", "[0-9]" },
  { "\\s", "[\\t-\\n\\f-\\r ]" },
  { "\\w", "[0-9A-Z_a-z]" },
  { "\\D", "[^0-9]" },
  { "\\S", "[^\\t-\\n\\f-\\r ]" },
  { "\\W", "[^0-9A-Z_a-z]" },
  { "[\\d]", "[0-9]" },
  { "[\\s]", "[\\t-\\n\\f-\\r ]" },
  { "[\\w]", "[0-9A-Z_a-z]" },
  { "[\\D]", "[^0-9]" },
  { "[\\S]", "[^\\t-\\n\\f-\\r ]" },
  { "[\\W]", "[^0-9A-Z_a-z]" },

  // Posix repetitions
  { "a{1}", "a" },
  { "a{2}", "aa" },
  { "a{5}", "aaaaa" },
  { "a{0,1}", "a?" },
  // The next three are illegible because Simplify inserts (?:)
  // parens instead of () parens to avoid creating extra
  // captured subexpressions.  The comments show a version fewer parens.
  { "(a){0,2}",                   "(?:(a)(a)?)?"     },  //       (aa?)?
  { "(a){0,4}",       "(?:(a)(?:(a)(?:(a)(a)?)?)?)?" },  //   (a(a(aa?)?)?)?
  { "(a){2,6}", "(a)(a)(?:(a)(?:(a)(?:(a)(a)?)?)?)?" },  // aa(a(a(aa?)?)?)?
  { "a{0,2}",           "(?:aa?)?"     },  //       (aa?)?
  { "a{0,4}",   "(?:a(?:a(?:aa?)?)?)?" },  //   (a(a(aa?)?)?)?
  { "a{2,6}", "aa(?:a(?:a(?:aa?)?)?)?" },  // aa(a(a(aa?)?)?)?
  { "a{0,}", "a*" },
  { "a{1,}", "a+" },
  { "a{2,}", "aa+" },
  { "a{5,}", "aaaaa+" },

  // Test that operators simplify their arguments.
  // (Simplify used to not simplify arguments to a {} repeat.)
  { "(?:a{1,}){1,}", "a+" },
  { "(a{1,}b{1,})", "(a+b+)" },
  { "a{1,}|b{1,}", "a+|b+" },
  { "(?:a{1,})*", "(?:a+)*" },
  { "(?:a{1,})+", "a+" },
  { "(?:a{1,})?", "(?:a+)?" },
  { "a{0}", "" },

  // Character class simplification
  { "[ab]", "[a-b]" },
  { "[a-za-za-z]", "[a-z]" },
  { "[A-Za-zA-Za-z]", "[A-Za-z]" },
  { "[ABCDEFGH]", "[A-H]" },
  { "[AB-CD-EF-GH]", "[A-H]" },
  { "[W-ZP-XE-R]", "[E-Z]" },
  { "[a-ee-gg-m]", "[a-m]" },
  { "[a-ea-ha-m]", "[a-m]" },
  { "[a-ma-ha-e]", "[a-m]" },
  { "[a-zA-Z0-9 -~]", "[ -~]" },

  // Empty character classes
  { "[^[:cntrl:][:^cntrl:]]", "[^\\x00-\\x{10ffff}]" },

  // Full character classes
  { "[[:cntrl:][:^cntrl:]]", "." },

  // Unicode case folding.
  { "(?i)A", "[Aa]" },
  { "(?i)a", "[Aa]" },
  { "(?i)K", "[Kk\\x{212a}]" },
  { "(?i)k", "[Kk\\x{212a}]" },
  { "(?i)\\x{212a}", "[Kk\\x{212a}]" },
  { "(?i)[a-z]", "[A-Za-z\\x{17f}\\x{212a}]" },
  { "(?i)[\\x00-\\x{FFFD}]", "[\\x00-\\x{fffd}]" },
  { "(?i)[\\x00-\\x{10ffff}]", "." },

  // Empty string as a regular expression.
  // Empty string must be preserved inside parens in order
  // to make submatches work right, so these are less
  // interesting than they used to be.  ToString inserts
  // explicit (?:) in place of non-parenthesized empty strings,
  // to make them easier to spot for other parsers.
  { "(a|b|)", "([a-b]|(?:))" },
  { "(|)", "()" },
  { "a()", "a()" },
  { "(()|())", "(()|())" },
  { "(a|)", "(a|(?:))" },
  { "ab()cd()", "ab()cd()" },
  { "()", "()" },
  { "()*", "()*" },
  { "()+", "()+" },
  { "()?" , "()?" },
  { "(){0}", "" },
  { "(){1}", "()" },
  { "(){1,}", "()+" },
  { "(){0,2}", "(?:()()?)?" },
};

TEST(TestSimplify, SimpleRegexps) {
  for (int i = 0; i < arraysize(tests); i++) {
    RegexpStatus status;
    VLOG(1) << "Testing " << tests[i].regexp;
    Regexp* re = Regexp::Parse(tests[i].regexp,
                               Regexp::MatchNL | (Regexp::LikePerl &
                                                  ~Regexp::OneLine),
                               &status);
    CHECK(re != NULL) << " " << tests[i].regexp << " " << status.Text();
    Regexp* sre = re->Simplify();
    CHECK(sre != NULL);

    // Check that already-simple regexps don't allocate new ones.
    if (strcmp(tests[i].regexp, tests[i].simplified) == 0) {
      CHECK(re == sre) << " " << tests[i].regexp
        << " " << re->ToString() << " " << sre->ToString();
    }

    EXPECT_EQ(tests[i].simplified, sre->ToString())
      << " " << tests[i].regexp << " " << sre->Dump();

    re->Decref();
    sre->Decref();
  }
}

}  // namespace re2
