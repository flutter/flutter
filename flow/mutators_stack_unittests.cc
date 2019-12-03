// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/embedded_views.h"

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(MutatorsStack, Initialization) {
  MutatorsStack stack;
  ASSERT_TRUE(true);
}

TEST(MutatorsStack, CopyConstructor) {
  MutatorsStack stack;
  auto rrect = SkRRect::MakeEmpty();
  auto rect = SkRect::MakeEmpty();
  stack.PushClipRect(rect);
  stack.PushClipRRect(rrect);
  MutatorsStack copy = MutatorsStack(stack);
  ASSERT_TRUE(copy == stack);
}

TEST(MutatorsStack, PushClipRect) {
  MutatorsStack stack;
  auto rect = SkRect::MakeEmpty();
  stack.PushClipRect(rect);
  auto iter = stack.Bottom();
  ASSERT_TRUE(iter->get()->GetType() == MutatorType::clip_rect);
  ASSERT_TRUE(iter->get()->GetRect() == rect);
}

TEST(MutatorsStack, PushClipRRect) {
  MutatorsStack stack;
  auto rrect = SkRRect::MakeEmpty();
  stack.PushClipRRect(rrect);
  auto iter = stack.Bottom();
  ASSERT_TRUE(iter->get()->GetType() == MutatorType::clip_rrect);
  ASSERT_TRUE(iter->get()->GetRRect() == rrect);
}

TEST(MutatorsStack, PushClipPath) {
  MutatorsStack stack;
  SkPath path;
  stack.PushClipPath(path);
  auto iter = stack.Bottom();
  ASSERT_TRUE(iter->get()->GetType() == flutter::MutatorType::clip_path);
  ASSERT_TRUE(iter->get()->GetPath() == path);
}

TEST(MutatorsStack, PushTransform) {
  MutatorsStack stack;
  SkMatrix matrix;
  matrix.setIdentity();
  stack.PushTransform(matrix);
  auto iter = stack.Bottom();
  ASSERT_TRUE(iter->get()->GetType() == MutatorType::transform);
  ASSERT_TRUE(iter->get()->GetMatrix() == matrix);
}

TEST(MutatorsStack, PushOpacity) {
  MutatorsStack stack;
  int alpha = 240;
  stack.PushOpacity(alpha);
  auto iter = stack.Bottom();
  ASSERT_TRUE(iter->get()->GetType() == MutatorType::opacity);
  ASSERT_TRUE(iter->get()->GetAlpha() == 240);
}

TEST(MutatorsStack, Pop) {
  MutatorsStack stack;
  SkMatrix matrix;
  matrix.setIdentity();
  stack.PushTransform(matrix);
  stack.Pop();
  auto iter = stack.Bottom();
  ASSERT_TRUE(iter == stack.Top());
}

TEST(MutatorsStack, Traversal) {
  MutatorsStack stack;
  SkMatrix matrix;
  matrix.setIdentity();
  stack.PushTransform(matrix);
  auto rect = SkRect::MakeEmpty();
  stack.PushClipRect(rect);
  auto rrect = SkRRect::MakeEmpty();
  stack.PushClipRRect(rrect);
  auto iter = stack.Bottom();
  int index = 0;
  while (iter != stack.Top()) {
    switch (index) {
      case 0:
        ASSERT_TRUE(iter->get()->GetType() == MutatorType::clip_rrect);
        ASSERT_TRUE(iter->get()->GetRRect() == rrect);
        break;
      case 1:
        ASSERT_TRUE(iter->get()->GetType() == MutatorType::clip_rect);
        ASSERT_TRUE(iter->get()->GetRect() == rect);
        break;
      case 2:
        ASSERT_TRUE(iter->get()->GetType() == MutatorType::transform);
        ASSERT_TRUE(iter->get()->GetMatrix() == matrix);
        break;
      default:
        break;
    }
    ++iter;
    ++index;
  }
}

TEST(MutatorsStack, Equality) {
  MutatorsStack stack;
  SkMatrix matrix = SkMatrix::MakeScale(1, 1);
  stack.PushTransform(matrix);
  SkRect rect = SkRect::MakeEmpty();
  stack.PushClipRect(rect);
  SkRRect rrect = SkRRect::MakeEmpty();
  stack.PushClipRRect(rrect);
  SkPath path;
  stack.PushClipPath(path);
  int alpha = 240;
  stack.PushOpacity(alpha);

  MutatorsStack stackOther;
  SkMatrix matrixOther = SkMatrix::MakeScale(1, 1);
  stackOther.PushTransform(matrixOther);
  SkRect rectOther = SkRect::MakeEmpty();
  stackOther.PushClipRect(rectOther);
  SkRRect rrectOther = SkRRect::MakeEmpty();
  stackOther.PushClipRRect(rrectOther);
  SkPath otherPath;
  stackOther.PushClipPath(otherPath);
  int otherAlpha = 240;
  stackOther.PushOpacity(otherAlpha);

  ASSERT_TRUE(stack == stackOther);
}

