// Copyright 2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Test StringGenerator.

#include <stdlib.h>
#include <string>
#include <vector>
#include "util/test.h"
#include "re2/testing/string_generator.h"
#include "re2/testing/regexp_generator.h"

namespace re2 {

// Returns i to the e.
static int64 IntegerPower(int i, int e) {
  int64 p = 1;
  while (e-- > 0)
    p *= i;
  return p;
}

// Checks that for given settings of the string generator:
//   * it generates strings that are non-decreasing in length.
//   * strings of the same length are sorted in alphabet order.
//   * it doesn't generate the same string twice.
//   * it generates the right number of strings.
//
// If all of these hold, the StringGenerator is behaving.
// Assumes that the alphabet is sorted, so that the generated
// strings can just be compared lexicographically.
static void RunTest(int len, string alphabet, bool donull) {
  StringGenerator g(len, Explode(alphabet));

  int n = 0;
  int last_l = -1;
  string last_s;

  if (donull) {
    g.GenerateNULL();
    EXPECT_TRUE(g.HasNext());
    StringPiece sp = g.Next();
    EXPECT_EQ(sp.data(), static_cast<const char*>(NULL));
    EXPECT_EQ(sp.size(), 0);
  }

  while (g.HasNext()) {
    string s = g.Next().as_string();
    n++;

    // Check that all characters in s appear in alphabet.
    for (const char *p = s.c_str(); *p != '\0'; ) {
      Rune r;
      p += chartorune(&r, p);
      EXPECT_TRUE(utfrune(alphabet.c_str(), r) != NULL);
    }

    // Check that string is properly ordered w.r.t. previous string.
    int l = utflen(s.c_str());
    EXPECT_LE(l, len);
    if (last_l < l) {
      last_l = l;
    } else {
      EXPECT_EQ(last_l, l);
      EXPECT_LT(last_s, s);
    }
    last_s = s;
  }

  // Check total string count.
  int64 m = 0;
  int alpha = utflen(alphabet.c_str());
  if (alpha == 0)  // Degenerate case.
    len = 0;
  for (int i = 0; i <= len; i++)
    m += IntegerPower(alpha, i);
  EXPECT_EQ(n, m);
}

TEST(StringGenerator, NoLength) {
  RunTest(0, "abc", false);
}

TEST(StringGenerator, NoLengthNoAlphabet) {
  RunTest(0, "", false);
}

TEST(StringGenerator, NoAlphabet) {
  RunTest(5, "", false);
}

TEST(StringGenerator, Simple) {
  RunTest(3, "abc", false);
}

TEST(StringGenerator, UTF8) {
  RunTest(4, "abc\xE2\x98\xBA", false);
}

TEST(StringGenerator, GenNULL) {
  RunTest(0, "abc", true);
  RunTest(0, "", true);
  RunTest(5, "", true);
  RunTest(3, "abc", true);
  RunTest(4, "abc\xE2\x98\xBA", true);
}

}  // namespace re2
