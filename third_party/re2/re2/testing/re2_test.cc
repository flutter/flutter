// -*- coding: utf-8 -*-
// Copyright 2002-2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// TODO: Test extractions for PartialMatch/Consume

#include <sys/types.h>
#ifndef WIN32
#include <sys/mman.h>
#endif
#include <sys/stat.h>
#include <errno.h>
#include <vector>
#include "util/test.h"
#include "re2/re2.h"
#include "re2/regexp.h"

#ifdef WIN32
#include <stdio.h>
#define snprintf _snprintf
#endif

DECLARE_bool(logtostderr);

namespace re2 {

TEST(RE2, HexTests) {

  VLOG(1) << "hex tests";

#define CHECK_HEX(type, value) \
  do { \
    type v; \
    CHECK(RE2::FullMatch(#value, "([0-9a-fA-F]+)[uUlL]*", RE2::Hex(&v))); \
    CHECK_EQ(v, 0x ## value); \
    CHECK(RE2::FullMatch("0x" #value, "([0-9a-fA-FxX]+)[uUlL]*", RE2::CRadix(&v))); \
    CHECK_EQ(v, 0x ## value); \
  } while(0)

  CHECK_HEX(short,              2bad);
  CHECK_HEX(unsigned short,     2badU);
  CHECK_HEX(int,                dead);
  CHECK_HEX(unsigned int,       deadU);
  CHECK_HEX(long,               7eadbeefL);
  CHECK_HEX(unsigned long,      deadbeefUL);
  CHECK_HEX(long long,          12345678deadbeefLL);
  CHECK_HEX(unsigned long long, cafebabedeadbeefULL);

#undef CHECK_HEX
}

TEST(RE2, OctalTests) {
  VLOG(1) << "octal tests";

#define CHECK_OCTAL(type, value) \
  do { \
    type v; \
    CHECK(RE2::FullMatch(#value, "([0-7]+)[uUlL]*", RE2::Octal(&v))); \
    CHECK_EQ(v, 0 ## value); \
    CHECK(RE2::FullMatch("0" #value, "([0-9a-fA-FxX]+)[uUlL]*", RE2::CRadix(&v))); \
    CHECK_EQ(v, 0 ## value); \
  } while(0)

  CHECK_OCTAL(short,              77777);
  CHECK_OCTAL(unsigned short,     177777U);
  CHECK_OCTAL(int,                17777777777);
  CHECK_OCTAL(unsigned int,       37777777777U);
  CHECK_OCTAL(long,               17777777777L);
  CHECK_OCTAL(unsigned long,      37777777777UL);
  CHECK_OCTAL(long long,          777777777777777777777LL);
  CHECK_OCTAL(unsigned long long, 1777777777777777777777ULL);

#undef CHECK_OCTAL
}

TEST(RE2, DecimalTests) {
  VLOG(1) << "decimal tests";

#define CHECK_DECIMAL(type, value) \
  do { \
    type v; \
    CHECK(RE2::FullMatch(#value, "(-?[0-9]+)[uUlL]*", &v)); \
    CHECK_EQ(v, value); \
    CHECK(RE2::FullMatch(#value, "(-?[0-9a-fA-FxX]+)[uUlL]*", RE2::CRadix(&v))); \
    CHECK_EQ(v, value); \
  } while(0)

  CHECK_DECIMAL(short,              -1);
  CHECK_DECIMAL(unsigned short,     9999);
  CHECK_DECIMAL(int,                -1000);
  CHECK_DECIMAL(unsigned int,       12345U);
  CHECK_DECIMAL(long,               -10000000L);
  CHECK_DECIMAL(unsigned long,      3083324652U);
  CHECK_DECIMAL(long long,          -100000000000000LL);
  CHECK_DECIMAL(unsigned long long, 1234567890987654321ULL);

#undef CHECK_DECIMAL
}

TEST(RE2, Replace) {
  VLOG(1) << "TestReplace";

  struct ReplaceTest {
    const char *regexp;
    const char *rewrite;
    const char *original;
    const char *single;
    const char *global;
    int        greplace_count;
  };
  static const ReplaceTest tests[] = {
    { "(qu|[b-df-hj-np-tv-z]*)([a-z]+)",
      "\\2\\1ay",
      "the quick brown fox jumps over the lazy dogs.",
      "ethay quick brown fox jumps over the lazy dogs.",
      "ethay ickquay ownbray oxfay umpsjay overay ethay azylay ogsday.",
      9 },
    { "\\w+",
      "\\0-NOSPAM",
      "abcd.efghi@google.com",
      "abcd-NOSPAM.efghi@google.com",
      "abcd-NOSPAM.efghi-NOSPAM@google-NOSPAM.com-NOSPAM",
      4 },
    { "^",
      "(START)",
      "foo",
      "(START)foo",
      "(START)foo",
      1 },
    { "^",
      "(START)",
      "",
      "(START)",
      "(START)",
      1 },
    { "$",
      "(END)",
      "",
      "(END)",
      "(END)",
      1 },
    { "b",
      "bb",
      "ababababab",
      "abbabababab",
      "abbabbabbabbabb",
      5 },
    { "b",
      "bb",
      "bbbbbb",
      "bbbbbbb",
      "bbbbbbbbbbbb",
      6 },
    { "b+",
      "bb",
      "bbbbbb",
      "bb",
      "bb",
      1 },
    { "b*",
      "bb",
      "bbbbbb",
      "bb",
      "bb",
      1 },
    { "b*",
      "bb",
      "aaaaa",
      "bbaaaaa",
      "bbabbabbabbabbabb",
      6 },
    // Check newline handling
    { "a.*a",
      "(\\0)",
      "aba\naba",
      "(aba)\naba",
      "(aba)\n(aba)",
      2 },
    { "", NULL, NULL, NULL, NULL, 0 }
  };

  for (const ReplaceTest *t = tests; t->original != NULL; ++t) {
    VLOG(1) << StringPrintf("\"%s\" =~ s/%s/%s/g", t->original, t->regexp, t->rewrite);
    string one(t->original);
    CHECK(RE2::Replace(&one, t->regexp, t->rewrite));
    CHECK_EQ(one, t->single);
    string all(t->original);
    CHECK_EQ(RE2::GlobalReplace(&all, t->regexp, t->rewrite), t->greplace_count)
      << "Got: " << all;
    CHECK_EQ(all, t->global);
  }
}

static void TestCheckRewriteString(const char* regexp, const char* rewrite,
                              bool expect_ok) {
  string error;
  RE2 exp(regexp);
  bool actual_ok = exp.CheckRewriteString(rewrite, &error);
  EXPECT_EQ(expect_ok, actual_ok) << " for " << rewrite << " error: " << error;
}

TEST(CheckRewriteString, all) {
  TestCheckRewriteString("abc", "foo", true);
  TestCheckRewriteString("abc", "foo\\", false);
  TestCheckRewriteString("abc", "foo\\0bar", true);

  TestCheckRewriteString("a(b)c", "foo", true);
  TestCheckRewriteString("a(b)c", "foo\\0bar", true);
  TestCheckRewriteString("a(b)c", "foo\\1bar", true);
  TestCheckRewriteString("a(b)c", "foo\\2bar", false);
  TestCheckRewriteString("a(b)c", "f\\\\2o\\1o", true);

  TestCheckRewriteString("a(b)(c)", "foo\\12", true);
  TestCheckRewriteString("a(b)(c)", "f\\2o\\1o", true);
  TestCheckRewriteString("a(b)(c)", "f\\oo\\1", false);
}

TEST(RE2, Extract) {
  VLOG(1) << "TestExtract";

  string s;

  CHECK(RE2::Extract("boris@kremvax.ru", "(.*)@([^.]*)", "\\2!\\1", &s));
  CHECK_EQ(s, "kremvax!boris");

  CHECK(RE2::Extract("foo", ".*", "'\\0'", &s));
  CHECK_EQ(s, "'foo'");
  // check that false match doesn't overwrite
  CHECK(!RE2::Extract("baz", "bar", "'\\0'", &s));
  CHECK_EQ(s, "'foo'");
}

TEST(RE2, Consume) {
  VLOG(1) << "TestConsume";

  RE2 r("\\s*(\\w+)");    // matches a word, possibly proceeded by whitespace
  string word;

  string s("   aaa b!@#$@#$cccc");
  StringPiece input(s);

  CHECK(RE2::Consume(&input, r, &word));
  CHECK_EQ(word, "aaa") << " input: " << input;
  CHECK(RE2::Consume(&input, r, &word));
  CHECK_EQ(word, "b") << " input: " << input;
  CHECK(! RE2::Consume(&input, r, &word)) << " input: " << input;
}

TEST(RE2, ConsumeN) {
  const string s(" one two three 4");
  StringPiece input(s);

  RE2::Arg argv[2];
  const RE2::Arg* const args[2] = { &argv[0], &argv[1] };

  // 0 arg
  EXPECT_TRUE(RE2::ConsumeN(&input, "\\s*(\\w+)", args, 0));  // Skips "one".

  // 1 arg
  string word;
  argv[0] = &word;
  EXPECT_TRUE(RE2::ConsumeN(&input, "\\s*(\\w+)", args, 1));
  EXPECT_EQ("two", word);

  // Multi-args
  int n;
  argv[1] = &n;
  EXPECT_TRUE(RE2::ConsumeN(&input, "\\s*(\\w+)\\s*(\\d+)", args, 2));
  EXPECT_EQ("three", word);
  EXPECT_EQ(4, n);
}

TEST(RE2, FindAndConsume) {
  VLOG(1) << "TestFindAndConsume";

  RE2 r("(\\w+)");      // matches a word
  string word;

  string s("   aaa b!@#$@#$cccc");
  StringPiece input(s);

  CHECK(RE2::FindAndConsume(&input, r, &word));
  CHECK_EQ(word, "aaa");
  CHECK(RE2::FindAndConsume(&input, r, &word));
  CHECK_EQ(word, "b");
  CHECK(RE2::FindAndConsume(&input, r, &word));
  CHECK_EQ(word, "cccc");
  CHECK(! RE2::FindAndConsume(&input, r, &word));

  // Check that FindAndConsume works without any submatches.
  // Earlier version used uninitialized data for
  // length to consume.
  input = "aaa";
  CHECK(RE2::FindAndConsume(&input, "aaa"));
  CHECK_EQ(input, "");
}

TEST(RE2, FindAndConsumeN) {
  const string s(" one two three 4");
  StringPiece input(s);

  RE2::Arg argv[2];
  const RE2::Arg* const args[2] = { &argv[0], &argv[1] };

  // 0 arg
  EXPECT_TRUE(RE2::FindAndConsumeN(&input, "(\\w+)", args, 0));  // Skips "one".

  // 1 arg
  string word;
  argv[0] = &word;
  EXPECT_TRUE(RE2::FindAndConsumeN(&input, "(\\w+)", args, 1));
  EXPECT_EQ("two", word);

  // Multi-args
  int n;
  argv[1] = &n;
  EXPECT_TRUE(RE2::FindAndConsumeN(&input, "(\\w+)\\s*(\\d+)", args, 2));
  EXPECT_EQ("three", word);
  EXPECT_EQ(4, n);
}

TEST(RE2, MatchNumberPeculiarity) {
  VLOG(1) << "TestMatchNumberPeculiarity";

  RE2 r("(foo)|(bar)|(baz)");
  string word1;
  string word2;
  string word3;

  CHECK(RE2::PartialMatch("foo", r, &word1, &word2, &word3));
  CHECK_EQ(word1, "foo");
  CHECK_EQ(word2, "");
  CHECK_EQ(word3, "");
  CHECK(RE2::PartialMatch("bar", r, &word1, &word2, &word3));
  CHECK_EQ(word1, "");
  CHECK_EQ(word2, "bar");
  CHECK_EQ(word3, "");
  CHECK(RE2::PartialMatch("baz", r, &word1, &word2, &word3));
  CHECK_EQ(word1, "");
  CHECK_EQ(word2, "");
  CHECK_EQ(word3, "baz");
  CHECK(!RE2::PartialMatch("f", r, &word1, &word2, &word3));

  string a;
  CHECK(RE2::FullMatch("hello", "(foo)|hello", &a));
  CHECK_EQ(a, "");
}

TEST(RE2, Match) {
  RE2 re("((\\w+):([0-9]+))");   // extracts host and port
  StringPiece group[4];

  // No match.
  StringPiece s = "zyzzyva";
  CHECK(!re.Match(s, 0, s.size(), RE2::UNANCHORED,
                  group, arraysize(group)));

  // Matches and extracts.
  s = "a chrisr:9000 here";
  CHECK(re.Match(s, 0, s.size(), RE2::UNANCHORED,
                 group, arraysize(group)));
  CHECK_EQ(group[0], "chrisr:9000");
  CHECK_EQ(group[1], "chrisr:9000");
  CHECK_EQ(group[2], "chrisr");
  CHECK_EQ(group[3], "9000");

  string all, host;
  int port;
  CHECK(RE2::PartialMatch("a chrisr:9000 here", re, &all, &host, &port));
  CHECK_EQ(all, "chrisr:9000");
  CHECK_EQ(host, "chrisr");
  CHECK_EQ(port, 9000);
}

static void TestRecursion(int size, const char *pattern) {
  // Fill up a string repeating the pattern given
  string domain;
  domain.resize(size);
  int patlen = strlen(pattern);
  for (int i = 0; i < size; ++i) {
    domain[i] = pattern[i % patlen];
  }
  // Just make sure it doesn't crash due to too much recursion.
  RE2 re("([a-zA-Z0-9]|-)+(\\.([a-zA-Z0-9]|-)+)*(\\.)?", RE2::Quiet);
  RE2::FullMatch(domain, re);
}

// A meta-quoted string, interpreted as a pattern, should always match
// the original unquoted string.
static void TestQuoteMeta(string unquoted,
                          const RE2::Options& options = RE2::DefaultOptions) {
  string quoted = RE2::QuoteMeta(unquoted);
  RE2 re(quoted, options);
  EXPECT_TRUE_M(RE2::FullMatch(unquoted, re),
                "Unquoted='" + unquoted + "', quoted='" + quoted + "'.");
}

// A meta-quoted string, interpreted as a pattern, should always match
// the original unquoted string.
static void NegativeTestQuoteMeta(string unquoted, string should_not_match,
                                  const RE2::Options& options = RE2::DefaultOptions) {
  string quoted = RE2::QuoteMeta(unquoted);
  RE2 re(quoted, options);
  EXPECT_FALSE_M(RE2::FullMatch(should_not_match, re),
                 "Unquoted='" + unquoted + "', quoted='" + quoted + "'.");
}

// Tests that quoted meta characters match their original strings,
// and that a few things that shouldn't match indeed do not.
TEST(QuoteMeta, Simple) {
  TestQuoteMeta("foo");
  TestQuoteMeta("foo.bar");
  TestQuoteMeta("foo\\.bar");
  TestQuoteMeta("[1-9]");
  TestQuoteMeta("1.5-2.0?");
  TestQuoteMeta("\\d");
  TestQuoteMeta("Who doesn't like ice cream?");
  TestQuoteMeta("((a|b)c?d*e+[f-h]i)");
  TestQuoteMeta("((?!)xxx).*yyy");
  TestQuoteMeta("([");
}
TEST(QuoteMeta, SimpleNegative) {
  NegativeTestQuoteMeta("foo", "bar");
  NegativeTestQuoteMeta("...", "bar");
  NegativeTestQuoteMeta("\\.", ".");
  NegativeTestQuoteMeta("\\.", "..");
  NegativeTestQuoteMeta("(a)", "a");
  NegativeTestQuoteMeta("(a|b)", "a");
  NegativeTestQuoteMeta("(a|b)", "(a)");
  NegativeTestQuoteMeta("(a|b)", "a|b");
  NegativeTestQuoteMeta("[0-9]", "0");
  NegativeTestQuoteMeta("[0-9]", "0-9");
  NegativeTestQuoteMeta("[0-9]", "[9]");
  NegativeTestQuoteMeta("((?!)xxx)", "xxx");
}

TEST(QuoteMeta, Latin1) {
  TestQuoteMeta("3\xb2 = 9", RE2::Latin1);
}

TEST(QuoteMeta, UTF8) {
  TestQuoteMeta("Plácido Domingo");
  TestQuoteMeta("xyz");  // No fancy utf8.
  TestQuoteMeta("\xc2\xb0");  // 2-byte utf8 -- a degree symbol.
  TestQuoteMeta("27\xc2\xb0 degrees");  // As a middle character.
  TestQuoteMeta("\xe2\x80\xb3");  // 3-byte utf8 -- a double prime.
  TestQuoteMeta("\xf0\x9d\x85\x9f");  // 4-byte utf8 -- a music note.
  TestQuoteMeta("27\xc2\xb0");  // Interpreted as Latin-1, this should
                                // still work.
  NegativeTestQuoteMeta("27\xc2\xb0",
                        "27\\\xc2\\\xb0");  // 2-byte utf8 -- a degree symbol.
}

TEST(QuoteMeta, HasNull) {
  string has_null;

  // string with one null character
  has_null += '\0';
  TestQuoteMeta(has_null);
  NegativeTestQuoteMeta(has_null, "");

  // Don't want null-followed-by-'1' to be interpreted as '\01'.
  has_null += '1';
  TestQuoteMeta(has_null);
  NegativeTestQuoteMeta(has_null, "\1");
}

TEST(ProgramSize, BigProgram) {
  RE2 re_simple("simple regexp");
  RE2 re_medium("medium.*regexp");
  RE2 re_complex("hard.{1,128}regexp");

  CHECK_GT(re_simple.ProgramSize(), 0);
  CHECK_GT(re_medium.ProgramSize(), re_simple.ProgramSize());
  CHECK_GT(re_complex.ProgramSize(), re_medium.ProgramSize());
}

// Issue 956519: handling empty character sets was
// causing NULL dereference.  This tests a few empty character sets.
// (The way to get an empty character set is to negate a full one.)
TEST(EmptyCharset, Fuzz) {
  static const char *empties[] = {
    "[^\\S\\s]",
    "[^\\S[:space:]]",
    "[^\\D\\d]",
    "[^\\D[:digit:]]"
  };
  for (int i = 0; i < arraysize(empties); i++)
    CHECK(!RE2(empties[i]).Match("abc", 0, 3, RE2::UNANCHORED, NULL, 0));
}

// Test that named groups work correctly.
TEST(Capture, NamedGroups) {
  {
    RE2 re("(hello world)");
    CHECK_EQ(re.NumberOfCapturingGroups(), 1);
    const map<string, int>& m = re.NamedCapturingGroups();
    CHECK_EQ(m.size(), 0);
  }

  {
    RE2 re("(?P<A>expr(?P<B>expr)(?P<C>expr))((expr)(?P<D>expr))");
    CHECK_EQ(re.NumberOfCapturingGroups(), 6);
    const map<string, int>& m = re.NamedCapturingGroups();
    CHECK_EQ(m.size(), 4);
    CHECK_EQ(m.find("A")->second, 1);
    CHECK_EQ(m.find("B")->second, 2);
    CHECK_EQ(m.find("C")->second, 3);
    CHECK_EQ(m.find("D")->second, 6);  // $4 and $5 are anonymous
  }
}

TEST(RE2, FullMatchWithNoArgs) {
  CHECK(RE2::FullMatch("h", "h"));
  CHECK(RE2::FullMatch("hello", "hello"));
  CHECK(RE2::FullMatch("hello", "h.*o"));
  CHECK(!RE2::FullMatch("othello", "h.*o"));       // Must be anchored at front
  CHECK(!RE2::FullMatch("hello!", "h.*o"));        // Must be anchored at end
}

TEST(RE2, PartialMatch) {
  CHECK(RE2::PartialMatch("x", "x"));
  CHECK(RE2::PartialMatch("hello", "h.*o"));
  CHECK(RE2::PartialMatch("othello", "h.*o"));
  CHECK(RE2::PartialMatch("hello!", "h.*o"));
  CHECK(RE2::PartialMatch("x", "((((((((((((((((((((x))))))))))))))))))))"));
}

TEST(RE2, PartialMatchN) {
  RE2::Arg argv[2];
  const RE2::Arg* const args[2] = { &argv[0], &argv[1] };

  // 0 arg
  EXPECT_TRUE(RE2::PartialMatchN("hello", "e.*o", args, 0));
  EXPECT_FALSE(RE2::PartialMatchN("othello", "a.*o", args, 0));

  // 1 arg
  int i;
  argv[0] = &i;
  EXPECT_TRUE(RE2::PartialMatchN("1001 nights", "(\\d+)", args, 1));
  EXPECT_EQ(1001, i);
  EXPECT_FALSE(RE2::PartialMatchN("three", "(\\d+)", args, 1));

  // Multi-arg
  string s;
  argv[1] = &s;
  EXPECT_TRUE(RE2::PartialMatchN("answer: 42:life", "(\\d+):(\\w+)", args, 2));
  EXPECT_EQ(42, i);
  EXPECT_EQ("life", s);
  EXPECT_FALSE(RE2::PartialMatchN("hi1", "(\\w+)(1)", args, 2));
}

TEST(RE2, FullMatchZeroArg) {
  // Zero-arg
  CHECK(RE2::FullMatch("1001", "\\d+"));
}

TEST(RE2, FullMatchOneArg) {
  int i;

  // Single-arg
  CHECK(RE2::FullMatch("1001", "(\\d+)",   &i));
  CHECK_EQ(i, 1001);
  CHECK(RE2::FullMatch("-123", "(-?\\d+)", &i));
  CHECK_EQ(i, -123);
  CHECK(!RE2::FullMatch("10", "()\\d+", &i));
  CHECK(!RE2::FullMatch("1234567890123456789012345678901234567890",
                       "(\\d+)", &i));
}

TEST(RE2, FullMatchIntegerArg) {
  int i;

  // Digits surrounding integer-arg
  CHECK(RE2::FullMatch("1234", "1(\\d*)4", &i));
  CHECK_EQ(i, 23);
  CHECK(RE2::FullMatch("1234", "(\\d)\\d+", &i));
  CHECK_EQ(i, 1);
  CHECK(RE2::FullMatch("-1234", "(-\\d)\\d+", &i));
  CHECK_EQ(i, -1);
  CHECK(RE2::PartialMatch("1234", "(\\d)", &i));
  CHECK_EQ(i, 1);
  CHECK(RE2::PartialMatch("-1234", "(-\\d)", &i));
  CHECK_EQ(i, -1);
}

TEST(RE2, FullMatchStringArg) {
  string s;
  // String-arg
  CHECK(RE2::FullMatch("hello", "h(.*)o", &s));
  CHECK_EQ(s, string("ell"));
}

TEST(RE2, FullMatchStringPieceArg) {
  int i;
  // StringPiece-arg
  StringPiece sp;
  CHECK(RE2::FullMatch("ruby:1234", "(\\w+):(\\d+)", &sp, &i));
  CHECK_EQ(sp.size(), 4);
  CHECK(memcmp(sp.data(), "ruby", 4) == 0);
  CHECK_EQ(i, 1234);
}

TEST(RE2, FullMatchMultiArg) {
  int i;
  string s;
  // Multi-arg
  CHECK(RE2::FullMatch("ruby:1234", "(\\w+):(\\d+)", &s, &i));
  CHECK_EQ(s, string("ruby"));
  CHECK_EQ(i, 1234);
}

TEST(RE2, FullMatchN) {
  RE2::Arg argv[2];
  const RE2::Arg* const args[2] = { &argv[0], &argv[1] };

  // 0 arg
  EXPECT_TRUE(RE2::FullMatchN("hello", "h.*o", args, 0));
  EXPECT_FALSE(RE2::FullMatchN("othello", "h.*o", args, 0));

  // 1 arg
  int i;
  argv[0] = &i;
  EXPECT_TRUE(RE2::FullMatchN("1001", "(\\d+)", args, 1));
  EXPECT_EQ(1001, i);
  EXPECT_FALSE(RE2::FullMatchN("three", "(\\d+)", args, 1));

  // Multi-arg
  string s;
  argv[1] = &s;
  EXPECT_TRUE(RE2::FullMatchN("42:life", "(\\d+):(\\w+)", args, 2));
  EXPECT_EQ(42, i);
  EXPECT_EQ("life", s);
  EXPECT_FALSE(RE2::FullMatchN("hi1", "(\\w+)(1)", args, 2));
}

TEST(RE2, FullMatchIgnoredArg) {
  int i;
  string s;
  // Ignored arg
  CHECK(RE2::FullMatch("ruby:1234", "(\\w+)(:)(\\d+)", &s, (void*)NULL, &i));
  CHECK_EQ(s, string("ruby"));
  CHECK_EQ(i, 1234);
}

TEST(RE2, FullMatchTypedNullArg) {
  string s;

  // Ignore non-void* NULL arg
  CHECK(RE2::FullMatch("hello", "he(.*)lo", (char*)NULL));
  CHECK(RE2::FullMatch("hello", "h(.*)o", (string*)NULL));
  CHECK(RE2::FullMatch("hello", "h(.*)o", (StringPiece*)NULL));
  CHECK(RE2::FullMatch("1234", "(.*)", (int*)NULL));
  CHECK(RE2::FullMatch("1234567890123456", "(.*)", (long long*)NULL));
  CHECK(RE2::FullMatch("123.4567890123456", "(.*)", (double*)NULL));
  CHECK(RE2::FullMatch("123.4567890123456", "(.*)", (float*)NULL));

  // Fail on non-void* NULL arg if the match doesn't parse for the given type.
  CHECK(!RE2::FullMatch("hello", "h(.*)lo", &s, (char*)NULL));
  CHECK(!RE2::FullMatch("hello", "(.*)", (int*)NULL));
  CHECK(!RE2::FullMatch("1234567890123456", "(.*)", (int*)NULL));
  CHECK(!RE2::FullMatch("hello", "(.*)", (double*)NULL));
  CHECK(!RE2::FullMatch("hello", "(.*)", (float*)NULL));
}

#ifndef WIN32
// Check that numeric parsing code does not read past the end of
// the number being parsed.
TEST(RE2, NULTerminated) {
  char *v;
  int x;
  long pagesize = sysconf(_SC_PAGE_SIZE);

#ifndef MAP_ANONYMOUS
#define MAP_ANONYMOUS MAP_ANON
#endif
  v = static_cast<char*>(mmap(NULL, 2*pagesize, PROT_READ|PROT_WRITE,
                              MAP_ANONYMOUS|MAP_PRIVATE, -1, 0));
  CHECK(v != reinterpret_cast<char*>(-1));
  LOG(INFO) << "Memory at " << (void*)v;
  CHECK_EQ(munmap(v + pagesize, pagesize), 0) << " error " << errno;
  v[pagesize - 1] = '1';

  x = 0;
  CHECK(RE2::FullMatch(StringPiece(v + pagesize - 1, 1), "(.*)", &x));
  CHECK_EQ(x, 1);
}
#endif

TEST(RE2, FullMatchTypeTests) {
  // Type tests
  string zeros(100, '0');
  {
    char c;
    CHECK(RE2::FullMatch("Hello", "(H)ello", &c));
    CHECK_EQ(c, 'H');
  }
  {
    unsigned char c;
    CHECK(RE2::FullMatch("Hello", "(H)ello", &c));
    CHECK_EQ(c, static_cast<unsigned char>('H'));
  }
  {
    int16 v;
    CHECK(RE2::FullMatch("100",     "(-?\\d+)", &v));    CHECK_EQ(v, 100);
    CHECK(RE2::FullMatch("-100",    "(-?\\d+)", &v));    CHECK_EQ(v, -100);
    CHECK(RE2::FullMatch("32767",   "(-?\\d+)", &v));    CHECK_EQ(v, 32767);
    CHECK(RE2::FullMatch("-32768",  "(-?\\d+)", &v));    CHECK_EQ(v, -32768);
    CHECK(!RE2::FullMatch("-32769", "(-?\\d+)", &v));
    CHECK(!RE2::FullMatch("32768",  "(-?\\d+)", &v));
  }
  {
    uint16 v;
    CHECK(RE2::FullMatch("100",     "(\\d+)", &v));    CHECK_EQ(v, 100);
    CHECK(RE2::FullMatch("32767",   "(\\d+)", &v));    CHECK_EQ(v, 32767);
    CHECK(RE2::FullMatch("65535",   "(\\d+)", &v));    CHECK_EQ(v, 65535);
    CHECK(!RE2::FullMatch("65536",  "(\\d+)", &v));
  }
  {
    int32 v;
    static const int32 max = 0x7fffffff;
    static const int32 min = -max - 1;
    CHECK(RE2::FullMatch("100",          "(-?\\d+)", &v)); CHECK_EQ(v, 100);
    CHECK(RE2::FullMatch("-100",         "(-?\\d+)", &v)); CHECK_EQ(v, -100);
    CHECK(RE2::FullMatch("2147483647",   "(-?\\d+)", &v)); CHECK_EQ(v, max);
    CHECK(RE2::FullMatch("-2147483648",  "(-?\\d+)", &v)); CHECK_EQ(v, min);
    CHECK(!RE2::FullMatch("-2147483649", "(-?\\d+)", &v));
    CHECK(!RE2::FullMatch("2147483648",  "(-?\\d+)", &v));

    CHECK(RE2::FullMatch(zeros + "2147483647", "(-?\\d+)", &v));
    CHECK_EQ(v, max);
    CHECK(RE2::FullMatch("-" + zeros + "2147483648", "(-?\\d+)", &v));
    CHECK_EQ(v, min);

    CHECK(!RE2::FullMatch("-" + zeros + "2147483649", "(-?\\d+)", &v));
    CHECK(RE2::FullMatch("0x7fffffff", "(.*)", RE2::CRadix(&v)));
    CHECK_EQ(v, max);
    CHECK(!RE2::FullMatch("000x7fffffff", "(.*)", RE2::CRadix(&v)));
  }
  {
    uint32 v;
    static const uint32 max = 0xfffffffful;
    CHECK(RE2::FullMatch("100",         "(\\d+)", &v)); CHECK_EQ(v, 100);
    CHECK(RE2::FullMatch("4294967295",  "(\\d+)", &v)); CHECK_EQ(v, max);
    CHECK(!RE2::FullMatch("4294967296", "(\\d+)", &v));
    CHECK(!RE2::FullMatch("-1",         "(\\d+)", &v));

    CHECK(RE2::FullMatch(zeros + "4294967295", "(\\d+)", &v)); CHECK_EQ(v, max);
  }
  {
    int64 v;
    static const int64 max = 0x7fffffffffffffffull;
    static const int64 min = -max - 1;
    char buf[32];

    CHECK(RE2::FullMatch("100",  "(-?\\d+)", &v)); CHECK_EQ(v, 100);
    CHECK(RE2::FullMatch("-100", "(-?\\d+)", &v)); CHECK_EQ(v, -100);

    snprintf(buf, sizeof(buf), "%lld", (long long int)max);
    CHECK(RE2::FullMatch(buf,    "(-?\\d+)", &v)); CHECK_EQ(v, max);

    snprintf(buf, sizeof(buf), "%lld", (long long int)min);
    CHECK(RE2::FullMatch(buf,    "(-?\\d+)", &v)); CHECK_EQ(v, min);

    snprintf(buf, sizeof(buf), "%lld", (long long int)max);
    assert(buf[strlen(buf)-1] != '9');
    buf[strlen(buf)-1]++;
    CHECK(!RE2::FullMatch(buf,   "(-?\\d+)", &v));

    snprintf(buf, sizeof(buf), "%lld", (long long int)min);
    assert(buf[strlen(buf)-1] != '9');
    buf[strlen(buf)-1]++;
    CHECK(!RE2::FullMatch(buf,   "(-?\\d+)", &v));
  }
  {
    uint64 v;
    int64 v2;
    static const uint64 max = 0xffffffffffffffffull;
    char buf[32];

    CHECK(RE2::FullMatch("100",  "(-?\\d+)", &v));  CHECK_EQ(v, 100);
    CHECK(RE2::FullMatch("-100", "(-?\\d+)", &v2)); CHECK_EQ(v2, -100);

    snprintf(buf, sizeof(buf), "%llu", (long long unsigned)max);
    CHECK(RE2::FullMatch(buf,    "(-?\\d+)", &v)); CHECK_EQ(v, max);

    assert(buf[strlen(buf)-1] != '9');
    buf[strlen(buf)-1]++;
    CHECK(!RE2::FullMatch(buf,   "(-?\\d+)", &v));
  }
}

TEST(RE2, FloatingPointFullMatchTypes) {
  string zeros(100, '0');
  {
    float v;
    CHECK(RE2::FullMatch("100",   "(.*)", &v));  CHECK_EQ(v, 100);
    CHECK(RE2::FullMatch("-100.", "(.*)", &v));  CHECK_EQ(v, -100);
    CHECK(RE2::FullMatch("1e23",  "(.*)", &v));  CHECK_EQ(v, float(1e23));

    CHECK(RE2::FullMatch(zeros + "1e23",  "(.*)", &v));
    CHECK_EQ(v, float(1e23));

    // 6700000000081920.1 is an edge case.
    // 6700000000081920 is exactly halfway between
    // two float32s, so the .1 should make it round up.
    // However, the .1 is outside the precision possible with
    // a float64: the nearest float64 is 6700000000081920.
    // So if the code uses strtod and then converts to float32,
    // round-to-even will make it round down instead of up.
    // To pass the test, the parser must call strtof directly.
    // This test case is carefully chosen to use only a 17-digit
    // number, since C does not guarantee to get the correctly
    // rounded answer for strtod and strtof unless the input is
    // short.
    CHECK(RE2::FullMatch("0.1", "(.*)", &v));
    CHECK_EQ(v, 0.1f) << StringPrintf("%.8g != %.8g", v, 0.1f);
    CHECK(RE2::FullMatch("6700000000081920.1", "(.*)", &v));
    CHECK_EQ(v, 6700000000081920.1f)
      << StringPrintf("%.8g != %.8g", v, 6700000000081920.1f);
  }
  {
    double v;
    CHECK(RE2::FullMatch("100",   "(.*)", &v));  CHECK_EQ(v, 100);
    CHECK(RE2::FullMatch("-100.", "(.*)", &v));  CHECK_EQ(v, -100);
    CHECK(RE2::FullMatch("1e23",  "(.*)", &v));  CHECK_EQ(v, 1e23);
    CHECK(RE2::FullMatch(zeros + "1e23", "(.*)", &v));
    CHECK_EQ(v, double(1e23));

    CHECK(RE2::FullMatch("0.1", "(.*)", &v));
    CHECK_EQ(v, 0.1) << StringPrintf("%.17g != %.17g", v, 0.1);
    CHECK(RE2::FullMatch("1.00000005960464485", "(.*)", &v));
    CHECK_EQ(v, 1.0000000596046448)
      << StringPrintf("%.17g != %.17g", v, 1.0000000596046448);
  }
}

TEST(RE2, FullMatchAnchored) {
  int i;
  // Check that matching is fully anchored
  CHECK(!RE2::FullMatch("x1001", "(\\d+)",  &i));
  CHECK(!RE2::FullMatch("1001x", "(\\d+)",  &i));
  CHECK(RE2::FullMatch("x1001",  "x(\\d+)", &i)); CHECK_EQ(i, 1001);
  CHECK(RE2::FullMatch("1001x",  "(\\d+)x", &i)); CHECK_EQ(i, 1001);
}

TEST(RE2, FullMatchBraces) {
  // Braces
  CHECK(RE2::FullMatch("0abcd",  "[0-9a-f+.-]{5,}"));
  CHECK(RE2::FullMatch("0abcde", "[0-9a-f+.-]{5,}"));
  CHECK(!RE2::FullMatch("0abc",  "[0-9a-f+.-]{5,}"));
}

TEST(RE2, Complicated) {
  // Complicated RE2
  CHECK(RE2::FullMatch("foo", "foo|bar|[A-Z]"));
  CHECK(RE2::FullMatch("bar", "foo|bar|[A-Z]"));
  CHECK(RE2::FullMatch("X",   "foo|bar|[A-Z]"));
  CHECK(!RE2::FullMatch("XY", "foo|bar|[A-Z]"));
}

TEST(RE2, FullMatchEnd) {
  // Check full-match handling (needs '$' tacked on internally)
  CHECK(RE2::FullMatch("fo", "fo|foo"));
  CHECK(RE2::FullMatch("foo", "fo|foo"));
  CHECK(RE2::FullMatch("fo", "fo|foo$"));
  CHECK(RE2::FullMatch("foo", "fo|foo$"));
  CHECK(RE2::FullMatch("foo", "foo$"));
  CHECK(!RE2::FullMatch("foo$bar", "foo\\$"));
  CHECK(!RE2::FullMatch("fox", "fo|bar"));

  // Uncomment the following if we change the handling of '$' to
  // prevent it from matching a trailing newline
  if (false) {
    // Check that we don't get bitten by pcre's special handling of a
    // '\n' at the end of the string matching '$'
    CHECK(!RE2::PartialMatch("foo\n", "foo$"));
  }
}

TEST(RE2, FullMatchArgCount) {
  // Number of args
  int a[16];
  CHECK(RE2::FullMatch("", ""));

  memset(a, 0, sizeof(0));
  CHECK(RE2::FullMatch("1",
                      "(\\d){1}",
                      &a[0]));
  CHECK_EQ(a[0], 1);

  memset(a, 0, sizeof(0));
  CHECK(RE2::FullMatch("12",
                      "(\\d)(\\d)",
                      &a[0],  &a[1]));
  CHECK_EQ(a[0], 1);
  CHECK_EQ(a[1], 2);

  memset(a, 0, sizeof(0));
  CHECK(RE2::FullMatch("123",
                      "(\\d)(\\d)(\\d)",
                      &a[0],  &a[1],  &a[2]));
  CHECK_EQ(a[0], 1);
  CHECK_EQ(a[1], 2);
  CHECK_EQ(a[2], 3);

  memset(a, 0, sizeof(0));
  CHECK(RE2::FullMatch("1234",
                      "(\\d)(\\d)(\\d)(\\d)",
                      &a[0],  &a[1],  &a[2],  &a[3]));
  CHECK_EQ(a[0], 1);
  CHECK_EQ(a[1], 2);
  CHECK_EQ(a[2], 3);
  CHECK_EQ(a[3], 4);

  memset(a, 0, sizeof(0));
  CHECK(RE2::FullMatch("12345",
                      "(\\d)(\\d)(\\d)(\\d)(\\d)",
                      &a[0],  &a[1],  &a[2],  &a[3],
                      &a[4]));
  CHECK_EQ(a[0], 1);
  CHECK_EQ(a[1], 2);
  CHECK_EQ(a[2], 3);
  CHECK_EQ(a[3], 4);
  CHECK_EQ(a[4], 5);

  memset(a, 0, sizeof(0));
  CHECK(RE2::FullMatch("123456",
                      "(\\d)(\\d)(\\d)(\\d)(\\d)(\\d)",
                      &a[0],  &a[1],  &a[2],  &a[3],
                      &a[4],  &a[5]));
  CHECK_EQ(a[0], 1);
  CHECK_EQ(a[1], 2);
  CHECK_EQ(a[2], 3);
  CHECK_EQ(a[3], 4);
  CHECK_EQ(a[4], 5);
  CHECK_EQ(a[5], 6);

  memset(a, 0, sizeof(0));
  CHECK(RE2::FullMatch("1234567",
                      "(\\d)(\\d)(\\d)(\\d)(\\d)(\\d)(\\d)",
                      &a[0],  &a[1],  &a[2],  &a[3],
                      &a[4],  &a[5],  &a[6]));
  CHECK_EQ(a[0], 1);
  CHECK_EQ(a[1], 2);
  CHECK_EQ(a[2], 3);
  CHECK_EQ(a[3], 4);
  CHECK_EQ(a[4], 5);
  CHECK_EQ(a[5], 6);
  CHECK_EQ(a[6], 7);

  memset(a, 0, sizeof(0));
  CHECK(RE2::FullMatch("1234567890123456",
                      "(\\d)(\\d)(\\d)(\\d)(\\d)(\\d)(\\d)(\\d)"
                      "(\\d)(\\d)(\\d)(\\d)(\\d)(\\d)(\\d)(\\d)",
                      &a[0],  &a[1],  &a[2],  &a[3],
                      &a[4],  &a[5],  &a[6],  &a[7],
                      &a[8],  &a[9],  &a[10], &a[11],
                      &a[12], &a[13], &a[14], &a[15]));
  CHECK_EQ(a[0], 1);
  CHECK_EQ(a[1], 2);
  CHECK_EQ(a[2], 3);
  CHECK_EQ(a[3], 4);
  CHECK_EQ(a[4], 5);
  CHECK_EQ(a[5], 6);
  CHECK_EQ(a[6], 7);
  CHECK_EQ(a[7], 8);
  CHECK_EQ(a[8], 9);
  CHECK_EQ(a[9], 0);
  CHECK_EQ(a[10], 1);
  CHECK_EQ(a[11], 2);
  CHECK_EQ(a[12], 3);
  CHECK_EQ(a[13], 4);
  CHECK_EQ(a[14], 5);
  CHECK_EQ(a[15], 6);
}

TEST(RE2, Accessors) {
  // Check the pattern() accessor
  {
    const string kPattern = "http://([^/]+)/.*";
    const RE2 re(kPattern);
    CHECK_EQ(kPattern, re.pattern());
  }

  // Check RE2 error field.
  {
    RE2 re("foo");
    CHECK(re.error().empty());  // Must have no error
    CHECK(re.ok());
    CHECK(re.error_code() == RE2::NoError);
  }
}

TEST(RE2, UTF8) {
  // Check UTF-8 handling
  // Three Japanese characters (nihongo)
  const char utf8_string[] = {
       0xe6, 0x97, 0xa5, // 65e5
       0xe6, 0x9c, 0xac, // 627c
       0xe8, 0xaa, 0x9e, // 8a9e
       0
  };
  const char utf8_pattern[] = {
       '.',
       0xe6, 0x9c, 0xac, // 627c
       '.',
       0
  };

  // Both should match in either mode, bytes or UTF-8
  RE2 re_test1(".........", RE2::Latin1);
  CHECK(RE2::FullMatch(utf8_string, re_test1));
  RE2 re_test2("...");
  CHECK(RE2::FullMatch(utf8_string, re_test2));

  // Check that '.' matches one byte or UTF-8 character
  // according to the mode.
  string s;
  RE2 re_test3("(.)", RE2::Latin1);
  CHECK(RE2::PartialMatch(utf8_string, re_test3, &s));
  CHECK_EQ(s, string("\xe6"));
  RE2 re_test4("(.)");
  CHECK(RE2::PartialMatch(utf8_string, re_test4, &s));
  CHECK_EQ(s, string("\xe6\x97\xa5"));

  // Check that string matches itself in either mode
  RE2 re_test5(utf8_string, RE2::Latin1);
  CHECK(RE2::FullMatch(utf8_string, re_test5));
  RE2 re_test6(utf8_string);
  CHECK(RE2::FullMatch(utf8_string, re_test6));

  // Check that pattern matches string only in UTF8 mode
  RE2 re_test7(utf8_pattern, RE2::Latin1);
  CHECK(!RE2::FullMatch(utf8_string, re_test7));
  RE2 re_test8(utf8_pattern);
  CHECK(RE2::FullMatch(utf8_string, re_test8));
}

TEST(RE2, UngreedyUTF8) {
  // Check that ungreedy, UTF8 regular expressions don't match when they
  // oughtn't -- see bug 82246.
  {
    // This code always worked.
    const char* pattern = "\\w+X";
    const string target = "a aX";
    RE2 match_sentence(pattern, RE2::Latin1);
    RE2 match_sentence_re(pattern);

    CHECK(!RE2::FullMatch(target, match_sentence));
    CHECK(!RE2::FullMatch(target, match_sentence_re));
  }
  {
    const char* pattern = "(?U)\\w+X";
    const string target = "a aX";
    RE2 match_sentence(pattern, RE2::Latin1);
    CHECK_EQ(match_sentence.error(), "");
    RE2 match_sentence_re(pattern);

    CHECK(!RE2::FullMatch(target, match_sentence));
    CHECK(!RE2::FullMatch(target, match_sentence_re));
  }
}

TEST(RE2, Rejects) {
  { RE2 re("a\\1", RE2::Quiet); CHECK(!re.ok()); }
  {
    RE2 re("a[x", RE2::Quiet);
    CHECK(!re.ok());
  }
  {
    RE2 re("a[z-a]", RE2::Quiet);
    CHECK(!re.ok());
  }
  {
    RE2 re("a[[:foobar:]]", RE2::Quiet);
    CHECK(!re.ok());
  }
  {
    RE2 re("a(b", RE2::Quiet);
    CHECK(!re.ok());
  }
  {
    RE2 re("a\\", RE2::Quiet);
    CHECK(!re.ok());
  }
}

TEST(RE2, NoCrash) {
  // Test that using a bad regexp doesn't crash.
  {
    RE2 re("a\\", RE2::Quiet);
    CHECK(!re.ok());
    CHECK(!RE2::PartialMatch("a\\b", re));
  }

  // Test that using an enormous regexp doesn't crash
  {
    RE2 re("(((.{100}){100}){100}){100}", RE2::Quiet);
    CHECK(!re.ok());
    CHECK(!RE2::PartialMatch("aaa", re));
  }

  // Test that a crazy regexp still compiles and runs.
  {
    RE2 re(".{512}x", RE2::Quiet);
    CHECK(re.ok());
    string s;
    s.append(515, 'c');
    s.append("x");
    CHECK(RE2::PartialMatch(s, re));
  }
}

TEST(RE2, Recursion) {
  // Test that recursion is stopped.
  // This test is PCRE-legacy -- there's no recursion in RE2.
  int bytes = 15 * 1024;  // enough to crash PCRE
  TestRecursion(bytes, ".");
  TestRecursion(bytes, "a");
  TestRecursion(bytes, "a.");
  TestRecursion(bytes, "ab.");
  TestRecursion(bytes, "abc.");
}

TEST(RE2, BigCountedRepetition) {
  // Test that counted repetition works, given tons of memory.
  RE2::Options opt;
  opt.set_max_mem(256<<20);

  RE2 re(".{512}x", opt);
  CHECK(re.ok());
  string s;
  s.append(515, 'c');
  s.append("x");
  CHECK(RE2::PartialMatch(s, re));
}

TEST(RE2, DeepRecursion) {
  // Test for deep stack recursion.  This would fail with a
  // segmentation violation due to stack overflow before pcre was
  // patched.
  // Again, a PCRE legacy test.  RE2 doesn't recurse.
  string comment("x*");
  string a(131072, 'a');
  comment += a;
  comment += "*x";
  RE2 re("((?:\\s|xx.*\n|x[*](?:\n|.)*?[*]x)*)");
  CHECK(RE2::FullMatch(comment, re));
}

// Suggested by Josh Hyman.  Failed when SearchOnePass was
// not implementing case-folding.
TEST(CaseInsensitive, MatchAndConsume) {
  string result;
  string text = "A fish named *Wanda*";
  StringPiece sp(text);

  EXPECT_TRUE(RE2::PartialMatch(sp, "(?i)([wand]{5})", &result));
  EXPECT_TRUE(RE2::FindAndConsume(&sp, "(?i)([wand]{5})", &result));
}

// RE2 should permit implicit conversions from string, StringPiece, const char*,
// and C string literals.
TEST(RE2, ImplicitConversions) {
  string re_string(".");
  StringPiece re_stringpiece(".");
  const char* re_cstring = ".";
  EXPECT_TRUE(RE2::PartialMatch("e", re_string));
  EXPECT_TRUE(RE2::PartialMatch("e", re_stringpiece));
  EXPECT_TRUE(RE2::PartialMatch("e", re_cstring));
  EXPECT_TRUE(RE2::PartialMatch("e", "."));
}

// Bugs introduced by 8622304
TEST(RE2, CL8622304) {
  // reported by ingow
  string dir;
  EXPECT_TRUE(RE2::FullMatch("D", "([^\\\\])"));  // ok
  EXPECT_TRUE(RE2::FullMatch("D", "([^\\\\])", &dir));  // fails

  // reported by jacobsa
  string key, val;
  EXPECT_TRUE(RE2::PartialMatch("bar:1,0x2F,030,4,5;baz:true;fooby:false,true",
              "(\\w+)(?::((?:[^;\\\\]|\\\\.)*))?;?",
              &key,
              &val));
  EXPECT_EQ(key, "bar");
  EXPECT_EQ(val, "1,0x2F,030,4,5");
}


// Check that RE2 returns correct regexp pieces on error.
// In particular, make sure it returns whole runes
// and that it always reports invalid UTF-8.
// Also check that Perl error flag piece is big enough.
static struct ErrorTest {
  const char *regexp;
  const char *error;
} error_tests[] = {
  { "ab\\αcd", "\\α" },
  { "ef\\x☺01", "\\x☺0" },
  { "gh\\x1☺01", "\\x1☺" },
  { "ij\\x1", "\\x1" },
  { "kl\\x", "\\x" },
  { "uv\\x{0000☺}", "\\x{0000☺" },
  { "wx\\p{ABC", "\\p{ABC" },
  { "yz(?smiUX:abc)", "(?smiUX" },   // used to return (?s but the error is X
  { "aa(?sm☺i", "(?sm☺" },
  { "bb[abc", "[abc" },

  { "mn\\x1\377", "" },  // no argument string returned for invalid UTF-8
  { "op\377qr", "" },
  { "st\\x{00000\377", "" },
  { "zz\\p{\377}", "" },
  { "zz\\x{00\377}", "" },
  { "zz(?P<name\377>abc)", "" },
};
TEST(RE2, ErrorArgs) {
  for (int i = 0; i < arraysize(error_tests); i++) {
    RE2 re(error_tests[i].regexp, RE2::Quiet);
    EXPECT_FALSE(re.ok());
    EXPECT_EQ(re.error_arg(), error_tests[i].error) << re.error();
  }
}

// Check that "never match \n" mode never matches \n.
static struct NeverTest {
  const char* regexp;
  const char* text;
  const char* match;
} never_tests[] = {
  { "(.*)", "abc\ndef\nghi\n", "abc" },
  { "(?s)(abc.*def)", "abc\ndef\n", NULL },
  { "(abc(.|\n)*def)", "abc\ndef\n", NULL },
  { "(abc[^x]*def)", "abc\ndef\n", NULL },
  { "(abc[^x]*def)", "abczzzdef\ndef\n", "abczzzdef" },
};
TEST(RE2, NeverNewline) {
  RE2::Options opt;
  opt.set_never_nl(true);
  for (int i = 0; i < arraysize(never_tests); i++) {
    const NeverTest& t = never_tests[i];
    RE2 re(t.regexp, opt);
    if (t.match == NULL) {
      EXPECT_FALSE(re.PartialMatch(t.text, re));
    } else {
      StringPiece m;
      EXPECT_TRUE(re.PartialMatch(t.text, re, &m));
      EXPECT_EQ(m, t.match);
    }
  }
}

// Check that there are no capturing groups in "never capture" mode.
TEST(RE2, NeverCapture) {
  RE2::Options opt;
  opt.set_never_capture(true);
  RE2 re("(r)(e)", opt);
  EXPECT_EQ(0, re.NumberOfCapturingGroups());
}

// Bitstate bug was looking at submatch[0] even if nsubmatch == 0.
// Triggered by a failed DFA search falling back to Bitstate when
// using Match with a NULL submatch set.  Bitstate tried to read
// the submatch[0] entry even if nsubmatch was 0.
TEST(RE2, BitstateCaptureBug) {
  RE2::Options opt;
  opt.set_max_mem(20000);
  RE2 re("(_________$)", opt);
  StringPiece s = "xxxxxxxxxxxxxxxxxxxxxxxxxx_________x";
  EXPECT_FALSE(re.Match(s, 0, s.size(), RE2::UNANCHORED, NULL, 0));
}

// C++ version of bug 609710.
TEST(RE2, UnicodeClasses) {
  const string str = "ABCDEFGHI譚永鋒";
  string a, b, c;

  EXPECT_TRUE(RE2::FullMatch("A", "\\p{L}"));
  EXPECT_TRUE(RE2::FullMatch("A", "\\p{Lu}"));
  EXPECT_FALSE(RE2::FullMatch("A", "\\p{Ll}"));
  EXPECT_FALSE(RE2::FullMatch("A", "\\P{L}"));
  EXPECT_FALSE(RE2::FullMatch("A", "\\P{Lu}"));
  EXPECT_TRUE(RE2::FullMatch("A", "\\P{Ll}"));

  EXPECT_TRUE(RE2::FullMatch("譚", "\\p{L}"));
  EXPECT_FALSE(RE2::FullMatch("譚", "\\p{Lu}"));
  EXPECT_FALSE(RE2::FullMatch("譚", "\\p{Ll}"));
  EXPECT_FALSE(RE2::FullMatch("譚", "\\P{L}"));
  EXPECT_TRUE(RE2::FullMatch("譚", "\\P{Lu}"));
  EXPECT_TRUE(RE2::FullMatch("譚", "\\P{Ll}"));

  EXPECT_TRUE(RE2::FullMatch("永", "\\p{L}"));
  EXPECT_FALSE(RE2::FullMatch("永", "\\p{Lu}"));
  EXPECT_FALSE(RE2::FullMatch("永", "\\p{Ll}"));
  EXPECT_FALSE(RE2::FullMatch("永", "\\P{L}"));
  EXPECT_TRUE(RE2::FullMatch("永", "\\P{Lu}"));
  EXPECT_TRUE(RE2::FullMatch("永", "\\P{Ll}"));

  EXPECT_TRUE(RE2::FullMatch("鋒", "\\p{L}"));
  EXPECT_FALSE(RE2::FullMatch("鋒", "\\p{Lu}"));
  EXPECT_FALSE(RE2::FullMatch("鋒", "\\p{Ll}"));
  EXPECT_FALSE(RE2::FullMatch("鋒", "\\P{L}"));
  EXPECT_TRUE(RE2::FullMatch("鋒", "\\P{Lu}"));
  EXPECT_TRUE(RE2::FullMatch("鋒", "\\P{Ll}"));

  EXPECT_TRUE(RE2::PartialMatch(str, "(.).*?(.).*?(.)", &a, &b, &c));
  EXPECT_EQ("A", a);
  EXPECT_EQ("B", b);
  EXPECT_EQ("C", c);

  EXPECT_TRUE(RE2::PartialMatch(str, "(.).*?([\\p{L}]).*?(.)", &a, &b, &c));
  EXPECT_EQ("A", a);
  EXPECT_EQ("B", b);
  EXPECT_EQ("C", c);

  EXPECT_FALSE(RE2::PartialMatch(str, "\\P{L}"));

  EXPECT_TRUE(RE2::PartialMatch(str, "(.).*?([\\p{Lu}]).*?(.)", &a, &b, &c));
  EXPECT_EQ("A", a);
  EXPECT_EQ("B", b);
  EXPECT_EQ("C", c);

  EXPECT_FALSE(RE2::PartialMatch(str, "[^\\p{Lu}\\p{Lo}]"));

  EXPECT_TRUE(RE2::PartialMatch(str, ".*(.).*?([\\p{Lu}\\p{Lo}]).*?(.)", &a, &b, &c));
  EXPECT_EQ("譚", a);
  EXPECT_EQ("永", b);
  EXPECT_EQ("鋒", c);
}

// Bug reported by saito. 2009/02/17
TEST(RE2, NullVsEmptyString) {
  RE2 re2(".*");
  StringPiece v1("");
  EXPECT_TRUE(RE2::FullMatch(v1, re2));

  StringPiece v2;
  EXPECT_TRUE(RE2::FullMatch(v2, re2));
}

// Issue 1816809
TEST(RE2, Bug1816809) {
  RE2 re("(((((llx((-3)|(4)))(;(llx((-3)|(4))))*))))");
  StringPiece piece("llx-3;llx4");
  string x;
  EXPECT_TRUE(RE2::Consume(&piece, re, &x));
}

// Issue 3061120
TEST(RE2, Bug3061120) {
  RE2 re("(?i)\\W");
  EXPECT_FALSE(RE2::PartialMatch("x", re));  // always worked
  EXPECT_FALSE(RE2::PartialMatch("k", re));  // broke because of kelvin
  EXPECT_FALSE(RE2::PartialMatch("s", re));  // broke because of latin long s
}

TEST(RE2, CapturingGroupNames) {
  // Opening parentheses annotated with group IDs:
  //      12    3        45   6         7
  RE2 re("((abc)(?P<G2>)|((e+)(?P<G2>.*)(?P<G1>u+)))");
  EXPECT_TRUE(re.ok());
  const map<int, string>& have = re.CapturingGroupNames();
  map<int, string> want;
  want[3] = "G2";
  want[6] = "G2";
  want[7] = "G1";
  EXPECT_EQ(want, have);
}

TEST(RE2, RegexpToStringLossOfAnchor) {
  EXPECT_EQ(RE2("^[a-c]at", RE2::POSIX).Regexp()->ToString(), "^[a-c]at");
  EXPECT_EQ(RE2("^[a-c]at").Regexp()->ToString(), "(?-m:^)[a-c]at");
  EXPECT_EQ(RE2("ca[t-z]$", RE2::POSIX).Regexp()->ToString(), "ca[t-z]$");
  EXPECT_EQ(RE2("ca[t-z]$").Regexp()->ToString(), "ca[t-z](?-m:$)");
}

}  // namespace re2
