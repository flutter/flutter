// Copyright 2006 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Test parse.cc, dump.cc, and tostring.cc.

#include <string>
#include <vector>
#include "util/test.h"
#include "re2/regexp.h"

namespace re2 {

// Test that overflowed ref counts work.
TEST(Regexp, BigRef) {
  Regexp* re;
  re = Regexp::Parse("x", Regexp::NoParseFlags, NULL);
  for (int i = 0; i < 100000; i++)
    re->Incref();
  for (int i = 0; i < 100000; i++)
    re->Decref();
  CHECK_EQ(re->Ref(), 1);
  re->Decref();
}

// Test that very large Concats work.
// Depends on overflowed ref counts working.
TEST(Regexp, BigConcat) {
  Regexp* x;
  x = Regexp::Parse("x", Regexp::NoParseFlags, NULL);
  vector<Regexp*> v(90000, x);  // ToString bails out at 100000
  for (int i = 0; i < v.size(); i++)
    x->Incref();
  CHECK_EQ(x->Ref(), 1 + v.size()) << x->Ref();
  Regexp* re = Regexp::Concat(&v[0], v.size(), Regexp::NoParseFlags);
  CHECK_EQ(re->ToString(), string(v.size(), 'x'));
  re->Decref();
  CHECK_EQ(x->Ref(), 1) << x->Ref();
  x->Decref();
}

TEST(Regexp, NamedCaptures) {
  Regexp* x;
  RegexpStatus status;
  x = Regexp::Parse(
      "(?P<g1>a+)|(e)(?P<g2>w*)+(?P<g1>b+)", Regexp::PerlX, &status);
  EXPECT_TRUE(status.ok());
  EXPECT_EQ(4, x->NumCaptures());
  const map<string, int>* have = x->NamedCaptures();
  EXPECT_TRUE(have != NULL);
  EXPECT_EQ(2, have->size());  // there are only two named groups in
                               // the regexp: 'g1' and 'g2'.
  map<string, int> want;
  want["g1"] = 1;
  want["g2"] = 3;
  EXPECT_EQ(want, *have);
  x->Decref();
  delete have;
}

TEST(Regexp, CaptureNames) {
  Regexp* x;
  RegexpStatus status;
  x = Regexp::Parse(
      "(?P<g1>a+)|(e)(?P<g2>w*)+(?P<g1>b+)", Regexp::PerlX, &status);
  EXPECT_TRUE(status.ok());
  EXPECT_EQ(4, x->NumCaptures());
  const map<int, string>* have = x->CaptureNames();
  EXPECT_TRUE(have != NULL);
  EXPECT_EQ(3, have->size());
  map<int, string> want;
  want[1] = "g1";
  want[3] = "g2";
  want[4] = "g1";

  EXPECT_EQ(want, *have);
  x->Decref();
  delete have;
}

}  // namespace re2
