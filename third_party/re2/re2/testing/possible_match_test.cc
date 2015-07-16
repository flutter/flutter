// Copyright 2006-2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include <vector>
#include "util/test.h"
#include "re2/prog.h"
#include "re2/re2.h"
#include "re2/regexp.h"
#include "re2/testing/regexp_generator.h"
#include "re2/testing/string_generator.h"

namespace re2 {

// Test that C++ strings are compared as uint8s, not int8s.
// PossibleMatchRange doesn't depend on this, but callers probably will.
TEST(CplusplusStrings, EightBit) {
  string s = "\x70";
  string t = "\xA0";
  EXPECT_LT(s, t);
}

struct PrefixTest {
  const char* regexp;
  int maxlen;
  const char* min;
  const char* max;
};

static PrefixTest tests[] = {
  { "",                  10,  "",           "",        },
  { "Abcdef",            10,  "Abcdef",     "Abcdef"   },
  { "abc(def|ghi)",      10,  "abcdef",     "abcghi"   },
  { "a+hello",           10,  "aa",         "ahello"   },
  { "a*hello",           10,  "a",          "hello"    },
  { "def|abc",           10,  "abc",        "def"      },
  { "a(b)(c)[d]",        10,  "abcd",       "abcd"     },
  { "ab(cab|cat)",       10,  "abcab",      "abcat"    },
  { "ab(cab|ca)x",       10,  "abcabx",     "abcax"    },
  { "(ab|x)(c|de)",      10,  "abc",        "xde"      },
  { "(ab|x)?(c|z)?",     10,  "",           "z"        },
  { "[^\\s\\S]",         10,  "",           ""         },
  { "(abc)+",             5,  "abc",        "abcac"    },
  { "(abc)+",             2,  "ab",         "ac"       },
  { "(abc)+",             1,  "a",          "b"        },
  { "[a\xC3\xA1]",        4,  "a",          "\xC3\xA1" },
  { "a*",                10,  "",           "ab"       },

  { "(?i)Abcdef",        10,  "ABCDEF",     "abcdef"   },
  { "(?i)abc(def|ghi)",  10,  "ABCDEF",     "abcghi"   },
  { "(?i)a+hello",       10,  "AA",         "ahello"   },
  { "(?i)a*hello",       10,  "A",          "hello"    },
  { "(?i)def|abc",       10,  "ABC",        "def"      },
  { "(?i)a(b)(c)[d]",    10,  "ABCD",       "abcd"     },
  { "(?i)ab(cab|cat)",   10,  "ABCAB",      "abcat"    },
  { "(?i)ab(cab|ca)x",   10,  "ABCABX",     "abcax"    },
  { "(?i)(ab|x)(c|de)",  10,  "ABC",        "xde"      },
  { "(?i)(ab|x)?(c|z)?", 10,  "",           "z"        },
  { "(?i)[^\\s\\S]",     10,  "",           ""         },
  { "(?i)(abc)+",         5,  "ABC",        "abcac"    },
  { "(?i)(abc)+",         2,  "AB",         "ac"       },
  { "(?i)(abc)+",         1,  "A",          "b"        },
  { "(?i)[a\xC3\xA1]",    4,  "A",          "\xC3\xA1" },
  { "(?i)a*",            10,  "",           "ab"       },
  { "(?i)A*",            10,  "",           "ab"       },

  { "\\AAbcdef",         10,  "Abcdef",     "Abcdef"   },
  { "\\Aabc(def|ghi)",   10,  "abcdef",     "abcghi"   },
  { "\\Aa+hello",        10,  "aa",         "ahello"   },
  { "\\Aa*hello",        10,  "a",          "hello"    },
  { "\\Adef|abc",        10,  "abc",        "def"      },
  { "\\Aa(b)(c)[d]",     10,  "abcd",       "abcd"     },
  { "\\Aab(cab|cat)",    10,  "abcab",      "abcat"    },
  { "\\Aab(cab|ca)x",    10,  "abcabx",     "abcax"    },
  { "\\A(ab|x)(c|de)",   10,  "abc",        "xde"      },
  { "\\A(ab|x)?(c|z)?",  10,  "",           "z"        },
  { "\\A[^\\s\\S]",      10,  "",           ""         },
  { "\\A(abc)+",          5,  "abc",        "abcac"    },
  { "\\A(abc)+",          2,  "ab",         "ac"       },
  { "\\A(abc)+",          1,  "a",          "b"        },
  { "\\A[a\xC3\xA1]",     4,  "a",          "\xC3\xA1" },
  { "\\Aa*",             10,  "",           "ab"       },

  { "(?i)\\AAbcdef",         10,  "ABCDEF",     "abcdef"   },
  { "(?i)\\Aabc(def|ghi)",   10,  "ABCDEF",     "abcghi"   },
  { "(?i)\\Aa+hello",        10,  "AA",         "ahello"   },
  { "(?i)\\Aa*hello",        10,  "A",          "hello"    },
  { "(?i)\\Adef|abc",        10,  "ABC",        "def"      },
  { "(?i)\\Aa(b)(c)[d]",     10,  "ABCD",       "abcd"     },
  { "(?i)\\Aab(cab|cat)",    10,  "ABCAB",      "abcat"    },
  { "(?i)\\Aab(cab|ca)x",    10,  "ABCABX",     "abcax"    },
  { "(?i)\\A(ab|x)(c|de)",   10,  "ABC",        "xde"      },
  { "(?i)\\A(ab|x)?(c|z)?",  10,  "",           "z"        },
  { "(?i)\\A[^\\s\\S]",      10,  "",           ""         },
  { "(?i)\\A(abc)+",          5,  "ABC",        "abcac"    },
  { "(?i)\\A(abc)+",          2,  "AB",         "ac"       },
  { "(?i)\\A(abc)+",          1,  "A",          "b"        },
  { "(?i)\\A[a\xC3\xA1]",     4,  "A",          "\xC3\xA1" },
  { "(?i)\\Aa*",             10,  "",           "ab"       },
  { "(?i)\\AA*",             10,  "",           "ab"       },
};

TEST(PossibleMatchRange, HandWritten) {
  for (int i = 0; i < arraysize(tests); i++) {
    for (int j = 0; j < 2; j++) {
      const PrefixTest& t = tests[i];
      string min, max;
      if (j == 0) {
        LOG(INFO) << "Checking regexp=" << CEscape(t.regexp);
        Regexp* re = Regexp::Parse(t.regexp, Regexp::LikePerl, NULL);
        CHECK(re);
        Prog* prog = re->CompileToProg(0);
        CHECK(prog);
        CHECK(prog->PossibleMatchRange(&min, &max, t.maxlen))
          << " " << t.regexp;
        delete prog;
        re->Decref();
      } else {
        CHECK(RE2(t.regexp).PossibleMatchRange(&min, &max, t.maxlen));
      }
      EXPECT_EQ(t.min, min) << t.regexp;
      EXPECT_EQ(t.max, max) << t.regexp;
    }
  }
}

// Test cases where PossibleMatchRange should return false.
TEST(PossibleMatchRange, Failures) {
  string min, max;

  // Fails because no room to write max.
  EXPECT_FALSE(RE2("abc").PossibleMatchRange(&min, &max, 0));

  // Fails because there is no max -- any non-empty string matches
  // or begins a match.  Have to use Latin-1 input, because there
  // are no valid UTF-8 strings beginning with byte 0xFF.
  EXPECT_FALSE(RE2("[\\s\\S]+", RE2::Latin1).
               PossibleMatchRange(&min, &max, 10))
    << "min=" << CEscape(min) << ", max=" << CEscape(max);
  EXPECT_FALSE(RE2("[\\0-\xFF]+", RE2::Latin1).
               PossibleMatchRange(&min, &max, 10))
    << "min=" << CEscape(min) << ", max=" << CEscape(max);
  EXPECT_FALSE(RE2(".+hello", RE2::Latin1).
               PossibleMatchRange(&min, &max, 10))
    << "min=" << CEscape(min) << ", max=" << CEscape(max);
  EXPECT_FALSE(RE2(".*hello", RE2::Latin1).
               PossibleMatchRange(&min, &max, 10))
    << "min=" << CEscape(min) << ", max=" << CEscape(max);
  EXPECT_FALSE(RE2(".*", RE2::Latin1).
               PossibleMatchRange(&min, &max, 10))
    << "min=" << CEscape(min) << ", max=" << CEscape(max);
  EXPECT_FALSE(RE2("\\C*").
               PossibleMatchRange(&min, &max, 10))
    << "min=" << CEscape(min) << ", max=" << CEscape(max);

  // Fails because it's a malformed regexp.
  EXPECT_FALSE(RE2("*hello").PossibleMatchRange(&min, &max, 10))
    << "min=" << CEscape(min) << ", max=" << CEscape(max);
}

// Exhaustive test: generate all regexps within parameters,
// then generate all strings of a given length over a given alphabet,
// then check that the prefix information agrees with whether
// the regexp matches each of the strings.
class PossibleMatchTester : public RegexpGenerator {
 public:
  PossibleMatchTester(int maxatoms,
                      int maxops,
                      const vector<string>& alphabet,
                      const vector<string>& ops,
                      int maxstrlen,
                      const vector<string>& stralphabet)
    : RegexpGenerator(maxatoms, maxops, alphabet, ops),
      strgen_(maxstrlen, stralphabet),
      regexps_(0), tests_(0) { }

