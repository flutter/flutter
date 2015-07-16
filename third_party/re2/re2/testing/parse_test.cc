// Copyright 2006 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Test parse.cc, dump.cc, and tostring.cc.

#include <string>
#include <vector>
#include "util/test.h"
#include "re2/regexp.h"

namespace re2 {

static const Regexp::ParseFlags TestZeroFlags = Regexp::ParseFlags(1<<30);

struct Test {
  const char* regexp;
  const char* parse;
  Regexp::ParseFlags flags;
};

static Regexp::ParseFlags kTestFlags = Regexp::MatchNL |
                                       Regexp::PerlX |
                                       Regexp::PerlClasses |
                                       Regexp::UnicodeGroups;

static Test tests[] = {
  // Base cases
  { "a", "lit{a}" },
  { "a.", "cat{lit{a}dot{}}" },
  { "a.b", "cat{lit{a}dot{}lit{b}}" },
  { "ab", "str{ab}" },
  { "a.b.c", "cat{lit{a}dot{}lit{b}dot{}lit{c}}" },
  { "abc", "str{abc}" },
  { "a|^", "alt{lit{a}bol{}}" },
  { "a|b", "cc{0x61-0x62}" },
  { "(a)", "cap{lit{a}}" },
  { "(a)|b", "alt{cap{lit{a}}lit{b}}" },
  { "a*", "star{lit{a}}" },
  { "a+", "plus{lit{a}}" },
  { "a?", "que{lit{a}}" },
  { "a{2}", "rep{2,2 lit{a}}" },
  { "a{2,3}", "rep{2,3 lit{a}}" },
  { "a{2,}", "rep{2,-1 lit{a}}" },
  { "a*?", "nstar{lit{a}}" },
  { "a+?", "nplus{lit{a}}" },
  { "a??", "nque{lit{a}}" },
  { "a{2}?", "nrep{2,2 lit{a}}" },
  { "a{2,3}?", "nrep{2,3 lit{a}}" },
  { "a{2,}?", "nrep{2,-1 lit{a}}" },
  { "", "emp{}" },
  { "|", "emp{}" },  // alt{emp{}emp{}} but got factored
  { "|x|", "alt{emp{}lit{x}emp{}}" },
  { ".", "dot{}" },
  { "^", "bol{}" },
  { "$", "eol{}" },
  { "\\|", "lit{|}" },
  { "\\(", "lit{(}" },
  { "\\)", "lit{)}" },
  { "\\*", "lit{*}" },
  { "\\+", "lit{+}" },
  { "\\?", "lit{?}" },
  { "{", "lit{{}" },
  { "}", "lit{}}" },
  { "\\.", "lit{.}" },
  { "\\^", "lit{^}" },
  { "\\$", "lit{$}" },
  { "\\\\", "lit{\\}" },
  { "[ace]", "cc{0x61 0x63 0x65}" },
  { "[abc]", "cc{0x61-0x63}" },
  { "[a-z]", "cc{0x61-0x7a}" },
  { "[a]", "lit{a}" },
  { "\\-", "lit{-}" },
  { "-", "lit{-}" },
  { "\\_", "lit{_}" },

  // Posix and Perl extensions
  { "[[:lower:]]", "cc{0x61-0x7a}" },
  { "[a-z]", "cc{0x61-0x7a}" },
  { "[^[:lower:]]", "cc{0-0x60 0x7b-0x10ffff}" },
  { "[[:^lower:]]", "cc{0-0x60 0x7b-0x10ffff}" },
  { "(?i)[[:lower:]]", "cc{0x41-0x5a 0x61-0x7a 0x17f 0x212a}" },
  { "(?i)[a-z]", "cc{0x41-0x5a 0x61-0x7a 0x17f 0x212a}" },
  { "(?i)[^[:lower:]]", "cc{0-0x40 0x5b-0x60 0x7b-0x17e 0x180-0x2129 0x212b-0x10ffff}" },
  { "(?i)[[:^lower:]]", "cc{0-0x40 0x5b-0x60 0x7b-0x17e 0x180-0x2129 0x212b-0x10ffff}" },
  { "\\d", "cc{0x30-0x39}" },
  { "\\D", "cc{0-0x2f 0x3a-0x10ffff}" },
  { "\\s", "cc{0x9-0xa 0xc-0xd 0x20}" },
  { "\\S", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}" },
  { "\\w", "cc{0x30-0x39 0x41-0x5a 0x5f 0x61-0x7a}" },
  { "\\W", "cc{0-0x2f 0x3a-0x40 0x5b-0x5e 0x60 0x7b-0x10ffff}" },
  { "(?i)\\w", "cc{0x30-0x39 0x41-0x5a 0x5f 0x61-0x7a 0x17f 0x212a}" },
  { "(?i)\\W", "cc{0-0x2f 0x3a-0x40 0x5b-0x5e 0x60 0x7b-0x17e 0x180-0x2129 0x212b-0x10ffff}" },
  { "[^\\\\]", "cc{0-0x5b 0x5d-0x10ffff}" },
  { "\\C", "byte{}" },

  // Unicode, negatives, and a double negative.
  { "\\p{Braille}", "cc{0x2800-0x28ff}" },
  { "\\P{Braille}", "cc{0-0x27ff 0x2900-0x10ffff}" },
  { "\\p{^Braille}", "cc{0-0x27ff 0x2900-0x10ffff}" },
  { "\\P{^Braille}", "cc{0x2800-0x28ff}" },

  // More interesting regular expressions.
  { "a{,2}", "str{a{,2}}" },
  { "\\.\\^\\$\\\\", "str{.^$\\}" },
  { "[a-zABC]", "cc{0x41-0x43 0x61-0x7a}" },
  { "[^a]", "cc{0-0x60 0x62-0x10ffff}" },
  { "[\xce\xb1-\xce\xb5\xe2\x98\xba]", "cc{0x3b1-0x3b5 0x263a}" },  // utf-8
  { "a*{", "cat{star{lit{a}}lit{{}}" },

  // Test precedences
  { "(?:ab)*", "star{str{ab}}" },
  { "(ab)*", "star{cap{str{ab}}}" },
  { "ab|cd", "alt{str{ab}str{cd}}" },
  { "a(b|c)d", "cat{lit{a}cap{cc{0x62-0x63}}lit{d}}" },

  // Test flattening.
  { "(?:a)", "lit{a}" },
  { "(?:ab)(?:cd)", "str{abcd}" },
  { "(?:a|b)|(?:c|d)", "cc{0x61-0x64}" },
  { "a|.", "dot{}" },
  { ".|a", "dot{}" },

  // Test Perl quoted literals
  { "\\Q+|*?{[\\E", "str{+|*?{[}" },
  { "\\Q+\\E+", "plus{lit{+}}" },
  { "\\Q\\\\E", "lit{\\}" },
  { "\\Q\\\\\\E", "str{\\\\}" },

  // Test Perl \A and \z
  { "(?m)^", "bol{}" },
  { "(?m)$", "eol{}" },
  { "(?-m)^", "bot{}" },
  { "(?-m)$", "eot{}" },
  { "(?m)\\A", "bot{}" },
  { "(?m)\\z", "eot{\\z}" },
  { "(?-m)\\A", "bot{}" },
  { "(?-m)\\z", "eot{\\z}" },

  // Test named captures
  { "(?P<name>a)", "cap{name:lit{a}}" },

  // Case-folded literals
  { "[Aa]", "litfold{a}" },

  // Strings
  { "abcde", "str{abcde}" },
  { "[Aa][Bb]cd", "cat{strfold{ab}str{cd}}" },

  // Reported bug involving \n leaking in despite use of NeverNL.
  { "[^ ]", "cc{0-0x9 0xb-0x1f 0x21-0x10ffff}", TestZeroFlags },
  { "[^ ]", "cc{0-0x9 0xb-0x1f 0x21-0x10ffff}", Regexp::FoldCase },
  { "[^ ]", "cc{0-0x9 0xb-0x1f 0x21-0x10ffff}", Regexp::NeverNL },
  { "[^ ]", "cc{0-0x9 0xb-0x1f 0x21-0x10ffff}", Regexp::NeverNL | Regexp::FoldCase },
  { "[^ \f]", "cc{0-0x9 0xb 0xd-0x1f 0x21-0x10ffff}", TestZeroFlags },
  { "[^ \f]", "cc{0-0x9 0xb 0xd-0x1f 0x21-0x10ffff}", Regexp::FoldCase },
  { "[^ \f]", "cc{0-0x9 0xb 0xd-0x1f 0x21-0x10ffff}", Regexp::NeverNL },
  { "[^ \f]", "cc{0-0x9 0xb 0xd-0x1f 0x21-0x10ffff}", Regexp::NeverNL | Regexp::FoldCase },
  { "[^ \r]", "cc{0-0x9 0xb-0xc 0xe-0x1f 0x21-0x10ffff}", TestZeroFlags },
  { "[^ \r]", "cc{0-0x9 0xb-0xc 0xe-0x1f 0x21-0x10ffff}", Regexp::FoldCase },
  { "[^ \r]", "cc{0-0x9 0xb-0xc 0xe-0x1f 0x21-0x10ffff}", Regexp::NeverNL },
  { "[^ \r]", "cc{0-0x9 0xb-0xc 0xe-0x1f 0x21-0x10ffff}", Regexp::NeverNL | Regexp::FoldCase },
  { "[^ \v]", "cc{0-0x9 0xc-0x1f 0x21-0x10ffff}", TestZeroFlags },
  { "[^ \v]", "cc{0-0x9 0xc-0x1f 0x21-0x10ffff}", Regexp::FoldCase },
  { "[^ \v]", "cc{0-0x9 0xc-0x1f 0x21-0x10ffff}", Regexp::NeverNL },
  { "[^ \v]", "cc{0-0x9 0xc-0x1f 0x21-0x10ffff}", Regexp::NeverNL | Regexp::FoldCase },
  { "[^ \t]", "cc{0-0x8 0xb-0x1f 0x21-0x10ffff}", TestZeroFlags },
  { "[^ \t]", "cc{0-0x8 0xb-0x1f 0x21-0x10ffff}", Regexp::FoldCase },
  { "[^ \t]", "cc{0-0x8 0xb-0x1f 0x21-0x10ffff}", Regexp::NeverNL },
  { "[^ \t]", "cc{0-0x8 0xb-0x1f 0x21-0x10ffff}", Regexp::NeverNL | Regexp::FoldCase },
  { "[^ \r\f\v]", "cc{0-0x9 0xe-0x1f 0x21-0x10ffff}", Regexp::NeverNL },
  { "[^ \r\f\v]", "cc{0-0x9 0xe-0x1f 0x21-0x10ffff}", Regexp::NeverNL | Regexp::FoldCase },
  { "[^ \r\f\t\v]", "cc{0-0x8 0xe-0x1f 0x21-0x10ffff}", Regexp::NeverNL },
  { "[^ \r\f\t\v]", "cc{0-0x8 0xe-0x1f 0x21-0x10ffff}", Regexp::NeverNL | Regexp::FoldCase },
  { "[^ \r\n\f\t\v]", "cc{0-0x8 0xe-0x1f 0x21-0x10ffff}", Regexp::NeverNL },
  { "[^ \r\n\f\t\v]", "cc{0-0x8 0xe-0x1f 0x21-0x10ffff}", Regexp::NeverNL | Regexp::FoldCase },
  { "[^ \r\n\f\t]", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}", Regexp::NeverNL },
  { "[^ \r\n\f\t]", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}", Regexp::NeverNL | Regexp::FoldCase },
  { "[^\t-\n\f-\r ]", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
    Regexp::PerlClasses },
  { "[^\t-\n\f-\r ]", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
    Regexp::PerlClasses | Regexp::FoldCase },
  { "[^\t-\n\f-\r ]", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
    Regexp::PerlClasses | Regexp::NeverNL },
  { "[^\t-\n\f-\r ]", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
    Regexp::PerlClasses | Regexp::NeverNL | Regexp::FoldCase },
  { "\\S", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
    Regexp::PerlClasses },
  { "\\S", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
    Regexp::PerlClasses | Regexp::FoldCase },
  { "\\S", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
    Regexp::PerlClasses | Regexp::NeverNL },
  { "\\S", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
    Regexp::PerlClasses | Regexp::NeverNL | Regexp::FoldCase },
};

bool RegexpEqualTestingOnly(Regexp* a, Regexp* b) {
  return Regexp::Equal(a, b);
}

void TestParse(const Test* tests, int ntests, Regexp::ParseFlags flags,
               const string& title) {
  Regexp** re = new Regexp*[ntests];
  for (int i = 0; i < ntests; i++) {
    RegexpStatus status;
    Regexp::ParseFlags f = flags;
    if (tests[i].flags != 0) {
      f = tests[i].flags & ~TestZeroFlags;
    }
    re[i] = Regexp::Parse(tests[i].regexp, f, &status);
    CHECK(re[i] != NULL) << " " << tests[i].regexp << " "
                         << status.Text();
    string s = re[i]->Dump();
    EXPECT_EQ(string(tests[i].parse), s) << "Regexp: " << tests[i].regexp
      << "\nparse: " << tests[i].parse << " s: " << s << " flag=" << f;
  }

  for (int i = 0; i < ntests; i++) {
    for (int j = 0; j < ntests; j++) {
      EXPECT_EQ(string(tests[i].parse) == tests[j].parse,
                RegexpEqualTestingOnly(re[i], re[j]))
        << "Regexp: " << tests[i].regexp << " " << tests[j].regexp;
    }
  }

  for (int i = 0; i < ntests; i++)
    re[i]->Decref();
  delete[] re;
}

// Test that regexps parse to expected structures.
TEST(TestParse, SimpleRegexps) {
  TestParse(tests, arraysize(tests), kTestFlags, "simple");
}

Test foldcase_tests[] = {
  { "AbCdE", "strfold{abcde}" },
  { "[Aa]", "litfold{a}" },
  { "a", "litfold{a}" },

  // 0x17F is an old English long s (looks like an f) and folds to s.
  // 0x212A is the Kelvin symbol and folds to k.
  { "A[F-g]", "cat{litfold{a}cc{0x41-0x7a 0x17f 0x212a}}" },  // [Aa][A-z...]
  { "[[:upper:]]", "cc{0x41-0x5a 0x61-0x7a 0x17f 0x212a}" },
  { "[[:lower:]]", "cc{0x41-0x5a 0x61-0x7a 0x17f 0x212a}" },
};

// Test that parsing with FoldCase works.
TEST(TestParse, FoldCase) {
  TestParse(foldcase_tests, arraysize(foldcase_tests), Regexp::FoldCase, "foldcase");
}

Test literal_tests[] = {
  { "(|)^$.[*+?]{5,10},\\", "str{(|)^$.[*+?]{5,10},\\}" },
};

// Test that parsing with Literal works.
TEST(TestParse, Literal) {
  TestParse(literal_tests, arraysize(literal_tests), Regexp::Literal, "literal");
}

Test matchnl_tests[] = {
  { ".", "dot{}" },
  { "\n", "lit{\n}" },
  { "[^a]", "cc{0-0x60 0x62-0x10ffff}" },
  { "[a\\n]", "cc{0xa 0x61}" },
};

// Test that parsing with MatchNL works.
// (Also tested above during simple cases.)
TEST(TestParse, MatchNL) {
  TestParse(matchnl_tests, arraysize(matchnl_tests), Regexp::MatchNL, "with MatchNL");
}

Test nomatchnl_tests[] = {
  { ".", "cc{0-0x9 0xb-0x10ffff}" },
  { "\n", "lit{\n}" },
  { "[^a]", "cc{0-0x9 0xb-0x60 0x62-0x10ffff}" },
  { "[a\\n]", "cc{0xa 0x61}" },
};

// Test that parsing without MatchNL works.
TEST(TestParse, NoMatchNL) {
  TestParse(nomatchnl_tests, arraysize(nomatchnl_tests), Regexp::NoParseFlags, "without MatchNL");
}

Test prefix_tests[] = {
  { "abc|abd", "cat{str{ab}cc{0x63-0x64}}" },
  { "a(?:b)c|abd", "cat{str{ab}cc{0x63-0x64}}" },
  { "abc|abd|aef|bcx|bcy",
    "alt{cat{lit{a}alt{cat{lit{b}cc{0x63-0x64}}str{ef}}}"
      "cat{str{bc}cc{0x78-0x79}}}" },
  { "abc|x|abd", "alt{str{abc}lit{x}str{abd}}" },
  { "(?i)abc|ABD", "cat{strfold{ab}cc{0x43-0x44 0x63-0x64}}" },
  { "[ab]c|[ab]d", "cat{cc{0x61-0x62}cc{0x63-0x64}}" },
  { "(?:xx|yy)c|(?:xx|yy)d",
    "cat{alt{str{xx}str{yy}}cc{0x63-0x64}}" },
  { "x{2}|x{2}[0-9]",
    "cat{rep{2,2 lit{x}}alt{emp{}cc{0x30-0x39}}}" },
  { "x{2}y|x{2}[0-9]y",
    "cat{rep{2,2 lit{x}}alt{lit{y}cat{cc{0x30-0x39}lit{y}}}}" },
};

// Test that prefix factoring works.
TEST(TestParse, Prefix) {
  TestParse(prefix_tests, arraysize(prefix_tests), Regexp::PerlX, "prefix");
}

// Invalid regular expressions
const char* badtests[] = {
  "(",
  ")",
  "(a",
  "(a|b|",
  "(a|b",
  "[a-z",
  "([a-z)",
  "x{1001}",
  "\xff",      // Invalid UTF-8
  "[\xff]",
  "[\\\xff]",
  "\\\xff",
  "(?P<name>a",
  "(?P<name>",
  "(?P<name",
  "(?P<x y>a)",
  "(?P<>a)",
  "[a-Z]",
  "(?i)[a-Z]",
  "a{100000}",
  "a{100000,}",
};

// Valid in Perl, bad in POSIX
const char* only_perl[] = {
 "[a-b-c]",
 "\\Qabc\\E",
 "\\Q*+?{[\\E",
 "\\Q\\\\E",
 "\\Q\\\\\\E",
 "\\Q\\\\\\\\E",
 "\\Q\\\\\\\\\\E",
 "(?:a)",
 "(?P<name>a)",
};

// Valid in POSIX, bad in Perl.
const char* only_posix[] = {
  "a++",
  "a**",
  "a?*",
  "a+*",
  "a{1}*",
};

// Test that parser rejects bad regexps.
TEST(TestParse, InvalidRegexps) {
  for (int i = 0; i < arraysize(badtests); i++) {
    CHECK(Regexp::Parse(badtests[i], Regexp::PerlX, NULL) == NULL)
      << " " << badtests[i];
    CHECK(Regexp::Parse(badtests[i], Regexp::NoParseFlags, NULL) == NULL)
      << " " << badtests[i];
  }
  for (int i = 0; i < arraysize(only_posix); i++) {
    CHECK(Regexp::Parse(only_posix[i], Regexp::PerlX, NULL) == NULL)
      << " " << only_posix[i];
    Regexp* re = Regexp::Parse(only_posix[i], Regexp::NoParseFlags, NULL);
    CHECK(re) << " " << only_posix[i];
    re->Decref();
  }
  for (int i = 0; i < arraysize(only_perl); i++) {
    CHECK(Regexp::Parse(only_perl[i], Regexp::NoParseFlags, NULL) == NULL)
      << " " << only_perl[i];
    Regexp* re = Regexp::Parse(only_perl[i], Regexp::PerlX, NULL);
    CHECK(re) << " " << only_perl[i];
    re->Decref();
  }
}

// Test that ToString produces original regexp or equivalent one.
TEST(TestToString, EquivalentParse) {
  for (int i = 0; i < arraysize(tests); i++) {
    RegexpStatus status;
    Regexp::ParseFlags f = kTestFlags;
    if (tests[i].flags != 0) {
      f = tests[i].flags & ~TestZeroFlags;
    }
    Regexp* re = Regexp::Parse(tests[i].regexp, f, &status);
    CHECK(re != NULL) << " " << tests[i].regexp << " " << status.Text();
    string s = re->Dump();
    EXPECT_EQ(string(tests[i].parse), s) << " " << tests[i].regexp << " " << string(tests[i].parse) << " " << s;
    string t = re->ToString();
    if (t != tests[i].regexp) {
      // If ToString didn't return the original regexp,
      // it must have found one with fewer parens.
      // Unfortunately we can't check the length here, because
      // ToString produces "\\{" for a literal brace,
      // but "{" is a shorter equivalent.
      // CHECK_LT(t.size(), strlen(tests[i].regexp))
      //     << " t=" << t << " regexp=" << tests[i].regexp;

      // Test that if we parse the new regexp we get the same structure.
      Regexp* nre = Regexp::Parse(t, Regexp::MatchNL | Regexp::PerlX, &status);
      CHECK(nre != NULL) << " reparse " << t << " " << status.Text();
      string ss = nre->Dump();
      string tt = nre->ToString();
      if (s != ss || t != tt)
        LOG(INFO) << "ToString(" << tests[i].regexp << ") = " << t;
      EXPECT_EQ(s, ss);
      EXPECT_EQ(t, tt);
      nre->Decref();
    }
    re->Decref();
  }
}

// Test that capture error args are correct.
TEST(NamedCaptures, ErrorArgs) {
  RegexpStatus status;
  Regexp* re;

  re = Regexp::Parse("test(?P<name", Regexp::LikePerl, &status);
  EXPECT_TRUE(re == NULL);
  EXPECT_EQ(status.code(), kRegexpBadNamedCapture);
  EXPECT_EQ(status.error_arg(), "(?P<name");

  re = Regexp::Parse("test(?P<space bar>z)", Regexp::LikePerl, &status);
  EXPECT_TRUE(re == NULL);
  EXPECT_EQ(status.code(), kRegexpBadNamedCapture);
  EXPECT_EQ(status.error_arg(), "(?P<space bar>");
}

}  // namespace re2
