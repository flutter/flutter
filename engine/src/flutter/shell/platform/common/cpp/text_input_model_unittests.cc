// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/cpp/text_input_model.h"

#include <limits>
#include <map>
#include <vector>

#include "gtest/gtest.h"

namespace flutter {

TEST(TextInputModel, SetText) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, SetTextWideCharacters) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("😄🙃🤪🧐");
  EXPECT_STREQ(model->GetText().c_str(), "😄🙃🤪🧐");
}

TEST(TextInputModel, SetTextEmpty) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("");
  EXPECT_STREQ(model->GetText().c_str(), "");
}

TEST(TextInputModel, SetTextReplaceText) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
  model->SetText("");
  EXPECT_STREQ(model->GetText().c_str(), "");
}

TEST(TextInputModel, SetTextResetsSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(3, 3));
  EXPECT_EQ(model->selection_base(), 3);
  EXPECT_EQ(model->selection_extent(), 3);
  model->SetText("FGHJI");
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
}

TEST(TextInputModel, SetSelectionStart) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(0, 0));
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, SetSelectionMiddle) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, SetSelectionEnd) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(5, 5));
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, SetSelectionWthExtent) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(1, 4));
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 4);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, SetSelectionReverseExtent) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(4, 1));
  EXPECT_EQ(model->selection_base(), 4);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, SetSelectionOutsideString) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_FALSE(model->SetSelection(4, 6));
  EXPECT_FALSE(model->SetSelection(5, 6));
  EXPECT_FALSE(model->SetSelection(6, 6));
}

TEST(TextInputModel, AddCodePoint) {
  auto model = std::make_unique<TextInputModel>();
  model->AddCodePoint('A');
  model->AddCodePoint('B');
  model->AddCodePoint(0x1f604);
  model->AddCodePoint('D');
  model->AddCodePoint('E');
  EXPECT_EQ(model->selection_base(), 6);
  EXPECT_EQ(model->selection_extent(), 6);
  EXPECT_STREQ(model->GetText().c_str(), "AB😄DE");
}

TEST(TextInputModel, AddCodePointSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(1, 4));
  model->AddCodePoint('x');
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "AxE");
}

TEST(TextInputModel, AddCodePointReverseSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(4, 1));
  model->AddCodePoint('x');
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "AxE");
}

TEST(TextInputModel, AddCodePointSelectionWideCharacter) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(1, 4));
  model->AddCodePoint(0x1f604);
  EXPECT_EQ(model->selection_base(), 3);
  EXPECT_EQ(model->selection_extent(), 3);
  EXPECT_STREQ(model->GetText().c_str(), "A😄E");
}

TEST(TextInputModel, AddCodePointReverseSelectionWideCharacter) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(4, 1));
  model->AddCodePoint(0x1f604);
  EXPECT_EQ(model->selection_base(), 3);
  EXPECT_EQ(model->selection_extent(), 3);
  EXPECT_STREQ(model->GetText().c_str(), "A😄E");
}

TEST(TextInputModel, AddText) {
  auto model = std::make_unique<TextInputModel>();
  model->AddText(u"ABCDE");
  model->AddText("😄");
  model->AddText("FGHIJ");
  EXPECT_EQ(model->selection_base(), 12);
  EXPECT_EQ(model->selection_extent(), 12);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE😄FGHIJ");
}

TEST(TextInputModel, AddTextSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(1, 4));
  model->AddText("xy");
  EXPECT_EQ(model->selection_base(), 3);
  EXPECT_EQ(model->selection_extent(), 3);
  EXPECT_STREQ(model->GetText().c_str(), "AxyE");
}

TEST(TextInputModel, AddTextReverseSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(4, 1));
  model->AddText("xy");
  EXPECT_EQ(model->selection_base(), 3);
  EXPECT_EQ(model->selection_extent(), 3);
  EXPECT_STREQ(model->GetText().c_str(), "AxyE");
}

TEST(TextInputModel, AddTextSelectionWideCharacter) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(1, 4));
  model->AddText(u"😄🙃");
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "A😄🙃E");
}

TEST(TextInputModel, AddTextReverseSelectionWideCharacter) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(4, 1));
  model->AddText(u"😄🙃");
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "A😄🙃E");
}

TEST(TextInputModel, DeleteStart) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(0, 0));
  ASSERT_TRUE(model->Delete());
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "BCDE");
}

