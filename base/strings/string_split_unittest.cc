// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/strings/string_split.h"

#include "base/strings/utf_string_conversions.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

using ::testing::ElementsAre;

namespace base {

namespace {

#if !defined(WCHAR_T_IS_UTF16)
// Overload SplitString with a wide-char version to make it easier to
// test the string16 version with wide character literals.
void SplitString(const std::wstring& str,
                 wchar_t c,
                 std::vector<std::wstring>* result) {
  std::vector<string16> result16;
  SplitString(WideToUTF16(str), c, &result16);
  for (size_t i = 0; i < result16.size(); ++i)
    result->push_back(UTF16ToWide(result16[i]));
}
#endif

}  // anonymous namespace

class SplitStringIntoKeyValuePairsTest : public testing::Test {
 protected:
  base::StringPairs kv_pairs;
};

TEST_F(SplitStringIntoKeyValuePairsTest, EmptyString) {
  EXPECT_TRUE(SplitStringIntoKeyValuePairs(std::string(),
                                           ':',  // Key-value delimiter
                                           ',',  // Key-value pair delimiter
                                           &kv_pairs));
  EXPECT_TRUE(kv_pairs.empty());
}

TEST_F(SplitStringIntoKeyValuePairsTest, MissingKeyValueDelimiter) {
  EXPECT_FALSE(SplitStringIntoKeyValuePairs("key1,key2:value2",
                                            ':',  // Key-value delimiter
                                            ',',  // Key-value pair delimiter
                                            &kv_pairs));
  ASSERT_EQ(2U, kv_pairs.size());
  EXPECT_TRUE(kv_pairs[0].first.empty());
  EXPECT_TRUE(kv_pairs[0].second.empty());
  EXPECT_EQ("key2", kv_pairs[1].first);
  EXPECT_EQ("value2", kv_pairs[1].second);
}

TEST_F(SplitStringIntoKeyValuePairsTest, EmptyKeyWithKeyValueDelimiter) {
  EXPECT_TRUE(SplitStringIntoKeyValuePairs(":value1,key2:value2",
                                           ':',  // Key-value delimiter
                                           ',',  // Key-value pair delimiter
                                           &kv_pairs));
  ASSERT_EQ(2U, kv_pairs.size());
  EXPECT_TRUE(kv_pairs[0].first.empty());
  EXPECT_EQ("value1", kv_pairs[0].second);
  EXPECT_EQ("key2", kv_pairs[1].first);
  EXPECT_EQ("value2", kv_pairs[1].second);
}

TEST_F(SplitStringIntoKeyValuePairsTest, TrailingAndLeadingPairDelimiter) {
  EXPECT_TRUE(SplitStringIntoKeyValuePairs(",key1:value1,key2:value2,",
                                           ':',   // Key-value delimiter
                                           ',',   // Key-value pair delimiter
                                           &kv_pairs));
  ASSERT_EQ(2U, kv_pairs.size());
  EXPECT_EQ("key1", kv_pairs[0].first);
  EXPECT_EQ("value1", kv_pairs[0].second);
  EXPECT_EQ("key2", kv_pairs[1].first);
  EXPECT_EQ("value2", kv_pairs[1].second);
}

TEST_F(SplitStringIntoKeyValuePairsTest, EmptyPair) {
  EXPECT_TRUE(SplitStringIntoKeyValuePairs("key1:value1,,key3:value3",
                                           ':',   // Key-value delimiter
                                           ',',   // Key-value pair delimiter
                                           &kv_pairs));
  ASSERT_EQ(2U, kv_pairs.size());
  EXPECT_EQ("key1", kv_pairs[0].first);
  EXPECT_EQ("value1", kv_pairs[0].second);
  EXPECT_EQ("key3", kv_pairs[1].first);
  EXPECT_EQ("value3", kv_pairs[1].second);
}

TEST_F(SplitStringIntoKeyValuePairsTest, EmptyValue) {
  EXPECT_FALSE(SplitStringIntoKeyValuePairs("key1:,key2:value2",
                                            ':',   // Key-value delimiter
                                            ',',   // Key-value pair delimiter
                                            &kv_pairs));
  ASSERT_EQ(2U, kv_pairs.size());
  EXPECT_EQ("key1", kv_pairs[0].first);
  EXPECT_EQ("", kv_pairs[0].second);
  EXPECT_EQ("key2", kv_pairs[1].first);
  EXPECT_EQ("value2", kv_pairs[1].second);
}

TEST_F(SplitStringIntoKeyValuePairsTest, UntrimmedWhitespace) {
  EXPECT_TRUE(SplitStringIntoKeyValuePairs("key1 : value1",
                                           ':',  // Key-value delimiter
                                           ',',  // Key-value pair delimiter
                                           &kv_pairs));
  ASSERT_EQ(1U, kv_pairs.size());
  EXPECT_EQ("key1 ", kv_pairs[0].first);
  EXPECT_EQ(" value1", kv_pairs[0].second);
}

TEST_F(SplitStringIntoKeyValuePairsTest, TrimmedWhitespace) {
  EXPECT_TRUE(SplitStringIntoKeyValuePairs("key1:value1 , key2:value2",
                                           ':',   // Key-value delimiter
                                           ',',   // Key-value pair delimiter
                                           &kv_pairs));
  ASSERT_EQ(2U, kv_pairs.size());
  EXPECT_EQ("key1", kv_pairs[0].first);
  EXPECT_EQ("value1", kv_pairs[0].second);
  EXPECT_EQ("key2", kv_pairs[1].first);
  EXPECT_EQ("value2", kv_pairs[1].second);
}

TEST_F(SplitStringIntoKeyValuePairsTest, MultipleKeyValueDelimiters) {
  EXPECT_TRUE(SplitStringIntoKeyValuePairs("key1:::value1,key2:value2",
                                           ':',   // Key-value delimiter
                                           ',',   // Key-value pair delimiter
                                           &kv_pairs));
  ASSERT_EQ(2U, kv_pairs.size());
  EXPECT_EQ("key1", kv_pairs[0].first);
  EXPECT_EQ("value1", kv_pairs[0].second);
  EXPECT_EQ("key2", kv_pairs[1].first);
  EXPECT_EQ("value2", kv_pairs[1].second);
}

TEST_F(SplitStringIntoKeyValuePairsTest, OnlySplitAtGivenSeparator) {
  std::string a("a ?!@#$%^&*()_+:/{}\\\t\nb");
  EXPECT_TRUE(SplitStringIntoKeyValuePairs(a + "X" + a + "Y" + a + "X" + a,
                                           'X',  // Key-value delimiter
                                           'Y',  // Key-value pair delimiter
                                           &kv_pairs));
  ASSERT_EQ(2U, kv_pairs.size());
  EXPECT_EQ(a, kv_pairs[0].first);
  EXPECT_EQ(a, kv_pairs[0].second);
  EXPECT_EQ(a, kv_pairs[1].first);
  EXPECT_EQ(a, kv_pairs[1].second);
}


TEST_F(SplitStringIntoKeyValuePairsTest, DelimiterInValue) {
  EXPECT_TRUE(SplitStringIntoKeyValuePairs("key1:va:ue1,key2:value2",
                                           ':',   // Key-value delimiter
                                           ',',   // Key-value pair delimiter
                                           &kv_pairs));
  ASSERT_EQ(2U, kv_pairs.size());
  EXPECT_EQ("key1", kv_pairs[0].first);
  EXPECT_EQ("va:ue1", kv_pairs[0].second);
  EXPECT_EQ("key2", kv_pairs[1].first);
  EXPECT_EQ("value2", kv_pairs[1].second);
}

TEST(SplitStringUsingSubstrTest, EmptyString) {
  std::vector<std::string> results;
  SplitStringUsingSubstr(std::string(), "DELIMITER", &results);
  ASSERT_EQ(1u, results.size());
  EXPECT_THAT(results, ElementsAre(""));
}

TEST(StringUtilTest, SplitString_Basics) {
  std::vector<std::string> r;

  r = SplitString(std::string(), ",:;", KEEP_WHITESPACE, SPLIT_WANT_ALL);
  EXPECT_TRUE(r.empty());

  // Empty separator list
  r = SplitString("hello, world", "", KEEP_WHITESPACE, SPLIT_WANT_ALL);
  ASSERT_EQ(1u, r.size());
  EXPECT_EQ("hello, world", r[0]);

  // Should split on any of the separators.
  r = SplitString("::,,;;", ",:;", KEEP_WHITESPACE, SPLIT_WANT_ALL);
  ASSERT_EQ(7u, r.size());
  for (auto str : r)
    ASSERT_TRUE(str.empty());

  r = SplitString("red, green; blue:", ",:;", TRIM_WHITESPACE,
                  SPLIT_WANT_NONEMPTY);
  ASSERT_EQ(3u, r.size());
  EXPECT_EQ("red", r[0]);
  EXPECT_EQ("green", r[1]);
  EXPECT_EQ("blue", r[2]);

  // Want to split a string along whitespace sequences.
  r = SplitString("  red green   \tblue\n", " \t\n", TRIM_WHITESPACE,
                  SPLIT_WANT_NONEMPTY);
  ASSERT_EQ(3u, r.size());
  EXPECT_EQ("red", r[0]);
  EXPECT_EQ("green", r[1]);
  EXPECT_EQ("blue", r[2]);

  // Weird case of splitting on spaces but not trimming.
  r = SplitString(" red ", " ", TRIM_WHITESPACE, SPLIT_WANT_ALL);
  ASSERT_EQ(3u, r.size());
  EXPECT_EQ("", r[0]);  // Before the first space.
  EXPECT_EQ("red", r[1]);
  EXPECT_EQ("", r[2]);  // After the last space.
}

TEST(StringUtilTest, SplitString_WhitespaceAndResultType) {
  std::vector<std::string> r;

  // Empty input handling.
  r = SplitString(std::string(), ",", KEEP_WHITESPACE, SPLIT_WANT_ALL);
  EXPECT_TRUE(r.empty());
  r = SplitString(std::string(), ",", KEEP_WHITESPACE, SPLIT_WANT_NONEMPTY);
  EXPECT_TRUE(r.empty());

  // Input string is space and we're trimming.
  r = SplitString(" ", ",", TRIM_WHITESPACE, SPLIT_WANT_ALL);
  ASSERT_EQ(1u, r.size());
  EXPECT_EQ("", r[0]);
  r = SplitString(" ", ",", TRIM_WHITESPACE, SPLIT_WANT_NONEMPTY);
  EXPECT_TRUE(r.empty());

  // Test all 4 combinations of flags on ", ,".
  r = SplitString(", ,", ",", KEEP_WHITESPACE, SPLIT_WANT_ALL);
  ASSERT_EQ(3u, r.size());
  EXPECT_EQ("", r[0]);
  EXPECT_EQ(" ", r[1]);
  EXPECT_EQ("", r[2]);
  r = SplitString(", ,", ",", KEEP_WHITESPACE, SPLIT_WANT_NONEMPTY);
  ASSERT_EQ(1u, r.size());
  ASSERT_EQ(" ", r[0]);
  r = SplitString(", ,", ",", TRIM_WHITESPACE, SPLIT_WANT_ALL);
  ASSERT_EQ(3u, r.size());
  EXPECT_EQ("", r[0]);
  EXPECT_EQ("", r[1]);
  EXPECT_EQ("", r[2]);
  r = SplitString(", ,", ",", TRIM_WHITESPACE, SPLIT_WANT_NONEMPTY);
  ASSERT_TRUE(r.empty());
}

TEST(StringUtilTest, SplitString_Legacy) {
  std::vector<std::wstring> r;

  SplitString(std::wstring(), L',', &r);
  EXPECT_EQ(0U, r.size());
  r.clear();

  SplitString(L"a,b,c", L',', &r);
  ASSERT_EQ(3U, r.size());
  EXPECT_EQ(r[0], L"a");
  EXPECT_EQ(r[1], L"b");
  EXPECT_EQ(r[2], L"c");
  r.clear();

  SplitString(L"a, b, c", L',', &r);
  ASSERT_EQ(3U, r.size());
  EXPECT_EQ(r[0], L"a");
  EXPECT_EQ(r[1], L"b");
  EXPECT_EQ(r[2], L"c");
  r.clear();

  SplitString(L"a,,c", L',', &r);
  ASSERT_EQ(3U, r.size());
  EXPECT_EQ(r[0], L"a");
  EXPECT_EQ(r[1], L"");
  EXPECT_EQ(r[2], L"c");
  r.clear();

  SplitString(L"a, ,c", L',', &r);
  ASSERT_EQ(3U, r.size());
  EXPECT_EQ(r[0], L"a");
  EXPECT_EQ(r[1], L"");
  EXPECT_EQ(r[2], L"c");
  r.clear();

  SplitString(L"   ", L'*', &r);
  EXPECT_EQ(0U, r.size());
  r.clear();

  SplitString(L"foo", L'*', &r);
  ASSERT_EQ(1U, r.size());
  EXPECT_EQ(r[0], L"foo");
  r.clear();

  SplitString(L"foo ,", L',', &r);
  ASSERT_EQ(2U, r.size());
  EXPECT_EQ(r[0], L"foo");
  EXPECT_EQ(r[1], L"");
  r.clear();

  SplitString(L",", L',', &r);
  ASSERT_EQ(2U, r.size());
  EXPECT_EQ(r[0], L"");
  EXPECT_EQ(r[1], L"");
  r.clear();

  SplitString(L"\t\ta\t", L'\t', &r);
  ASSERT_EQ(4U, r.size());
  EXPECT_EQ(r[0], L"");
  EXPECT_EQ(r[1], L"");
  EXPECT_EQ(r[2], L"a");
  EXPECT_EQ(r[3], L"");
  r.clear();

  SplitString(L"\ta\t\nb\tcc", L'\n', &r);
  ASSERT_EQ(2U, r.size());
  EXPECT_EQ(r[0], L"a");
  EXPECT_EQ(r[1], L"b\tcc");
  r.clear();
}

TEST(SplitStringUsingSubstrTest, StringWithNoDelimiter) {
  std::vector<std::string> results;
  SplitStringUsingSubstr("alongwordwithnodelimiter", "DELIMITER", &results);
  ASSERT_EQ(1u, results.size());
  EXPECT_THAT(results, ElementsAre("alongwordwithnodelimiter"));
}

TEST(SplitStringUsingSubstrTest, LeadingDelimitersSkipped) {
  std::vector<std::string> results;
  SplitStringUsingSubstr(
      "DELIMITERDELIMITERDELIMITERoneDELIMITERtwoDELIMITERthree",
      "DELIMITER",
      &results);
  ASSERT_EQ(6u, results.size());
  EXPECT_THAT(results, ElementsAre("", "", "", "one", "two", "three"));
}

TEST(SplitStringUsingSubstrTest, ConsecutiveDelimitersSkipped) {
  std::vector<std::string> results;
  SplitStringUsingSubstr(
      "unoDELIMITERDELIMITERDELIMITERdosDELIMITERtresDELIMITERDELIMITERcuatro",
      "DELIMITER",
      &results);
  ASSERT_EQ(7u, results.size());
  EXPECT_THAT(results, ElementsAre("uno", "", "", "dos", "tres", "", "cuatro"));
}

TEST(SplitStringUsingSubstrTest, TrailingDelimitersSkipped) {
  std::vector<std::string> results;
  SplitStringUsingSubstr(
      "unDELIMITERdeuxDELIMITERtroisDELIMITERquatreDELIMITERDELIMITERDELIMITER",
      "DELIMITER",
      &results);
  ASSERT_EQ(7u, results.size());
  EXPECT_THAT(
      results, ElementsAre("un", "deux", "trois", "quatre", "", "", ""));
}

TEST(StringSplitTest, StringSplitDontTrim) {
  std::vector<std::string> r;

  SplitStringDontTrim("   ", '*', &r);
  ASSERT_EQ(1U, r.size());
  EXPECT_EQ(r[0], "   ");

  SplitStringDontTrim("\t  \ta\t ", '\t', &r);
  ASSERT_EQ(4U, r.size());
  EXPECT_EQ(r[0], "");
  EXPECT_EQ(r[1], "  ");
  EXPECT_EQ(r[2], "a");
  EXPECT_EQ(r[3], " ");

  SplitStringDontTrim("\ta\t\nb\tcc", '\n', &r);
  ASSERT_EQ(2U, r.size());
  EXPECT_EQ(r[0], "\ta\t");
  EXPECT_EQ(r[1], "b\tcc");
}

TEST(StringSplitTest, SplitStringAlongWhitespace) {
  struct TestData {
    const char* input;
    const size_t expected_result_count;
    const char* output1;
    const char* output2;
  } data[] = {
    { "a",       1, "a",  ""   },
    { " ",       0, "",   ""   },
    { " a",      1, "a",  ""   },
    { " ab ",    1, "ab", ""   },
    { " ab c",   2, "ab", "c"  },
    { " ab c ",  2, "ab", "c"  },
    { " ab cd",  2, "ab", "cd" },
    { " ab cd ", 2, "ab", "cd" },
    { " \ta\t",  1, "a",  ""   },
    { " b\ta\t", 2, "b",  "a"  },
    { " b\tat",  2, "b",  "at" },
    { "b\tat",   2, "b",  "at" },
    { "b\t at",  2, "b",  "at" },
  };
  for (size_t i = 0; i < arraysize(data); ++i) {
    std::vector<std::string> results;
    SplitStringAlongWhitespace(data[i].input, &results);
    ASSERT_EQ(data[i].expected_result_count, results.size());
    if (data[i].expected_result_count > 0)
      ASSERT_EQ(data[i].output1, results[0]);
    if (data[i].expected_result_count > 1)
      ASSERT_EQ(data[i].output2, results[1]);
  }
}

}  // namespace base
