// Copyright 2006-2007 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include <stdlib.h>
#include <vector>
#include "util/test.h"
#include "re2/prog.h"
#include "re2/regexp.h"
#include "re2/testing/tester.h"
#include "re2/testing/exhaustive_tester.h"

namespace re2 {

struct RegexpTest {
  const char* regexp;
  const char* text;
};

RegexpTest simple_tests[] = {
  { "a", "a" },
  { "a", "zyzzyva" },
  { "a+", "aa" },
  { "(a+|b)+", "ab" },
  { "ab|cd", "xabcdx" },
  { "h.*od?", "hello\ngoodbye\n" },
  { "h.*o", "hello\ngoodbye\n" },
  { "h.*o", "goodbye\nhello\n" },
  { "h.*o", "hello world" },
  { "h.*o", "othello, world" },
  { "[^\\s\\S]", "aaaaaaa" },
  { "a", "aaaaaaa" },
  { "a*", "aaaaaaa" },
  { "a*", "" },
  { "a*", NULL },
  { "ab|cd", "xabcdx" },
  { "a", "cab" },
  { "a*b", "cab" },
  { "((((((((((((((((((((x))))))))))))))))))))", "x" },
  { "[abcd]", "xxxabcdxxx" },
  { "[^x]", "xxxabcdxxx" },
  { "[abcd]+", "xxxabcdxxx" },
  { "[^x]+", "xxxabcdxxx" },
  { "(fo|foo)", "fo" },
  { "(foo|fo)", "foo" },

  { "aa", "aA" },
  { "a", "Aa" },
  { "a", "A" },
  { "ABC", "abc" },
  { "abc", "XABCY" },
  { "ABC", "xabcy" },

  // Make sure ^ and $ work.
  // The pathological cases didn't work
  // in the original grep code.
  { "foo|bar|[A-Z]", "foo" },
  { "^(foo|bar|[A-Z])", "foo" },
  { "(foo|bar|[A-Z])$", "foo\n" },
  { "(foo|bar|[A-Z])$", "foo" },
  { "^(foo|bar|[A-Z])$", "foo\n" },
  { "^(foo|bar|[A-Z])$", "foo" },
  { "^(foo|bar|[A-Z])$", "bar" },
  { "^(foo|bar|[A-Z])$", "X" },
  { "^(foo|bar|[A-Z])$", "XY" },
  { "^(fo|foo)$", "fo" },
  { "^(fo|foo)$", "foo" },
  { "^^(fo|foo)$", "fo" },
  { "^^(fo|foo)$", "foo" },
  { "^$", "" },
  { "^$", "x" },
  { "^^$", "" },
  { "^$$", "" },
  { "^^$", "x" },
  { "^$$", "x" },
  { "^^$$", "" },
  { "^^$$", "x" },
  { "^^^^^^^^$$$$$$$$", "" },
  { "^", "x" },
  { "$", "x" },

  // Word boundaries.
  { "\\bfoo\\b", "nofoo foo that" },
  { "a\\b", "faoa x" },
  { "\\bbar", "bar x" },
  { "\\bbar", "foo\nbar x" },
  { "bar\\b", "foobar" },
  { "bar\\b", "foobar\nxxx" },
  { "(foo|bar|[A-Z])\\b", "foo" },
  { "(foo|bar|[A-Z])\\b", "foo\n" },
  { "\\b", "" },
  { "\\b", "x" },
  { "\\b(foo|bar|[A-Z])", "foo" },
  { "\\b(foo|bar|[A-Z])\\b", "X" },
  { "\\b(foo|bar|[A-Z])\\b", "XY" },
  { "\\b(foo|bar|[A-Z])\\b", "bar" },
  { "\\b(foo|bar|[A-Z])\\b", "foo" },
  { "\\b(foo|bar|[A-Z])\\b", "foo\n" },
  { "\\b(foo|bar|[A-Z])\\b", "ffoo bbar N x" },
  { "\\b(fo|foo)\\b", "fo" },
  { "\\b(fo|foo)\\b", "foo" },
  { "\\b\\b", "" },
  { "\\b\\b", "x" },
  { "\\b$", "" },
  { "\\b$", "x" },
  { "\\b$", "y x" },
  { "\\b.$", "x" },
  { "^\\b(fo|foo)\\b", "fo" },
  { "^\\b(fo|foo)\\b", "foo" },
  { "^\\b", "" },
  { "^\\b", "x" },
  { "^\\b\\b", "" },
  { "^\\b\\b", "x" },
  { "^\\b$", "" },
  { "^\\b$", "x" },
  { "^\\b.$", "x" },
  { "^\\b.\\b$", "x" },
  { "^^^^^^^^\\b$$$$$$$", "" },
  { "^^^^^^^^\\b.$$$$$$", "x" },
  { "^^^^^^^^\\b$$$$$$$", "x" },

  // Non-word boundaries.
  { "\\Bfoo\\B", "n foo xfoox that" },
  { "a\\B", "faoa x" },
  { "\\Bbar", "bar x" },
  { "\\Bbar", "foo\nbar x" },
  { "bar\\B", "foobar" },
  { "bar\\B", "foobar\nxxx" },
  { "(foo|bar|[A-Z])\\B", "foox" },
  { "(foo|bar|[A-Z])\\B", "foo\n" },
  { "\\B", "" },
  { "\\B", "x" },
  { "\\B(foo|bar|[A-Z])", "foo" },
  { "\\B(foo|bar|[A-Z])\\B", "xXy" },
  { "\\B(foo|bar|[A-Z])\\B", "XY" },
  { "\\B(foo|bar|[A-Z])\\B", "XYZ" },
  { "\\B(foo|bar|[A-Z])\\B", "abara" },
  { "\\B(foo|bar|[A-Z])\\B", "xfoo_" },
  { "\\B(foo|bar|[A-Z])\\B", "xfoo\n" },
  { "\\B(foo|bar|[A-Z])\\B", "foo bar vNx" },
  { "\\B(fo|foo)\\B", "xfoo" },
  { "\\B(foo|fo)\\B", "xfooo" },
  { "\\B\\B", "" },
  { "\\B\\B", "x" },
  { "\\B$", "" },
  { "\\B$", "x" },
  { "\\B$", "y x" },
  { "\\B.$", "x" },
  { "^\\B(fo|foo)\\B", "fo" },
  { "^\\B(fo|foo)\\B", "foo" },
  { "^\\B", "" },
  { "^\\B", "x" },
  { "^\\B\\B", "" },
  { "^\\B\\B", "x" },
  { "^\\B$", "" },
  { "^\\B$", "x" },
  { "^\\B.$", "x" },
  { "^\\B.\\B$", "x" },
  { "^^^^^^^^\\B$$$$$$$", "" },
  { "^^^^^^^^\\B.$$$$$$", "x" },
  { "^^^^^^^^\\B$$$$$$$", "x" },

  // PCRE uses only ASCII for \b computation.
  // All non-ASCII are *not* word characters.
  { "\\bx\\b", "x" },
  { "\\bx\\b", "x>" },
  { "\\bx\\b", "<x" },
  { "\\bx\\b", "<x>" },
  { "\\bx\\b", "ax" },
  { "\\bx\\b", "xb" },
  { "\\bx\\b", "axb" },
  { "\\bx\\b", "«x" },
  { "\\bx\\b", "x»" },
  { "\\bx\\b", "«x»" },
  { "\\bx\\b", "axb" },
  { "\\bx\\b", "áxβ" },
  { "\\Bx\\B", "axb" },
  { "\\Bx\\B", "áxβ" },

  // Weird boundary cases.
  { "^$^$", "" },
  { "^$^", "" },
  { "$^$", "" },

  { "^$^$", "x" },
  { "^$^", "x" },
  { "$^$", "x" },

  { "^$^$", "x\ny" },
  { "^$^", "x\ny" },
  { "$^$", "x\ny" },

  { "^$^$", "x\n\ny" },
  { "^$^", "x\n\ny" },
  { "$^$", "x\n\ny" },

  { "^(foo\\$)$", "foo$bar" },
  { "(foo\\$)", "foo$bar" },
  { "^...$", "abc" },

  // UTF-8
  { "^\xe6\x9c\xac$", "\xe6\x9c\xac" },
  { "^...$", "\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e" },
  { "^...$", ".\xe6\x9c\xac." },

  { "^\\C\\C\\C$", "\xe6\x9c\xac" },
  { "^\\C$", "\xe6\x9c\xac" },
  { "^\\C\\C\\C$", "\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e" },

  // Latin1
  { "^...$", "\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e" },
  { "^.........$", "\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e" },
  { "^...$", ".\xe6\x9c\xac." },
  { "^.....$", ".\xe6\x9c\xac." },

  // Perl v Posix
  { "\\B(fo|foo)\\B", "xfooo" },
  { "(fo|foo)", "foo" },

  // Octal escapes.
  { "\\141", "a" },
  { "\\060", "0" },
  { "\\0600", "00" },
  { "\\608", "08" },
  { "\\01", "\01" },
  { "\\018", "\01" "8" },

  // Hexadecimal escapes
  { "\\x{61}", "a" },
  { "\\x61", "a" },
  { "\\x{00000061}", "a" },

  // Unicode scripts.
  { "\\p{Greek}+", "aαβb" },
  { "\\P{Greek}+", "aαβb" },
  { "\\p{^Greek}+", "aαβb" },
  { "\\P{^Greek}+", "aαβb" },

  // Unicode properties.  Nd is decimal number.  N is any number.
  { "[^0-9]+",  "abc123" },
  { "\\p{Nd}+", "abc123²³¼½¾₀₉" },
  { "\\p{^Nd}+", "abc123²³¼½¾₀₉" },
  { "\\P{Nd}+", "abc123²³¼½¾₀₉" },
  { "\\P{^Nd}+", "abc123²³¼½¾₀₉" },
  { "\\pN+", "abc123²³¼½¾₀₉" },
  { "\\p{N}+", "abc123²³¼½¾₀₉" },
  { "\\p{^N}+", "abc123²³¼½¾₀₉" },

  { "\\p{Any}+", "abc123" },

  // Character classes & case folding.
  { "(?i)[@-A]+", "@AaB" },  // matches @Aa but not B
  { "(?i)[A-Z]+", "aAzZ" },
  { "(?i)[^\\\\]+", "Aa\\" },  // \\ is between A-Z and a-z -
                               // splits the ranges in an interesting way.

  // would like to use, but PCRE mishandles in full-match, non-greedy mode
  // { "(?i)[\\\\]+", "Aa" },

  { "(?i)[acegikmoqsuwy]+", "acegikmoqsuwyACEGIKMOQSUWY" },

  // Character classes & case folding.
  { "[@-A]+", "@AaB" },
  { "[A-Z]+", "aAzZ" },
  { "[^\\\\]+", "Aa\\" },
  { "[acegikmoqsuwy]+", "acegikmoqsuwyACEGIKMOQSUWY" },
  
  // Anchoring.  (^abc in aabcdef was a former bug)
  // The tester checks for a match in the text and
  // subpieces of the text with a byte removed on either side.
  { "^abc", "abcdef" },
  { "^abc", "aabcdef" },
  { "^[ay]*[bx]+c", "abcdef" },
  { "^[ay]*[bx]+c", "aabcdef" },
  { "def$", "abcdef" },
  { "def$", "abcdeff" },
  { "d[ex][fy]$", "abcdef" },
  { "d[ex][fy]$", "abcdeff" },
  { "[dz][ex][fy]$", "abcdef" },
  { "[dz][ex][fy]$", "abcdeff" },
  { "(?m)^abc", "abcdef" },
  { "(?m)^abc", "aabcdef" },
  { "(?m)^[ay]*[bx]+c", "abcdef" },
  { "(?m)^[ay]*[bx]+c", "aabcdef" },
  { "(?m)def$", "abcdef" },
  { "(?m)def$", "abcdeff" },
  { "(?m)d[ex][fy]$", "abcdef" },
  { "(?m)d[ex][fy]$", "abcdeff" },
  { "(?m)[dz][ex][fy]$", "abcdef" },
  { "(?m)[dz][ex][fy]$", "abcdeff" },
  { "^", "a" },
  { "^^", "a" },

  // Context.
  // The tester checks for a match in the text and
  // subpieces of the text with a byte removed on either side.
  { "a", "a" },
  { "ab*", "a" },
  { "a\\C*", "a" },
  
  // Former bugs.
  { "a\\C*|ba\\C", "baba" },
};

TEST(Regexp, SearchTests) {
  int failures = 0;
  for (int i = 0; i < arraysize(simple_tests); i++) {
    const RegexpTest& t = simple_tests[i];
    if (!TestRegexpOnText(t.regexp, t.text))
      failures++;

#ifdef LOGGING
    // Build a dummy ExhaustiveTest call that will trigger just
    // this one test, so that we log the test case.
    vector<string> atom, alpha, ops;
    atom.push_back(StringPiece(t.regexp).as_string());
    alpha.push_back(StringPiece(t.text).as_string());
    ExhaustiveTest(1, 0, atom, ops, 1, alpha, "", "");
#endif

  }
  EXPECT_EQ(failures, 0);
}

}  // namespace re2
