// Copyright 2010 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include <sys/types.h>
#include <sys/stat.h>
#include <vector>

#include "util/test.h"
#include "re2/re2.h"
#include "re2/set.h"

namespace re2 {

TEST(Set, Unanchored) {
  RE2::Set s(RE2::DefaultOptions, RE2::UNANCHORED);

  CHECK_EQ(s.Add("foo", NULL), 0);
  CHECK_EQ(s.Add("(", NULL), -1);
  CHECK_EQ(s.Add("bar", NULL), 1);

  CHECK_EQ(s.Compile(), true);

  vector<int> v;
  CHECK_EQ(s.Match("foobar", &v), true);
  CHECK_EQ(v.size(), 2);
  CHECK_EQ(v[0], 0);
  CHECK_EQ(v[1], 1);

  v.clear();
  CHECK_EQ(s.Match("fooba", &v), true);
  CHECK_EQ(v.size(), 1);
  CHECK_EQ(v[0], 0);

  v.clear();
  CHECK_EQ(s.Match("oobar", &v), true);
  CHECK_EQ(v.size(), 1);
  CHECK_EQ(v[0], 1);
}

TEST(Set, UnanchoredFactored) {
  RE2::Set s(RE2::DefaultOptions, RE2::UNANCHORED);

  CHECK_EQ(s.Add("foo", NULL), 0);
  CHECK_EQ(s.Add("(", NULL), -1);
  CHECK_EQ(s.Add("foobar", NULL), 1);

  CHECK_EQ(s.Compile(), true);

  vector<int> v;
  CHECK_EQ(s.Match("foobar", &v), true);
  CHECK_EQ(v.size(), 2);
  CHECK_EQ(v[0], 0);
  CHECK_EQ(v[1], 1);

  v.clear();
  CHECK_EQ(s.Match("obarfoobaroo", &v), true);
  CHECK_EQ(v.size(), 2);
  CHECK_EQ(v[0], 0);
  CHECK_EQ(v[1], 1);

  v.clear();
  CHECK_EQ(s.Match("fooba", &v), true);
  CHECK_EQ(v.size(), 1);
  CHECK_EQ(v[0], 0);

  v.clear();
  CHECK_EQ(s.Match("oobar", &v), false);
  CHECK_EQ(v.size(), 0);
}

TEST(Set, UnanchoredDollar) {
  RE2::Set s(RE2::DefaultOptions, RE2::UNANCHORED);
  
  CHECK_EQ(s.Add("foo$", NULL), 0);
  CHECK_EQ(s.Compile(), true);
  
  vector<int> v;
  CHECK_EQ(s.Match("foo", &v), true);
  CHECK_EQ(v.size(), 1);
  CHECK_EQ(v[0], 0);
}

TEST(Set, Anchored) {
  RE2::Set s(RE2::DefaultOptions, RE2::ANCHOR_BOTH);

  CHECK_EQ(s.Add("foo", NULL), 0);
  CHECK_EQ(s.Add("(", NULL), -1);
  CHECK_EQ(s.Add("bar", NULL), 1);

  CHECK_EQ(s.Compile(), true);

  vector<int> v;
  CHECK_EQ(s.Match("foobar", &v), false);
  CHECK_EQ(v.size(), 0);

  CHECK_EQ(s.Match("fooba", &v), false);
  CHECK_EQ(v.size(), 0);

  CHECK_EQ(s.Match("oobar", &v), false);
  CHECK_EQ(v.size(), 0);

  CHECK_EQ(s.Match("foo", &v), true);
  CHECK_EQ(v.size(), 1);
  CHECK_EQ(v[0], 0);

  CHECK_EQ(s.Match("bar", &v), true);
  CHECK_EQ(v.size(), 1);
  CHECK_EQ(v[0], 1);

}

}  // namespace re2