TEST(TextInputModel, DeleteMiddle) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  ASSERT_TRUE(model->Delete());
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "ABDE");
}

TEST(TextInputModel, DeleteEnd) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(5, 5));
  ASSERT_FALSE(model->Delete());
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, DeleteWideCharacters) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("😄🙃🤪🧐");
  EXPECT_TRUE(model->SetSelection(4, 4));
  ASSERT_TRUE(model->Delete());
  EXPECT_EQ(model->selection_base(), 4);
  EXPECT_EQ(model->selection_extent(), 4);
  EXPECT_STREQ(model->GetText().c_str(), "😄🙃🧐");
}

TEST(TextInputModel, DeleteSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(1, 4));
  ASSERT_TRUE(model->Delete());
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "AE");
}

TEST(TextInputModel, DeleteReverseSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(4, 1));
  ASSERT_TRUE(model->Delete());
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "AE");
}

TEST(TextInputModel, DeleteSurroundingAtCursor) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  EXPECT_TRUE(model->DeleteSurrounding(0, 1));
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "ABDE");
}

TEST(TextInputModel, DeleteSurroundingAtCursorAll) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  EXPECT_TRUE(model->DeleteSurrounding(0, 3));
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "AB");
}

TEST(TextInputModel, DeleteSurroundingAtCursorGreedy) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  EXPECT_TRUE(model->DeleteSurrounding(0, 4));
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "AB");
}

TEST(TextInputModel, DeleteSurroundingBeforeCursor) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  EXPECT_TRUE(model->DeleteSurrounding(-1, 1));
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "ACDE");
}

TEST(TextInputModel, DeleteSurroundingBeforeCursorAll) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  EXPECT_TRUE(model->DeleteSurrounding(-2, 2));
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "CDE");
}

TEST(TextInputModel, DeleteSurroundingBeforeCursorGreedy) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  EXPECT_TRUE(model->DeleteSurrounding(-3, 3));
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "CDE");
}

TEST(TextInputModel, DeleteSurroundingAfterCursor) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  EXPECT_TRUE(model->DeleteSurrounding(1, 1));
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "ABCE");
}

TEST(TextInputModel, DeleteSurroundingAfterCursorAll) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  EXPECT_TRUE(model->DeleteSurrounding(1, 2));
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "ABC");
}

TEST(TextInputModel, DeleteSurroundingAfterCursorGreedy) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  EXPECT_TRUE(model->DeleteSurrounding(1, 3));
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "ABC");
}

TEST(TextInputModel, DeleteSurroundingSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 3));
  EXPECT_TRUE(model->DeleteSurrounding(0, 1));
  EXPECT_EQ(model->selection_base(), 3);
  EXPECT_EQ(model->selection_extent(), 3);
  EXPECT_STREQ(model->GetText().c_str(), "ABCE");
}

TEST(TextInputModel, DeleteSurroundingReverseSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(4, 3));
  EXPECT_TRUE(model->DeleteSurrounding(0, 1));
  EXPECT_EQ(model->selection_base(), 3);
  EXPECT_EQ(model->selection_extent(), 3);
  EXPECT_STREQ(model->GetText().c_str(), "ABCE");
}

TEST(TextInputModel, BackspaceStart) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(0, 0));
  ASSERT_FALSE(model->Backspace());
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, BackspaceMiddle) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  ASSERT_TRUE(model->Backspace());
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "ACDE");
}

TEST(TextInputModel, BackspaceEnd) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(5, 5));
  ASSERT_TRUE(model->Backspace());
  EXPECT_EQ(model->selection_base(), 4);
  EXPECT_EQ(model->selection_extent(), 4);
  EXPECT_STREQ(model->GetText().c_str(), "ABCD");
}

TEST(TextInputModel, BackspaceWideCharacters) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("😄🙃🤪🧐");
  EXPECT_TRUE(model->SetSelection(4, 4));
  ASSERT_TRUE(model->Backspace());
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "😄🤪🧐");
}

TEST(TextInputModel, BackspaceSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(1, 4));
  ASSERT_TRUE(model->Delete());
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "AE");
}

TEST(TextInputModel, BackspaceReverseSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(4, 1));
  ASSERT_TRUE(model->Delete());
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "AE");
}

