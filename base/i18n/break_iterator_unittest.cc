// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/i18n/break_iterator.h"

#include "base/strings/string_piece.h"
#include "base/strings/stringprintf.h"
#include "base/strings/utf_string_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace i18n {

TEST(BreakIteratorTest, BreakWordEmpty) {
  string16 empty;
  BreakIterator iter(empty, BreakIterator::BREAK_WORD);
  ASSERT_TRUE(iter.Init());
  EXPECT_FALSE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_FALSE(iter.Advance());  // Test unexpected advance after end.
  EXPECT_FALSE(iter.IsWord());
}

TEST(BreakIteratorTest, BreakWord) {
  string16 space(UTF8ToUTF16(" "));
  string16 str(UTF8ToUTF16(" foo bar! \npouet boom"));
  BreakIterator iter(str, BreakIterator::BREAK_WORD);
  ASSERT_TRUE(iter.Init());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(space, iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_TRUE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("foo"), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(space, iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_TRUE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("bar"), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("!"), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(space, iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("\n"), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_TRUE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("pouet"), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(space, iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_TRUE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("boom"), iter.GetString());
  EXPECT_FALSE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_FALSE(iter.Advance());  // Test unexpected advance after end.
  EXPECT_FALSE(iter.IsWord());
}

TEST(BreakIteratorTest, BreakWide16) {
  // Two greek words separated by space.
  const string16 str(WideToUTF16(
      L"\x03a0\x03b1\x03b3\x03ba\x03cc\x03c3\x03bc\x03b9"
      L"\x03bf\x03c2\x0020\x0399\x03c3\x03c4\x03cc\x03c2"));
  const string16 word1(str.substr(0, 10));
  const string16 word2(str.substr(11, 5));
  BreakIterator iter(str, BreakIterator::BREAK_WORD);
  ASSERT_TRUE(iter.Init());
  EXPECT_TRUE(iter.Advance());
  EXPECT_TRUE(iter.IsWord());
  EXPECT_EQ(word1, iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16(" "), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_TRUE(iter.IsWord());
  EXPECT_EQ(word2, iter.GetString());
  EXPECT_FALSE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_FALSE(iter.Advance());  // Test unexpected advance after end.
  EXPECT_FALSE(iter.IsWord());
}

TEST(BreakIteratorTest, BreakWide32) {
  // U+1D49C MATHEMATICAL SCRIPT CAPITAL A
  const char very_wide_char[] = "\xF0\x9D\x92\x9C";
  const string16 str(
      UTF8ToUTF16(base::StringPrintf("%s a", very_wide_char)));
  const string16 very_wide_word(str.substr(0, 2));

  BreakIterator iter(str, BreakIterator::BREAK_WORD);
  ASSERT_TRUE(iter.Init());
  EXPECT_TRUE(iter.Advance());
  EXPECT_TRUE(iter.IsWord());
  EXPECT_EQ(very_wide_word, iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16(" "), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_TRUE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("a"), iter.GetString());
  EXPECT_FALSE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_FALSE(iter.Advance());  // Test unexpected advance after end.
  EXPECT_FALSE(iter.IsWord());
}

TEST(BreakIteratorTest, BreakSpaceEmpty) {
  string16 empty;
  BreakIterator iter(empty, BreakIterator::BREAK_SPACE);
  ASSERT_TRUE(iter.Init());
  EXPECT_FALSE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_FALSE(iter.Advance());  // Test unexpected advance after end.
  EXPECT_FALSE(iter.IsWord());
}

TEST(BreakIteratorTest, BreakSpace) {
  string16 str(UTF8ToUTF16(" foo bar! \npouet boom"));
  BreakIterator iter(str, BreakIterator::BREAK_SPACE);
  ASSERT_TRUE(iter.Init());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16(" "), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("foo "), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("bar! \n"), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("pouet "), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("boom"), iter.GetString());
  EXPECT_FALSE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_FALSE(iter.Advance());  // Test unexpected advance after end.
  EXPECT_FALSE(iter.IsWord());
}

TEST(BreakIteratorTest, BreakSpaceSP) {
  string16 str(UTF8ToUTF16(" foo bar! \npouet boom "));
  BreakIterator iter(str, BreakIterator::BREAK_SPACE);
  ASSERT_TRUE(iter.Init());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16(" "), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("foo "), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("bar! \n"), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("pouet "), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("boom "), iter.GetString());
  EXPECT_FALSE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_FALSE(iter.Advance());  // Test unexpected advance after end.
  EXPECT_FALSE(iter.IsWord());
}

TEST(BreakIteratorTest, BreakSpacekWide16) {
  // Two Greek words.
  const string16 str(WideToUTF16(
      L"\x03a0\x03b1\x03b3\x03ba\x03cc\x03c3\x03bc\x03b9"
      L"\x03bf\x03c2\x0020\x0399\x03c3\x03c4\x03cc\x03c2"));
  const string16 word1(str.substr(0, 11));
  const string16 word2(str.substr(11, 5));
  BreakIterator iter(str, BreakIterator::BREAK_SPACE);
  ASSERT_TRUE(iter.Init());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(word1, iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(word2, iter.GetString());
  EXPECT_FALSE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_FALSE(iter.Advance());  // Test unexpected advance after end.
  EXPECT_FALSE(iter.IsWord());
}

TEST(BreakIteratorTest, BreakSpaceWide32) {
  // U+1D49C MATHEMATICAL SCRIPT CAPITAL A
  const char very_wide_char[] = "\xF0\x9D\x92\x9C";
  const string16 str(
      UTF8ToUTF16(base::StringPrintf("%s a", very_wide_char)));
  const string16 very_wide_word(str.substr(0, 3));

  BreakIterator iter(str, BreakIterator::BREAK_SPACE);
  ASSERT_TRUE(iter.Init());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(very_wide_word, iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("a"), iter.GetString());
  EXPECT_FALSE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_FALSE(iter.Advance());  // Test unexpected advance after end.
  EXPECT_FALSE(iter.IsWord());
}

TEST(BreakIteratorTest, BreakLineEmpty) {
  string16 empty;
  BreakIterator iter(empty, BreakIterator::BREAK_NEWLINE);
  ASSERT_TRUE(iter.Init());
  EXPECT_FALSE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_FALSE(iter.Advance());   // Test unexpected advance after end.
  EXPECT_FALSE(iter.IsWord());
}

TEST(BreakIteratorTest, BreakLine) {
  string16 nl(UTF8ToUTF16("\n"));
  string16 str(UTF8ToUTF16("\nfoo bar!\n\npouet boom"));
  BreakIterator iter(str, BreakIterator::BREAK_NEWLINE);
  ASSERT_TRUE(iter.Init());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(nl, iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("foo bar!\n"), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(nl, iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("pouet boom"), iter.GetString());
  EXPECT_FALSE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_FALSE(iter.Advance());   // Test unexpected advance after end.
  EXPECT_FALSE(iter.IsWord());
}

TEST(BreakIteratorTest, BreakLineNL) {
  string16 nl(UTF8ToUTF16("\n"));
  string16 str(UTF8ToUTF16("\nfoo bar!\n\npouet boom\n"));
  BreakIterator iter(str, BreakIterator::BREAK_NEWLINE);
  ASSERT_TRUE(iter.Init());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(nl, iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("foo bar!\n"), iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(nl, iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("pouet boom\n"), iter.GetString());
  EXPECT_FALSE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_FALSE(iter.Advance());   // Test unexpected advance after end.
  EXPECT_FALSE(iter.IsWord());
}

TEST(BreakIteratorTest, BreakLineWide16) {
  // Two Greek words separated by newline.
  const string16 str(WideToUTF16(
      L"\x03a0\x03b1\x03b3\x03ba\x03cc\x03c3\x03bc\x03b9"
      L"\x03bf\x03c2\x000a\x0399\x03c3\x03c4\x03cc\x03c2"));
  const string16 line1(str.substr(0, 11));
  const string16 line2(str.substr(11, 5));
  BreakIterator iter(str, BreakIterator::BREAK_NEWLINE);
  ASSERT_TRUE(iter.Init());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(line1, iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(line2, iter.GetString());
  EXPECT_FALSE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_FALSE(iter.Advance());   // Test unexpected advance after end.
  EXPECT_FALSE(iter.IsWord());
}

TEST(BreakIteratorTest, BreakLineWide32) {
  // U+1D49C MATHEMATICAL SCRIPT CAPITAL A
  const char very_wide_char[] = "\xF0\x9D\x92\x9C";
  const string16 str(
      UTF8ToUTF16(base::StringPrintf("%s\na", very_wide_char)));
  const string16 very_wide_line(str.substr(0, 3));
  BreakIterator iter(str, BreakIterator::BREAK_NEWLINE);
  ASSERT_TRUE(iter.Init());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(very_wide_line, iter.GetString());
  EXPECT_TRUE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_EQ(UTF8ToUTF16("a"), iter.GetString());
  EXPECT_FALSE(iter.Advance());
  EXPECT_FALSE(iter.IsWord());
  EXPECT_FALSE(iter.Advance());   // Test unexpected advance after end.
  EXPECT_FALSE(iter.IsWord());
}

TEST(BreakIteratorTest, BreakCharacter) {
  static const wchar_t* kCharacters[] = {
    // An English word consisting of four ASCII characters.
    L"w", L"o", L"r", L"d", L" ",
    // A Hindi word (which means "Hindi") consisting of three Devanagari
    // characters.
    L"\x0939\x093F", L"\x0928\x094D", L"\x0926\x0940", L" ",
    // A Thai word (which means "feel") consisting of three Thai characters.
    L"\x0E23\x0E39\x0E49", L"\x0E2A\x0E36", L"\x0E01", L" ",
  };
  std::vector<string16> characters;
  string16 text;
  for (size_t i = 0; i < arraysize(kCharacters); ++i) {
    characters.push_back(WideToUTF16(kCharacters[i]));
    text.append(characters.back());
  }
  BreakIterator iter(text, BreakIterator::BREAK_CHARACTER);
  ASSERT_TRUE(iter.Init());
  for (size_t i = 0; i < arraysize(kCharacters); ++i) {
    EXPECT_TRUE(iter.Advance());
    EXPECT_EQ(characters[i], iter.GetString());
  }
}

// Test for https://code.google.com/p/chromium/issues/detail?id=411213
// We should be able to get valid substrings with GetString() function
// after setting new content by calling SetText().
TEST(BreakIteratorTest, GetStringAfterSetText) {
  const string16 initial_string(ASCIIToUTF16("str"));
  BreakIterator iter(initial_string, BreakIterator::BREAK_WORD);
  ASSERT_TRUE(iter.Init());

  const string16 long_string(ASCIIToUTF16("another,string"));
  EXPECT_TRUE(iter.SetText(long_string.c_str(), long_string.size()));
  EXPECT_TRUE(iter.Advance());
  EXPECT_TRUE(iter.Advance());  // Advance to ',' in |long_string|

  // Check that the current position is out of bounds of the |initial_string|.
  EXPECT_LT(initial_string.size(), iter.pos());

  // Check that we can get a valid substring of |long_string|.
  EXPECT_EQ(ASCIIToUTF16(","), iter.GetString());
}

TEST(BreakIteratorTest, GetStringPiece) {
  const string16 initial_string(ASCIIToUTF16("some string"));
  BreakIterator iter(initial_string, BreakIterator::BREAK_WORD);
  ASSERT_TRUE(iter.Init());

  EXPECT_TRUE(iter.Advance());
  EXPECT_EQ(iter.GetString(), iter.GetStringPiece().as_string());
  EXPECT_EQ(StringPiece16(ASCIIToUTF16("some")), iter.GetStringPiece());

  EXPECT_TRUE(iter.Advance());
  EXPECT_TRUE(iter.Advance());
  EXPECT_EQ(iter.GetString(), iter.GetStringPiece().as_string());
  EXPECT_EQ(StringPiece16(ASCIIToUTF16("string")), iter.GetStringPiece());
}

}  // namespace i18n
}  // namespace base
