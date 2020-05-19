// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/cpp/text_input_model.h"

#include <limits>
#include <map>
#include <vector>

#include "gtest/gtest.h"

namespace flutter {

TEST(TextInputModel, InputTypeAndAction) {
  auto model = std::make_unique<TextInputModel>("INPUT_TYPE", "INPUT_ACTION");
  EXPECT_STREQ(model->input_type().c_str(), "INPUT_TYPE");
  EXPECT_STREQ(model->input_action().c_str(), "INPUT_ACTION");
}

TEST(TextInputModel, SetEditingStateStart) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(0, 0, "ABCDE"));
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, SetEditingMiddle) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(2, 2, "ABCDE"));
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, SetEditingStateEnd) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(5, 5, "ABCDE"));
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, SetEditingStateSelection) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(1, 4, "ABCDE"));
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 4);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, SetEditingStateReverseSelection) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_FALSE(model->SetEditingState(3, 1, "ABCDE"));
}

TEST(TextInputModel, SetEditingStateOutsideString) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_FALSE(model->SetEditingState(4, 6, "ABCDE"));
  EXPECT_FALSE(model->SetEditingState(5, 6, "ABCDE"));
  EXPECT_FALSE(model->SetEditingState(6, 6, "ABCDE"));
}

TEST(TextInputModel, SetEditingStateWideCharacters) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(0, 0, "😄🙃🤪🧐"));
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "😄🙃🤪🧐");
}

TEST(TextInputModel, AddCodePoint) {
  auto model = std::make_unique<TextInputModel>("", "");
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
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(1, 4, "ABCDE"));
  model->AddCodePoint('x');
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "AxE");
}

TEST(TextInputModel, AddCodePointSelectionWideCharacter) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(1, 4, "ABCDE"));
  model->AddCodePoint(0x1f604);
  EXPECT_EQ(model->selection_base(), 3);
  EXPECT_EQ(model->selection_extent(), 3);
  EXPECT_STREQ(model->GetText().c_str(), "A😄E");
}

TEST(TextInputModel, AddText) {
  auto model = std::make_unique<TextInputModel>("", "");
  model->AddText(u"ABCDE");
  model->AddText(u"😄");
  model->AddText(u"FGHIJ");
  EXPECT_EQ(model->selection_base(), 12);
  EXPECT_EQ(model->selection_extent(), 12);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE😄FGHIJ");
}

TEST(TextInputModel, AddTextSelection) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(1, 4, "ABCDE"));
  model->AddText(u"xy");
  EXPECT_EQ(model->selection_base(), 3);
  EXPECT_EQ(model->selection_extent(), 3);
  EXPECT_STREQ(model->GetText().c_str(), "AxyE");
}

TEST(TextInputModel, AddTextSelectionWideCharacter) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(1, 4, "ABCDE"));
  model->AddText(u"😄🙃");
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "A😄🙃E");
}

TEST(TextInputModel, DeleteStart) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(0, 0, "ABCDE"));
  ASSERT_TRUE(model->Delete());
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "BCDE");
}

TEST(TextInputModel, DeleteMiddle) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(2, 2, "ABCDE"));
  ASSERT_TRUE(model->Delete());
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "ABDE");
}

TEST(TextInputModel, DeleteEnd) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(5, 5, "ABCDE"));
  ASSERT_FALSE(model->Delete());
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, DeleteWideCharacters) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(4, 4, "😄🙃🤪🧐"));
  ASSERT_TRUE(model->Delete());
  EXPECT_EQ(model->selection_base(), 4);
  EXPECT_EQ(model->selection_extent(), 4);
  EXPECT_STREQ(model->GetText().c_str(), "😄🙃🧐");
}

TEST(TextInputModel, DeleteSelection) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(1, 4, "ABCDE"));
  ASSERT_TRUE(model->Delete());
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "AE");
}

TEST(TextInputModel, BackspaceStart) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(0, 0, "ABCDE"));
  ASSERT_FALSE(model->Backspace());
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, BackspaceMiddle) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(2, 2, "ABCDE"));
  ASSERT_TRUE(model->Backspace());
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "ACDE");
}

TEST(TextInputModel, BackspaceEnd) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(5, 5, "ABCDE"));
  ASSERT_TRUE(model->Backspace());
  EXPECT_EQ(model->selection_base(), 4);
  EXPECT_EQ(model->selection_extent(), 4);
  EXPECT_STREQ(model->GetText().c_str(), "ABCD");
}

TEST(TextInputModel, BackspaceWideCharacters) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(4, 4, "😄🙃🤪🧐"));
  ASSERT_TRUE(model->Backspace());
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "😄🤪🧐");
}

TEST(TextInputModel, BackspaceSelection) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(1, 4, "ABCDE"));
  ASSERT_TRUE(model->Delete());
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "AE");
}