TEST(TextInputModel, MoveCursorForwardStart) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(0, 0));
  EXPECT_TRUE(model->MoveCursorForward());
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorForwardMiddle) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  EXPECT_TRUE(model->MoveCursorForward());
  EXPECT_EQ(model->selection_base(), 3);
  EXPECT_EQ(model->selection_extent(), 3);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorForwardEnd) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(5, 5));
  EXPECT_FALSE(model->MoveCursorForward());
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorForwardWideCharacters) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("😄🙃🤪🧐");
  EXPECT_TRUE(model->SetSelection(4, 4));
  ASSERT_TRUE(model->MoveCursorForward());
  EXPECT_EQ(model->selection_base(), 6);
  EXPECT_EQ(model->selection_extent(), 6);
  EXPECT_STREQ(model->GetText().c_str(), "😄🙃🤪🧐");
}

TEST(TextInputModel, MoveCursorForwardSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(1, 4));
  EXPECT_TRUE(model->MoveCursorForward());
  EXPECT_EQ(model->selection_base(), 4);
  EXPECT_EQ(model->selection_extent(), 4);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorForwardReverseSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(4, 1));
  EXPECT_TRUE(model->MoveCursorForward());
  EXPECT_EQ(model->selection_base(), 4);
  EXPECT_EQ(model->selection_extent(), 4);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorBackStart) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(0, 0));
  EXPECT_FALSE(model->MoveCursorBack());
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorBackMiddle) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  EXPECT_TRUE(model->MoveCursorBack());
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorBackEnd) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(5, 5));
  EXPECT_TRUE(model->MoveCursorBack());
  EXPECT_EQ(model->selection_base(), 4);
  EXPECT_EQ(model->selection_extent(), 4);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorBackWideCharacters) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("😄🙃🤪🧐");
  EXPECT_TRUE(model->SetSelection(4, 4));
  ASSERT_TRUE(model->MoveCursorBack());
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "😄🙃🤪🧐");
}

TEST(TextInputModel, MoveCursorBackSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(1, 4));
  EXPECT_TRUE(model->MoveCursorBack());
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorBackReverseSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(4, 1));
  EXPECT_TRUE(model->MoveCursorBack());
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToBeginningStart) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(0, 0));
  EXPECT_FALSE(model->MoveCursorToBeginning());
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToBeginningMiddle) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  EXPECT_TRUE(model->MoveCursorToBeginning());
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToBeginningEnd) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(5, 5));
  EXPECT_TRUE(model->MoveCursorToBeginning());
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToBeginningSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(1, 4));
  EXPECT_TRUE(model->MoveCursorToBeginning());
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToBeginningReverseSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(4, 1));
  EXPECT_TRUE(model->MoveCursorToBeginning());
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToEndStart) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(0, 0));
  EXPECT_TRUE(model->MoveCursorToEnd());
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToEndMiddle) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(2, 2));
  EXPECT_TRUE(model->MoveCursorToEnd());
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToEndEnd) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(5, 5));
  EXPECT_FALSE(model->MoveCursorToEnd());
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToEndSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(1, 4));
  EXPECT_TRUE(model->MoveCursorToEnd());
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToEndReverseSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(4, 1));
  EXPECT_TRUE(model->MoveCursorToEnd());
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, GetCursorOffset) {
  auto model = std::make_unique<TextInputModel>();
  // These characters take 1, 2, 3 and 4 bytes in UTF-8.
  model->SetText("$¢€𐍈");
  EXPECT_TRUE(model->SetSelection(0, 0));
  EXPECT_EQ(model->GetCursorOffset(), 0);
  EXPECT_TRUE(model->MoveCursorForward());
  EXPECT_EQ(model->GetCursorOffset(), 1);
  EXPECT_TRUE(model->MoveCursorForward());
  EXPECT_EQ(model->GetCursorOffset(), 3);
  EXPECT_TRUE(model->MoveCursorForward());
  EXPECT_EQ(model->GetCursorOffset(), 6);
  EXPECT_TRUE(model->MoveCursorForward());
  EXPECT_EQ(model->GetCursorOffset(), 10);
}

TEST(TextInputModel, GetCursorOffsetSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(1, 4));
  EXPECT_EQ(model->GetCursorOffset(), 4);
}

TEST(TextInputModel, GetCursorOffsetReverseSelection) {
  auto model = std::make_unique<TextInputModel>();
  model->SetText("ABCDE");
  EXPECT_TRUE(model->SetSelection(4, 1));
  EXPECT_EQ(model->GetCursorOffset(), 1);
}

}  // namespace flutter
