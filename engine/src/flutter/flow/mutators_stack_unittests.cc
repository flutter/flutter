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
  stack.pushClipRect(rect);
  stack.pushClipRRect(rrect);
  MutatorsStack copy = MutatorsStack(stack);
  ASSERT_TRUE(copy == stack);
}

TEST(MutatorsStack, PushClipRect) {
  MutatorsStack stack;
  auto rect = SkRect::MakeEmpty();
  stack.pushClipRect(rect);
  auto iter = stack.bottom();
  ASSERT_TRUE(iter->get()->type() == MutatorType::clip_rect);
  ASSERT_TRUE(iter->get()->rect() == rect);
}

TEST(MutatorsStack, PushClipRRect) {
  MutatorsStack stack;
  auto rrect = SkRRect::MakeEmpty();
  stack.pushClipRRect(rrect);
  auto iter = stack.bottom();
  ASSERT_TRUE(iter->get()->type() == MutatorType::clip_rrect);
  ASSERT_TRUE(iter->get()->rrect() == rrect);
}

TEST(MutatorsStack, PushTransform) {
  MutatorsStack stack;
  SkMatrix matrix;
  matrix.setIdentity();
  stack.pushTransform(matrix);
  auto iter = stack.bottom();
  ASSERT_TRUE(iter->get()->type() == MutatorType::transform);
  ASSERT_TRUE(iter->get()->matrix() == matrix);
}

TEST(MutatorsStack, Pop) {
  MutatorsStack stack;
  SkMatrix matrix;
  matrix.setIdentity();
  stack.pushTransform(matrix);
  stack.pop();
  auto iter = stack.bottom();
  ASSERT_TRUE(iter == stack.top());
}

TEST(MutatorsStack, Traversal) {
  MutatorsStack stack;
  SkMatrix matrix;
  matrix.setIdentity();
  stack.pushTransform(matrix);
  auto rect = SkRect::MakeEmpty();
  stack.pushClipRect(rect);
  auto rrect = SkRRect::MakeEmpty();
  stack.pushClipRRect(rrect);
  auto iter = stack.bottom();
  int index = 0;
  while (iter != stack.top()) {
    switch (index) {
      case 0:
        ASSERT_TRUE(iter->get()->type() == MutatorType::clip_rrect);
        ASSERT_TRUE(iter->get()->rrect() == rrect);
        break;
      case 1:
        ASSERT_TRUE(iter->get()->type() == MutatorType::clip_rect);
        ASSERT_TRUE(iter->get()->rect() == rect);
        break;
      case 2:
        ASSERT_TRUE(iter->get()->type() == MutatorType::transform);
        ASSERT_TRUE(iter->get()->matrix() == matrix);
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
  stack.pushTransform(matrix);
  SkRect rect = SkRect::MakeEmpty();
  stack.pushClipRect(rect);
  SkRRect rrect = SkRRect::MakeEmpty();
  stack.pushClipRRect(rrect);

  MutatorsStack stackOther;
  SkMatrix matrixOther = SkMatrix::MakeScale(1, 1);
  stackOther.pushTransform(matrixOther);
  SkRect rectOther = SkRect::MakeEmpty();
  stackOther.pushClipRect(rectOther);
  SkRRect rrectOther = SkRRect::MakeEmpty();
  stackOther.pushClipRRect(rrectOther);

  ASSERT_TRUE(stack == stackOther);
}

TEST(Mutator, Initialization) {
  SkRect rect = SkRect::MakeEmpty();
  Mutator mutator = Mutator(rect);
  ASSERT_TRUE(mutator.type() == MutatorType::clip_rect);
  ASSERT_TRUE(mutator.rect() == rect);

  SkRRect rrect = SkRRect::MakeEmpty();
  Mutator mutator2 = Mutator(rrect);
  ASSERT_TRUE(mutator2.type() == MutatorType::clip_rrect);
  ASSERT_TRUE(mutator2.rrect() == rrect);

  SkPath path;
  Mutator mutator3 = Mutator(path);
  ASSERT_TRUE(mutator3.type() == MutatorType::clip_path);
  ASSERT_TRUE(mutator3.path() == path);

  SkMatrix matrix;
  matrix.setIdentity();
  Mutator mutator4 = Mutator(matrix);
  ASSERT_TRUE(mutator4.type() == MutatorType::transform);
  ASSERT_TRUE(mutator4.matrix() == matrix);
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

  ASSERT_FALSE(mutator2 == mutator);
}

TEST(Mutator, UnEquality) {
  SkRect rect = SkRect::MakeEmpty();
  Mutator mutator = Mutator(rect);
  SkMatrix matrix;
  matrix.setIdentity();
  Mutator notEqualMutator = Mutator(matrix);
  ASSERT_TRUE(notEqualMutator != mutator);
}

}  // namespace testing
}  // namespace flutter
