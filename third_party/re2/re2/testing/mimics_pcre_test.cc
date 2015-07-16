// Copyright 2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "util/test.h"
#include "re2/prog.h"
#include "re2/regexp.h"

namespace re2 {

struct PCRETest {
  const char* regexp;
  bool should_match;
};

static PCRETest tests[] = {
  // Most things should behave exactly.
  { "abc",       true  },
  { "(a|b)c",    true  },
  { "(a*|b)c",   true  },
  { "(a|b*)c",   true  },
  { "a(b|c)d",   true  },
  { "a(()|())c", true  },
  { "ab*c",      true  },
  { "ab+c",      true  },
  { "a(b*|c*)d", true  },
  { "\\W",       true  },
  { "\\W{1,2}",  true  },
  { "\\d",       true  },

  // Check that repeated empty strings do not.
  { "(a*)*",     false },
  { "x(a*)*y",   false },
  { "(a*)+",     false },
  { "(a+)*",     true  },
  { "(a+)+",     true  },
  { "(a+)+",     true  },

  // \v is the only character class that shouldn't.
  { "\\b",       true  },
  { "\\v",       false },
  { "\\d",       true  },

  // The handling of ^ in multi-line mode is different, as is
  // the handling of $ in single-line mode.  (Both involve
  // boundary cases if the string ends with \n.)
  { "\\A",       true  },
  { "\\z",       true  },
  { "(?m)^",     false },
  { "(?m)$",     true  },
  { "(?-m)^",    true  },
  { "(?-m)$",    false },  // In PCRE, == \Z
  { "(?m)\\A",   true  },
  { "(?m)\\z",   true  },
  { "(?-m)\\A",  true  },
  { "(?-m)\\z",  true  },
};

TEST(MimicsPCRE, SimpleTests) {
  for (int i = 0; i < arraysize(tests); i++) {
    const PCRETest& t = tests[i];
    for (int j = 0; j < 2; j++) {
      Regexp::ParseFlags flags = Regexp::LikePerl;
      if (j == 0)
        flags = flags | Regexp::Latin1;
      Regexp* re = Regexp::Parse(t.regexp, flags, NULL);
      CHECK(re) << " " << t.regexp;
      CHECK_EQ(t.should_match, re->MimicsPCRE())
        << " " << t.regexp << " "
        << (j==0 ? "latin1" : "utf");
      re->Decref();
    }
  }
}

}  // namespace re2
