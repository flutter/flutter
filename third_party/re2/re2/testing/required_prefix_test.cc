// Copyright 2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "util/test.h"
#include "re2/regexp.h"

namespace re2 {

struct PrefixTest {
  const char* regexp;
  bool return_value;
  const char* prefix;
  bool foldcase;
  const char* suffix;
};

static PrefixTest tests[] = {
  // If the regexp is missing a ^, there's no required prefix.
  { "abc", false },
  { "", false },
  { "(?m)^", false },

  // If the regexp immediately goes into
  // something not a literal match, there's no required prefix.
  { "^(abc)", false },
  { "^a*",  false },

  // Otherwise, it should work.
  { "^abc$", true, "abc", false, "(?-m:$)" },
  { "^abc", "true", "abc", false, "" },
  { "^(?i)abc", true, "abc", true, "" },
  { "^abcd*", true, "abc", false, "d*" },
  { "^[Aa][Bb]cd*", true, "ab", true, "cd*" },
  { "^ab[Cc]d*", true, "ab", false, "[Cc]d*" },
  { "^☺abc", true, "☺abc", false, "" },
};

TEST(RequiredPrefix, SimpleTests) {
  for (int i = 0; i < arraysize(tests); i++) {
    const PrefixTest& t = tests[i];
    for (int j = 0; j < 2; j++) {
      Regexp::ParseFlags flags = Regexp::LikePerl;
      if (j == 0)
        flags = flags | Regexp::Latin1;
      Regexp* re = Regexp::Parse(t.regexp, flags, NULL);
      CHECK(re) << " " << t.regexp;
      string p;
      bool f = false;
      Regexp* s = NULL;
      CHECK_EQ(t.return_value, re->RequiredPrefix(&p, &f, &s))
        << " " << t.regexp << " " << (j==0 ? "latin1" : "utf") << " " << re->Dump();
      if (t.return_value) {
        CHECK_EQ(p, string(t.prefix))
          << " " << t.regexp << " " << (j==0 ? "latin1" : "utf");
        CHECK_EQ(f, t.foldcase)
          << " " << t.regexp << " " << (j==0 ? "latin1" : "utf");
        CHECK_EQ(s->ToString(), string(t.suffix))
          << " " << t.regexp << " " << (j==0 ? "latin1" : "utf");
        s->Decref();
      }
      re->Decref();
    }
  }
}

}  // namespace re2