TEST(Mutator, Initialization) {
  SkRect rect = SkRect::MakeEmpty();
  Mutator mutator = Mutator(rect);
  ASSERT_TRUE(mutator.GetType() == MutatorType::clip_rect);
  ASSERT_TRUE(mutator.GetRect() == rect);

  SkRRect rrect = SkRRect::MakeEmpty();
  Mutator mutator2 = Mutator(rrect);
  ASSERT_TRUE(mutator2.GetType() == MutatorType::clip_rrect);
  ASSERT_TRUE(mutator2.GetRRect() == rrect);

  SkPath path;
  Mutator mutator3 = Mutator(path);
  ASSERT_TRUE(mutator3.GetType() == MutatorType::clip_path);
  ASSERT_TRUE(mutator3.GetPath() == path);

  SkMatrix matrix;
  matrix.setIdentity();
  Mutator mutator4 = Mutator(matrix);
  ASSERT_TRUE(mutator4.GetType() == MutatorType::transform);
  ASSERT_TRUE(mutator4.GetMatrix() == matrix);

  int alpha = 240;
  Mutator mutator5 = Mutator(alpha);
  ASSERT_TRUE(mutator5.GetType() == MutatorType::opacity);
}

TEST(Mutator, CopyConstructor) {
  SkRect rect = SkRect::MakeEmpty();
  Mutator mutator = Mutator(rect);
  Mutator copy = Mutator(mutator);
  ASSERT_TRUE(mutator == copy);

  SkRRect rrect = SkRRect::MakeEmpty();
  Mutator mutator2 = Mutator(rrect);
  Mutator copy2 = Mutator(mutator2);
  ASSERT_TRUE(mutator2 == copy2);

  SkPath path;
  Mutator mutator3 = Mutator(path);
  Mutator copy3 = Mutator(mutator3);
  ASSERT_TRUE(mutator3 == copy3);

  SkMatrix matrix;
  matrix.setIdentity();
  Mutator mutator4 = Mutator(matrix);
  Mutator copy4 = Mutator(mutator4);
  ASSERT_TRUE(mutator4 == copy4);

  int alpha = 240;
  Mutator mutator5 = Mutator(alpha);
  Mutator copy5 = Mutator(mutator5);
  ASSERT_TRUE(mutator5 == copy5);
}

TEST(Mutator, Equality) {
  SkMatrix matrix;
  matrix.setIdentity();
  Mutator mutator = Mutator(matrix);
  Mutator otherMutator = Mutator(matrix);
  ASSERT_TRUE(mutator == otherMutator);

  SkRect rect = SkRect::MakeEmpty();
  Mutator mutator2 = Mutator(rect);
  Mutator otherMutator2 = Mutator(rect);
  ASSERT_TRUE(mutator2 == otherMutator2);

  SkRRect rrect = SkRRect::MakeEmpty();
  Mutator mutator3 = Mutator(rrect);
  Mutator otherMutator3 = Mutator(rrect);
  ASSERT_TRUE(mutator3 == otherMutator3);

  SkPath path;
  flutter::Mutator mutator4 = flutter::Mutator(path);
  flutter::Mutator otherMutator4 = flutter::Mutator(path);
  ASSERT_TRUE(mutator4 == otherMutator4);
  ASSERT_FALSE(mutator2 == mutator);
  int alpha = 240;
  Mutator mutator5 = Mutator(alpha);
  Mutator otherMutator5 = Mutator(alpha);
  ASSERT_TRUE(mutator5 == otherMutator5);
}

TEST(Mutator, UnEquality) {
  SkRect rect = SkRect::MakeEmpty();
  Mutator mutator = Mutator(rect);
  SkMatrix matrix;
  matrix.setIdentity();
  Mutator notEqualMutator = Mutator(matrix);
  ASSERT_TRUE(notEqualMutator != mutator);

  int alpha = 240;
  int alpha2 = 241;
  Mutator mutator2 = Mutator(alpha);
  Mutator otherMutator2 = Mutator(alpha2);
  ASSERT_TRUE(mutator2 != otherMutator2);
}

}  // namespace testing
}  // namespace flutter