TEST(TextInputModel, MoveCursorForwardStart) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(0, 0, "ABCDE"));
  EXPECT_TRUE(model->MoveCursorForward());
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorForwardMiddle) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(2, 2, "ABCDE"));
  EXPECT_TRUE(model->MoveCursorForward());
  EXPECT_EQ(model->selection_base(), 3);
  EXPECT_EQ(model->selection_extent(), 3);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorForwardEnd) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(5, 5, "ABCDE"));
  EXPECT_FALSE(model->MoveCursorForward());
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorForwardWideCharacters) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(4, 4, "😄🙃🤪🧐"));
  ASSERT_TRUE(model->MoveCursorForward());
  EXPECT_EQ(model->selection_base(), 6);
  EXPECT_EQ(model->selection_extent(), 6);
  EXPECT_STREQ(model->GetText().c_str(), "😄🙃🤪🧐");
}

TEST(TextInputModel, MoveCursorForwardSelection) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(1, 4, "ABCDE"));
  EXPECT_TRUE(model->MoveCursorForward());
  EXPECT_EQ(model->selection_base(), 4);
  EXPECT_EQ(model->selection_extent(), 4);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorBackStart) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(0, 0, "ABCDE"));
  EXPECT_FALSE(model->MoveCursorBack());
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorBackMiddle) {
  auto model = std::make_unique<TextInputModel>("", "");
  model->SetEditingState(2, 2, "ABCDE");
  EXPECT_TRUE(model->MoveCursorBack());
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorBackEnd) {
  auto model = std::make_unique<TextInputModel>("", "");
  model->SetEditingState(5, 5, "ABCDE");
  EXPECT_TRUE(model->MoveCursorBack());
  EXPECT_EQ(model->selection_base(), 4);
  EXPECT_EQ(model->selection_extent(), 4);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorBackWideCharacters) {
  auto model = std::make_unique<TextInputModel>("", "");
  EXPECT_TRUE(model->SetEditingState(4, 4, "😄🙃🤪🧐"));
  ASSERT_TRUE(model->MoveCursorBack());
  EXPECT_EQ(model->selection_base(), 2);
  EXPECT_EQ(model->selection_extent(), 2);
  EXPECT_STREQ(model->GetText().c_str(), "😄🙃🤪🧐");
}

TEST(TextInputModel, MoveCursorBackSelection) {
  auto model = std::make_unique<TextInputModel>("", "");
  model->SetEditingState(1, 4, "ABCDE");
  EXPECT_TRUE(model->MoveCursorBack());
  EXPECT_EQ(model->selection_base(), 1);
  EXPECT_EQ(model->selection_extent(), 1);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToBeginningStart) {
  auto model = std::make_unique<TextInputModel>("", "");
  model->SetEditingState(0, 0, "ABCDE");
  EXPECT_FALSE(model->MoveCursorToBeginning());
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToBeginningMiddle) {
  auto model = std::make_unique<TextInputModel>("", "");
  model->SetEditingState(2, 2, "ABCDE");
  EXPECT_TRUE(model->MoveCursorToBeginning());
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToBeginningEnd) {
  auto model = std::make_unique<TextInputModel>("", "");
  model->SetEditingState(5, 5, "ABCDE");
  EXPECT_TRUE(model->MoveCursorToBeginning());
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToBeginningSelection) {
  auto model = std::make_unique<TextInputModel>("", "");
  model->SetEditingState(1, 4, "ABCDE");
  EXPECT_TRUE(model->MoveCursorToBeginning());
  EXPECT_EQ(model->selection_base(), 0);
  EXPECT_EQ(model->selection_extent(), 0);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToEndStart) {
  auto model = std::make_unique<TextInputModel>("", "");
  model->SetEditingState(0, 0, "ABCDE");
  EXPECT_TRUE(model->MoveCursorToEnd());
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToEndMiddle) {
  auto model = std::make_unique<TextInputModel>("", "");
  model->SetEditingState(2, 2, "ABCDE");
  EXPECT_TRUE(model->MoveCursorToEnd());
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToEndEnd) {
  auto model = std::make_unique<TextInputModel>("", "");
  model->SetEditingState(5, 5, "ABCDE");
  EXPECT_FALSE(model->MoveCursorToEnd());
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

TEST(TextInputModel, MoveCursorToEndSelection) {
  auto model = std::make_unique<TextInputModel>("", "");
  model->SetEditingState(1, 4, "ABCDE");
  EXPECT_TRUE(model->MoveCursorToEnd());
  EXPECT_EQ(model->selection_base(), 5);
  EXPECT_EQ(model->selection_extent(), 5);
  EXPECT_STREQ(model->GetText().c_str(), "ABCDE");
}

}  // namespace flutter
