// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/ax_text_utils.h"

#include <stddef.h>
#include <utility>

#include "base/strings/utf_string_conversions.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/accessibility/ax_enums.mojom.h"

namespace ui {

TEST(AXTextUtils, FindAccessibleTextBoundaryWord) {
  const base::string16 text =
      base::UTF8ToUTF16("Hello there.This/is\ntesting.");
  const size_t text_length = text.length();
  std::vector<int> line_start_offsets;
  line_start_offsets.push_back(19);
  size_t result;

  result = FindAccessibleTextBoundary(
      text, line_start_offsets, ax::mojom::TextBoundary::kWordStart, 0,
      ax::mojom::MoveDirection::kForward, ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(6UL, result);
  result = FindAccessibleTextBoundary(text, line_start_offsets,
                                      ax::mojom::TextBoundary::kWordStart, 5,
                                      ax::mojom::MoveDirection::kBackward,
                                      ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(0UL, result);
  result = FindAccessibleTextBoundary(
      text, line_start_offsets, ax::mojom::TextBoundary::kWordStart, 6,
      ax::mojom::MoveDirection::kForward, ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(12UL, result);
  result = FindAccessibleTextBoundary(text, line_start_offsets,
                                      ax::mojom::TextBoundary::kWordStart, 11,
                                      ax::mojom::MoveDirection::kBackward,
                                      ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(6UL, result);
  result = FindAccessibleTextBoundary(text, line_start_offsets,
                                      ax::mojom::TextBoundary::kWordStart, 12,
                                      ax::mojom::MoveDirection::kBackward,
                                      ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(12UL, result);
  result = FindAccessibleTextBoundary(
      text, line_start_offsets, ax::mojom::TextBoundary::kWordStart, 15,
      ax::mojom::MoveDirection::kForward, ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(17UL, result);
  result = FindAccessibleTextBoundary(text, line_start_offsets,
                                      ax::mojom::TextBoundary::kWordStart, 15,
                                      ax::mojom::MoveDirection::kBackward,
                                      ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(12UL, result);
  result = FindAccessibleTextBoundary(
      text, line_start_offsets, ax::mojom::TextBoundary::kWordStart, 16,
      ax::mojom::MoveDirection::kForward, ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(17UL, result);
  result = FindAccessibleTextBoundary(
      text, line_start_offsets, ax::mojom::TextBoundary::kWordStart, 17,
      ax::mojom::MoveDirection::kForward, ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(20UL, result);
  result = FindAccessibleTextBoundary(
      text, line_start_offsets, ax::mojom::TextBoundary::kWordStart, 20,
      ax::mojom::MoveDirection::kForward, ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(text_length, result);
  result = FindAccessibleTextBoundary(
      text, line_start_offsets, ax::mojom::TextBoundary::kWordStart,
      text_length, ax::mojom::MoveDirection::kBackward,
      ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(20UL, result);
}

TEST(AXTextUtils, FindAccessibleTextBoundaryLine) {
  const base::string16 text = base::UTF8ToUTF16("Line 1.\nLine 2\n\t");
  const size_t text_length = text.length();
  std::vector<int> line_start_offsets;
  line_start_offsets.push_back(8);
  line_start_offsets.push_back(15);
  size_t result;

  // Basic cases.
  result = FindAccessibleTextBoundary(
      text, line_start_offsets, ax::mojom::TextBoundary::kLineStart, 5,
      ax::mojom::MoveDirection::kForward, ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(8UL, result);
  result = FindAccessibleTextBoundary(text, line_start_offsets,
                                      ax::mojom::TextBoundary::kLineStart, 9,
                                      ax::mojom::MoveDirection::kBackward,
                                      ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(8UL, result);
  result = FindAccessibleTextBoundary(
      text, line_start_offsets, ax::mojom::TextBoundary::kLineStart, 10,
      ax::mojom::MoveDirection::kForward, ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(15UL, result);

  // Edge cases.
  result = FindAccessibleTextBoundary(
      text, line_start_offsets, ax::mojom::TextBoundary::kLineStart,
      text_length, ax::mojom::MoveDirection::kBackward,
      ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(15UL, result);

  // When the start_offset is at the start of the next line and we are searching
  // backwards, it should not move.
  result = FindAccessibleTextBoundary(text, line_start_offsets,
                                      ax::mojom::TextBoundary::kLineStart, 15,
                                      ax::mojom::MoveDirection::kBackward,
                                      ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(15UL, result);

  // When the start_offset is at a hard line break and we are searching
  // backwards, it should return the start of the previous line.
  result = FindAccessibleTextBoundary(text, line_start_offsets,
                                      ax::mojom::TextBoundary::kLineStart, 14,
                                      ax::mojom::MoveDirection::kBackward,
                                      ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(8UL, result);

  // When the start_offset is at the start of a line and we are searching
  // forwards, it should return the start of the next line.
  result = FindAccessibleTextBoundary(
      text, line_start_offsets, ax::mojom::TextBoundary::kLineStart, 8,
      ax::mojom::MoveDirection::kForward, ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(15UL, result);

  // When there is no previous line break and we are searching backwards,
  // it should return 0.
  result = FindAccessibleTextBoundary(text, line_start_offsets,
                                      ax::mojom::TextBoundary::kLineStart, 4,
                                      ax::mojom::MoveDirection::kBackward,
                                      ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(0UL, result);

  // When we are at the start of the last line and we are searching forwards.
  // it should return the text length.
  result = FindAccessibleTextBoundary(
      text, line_start_offsets, ax::mojom::TextBoundary::kLineStart, 15,
      ax::mojom::MoveDirection::kForward, ax::mojom::TextAffinity::kDownstream);
  EXPECT_EQ(text_length, result);
}

TEST(AXTextUtils, FindAccessibleTextBoundarySentence) {
  auto find_sentence_boundaries_at_offset = [](const base::string16& text,
                                               int offset) {
    std::vector<int> line_start_offsets;
    size_t backwards = FindAccessibleTextBoundary(
        text, line_start_offsets, ax::mojom::TextBoundary::kSentenceStart,
        offset, ax::mojom::MoveDirection::kBackward,
        ax::mojom::TextAffinity::kDownstream);
    size_t forwards = FindAccessibleTextBoundary(
        text, line_start_offsets, ax::mojom::TextBoundary::kSentenceStart,
        offset, ax::mojom::MoveDirection::kForward,
        ax::mojom::TextAffinity::kDownstream);
    return std::make_pair(backwards, forwards);
  };

  const base::string16 text =
      base::UTF8ToUTF16("Sentence 1. Sentence 2...\n\tSentence 3! Sentence 4");
  std::pair<size_t, size_t> boundaries =
      find_sentence_boundaries_at_offset(text, 5);
  EXPECT_EQ(0UL, boundaries.first);
  EXPECT_EQ(12UL, boundaries.second);

  // When a sentence ends with multiple punctuation, we should look for the
  // first word character that follows.
  boundaries = find_sentence_boundaries_at_offset(text, 16);
  EXPECT_EQ(12UL, boundaries.first);
  EXPECT_EQ(27UL, boundaries.second);

  // This is also true if we start in the middle of that punctuation.
  boundaries = find_sentence_boundaries_at_offset(text, 23);
  EXPECT_EQ(12UL, boundaries.first);
  EXPECT_EQ(27UL, boundaries.second);

  // When the offset is in the whitespace between two sentences, the boundaries
  // should be those of the previous sentence to the beginning of the first
  // non-whitespace character of the next one.
  boundaries = find_sentence_boundaries_at_offset(text, 38);
  EXPECT_EQ(27UL, boundaries.first);
  EXPECT_EQ(39UL, boundaries.second);

  // The end of the string should be considered the end of the last sentence
  // regardless of whether or not there is punctuation.
  boundaries = find_sentence_boundaries_at_offset(text, 44);
  EXPECT_EQ(39UL, boundaries.first);
  EXPECT_EQ(49UL, boundaries.second);

  // The sentence should include whitespace all the way until the end of the
  // string.
  const base::string16 text2 = base::UTF8ToUTF16("A sentence . \n\n\t\t\n");
  boundaries = find_sentence_boundaries_at_offset(text2, 10);
  EXPECT_EQ(0UL, boundaries.first);
  EXPECT_EQ(18UL, boundaries.second);
}

TEST(AXTextUtils, FindAccessibleTextBoundaryCharacter) {
  static const wchar_t* kCharacters[] = {
      // An English word consisting of four ASCII characters.
      L"w",
      L"o",
      L"r",
      L"d",
      L" ",
      // A Hindi word (which means "Hindi") consisting of three Devanagari
      // characters.
      L"\x0939\x093F",
      L"\x0928\x094D",
      L"\x0926\x0940",
      L" ",
      // A Thai word (which means "feel") consisting of three Thai characters.
      L"\x0E23\x0E39\x0E49",
      L"\x0E2A\x0E36",
      L"\x0E01",
      L" ",
  };

  std::vector<base::string16> characters;
  base::string16 text;
  for (auto*& i : kCharacters) {
    characters.push_back(base::WideToUTF16(i));
    text.append(characters.back());
  }

  auto verify_boundaries_at_offset = [&text](int offset, size_t start,
                                             size_t end) {
    testing::Message message;
    message << "Testing character bounds at index " << offset;
    SCOPED_TRACE(message);

    std::vector<int> line_start_offsets;
    size_t backwards = FindAccessibleTextBoundary(
        text, line_start_offsets, ax::mojom::TextBoundary::kCharacter, offset,
        ax::mojom::MoveDirection::kBackward,
        ax::mojom::TextAffinity::kDownstream);
    EXPECT_EQ(backwards, start);

    size_t forwards = FindAccessibleTextBoundary(
        text, line_start_offsets, ax::mojom::TextBoundary::kCharacter, offset,
        ax::mojom::MoveDirection::kForward,
        ax::mojom::TextAffinity::kDownstream);
    EXPECT_EQ(forwards, end);
  };

  verify_boundaries_at_offset(0, 0UL, 1UL);
  verify_boundaries_at_offset(1, 1UL, 2UL);
  verify_boundaries_at_offset(2, 2UL, 3UL);
  verify_boundaries_at_offset(3, 3UL, 4UL);
  verify_boundaries_at_offset(4, 4UL, 5UL);
  verify_boundaries_at_offset(5, 5UL, 7UL);
  verify_boundaries_at_offset(6, 5UL, 7UL);
  verify_boundaries_at_offset(7, 7UL, 11UL);
  verify_boundaries_at_offset(8, 7UL, 11UL);
  verify_boundaries_at_offset(9, 7UL, 11UL);
  verify_boundaries_at_offset(10, 7UL, 11UL);
  verify_boundaries_at_offset(11, 11L, 12UL);
  verify_boundaries_at_offset(12, 12L, 15UL);
  verify_boundaries_at_offset(13, 12L, 15UL);
  verify_boundaries_at_offset(14, 12L, 15UL);
  verify_boundaries_at_offset(15, 15L, 17UL);
  verify_boundaries_at_offset(16, 15L, 17UL);
  verify_boundaries_at_offset(17, 17L, 18UL);
  verify_boundaries_at_offset(18, 18L, 19UL);
}

TEST(AXTextUtils, GetWordOffsetsEmptyTest) {
  const base::string16 text = base::UTF8ToUTF16("");
  std::vector<int> word_starts = GetWordStartOffsets(text);
  std::vector<int> word_ends = GetWordEndOffsets(text);
  EXPECT_EQ(0UL, word_starts.size());
  EXPECT_EQ(0UL, word_ends.size());
}

TEST(AXTextUtils, GetWordStartOffsetsBasicTest) {
  const base::string16 text = base::UTF8ToUTF16("This is very simple input");
  EXPECT_THAT(GetWordStartOffsets(text), testing::ElementsAre(0, 5, 8, 13, 20));
}

TEST(AXTextUtils, GetWordEndOffsetsBasicTest) {
  const base::string16 text = base::UTF8ToUTF16("This is very simple input");
  EXPECT_THAT(GetWordEndOffsets(text), testing::ElementsAre(4, 7, 12, 19, 25));
}

TEST(AXTextUtils, GetWordStartOffsetsMalformedInputTest) {
  const base::string16 text =
      base::UTF8ToUTF16("..we *## should parse $#@$ through bad ,,  input");
  EXPECT_THAT(GetWordStartOffsets(text),
              testing::ElementsAre(2, 9, 16, 27, 35, 43));
}

}  // namespace ui