  int regexps()  { return regexps_; }
  int tests()    { return tests_; }

  // Needed for RegexpGenerator interface.
  void HandleRegexp(const string& regexp);

 private:
  StringGenerator strgen_;

  int regexps_;   // Number of HandleRegexp calls
  int tests_;     // Number of regexp tests.

  DISALLOW_EVIL_CONSTRUCTORS(PossibleMatchTester);
};

// Processes a single generated regexp.
// Checks that all accepted strings agree with the prefix range.
void PossibleMatchTester::HandleRegexp(const string& regexp) {
  regexps_++;

  VLOG(3) << CEscape(regexp);

  RE2 re(regexp, RE2::Latin1);
  CHECK_EQ(re.error(), "");

  string min, max;
  if(!re.PossibleMatchRange(&min, &max, 10)) {
    // There's no good max for "\\C*".  Can't use strcmp
    // because sometimes it gets embedded in more
    // complicated expressions.
    if(strstr(regexp.c_str(), "\\C*"))
      return;
    LOG(QFATAL) << "PossibleMatchRange failed on: " << CEscape(regexp);
  }

  strgen_.Reset();
  while (strgen_.HasNext()) {
    const StringPiece& s = strgen_.Next();
    tests_++;
    if (!RE2::FullMatch(s, re))
      continue;
    CHECK_GE(s, min) << " regexp: " << regexp << " max: " << max;
    CHECK_LE(s, max) << " regexp: " << regexp << " min: " << min;
  }
}

TEST(PossibleMatchRange, Exhaustive) {
  int natom = 3;
  int noperator = 3;
  int stringlen = 5;
  if (DEBUG_MODE) {
    natom = 2;
    noperator = 3;
    stringlen = 3;
  }
  PossibleMatchTester t(natom, noperator, Split(" ", "a b [0-9]"),
                 RegexpGenerator::EgrepOps(),
                 stringlen, Explode("ab4"));
  t.Generate();
  LOG(INFO) << t.regexps() << " regexps, "
            << t.tests() << " tests";
}

}  // namespace re2
